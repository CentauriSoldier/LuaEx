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

local D=require("examples.support.tutorial").new("Blueprint factory","Register a typed blueprint schema, construct objects, and distinguish records from instances.")

D.section("Factory registration", "A CoG subclass registers its schema from its authorized static constructor.")
local Item
Item=class("ExampleBlueprintItem",{}, {
    ExampleBlueprintItem=function(child,auth)
        local record=schema.Record{id=Factorium.SCHEMA_ID,name=schema.String,weight=schema.Number}
        local ok,message=Factorium.registerFactory(child,auth,record,function(id,data)
            return child(data.name,data.weight)
        end)
        assert(ok,message)
    end,
}, {name="",weight=0}, {}, {
    ExampleBlueprintItem=function(this,cdat,super,name,weight)
        super();cdat.pri.name=name;cdat.pri.weight=weight
    end,
    getName=function(this,cdat) return cdat.pri.name end,
    getWeight=function(this,cdat) return cdat.pri.weight end,
},CoG)

D.section("Your blueprint", "The schema requires a string identifier, string name and numeric weight.")
local name=D.input("name","Trail boots");local weight=D.input("weight",2)
local record={id="DEM-ITM-0001",name=name,weight=weight}
D.show("Blueprint record",record)
local ok,message=Factorium.addBlueprint(Item,record);D.check("Blueprint accepted",ok)
D.section("Build an instance", "The factory translates the record into private class state.")
local boots,why=Factorium.fromBlueprint(record.id);D.check("Instance created",boots~=nil)
D.equal("Name",boots.getName(),name);D.equal("Weight",boots.getWeight(),weight)
D.section("Multiple instances", "The same blueprint can create distinct instances with identical initial data.")
local second=Factorium.fromBlueprint(record.id)
D.check("Different object identities",boots~=second)
D.equal("Same initial weight",second.getWeight(),weight)
D.section("Another record", "Registry identifiers select different records within the same class schema.")
local accepted,reason=Factorium.addBlueprint(Item,{id="DEM-ITM-0002",name="Light pack",weight=0.5})
D.check("Second blueprint accepted",accepted)
D.equal("Second record name",Factorium.fromBlueprint("DEM-ITM-0002").getName(),"Light pack")
D.section("Unknown identifier", "Lookup returns nil and an explanation when no matching blueprint exists.")
local missing,errorText=Factorium.fromBlueprint("DEM-ITM-FFFF")
D.equal("Missing result",missing,nil);D.show("Missing reason",errorText)

D.finish()
