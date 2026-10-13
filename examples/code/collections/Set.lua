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
local D = require("examples.support.tutorial").new("Set","Uniqueness, union/intersection/difference, identity and mixed-type membership.")

D.section("Your two sets", "Comma-separated strings make it easy to compare overlapping groups.")
local left=Set(D.list(("red,green,blue" --[[ Edit left here ]])))
local right=Set(D.list(("green,gold" --[[ Edit right here ]])))
local function show(label,set) local values={};for value in set() do values[#values+1]=D.format(value) end;table.sort(values);D.show(label,table.concat(values,", ")) end
show("Left",left);show("Right",right)
D.section("Uniqueness", "Adding the exact same value twice does not create a second membership.")
local unique=Set();unique.add("same").add("same")
D.equal("Duplicate strings collapse",unique.size(),1)
D.check("Membership lookup",unique.contains("same"));D.check("Missing lookup",not unique.contains("absent"))
D.section("Set operations", "Operators make new sets. Methods such as importSet and purgeSet mutate a set.")
local union=left+right;local common=left.intersection(right)
show("Union",union);show("Intersection",common)
for value in left() do D.check("Union contains every left member",union.contains(value)) end
for value in common() do D.check("Intersection member exists in both",left.contains(value) and right.contains(value)) end
local difference=Set();for value in left() do if not right.contains(value) then difference.add(value) end end
show("Left minus right",difference)
D.observe("Current purgeSet implementation",function()local copy=Set();copy.importSet(left);copy.purgeSet(right);return copy.size() end)
D.note("purgeSet currently calls a missing global helper; the explicit membership loop above gives the intended difference.")
D.section("Mixed types are distinct", "The number 1 differs from string '1'; table identity matters more than equal contents.")
local a,b={x=1},{x=1};local point=Point(2,3)
local mixed=Set({1,"1",false,true,a,b,point,null})
D.equal("Eight distinct members",mixed.size(),8)
D.check("First table identity",mixed.contains(a));D.check("Equivalent fresh table is not a member",not mixed.contains({x=1}))
show("Mixed members",mixed)
D.section("Remove, subset and clear", "Removing absent membership is harmless; an empty set is a subset of another set.")
D.observe("Remove absent member",function() unique.remove("absent");return unique.size() end)
D.observe("Remove present member",function() unique.remove("same");return unique.size() end)
D.note("remove currently shares the missing helper used by purgeSet. A new empty set demonstrates subset behavior independently.")
D.check("Empty is a subset",Set().isSubSet(left))
mixed.clear();D.equal("Cleared mixed set",mixed.size(),0)
D.section("Invalid values", "nil has no membership identity in this API.")
D.reject("Cannot add nil",function()left.add(nil) end)
D.reject("Cannot remove nil",function()left.remove(nil) end)
D.finish()
