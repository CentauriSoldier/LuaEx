if (not LUAEX_INIT) then
    require("LuaEx.init");
end

local tMessages = {};
Factorium.setLog(function(sMessage)
    tMessages[#tMessages + 1] = sMessage;
end);

local nFactories = 0;
local nParentChecks = 0;
local nChildChecks = 0;

local Creature = class("FactoriumTestCreature", {}, {
    Blueprint = {
        health = 100,
        stats = { armor = 0, speed = 10 },
        slots = { "first", "second" },
    },
    validateBlueprint = function(bp)
        nParentChecks = nParentChecks + 1;

        if (rawtype(bp.health) ~= "number" or bp.health <= 0) then
            return false, "health must be positive";
        end

        return true;
    end,
    fromBlueprint = function(bp)
        nFactories = nFactories + 1;
        return bp;
    end,
}, {}, {}, {
    FactoriumTestCreature = function(this, cdat, super)
        super();
    end,
}, CoG);

local Dragon = class("FactoriumTestDragon", {}, {
    Blueprint = { health = 500, stats = { armor = 20 }, element = "fire" },
    validateBlueprint = function(bp)
        nChildChecks = nChildChecks + 1;

        if (bp.explode) then
            error("deliberate validator failure");
        end

        return bp.element == "fire" or bp.element == "ice", "invalid element";
    end,
    fromBlueprint = function(bp)
        nFactories = nFactories + 1;
        return bp;
    end,
}, {}, {}, {
    FactoriumTestDragon = function(this, cdat, super)
        super();
    end,
}, Creature);

assert(Factorium.registerClass(Creature));
assert(Factorium.registerClass(Dragon));
assert(Factorium.registerClass(Dragon));
assert(not Factorium.registerClass(Point));
assert(not Factorium.registerClass(nil));

local function mod(nID, tBlueprints, tRequired, tConflicts)
    return {
        id = string.format("10000000-0000-4000-8000-%012d", nID),
        name = "Test mod "..nID,
        authors = { "Tester" },
        description = "Factorium regression fixture",
        released = "2026-10-13",
        updated = "2026-10-13",
        version = 1,
        required = tRequired or {},
        conflicts = tConflicts or {},
        blueprints = tBlueprints or {},
    };
end

local function bp(sID, nHealth)
    return { id = sID, class = "FactoriumTestDragon", health = nHealth };
end

local tCycle = bp("cycle", 10);
tCycle.loop = tCycle;
local tKeyCycle = bp("key-cycle", 10);
local tBadKey = {};
tBadKey[tBadKey] = "loop";
tKeyCycle[tBadKey] = true;
local tInvalidKey = bp("invalid-key", 10);
tInvalidKey[true] = "bad";
local tClassLeak = bp("class-leak", 10);
tClassLeak.hidden = Dragon;
local fRoll = function() return 7; end;
local tSource = bp("dragon", nil);
tSource.stats = { speed = 15 };
tSource.slots = { "override" };
tSource.enabled = false;
tSource.weight = 0;
tSource.extra = "retained";
tSource.roll = fRoll;
local tShared = { value = 8 };
tSource.left = tShared;
tSource.right = tShared;
tSource[{ tag = "table-key" }] = { value = 9 };

local tBob = mod(1, {
    tSource,
    { id = "creature", class = "FactoriumTestCreature" },
    bp("bad-health", -1),
    { id = "bad-element", class = "FactoriumTestDragon", element = "water" },
    { id = "explode", class = "FactoriumTestDragon", explode = true },
    { id = "unknown", class = "UnknownClass" },
    tCycle, tKeyCycle, tInvalidKey, tClassLeak,
    bp("last-good", 50),
});

local bImported, tCounts = Factorium.importMod(tBob);
assert(bImported and tCounts.loaded == 3 and tCounts.skipped == 8);
assert(Factorium.getBlueprint(Dragon, "dragon") == nil);
Factorium.finalizeImports();
local tCompiled, sModID = Factorium.getBlueprint(Dragon, "dragon");
assert(tCompiled.health == 500 and tCompiled.stats.armor == 20 and tCompiled.stats.speed == 15);
assert(tCompiled.slots[1] == "override" and tCompiled.slots[2] == "second");
assert(tCompiled.enabled == false and tCompiled.weight == 0 and tCompiled.extra == "retained");
assert(tCompiled.roll == fRoll and tCompiled.roll() == 7);
assert(sModID == tBob.id and nFactories == 0);
assert(nParentChecks > 0 and nChildChecks > 0);
assert(Factorium.getBlueprint(Creature, "dragon") == nil);
assert(Factorium.getBlueprints(Creature).dragon == nil);
assert(Factorium.getBlueprints(Dragon).dragon.class == nil);
tCompiled.stats.armor = 999;
tSource.stats.speed = 999;
assert(Factorium.getBlueprint(Dragon, "dragon").stats.armor == 20);
assert(Factorium.getBlueprint(Dragon, "dragon").stats.speed == 15);
assert(Creature.Blueprint.stats.armor == 0 and Dragon.Blueprint.stats.armor == 20);

-- Ed's valid override wins. Bad replacements do not erase the old winner.
local tEd = mod(2, { bp("dragon", 900), bp("new-dragon", 400) }, { tBob.id });
assert(Factorium.importMod(tEd));
Factorium.finalizeImports();
assert(Factorium.getBlueprint(Dragon, "dragon").health == 900);
assert(Factorium.setModActive(tEd.id, false));
Factorium.finalizeImports();
assert(Factorium.getBlueprint(Dragon, "dragon").health == 500);
assert(Factorium.setModActive(tEd.id, true));
Factorium.finalizeImports();
assert(Factorium.getBlueprint(Dragon, "dragon").health == 900);
assert(Factorium.replaceMod(mod(2, { bp("dragon", -2) }, { tBob.id })));
Factorium.finalizeImports();
assert(Factorium.getBlueprint(Dragon, "dragon").health == 900);
assert(Factorium.getBlueprint(Dragon, "new-dragon") == nil);

-- A globally duplicated ID may move to a different class, with no stale index.
assert(Factorium.importMod(mod(3, { { id = "dragon", class = "FactoriumTestCreature" } })));
Factorium.finalizeImports();
assert(Factorium.getBlueprint(Dragon, "dragon") == nil);
assert(Factorium.getBlueprint(Creature, "dragon").health == 100);
assert(Factorium.removeMod(mod(3).id));
Factorium.finalizeImports();
assert(Factorium.getBlueprint(Dragon, "dragon").health == 900);
assert(Factorium.removeMod(tBob.id));
Factorium.finalizeImports();
assert(not Factorium.getModStatus(tEd.id).accepted);
assert(Factorium.getBlueprint(Dragon, "dragon") == nil);

-- Rejected early mods do not reserve conflicts. One-sided declarations count.
local tMissing = mod(90).id;
local tEarly = mod(10, { bp("conflict", 10) }, { tMissing }, { mod(11).id });
local tLater = mod(11, { bp("conflict", 11) });
assert(Factorium.importMod(tEarly));
assert(Factorium.importMod(tLater));
Factorium.finalizeImports();
assert(Factorium.getModStatus(tLater.id).accepted);
assert(Factorium.getBlueprint(Dragon, "conflict").health == 11);
assert(Factorium.replaceMod(mod(10, { bp("conflict", 10) }, {}, { tLater.id })));
Factorium.finalizeImports();
assert(Factorium.getModStatus(tEarly.id).accepted);
assert(not Factorium.getModStatus(tLater.id).accepted);
assert(Factorium.getBlueprint(Dragon, "conflict").health == 10);
assert(Factorium.removeMod(tEarly.id));
Factorium.finalizeImports();
assert(Factorium.getModStatus(tLater.id).accepted);

-- An accepted early mod losing a dependency releases its conflict claim.
local tA = mod(20, {}, { mod(22).id }, { mod(23).id });
local tB = mod(21, {}, {}, { mod(22).id });
local tC = mod(22);
local tD = mod(23);
for _, tMod in ipairs({ tA, tB, tC, tD }) do
    assert(Factorium.importMod(tMod));
end
Factorium.finalizeImports();
assert(not Factorium.getModStatus(tA.id).accepted);
assert(Factorium.getModStatus(tB.id).accepted);
assert(not Factorium.getModStatus(tC.id).accepted);
assert(Factorium.getModStatus(tD.id).accepted);

-- Loading uses the configured environment and does not execute until runMods.
local tEnv = { marker = 321 };
assert(Factorium.setEnvironment(tEnv));
local hFile = assert(io.open("/factorium-test-mod.lua", "w"));
hFile:write([[return {
    id = "10000000-0000-4000-8000-000000000030",
    name = "Environment test", authors = { "Tester" }, description = "Test",
    released = "2026-10-13", updated = "2026-10-13", version = 1,
    blueprints = { { id = "environment", class = "FactoriumTestDragon",
                    health = marker, callback = function() return marker end } }
}]]);
hFile:close();
assert(Factorium.loadMod("/factorium-test-mod.lua"));
assert(Factorium.getModStatus(mod(30).id) == nil);
assert(Factorium.setEnvironment({ marker = 999 }));
local tRun = Factorium.runMods();
assert(tRun.loaded == 1 and tRun.skipped == 0);
Factorium.finalizeImports();
local tEnvironmentBP = Factorium.getBlueprint(Dragon, "environment");
assert(tEnvironmentBP.health == 321 and tEnvironmentBP.callback() == 321);
assert(#tMessages > 0 and #Factorium.getWarnings() == #tMessages);

-- The default logger uses BaseLog; a bad logger cannot stop later imports.
assert(Factorium.setLog(nil));
assert(not Factorium.importMod({ name = "invalid metadata" }));
local hLog = assert(io.open("Factorium.log", "r"));
assert(hLog:read("*a"):find("Mod import rejected", 1, true));
hLog:close();
assert(Factorium.setLog(function() error("logger failed") end));
assert(not Factorium.importMod({}));
assert(Factorium.importMod(mod(31, { bp("after-logger-failure", 31) })));
Factorium.finalizeImports();
assert(Factorium.getBlueprint(Dragon, "after-logger-failure").health == 31);

-- The fallback environment is valid. Runtime failures skip only that file.
assert(Factorium.setEnvironment({}));
local hFailure = assert(io.open("/factorium-failure.lua", "w"));
hFailure:write("return unavailable_global()");
hFailure:close();
assert(Factorium.loadMod("/factorium-failure.lua"));
assert(Factorium.runMods().skipped == 1);
assert(not Factorium.loadMod("/does-not-exist.lua"));

-- BaseMod subclasses carry conflicts, dependencies and raw definitions.
local ModClass = class("FactoriumTestMod", {}, {}, {}, {}, {
    FactoriumTestMod = function(this, cdat, super, tInfo)
        super(tInfo);
    end,
}, BaseMod);
local tModInfo = mod(32, { bp("mod-object", 32) }, { mod(31).id });
tModInfo.conflicts = { mod(90).id };
local oMod = ModClass(tModInfo);
assert(oMod.getInfo().conflicts[1] == mod(90).id);
assert(Factorium.importMod(oMod));
Factorium.finalizeImports();
assert(Factorium.getBlueprint(Dragon, "mod-object").health == 32);

-- Table keys use identity while being copied out of the private repository.
local tIdentityKey = { tag = "identity" };
Dragon.Blueprint[tIdentityKey] = { first = 1, second = 2 };
local tKeyedBP = bp("keyed", 40);
tKeyedBP[tIdentityKey] = { first = 9 };
assert(Factorium.importMod(mod(40, { tKeyedBP })));
Factorium.finalizeImports();
local tKeyedResult = Factorium.getBlueprint(Dragon, "keyed");
local bFound = false;

for vKey, vValue in pairs(tKeyedResult) do
    if (rawtype(vKey) == "table" and vKey.tag == "identity") then
        assert(vKey ~= tIdentityKey);
        assert(vValue.first == 9 and vValue.second == 2);
        bFound = true;
    end
end

assert(bFound);

print("PASS Factorium: inherited defaults/validators, structural rejection, exact-class copies, overrides/history, dependencies/conflicts, reload/removal and environments");
