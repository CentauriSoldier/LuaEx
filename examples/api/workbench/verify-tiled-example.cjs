const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {generate, root} = require('./catalog.cjs');
const {LuaSession} = require('./runtime.js');
const wasmoon = require('../wasmoon/package/dist/index.js');

(async () => {
    const manifest = generate();
    const entry = manifest.entries.find(item => item.id === 'cog/Tiled.lua');
    assert(entry && entry.group === 'CoG');
    const runs = [];
    for (const sourcePath of [entry.path, entry.codePath]) {
        const output = [];
        const engine = new LuaSession(wasmoon, new Uint8Array(fs.readFileSync(path.join(root, 'examples/api/wasmoon/package/dist/glue.wasm'))), text => output.push(text));
        try {
            await engine.boot(Object.fromEntries(manifest.files.map(file => [file, new Uint8Array(fs.readFileSync(path.join(root, file)))])));
            await engine.run(sourcePath, fs.readFileSync(path.join(root, sourcePath), 'utf8'));
            assert(output.filter(line => /^\[\d+\]/.test(line.trimStart())).length >= 6);
            const summary = output.find(line => line.includes('[SUMMARY]'));
            assert(summary);
            runs.push({result: 'passed', lines: output.length, summary, inputs: {}});
            console.log('PASS', sourcePath, summary);
        } finally {
            engine.close();
        }
    }
    const resultPath = path.join(root, 'examples/verification.json');
    const results = JSON.parse(fs.readFileSync(resultPath, 'utf8')).filter(item => item.id !== entry.id);
    results.push({id: entry.id, result: 'passed', runs});
    fs.writeFileSync(resultPath, JSON.stringify(results, null, 2) + '\n');
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
