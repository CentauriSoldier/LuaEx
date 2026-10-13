const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{
 const manifest=generate(),engine=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),()=>{});
 try{
  await engine.boot(Object.fromEntries(manifest.files.map(file=>[file,new Uint8Array(fs.readFileSync(path.join(root,file)))])));
  await engine.lua.doString('local p=Pool(120,120);p.set(0.1,Pool.ASPECT.RESERVED_PERCENT);assert(p.get()==108 and p.get(Pool.ASPECT.AVAILABLE)==108);local _,changed=p.set(120);assert(changed==false and p.get()==108)');
  let state=await engine.run('examples/visual/Pool/browser.lua',fs.readFileSync(path.join(root,'examples/visual/Pool/browser.lua'),'utf8'));
  const get=key=>Object.values(state.resources).find(r=>r.key===key);
  assert.equal(get('health').current,90);assert.equal(get('mana').current,60);assert.equal(get('stamina').current,80);
  state=await engine.action('configure',{key:'health',config:{...get('health').config,percent:10}});
  assert(!state.message.startsWith('Rejected:'));assert.equal(get('health').current,90);assert.equal(get('health').reserved,12);
  state=await engine.action('configure',{key:'health',config:{...get('health').config}});
  assert(!state.message.startsWith('Rejected:'));assert.equal(get('health').current,90);
  state=await engine.action('reset');
  state=await engine.action('fill',{key:'health'});assert.equal(get('health').current,120);
  state=await engine.action('configure',{key:'health',config:{...get('health').config,percent:10}});
  assert(!state.message.startsWith('Rejected:'));assert.equal(get('health').current,108);assert.equal(get('health').reserved,12);
  state=await engine.action('configure',{key:'health',config:{...get('health').config,current:120}});
  assert(!state.message.startsWith('Rejected:'));assert.equal(get('health').current,108);
  state=await engine.action('reset');
  state=await engine.action('spend',{key:'health',amount:25});assert.equal(get('health').current,65);assert.equal(get('mana').current,60);assert(Object.values(state.events).some(event=>event.includes('Health / decrease')));
  const config={...get('mana').config,maximum:200,current:1000,flat:20,percent:25,regen:5,regenPercent:10,bonus:0,multiplier:0};
  state=await engine.action('configure',{key:'mana',config});assert.equal(get('mana').reserved,70);assert.equal(get('mana').available,130);assert.equal(get('mana').current,130);assert.equal(get('mana').cycle,25);
  state=await engine.action('empty',{key:'mana'});assert.equal(get('mana').current,0);
  state=await engine.action('cycle',{multiplier:2});assert.equal(get('mana').current,50);assert.equal(state.tick,2);
  state=await engine.action('configure',{key:'mana',config:{...get('mana').config,flat:500}});assert(state.message.startsWith('Rejected:'));assert.equal(get('mana').reserved,70);assert.equal(get('mana').current,50);
  state=await engine.action('configure',{key:'stamina',config:{...get('stamina').config,maximum:100,bonus:20,multiplier:50,regen:-5,current:50}});assert.equal(get('stamina').maximum,180);
  state=await engine.action('cycle',{multiplier:1});assert.equal(get('stamina').current,45);
  state=await engine.action('spend',{key:'health',amount:10000});assert.equal(get('health').current,0);assert.equal(get('health').empty,true);
  state=await engine.action('fill',{key:'mana'});assert.equal(get('mana').current,130);assert.equal(get('mana').full,true);
  state=await engine.action('configure',{key:'health',config:{...get('health').config,low:80,high:20}});assert(state.message.startsWith('Rejected:'));
  state=await engine.action('reset');assert.equal(get('mana').maximum,100);assert.equal(state.tick,0);
  assert(Object.values(state.events).length>0);
  console.log('PASS visual Pool: separate resources, spending, fractional/flat reservations, clamping, modifiers, regeneration/drain, atomic rejection, thresholds, events and reset');
 }finally{engine.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
