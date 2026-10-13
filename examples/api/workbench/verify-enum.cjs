const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{const m=generate(),e=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),()=>{});try{
 await e.boot(Object.fromEntries(m.files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))])));let s=await e.run('examples/visual/Enum/browser.lua',fs.readFileSync(path.join(root,'examples/visual/Enum/browser.lua'),'utf8'));const act=async(a,d={})=>s=await e.action(a,d);
 assert.equal(s.count,3);await act('previous',{wrap:false});assert.equal(s.index,1);assert(s.message.includes('nil'));await act('previous',{wrap:true});assert.equal(s.index,3);await act('sum',{index:1});assert(s.message.includes('60'));
 await act('set',{id:3});await act('compare',{index:2});assert(s.message.includes('identity equal: false'));assert(s.message.includes('Payload equal: true'));
 await act('set',{id:4});assert.equal(Object.values(s.items)[1].payload,'false');await act('mutate');assert(s.message.includes('rejection'));await act('set',{id:1});await act('snapshot');assert(s.message.includes('identity: true'));await act('clone');assert(s.message.includes('true'));
 await act('build',{names:'LOW,MIDDLE,HIGH',value1:'3',value2:'6',value3:'9'});assert.equal(s.active,5);await act('sum',{index:3});assert(s.message.includes('12'));
 await act('build',{names:'A,A,C',value1:'1',value2:'2',value3:'3'});assert(s.message.includes('rejection'));assert.equal(s.active,5);
 console.log('PASS enum visual: boundaries, wrapping, arithmetic, duplicate payload identity, false, protection, canonical snapshots, cloning and validated custom definitions');
 }finally{e.close();}})().catch(err=>{console.error(err);process.exitCode=1;});
