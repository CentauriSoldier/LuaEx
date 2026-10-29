'use strict';
const path = require('path');
const os = require('os');
const profile = require('../installation.json');
const packagePath = path.resolve(__dirname, '..');
const root = process.env.LUAEX_ROOT || profile.luaExRoot || path.resolve(__dirname, '../../../..');
const lua = process.env.LUA54 || profile.luaExecutable || path.join(os.homedir(), 'Sync/Portable Apps/Libraries/Lua/5.4/lua54.exe');

// Runs in Pulsar's isolated --test process, not in the user's open editor.
describe('LXC package in Pulsar', function () {
    it('loads grammar and provides real Linter v2 diagnostics for LXC and Lua', function () {
        let done = false, failure;
        const providers = [];
        let subscription, editor, loaded;
        runs(function () {
            (async function () {
                atom.config.set('linter-lxc.luaExRoot', root);
                atom.config.set('linter-lxc.luaExecutable', lua);
                atom.config.set('linter-lxc.delegateLua', false);
                subscription = atom.packages.serviceHub.consume('linter', '2.0.0', function (provider) {
                    providers.push(provider);
                    return {dispose() {}};
                });
                await atom.packages.activatePackage(path.join(os.homedir(), '.pulsar/packages/language-lua'));
                loaded = await atom.packages.activatePackage(packagePath);
                const grammar = atom.grammars.selectGrammar(path.join(root, 'smoke.lxc'));
                expect(grammar.scopeName).toBe('source.lxc');
                const tokens = grammar.tokenizeLine('public class Creature {').tokens;
                expect(tokens.some(token => token.value === 'public' && token.scopes.indexOf('storage.modifier.visibility.lxc') >= 0)).toBe(true);
                expect(tokens.some(token => token.value === 'Creature' && token.scopes.indexOf('entity.name.type.declaration.lxc') >= 0)).toBe(true);
                const comment = grammar.tokenizeLine('-- public class Creature').tokens;
                expect(comment.some(token => token.scopes.indexOf('storage.modifier.visibility.lxc') >= 0)).toBe(false);
                const provider = providers.find(value => value.name === 'LXC / Lua 5.4');
                expect(provider).toBeDefined();
                editor = atom.workspace.buildTextEditor();
                editor.getBuffer().setPath(path.join(root, 'pulsar-linter-smoke.lxc'));
                editor.setGrammar(grammar);
                document.body.appendChild(editor.element);
                expect(editor.element.getAttribute('data-grammar')).toBe('source lxc');
                const palette = [
                    ['entity name type declaration lxc','rgb(255, 223, 153)'],
                    ['entity name function constructor lxc','rgb(255, 223, 153)'],
                    ['entity name namespace declaration lxc','rgb(201, 166, 91)'],
                    ['punctuation section declaration begin lxc','rgb(183, 255, 74)'],
                    ['punctuation section declaration end lxc','rgb(183, 255, 74)'],
                    ['keyword operator lua','rgb(133, 215, 255)'],
                    ['storage type declaration lxc','rgb(205, 165, 255)'],
                    ['storage modifier visibility lxc','rgb(255, 173, 70)'],
                    ['storage modifier static lxc','rgb(255, 79, 225)'],
                    ['storage modifier other lxc','rgb(214, 164, 49)'],
                    ['variable language receiver lxc','rgb(69, 240, 255)'],
                    ['keyword other dependency lxc','rgb(131, 255, 131)'],
                    ['storage type accessor lxc','rgb(255, 128, 128)'],
                    ['storage type operator lxc','rgb(248, 248, 242)'],
                    ['constant language null lxc','rgb(168, 191, 255)']
                ];
                for (const entry of palette) {
                    const span = document.createElement('span');
                    span.className=entry[0].split(' ').map(value=>'syntax--'+value).join(' ');
                    editor.element.appendChild(span);
                    expect(window.getComputedStyle(span).color).toBe(entry[1]);
                    span.remove();
                }
                const staticTokens=grammar.tokenizeLine('public static final class A requires(B.C) {').tokens;
                expect(staticTokens.some(token=>token.value==='static'&&token.scopes.indexOf('storage.modifier.static.lxc')>=0)).toBe(true);
                expect(staticTokens.some(token=>token.value==='final'&&token.scopes.indexOf('storage.modifier.other.lxc')>=0)).toBe(true);
                const strings=grammar.tokenizeLine('local text = "static public class"').tokens;
                expect(strings.some(token=>token.scopes.indexOf('storage.modifier.static.lxc')>=0)).toBe(false);
                const accessor=grammar.tokenizeLine('set { field = value; }').tokens;
                expect(accessor.some(token=>token.value==='field'&&token.scopes.indexOf('variable.language.accessor.lxc')>=0)).toBe(true);
                const ordinaryField=grammar.tokenizeLine('local field = value').tokens;
                expect(ordinaryField.some(token=>token.scopes.indexOf('variable.language.accessor.lxc')>=0)).toBe(false);
                editor.setText('namespace PulsarSmoke { class A { public f() { return 1; } } }');
                const scopes = editor.getLastCursor().getScopeDescriptor().getScopesArray();
                expect(scopes.indexOf('source.lxc') >= 0).toBe(true);
                expect(scopes.indexOf('source.lua')).toBe(-1);
                let messages = await provider.lint(editor);
                expect(messages.length).toBe(0);
                editor.setText('namespace PulsarSmoke {\n class A { public public value = 1; }\n}');
                messages = await provider.lint(editor);
                expect(messages.length).toBe(1);
                expect(messages[0].severity).toBe('error');
                expect(messages[0].location.position[0][0]).toBe(1);
                editor.getBuffer().setPath(path.join(root, 'pulsar-linter-smoke.lua'));
                editor.setGrammar(atom.grammars.selectGrammar(editor.getPath()));
                editor.setText('local value = ;');
                messages = await provider.lint(editor);
                expect(messages.length).toBe(1);
                expect(messages[0].description).toBe('Lua 5.4 syntax');
                editor.getBuffer().setPath(path.join(root,'pulsar-refinement-smoke.lxc'));
                const refinement = [
                    'namespace Refined {',
                    ' class Creature',
                    ' {',
                    ' public Creature() { local t = { brace = "}" }; }',
                    ' public describe() { return {1, 2}; }',
                    ' public HitPoints { get; set { field = value; } }',
                    ' private class Inner { public Inner() {} public Creature() {} }',
                    ' }',
                    ' class Human : Creature { public Human() { base(); } }',
                    ' -- } { class Bogus { public Creature() {} }',
                    '}'
                ].join('\n');
                editor.setGrammar(grammar);
                editor.setText(refinement);
                messages=await provider.lint(editor);
                expect(messages.length).toBe(0);
                const contextual=editor.getGrammar();
                let state;
                const rows=refinement.split('\n').map(line=>{
                    const result=contextual.tokenizeLine(line,state);state=result.ruleStack;return result.tokens;
                });
                const scoped=(row,value,scope)=>rows[row].filter(token=>token.value===value&&token.scopes.indexOf(scope)>=0);
                expect(scoped(0,'Refined','entity.name.namespace.declaration.lxc').length).toBe(1);
                expect(scoped(1,'Creature','entity.name.type.declaration.lxc').length).toBe(1);
                expect(scoped(3,'Creature','entity.name.function.constructor.lxc').length).toBe(1);
                expect(scoped(6,'Inner','entity.name.function.constructor.lxc').length).toBe(1);
                expect(scoped(6,'Creature','entity.name.function.method.lxc').length).toBe(1);
                expect(scoped(8,'Human','entity.name.function.constructor.lxc').length).toBe(1);
                const opening=rows.flat().filter(token=>token.scopes.indexOf('punctuation.section.declaration.begin.lxc')>=0);
                const closing=rows.flat().filter(token=>token.scopes.indexOf('punctuation.section.declaration.end.lxc')>=0);
                expect(opening.length).toBe(4);
                expect(closing.length).toBe(4);
                expect(rows[9].some(token=>token.scopes.indexOf('entity.name.function.constructor.lxc')>=0)).toBe(false);
                expect(rows[3].some(token=>token.scopes.indexOf('punctuation.section.declaration.end.lxc')>=0)).toBe(false);
                expect(rows[4].some(token=>token.scopes.indexOf('punctuation.section.declaration.end.lxc')>=0)).toBe(false);
                expect(rows[5].some(token=>token.scopes.indexOf('punctuation.section.declaration.end.lxc')>=0)).toBe(false);
                const sameLine=contextual.tokenizeLine('namespace Same { class lower { public lower() {} } }').tokens;
                const generated=require('../lib/highlight').grammar(['lower']);
                const lower=atom.grammars.createGrammar(path.join(packagePath,'grammars/lxc.cson'),generated);
                expect(lower.tokenizeLine('class lower { public lower() {} }').tokens.some(token=>token.value==='lower'&&token.scopes.indexOf('entity.name.function.constructor.lxc')>=0)).toBe(true);
                expect(sameLine.filter(token=>token.scopes.indexOf('punctuation.section.declaration.end.lxc')>=0).length).toBe(2);
                const operators=contextual.tokenizeLine('local x = 1e-3 + 2 > 1 and 3 < 4 -- + 99').tokens;
                expect(operators.some(token=>token.value==='1e-3'&&token.scopes.indexOf('constant.numeric.lua')>=0)).toBe(true);
                for(const symbol of ['=','+','>','<']) expect(operators.some(token=>token.value===symbol&&token.scopes.indexOf('keyword.operator.lua')>=0)).toBe(true);
                const literal=document.createElement('span');literal.className='syntax--constant syntax--language syntax--lua';editor.element.appendChild(literal);
                expect(window.getComputedStyle(literal).color).not.toBe('rgb(214, 164, 49)');literal.remove();
                const comparison=document.createElement('span');
                comparison.className='syntax--constant syntax--numeric syntax--lua';editor.element.appendChild(comparison);
                expect(window.getComputedStyle(comparison).color).not.toBe('rgb(133, 215, 255)');comparison.remove();
                // Regression for the screenshot: the setter opening brace had a punctuation
                // scope, but its closing brace had only source.lxc/default text.
                await atom.packages.activatePackage(path.join(os.homedir(), '.pulsar/packages/synthwave-protocol-syntax'));
                const pairSource=[
                    'namespace Playground {',
                    ' class Creature {',
                    ' public HitPoints {',
                    ' get;',
                    ' protected set { field = math.min(this.maximumHitPoints, math.max(0, value)); }',
                    ' } = 100;',
                    ' }',
                    '}'
                ];
                let pairState;
                const pairRows=pairSource.map(line=>{
                    const result=contextual.tokenizeLine(line,pairState);pairState=result.ruleStack;return result.tokens;
                });
                function scopesAt(row,column) {
                    let start=0;
                    for(const token of pairRows[row]) {
                        if(column<start+token.value.length)return token.scopes;
                        start+=token.value.length;
                    }
                    throw new Error('Missing brace token');
                }
                function braceColor(scopes) {
                    const container=document.createElement('span');editor.element.appendChild(container);
                    let leaf=container;
                    for(const scope of scopes) {
                        const span=document.createElement('span');span.className=scope.split('.').map(part=>'syntax--'+part).join(' ');
                        leaf.appendChild(span);leaf=span;
                    }
                    leaf.textContent='{';const color=window.getComputedStyle(leaf).color;container.remove();return color;
                }
                const setOpen=scopesAt(4,pairSource[4].indexOf('{'));
                const setClose=scopesAt(4,pairSource[4].lastIndexOf('}'));
                const propertyOpen=scopesAt(2,pairSource[2].indexOf('{'));
                const propertyClose=scopesAt(5,pairSource[5].indexOf('}'));
                console.log('Paired accessor colors with installed syntax theme: '+braceColor(setOpen)+' / '+braceColor(setClose));
                expect(setOpen.indexOf('punctuation.section.block.begin.lxc')>=0).toBe(true);
                expect(setClose.indexOf('punctuation.section.block.end.lxc')>=0).toBe(true);
                expect(braceColor(setOpen)).toBe(braceColor(setClose));
                expect(braceColor(propertyOpen)).toBe(braceColor(propertyClose));
                expect(propertyClose.indexOf('punctuation.section.declaration.end.lxc')).toBe(-1);
                console.log('PASS Pulsar package: activation, .lxc grammar/cursor scopes, Linter v2 service, LXC diagnostics and Lua diagnostics.');
            })().then(function () { done = true; }, function (error) { failure = error; done = true; });
        });
        waitsFor(function () { return done; }, 'Pulsar LXC package checks', 30000);
        runs(function () {
            if (editor) editor.destroy();
            if (subscription) subscription.dispose();
            if (loaded) atom.packages.deactivatePackage(loaded.name);
            if (failure) throw failure;
        });
    });
});
