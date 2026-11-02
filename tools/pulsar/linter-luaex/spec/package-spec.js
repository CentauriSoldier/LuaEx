 'use strict';
const path = require('path');
const os = require('os');
const root = process.env.LUAEX_ROOT || require('../installation.json').luaExRoot || path.resolve(__dirname, '../../../..');
const packagePath = path.resolve(__dirname, '..');
// GUI executables on Windows may not inherit stdout. A test-only report provides
// evidence independently of the launcher's exit status.
if (process.env.LUAEX_TEST_REPORT) jasmine.getEnv().addReporter({reportRunnerResults(runner) {
    const result = runner.results(), failures = [];
    const visit = item => {
        if (item.getItems) item.getItems().forEach(visit);
        else if (item.passed && !item.passed()) failures.push(item.message);
    };
    visit(result);
    require('fs').writeFileSync(process.env.LUAEX_TEST_REPORT, JSON.stringify({passed: result.passedCount, failed: result.failedCount, total: result.totalCount, failures}, null, 2));
}});

// Run with Pulsar --test in an isolated process. No user configuration is written.
describe('LuaEx editor package', function () {
    it('provides diagnostics, completions, rendered hover and signature help', function () {
        let done = false, failure, editor, loaded, service;
        runs(function () {
            (async function () {
                atom.config.set('linter-luaex.luaExRoot', root);
                atom.config.set('linter-luaex.delegateLua', false);
                const linters = [], completions = [];
                const a = atom.packages.serviceHub.consume('linter', '2.0.0', value => { linters.push(value); return {dispose() {}}; });
                const b = atom.packages.serviceHub.consume('autocomplete.provider', '2.0.0', value => { completions.push(value); return {dispose() {}}; });
                service = {dispose() { a.dispose(); b.dispose(); }};
                await atom.packages.activatePackage(path.join(os.homedir(), '.pulsar/packages/language-lua'));
                loaded = await atom.packages.activatePackage(packagePath);
                expect(linters.length).toBe(1);
                expect(completions.length).toBe(1);
                expect(linters[0].name).toBe('LuaEx / LXC / LXE / Lua 5.4');
                expect(atom.grammars.selectGrammar('example.lxe').scopeName).toBe('source.lxe');
                const grammar = atom.grammars.selectGrammar('example.lxc');
                expect(grammar.scopeName).toBe('source.lxc');
                expect(grammar.tokenizeLine('public class Example {').tokens.some(token => token.scopes.includes('entity.name.type.declaration.lxc'))).toBe(true);
                editor = await atom.workspace.open();
                editor.getBuffer().setPath(path.join(root, 'luaex-editor-smoke.lxc'));
                editor.setGrammar(grammar);
                const source = `namespace EditorSmoke {
class Example {
    ---@type number
    public Value { get; set; } = 1;
    ---@param number first First value.
    ---@param string second Second value.
    ---@return boolean
    public method(first, second) { return true; }
    public work() {
        this.method(1, "test");
    }
}
}`;
                editor.setText(source);
                expect((await linters[0].lint(editor)).length).toBe(0);
                const offset = source.indexOf('this.method(1, "test")') + 'this.method(1, '.length;
                editor.setCursorBufferPosition(editor.getBuffer().positionForCharacterIndex(offset));
                atom.commands.dispatch(atom.views.getView(editor), 'linter-luaex:signature-help');
                await new Promise(resolve => setTimeout(resolve, 100));
                const signature = atom.views.getView(editor).querySelector('.luaex-signature');
                expect(signature).not.toBe(null);
                expect(signature.querySelector('strong').textContent).toBe('second: string');
                expect(signature.textContent).toContain('boolean');
                const point = editor.getBuffer().positionForCharacterIndex(source.indexOf('this.method(1') + 8);
                const suggestions = await completions[0].getSuggestions({editor, bufferPosition: point});
                expect(suggestions.some(item => item.text === 'method' && item.description.includes('first: number'))).toBe(true);
                const index = loaded.mainModule.getIndex(editor);
                const hover = require('../lib/hover');
                expect(hover.text(index, editor.getPath(), source.indexOf('this.method(1') + 8)).toContain('first: number');
                const element = atom.views.getView(editor);
                element.getComponent().updateSync();
                const lines = element.querySelector('.lines');
                const position = editor.screenPositionForBufferPosition(point);
                const pixel = element.pixelPositionForScreenPosition(position);
                const rectangle = lines.getBoundingClientRect();
                element.dispatchEvent(new MouseEvent('mousemove', {bubbles: true, clientX: rectangle.left + pixel.left, clientY: rectangle.top + pixel.top + 2}));
                await new Promise(resolve => setTimeout(resolve, 600));
                const tip = document.querySelector('.luaex-hover');
                expect(tip).not.toBe(null);
                expect(tip.textContent).toContain('first: number');
                element.dispatchEvent(new MouseEvent('mouseleave'));
                expect(document.querySelector('.luaex-hover')).toBe(null);
                editor.setText(source.replace('---@type number', '---@type MissingEditorType'));
                expect((await linters[0].lint(editor)).some(item => item.severity === 'warning' && /MissingEditorType/.test(item.excerpt))).toBe(true);
                editor.setText('local broken = )'); editor.setGrammar(atom.grammars.selectGrammar('example.lua'));
                editor.getBuffer().setPath(path.join(root,'luaex-editor-smoke.lua'));
                expect((await linters[0].lint(editor)).some(item => item.severity === 'error')).toBe(true);
                console.log('PASS real Pulsar: services, grammar, compiler diagnostics, annotation warnings, completion, hover DOM and active-parameter signature DOM.');
            })().then(() => {done = true;}, error => {failure = error; done = true;});
        });
        waitsFor(() => done, 'LuaEx editor integration', 30000);
        runs(function () {
            if (editor) editor.destroy();
            if (service) service.dispose();
            if (loaded) atom.packages.deactivatePackage(loaded.name);
            if (failure) throw failure;
        });
    });
});
