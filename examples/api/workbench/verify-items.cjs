const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{
 const manifest=generate();assert.equal(manifest.entries.filter(e=>e.group==='CoG').length,10);assert.equal(manifest.entries.find(e=>e.id==='components/ItemSlotSystem.lua').visualType,'items');
 const engine=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),()=>{});
 try{
  await engine.boot(Object.fromEntries(manifest.files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))])));
  let s=await engine.run('examples/visual/ItemSystem/browser.lua',fs.readFileSync(path.join(root,'examples/visual/ItemSystem/browser.lua'),'utf8'));
  const arr=v=>Array.isArray(v)?v:Object.values(v||{}),item=id=>arr(s.items).find(i=>i.id===id),coins=key=>arr(s.actors).find(a=>a.key===key).coins;
  const act=async(a,d={})=>{s=await engine.action(a,d);return s};
  assert.equal(s.totals.live,20);assert.equal(s.totals.character,6);assert.equal(s.totals.stash,6);assert.equal(s.totals.shop,4);assert.equal(s.grid,true);
  await act('tab',{tab:2});await act('move',{id:10,destination:'stash'});assert.equal(s.ok,false);assert.equal(item(10).where,'shop');assert.equal(s.totals.stash,6);
  const c=structuredClone(item(10).config);c.storage='Shop only';await act('edit',{id:10,config:c});assert(s.ok);const cash=coins('player');await act('buy',{id:10,destination:'character',slot:13});assert(!s.ok);assert.equal(coins('player'),cash);assert.equal(item(10).where,'shop');
  c.storage='Anywhere';await act('edit',{id:10,config:c});assert(s.ok);await act('buy',{id:10,destination:'stash'});assert(!s.ok);assert.equal(coins('player'),cash);
  await act('buy',{id:10,destination:'character',slot:13});assert(s.ok);assert.equal(item(10).owner,'player');assert.equal(coins('player'),cash-70);
  await act('move',{id:10,destination:'stash'});assert(!s.ok);assert.equal(item(10).where,'character');
  await act('delete',{id:9});assert(s.ok);await act('move',{id:10,destination:'stash'});assert(s.ok);assert.equal(item(10).index,2);
  await act('damage',{id:1,amount:500});assert(s.ok);assert.equal(item(1).health,0);assert(item(1));await act('repair',{id:1,amount:20});assert.equal(item(1).health,20);
  await act('actor',{key:'visitor'});await act('upgrade',{id:1});assert(!s.ok);await act('actor',{key:'player'});await act('upgrade',{id:1});assert(s.ok);assert.equal(item(1).maximum,105);
  const sword=structuredClone(item(1).config);sword.pattern='0,0;1,0;2,0';await act('edit',{id:1,config:sword});assert(!s.ok);assert.equal(item(1).config.pattern,'0,0;1,0');
  const quest=structuredClone(item(12).config);quest.storage='Nowhere';await act('edit',{id:12,config:quest});assert(!s.ok);assert.equal(item(12).config.storage,'Player storage');
  await act('actor',{key:'player'});await act('equip',{id:17,slot:16});assert(!s.ok);assert.equal(item(17).where,'shop');
  await act('unplace',{id:13});assert(s.ok);await act('attach',{id:13,host:1});assert(s.ok);assert.equal(item(13).where,'attached');await act('move',{id:13,destination:'ground'});assert(!s.ok);await act('detach',{id:13});assert(s.ok);assert.equal(item(13).where,'unplaced');
  await act('clone',{id:11});assert(!s.ok);await act('clone',{id:11,override:true});assert(s.ok);const copy=s.selectedID;assert.equal(item(copy).where,'unplaced');await act('delete',{id:copy});assert(s.ok);
  await act('grid',{enabled:false});assert(s.ok);await act('move',{id:4,destination:'character',slot:3});assert(s.ok);assert.equal(arr(s.slots)[2].count,2);
  await act('consume',{id:3});assert(s.ok);assert.equal(arr(s.slots)[2].count,1);assert.equal(item(3),undefined);assert(item(4));
  const draft={...s.defaults,name:'Custom test item',value:7,owner:'player'};await act('create',{config:draft,destination:'ground'});assert(s.ok);const created=s.selectedID;assert.equal(item(created).name,'Custom test item');
  await act('move',{id:created,destination:'character',slot:16});assert(s.ok);await act('swap',{id:created,slot:15});assert(s.ok);assert.equal(item(created).index,15);
  await act('container',{key:'ground',enabled:true,locked:true});await act('move',{id:created,destination:'ground'});assert(!s.ok);assert.equal(item(created).where,'character');await act('container',{key:'ground',enabled:true,locked:false});
  await act('capacity',{key:'shop',capacity:1});assert(!s.ok);assert.equal(s.capacities.shop,12);
  await act('addTab');assert(s.ok);assert.equal(arr(s.tabs).length,4);await act('removeTab');assert(s.ok);assert.equal(arr(s.tabs).length,3);
  await act('clear',{key:'ground'});assert(s.ok);assert.equal(s.totals.ground,0);await act('validate');assert(s.ok);
  await act('reset');assert.equal(s.totals.live,20);assert.equal(coins('player'),120);assert.equal(s.grid,true);
  console.log('PASS item-system visual: 20 seeds, all contexts, whole-stash exclusivity, atomic trading/wallets, permissions, edits/rollback, grid and stacks, single-instance consumption, attachments, cloning, deletion, creation, capacity, locks, swaps, tab management and reset');
 }finally{engine.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
