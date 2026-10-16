const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{
 const manifest=generate();assert.equal(manifest.entries.length,29);assert(!manifest.entries.some(e=>e.group==='Visual examples'||e.title==='PoolBasics'));
 assert.equal(manifest.entries.filter(e=>e.visualPath).length,11);
 for(const entry of manifest.entries){
  const engine=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),()=>{});
  try{
   await engine.boot(Object.fromEntries(manifest.files.map(file=>[file,new Uint8Array(fs.readFileSync(path.join(root,file)))])));
   const source=fs.readFileSync(path.join(root,entry.codePath),'utf8');assert(!source.includes('D.input('));
   await engine.run(entry.codePath,source);console.log('PASS code',entry.id);
  }finally{engine.close();}
 }
})().catch(error=>{console.error(error);process.exitCode=1;});
