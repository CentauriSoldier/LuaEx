const fs = require('node:fs');
const path = require('node:path');
const {generate, root} = require('./catalog.cjs');
const {LuaSession} = require('./runtime.js');
const wasmoon = require('../wasmoon/package/dist/index.js');

(async () => {
    const manifest = generate();
    const wasm = new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm')));
    const engine = new LuaSession(wasmoon, wasm, console.log);

    try {
        const files = Object.fromEntries(manifest.files.map(file => [
            file, new Uint8Array(fs.readFileSync(path.join(root, file))),
        ]));

        // This test host supplies the target math API before primitives load.
        // Product atan2 calls are left unchanged.
        const mathHook = 'LuaEx/hook/mathhook.lua';
        files[mathHook] = new TextEncoder().encode(
            'math.atan2 = math.atan2 or function(y, x) return math.atan(y, x or 1); end;\n' +
            new TextDecoder().decode(files[mathHook])
        );

        await engine.boot(files);
        await engine.lua.doFile('/tests/primitive_copy_regression.lua');
    } finally {
        engine.close();
    }
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
