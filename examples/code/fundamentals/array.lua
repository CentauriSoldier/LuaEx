-- Independent code tutorial. Edit the values below, then Run code.
-- Locate the repository from this example (native Lua and browser virtual files).
local sExampleSource = debug.getinfo(1, "S").source:gsub("^@", "")
local sSourcePath = sExampleSource:match("^(.*)[/\\]") or "."
local sRepositoryPath = sSourcePath
for _ = 1, 8 do
    local file = io.open(sRepositoryPath .. "/LuaEx/init.lua", "r")
    if file then file:close(); break end
    sRepositoryPath = sRepositoryPath .. "/.."
end
package.path = sRepositoryPath .. "/?.lua;" .. package.path
if not LUAEX_INIT then require("LuaEx.init") end
local D = require("examples.support.tutorial").new("Array","Fixed length, one element type, safe null slots, and independent copies.")

D.section("Your string array", "An array keeps its size and element type; use a comma-separated list to try your own strings.")
local names=D.list(("cat,dog,owl" --[[ Edit items here ]]))
local pets=array(names)
D.show("Original",pets);D.equal("Length",#pets,#names)
for index,value in pets() do D.show("Slot "..index,value) end
D.section("Numbers and booleans", "Different arrays may use different types. A single array is homogeneous.")
local numbers=array({-2,0,1.5,9})
numbers.sort();D.show("Ascending",numbers)
numbers.sort(function(a,b)return a>b end);D.equal("Descending first",numbers[1],9)
D.equal("Find zero",numbers.indexof(0),3)
local flags=array({false,true,false})
D.equal("False is a real value",flags[1],false);D.equal("Last false",flags.lastindexof(false),3)
D.section("Empty slots and type binding", "null represents an empty slot. First assignment binds an untyped array.")
local slots=array(3);D.equal("Unassigned slot",slots[2],null)
slots[1]=42;slots[3]=-4
D.reject("A number array rejects a string",function()slots[2]="forty-two" end)
slots[2]=null;slots.clear();slots[2]=8
D.equal("clear retains the bound number type",slots[2],8)
D.section("Tables, objects and functions", "Element type can be a Lua table, a LuaEx object type or a function.")
local records=array({{score=1},{score=2}})
local copied=clone(records);copied[1].score=100
D.equal("Deep copy owns nested records",records[1].score,1)
local points=array({Point(1,2),Point(-3,0)})
D.show("Second Point",points[2])
local functions=array({function(n)return n*2 end,function(n)return n+1 end})
D.equal("Function stored in an array",functions[1](5),10)
D.section("Validation boundaries", "Indexes are integers from 1 to length; size and type cannot be changed accidentally.")
for _,index in ipairs({0,-1,1.5,4}) do D.reject("Index "..index,function()return slots[index] end) end
D.reject("nil assignment",function()slots[1]=nil end)
D.reject("Changing fixed length",function()slots.length=9 end)
D.equal("An empty array is allowed",#array(0),0)
D.section("Clone and serialization", "Snapshots preserve false and null, type binding and nested ownership.")
local restored=deserialize(serialize(flags))
D.equal("False survives restoration",restored[1],false)
local loop=array(1);loop[1]=loop
local loopCopy=clone(loop);D.check("Clone preserves a self-reference",loopCopy[1]==loopCopy)
D.finish()
