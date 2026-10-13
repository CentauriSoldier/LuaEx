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
local D = require("examples.support.tutorial").new("Struct","Fixed fields, mutable and read-only records, null type binding and snapshots.")

D.section("A record using your inputs", "Fields are declared by a factory. Values are type checked on later assignments.")
local speed=D.input("speed",5.5);local caliber=D.input("caliber","9mm");local enabled=D.input("enabled",true)
local Bullet=structfactory("TutorialBullet",{speed=1,damage=10,caliber="",enabled=false,owner=null,data={hits=0}})
local bullet=Bullet({speed=speed,caliber=caliber,enabled=enabled})
D.show("Numeric speed",bullet.speed);D.show("Text caliber",bullet.caliber);D.show("Boolean enabled",bullet.enabled)
D.equal("Omitted field uses default",bullet.damage,10)
D.section("Mutation and fixed field names", "Values may change but the record layout cannot grow.")
bullet.damage=25;D.equal("Updated numeric field",bullet.damage,25)
D.reject("Add an undeclared field",function()bullet.extra=1 end)
D.reject("Read an undeclared field",function()return bullet.extra end)
D.reject("Change number into text",function()bullet.damage="high" end)
D.reject("Assign nil",function()bullet.damage=nil end)
D.section("null chooses a type later", "A null field binds to the first non-null type, even after being cleared back to null.")
D.equal("Owner starts empty",bullet.owner,null)
bullet.owner="Mira";bullet.owner=null
D.reject("Owner was bound to string",function()bullet.owner=Point() end)
bullet.owner="Ari";D.show("Owner",bullet.owner)
D.section("Nested data and ownership", "Factory default tables are copied for each new record.")
local other=Bullet();bullet.data.hits=4
D.equal("Other record has independent defaults",other.data.hits,0)
local copied=clone(bullet);copied.data.hits=99
D.equal("Clone is independent",bullet.data.hits,4)
D.section("Read-only is shallow", "Read-only protects field bindings; it does not freeze a table stored inside a field.")
local Readonly=structfactory("TutorialReadonly",{enabled=true,data={}},true)
local frozen=Readonly()
D.reject("Replace a read-only field",function()frozen.enabled=false end)
frozen.data.note="nested table is still mutable"
D.show("Allowed nested mutation",frozen.data)
D.reject("Read-only factories cannot contain null defaults",function()structfactory("TutorialBadFrozen",{owner=null},true) end)
D.section("Iteration and restoration", "Snapshots preserve the factory subtype and field constraints.")
for key,value in pairs(bullet) do D.show("Field "..key,value) end
local restored=deserialize(serialize(bullet))
D.equal("Subtype restored",subtype(restored),"TutorialBullet")
D.equal("Current damage restored",restored.damage,25)
D.reject("Restored type remains protected",function()restored.damage=false end)
D.finish()
