if not LUAEX_INIT then require("LuaEx.init") end

local oFirst, oSecond = Point(1, 2), Point(1, 2);
local oRegistry = Registry({Point});
assert(oRegistry.allows(oFirst) and oRegistry.allows(oSecond));
assert(not ObjectRegistry({CoG}).allows(oFirst));

local oExact = Registry({oFirst});
assert(oExact.allows(oFirst) and not oExact.allows(oSecond));
local oCopy = clone(oExact);
local _, oEntry = oCopy.eachEntry()();
assert(rawequal(oEntry, oFirst));
oCopy.clear().add(oSecond);
assert(oCopy.allows(oSecond) and not oCopy.allows(oFirst));
assert(oExact.allows(oFirst) and not oExact.allows(oSecond));

local oSlots1 = ItemSlotSystem(nil, oFirst);
local oSlots2 = ItemSlotSystem(nil, oSecond);
local oAllSlots = Registry({ItemSlotSystem});
assert(oAllSlots.allows(oSlots1) and oAllSlots.allows(oSlots2));
local oSpecificSlots = Registry({oSlots1});
assert(oSpecificSlots.allows(oSlots1) and not oSpecificSlots.allows(oSlots2));
assert(not Registry({Point}, nil, false).allows(oFirst));
local nCalls = 0;
local fCheck = function(oPoint, nMinimum)
    nCalls = nCalls + 1;
    return oPoint.getX() >= nMinimum, "X too small";
end;
oRegistry.setPrerequisite(fCheck);
local bAllowed, sReason = oRegistry.allows(oFirst, 5);
assert(not bAllowed and sReason == "X too small" and nCalls == 1);
assert(oRegistry.allows(oFirst, 1));
local oCallbackClone = clone(oRegistry);
assert(oCallbackClone.getPrerequisite() == fCheck);
oCallbackClone.setDefaultPrerequisite(false).setPrerequisite();
assert(not oCallbackClone.allows(oFirst));
assert(oRegistry.getPrerequisite() == fCheck);
assert(not pcall(function() Registry({{}}) end));
assert(not pcall(function() Registry({"Point"}) end));
assert(not pcall(function() Registry({[2] = Point}) end));
assert(not oRegistry.allows({}));
local Base = class("RegistryGeneralBase", {}, {}, {}, {}, {
    RegistryGeneralBase = function(this, cdat) end,
});
local Child = class("RegistryGeneralChild", {}, {}, {}, {}, {
    RegistryGeneralChild = function(this, cdat, super) super() end,
}, Base);
assert(Registry({Base}).allows(Child()));
print("PASS Registry: unrestricted class families, exact instances, slot-system scopes, prerequisite defaults, reasons, validation and independent cloning");
