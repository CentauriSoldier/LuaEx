const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');const {generate,root}=require('../examples/api/workbench/catalog.cjs'),wasmoon=require('../examples/api/wasmoon/package/dist/index.js');
const wasm=new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm')));
const files=Object.fromEntries(generate().files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))]));
async function run(code,extra={}){const all={...files,...extra},factory=new wasmoon.LuaFactory('/embedded-lua.wasm',undefined,wasm);for(const [name,bytes]of Object.entries(all))await factory.mountFile('/'+name,bytes);const e=await factory.createEngine({injectObjects:false,enableProxy:false});try{e.global.set('__files',Object.fromEntries(Object.keys(all).map(n=>[n.toLowerCase(),'/'+n])));await e.doString(`package.path='/?.lua;/LuaEx/?.lua'; local files=__files; table.insert(package.searchers,2,function(name) local file=files[(name:gsub('%.','/')..'.lua'):lower()]; if file then return assert(loadfile(file)),file end return '\\nNo mounted module '..name end); local nativeType=type; local oldPath=package.path; local init=require('LuaEx.load'); assert(nativeType(init)=='function'); assert(luaex==nil and LUAEX_INIT==nil and type==nativeType and package.path==oldPath); ${code}`);}finally{e.global.close();}}
(async()=>{
for(let level=0;level<=6;level++)await run(`local env=init(nil,${level}); assert(env==luaex and LUAEX_INIT and not luaex.__isbooting); assert(package.path==oldPath); assert((class~=nil)==(${level}>=1)); assert((Queue~=nil)==(${level}>=2)); assert((Protean~=nil)==(${level}>=3)); assert((Dox~=nil)==(${level}>=4)); assert((Point~=nil)==(${level}>=5)); assert((CoG~=nil)==(${level}>=6)); assert(init(99,0)==env); assert(require('LuaEx.load')==init);`);
for(const args of ['', 'nil', 'nil,nil'])await run(`assert(init(${args})==luaex); assert(CoG~=nil and Dox~=nil);`);
for(const invalid of ['-1','7','0.5','math.huge','0/0','false','"6"','{}'])await run(`assert(not pcall(init,0,${invalid})); assert(luaex==nil and LUAEX_INIT==nil and package.path==oldPath); init(0,0);`);
for(const invalid of ['-1','0.5','math.huge','0/0','false','"1"','{}'])await run(`assert(not pcall(init,${invalid},6)); assert(luaex==nil and LUAEX_INIT==nil); init(0,0);`);
await run(`assert(not pcall(init,0,6,true)); assert(luaex==nil); init(false,0);`);
await run(`local ok,why=pcall(init,1,6); assert(not ok and tostring(why):find('Unable to load CoG user config',1,true)); assert(package.path==oldPath and not LUAEX_INIT);`);
// User configs now provide section overlays; no copied default sections are required.
for(let n=1;n<=3;n++){
 const prefix=['','LuaEx/inc/','LuaEx/',''][n];
 const extra={[prefix+'config.lua']:Buffer.from('assert(package.loaded["LuaEx.inc.cog.config.Pool"]); userConfigCalls=(userConfigCalls or 0)+1; return {app=setmetatable({ relocated=true}, {__purge=true}), MyGame=setmetatable({ enabled=false}, {__purge=true})}')};
 await run(`init(${n}); assert(luaex.cog.config.app.relocated and luaex.cog.config.app.path==nil); assert(luaex.cog.config.Pool.reservationMax>0); assert(luaex.cog.config.MyGame.enabled==false); assert(require('LuaEx.inc.cog.config').app.relocated); assert(userConfigCalls==1); init(0); assert(userConfigCalls==1 and package.path==oldPath);`,extra);
}
await run(`init(); assert(luaex.cog.config.app.name=='');`,{'LuaEx/inc/config.lua':Buffer.from('error("zero must not load a user config")')});

// Replacing Rarity must not retain any absent default fields or trailing levels.
const rarityOverlay=Buffer.from(`return {Rarity=setmetatable({ Affix={maxTier=TIER.I}, LEVEL={'CUSTOM'}, COLOR={'#112233'}, CHANCE={100}, MIN_AFFIX_TIER={TIER.I}, MAX_AFFIX_TIER={TIER.I}, MIN_PREFIXES={0}, MAX_PREFIXES={0}, MIN_SUFFIXES={0}, MAX_SUFFIXES={0}}, {__purge=true})}`);
await run(`init(3); assert(#Rarity.LEVEL==1 and Rarity.LEVEL[1].name=='CUSTOM'); assert(#luaex.cog.config.Rarity.LEVEL==1); assert(#require('LuaEx.inc.cog.config.Rarity').LEVEL==6);`,{'config.lua':rarityOverlay});
await run(`init(0,5); require('LuaEx.inc.cog.Enums'); local assembled=assert(loadfile('/LuaEx/inc/cog/config.lua'))('LuaEx.inc.cog.config',{userDirectory='/'}); assert(assembled.Rarity.only==true and assembled.Rarity.Affix==nil and assembled.Rarity.LEVEL==nil); assert(assembled.app.path.save=='');`,{'config.lua':Buffer.from('return {Rarity=setmetatable({ only=true}, {__purge=true})}')});

// Both sources remain independent of the recursively read-only assembled snapshot.
await run(`init(3); userConfigInput.app.name='changed'; assert(luaex.cog.config.app.name=='User game'); assert(require('LuaEx.inc.cog.config.app').name==''); assert(not pcall(function() luaex.cog.config.app.name='blocked' end)); assert(not pcall(function() luaex.cog.config.MyGame.nested.enabled=true end));`,{'config.lua':Buffer.from('userConfigInput={app={name="User game"}, MyGame=setmetatable({ nested={enabled=false}}, {__purge=true})}; return userConfigInput')});
for(const source of ['return nil','return false','return 1','return "bad"','return function() end','return {']){
 await run(`local ok,why=pcall(init,3); assert(not ok and tostring(why):find('config',1,true)); assert(package.path==oldPath and not LUAEX_INIT);`,{'config.lua':Buffer.from(source)});
}
await run(`local ok,why=pcall(init,3); assert(not ok and tostring(why):find('user failure',1,true)); assert(package.path==oldPath and not LUAEX_INIT);`,{'config.lua':Buffer.from('error("user failure")')});

// Ordinary overrides affect existing named keys and list positions only.
const appDefaults=Buffer.from('return {name="Default", path={data="data/", save="old/"}, enabled=false, slots={"one","two","three"}, branch={keep=true, replace={old=true}}}');
await run(`init(3); local app=luaex.cog.config.app; assert(app.name=='Custom' and app.path.save=='new/' and app.path.data=='data/'); assert(app.enabled==true); assert(app.unknown==nil and luaex.cog.config.Unknown==nil); assert(app.slots[1]=='changed' and app.slots[2]=='two' and #app.slots==3); assert(app.__purge==nil); assert(require('LuaEx.inc.cog.config.app').path.save=='old/');`,{'LuaEx/inc/cog/config/app.lua':appDefaults,'config.lua':Buffer.from('return {app=setmetatable({name="Custom",path={save="new/",unknown=true},enabled=true,unknown=true,slots={"changed"}}, {__purge=false}),Unknown={ignored=true}}')});

// A nested purge drops defaults at that level, admits new keys and strips nested markers.
await run(`init(3); local app=luaex.cog.config.app; assert(app.path.data==nil and app.path.save=='only/' and app.path.new==true and app.name=='Default'); assert(app.branch.keep and app.branch.replace.old==nil and app.branch.replace.new.value==1); assert(app.path.__purge==nil and app.branch.replace.new.__purge==nil); assert(#app.slots==1 and app.slots[1]=='only'); assert(luaex.cog.config.Extra.value==1 and luaex.cog.config.Extra.__purge==nil);`,{'LuaEx/inc/cog/config/app.lua':appDefaults,'config.lua':Buffer.from('return {app={path=setmetatable({save="only/",new=true}, {__purge=true}),slots=setmetatable({"only"}, {__purge=true}),branch={replace=setmetatable({new=setmetatable({value=1}, {__purge=false})}, {__purge=true})}},Extra=setmetatable({value=1}, {__purge=true})}')});
await run(`init(3); assert(next(require('LuaEx.inc.cog.config').app.slots)==nil); assert(#luaex.cog.config.app.slots==0 and luaex.cog.config.app.name=='Default');`,{'LuaEx/inc/cog/config/app.lua':appDefaults,'config.lua':Buffer.from('return {app={slots=setmetatable({}, {__purge=true})}}')});

// Root purge replaces the whole assembled table; use the assembler directly to inspect its result.
await run(`init(0,5); require('LuaEx.inc.cog.Enums'); local assembled=assert(loadfile('/LuaEx/inc/cog/config.lua'))('LuaEx.inc.cog.config',{userDirectory='/'}); assert(assembled.app==nil and assembled.Rarity==nil and assembled.Only.flag==false and assembled.__purge==nil);`,{'config.lua':Buffer.from('return setmetatable({Only={flag=false}}, {__purge=true})')});
for(const value of ['1','"true"','{}']){
 await run(`local ok,why=pcall(init,3); assert(not ok and tostring(why):find('__purge',1,true)); assert(package.path==oldPath and not LUAEX_INIT);`,{'config.lua':Buffer.from('return {app=setmetatable({}, {__purge='+value+'})}')});
}

// Copies preserve cyclic data without modifying either source or leaking marker keys.
await run(`init(3); local app=luaex.cog.config.app; assert(rawequal(app,app.self) and app.name=='Updated'); assert(app.extra.__purge==nil and rawequal(app.extra,app.extra.self)); assert(require('LuaEx.inc.cog.config.app').name=='Original'); assert(debug.getmetatable(userConfigInput.app.extra).__purge==true);`,{'LuaEx/inc/cog/config/app.lua':Buffer.from('local t={name="Original"};t.self=t;return t'),'config.lua':Buffer.from('local t={name="Updated"};t.self=t;local extra=setmetatable({}, {__purge=true});extra.self=extra;t.extra=extra;userConfigInput={app=t};return userConfigInput')});

// A data field is not a metavalue. Inherited __index results do not declare the instruction either.
await run(`init(3); local app=luaex.cog.config.app; assert(app.name=='Data field' and app.path.data=='data/'); assert(app.unknown==nil and app.__purge==nil);`,{'LuaEx/inc/cog/config/app.lua':appDefaults,'config.lua':Buffer.from('return {app={__purge=true,name="Data field",unknown=true}}')});
await run(`init(3); local app=luaex.cog.config.app; assert(app.path.save=='merged/' and app.path.data=='data/');`,{'LuaEx/inc/cog/config/app.lua':appDefaults,'config.lua':Buffer.from('return {app={path=setmetatable({save="merged/"},setmetatable({}, {__index={__purge=true}}))}}')});

// Protected metatables still carry a real purge metavalue; runtime snapshots do not inherit it.
await run(`init(3); local path=luaex.cog.config.app.path; assert(path.save=='protected/' and path.data==nil); assert(debug.getmetatable(path).__purge==nil); assert(getmetatable(userConfigInput.app.path)=='hidden' and debug.getmetatable(userConfigInput.app.path).__purge==true);`,{'LuaEx/inc/cog/config/app.lua':appDefaults,'config.lua':Buffer.from('userConfigInput={app={path=setmetatable({save="protected/"},{__purge=true,__metatable="hidden"})}};return userConfigInput')});

// CoG.purge is available while user config executes and only adds the metavalue.
await run(`init(3); local app=luaex.cog.config.app; assert(app.path.save=='helper/' and app.path.data==nil); assert(helperTable.save=='helper/' and helperTable.__purge==nil and debug.getmetatable(helperTable).__purge==true);`,{'config.lua':Buffer.from('helperTable={save="helper/"};assert(rawequal(CoG.purge(helperTable),helperTable));return {app={path=helperTable}}')});
await run(`init(); local mt={tag='retained',__purge=false,__metatable='protected'}; local t=setmetatable({value=1},mt); assert(rawequal(CoG.purge(t),t)); assert(rawequal(debug.getmetatable(t),mt) and mt.__purge==true and mt.tag=='retained' and t.value==1); assert(rawequal(CoG.purge(t),t)); for _,v in ipairs({1,false,'bad',CoG}) do assert(not pcall(CoG.purge,v)); end assert(not pcall(CoG.purge));`);

// Missing debug fails before publishing any framework globals.
await run(`debug=nil; assert(not pcall(init)); assert(luaex==nil and LUAEX_INIT==nil and package.path==oldPath);`);
console.log('PASS loader: lazy require, all levels 0-6, defaults/nil, validation, repeat calls, path restoration, recursive existing-key overrides, per-table metatable __purge and CoG.purge, complete Rarity replacement, immutable snapshots, config failures and missing debug.');
})().catch(e=>{console.error(e);process.exitCode=1;});
