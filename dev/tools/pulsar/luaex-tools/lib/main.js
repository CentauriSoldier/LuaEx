'use strict';
const path = require('path');
const installation = require('../installation.json');
const {Runner} = require('./runner');
const project = require('./project');
const highlight = require('./highlight');
const {Index} = require('./symbols');
const autocomplete = require('./autocomplete');
const hover = require('./hover');
const signatures = require('./signatures');

function position(text, line) {
    const lines = text.split(/\r?\n/);
    const row = Math.max(0, Math.min(lines.length - 1, (Number(line) || 1) - 1));
    const start = Math.max(0, lines[row].search(/\S/));
    return [[row, start], [row, lines[row].length]];
}

module.exports = {
    config: {
        luaExecutable: {type: 'string', default: installation.luaExecutable || '', description: 'Lua 5.4 executable. Empty searches LUA54, the local portable Lua 5.4 folder, and PATH.'},
        luaExRoot: {type: 'string', default: installation.luaExRoot || '', description: 'LuaEx repository. Empty searches LUAEX_ROOT, file/package/project ancestors, sibling repositories and the local GitHub checkout.'},
        projectRoot: {type: 'string', default: '', description: 'LXC source root. Empty uses the Pulsar project root, limited to the LuaEx repository for files inside it.'},
        delegateLua: {type: 'boolean', default: true, description: 'Let active linter-lua handle ordinary .lua files. Disable to use this package\'s Lua 5.4 syntax checks instead.'}
    },

    activate() {
        if (this.active) return;
        this.runner = new Runner(); this.revisions = new Map(); this.active = true;
        this.indexCache = new Map(); this.subscriptions = [];
        const invalidate = () => this.indexCache.clear();
        if (atom.workspace.observeTextEditors) this.subscriptions.push(atom.workspace.observeTextEditors(editor => {
            const changes = editor.onDidChange(invalidate);
            const disposed = [];
            if (/\.(lxc|lxe)$/i.test(editor.getPath() || '')) {
                disposed.push(hover.attach(editor, item => this.getIndex(item)), signatures.attach(editor, item => this.getIndex(item)));
            }
            let finished = false;
            const cleanup = () => { if (finished) return; finished = true; changes.dispose(); disposed.forEach(item => item.dispose()); invalidate(); };
            const destroy = editor.onDidDestroy(cleanup);
            this.subscriptions.push({dispose() { destroy.dispose(); cleanup(); }});
        }));
        if (atom.project.onDidChangeFiles) this.subscriptions.push(atom.project.onDidChangeFiles(invalidate));
        if (atom.config.onDidChange) this.subscriptions.push(atom.config.onDidChange('luaex-tools', invalidate));
    },
    deactivate() {
        this.active = false; if (this.runner) this.runner.dispose();
        (this.subscriptions || []).forEach(item => item.dispose()); this.subscriptions = [];
        if (this.indexCache) this.indexCache.clear(); this.revisions = new Map();
    },

    sourceBatch(editor) {
        const file = editor.getPath(), source = editor.getText();
        const root = project.frameworkRoot(file, atom.config.get('luaex-tools.luaExRoot'));
        const selected = atom.config.get('luaex-tools.projectRoot') ||
            (project.inside(file, root) ? root : atom.project.relativizePath(file)[0]) || path.dirname(file);
        const overlays = atom.workspace.getTextEditors().filter(item => item.getPath()).map(item => ({file: item.getPath(), source: item.getText()}));
        return {root, files: project.collect(file, source, root, path.resolve(selected), overlays)};
    },
    getIndex(editor) {
        if (!this.active) this.activate();
        const file = editor.getPath();
        const cached = this.indexCache.get(file);
        if (cached && cached.source === editor.getText()) return cached.index;
        const batch = this.sourceBatch(editor), index = new Index(batch.files);
        this.indexCache.set(file, {source: editor.getText(), index});
        return index;
    },
    provideAutocomplete() {
        if (!this.active) this.activate();
        return autocomplete.provider(editor => this.getIndex(editor));
    },

    provideLinter() {
        if (!this.runner) this.activate();
        return {
            name: 'LuaEx / LXC / LXE / Lua 5.4', scope: 'file', lintsOnChange: true,
            grammarScopes: ['source.lxc', 'source.lxe', 'source.lua', 'text.plain'],
            lint: editor => this.lint(editor)
        };
    },

    async lint(editor) {
        const file = editor.getPath();
        if (!file || !/\.(lua|lxc|lxe)$/i.test(file)) return [];
        const lua = path.extname(file).toLowerCase() === '.lua';
        if (lua && atom.config.get('luaex-tools.delegateLua') && atom.packages.isPackageActive('linter-lua')) return [];
        const source = editor.getText();
        const revision = (this.revisions.get(file) || 0) + 1;
        this.revisions.set(file, revision);
        const snapshots = atom.workspace.getTextEditors().filter(item => item.getPath()).map(item => ({
            editor: item, file: item.getPath(), source: item.getText()
        }));
        const current = () => this.active && this.revisions.get(file) === revision &&
            !editor.isDestroyed() && editor.getText() === source &&
            snapshots.every(item => item.editor.isDestroyed() || item.editor.getText() === item.source);
        try {
            let root = '', files = [{file, source}];
            if (!lua) {
                root = project.frameworkRoot(file, atom.config.get('luaex-tools.luaExRoot'));
                const selected = atom.config.get('luaex-tools.projectRoot') ||
                    (project.inside(file, root) ? root : atom.project.relativizePath(file)[0]) || path.dirname(file);
                files = project.collect(file, source, root, path.resolve(selected), snapshots);
            }
            const diagnostics = await this.runner.lint({
                executable: atom.config.get('luaex-tools.luaExecutable'), root,
                mode: lua ? 'lua' : 'lxc', files
            });
            if (!current()) return null;
            if (!lua) {
                const index = new Index(files);
                this.indexCache.set(file, {source, index});
                diagnostics.push(...index.diagnostics());
            }
            if (!lua && path.extname(file).toLowerCase() === '.lxc') highlight.apply(editor, diagnostics.classNames);
            return diagnostics.map(item => {
                const same = project.key(item.file) === project.key(file);
                const message = {
                    severity: item.severity || 'error',
                    excerpt: (same ? '' : path.basename(item.file) + ': ') + item.message,
                    description: item.phase + (same ? '' : '\nDependency: ' + item.file + ':' + item.line),
                    location: {file, position: position(source, same ? item.line : 1)}
                };
                if (!same) message.reference = {file: item.file, position: [Math.max(0, item.line - 1), 0]};
                return message;
            });
        } catch (error) {
            if (!current()) return null;
            return [{severity: 'error', excerpt: 'LuaEx linter: ' + error.message,
                description: 'Linter configuration/process failure; this is not an application-source diagnosis.',
                location: {file, position: position(source, 1)}}];
        }
    },
    position
};


