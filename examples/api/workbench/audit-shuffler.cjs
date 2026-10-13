const fs=require('node:fs'),path=require('node:path');const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{const m=generate(),e=new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),console.log);try{await e.boot(Object.fromEntries(m.files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))])));await e.lua.doString(`
local s=Shuffler({'only'}); local ok,err=pcall(s.pop);print('Last pop:',ok,err,'remaining',s.getRemaining());
local empty=Shuffler();ok,err=pcall(empty.pop);print('Empty pop:',ok,err);
local r=Shuffler({'a','b'});print('remove a:',r.remove('a'),'pool size',r.size(),'remaining',r.getRemaining());local found=false;for _,v in pairs(r) do if v=='a' then found=true end end;print('Removed value still yielded:',found);
local i=Shuffler({'a','b'});i.setAutoReset(false);local count=0;for _,v in pairs(i) do count=count+1 end;print('Iteration with auto-reset OFF: yielded',count,'remaining after loop',i.getRemaining());
local p=Shuffler({'a'});p.setAutoReset(false);pcall(p.pop);print('Remove previously popped pool entry:',p.remove('a'),'pool size',p.size());
local sparse=Shuffler({[1]='a',[3]='c'});print('Sparse constructor pool size:',sparse.size());
`);}finally{e.close()}})().catch(err=>{console.error(err);process.exitCode=1});
