const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{const m=generate(),e=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),()=>{});try{
 await e.boot(Object.fromEntries(m.files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))])));let s=await e.run('examples/visual/Stack/browser.lua',fs.readFileSync(path.join(root,'examples/visual/Stack/browser.lua'),'utf8'));const act=async(a,d={})=>s=await e.action(a,d);const top=()=>Object.values(s.items)[0];
 assert.equal(s.size,3);assert.equal(top().text,'"Save document"');await act('pop');assert.equal(top().text,'"Edit text"');await act('peek');assert.equal(s.size,2);
 await act('push',{kind:'false'});assert.equal(top().kind,'boolean');await act('peek');assert(s.message.includes('false'));await act('pop');assert(s.message.includes('false'));
 await act('push',{kind:'number',value:'3.5'});assert.equal(top().text,'3.5');await act('reverse');assert.equal(top().text,'"Open document"');await act('drain');assert.equal(s.size,0);await act('pop');assert(s.message.includes('Empty stack'));
 await act('push',{kind:'nil'});assert.equal(s.size,0);await act('push',{kind:'record',value:'move'});assert.equal(top().kind,'table');await act('push',{kind:'null'});assert.equal(s.size,2);await act('clear');assert.equal(s.size,0);await act('reset');assert.equal(s.size,3);
 console.log('PASS Stack visual: LIFO, peek without mutation, mixed values, false, nil, reverse, safe empty pop, drain, clear and reset');
 }finally{e.close();}})().catch(err=>{console.error(err);process.exitCode=1;});
