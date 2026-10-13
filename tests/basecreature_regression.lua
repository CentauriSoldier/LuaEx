if not LUAEX_INIT then require("LuaEx.init") end
local creature = BaseCreature("Bob", "A soldier.", nil, nil, {Species = "Human", Faction = "Guard", Level = 3});
local other = BaseCreature();
assert(creature.getName() == "Bob" and creature.getSpecies() == "Human" and creature.getLevel() == 3);
assert(not rawequal(creature.getHealth(), other.getHealth()));
assert(select(2, creature.takeDamage(30)) == 30 and creature.getHealth().get() == 70);
assert(select(2, creature.heal(100)) == 30);
assert(not select(2, creature.spendMana(101)) and creature.getMana().get() == 100);
assert(select(2, creature.spendMana(40)) and creature.getMana().get() == 60);
assert(select(2, creature.spendStamina(100)) and creature.isExhausted());
creature.takeDamage(200);
assert(creature.isHealthDepleted());
creature.restoreResources().setAge(20).setLevel(4).setFaction("Free");
assert(not creature.isExhausted() and not creature.isHealthDepleted() and creature.getFaction() == "Free");
local health = Pool(20, 10);
assert(rawequal(BaseCreature(nil, nil, nil, nil, {Health = health}).getHealth(), health));
assert(not pcall(creature.takeDamage, -1));
assert(not pcall(BaseCreature, nil,nil,nil,nil,{Level = 0}));
local Child = class("CreatureBasicRegressionChild", {}, {}, {}, {}, {
    CreatureBasicRegressionChild = function(this, cdat, super)
        super("Child", "A concrete creature.");
    end,
}, BaseCreature);
assert(Child().getHealth().get() == 100);
print("PASS BaseCreature: superclass metadata, independent/supplied Pools, traits, clamped healing/damage, spending, depletion, restore and subclass construction");
