const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{const m=generate(),e=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),()=>{});try{
 await e.boot(Object.fromEntries(m.files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))])));let s=await e.run('examples/visual/Potentiometer/browser.lua',fs.readFileSync(path.join(root,'examples/visual/Potentiometer/browser.lua'),'utf8'));const get=k=>Object.values(s.items).find(p=>p.key===k);
 s=await e.action('configure',{min:0,max:10,position:10,rate:1});s=await e.action('increase',{amount:1});assert.equal(get('clamp').position,10);assert.equal(get('wrap').position,0);assert.equal(get('bounce').position,9);assert.equal(get('bounce').direction,'Descending');
 s=await e.action('increase',{amount:2});assert.equal(get('bounce').position,7);s=await e.action('adjust',{amount:1});assert.equal(get('bounce').position,8);
 s=await e.action('configure',{min:-2,max:2,position:1.5,rate:.5});s=await e.action('increase',{amount:2});assert.equal(get('bounce').position,1.5);
 s=await e.action('configure',{min:5,max:2,position:0,rate:1});assert(s.message.startsWith('Rejected:'));assert.equal(get('bounce').position,1.5);
 s=await e.action('reset');assert.equal(get('clamp').position,5);console.log('PASS Potentiometer visual: clamp, inclusive wrap, bounce direction, signed adjustment, fractions, rejected settings and reset');
 }finally{e.close();}})().catch(err=>{console.error(err);process.exitCode=1;});
