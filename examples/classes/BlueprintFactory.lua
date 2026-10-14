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

local D = require("examples.support.tutorial").new(
    "Blueprint repository",
    "Register a class, import definitions, and let the class construct objects."
);

D.section("Class registration", "Each participating CoG class declares its defaults, validator and factory.")
local Item;
Item = class("ExampleBlueprintItem", {}, {
    Blueprint = { name = "Unnamed item", weight = 1 },

    validateBlueprint = function(bp)
        if (rawtype(bp.name) ~= "string" or not bp.name:find("%S")) then
            return false, "name must be a nonblank string";
        end

        if (rawtype(bp.weight) ~= "number" or bp.weight < 0) then
            return false, "weight must be nonnegative";
        end

        return true;
    end,

    fromBlueprint = function(bp)
        return Item(bp.name, bp.weight);
    end,

    ExampleBlueprintItem = function(cClass)
        local bRegistered, sReason = Factorium.registerClass(cClass);
        assert(bRegistered, sReason);
    end,
}, {
    name = "",
    weight = 0,
}, {}, {
    ExampleBlueprintItem = function(this, cdat, super, sName, nWeight)
        super();
        cdat.pri.name = sName;
        cdat.pri.weight = nWeight;
    end,

    getName = function(this, cdat)
        return cdat.pri.name;
    end,

    getWeight = function(this, cdat)
        return cdat.pri.weight;
    end,
}, CoG);

D.section("Your blueprint", "The mod supplies only the fields it wants to override.")
local name = D.input("name", "Trail boots");
local weight = D.input("weight", 2);
local record = { id = "trail_boots", class = "ExampleBlueprintItem", name = name, weight = weight };
D.show("Blueprint record", record);

local bImported, tReport = Factorium.importMod({
    id = BaseMod.DEFAULT_MOD_ID,
    name = "Blueprint tutorial",
    authors = { "LuaEx" },
    description = "Two content definitions backed by one class.",
    released = "2026-10-13",
    updated = "2026-10-13",
    version = 1,
    blueprints = {
        record,
        { id = "light_pack", class = "ExampleBlueprintItem", name = "Light pack", weight = 0.5 },
    },
});
D.check("Mod imported", bImported);
D.equal("Blueprints accepted", tReport.loaded, 2);
Factorium.finalizeImports();

D.section("Build an instance", "Factorium supplies a copy; the class's factory creates the object.")
local boots = Item.fromBlueprint(Factorium.getBlueprint(Item, record.id));
D.check("Instance created", boots ~= nil);
D.equal("Name", boots.getName(), name);
D.equal("Weight", boots.getWeight(), weight);

D.section("Multiple instances", "One stored definition can initialize independent objects.")
local second = Item.fromBlueprint(Factorium.getBlueprint(Item, record.id));
D.check("Different object identities", boots ~= second);
D.equal("Same initial weight", second.getWeight(), weight);

D.section("Another record", "Queries return definitions for the exact class supplied by the caller.")
local pack = Item.fromBlueprint(Factorium.getBlueprint(Item, "light_pack"));
D.equal("Second record name", pack.getName(), "Light pack");
D.check("Class catalog contains boots", Factorium.getBlueprints(Item).trail_boots ~= nil);

D.section("Unknown identifier", "Missing definitions return nil without constructing anything.")
D.equal("Missing result", Factorium.getBlueprint(Item, "missing"), nil);
D.finish();
