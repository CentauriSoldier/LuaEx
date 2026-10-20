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
            else if (relative.endsWith('.lua')) {
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
