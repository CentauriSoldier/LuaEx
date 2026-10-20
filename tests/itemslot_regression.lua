if not LUAEX_INIT then require("LuaEx.init") end
local Item = class("SlotRegressionItem", {}, {}, {}, {}, {
    SlotRegressionItem = function(this, cdat, super)
        super("Slot test", "Individual instance");
    end,
}, CoGItem);
local a, b, c = Item(), Item(), Item();
local slot = ItemSlot(nil, 2);
assert(slot.getCapacity() == 2 and not slot.isOccupied());
local _, ok = slot.set(a);
assert(ok and rawequal(a.getLocation(), slot));
_, ok = slot.set(a);
assert(not ok and #slot == 1);
assert(select(2, slot.set(b)) and #slot == 2);
assert(not select(2, slot.set(c)));
assert(not select(2, slot.setCapacity(1)) and slot.getCapacity() == 2);
local removed;
_, ok, removed = slot.set(c, true);
assert(ok and rawequal(removed, a) and a.getLocation() == null);
assert(rawequal(slot.get(), b) and #slot == 2);
slot.setLocked(true);
assert(not select(2, slot.remove()) and not select(2, slot.set(a, true)));
slot.setLocked(false).setEnabled(false);
assert(not select(2, slot.remove()));
slot.setEnabled(true);
_, ok, removed = slot.remove(c);
assert(ok and rawequal(removed, c) and c.getLocation() == null);
local other = ItemSlot(ObjectRegistry({a}), 2);
assert(not select(2, other.set(b)));
assert(select(2, other.set(a)));
assert(not select(2, slot.set(a)));
assert(not select(2, slot.swapWith(other)));
assert(rawequal(slot.get(), b) and rawequal(other.get(), a));
other.getAllowed_Items().add(CoGItem);
assert(select(2, slot.swapWith(other)));
assert(rawequal(slot.get(), a) and rawequal(other.get(), b));
assert(rawequal(a.getLocation(), slot) and rawequal(b.getLocation(), other));
local system = ItemSlotSystem({slot, other});
assert(system.getItemSlotCount() == 2 and system.getItemCount() == 2);
assert(system.containsItemAt(a, 1) and rawequal(system.getItemAt(2), b));
assert(select(2, system.swapItems(1, 2)));
assert(system.containsItemAt(b, 1));
assert(not select(2, system.swapItems(1, 1)));
local empty = ItemSlot();
assert(select(2, other.swapWith(empty)));
assert(not other.isOccupied() and empty.isOccupied());
for _, capacity in ipairs({0, -1, 1.5, math.huge}) do
    assert(not pcall(ItemSlot, nil, capacity));
end
local registry = ObjectRegistry({CoGItem}, function(item, destination)
    return rawequal(item, c) and destination.getCapacity() == 1;
end);
local filtered = ItemSlot(registry);
assert(not select(2, filtered.set(a)) and select(2, filtered.set(c)));
assert(rawequal(filtered.getAllowed_Items(), registry));
print("PASS ItemSlot: capacity, individual identity, eligibility, location, disabled/locked operations, displaced items, complete swaps and ItemSlotSystem integration");
