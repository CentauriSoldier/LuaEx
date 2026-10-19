--[[!
    @fqxn CoG.ItemSystem.ItemStashSystem
    @desc A hierarchy of ItemSystem inventory tabs, initially one tab. Default new-tab capacity is math.huge. Stash-wide exclusivity and outer ownership apply across tabs; releasing tabs requires them to be empty and at least one tab must remain.
!]]
--LOCALIZATION
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

local cItemStashSystem = class("ItemStashSystem",
{--METAMETHODS

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.__len
        @desc Returns the collection count used by the length operator; see the delegated count method.
    !]]
    __len = function(this)
        return this.getTabCount();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.__pairs
        @desc Iterates a copied membership list through the collection's public iterator.
    !]]
    __pairs = function(this)
        return this.eachTab();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.__clone
        @desc Requires callers to choose how concrete items are cloned before populating another container.
    !]]
    __clone = function()
        error("Clone concrete items explicitly, then construct a new ItemStashSystem.");
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE

    -- The class owns this table; Rules indexes the same table rather than storing separate state.
    state = {},

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.validateSnapshot
        @desc Checks saved fields before the generated class deserializer accepts them.
    !]]
    validateSnapshot = function(tState)
        Rules.validateSnapshot(tState.pri.state, "stash");
        Rules.integer(tState.pri.maxItemsPerTab, 0, true);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.prepareSnapshot
        @desc Prepares a copied class snapshot without changing the live inventory.
    !]]
    prepareSnapshot = function(tState)
        Rules.prepareSnapshot(tState.pri.state);
    end,

    maxItemsPerTab = math.huge,
},
{--PROTECTED
},
{--PUBLIC

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.restoreRuntime
        @desc Internal reconnection after generated deserialization; retains saved
        membership and restores runtime lookups without permission callbacks.
    !]]
    restoreRuntime__FNL = function(this, cdat, tToken)
        Rules.restore(this, cdat.pri.state, tToken);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.ItemStashSystem
        @desc Creates a stash with at least one inventory tab and a default capacity for newly created tabs.
    !]]
    ItemStashSystem = function(this, cdat, oOwner, nTabs, nMaxItemsPerTab)
        nTabs = nTabs == nil and 1 or nTabs;
        nMaxItemsPerTab = nMaxItemsPerTab == nil and math.huge or nMaxItemsPerTab;
        Rules.integer(nTabs, 1);
        Rules.integer(nMaxItemsPerTab, 0, true);
        cdat.pri.state = Rules.create(this, "stash", math.huge, oOwner);
        cdat.pri.maxItemsPerTab = nMaxItemsPerTab;

        -- Create each tab through the normal adoption path so parent links and shared rules agree.
        for nIndex = 1, nTabs do
            this.addTab();
        end
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.setOwner
        @desc Reconnects the caller-owned owner after loading. The owner is not saved.
        @param object|null oOwner A class instance, or null to clear the owner.
        @ret ItemStashSystem this This container.
    !]]
    setOwner = function(this, cdat, oOwner)
        Rules.setOwner(this, oOwner);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.getOwner
        @desc Resolves the owner through the container hierarchy; an outer owner takes precedence.
    !]]
    getOwner = function(this)
        return Rules.owner(this);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.getTabCount
        @desc Returns the number of child inventory tabs.
    !]]
    getTabCount = function(this)
        return #Rules.state(this).children;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.getItemCount
        @desc Counts individual items across every tab.
    !]]
    getItemCount = function(this)
        return #Rules.items(this);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.getTab
        @desc Returns the tab at a positive one-based index, or nil when absent.
    !]]
    getTab = function(this, cdat, nTab)
        Rules.integer(nTab, 1);

        return Rules.state(this).children[nTab];
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.tabExistsAt
        @desc Reports whether a tab exists at the requested positive index.
    !]]
    tabExistsAt = function(this, cdat, nTab)
        return this.getTab(nTab) ~= nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.eachTab
        @desc Iterates a copy of the ordered tab references so callers cannot edit the live child list.
    !]]
    eachTab = function(this)
        local tOutput = {};

        for nIndex, oTab in ipairs(Rules.state(this).children) do
            tOutput[nIndex] = oTab;
        end

        return ipairs(tOutput);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.eachItem
        @desc Iterates a copied list of item references, keeping callers away from the live membership array.
    !]]
    eachItem = function(this)
        return ipairs(Rules.items(this));
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.addTab
        @desc Creates a tab when omitted, or adopts the supplied independent inventory; returns this, success,
        adopted tab and reason.
    !]]
    addTab = function(this, cdat, oTab)

        -- Omitted tabs receive this stash's configured default capacity and current owner.
        if (oTab == nil) then
            oTab = ItemSystem(cdat.pri.maxItemsPerTab, nil, this.getOwner());
        end

        assert(class.isinstance(oTab) and class.ischildorself(class.of(oTab), ItemSystem), "Expected an ItemSystem tab.");
        local bOK, sReason = Rules.adopt(this, oTab);

        return this, bOK, bOK and oTab or nil, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.removeTab
        @desc Releases an empty tab while retaining at least one tab. Returns the removed tab, success and an
        optional reason.
    !]]
    removeTab = function(this, cdat, nTab)
        Rules.integer(nTab, 1);

        -- Retaining one tab keeps the stash usable even after the caller removes empty tabs.
        if (this.getTabCount() <= 1) then
            return nil, false, "A stash must retain at least one tab.";
        end

        local bOK, vResult = Rules.release(this, nTab);

        return bOK and vResult or nil, bOK, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.containsItem
        @desc Searches tabs for the exact item instance; returns success, tab index and item index, or false and
        two -1 values.
    !]]
    containsItem = function(this, cdat, oItem)
        Rules.item(oItem);

        for nTab, oTab in this.eachTab() do
            local bFound, nItem = oTab.containsItem(oItem);

            if (bFound) then
                return true, nTab, nItem;
            end
        end

        return false, -1, -1;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.addItem
        @desc Uses a selected tab, or tries tabs in order until one accepts the item under stash-wide rules.
    !]]
    addItem = function(this, cdat, oItem, nTab)
        Rules.item(oItem);

        -- Use an explicitly selected tab directly; otherwise try each tab without displacing items.
        if (nTab ~= nil) then
            local oTab = this.getTab(nTab);

            if (not oTab) then
                return this, false, "Tab does not exist.";
            end

            local bOK, _, sReason = oTab.addItem(oItem);

            return this, bOK, sReason;
        end

        local sReason = "No tab has room.";

        for _, oTab in this.eachTab() do
            local bOK, _, sFailure = oTab.addItem(oItem);

            if (bOK) then
                return this, true;
            end

            sReason = sFailure;
        end

        return this, false, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.removeItem
        @desc Locates the owning tab and delegates removal; missing items return a failure without changing
        contents.
    !]]
    removeItem = function(this, cdat, oItem, oActor)
        local bFound, nTab = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local _, bOK, oRemoved, sReason = this.getTab(nTab).removeItem(oItem, oActor);

        return this, bOK, oRemoved, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.transferItemTo
        @desc Finds the source tab and, for a stash destination, selects its requested target tab before
        transferring.
    !]]
    transferItemTo = function(this, cdat, oDestination, oItem, nTab, bReplace)
        local bFound, nSourceTab = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        -- Resolve a stash destination to a leaf inventory before invoking the shared transfer rules.
        local oTarget = oDestination;

        if (class.isinstance(oDestination) and class.ischildorself(class.of(oDestination), ItemStashSystem)) then
            oTarget = oDestination.getTab(nTab);
        end

        local _, bOK, oRemoved, sReason = this.getTab(nSourceTab).transferItemTo(oTarget, oItem, bReplace);

        return this, bOK, oRemoved, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.clear
        @desc Removes items throughout this subtree in one transaction; returns this, success, removed items or
        a failure reason.
    !]]
    clear = function(this)
        local bOK, vResult = Rules.clear(this);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.consumeItem
        @desc Checks the actor's consumption permission and removes the item. Gameplay effects remain the
        caller's responsibility.
    !]]
    consumeItem = function(this, cdat, oItem, oActor)
        local bFound, nTab = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local _, bOK, oRemoved, sReason = this.getTab(nTab).consumeItem(oItem, oActor);

        return this, bOK, oRemoved, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.tradeItemTo
        @desc Checks both trading permissions before moving the item atomically; pricing and payment belong to
        the caller.
    !]]
    tradeItemTo = function(this, cdat, oDestination, oItem, oTrader, oRecipient, nTab)
        local bFound, nSourceTab = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        -- Resolve a stash destination to a leaf inventory before invoking the shared transfer rules.
        local oTarget = oDestination;

        if (class.isinstance(oDestination) and class.ischildorself(class.of(oDestination), ItemStashSystem)) then
            oTarget = oDestination.getTab(nTab);
        end

        local _, bOK, oRemoved, sReason = this.getTab(nSourceTab).tradeItemTo(oTarget, oItem, oTrader, oRecipient);

        return this, bOK, oRemoved, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.isEnabled
        @desc Returns this container's own enabled flag; mutations also check its ancestors.
    !]]
    isEnabled = function(this)
        return Rules.state(this).enabled;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.isLocked
        @desc Returns this container's own lock flag; mutations also check its ancestors.
    !]]
    isLocked = function(this)
        return Rules.state(this).locked;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.setEnabled
        @desc Sets the local enabled flag and returns this container. Ancestor restrictions still apply.
    !]]
    setEnabled = function(this, cdat, bValue)
        Rules.setFlag(this, "enabled", bValue);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.setLocked
        @desc Sets the local lock flag and returns this container. Locked ancestors still prevent edits.
    !]]
    setLocked = function(this, cdat, bValue)
        Rules.setFlag(this, "locked", bValue);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemStashSystem.Methods.validate
        @desc Previews validation of the current hierarchy and rolls back projected state; returns success and
        an optional reason.
    !]]
    validate = function(this)
        return Rules.check(this);
    end,

},
nil,
false,
nil
);

-- Attach runtime reconnection through the general serializer's existing factory extension.
Rules.registerPersistence(cItemStashSystem);

return cItemStashSystem;
