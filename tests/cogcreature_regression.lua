-- Standalone regression: configure test-only categories before the framework loads.
if not LUAEX_INIT then
    package.preload["LuaEx.inc.cog.config.StatusTracker"] = function()
        return {ALL_THINGS = {CREATURES = {"HASTENED"}, ITEMS = {"DAMAGED"}}};
    end;
    require("LuaEx.load")();
end
local eScope = StatusTracker.ALL_THINGS and StatusTracker.ALL_THINGS.CREATURES;
assert(eScope, "Run this regression with its standalone test StatusTracker configuration.");

local function options()
    return {
        XP = {Type = XPSystem.TYPE.LINEAR, LevelOneXP = 10, MaxLevel = 5, Progression = 2},
        HP = {Max = 80, Current = 50},
        StatusScope = eScope,
    };
end
local creature = CoGCreature("Bob", "A soldier.", nil, nil, options());
local other = CoGCreature("Other", "Another creature.", nil, nil, options());
assert(creature.getName() == "Bob" and creature.getDescription() == "A soldier.");
assert(creature.getRarity() == Rarity.LEVEL[1]);
assert(creature.getHP().get(Pool.ASPECT.MAX) == 80 and creature.getHP().get() == 50);
assert(creature.getXP().getLevel() == 0);
creature.getXP().setLevel(3);
assert(creature.getXP().getLevel() == 3 and other.getXP().getLevel() == 0);
creature.getHP().adjust(-20);
assert(creature.getHP().get() == 30 and other.getHP().get() == 50);
assert(creature.getInventory().getOwner() == creature and creature.getEquipment().getOwner() == creature);
assert(creature.getInventory().getItemCount() == 0 and creature.getInventory().getMaxItems() == math.huge);
assert(creature.getEquipment().getItemSlotCount() == 0);
creature.getInventory().setLocked(true);
assert(creature.getInventory().isLocked() and not other.getInventory().isLocked());
assert(creature.getTargetor().Types.add({"CREATURE"}) == 1);
assert(#creature.getTargetor().Types == 1 and #other.getTargetor().Types == 0);
creature.getEquipment().addItemSlot(ItemSlot());
assert(creature.getEquipment().getItemSlotCount() == 1 and other.getEquipment().getItemSlotCount() == 0);
assert(creature.getStatusTracker().activate("HASTENED", 3, true));
assert(not other.getStatusTracker().isActive("HASTENED"));
assert(not pcall(creature.getStatusTracker().isActive, StatusTracker.ALL_THINGS.ITEMS.DAMAGED));
for _, sName in ipairs({"XP", "HP", "Inventory", "Equipment", "StatusTracker", "Targetor", "TagSystem"}) do
    local fGetter = creature["get"..sName];
    assert(rawequal(fGetter(), fGetter()) and not rawequal(fGetter(), other["get"..sName]()));
    assert(not pcall(function() return creature["set"..sName]; end));
    assert(not pcall(function() creature["get"..sName] = function() end; end));
    local sClass = "CreatureFinalGetter"..sName;
    local tPublic = {[sClass] = function(this, cdat, super) super("Child", "A child.", nil, nil, options()); end};
    tPublic["get"..sName] = function() end;
    assert(not pcall(class, sClass, {}, {}, {}, {}, tPublic, CoGCreature));
end
for _, sName in ipairs({"getSpecies", "getFaction", "getLevel", "getAge", "getHealth", "getMana", "getStamina",
                       "setLevel", "setAge", "setFaction", "takeDamage", "heal", "spendMana", "spendStamina",
                       "isHealthDepleted", "isExhausted", "restoreResources", "cycleResources"}) do
    assert(not pcall(function() return creature[sName]; end), sName.." should not be part of generic CoGCreature.");
end
assert(not pcall(CoGCreature));
for _, tBad in ipairs({{}, {XP = {}, HP = {Max = 10, Current = 10}, StatusScope = eScope},
                       {XP = options().XP, HP = {Max = 10}, StatusScope = eScope},
                       {XP = options().XP, HP = {Max = 10, Current = 10}},
                       {XP = options().XP, HP = {Max = 10, Current = 10}, StatusScope = StatusTracker.ALL_THINGS.CREATURES.HASTENED}}) do
    assert(not pcall(CoGCreature, "Bad", "Invalid options.", nil, nil, tBad));
end
local Child = class("CreatureGenericRegressionChild", {}, {}, {}, {}, {
    CreatureGenericRegressionChild = function(this, cdat, super, eCategory)
        local tOptions = options();
        tOptions.StatusScope = eCategory;
        super("Child", "A concrete creature.", nil, nil, tOptions);
    end,
}, CoGCreature);
local child = Child(StatusTracker.ALL_THINGS.ITEMS);
assert(child.getStatusTracker().activate("DAMAGED", 2, true));
assert(not pcall(child.getStatusTracker().isActive, "HASTENED"));
assert(child.getInventory().getOwner() == child);
assert(not pcall(clone, creature));
assert(not pcall(clone, child));
print("PASS CoGCreature: explicit options, inherited metadata, six owned components, final getters/no setters, independent state, subclass scopes and removed policy APIs");
