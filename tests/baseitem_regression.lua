if not LUAEX_INIT then require("LuaEx.init") end

local Item = class("BaseItemRegressionItem", {}, {}, {}, {}, {
    BaseItemRegressionItem = function(this, cdat, super, tInput)
        local t = tInput or {};
        super("Test item", "An individual item", nil, nil,
              t.attach, t.consume, t.damage, t.detach, t.equip, t.exclusiveIn, t.exclusiveWith, t.inimitable,
              t.remove, t.repair, t.store, t.tradeBy, t.tradeTo, t.unequip, t.upgrade, t.downgrade,
              t.durability, t.size, t.value, t.weight, t.host, t.location, t.pattern);
    end,

}, BaseItem);
local first, second = Item(), Item();
assert(first.getName() == "Test item");
assert(first.getDurability().get() == 1);
assert(first.getSize().get() == 0 and first.getValue().get() == 0 and first.getWeight().get() == 0);
assert(first.getDurability() ~= second.getDurability());
assert(first.getSize() ~= second.getSize());
assert(first.getAttachable_To() ~= second.getAttachable_To());
assert(first.getTradable_By() ~= first.getTradable_To());
assert(first.getAttachable_To().getCount() == 0);
assert(first.getAttached_To() == null and first.getLocation() == null);
assert(not first.isInimitable());
assert(first.getSlot_Pattern().getSlotCount() == 0);
assert(not rawequal(first.getSlot_Pattern(), second.getSlot_Pattern()));
first.getSlot_Pattern().setSlots({{x = 0, y = 0}});
assert(second.getSlot_Pattern().getSlotCount() == 0);
local slots = ItemSlotSystem(nil, first);
assert(first.getExclusive_In().allows(slots));
local otherSlots = ItemSlotSystem(nil, second);
local scoped = Item({exclusiveIn = slots});
assert(scoped.getExclusive_In().allows(slots) and not scoped.getExclusive_In().allows(otherSlots));
local damage = ObjectRegistry({CoG});
local size = Pool(10, 3);
local specific = CoGRegistry({slots});
local pattern = SlotPattern({{x = 0, y = 0}, {x = 1, y = 0}});
local supplied = Item({damage = damage, size = size, exclusiveIn = specific,
                       host = first, location = slots, inimitable = true, pattern = pattern});
assert(rawequal(supplied.getDamageable_By(), damage));
assert(rawequal(supplied.getSize(), size));
assert(rawequal(supplied.getExclusive_In(), specific));
assert(supplied.getAttached_To() == first and supplied.getLocation() == slots);
assert(supplied.isInimitable() and rawequal(supplied.getSlot_Pattern(), pattern));
damage.clear();
assert(supplied.getDamageable_By().getCount() == 0);
first.getDurability().setEmpty();
assert(second.getDurability().get() == 1);
for _,input in ipairs({{damage = CoGRegistry()}, {value = 0}, {exclusiveIn = Point(0,0)},
                       {inimitable = "false"}, {host = Point(0,0)}, {location = {}}, {pattern = -1}, {pattern = {}}, {pattern = SlotPattern}, {pattern = Pool(1, 0)}}) do
    assert(not pcall(Item, input), "Expected invalid constructor input to fail");
end

local Cloneable;
Cloneable = class("BaseItemRegressionCloneable", {
    __clone = function(this, cdat)
        return Cloneable(this.isInimitable());
    end,

}, {}, {}, {}, {
    BaseItemRegressionCloneable = function(this, cdat, super, bInimitable)
        super("Cloneable", "Caller-defined copying", nil, nil,
              nil,nil,nil,nil,nil,nil,nil,bInimitable);
    end,

}, BaseItem);
assert(clone(Cloneable(true)).isInimitable());
print("PASS BaseItem: real superclass construction, independent defaults, registry directives, slot-system scope, supplied identity, Pools, validation and caller-defined cloning");
