const fs = require('node:fs');
const path = require('node:path');
const {generate, root} = require('./catalog.cjs');
const {LuaSession} = require('./runtime.js');
const wasmoon = require('../wasmoon/package/dist/index.js');

(async () => {
    const manifest = generate();
    const wasm = new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm')));

    // Separate runtimes verify both shipped empty config and configured status behavior.
    for (const configured of [false, true]) {
        const engine = new LuaSession(wasmoon, wasm, console.log);

        try {
            const files = Object.fromEntries(manifest.files.map(file => [
                file, new Uint8Array(fs.readFileSync(path.join(root, file))),
            ]));

            if (configured) {
                files['LuaEx/inc/cog/config/StatusTracker.lua'] = new TextEncoder().encode(
                    'return { EFFECT = { "TIMED", "FOREVER" } };'
                );
            }

            await engine.boot(files);

            if (configured) {
                await engine.lua.doFile('/tests/statustracker_regression.lua');
            } else {
                await engine.lua.doString(`
                    local tracker = StatusTracker();
                    assert(type(tracker) == "StatusTracker" and #tracker == 0);
                    assert(tracker.cycle() == 0 and tracker.clear() == 0);
                    assert(next(StatusTracker.EFFECT) == nil);
                    assert(tracker.eachStatus()() == nil);
                    assert(#deserialize(serialize(tracker)) == 0);
                `);
                console.log('PASS StatusTracker: empty default configuration');
            }
        } finally {
            engine.close();
        }
    }
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
