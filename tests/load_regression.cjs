// Current LuaEx loader contract in isolated Wasmoon Lua 5.4 engines.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {LuaFactory} = require('../examples/api/wasmoon/package/dist/index.js');
const root = path.resolve(__dirname, '..');
const wasm = new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm')));
const files = {};
let cases = 0;

function collect(directory) {
    for (const entry of fs.readdirSync(path.join(root, directory), {withFileTypes: true})) {
        const relative = directory + '/' + entry.name;
        if (entry.isDirectory()) collect(relative);
        else if (/\.(lua|lxc|lxe)$/.test(relative)) files['/' + relative] = fs.readFileSync(path.join(root, relative));
    }
}
collect('LuaEx');

async function run(code) {
    const factory = new LuaFactory('/embedded-lua.wasm', undefined, wasm);
    for (const [name, bytes] of Object.entries(files)) await factory.mountFile(name, bytes);
    const engine = await factory.createEngine({injectObjects: false, enableProxy: false});
    try {
        engine.global.set('__loader_files', Object.keys(files));
        await engine.doString(`
            package.path = '/?.lua';
            local files = __loader_files;
            -- Wasmoon has a virtual filesystem, not a native process shell.
            -- Install virtual directory operations when the real I/O hooks load.
            package.preload['LuaEx.hook.iohook'] = function()
                local io = assert(loadfile('/LuaEx/hook/iohook.lua'))();
                local function normalize(path)
                    path = path:gsub('\\\\', '/'):gsub('/%./', '/');
                    while path:find('/[^/]+/%.%./') do path = path:gsub('/[^/]+/%.%./', '/'); end
                    return path:gsub('/+$', '')..'/';
                end
                io.isdir = function(path)
                    local prefix = normalize(path);
                    for _, file in pairs(files) do if file:sub(1, #prefix) == prefix then return true; end; end
                    return false;
                end;
                io.listfiles = function(directory, recursive, callback, extension)
                    local prefix, result = normalize(directory), {};
                    for _, file in pairs(files) do
                        local relative = file:sub(#prefix + 1);
                        if file:sub(1, #prefix) == prefix and (recursive or not relative:find('/')) and
                            (not extension or file:sub(-#extension - 1) == '.'..extension) then
                            result[#result + 1] = file;
                        end
                    end
                    table.sort(result);
                    if callback then for _, file in ipairs(result) do callback(file); end; end
                    return result;
                end;
                return io;
            end;
            local nativeType, oldPath = type, package.path;
            local init = require('LuaEx.load');
            assert(nativeType(init) == 'function' and luaex == nil and LUAEX_INIT == nil);
            assert(type == nativeType and package.path == oldPath);
            ${code}
        `);
        cases++;
    } finally {
        engine.global.close();
    }
}

(async () => {
    assert(Object.keys(files).some(name => name.endsWith('.lxc')), 'Native declarations must be mounted.');
    for (let level = 0; level <= 5; level++) {
        await run(`
            local environment = init(${level});
            assert(environment == luaex and LUAEX_INIT and not luaex.__isbooting);
            assert((class ~= nil) == (${level} >= 1));
            assert((Stack ~= nil) == (${level} >= 2));
            assert((Protean ~= nil) == (${level} >= 3));
            assert((VFS ~= nil) == (${level} >= 4));
            assert(CoG == nil and Dox == nil);
            assert(package.path == oldPath and init(99) == environment);
            assert(require('LuaEx.load') == init);
        `);
    }
    for (const args of ['', 'nil']) await run(`assert(init(${args}) == luaex and VFS ~= nil); assert(package.path == oldPath);`);
    await run(`
        for _, value in ipairs({-1, 6, 0.5, math.huge, false, '2', {}}) do
            assert(not pcall(init, value));
            assert(luaex == nil and LUAEX_INIT == nil and package.path == oldPath);
        end
        assert(not pcall(init, 0/0) and not pcall(init, 0, 4));
        assert(luaex == nil and package.path == oldPath);
        init(0);
    `);
    await run(`
        local original = debug;
        debug = nil;
        assert(not pcall(init, 0));
        assert(luaex == nil and LUAEX_INIT == nil and package.path == oldPath);
        debug = original;
        init(0);
    `);
    console.log('PASS browser loader: ' + cases + ' isolated current-API cases, levels 0–5, defaults, invalid options, retry and discovery.');
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
