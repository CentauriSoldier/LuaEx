-- Independent code tutorial. Edit the values below, then Run code.
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

local D = require("examples.support.tutorial").new("Complete item containers", "Individual items, stacks, stash-wide exclusivity, transfers, equipment permissions and coordinate footprints.");

-- Edit these values, then Run code.
local nStackCapacity = 3;
local nStashTabs = 2;
local nItemsPerTab = 4;

local ExampleItem = class("ContainerExampleItem", {}, {}, {}, {}, {
    ContainerExampleItem = function(this, cdat, super, sName, tOptions)
        local t = tOptions or {};
        super(sName, "A separate item instance", nil, nil,
              nil,t.consume,nil,nil,t.equip,t.scope,t.conflicts,nil,nil,nil,
              t.storage or Registry({ItemSystem, ItemStashSystem}),t.tradeBy,t.tradeTo,t.unequip,nil,nil,
              nil,nil,nil,nil,nil,nil,t.pattern);
    end,
}, BaseItem);

D.section("Individual instances in one stack", "The slot owns capacity; items remain separate objects. Removing one preserves the others.");
local stack = ItemSlot(nil, nStackCapacity);
local apple = ExampleItem("Apple");
local pear = ExampleItem("Pear");
D.check("Insert apple", select(2, stack.set(apple)));
D.check("Insert pear", select(2, stack.set(pear)));
D.equal("Actual instance count", stack.getItemCount(), 2);
D.check("Duplicate instance rejected", not select(2, stack.set(apple)));
D.check("Location points to the actual slot", rawequal(apple.getLocation(), stack));
D.check("Remove apple", select(2, stack.remove(apple)));
D.equal("Remaining count", #stack, 1);
D.check("Removed location becomes null", apple.getLocation() == null);

D.section("Eligibility and state", "Registries can permit exact instances, classes and prerequisite callbacks. Locked or disabled slots reject changes.");
local specific = ItemSlot(ObjectRegistry({apple}));
D.check("Exact apple accepted", select(2, specific.set(apple)));
D.check("Another instance rejected", not specific.canAccept(ExampleItem("Other apple")));
specific.setLocked(true);
D.check("Locked removal rejected", not select(2, specific.remove()));
specific.setLocked(false).setEnabled(false);
D.check("Disabled removal rejected", not select(2, specific.remove()));
specific.setEnabled(true);
D.check("Enabled removal succeeds", select(2, specific.remove()));

D.section("One kite across the entire stash", "Exclusive_In selects a context; Exclusive_With selects conflicting items. Direct tab insertion still checks every stash tab.");
local stash = ItemStashSystem(nil, nStashTabs, nItemsPerTab);
local kite = ExampleItem("Unique kite", {scope = Registry({stash}), conflicts = Registry({ExampleItem})});
local secondKite = ExampleItem("Second kite");
D.check("First kite stored", select(2, stash.addItem(kite, 1)));
local targetTab = math.min(2, nStashTabs);
local accepted, _, reason = stash.getTab(targetTab).addItem(secondKite);
D.check("Conflicting item rejected in another tab", not accepted);
D.note("Rejection reason: "..tostring(reason));
D.equal("Stash count stays one", stash.getItemCount(), 1);
D.check("Rejected item stays detached", secondKite.getLocation() == null);

D.section("Transfers commit or leave everything intact", "Transfers validate the final layout. Moving within the same stash does not conflict with the item's old position.");
if nStashTabs > 1 then
    D.check("Move kite between tabs", select(2, stash.getTab(1).transferItemTo(stash.getTab(2), kite)));
end
local limited = ItemSystem(1);
D.check("Fill a one-item inventory", limited.addItem(ExampleItem("Resident")));
local source = kite.getLocation();
D.check("Transfer to full inventory rejected", not select(2, source.transferItemTo(limited, kite)));
D.check("Failed transfer preserves original location", rawequal(kite.getLocation(), source));
D.check("Remove kite from stash", select(2, stash.removeItem(kite)));
D.check("Former conflict now allowed", select(2, stash.addItem(secondKite)));

D.section("Actor permissions and consuming one item", "Administrative containment calls manage contents. Named action methods also check the corresponding actor registry; the caller implements gameplay effects.");
local actor = ExampleItem("Adventurer");
local permitsActor = ObjectRegistry({actor});
local potion = ExampleItem("Potion", {consume = permitsActor});
local inventory = ItemSystem(4);
D.check("Store potion", inventory.addItem(potion));
D.check("Wrong actor cannot consume", not select(2, inventory.consumeItem(potion, ExampleItem("Stranger"))));
D.check("Permitted actor consumes the instance", select(2, inventory.consumeItem(potion, actor)));
D.equal("Inventory now empty", inventory.getItemCount(), 0);
local sword = ExampleItem("Sword", {equip = permitsActor, unequip = permitsActor});
local equipment = ItemSlotSystem({ItemSlot()});
D.check("Store sword", inventory.addItem(sword));
D.check("Equip transfers from inventory", select(2, equipment.equipItem(sword, actor, 1)));
D.check("Unequip transfers back", select(2, equipment.unequipItem(sword, actor, inventory)));

D.section("Pure patterns and grid placement", "SlotPattern contains relative coordinates only. ItemSlotSystem checks bounds and footprint overlap; one shaped item is counted once.");
local gridSlots = {};
for i = 1, 9 do gridSlots[i] = ItemSlot(); end
local grid = ItemSlotSystem(gridSlots);
D.check("Configure 3 by 3 grid", select(2, grid.configureGrid(3, 3)));
local pattern = SlotPattern({{x = 0, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}});
local shaped = ExampleItem("L-shaped item", {pattern = pattern});
D.equal("Pattern occupied coordinate count", pattern.getSlotCount(), 3);
D.check("Place at zero-based origin", select(2, grid.placeItem(shaped, 0, 0)));
D.equal("Actual item count", grid.getItemCount(), 1);
D.check("Offset cell refers to the same item", rawequal(grid.getOccupantAt(1, 1), shaped));
D.check("Overlapping placement rejected", not select(2, grid.placeItem(ExampleItem("Blocked"), 1, 1)));
D.check("Grid consistency", grid.validate());

D.section("Ground and shop inventories", "The same ItemSystem class can represent any inventory. Its owner is metadata; item legality and prices are application policy.");
local merchant = ExampleItem("Merchant");
local ground = ItemSystem(20);
local shop = ItemSystem(8, nil, merchant);
local goods = ExampleItem("Trade goods", {tradeBy = ObjectRegistry({merchant}), tradeTo = ObjectRegistry({actor})});
D.check("Place stock in the shop", shop.addItem(goods));
D.check("Shop retains its owner", rawequal(shop.getOwner(), merchant));
D.check("Ground has no owner", ground.getOwner() == null);
D.check("Wrong trader is rejected without moving stock", not select(2, shop.tradeItemTo(inventory, goods, actor, actor)));
D.check("Merchant can trade to the allowed recipient", select(2, shop.tradeItemTo(inventory, goods, merchant, actor)));
D.check("Successful trade updates actual location", rawequal(goods.getLocation(), inventory));
D.check("Drop through an administrative transfer", select(2, inventory.transferItemTo(ground, goods)));
D.equal("Ground item count", ground.getItemCount(), 1);

D.section("Capacity, clearing and live edits", "Containers reject capacity reductions that would lose items. Registries and Pools remain mutable objects exposed through getters.");
D.check("Cannot shrink ground below its contents", not select(2, ground.setMaxItems(0)));
goods.getWeight().set(0.5);
D.equal("Editable item Pool", goods.getWeight().get(), 0.5);
local _, cleared, removed = ground.clear();
D.check("Clear succeeds", cleared);
D.equal("Clear returns exactly one removed instance", #removed, 1);
D.check("Cleared item becomes unplaced", goods.getLocation() == null);
D.note("Durability zero does not destroy an item. Prices, damage/repair effects and upgrade effects are caller policy. Concrete item subclasses define copying.");
D.finish();
