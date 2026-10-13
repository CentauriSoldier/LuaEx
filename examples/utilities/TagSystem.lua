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

local D=require("examples.support.tutorial").new("TagSystem","String normalization, duplicate handling, enabled flags, iteration and persistence.")

D.section("Your tags", "Comma separated input becomes trimmed, uppercase string tags.")
local items=D.list(D.input("tags","Soldier,Massive,Rich,DEmOn,Baleful"))
local tags=TagSystem();tags.addMultiple(items)
for name,enabled in tags.eachTag() do D.show("Normalized "..name,enabled) end
D.section("Duplicate normalization", "Case and surrounding spaces do not create distinct tags.")
tags.add(" tutorial ");local count=#tags;tags.add("TUTORIAL")
D.equal("Duplicate does not increase count",#tags,count)
D.check("Trimmed lookup",tags.contains(" tutorial "))
D.section("Enabled and present", "A disabled tag is still present in the system.")
tags.setEnabled("tutorial",false)
D.check("Disabled tag still exists",tags.contains("TUTORIAL"))
D.equal("Disabled flag",tags.isEnabled("tutorial"),false)
tags.setEnabled("tutorial",true);D.equal("Enabled again",tags.isEnabled("tutorial"),true)
D.section("Independent copy", "Removing a tag from a clone preserves the original set.")
local copy=clone(tags);copy.remove("tutorial")
D.check("Original keeps tutorial",tags.contains("tutorial"))
D.equal("Copy removes tutorial",copy.contains("tutorial"),false)
D.section("Snapshot flags", "The shared serializer retains disabled state and tag membership.")
tags.setEnabled("tutorial",false)
local restored=deserialize(serialize(tags))
D.check("Same tag membership",restored.hasSameTags(tags))
D.equal("Disabled state restored",restored.isEnabled("tutorial"),false)
D.section("Invalid inputs", "Tags are nonblank strings; invalid types are explicit expected rejections.")
D.reject("Blank tag",function() tags.add("   ") end)
D.reject("Numeric tag",function() tags.add(42) end)
D.show("Final count",#tags)

D.finish()
