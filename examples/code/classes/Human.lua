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

local D=require("examples.support.tutorial").new("Human","Class construction, inheritance, Pool composition, independent instances and snapshots.")

local family=require("examples.support.creatures")
D.section("Your instance", "Names are strings; health and damage are numeric parameters.")
local name=("Mira" --[[ Edit name here ]]);local capacity=(80 --[[ Edit health here ]]);local damage=(15 --[[ Edit damage here ]])
local constructor=family.Human
local object=constructor(name,capacity,family.Rank.SERGEANT)
D.check("Class instance",class.isinstance(object))
D.show("Class",class.getname(object))
D.section("Composition", "The instance owns a real Pool, whose current and maximum are separate values.")
D.equal("Full starting health",object.getHealthPool().get(),capacity)
D.equal("Health capacity",object.getHealthPool().get(Pool.ASPECT.MAX),capacity)
D.section("Inherited behavior", "Damage uses the Creature method even on Human and Soldier instances.")
object.takeDamage(damage)
D.equal("Remaining health",object.getHealthPool().get(),math.max(0,capacity-damage))
D.show("Alive/dead flag",object.isDead())
D.equal("Human name",object.getName(),name)

D.section("Independent instances", "Two constructors must allocate distinct health Pools.")
local other=constructor("Other",30,family.Rank.SCOUT)
D.check("Distinct pools",other.getHealthPool()~=object.getHealthPool())
other.takeDamage(100);D.equal("Overkill clamps to zero",other.getHealthPool().get(),0)
D.check("Other is dead",other.isDead())
D.equal("Original health preserved",object.getHealthPool().get(),math.max(0,capacity-damage))
D.section("Cloning", "A clone preserves state but has an independently mutable Pool.")
local copy=clone(object);copy.getHealthPool().setFull()
D.equal("Clone filled",copy.getHealthPool().get(),capacity)
D.equal("Original not healed",object.getHealthPool().get(),math.max(0,capacity-damage))
D.section("Serialized state", "Text snapshots restore the concrete class and nested component state.")
local text=serialize(object);local restored=deserialize(text)
D.show("Snapshot bytes",#text)
D.check("Concrete class restored",class.getname(restored)==class.getname(constructor))
D.equal("Restored health",restored.getHealthPool().get(),object.getHealthPool().get())

D.finish()
