const fs = require('node:fs');
const path = require('node:path');
const {generate, root} = require('./catalog.cjs');
const {LuaSession} = require('./runtime.js');
const wasmoon = require('../wasmoon/package/dist/index.js');

(async () => {
    const manifest = generate();
    const wasm = new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm')));

    // Separate runtimes verify both shipped empty config and the user config hierarchy.
    for (const configured of [false, true]) {
        const engine = new LuaSession(wasmoon, wasm, console.log);

        try {
            const files = Object.fromEntries(manifest.files.map(file => [
                file, new Uint8Array(fs.readFileSync(path.join(root, file))),
            ]));

            if (configured) {
                files['tests/status_config.lua'] = new TextEncoder().encode(`
                    return { StatusTracker = { ALL_THINGS = {
                        PEOPLE = { "TIMED", "FOREVER", "CONFUSED" },
                        VEHICLES = { SHIPS = { "DAMAGED" } },
                        WEAPONS = { ONE_HANDED = { "DULL" }, TWO_HANDED = { "DULL" } },
                    } } };
                `);
                // Supply user-directory options without changing the shared runtime loader.
                const configPath = 'LuaEx/inc/cog/config.lua';
                const configSource = new TextDecoder().decode(files[configPath]);
                files[configPath] = new TextEncoder().encode(
                    'local sModule = ...; return (function(...)\n' + configSource +
                    '\nend)(sModule, {userDirectory="/tests", userFilename="status_config.lua"});'
                );
            }

            await engine.boot(files);

            if (configured) {
                await engine.lua.doFile('/tests/statustracker_regression.lua');
            } else {
                await engine.lua.doString(`
                    assert(StatusTracker.EFFECT == nil and StatusTracker.ALL_THINGS == nil);
                    assert(not pcall(StatusTracker));
                    assert(not pcall(StatusTracker, {}));
                    assert(rawequal(clone(StatusTracker), StatusTracker));
                    assert(rawequal(deserialize(serialize(StatusTracker)), StatusTracker));
                `);
                console.log('PASS StatusTracker: empty default configuration requires a configured scope');
            }
        } finally {
            engine.close();
        }
    }
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});