const fs=require('node:fs'),path=require('node:path');const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{const manifest=generate(),engine=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),console.log);try{
 await engine.boot(Object.fromEntries(manifest.files.map(file=>[file,new Uint8Array(fs.readFileSync(path.join(root,file)))])));
 await engine.lua.doFile('/tests/objectregistry_regression.lua');
 await engine.lua.doFile('/tests/registry_regression.lua');
 }finally{engine.close();}})().catch(error=>{console.error(error);process.exitCode=1;});
