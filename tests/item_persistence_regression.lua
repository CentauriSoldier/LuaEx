-- Inventory persistence uses generated class snapshots plus inventory-only runtime reconnection.
-- Keep owners external; the caller explicitly reconnects them after loading.
if not LUAEX_INIT then require("LuaEx.load")() end
local Item = class("SavedInventoryItem", {}, {}, {}, {}, {
    SavedInventoryItem = function(this, cdat, super)
        super("Saved item", "Persistence test", nil, nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,CoGRegistry({ItemSystem, ItemStashSystem}));
    end,
}, BaseItem);
local oOwner = Item();
local oStash = ItemStashSystem(oOwner, 2, 4);
local oItem = Item();
assert(oStash.getTab(1).addItem(oItem));
local oRestored = deserialize(serialize(oStash));
assert(oRestored.getOwner() == null);
assert(oRestored.getTabCount() == 2 and oRestored.getTab(1).getItemCount() == 1);
local oLoaded = oRestored.getTab(1).getItemAt(1);
assert(oLoaded and not rawequal(oLoaded, oItem));
assert(rawequal(oLoaded.getLocation(), oRestored.getTab(1)));
oRestored.setOwner(oOwner);
assert(rawequal(oRestored.getTab(1).getOwner(), oOwner));
assert(select(2, oRestored.getTab(1).removeItem(oLoaded)));
assert(oRestored.getTab(2).addItem(oLoaded));
local oTwice = deserialize(serialize(oRestored));
assert(oTwice.getItemCount() == 1);
print("PASS inventory save/load, locations, local item classes, owner reconnection and resave");


-- Permission callbacks retain their captured Lua state across the round trip.
local tGate = {allowed = true};
local oRegistry = ObjectRegistry({Item}, function() return tGate.allowed, "Saved gate"; end);
local oSlot = ItemSlot(oRegistry, 2);
local oSlotted = Item();
assert(select(2, oSlot.set(oSlotted)));
tGate.allowed = false;
local oSavedSlot = deserialize(serialize(oSlot));
local oNewItem = Item();
local _, bAllowed, _, sReason = oSavedSlot.set(oNewItem);
assert(not bAllowed and sReason:find("Saved gate"));
-- Specific registry entries must resolve to the loaded stash, never the original instance.
oStash = ItemStashSystem(nil, 2, 4);
local oSpecific = Item();
oSpecific.getExclusive_In().add(oStash);
oSpecific.getExclusive_With().add(Item);
assert(oStash.getTab(2).addItem(oSpecific));
local oSpecificStash = deserialize(serialize(oStash));
local oSpecificLoaded = oSpecificStash.getTab(2).getItemAt(1);
local bFound = false;
for _, vEntry in oSpecificLoaded.getExclusive_In().eachEntry() do
    bFound = bFound or rawequal(vEntry, oSpecificStash);
end
assert(bFound, "Registry must point to the loaded stash");
-- Forward attachment membership restores the inverse host reference without duplicating items.
local oHost, oAttachment = Item(), Item();
oAttachment.getAttachable_To().add(Item);
assert(select(2, oAttachment.attachTo(oHost)));
local oHostInventory = ItemSystem();
assert(oHostInventory.addItem(oHost));
local oHostLoaded = deserialize(serialize(oHostInventory)).getItemAt(1);
local oAttachmentLoaded;
for _, oChild in oHostLoaded.eachAttachment() do oAttachmentLoaded = oChild; end
assert(oAttachmentLoaded and rawequal(oAttachmentLoaded.getAttached_To(), oHostLoaded));
assert(not rawequal(oAttachmentLoaded, oAttachment));
print("PASS registry callbacks, specific container identity and item attachments");

-- Repeated references share identity within one load, while independent loads stay independent.
local sSharedSave = serialize({oSpecific, oStash, oSpecific});
local tShared = deserialize(sSharedSave);
local tIndependent = deserialize(sSharedSave);
assert(rawequal(tShared[1], tShared[3]));
assert(rawequal(tShared[1].getLocation(), tShared[2].getTab(2)));
assert(not rawequal(tShared[1], tIndependent[1]));
local bOwnScope = false;
for _, vEntry in tIndependent[1].getExclusive_In().eachEntry() do
    bOwnScope = bOwnScope or rawequal(vEntry, tIndependent[2]);
end
assert(bOwnScope);
assert(not pcall(oRestored.setOwner, "invalid"));
assert(rawequal(oRestored.getOwner(), oOwner));
print("PASS shared item identity, independent loads and atomic owner validation");
