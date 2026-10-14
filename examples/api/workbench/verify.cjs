const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {LuaSession} = require('./runtime.js');
const wasmoon = require('../wasmoon/package/dist/index.js');
const {generate,root} = require('./catalog.cjs');
async function session(manifest, emit) {
  const value = new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),emit);
  const files = Object.fromEntries(manifest.files.map(file => [file, new Uint8Array(fs.readFileSync(path.join(root,file)))]));
  assert.equal(await value.boot(files),'Lua 5.4');
  return value;
}
(async () => {
  const manifest = generate();
  let engine = await session(manifest,console.log);
  try {
    await engine.lua.doFile('/examples/visual/AStar/smoke.lua');
    let state = await engine.visual();
    assert.equal(state.cells.length,14); assert.equal(state.cells[0].length,20);
    assert.equal(state.hasPath,true);
    const saved = await engine.action('save');
    state = await engine.action('step'); assert.equal(state.moves,1); assert.equal(state.soldier,15);
    state = await engine.action('turn'); assert.equal(state.turn,1);
    await engine.action('tool',{tool:'WALL'});
    state = await engine.action('paint',{x:3,y:6}); assert.equal(state.cells[5][2],2);
    state = await engine.action('load',{snapshot:saved.snapshot}); assert.equal(state.moves,0);
    assert.equal(state.cells[5][2],1);
    console.log('PASS browser AStar bridge, terrain, budgets, save/restore');
  } finally {engine.close();}
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-pool.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-pot.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-protean.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-stack.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-enum.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-code.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-tiled-visual.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-baseitem.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-items.cjs')],{stdio:'inherit'});
  require('node:child_process').execFileSync(process.execPath,[path.join(__dirname,'verify-cards.cjs')],{stdio:'inherit'});
  const results = [];
  for (const entry of manifest.entries.filter(item=>item.kind !== 'visual')) {
    const cases=[{},Object.fromEntries(entry.inputs.map(field=>{
      let value=field.default;
      if(field.type==='boolean')value=!value;
      else if(field.type==='number')value=Math.min(field.max,Math.max(field.min,value+(field.name==='reservation'?0.1:1)));
      else value=field.options?field.options.find(item=>item!==value):field.name==='items'||field.name==='tags'||field.name==='left'||field.name==='right'?'oak,pine,oak':field.name==='text'?'Changed payload 42':value+' changed';
      return [field.name,value];
    }))];
    const runs=[];
    for(const inputs of cases) {
      const output=[];engine=await session(manifest,text=>output.push(text));
      try {
        await engine.run(entry.path,fs.readFileSync(path.join(root,entry.path),'utf8'),inputs);
        const summary=output.find(line=>line.includes('[SUMMARY]'));
        assert(summary,'Missing tutorial summary');
        assert(Number(summary.match(/: (\d+) sections/)[1])>=6,'Expected at least six explanatory sections');
        assert(!output.some(line=>line.includes('[FAIL]')),'Unexpected failure output');
        if(entry.id==='utilities/DoxExample.lua')assert((await engine.outputs()).some(file=>file.name.endsWith('DoxExample.html')),'Generated Dox HTML missing');
        runs.push({result:'passed',lines:output.length,summary,inputs});
      }catch(error){runs.push({result:'error',message:error.message,inputs});}
      finally{engine.close();}
    }
    results.push({id:entry.id,result:runs.every(run=>run.result==='passed')?'passed':'error',runs,...(runs.some(run=>run.result==='error')?{message:runs.find(run=>run.result==='error').message}:{})});
  }
  fs.writeFileSync(path.join(root,'examples/verification.json'),JSON.stringify(results,null,2)+'\n');
  for(const result of results)console.log(result.result.toUpperCase(),result.id,result.message||'default + changed parameters');
  assert(results.every(result=>result.result==='passed'),'An example failed in the browser Lua runtime');
})().catch(error => {console.error(error); process.exitCode = 1;});
