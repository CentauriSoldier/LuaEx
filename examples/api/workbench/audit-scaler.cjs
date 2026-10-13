const fs=require('node:fs'),path=require('node:path');const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{const m=generate(),e=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),console.log);try{await e.boot(Object.fromEntries(m.files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))])));await e.lua.doString(`
local ok,why=pcall(Scaler,100,100,200,100,false);print('Actual constructor:',ok,why);
local file=assert(io.open('/LuaEx/inc/cog/Scaler.lua','r'));local source=file:read('*a');file:close();
-- Isolate later behavior by correcting only the obsolete fitrect call in memory.
source=source:gsub('Scaler','ScalerAudit'):gsub(', 1, true%)',', true)');
local Review=assert(load(source,'Scaler review'))();
local scaler=Review(100,100,200,100,false);
local rect=scaler.adjust({x=0,y=0,width=10,height=10});local pos=scaler.adjustPos(0,0);
print('Windowed rectangle vs position:',rect.x,pos.x);
local size=scaler.getScreenSize();local viewport=scaler.getViewport();print('Reported screen:',size.width,size.height,'viewport:',viewport.width,viewport.height,'actual screen: 200 100');
local fired=false;scaler.setOnResizeCallback(function() fired=true end);scaler.onResize(400,300);size=scaler.getScreenSize();print('Resize callback fired:',fired,'size after resize:',size.width,size.height);
local invalid=scaler.adjustSize(math.huge,10);print('Infinite output accepted:',invalid.width);
local truthy=Review(100,100,200,100,'false');print('String fullscreen flag accepted, adjusted origin:',truthy.adjust({x=0,y=0,width=1,height=1}).x);
`);}finally{e.close()}})().catch(err=>{console.error(err);process.exitCode=1});
