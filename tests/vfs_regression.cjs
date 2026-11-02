// Run VFS and listing regressions in isolated Lua engines without native writes.
const fs = require('node:fs');
const path = require('node:path');
const {LuaFactory} = require('../examples/api/wasmoon/package/dist/index.js');
const root = path.resolve(__dirname, '..');
const wasm = new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm')));

async function run(file) {
    const factory = new LuaFactory('/embedded-lua.wasm', undefined, wasm);
    const files = {};

    async function mount(directory) {
        for (const entry of fs.readdirSync(path.join(root, directory), {withFileTypes: true})) {
            const relative = directory + '/' + entry.name;
            if (entry.isDirectory()) await mount(relative);
            else if (/\.(lua|lxc|lxe)$/.test(relative)) {
                files[relative.toLowerCase()] = '/' + relative;
                await factory.mountFile('/' + relative, fs.readFileSync(path.join(root, relative)));
            }
        }
    }

    await mount('LuaEx');
    await mount('examples/support');
    await factory.mountFile('/' + file, fs.readFileSync(path.join(root, file)));
    const engine = await factory.createEngine({injectObjects: false, enableProxy: false});

    try {
        engine.global.set('__regression_files', files);
        await engine.doString(`
            package.path = '/?.lua';
            local files = __regression_files;
            table.insert(package.searchers, 2, function(name)
                local file = files[(name:gsub('%.', '/')..'.lua'):lower()];
                if file then return assert(loadfile(file)), file; end
            end);
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
            require('LuaEx.load')(4);
            -- Later listing checks reload the real hooks with their own fake pipes.
            package.preload['LuaEx.hook.iohook'] = nil;
        `);
        await engine.doFile('/' + file);
    } finally {
        engine.global.close();
    }
}

(async () => {
    await run('tests/vfs_regression.lua');
    await run('tests/io_listing_regression.lua');
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
