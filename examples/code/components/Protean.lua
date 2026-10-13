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

local D=require("examples.support.tutorial").new("Protean","Calculate modifiers, inspect individual values, link bases and preserve independent snapshots.")

D.section("Your base value", "The base is a number; modifiers are separate numeric categories.")
local base=(100 --[[ Edit base here ]]);local bonus=(20 --[[ Edit bonus here ]]);local multiplier=(0.5 --[[ Edit multiplier here ]])
local attack=Protean(base);D.equal("Unmodified value",attack.getValue(),base)
D.section("Base bonus", "Add the bonus before multiplication.")
attack.setValue(Protean.BASE_BONUS,bonus)
D.equal("Base plus bonus",attack.getValue(),base+bonus)
D.equal("Stored base",attack.getValue(Protean.VALUE_BASE),base)
D.section("Multiplication and penalty", "Bonus and penalty modify the same factor: 1 + bonus - penalty.")
attack.setValue(Protean.MULTIPLICATIVE_BONUS,multiplier)
D.equal("Multiplied value",attack.getValue(),(base+bonus)*(1+multiplier))
attack.setValue(Protean.MULTIPLICATIVE_PENALTY,0.25)
D.equal("With penalty",attack.getValue(),(base+bonus)*(0.75+multiplier))
D.section("Independent copy", "Changing a clone must leave the original numeric base unchanged.")
local copy=clone(attack);copy.setValue(base+50)
D.equal("Original base remains",attack.getValue(Protean.VALUE_BASE),base)
D.equal("Copy has new base",copy.getValue(Protean.VALUE_BASE),base+50)
D.section("Serialization", "A textual snapshot reconstructs the calculated value and its categories.")
local snapshot=serialize(attack);D.show("Snapshot type",type(snapshot));D.show("Snapshot bytes",#snapshot)
local restored=deserialize(snapshot)
D.equal("Restored final",restored.getValue(),attack.getValue())
D.equal("Restored base",restored.getValue(Protean.VALUE_BASE),base)
D.section("Linked base values", "A shared linker propagates changes; unlinking preserves the last value.")
local first,second=Protean(10),Protean(10)
first.setLinker(0);second.setLinker(first.getLinkerID());first.setValue(30)
D.equal("Linked second",second.getValue(),30)
second.setLinker();first.setValue(40)
D.equal("Unlinked second",second.getValue(),30)
D.equal("First continues independently",first.getValue(),40)

D.finish()
