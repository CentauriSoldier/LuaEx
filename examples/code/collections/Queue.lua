-- Independent code tutorial. Edit the values below, then Run code.
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
local D = require("examples.support.tutorial").new("Queue","First in, first out: order, mixed types, non-destructive iteration and empty boundaries.")

D.section("Your waiting line", "enqueue adds to the back; dequeue removes the earliest waiting item.")
local items=D.list(("Ada,Bo,Cy" --[[ Edit items here ]]));local queue=Queue(items)
D.equal("Initial size",queue.size(),#items);D.show("Front without removal",queue.peek())
if #items>0 then D.equal("First served",queue.dequeue(),items[1]) end
queue.enqueue("new arrival");D.show("After adding a string",queue)
D.section("Different value types", "A Queue may hold strings, numbers, booleans, tables, LuaEx objects and functions together.")
local values={"text",3.5,false,{task="build"},point(2,3),function()return "done" end,null}
local mixed=Queue()
for _,value in ipairs(values) do mixed.enqueue(value) end
D.equal("Mixed queue size",mixed.size(),#values)
for index=1,#values do local value=mixed.dequeue();D.show("Removed "..index,value);D.equal("FIFO identity "..index,value,values[index]) end
D.section("Iteration does not consume", "Call the queue as an iterator; items retain their order and size.")
local ordered=Queue({10,20,30});local count=0
for value in ordered() do count=count+1;D.show("Position "..count,value) end
D.equal("All items visited",count,3);D.equal("Size unchanged",#ordered,3)
D.section("Reverse and clear", "reverse changes the waiting order in place; clear removes all items.")
ordered.reverse();D.equal("New front after reversal",ordered.peek(),30)
ordered.clear();D.equal("Cleared count",ordered.size(),0);D.equal("Empty dequeue",ordered.dequeue(),nil)
D.section("nil and false boundaries", "nil is ignored, while false is stored and preserved by both peek and dequeue.")
ordered.enqueue(nil);D.equal("nil does not occupy a slot",ordered.size(),0)
ordered.enqueue(false);D.equal("False occupies a slot",ordered.size(),1)
D.equal("peek preserves false",ordered.peek(),false);D.equal("dequeue preserves false",ordered.dequeue(),false)
D.section("Framework persistence", "Use the global serializer for collection save/load.")
ordered.enqueue("saved task");local restored=deserialize(serialize(ordered))
D.equal("Restored front",restored.peek(),"saved task")
D.note("Legacy instance deserialize remains unfinished; use deserialize(serialize(queue)).")
D.finish()
