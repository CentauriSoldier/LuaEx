if not LUAEX_INIT then require("LuaEx.init") end

local Actor = class("RegistryTestActor", {}, {}, {strength = 0}, {}, {
    RegistryTestActor = function(this, cdat, super, nStrength)
        super();
        cdat.pri.strength = nStrength or 0;
    end,
    getStrength = function(this, cdat) return cdat.pri.strength end,
}, CoG);
local Goblin = class("RegistryTestGoblin", {}, {}, {}, {}, {
    RegistryTestGoblin = function(this, cdat, super) super(20) end,
}, Actor);
local Other = class("RegistryTestOther", {}, {}, {}, {}, {
    RegistryTestOther = function(this, cdat, super) super() end,
}, CoG);
local oGoblin, oOther = Goblin(), Other();
local function rejects(fAction)
    assert(not pcall(fAction), "Expected a validation error");
end

local oRegistry = ObjectRegistry();
assert(not oRegistry.allows(oGoblin));
local _, bAdded = oRegistry.add(Actor);
assert(bAdded and oRegistry.allows(oGoblin));
_, bAdded = oRegistry.add(Actor);
assert(not bAdded and #oRegistry == 1);
assert(not oRegistry.allows(oOther));
assert(not oRegistry.allows({}));
assert(not oRegistry.allows(CoG));
assert(not oRegistry.allows(Point(0, 0)));
rejects(function() oRegistry.add(Point) end);
rejects(function() oRegistry.add(Point(0, 0)) end);
rejects(function() ObjectRegistry({[2] = Actor}) end);
rejects(function() ObjectRegistry({Actor}, false) end);

local oDenied = ObjectRegistry({CoG}, nil, false);
assert(not oDenied.allows(oGoblin));
oDenied.setDefaultPrerequisite(true);
assert(oDenied.allows(oGoblin));
oDenied.setDefaultPrerequisite(false);
assert(not oDenied.allows(oGoblin));

local nCalls = 0;
local fCheck = function(oActor, nRequired, sContext)
    nCalls = nCalls + 1;
    assert(sContext == "consume");
    return oActor.getStrength() >= nRequired, "Insufficient Strength";
end
oRegistry.add(CoG).setPrerequisite(fCheck);
local bAllowed, sReason = oRegistry.allows(oGoblin, 25, "consume");
assert(not bAllowed and sReason == "Insufficient Strength" and nCalls == 1);
assert(oRegistry.allows(oGoblin, 15, "consume") and nCalls == 2);
oRegistry.setDefaultPrerequisite(false);
assert(oRegistry.allows(oGoblin, 15, "consume"));
local oCopy = clone(oRegistry);
assert(oCopy ~= oRegistry and #oCopy == #oRegistry);
assert(oCopy.getPrerequisite() == fCheck and not oCopy.getDefaultPrerequisite());
oCopy.remove(Actor).remove(CoG);
assert(#oCopy == 0 and #oRegistry == 2);
oCopy.add(CoG).setPrerequisite();
assert(not oCopy.allows(oGoblin));
assert(oRegistry.getPrerequisite() == fCheck);
oCopy.setDefaultPrerequisite(true);
assert(oCopy.allows(oGoblin));
assert(not oRegistry.getDefaultPrerequisite());

local fIterator = oRegistry.eachClass();
oRegistry.clear();
local _, cFirst = fIterator();
assert(cFirst == Actor and oRegistry.getCount() == 0);
local oInputs = {Actor};
local oIndependent = ObjectRegistry(oInputs);
oInputs[1] = CoG;
assert(oIndependent.contains(Actor) and not oIndependent.contains(CoG));
local oFalseClone = clone(ObjectRegistry({Actor}, nil, false));
assert(not oFalseClone.allows(oGoblin));
oIndependent.setPrerequisite(function() return "yes" end);
rejects(function() oIndependent.allows(oGoblin) end);
oIndependent.setPrerequisite(function() error("prerequisite failure") end);
rejects(function() oIndependent.allows(oGoblin) end);
local Human = class("RegistryTestHuman", {}, {}, {}, {}, {
    RegistryTestHuman = function(this, cdat, super) super(20) end,
}, Actor);
local Soldier = class("RegistryTestSoldier", {}, {}, {}, {}, {
    RegistryTestSoldier = function(this, cdat, super) super() end,
}, Human);
local Bob, Alice = Soldier(), Soldier();

for _, cAllowed in ipairs({Actor, Human, Soldier}) do
    assert(ObjectRegistry({cAllowed}).allows(Bob));
    assert(ObjectRegistry({cAllowed}).allows(Alice));
end

local oBobOnly = ObjectRegistry({Bob});
assert(oBobOnly.allows(Bob) and not oBobOnly.allows(Alice));
assert(oBobOnly.contains(Bob) and not oBobOnly.contains(Soldier));
local oBobClone = clone(oBobOnly);
local _, oEntry = oBobClone.eachEntry()();
assert(rawequal(oEntry, Bob) and oBobClone.allows(Bob));
oBobClone.remove(Bob).add(Alice);
assert(oBobClone.allows(Alice) and not oBobClone.allows(Bob));
assert(oBobOnly.allows(Bob) and not oBobOnly.allows(Alice));
oBobOnly.add(Human);
assert(oBobOnly.allows(Alice));
oBobOnly.remove(Human);
assert(not oBobOnly.allows(Alice));
local nIdentityCalls = 0;
oBobOnly.setPrerequisite(function(oActor)
    nIdentityCalls = nIdentityCalls + 1;
    return oActor.getStrength() >= 15;
end);
assert(oBobOnly.allows(Bob) and nIdentityCalls == 1);
assert(not oBobOnly.allows(Alice) and nIdentityCalls == 1);
local EqualActor = class("RegistryTestEqualActor", {
    __eq = function() return true end,
}, {}, {}, {}, {
    RegistryTestEqualActor = function(this, cdat, super) super(20) end,
}, Actor);
local first, second = EqualActor(), EqualActor();
assert(first == second and not rawequal(first, second));
local oExact = ObjectRegistry({first});
assert(not oExact.allows(second));
local _, bSecondAdded = oExact.add(second);
assert(bSecondAdded and #oExact == 2);
oExact.remove(first);
assert(not oExact.contains(first) and oExact.contains(second));
print("PASS ObjectRegistry: inheritance and exact instances, mixed entries, mutation, dummies, callbacks, stable iteration and independent identity-preserving clones");
