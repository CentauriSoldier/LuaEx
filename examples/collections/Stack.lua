-- Locate the repository from this example (native Lua and browser virtual files).
local sExampleSource = debug.getinfo(1, "S").source:gsub("^@", "")
local sSourcePath = sExampleSource:match("^(.*)[/\\]") or "."
local sRepositoryPath = sSourcePath
for _ = 1, 8 do
    local file = io.open(sRepositoryPath .. "/LuaEx/load.lua", "r")
    if file then file:close(); break end
    sRepositoryPath = sRepositoryPath .. "/.."
end
package.path = sRepositoryPath .. "/?.lua;" .. package.path
if not LUAEX_INIT then require("LuaEx.load")(); end
local D = require("examples.support.tutorial").new("Stack","Last in, first out: undo-style ordering, mixed values and observable edge cases.")

D.section("Your undo stack", "push adds to the top. The last pushed item is the first popped.")
local items=D.list(D.input("items","open,edit,save"));local stack=Stack()
for _,item in ipairs(items) do stack.push(item);D.show("Pushed",item) end
D.equal("Size",#stack,#items)
for index=#items,1,-1 do D.equal("Undo in reverse insertion order",stack.pop(),items[index]) end
D.section("Mixed value types", "Stacks do not require a single element type.")
local _oPoint=point(-1,2);local record={command="move"};local fn=function()return 42 end
local values={"text",-3.25,true,false,record,_oPoint,fn,null}
for _,value in ipairs(values) do stack.push(value) end
for index=#values,1,-1 do local value=stack.pop();D.show("Pop type "..index,value);D.equal("LIFO identity "..index,value,values[index]) end
D.section("Iteration and peeking", "Iteration reads the top-first order without changing the stack.")
stack=Stack();stack.push(1).push(2).push(3)
D.equal("Top",stack.peek(),3)
local count=0;for value in stack() do count=count+1;D.show("Stack position "..count,value) end
D.equal("Iteration retained size",stack.size(),3)
D.section("Reverse and clear", "These operations mutate the same stack.")
stack.reverse();D.equal("Reversed top",stack.peek(),1)
stack.clear();D.equal("Empty size",stack.size(),0)
D.section("Boundary behavior", "nil is ignored; false occupies a slot and is preserved by peek and pop.")
stack.push(nil);D.equal("nil ignored",#stack,0)
stack.push(false);D.equal("False counted",#stack,1);D.equal("Peek preserves false",stack.peek(),false);D.equal("Popped false",stack.pop(),false)
D.equal("Empty pop after a false item",stack.pop(),nil)
D.note("Empty pop returns nil without modifying unrelated global state.")
D.section("Practical safe drain", "A size-guarded loop consumes exactly the queued undo commands.")
stack.push("first").push("second")
while stack.size()>0 do D.show("Safely drained",stack.pop()) end
D.equal("Drain complete",#stack,0)
D.finish()
