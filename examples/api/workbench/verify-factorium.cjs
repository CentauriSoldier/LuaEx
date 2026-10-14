// Execute the repository regression suite in its bundled Lua 5.4 runtime.
const fs = require('node:fs');
const path = require('node:path');
const {generate, root} = require('./catalog.cjs');
const {LuaSession} = require('./runtime.js');
const wasmoon = require('../wasmoon/package/dist/index.js');

(async () => {
    const manifest = generate();
    const wasmPath = path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm');
    const engine = new LuaSession(wasmoon, new Uint8Array(fs.readFileSync(wasmPath)), console.log);

    try {
        const files = Object.fromEntries(manifest.files.map(file => [
            file,
            new Uint8Array(fs.readFileSync(path.join(root, file))),
        ]));

        await engine.boot(files);
        await engine.lua.doFile('/tests/factorium_regression.lua');
        await engine.lua.doFile('/tests/basemod_regression.lua');
    } finally {
        engine.close();
    }
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
