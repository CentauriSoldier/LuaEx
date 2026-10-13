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
local D = require("examples.support.tutorial").new("SortedDictionary","String keys, mixed values, ordered iteration, comparators and independent clones.")

D.section("Your dictionary entry", "Keys must be strings; values may have different types.")
local key=("home" --[[ Edit key here ]]);local value=("Oregon" --[[ Edit value here ]]);local reverse=(false --[[ Edit reverse here ]])
local dictionary=SortedDictionary();dictionary.add(key,value)
dictionary.add("count",7).add("enabled",false).add("position",Point(1,2)).add("record",{score=2})
local function show(label) D.note(label);for name,item in dictionary() do D.show("Key "..name,item) end end
show("Lexicographic string-key order")
D.equal("Custom entry",dictionary.get(key),value)
D.section("Update and membership", "set replaces a value or adds a new key; add also updates an existing key.")
local size=dictionary.size();dictionary.set(key,"updated")
D.equal("Replacing a key retains size",dictionary.size(),size)
D.equal("New value",dictionary.get(key),"updated")
D.check("containsKey",dictionary.containsKey(key));D.check("Absent key",not dictionary.containsKey("missing"))
D.section("Custom sorting", "A comparator affects traversal, not membership.")
if reverse then dictionary.setSortFunction(function(a,b)return a>b end) else dictionary.setSortFunction() end
show(reverse and "Reverse order requested" or "Default order requested")
D.equal("Membership unaffected",dictionary.size(),size)
D.section("nil value versus absent key", "Setting nil clears the stored value while the key still occupies the ordered key list.")
dictionary.set("enabled",nil)
D.check("Key still exists",dictionary.containsKey("enabled"));D.equal("Value is nil",dictionary.get("enabled"),nil)
dictionary.remove("enabled");D.check("Explicit remove removes the key",not dictionary.containsKey("enabled"))
D.section("Cloning nested values", "The clone has its own record contents and ordering list.")
local copy=clone(dictionary);copy.get("record").score=99
D.equal("Original nested value retained",dictionary.get("record").score,2)
copy.add("copy-only",true);D.check("Original has no copy-only key",not dictionary.containsKey("copy-only"))
D.section("Validation and current limits", "Use dictionary() for ordered traversal; the current pairs metamethod references obsolete class data.")
D.reject("Numeric key rejected",function()dictionary.add(12,"bad") end)
D.reject("Missing get rejected",function()dictionary.get("missing") end)
D.reject("Invalid comparator rejected",function()dictionary.setSortFunction("descending") end)
D.observe("Current pairs implementation",function()for _ in pairs(dictionary) do break end;return "supported" end)
D.note("containsValue is currently unfinished. This tutorial uses explicit ordered iteration for value searches.")
D.finish()
