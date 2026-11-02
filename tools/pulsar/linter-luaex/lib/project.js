'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');

const ignored = new Set(['.git', '.hg', '.svn', 'node_modules', '.cache', 'legacy', 'lxc-prototype']);
const key = value => process.platform === 'win32' ? path.resolve(value).toLowerCase() : path.resolve(value);

// Find the framework without initializing it or requiring application modules.
function frameworkRoot(file, configured) {
    const valid = directory => directory && fs.existsSync(path.join(directory, 'LuaEx/lib/lxc/Parser.lua')) &&
        fs.existsSync(path.join(directory, 'LuaEx/lib/lxe/Parser.lua'));
    if (configured) {
        if (valid(path.resolve(configured))) return path.resolve(configured);
        throw new Error('Invalid linter-luaex.luaExRoot: expected a repository containing LuaEx/lib/lxc and LuaEx/lib/lxe.');
    }
    const projects = typeof atom !== 'undefined' && atom.project.getPaths ? atom.project.getPaths() : [];
    if (valid(process.env.LUAEX_ROOT)) return path.resolve(process.env.LUAEX_ROOT);
    for (const start of [path.dirname(file), __dirname, ...projects]) {
        let directory = start;
        while (true) {
            if (valid(directory)) return directory;
            const sibling = path.join(directory, 'LuaEx');
            if (valid(sibling)) return sibling;
            const parent = path.dirname(directory);
            if (parent === directory) break;
            directory = parent;
        }
    }
    const local = path.join(os.homedir(), 'Sync/Projects/GitHub/LuaEx');
    if (valid(local)) return local;
    throw new Error('Set linter-luaex.luaExRoot to the repository containing LuaEx/lib/lxc and LuaEx/lib/lxe.');
}

function inside(file, directory) {
    const relative = path.relative(directory, file);
    return relative === '' || (!relative.startsWith('..' + path.sep) && relative !== '..' && !path.isAbsolute(relative));
}

// Saved project dependencies and unsaved editor buffers form one source batch.
// Symbolic links are not followed; limits reject rather than silently omit files.
function collect(file, source, root, projectRoot, overlays = []) {
    const files = new Map();
    let bytes = 0;
    function add(filename, text) {
        const identity = key(filename);
        if (files.has(identity)) bytes -= Buffer.byteLength(files.get(identity).source);
        bytes += Buffer.byteLength(text);
        files.set(identity, {file: path.resolve(filename), source: text});
        if (files.size > 1000 || bytes > 16 * 1024 * 1024) {
            throw new Error('LXC lint batch exceeds 1,000 files or 16 MiB. Choose a smaller project root.');
        }
    }
    function visit(directory) {
        for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
            if (entry.isSymbolicLink()) continue;
            const filename = path.join(directory, entry.name);
            if (entry.isDirectory() && !ignored.has(entry.name)) visit(filename);
            else if (entry.isFile() && ['.lxc', '.lxe'].includes(path.extname(entry.name).toLowerCase())) {
                if (!files.has(key(filename))) {
                    const size = fs.statSync(filename).size;
                    if (size > 16 * 1024 * 1024) throw new Error('LXC source exceeds the lint batch limit: ' + filename);
                    add(filename, fs.readFileSync(filename, 'utf8'));
                }
            }
        }
    }
    visit(path.join(root, 'LuaEx/classes'));
    visit(projectRoot);
    for (const overlay of overlays) {
        if (['.lxc', '.lxe'].includes(path.extname(overlay.file).toLowerCase()) &&
            (inside(overlay.file, projectRoot) || inside(overlay.file, path.join(root, 'LuaEx/classes')))) {
            add(overlay.file, overlay.source);
        }
    }
    add(file, source);
    return Array.from(files.values()).sort((a, b) => a.file.localeCompare(b.file));
}

module.exports = {frameworkRoot, collect, inside, key};

