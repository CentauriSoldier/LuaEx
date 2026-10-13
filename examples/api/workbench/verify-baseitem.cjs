const fs=require('node:fs'),path=require('node:path');const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{const m=generate(),e=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),console.log);try{
 await e.boot(Object.fromEntries(m.files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))])));
 await e.lua.doFile('/tests/baseitem_regression.lua');
 await e.lua.doFile('/tests/basecreature_regression.lua');
 await e.lua.doFile('/tests/card_system_regression.lua');
 await e.lua.doFile('/tests/shuffler_regression.lua');
 await e.lua.doFile('/tests/slotpattern_regression.lua');
 await e.lua.doFile('/tests/itemslot_regression.lua');
 await e.lua.doFile('/tests/itemsystem_regression.lua');
 }finally{e.close();}})().catch(err=>{console.error(err);process.exitCode=1;});
