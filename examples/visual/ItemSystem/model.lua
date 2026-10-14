-- Application policy lives here; containment, registries and footprints are LuaEx.
local M = {};
local World;
local Item;
local kinds = {"Weapon", "Armor", "Potion", "Gem", "Material", "Relic", "Quest", "Tool"};
local races = {"Any", "Human", "Elf", "Goblin"};
local scopes = {"None", "Stash", "Character", "Shop", "Everywhere"};
local storageModes = {"Anywhere", "Player storage", "Ground only", "Shop only", "Nowhere"};
local defaults = {name = "New item", description = "An editable item.", kind = "Tool", owner = "none", rarity = 1,
    durabilityMax = 100, durability = 100, value = 10, weight = 1, size = 1, level = 1, strength = 0,
    race = "Any", storage = "Anywhere", exclusive = "None", group = "", pattern = "0,0",
    consumable = false, equipable = false, damageable = true, repairable = true, removable = true,
    tradableBy = true, tradableTo = true, upgradeable = false, downgradable = false, detachable = true, inimitable = false};

local Actor = class("ItemLabActor", {}, {}, {}, {
    Key__autoA_ = "", Name__autoA_ = "", Race__autoA_ = "", Level__autoA_ = 1, Strength__autoA_ = 0,
}, {
    ItemLabActor = function(this, cdat, super, sKey, sName, sRace, nLevel, nStrength)
        super();
        local pro = cdat.pro;
        pro.Key, pro.Name, pro.Race, pro.Level, pro.Strength = sKey, sName, sRace, nLevel, nStrength;
    end,
}, CoG);

local function number(nValue, nMin, nMax, bInteger)
    assert(rawtype(nValue) == "number" and nValue == nValue and nValue >= nMin and nValue <= nMax and
           (not bInteger or nValue % 1 == 0), "Enter a number in "..nMin..".."..nMax..(bInteger and " (whole number)" or ""));
    return nValue;
end

local function choice(vValue, tChoices)

    for _, vAllowed in ipairs(tChoices) do

        if (vValue == vAllowed) then
            return vValue;
        end

    end

    error("Unknown option: "..tostring(vValue));
end

local function config(tInput)
    assert(rawtype(tInput) == "table", "Item properties must be a table.");
    local tConfig = {};

    for sKey, vDefault in pairs(defaults) do
        local vValue = tInput[sKey];

        if (vValue == nil) then
            tConfig[sKey] = vDefault;
        else
            tConfig[sKey] = vValue;
        end
        assert(rawtype(tConfig[sKey]) == rawtype(vDefault), "Invalid property: "..sKey);
    end

    assert(tConfig.name:find("%S") and #tConfig.name <= 80, "Name must contain 1..80 characters.");
    assert(#tConfig.description <= 300 and #tConfig.group <= 40 and #tConfig.pattern <= 300, "Text is too long.");
    choice(tConfig.kind, kinds);
    choice(tConfig.race, races);
    choice(tConfig.exclusive, scopes);
    choice(tConfig.storage, storageModes);
    assert(tConfig.owner == "none" or World.actors[tConfig.owner], "Unknown item owner.");
    number(tConfig.rarity, 1, #Rarity.LEVEL, true);
    number(tConfig.durabilityMax, 1, 10000);
    number(tConfig.durability, 0, tConfig.durabilityMax);
    number(tConfig.value, 0, 10000);
    number(tConfig.weight, 0, 1000);
    number(tConfig.size, 0, 1000);
    number(tConfig.level, 1, 100, true);
    number(tConfig.strength, 0, 100);
    local tOffsets = {};

    for sPair in tConfig.pattern:gmatch("[^;\n]+") do
        local sX, sY = sPair:match("^%s*(-?%d+)%s*,%s*(-?%d+)%s*$");
        assert(sX, "Pattern format: x,y; x,y. Coordinates are relative integers.");
        tOffsets[#tOffsets + 1] = {x = number(tonumber(sX), -5, 5, true), y = number(tonumber(sY), -5, 5, true)};
    end

    assert(#tOffsets <= 25, "Use at most 25 footprint coordinates.");
    return tConfig, SlotPattern(tOffsets);
end

local function actorRegistry(bAllowed, fRule)
    return bAllowed and ObjectRegistry({Actor}, fRule) or ObjectRegistry();
end

local function owns(oActor, oItem)
    return oItem.getTrait("owner") == "none" or oItem.getTrait("owner") == oActor.getKey();
end

local function fields(tInput)
    local c, oPattern = config(tInput);
    local oStorage;

    if (c.storage == "Anywhere") then
        oStorage = CoGRegistry({ItemSystem, ItemSlotSystem, ItemStashSystem});
    elseif (c.storage == "Player storage") then
        oStorage = CoGRegistry({World.inventory, World.stash});
    elseif (c.storage == "Ground only") then
        oStorage = CoGRegistry({World.ground});
    elseif (c.storage == "Shop only") then
        oStorage = CoGRegistry({World.shop});
    else
        oStorage = CoGRegistry();
    end

    local oScope = CoGRegistry();

    if (c.exclusive == "Stash") then
        oScope.add(World.stash);
    elseif (c.exclusive == "Character") then
        oScope.add(World.inventory);
    elseif (c.exclusive == "Shop") then
        oScope.add(World.shop);
    elseif (c.exclusive == "Everywhere") then
        oScope = CoGRegistry({ItemSystem, ItemSlotSystem, ItemStashSystem});
    end

    local oConflict = c.group ~= "" and CoGRegistry({Item}, function(oOther, oRuleOwner)
        return oOther.getTrait("group") == oRuleOwner.getTrait("group");
    end) or CoGRegistry();
    local oAttach = c.kind == "Gem" and ObjectRegistry({Item}, function(oHost)
        return oHost.getTrait("kind") == "Weapon";
    end) or ObjectRegistry();
    local oEquip = actorRegistry(c.equipable, function(oActor, oItem)
        return owns(oActor, oItem) and oActor.getLevel() >= oItem.getTrait("level") and
               oActor.getStrength() >= oItem.getTrait("strength") and
               (oItem.getTrait("race") == "Any" or oItem.getTrait("race") == oActor.getRace()),
               "Ownership, race, level or strength prerequisite failed.";
    end);
    local tFields = {
        Name = c.name, Description = c.description, Rarity = Rarity.LEVEL[c.rarity],
        Attachable_To = oAttach, Consumable_By = actorRegistry(c.consumable, owns),
        Damageable_By = actorRegistry(c.damageable), Detachable_By = actorRegistry(c.detachable),
        Equipable_By = oEquip, Exclusive_In = oScope, Exclusive_With = oConflict,
        Inimitable = c.inimitable, Removable_By = actorRegistry(c.removable, owns),
        Repairable_By = actorRegistry(c.repairable), Storable_In = oStorage,
        Tradable_By = actorRegistry(c.tradableBy, owns), Tradable_To = actorRegistry(c.tradableTo),
        Unequippable_By = actorRegistry(c.equipable, owns),
        Upgradeable_By = actorRegistry(c.upgradeable, owns), Downgradable_By = actorRegistry(c.downgradable, owns),
        Durability = Pool(c.durabilityMax, c.durability), Size = Pool(math.max(1, c.size), c.size),
        Value = Pool(math.max(1, c.value), c.value), Weight = Pool(math.max(1, c.weight), c.weight), Slot_Pattern = oPattern,
    };
    return c, tFields;
end

Item = class("ItemLabItem", {
    __clone = function(this)
        return Item(this.getConfig());
    end,
}, {}, {config = {}}, {}, {
    ItemLabItem = function(this, cdat, super, tInput)
        local c, f = fields(tInput);
        super(c.name, c.description, f.Rarity, nil,
            f.Attachable_To, f.Consumable_By, f.Damageable_By, f.Detachable_By, f.Equipable_By,
            f.Exclusive_In, f.Exclusive_With, c.inimitable, f.Removable_By, f.Repairable_By, f.Storable_In,
            f.Tradable_By, f.Tradable_To, f.Unequippable_By, f.Upgradeable_By, f.Downgradable_By,
            f.Durability, f.Size, f.Value, f.Weight, nil, nil, f.Slot_Pattern);
        cdat.pri.config = c;
    end,

    getTrait = function(this, cdat, sName)
        return cdat.pri.config[sName];
    end,

    getConfig = function(this, cdat)
        local c = clone(cdat.pri.config);
        c.durability, c.durabilityMax = this.getDurability().get(), this.getDurability().get(Pool.ASPECT.MAX);
        return c;
    end,

    configure = function(this, cdat, tInput)
        local c, tFields = fields(tInput);
        local tPrevious, tOldConfig = {}, cdat.pri.config;

        for sField, oValue in pairs(tFields) do
            tPrevious[sField] = cdat.pro[sField];
            cdat.pro[sField] = oValue;
        end

        cdat.pri.config = c;
        local bOK, sReason = pcall(function()
            local oLocation = this.getLocation();

            if (oLocation ~= null) then
                local bValid, sFailure = oLocation.validate();
                assert(bValid, sFailure);
                local bStored = false;
                local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

                for _, oContext in ipairs(Rules.scopes(oLocation)) do

                    if (this.canStoreIn(oContext)) then
                        bStored = true;
                    end

                end

                assert(bStored, "The edited storage rule does not permit the current container. Move the item first.");
            end

            if (this.getAttached_To() ~= null) then
                assert(this.canAttachTo(this.getAttached_To()), "The edited item cannot stay attached to this host.");
            end

            for _, oAttachment in this.eachAttachment() do
                assert(oAttachment.canAttachTo(this), "An attached gem no longer accepts this host.");
            end

        end);

        if (not bOK) then

            for sField, vValue in pairs(tPrevious) do
                cdat.pro[sField] = vValue;
            end

            cdat.pri.config = tOldConfig;
            return false, tostring(sReason);
        end

        return true;
    end,

    -- Deletion is a lab-management operation, distinct from gameplay detach.
    detachForLab = function(this, cdat, oActor)
        local oPrevious = cdat.pro.Detachable_By;
        cdat.pro.Detachable_By = ObjectRegistry({oActor});
        local _, bOK, sReason = this.detach(oActor);
        cdat.pro.Detachable_By = oPrevious;
        return bOK, sReason;
    end,
}, BaseItem);

local function log(sText, bOK)
    World.message, World.ok = sText, bOK ~= false;
    World.events[#World.events + 1] = sText;

    if (#World.events > 60) then
        table.remove(World.events, 1);
    end

end

local function record(nID)
    local tRecord = World.records[tonumber(nID)];
    assert(tRecord and not tRecord.retired, "Select a live item first.");
    return tRecord;
end

local function actor()
    return World.actors[World.actor];
end

local function destination(sKey, nSlot)

    if (sKey == "character") then
        return World.inventory.getItemSlotAt(number(nSlot or 13, 1, 16, true));
    elseif (sKey == "stash") then
        return World.stash.getTab(World.tab);
    elseif (sKey == "ground") then
        return World.ground;
    elseif (sKey == "shop") then
        return World.shop;
    end

    error("Choose a destination inventory.");
end

local function where(oItem)
    local oLocation = oItem.getLocation();

    if (oLocation == null) then

        if (oItem.getAttached_To() ~= null) then
            return "attached", "Attached to "..oItem.getAttached_To().getName();
        end

        return "unplaced", "Unplaced";
    end

    if (World.inventory.containsItem(oItem)) then
        local _, nSlot = World.inventory.containsItem(oItem);
        return "character", "Character · slot "..nSlot, nSlot;
    end

    local bFound, nTab = World.stash.containsItem(oItem);

    if (bFound) then
        return "stash", "Stash · tab "..nTab, nTab;
    end

    if (rawequal(oLocation, World.ground)) then
        return "ground", "Ground";
    end

    if (rawequal(oLocation, World.shop)) then
        return "shop", "Shop";
    end

    return "unplaced", "Unplaced";
end

local function move(oItem, oDestination, bReplace)
    local oSource = oItem.getLocation();
    local _, bOK, oRemoved, sReason;

    if (oSource == null) then
        assert(oItem.getAttached_To() == null, "Detach the item before moving it.");

        if (class.of(oDestination) == ItemSlot) then
            _, bOK, oRemoved, sReason = oDestination.set(oItem, bReplace);
        else
            bOK, _, sReason = oDestination.addItem(oItem);
        end

    else
        _, bOK, oRemoved, sReason = oSource.transferItemTo(oDestination, oItem, bReplace);
    end

    assert(bOK, sReason or "Move rejected.");
    return oRemoved;
end

local function make(tInput, sDestination, nSlot)
    local nLive = 0;

    for _, tRecord in pairs(World.records) do

        if (not tRecord.retired) then
            nLive = nLive + 1;
        end

    end

    assert(nLive < 80, "The lab supports 80 live items. Delete an item first.");
    local oItem = Item(tInput);
    local nID = World.nextID;
    World.nextID = nID + 1;
    local tRecord = {id = nID, item = oItem, retired = false};
    World.records[nID] = tRecord;
    World.selected = nID;

    if (sDestination and sDestination ~= "unplaced") then
        local bOK, sReason = pcall(move, oItem, destination(sDestination, nSlot));

        if (not bOK) then
            return tRecord, "Created unplaced: requested insertion was rejected. "..tostring(sReason);
        end

    end

    return tRecord;
end

local seeds = {
    {name = "Iron longsword", kind = "Weapon", owner = "player", value = 45, weight = 3, size = 2, durability = 80,
     equipable = true, strength = 6, upgradeable = true, downgradable = true, pattern = "0,0;1,0", dest = "character", slot = 9},
    {name = "Oak hunting bow", kind = "Weapon", owner = "player", value = 60, weight = 2, size = 3, durability = 65,
     equipable = true, level = 4, pattern = "0,0;0,1;0,2", dest = "character", slot = 4},
    {name = "Greater health potion", kind = "Potion", owner = "player", value = 12, weight = 0.2, consumable = true,
     durabilityMax = 1, durability = 1, damageable = false, repairable = false, dest = "character", slot = 3},
    {name = "Lesser health potion", kind = "Potion", value = 5, weight = 0.1, consumable = true,
     durabilityMax = 1, durability = 1, damageable = false, repairable = false, dest = "ground"},
    {name = "Mana draught", kind = "Potion", owner = "player", value = 15, weight = 0.2, consumable = true,
     durabilityMax = 1, durability = 1, dest = "character", slot = 7},
    {name = "Round oak shield", kind = "Armor", owner = "player", value = 35, weight = 4, size = 4,
     equipable = true, strength = 5, pattern = "0,0;1,0;0,1;1,1", dest = "character", slot = 1},
    {name = "Leather trail boots", kind = "Armor", owner = "player", value = 20, equipable = true, dest = "stash", tab = 1},
    {name = "Traveler's cloak", kind = "Armor", owner = "player", value = 18, durability = 40, equipable = true, dest = "stash", tab = 1},
    {name = "Wind kite", kind = "Relic", owner = "player", value = 40, group = "kite", exclusive = "Stash", dest = "stash", tab = 1},
    {name = "Festival kite", kind = "Relic", owner = "merchant", value = 70, group = "kite", exclusive = "Stash", dest = "shop"},
    {name = "Bound signet", kind = "Relic", owner = "player", value = 100, equipable = true,
     tradableBy = false, tradableTo = false, inimitable = true, storage = "Player storage", dest = "character", slot = 11},
    {name = "Crypt quest key", kind = "Quest", owner = "player", value = 0, storage = "Player storage", removable = false,
     tradableBy = false, tradableTo = false, inimitable = true, damageable = false, dest = "stash", tab = 2},
    {name = "Ruby focus gem", kind = "Gem", value = 90, weight = 0.1, rarity = 2, dest = "ground"},
    {name = "Silver moon gem", kind = "Gem", owner = "merchant", value = 35, weight = 0.1, rarity = 2, dest = "shop"},
    {name = "Rough iron ore", kind = "Material", value = 3, weight = 5, size = 2, pattern = "0,0;1,0", dest = "ground"},
    {name = "Refined iron ingot", kind = "Material", owner = "merchant", value = 9, weight = 2, dest = "shop"},
    {name = "Elven sentinel helm", kind = "Armor", owner = "merchant", value = 80, equipable = true, race = "Elf",
     level = 10, strength = 8, rarity = 2, dest = "shop"},
    {name = "Tainted talisman", kind = "Relic", value = 5, durability = 5, repairable = false,
     group = "talisman", exclusive = "Everywhere", dest = "ground"},
    {name = "Ancient coast map", kind = "Quest", owner = "player", value = 55, damageable = false, dest = "stash", tab = 2},
    {name = "Field repair kit", kind = "Tool", owner = "player", value = 25, consumable = true, dest = "stash", tab = 3},
};

local function reset()
    World = {records = {}, events = {}, nextID = 1, selected = 1, tab = 1, actor = "player", message = "Ready", ok = true,
        actors = {player = Actor("player", "Adventurer", "Human", 7, 8), merchant = Actor("merchant", "Merchant", "Elf", 12, 10),
                  visitor = Actor("visitor", "Goblin visitor", "Goblin", 2, 3)}, coins = {player = 120, merchant = 200, visitor = 25}};
    local tSlots = {};

    for nIndex = 1, 16 do
        tSlots[nIndex] = ItemSlot(nil, 3, nil, "Cell "..nIndex);
    end

    World.inventory = ItemSlotSystem(tSlots, World.actors.player);
    assert(select(2, World.inventory.configureGrid(4, 4)));
    World.stash = ItemStashSystem(World.actors.player, 3, 8);
    World.ground = ItemSystem(40);
    World.shop = ItemSystem(12, nil, World.actors.merchant);

    for _, tSeed in ipairs(seeds) do
        World.tab = tSeed.tab or 1;
        local _, sReason = make(tSeed, tSeed.dest, tSeed.slot);
        assert(not sReason, sReason);
    end

    World.tab, World.selected = 1, 1;
    log("20 real BaseItem instances. Try moving Festival kite into any stash tab: Wind kite makes it exclusive across the whole stash.");
end

local function itemView(tRecord)
    local oItem = tRecord.item;
    local sWhere, sLocation, nIndex = where(oItem);
    local c = oItem.getConfig();
    local tAttachments = {};

    for _, oAttached in oItem.eachAttachment() do
        tAttachments[#tAttachments + 1] = oAttached.getName();
    end

    return {id = tRecord.id, name = oItem.getName(), kind = c.kind, owner = c.owner, ownerName = c.owner == "none" and "Unowned" or World.actors[c.owner].getName(),
        where = sWhere, location = sLocation, index = nIndex or 0, config = c, rarity = tostring(oItem.getRarity()),
        health = c.durability, maximum = c.durabilityMax, value = oItem.getValue().get(), weight = oItem.getWeight().get(),
        footprint = oItem.getSlot_Pattern().getSlotCount(), attachments = tAttachments,
        canEquip = oItem.canEquipBy(actor()), canConsume = oItem.canConsumeBy(actor()), canRepair = oItem.canRepairBy(actor()),
        canDamage = oItem.canDamageBy(actor()), canRemove = oItem.canRemoveBy(actor()), canTradeBy = oItem.canTradeBy(actor()),
        canTradeTo = oItem.canTradeTo(actor()), canUpgrade = oItem.canUpgradeBy(actor()), canDowngrade = oItem.canDowngradeBy(actor()),
        canDetach = oItem.canDetachBy(actor())};
end

local function view()
    local tItems, tActors, tTabs, tSlots = {}, {}, {}, {};
    local tRarities = {};

    for nIndex = 1, #Rarity.LEVEL do
        tRarities[#tRarities + 1] = tostring(Rarity.LEVEL[nIndex]);
    end
    local nLive, nRetired = 0, 0;

    for nID = 1, World.nextID - 1 do
        local tRecord = World.records[nID];

        if (tRecord.retired) then
            nRetired = nRetired + 1;
        else
            nLive = nLive + 1;
            tItems[#tItems + 1] = itemView(tRecord);
        end

    end

    for _, sKey in ipairs({"player", "merchant", "visitor"}) do
        local oActor = World.actors[sKey];
        tActors[#tActors + 1] = {key = sKey, name = oActor.getName(), race = oActor.getRace(), level = oActor.getLevel(),
                                strength = oActor.getStrength(), coins = World.coins[sKey]};
    end

    for nTab, oTab in World.stash.eachTab() do
        tTabs[#tTabs + 1] = {index = nTab, count = oTab.getItemCount(), capacity = oTab.getMaxItems(), locked = oTab.isLocked(), enabled = oTab.isEnabled()};
    end

    local nWidth = World.inventory.getGridSize();

    for nIndex, oSlot in World.inventory.eachItemSlot() do
        local tIDs = {};

        if (nWidth) then
            local oOccupant = World.inventory.getOccupantAt((nIndex - 1) % 4, math.floor((nIndex - 1) / 4));

            if (oOccupant) then

                for _, tRecord in pairs(World.records) do

                    if (not tRecord.retired and rawequal(tRecord.item, oOccupant)) then
                        tIDs[#tIDs + 1] = tRecord.id;
                        break;
                    end

                end

            end

        else

            for _, oItem in oSlot.eachItem() do

                for _, tRecord in pairs(World.records) do

                    if (not tRecord.retired and rawequal(tRecord.item, oItem)) then
                        tIDs[#tIDs + 1] = tRecord.id;
                        break;
                    end

                end

            end

        end

        tSlots[#tSlots + 1] = {index = nIndex, ids = tIDs, count = oSlot.getItemCount(), capacity = oSlot.getCapacity(), locked = oSlot.isLocked(), enabled = oSlot.isEnabled()};
    end

    local tSelected;

    for _, tItem in ipairs(tItems) do

        if (tItem.id == World.selected) then
            tSelected = tItem;
        end

    end

    return {visual = "items", items = tItems, selected = tSelected or false, selectedID = World.selected,
        actors = tActors, actor = World.actor, tabs = tTabs, tab = World.tab, slots = tSlots, grid = nWidth ~= nil,
        totals = {live = nLive, retired = nRetired, character = World.inventory.getItemCount(), stash = World.stash.getItemCount(),
                  ground = World.ground.getItemCount(), shop = World.shop.getItemCount()},
        capacities = {ground = World.ground.getMaxItems(), shop = World.shop.getMaxItems()},
        containers = {character = {enabled = World.inventory.isEnabled(), locked = World.inventory.isLocked()},
            stash = {enabled = World.stash.isEnabled(), locked = World.stash.isLocked()},
            ground = {enabled = World.ground.isEnabled(), locked = World.ground.isLocked()},
            shop = {enabled = World.shop.isEnabled(), locked = World.shop.isLocked()}},
        message = World.message, ok = World.ok, events = clone(World.events), defaults = clone(defaults),
        choices = {kinds = kinds, races = races, scopes = scopes, storage = storageModes, rarities = #Rarity.LEVEL, rarityNames = tRarities}};
end

local function action(sAction, tData)
    tData = tData or {};
    local bOK, sReason = pcall(function()

        if (sAction == "view") then
            return;
        elseif (sAction == "reset") then
            reset();
            return;
        elseif (sAction == "select") then
            World.selected = record(tData.id).id;
            return;
        elseif (sAction == "actor") then
            assert(World.actors[tData.key], "Unknown actor.");
            World.actor = tData.key;
            log("Active actor: "..actor().getName()..". Permission indicators now use this actor.");
            return;
        elseif (sAction == "tab") then
            assert(World.stash.getTab(number(tData.tab, 1, 8, true)), "Tab does not exist.");
            World.tab = tData.tab;
            return;
        elseif (sAction == "addTab") then
            assert(World.stash.getTabCount() < 8, "The lab supports eight stash tabs.");
            local _, bAdded, _, sFailure = World.stash.addTab();
            assert(bAdded, sFailure);
            World.tab = World.stash.getTabCount();
            log("Added stash tab "..World.tab..". Stash exclusivity still checks every tab.");
            return;
        elseif (sAction == "removeTab") then
            local _, bRemoved, sFailure = World.stash.removeTab(World.tab);
            assert(bRemoved, sFailure);
            World.tab = math.min(World.tab, World.stash.getTabCount());
            log("Removed an empty stash tab.");
            return;
        elseif (sAction == "grid") then
            local _, bChanged, sFailure;

            if (tData.enabled) then
                _, bChanged, sFailure = World.inventory.configureGrid(4, 4);
            else
                _, bChanged, sFailure = World.inventory.disableGrid();
            end

            assert(bChanged, sFailure);
            log(tData.enabled and "Grid mode: shapes reserve their actual cells; overlap and bounds are checked." or
                "Stack mode: every slot holds individual instances up to its count limit; shapes remain coordinate data.");
            return;
        elseif (sAction == "container") then
            local oContainer = ({character = World.inventory, stash = World.stash, ground = World.ground, shop = World.shop})[tData.key];
            assert(oContainer, "Unknown container.");
            assert(rawtype(tData.enabled) == "boolean" and rawtype(tData.locked) == "boolean", "Invalid container flags.");
            oContainer.setEnabled(tData.enabled).setLocked(tData.locked);
            log("Updated "..tData.key.." enabled/locked state. Reads remain available.");
            return;
        elseif (sAction == "capacity") then
            local nCapacity = number(tData.capacity, 1, 80, true);
            local oTarget = destination(tData.key, tData.slot);
            local _, bChanged, sFailure;

            if (tData.key == "character") then
                _, bChanged, sFailure = oTarget.setCapacity(nCapacity);
            else
                _, bChanged, sFailure = oTarget.setMaxItems(nCapacity);
            end

            assert(bChanged, sFailure);
            log("Changed "..tData.key.." capacity to "..nCapacity..". No items were discarded.");
            return;
        elseif (sAction == "slotState") then
            local oSlot = destination("character", tData.slot);
            assert(rawtype(tData.enabled) == "boolean" and rawtype(tData.locked) == "boolean", "Invalid slot flags.");
            oSlot.setEnabled(tData.enabled).setLocked(tData.locked);
            log("Updated character slot "..tData.slot..". Grid operations honor all affected footprint cells.");
            return;
        elseif (sAction == "create") then
            local tRecord, sFailure = make(tData.config, tData.destination or "unplaced", tData.slot);
            log(sFailure or ("Created "..tRecord.item.getName().." (#"..tRecord.id..")."));
            return;
        elseif (sAction == "clear") then
            local oContainer = ({character = World.inventory, stash = World.stash, ground = World.ground, shop = World.shop})[tData.key];
            assert(oContainer, "Unknown container.");
            local _, bCleared, tRemoved, sFailure = oContainer.clear();
            assert(bCleared, sFailure);
            log("Cleared "..tData.key..": "..#tRemoved.." instances are now unplaced, ready to move elsewhere.");
            return;
        elseif (sAction == "validate") then
            for _, oContainer in ipairs({World.inventory, World.stash, World.ground, World.shop}) do
                local bValid, sFailure = oContainer.validate();
                assert(bValid, sFailure);
            end
            log("All four container hierarchies are consistent: locations, membership, capacity, eligibility, exclusivity and footprints.");
            return;
        end

        local tRecord = record(tData.id or World.selected);
        local oItem = tRecord.item;
        World.selected = tRecord.id;

        if (sAction == "edit") then
            local bChanged, sFailure = oItem.configure(tData.config);
            assert(bChanged, sFailure);
            log("Properties applied to "..oItem.getName()..". Existing contents and rules were validated; failed edits keep the previous item.");
        elseif (sAction == "unplace") then
            local oSource = oItem.getLocation();
            assert(oSource ~= null, "Item is already unplaced or attached.");
            local _, bRemoved, _, sFailure;

            if (class.of(oSource) == ItemSlot) then
                _, bRemoved, _, sFailure = oSource.remove(oItem);
            else
                _, bRemoved, _, sFailure = oSource.removeItem(oItem);
            end

            assert(bRemoved, sFailure);
            log("Took "..oItem.getName().." out of storage (lab operation). It can now be attached or moved.");
        elseif (sAction == "swap") then
            local bFound, nSourceSlot = World.inventory.containsItem(oItem);
            assert(bFound, "Select an item in the character inventory.");
            local _, bSwapped, sFailure = World.inventory.swapItems(nSourceSlot, number(tData.slot, 1, 16, true));
            assert(bSwapped, sFailure);
            log("Swapped complete slot contents after validating both destinations.");
        elseif (sAction == "move") then
            local oTarget = destination(tData.destination, tData.slot);
            local bStored = oItem.canStoreIn(oTarget);

            if (tData.destination == "character") then
                bStored = bStored or oItem.canStoreIn(World.inventory);
            elseif (tData.destination == "stash") then
                bStored = bStored or oItem.canStoreIn(World.stash);
            end

            assert(bStored, "Storable_In does not permit this destination.");
            local oRemoved = move(oItem, oTarget, tData.replace == true);
            log("Moved "..oItem.getName().." to "..select(2, where(oItem)).." (administrative containment)."..
                (oRemoved and (" Replaced "..oRemoved.getName().."; it is now unplaced.") or ""));
        elseif (sAction == "equip") then
            local _, bEquipped, _, sFailure = World.inventory.equipItem(oItem, actor(), number(tData.slot, 1, 16, true));
            assert(bEquipped, sFailure);
            log("Equipped "..oItem.getName().." using "..actor().getName().."'s race, ownership, level and strength prerequisites.");
        elseif (sAction == "unequip") then
            assert(tData.destination ~= "character", "Choose stash, ground or shop for unequipping.");
            local _, bMoved, _, sFailure = World.inventory.unequipItem(oItem, actor(), destination(tData.destination, tData.slot));
            assert(bMoved, sFailure);
            log("Unequipped "..oItem.getName().." to "..select(2, where(oItem))..".");
        elseif (sAction == "buy" or sAction == "sell") then
            local oSource = oItem.getLocation();
            assert(oSource ~= null, "The item is not in an inventory.");
            local oTrader, oRecipient, oTarget;

            if (sAction == "buy") then
                assert(rawequal(oSource, World.shop), "Select shop stock to buy.");
                assert(World.actor ~= "merchant", "Choose the adventurer or visitor as buyer.");
                assert(tData.destination ~= "shop", "Choose character, stash or ground as the purchase destination.");
                oTrader, oRecipient, oTarget = World.actors.merchant, actor(), destination(tData.destination, tData.slot);
            else
                assert(not rawequal(oSource, World.shop), "The item is already in the shop.");
                assert(World.actor ~= "merchant", "Choose the adventurer or visitor as seller.");
                oTrader, oRecipient, oTarget = actor(), World.actors.merchant, World.shop;
            end

            local nPrice = oItem.getValue().get();
            assert(World.coins[oRecipient.getKey()] >= nPrice, "Buyer cannot afford "..nPrice.." coins.");
            local bStored = false;
            local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

            for _, oContext in ipairs(Rules.scopes(oTarget)) do

                if (oItem.canStoreIn(oContext)) then
                    bStored = true;
                end

            end

            assert(bStored, "Storable_In does not permit the trade destination.");
            local _, bTraded, _, sFailure = oSource.tradeItemTo(oTarget, oItem, oTrader, oRecipient);
            assert(bTraded, sFailure);
            World.coins[oRecipient.getKey()] = World.coins[oRecipient.getKey()] - nPrice;
            World.coins[oTrader.getKey()] = World.coins[oTrader.getKey()] + nPrice;
            local c = oItem.getConfig();
            c.owner = oRecipient.getKey();
            local bChanged, sFailure = oItem.configure(c);
            assert(bChanged, sFailure);
            log((sAction == "buy" and "Bought " or "Sold ")..oItem.getName().." for "..nPrice.." coins. Both trade registries passed; legal ownership and wallets were updated by this example.");
        elseif (sAction == "consume") then
            local oSource = oItem.getLocation();
            assert(oSource ~= null, "Store the item before consuming it.");
            local _, bConsumed, _, sFailure = oSource.consumeItem(oItem, actor());
            assert(bConsumed, sFailure);
            tRecord.retired = true;
            World.selected = 0;
            log("Consumed "..oItem.getName()..": exactly this instance left its container. Other stack members remain.");
        elseif (sAction == "damage" or sAction == "repair") then
            local nAmount = number(tData.amount, 0, 10000);
            assert(sAction == "damage" and oItem.canDamageBy(actor()) or sAction == "repair" and oItem.canRepairBy(actor()), "Actor is not permitted to do this.");
            local nBefore = oItem.getDurability().get();
            oItem.getDurability().adjust(sAction == "damage" and -nAmount or nAmount);
            log(oItem.getName()..": durability "..nBefore.." → "..oItem.getDurability().get()..". Zero does not destroy the item.");
        elseif (sAction == "upgrade" or sAction == "downgrade") then
            assert(sAction == "upgrade" and oItem.canUpgradeBy(actor()) or sAction == "downgrade" and oItem.canDowngradeBy(actor()), "Actor is not permitted to do this.");
            local c = oItem.getConfig();
            local nSign = sAction == "upgrade" and 1 or -1;
            c.durabilityMax = math.max(1, c.durabilityMax + nSign * 5);
            c.durability = math.min(c.durability, c.durabilityMax);
            c.value = math.max(0, c.value + nSign * 10);
            local bChanged, sFailure = oItem.configure(c);
            assert(bChanged, sFailure);
            log("Example "..sAction.." policy: max durability ±5 and value ±10; permission came from LuaEx.");
        elseif (sAction == "attach") then
            local oHost = record(tData.host).item;
            local _, bAttached, sFailure = oItem.attachTo(oHost);
            assert(bAttached, sFailure);
            log("Attached "..oItem.getName().." to "..oHost.getName()..". One host; no independent inventory location.");
        elseif (sAction == "detach") then
            local _, bDetached, sFailure = oItem.detach(actor());
            assert(bDetached, sFailure);
            log("Detached "..oItem.getName()..". It is unplaced until you move it.");
        elseif (sAction == "clone") then
            assert(not oItem.isInimitable() or tData.override == true, "This example honors Inimitable; use the explicit lab override to copy anyway.");
            local oCopy = clone(oItem);
            local c = oCopy.getConfig();
            c.name = c.name:sub(1, 70).." (copy)";
            assert(oCopy.configure(c));
            local nLive = 0;
            for _, r in pairs(World.records) do if not r.retired then nLive = nLive + 1; end end
            assert(nLive < 80, "Delete an item before cloning; live item limit is 80.");
            local nID = World.nextID;
            World.nextID = nID + 1;
            World.records[nID] = {id = nID, item = oCopy, retired = false};
            World.selected = nID;
            log("Copied "..oItem.getName().." into an independent unplaced item. Its own concrete __clone defines this policy; exclusivity will still check insertion.");
        elseif (sAction == "delete") then
            local oLocation = oItem.getLocation();

            if (oLocation ~= null) then
                local _, bRemoved, _, sFailure;

                if (class.of(oLocation) == ItemSlot) then
                    _, bRemoved, _, sFailure = oLocation.remove(oItem);
                else
                    _, bRemoved, _, sFailure = oLocation.removeItem(oItem);
                end

                assert(bRemoved, sFailure);
            end

            if (oItem.getAttached_To() ~= null) then
                assert(oItem.detachForLab(actor()));
            end

            for _, oAttachment in oItem.eachAttachment() do
                assert(oAttachment.detachForLab(actor()));
            end

            tRecord.retired = true;
            World.selected = 0;
            log("Deleted "..oItem.getName().." from the lab. Attached children were detached and remain unplaced. This is an editor operation, not durability-based destruction.");
        elseif (sAction == "validate") then
            for _, oContainer in ipairs({World.inventory, World.stash, World.ground, World.shop}) do
                local bValid, sFailure = oContainer.validate();
                assert(bValid, sFailure);
            end
            log("All four container hierarchies are consistent: locations, membership, capacity, eligibility, exclusivity and footprints.");
        else
            error("Unknown item action: "..tostring(sAction));
        end

    end);

    if (not bOK) then
        log("Rejected: "..tostring(sReason):gsub("[^%s:]+%.lua:%d+:%s*", ""), false);
    end

    return view();
end

function M.new()
    reset();
    return {view = view, action = action};
end

return M;
