'use strict';
const path = require('path');
const installation = require('../installation.json');
const {Runner} = require('./runner');
const project = require('./project');
const highlight = require('./highlight');

function position(text, line) {
    const lines = text.split(/\r?\n/);
    const row = Math.max(0, Math.min(lines.length - 1, (Number(line) || 1) - 1));
    const start = Math.max(0, lines[row].search(/\S/));
    return [[row, start], [row, lines[row].length]];
}

module.exports = {
    config: {
        luaExecutable: {type: 'string', default: installation.luaExecutable || '', description: 'Lua 5.4 executable. Empty searches LUA54, the local portable Lua 5.4 folder, and PATH.'},
        luaExRoot: {type: 'string', default: installation.luaExRoot || '', description: 'Repository containing LuaEx/lxc/modules. Empty searches ancestors of the file/package.'},
        projectRoot: {type: 'string', default: '', description: 'LXC source root. Empty uses the Pulsar project root, limited to the LuaEx repository for files inside it.'},
        delegateLua: {type: 'boolean', default: true, description: 'Let active linter-lua handle ordinary .lua files. Disable to use this package\'s Lua 5.4 syntax checks instead.'}
    },

    activate() { this.runner = new Runner(); this.revisions = new Map(); this.active = true; },
    deactivate() { this.active = false; if (this.runner) this.runner.dispose(); this.revisions = new Map(); },

    provideLinter() {
        if (!this.runner) this.activate();
        return {
            name: 'LXC / Lua 5.4', scope: 'file', lintsOnChange: true,
            grammarScopes: ['source.lxc', 'source.lua', 'text.plain'],
            lint: editor => this.lint(editor)
        };
    },

    async lint(editor) {
        const file = editor.getPath();
        if (!file || !/\.(lua|lxc)$/i.test(file)) return [];
        const lua = path.extname(file).toLowerCase() === '.lua';
        if (lua && atom.config.get('linter-lxc.delegateLua') && atom.packages.isPackageActive('linter-lua')) return [];
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
                root = project.frameworkRoot(file, atom.config.get('linter-lxc.luaExRoot'));
                const selected = atom.config.get('linter-lxc.projectRoot') ||
                    (project.inside(file, root) ? root : atom.project.relativizePath(file)[0]) || path.dirname(file);
                files = project.collect(file, source, root, path.resolve(selected), snapshots);
            }
            const diagnostics = await this.runner.lint({
                executable: atom.config.get('linter-lxc.luaExecutable'), root,
                mode: lua ? 'lua' : 'lxc', files
            });
            if (!current()) return null;
            if (!lua) highlight.apply(editor, diagnostics.classNames);
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
            return [{severity: 'error', excerpt: 'LXC linter: ' + error.message,
                description: 'Linter configuration/process failure; this is not an application-source diagnosis.',
                location: {file, position: position(source, 1)}}];
        }
    },
    position
};
