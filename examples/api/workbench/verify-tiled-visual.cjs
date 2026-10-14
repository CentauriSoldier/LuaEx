const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {generate, root} = require('./catalog.cjs');
const {LuaSession} = require('./runtime.js');
const wasmoon = require('../wasmoon/package/dist/index.js');
const list = value => Array.isArray(value) ? value : Object.values(value || {});

(async () => {
    const manifest = generate();
    const engine = new LuaSession(wasmoon, new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm'))), () => {});
    try {
        await engine.boot(Object.fromEntries(manifest.files.map(file => [file, new Uint8Array(fs.readFileSync(path.join(root, file)))])));
        await engine.run('examples/visual/Tiled/browser.lua', fs.readFileSync(path.join(root, 'examples/visual/Tiled/browser.lua'), 'utf8'));
        for (const sample of ['square', 'hex-flat', 'hex-pointy']) {
            let state = await engine.action('map', {sample});
            state = await engine.action('creature', {creature: 'SCOUT'});
            assert.equal(state.visual, 'tiled');
            assert.equal(list(state.cells).length, 35);
            assert.equal(state.cavesAllowed, false);
            assert.equal(state.hasPath, true);
            const scoutCost = state.cost;
            state = await engine.action('creature', {creature: 'GOBLIN'});
            assert.equal(state.cavesAllowed, true);
            assert.equal(state.hasPath, true);
            assert(state.cost < scoutCost, 'The goblin cave route should be cheaper.');
            const route = list(state.route);
            assert(route.some((cell, index) => index > 0 && Math.abs(cell.x - route[index - 1].x) >= 4), 'Route must actually traverse the cave port.');
            state = await engine.action('responses', {affinity: 0.25, aversion: 0.75});
            const mud = list(state.cells).find(cell => cell.x === 1 && cell.y === 2);
            assert.equal(mud.cost, 13.75);
            let guard = 0;
            while (!state.complete && guard++ < 30) {
                const before = state.moves;
                state = await engine.action('step');
                if (state.moves === before) state = await engine.action('turn');
            }
            assert.equal(state.complete, true);
            assert.equal(state.rover.x, state.goal.x);
            assert.equal(state.rover.y, state.goal.y);
            const saved = await engine.action('save');
            assert(saved.xml.includes('GOBLIN') && saved.xml.includes('ports'));
            state = await engine.action('tool', {tool: 'grass'});
            state = await engine.action('cell', {x: 3, y: 2});
            assert.equal(list(state.cells).find(cell => cell.x === 3 && cell.y === 2).gid, 1);
            assert.equal(state.moves, 0);
            state = await engine.action('tool', {tool: 'goal'});
            state = await engine.action('cell', {x: 4, y: 2});
            assert.equal(state.goal.x, 4);
            state = await engine.action('reset');
            assert.equal(list(state.cells).find(cell => cell.x === 3 && cell.y === 2).gid, 3);
            console.log('PASS visual Tiled', sample, 'native costs, cave permissions, movement, editing and export');
        }
    } finally {
        engine.close();
    }
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
