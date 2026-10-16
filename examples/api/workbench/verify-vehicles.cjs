// Exercise real Lua objects and expected failures through the browser session API.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {generate, root} = require('./catalog.cjs');
const {LuaSession} = require('./runtime.js');
const wasmoon = require('../wasmoon/package/dist/index.js');
(async () => {
  const manifest = generate();
  const lines = [];
  const engine = new LuaSession(wasmoon, new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm'))), line => lines.push(line));
  try {
    await engine.boot(Object.fromEntries(manifest.files.map(file => [file, new Uint8Array(fs.readFileSync(path.join(root, file)))])));
    const file = 'examples/visual/Vehicles/browser.lua';
    let state = await engine.run(file, fs.readFileSync(path.join(root, file), 'utf8'));
    assert.equal(state.fleet.length, 3);
    assert.equal(state.selected.fuel, 60);
    state = await engine.action('drive', {distance:40});
    assert.equal(state.selected.fuel, 50);
    assert.equal(state.selected.distance, 40);
    state = await engine.action('drive', {distance:100000});
    assert.match(state.message, /^Rejected:/);
    assert.equal(state.selected.fuel, 50);
    assert.equal(state.selected.distance, 40);
    const slot = state.selected.components[0].slot;
    await engine.action('component', {slot, operation:'share'});
    await engine.action('component', {slot, operation:'damage'});
    state = await engine.action('select', {id:2});
    assert.equal(state.selected.components[0].condition, 75);
    state = await engine.action('clone');
    assert.equal(state.fleet.length, 4);
    assert.match(state.message, /^Concrete clone:/);
    await engine.action('component', {slot, operation:'damage'});
    state = await engine.action('select', {id:2});
    assert.equal(state.selected.components[0].condition, 75);
    for (const test of ['speed','flag','fuel','slot','component']) {
      state = await engine.action('invalid', {test});
      assert.match(state.message, /^Expected validation rejection:/);
    }
    state = await engine.action('snapshot'); assert.match(state.message, /^PASS:/);
    state = await engine.action('baseclone'); assert.match(state.message, /^Expected base clone rejection:/);
    state = await engine.action('event'); assert.match(state.message, /^Inspection callback #1\./);
    state = await engine.action('serialize'); assert.match(state.message, /^Current native serialization limitation:/);
    state = await engine.action('tag', {tag:'research'}); assert(state.selected.tags.includes('RESEARCH'));
    const settings = {...state.selected, name:'Edited airship', unowned:true};
    state = await engine.action('rebuild', settings);
    assert.match(state.message, /^Constructed a replacement/);
    assert.equal(state.selected.name, 'Edited airship');
    assert.equal(state.selected.owner, 'Unowned');
    state = await engine.action('rebuild', {...settings, environment:'ExampleGarageWorkshop'});
    state = await engine.action('event');
    assert.equal(state.selected.inspections, 1);
    assert.equal(state.selected.lastEnvironment, 'Framework default environment');
    state = await engine.action('clone');
    assert.equal(state.selected.inspections, 0);
    assert.equal(state.selected.environment, 'ExampleGarageWorkshop');
    state = await engine.action('event');
    assert.equal(state.selected.lastEnvironment, 'Framework default environment');
    state = await engine.action('rebuild', {...settings, speed:-1});
    assert.match(state.message, /^Rejected:/);
    assert.equal(state.selected.speed, settings.speed);
    state = await engine.action('reserve', {amount:10}); assert.equal(state.selected.reserved, 10);
    state = await engine.action('reserve', {amount:10000}); assert.match(state.message, /^Rejected:/);
    assert.equal(state.selected.reserved, 10);
    state = await engine.action('component', {slot, operation:'remove'}); assert.equal(state.selected.components[0].installed, false);
    state = await engine.action('component', {slot, operation:'install'}); assert.equal(state.selected.components[0].condition, 100);
    state = await engine.action('fuel', {amount:10000}); assert.equal(state.selected.fuel, state.selected.available);
    state = await engine.action('reset'); assert.equal(state.fleet.length, 3); assert.equal(state.selected.distance, 0);
    console.log('PASS vehicle actions: trips, atomic rejections, shared components, independent clone, flags, ownership, tags, event dispatch and persistence probe.');
  } finally { engine.close(); }
  // Tutorials have their own session, matching the Code tab's independent state.
  const code = new LuaSession(wasmoon, new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm'))), line => lines.push(line));
  try {
    await code.boot(Object.fromEntries(manifest.files.map(file => [file, new Uint8Array(fs.readFileSync(path.join(root, file)))])));
    const file = 'examples/code/cog/Vehicles.lua';
    await code.run(file, fs.readFileSync(path.join(root, file), 'utf8'));
    const summary = lines.find(line => line.includes('[SUMMARY] Vehicles'));
    assert(summary);
    console.log(summary);
    const verificationPath = path.join(root, 'examples/verification.json');
    const verification = JSON.parse(fs.readFileSync(verificationPath, 'utf8')).filter(item => item.id !== 'cog/Vehicles.lua');
    verification.push({id:'cog/Vehicles.lua', result:'passed', runs:[{result:'passed', lines:lines.length, summary, inputs:{}}]});
    fs.writeFileSync(verificationPath, JSON.stringify(verification, null, 2) + '\n');
  } finally { code.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
