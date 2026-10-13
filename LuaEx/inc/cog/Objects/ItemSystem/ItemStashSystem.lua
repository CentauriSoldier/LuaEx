--LOCALIZATION
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

return class("ItemStashSystem",
{--METAMETHODS
    __len = function(this)
        return this.getTabCount();
    end,

    __pairs = function(this)
        return this.eachTab();
    end,

    __clone = function()
        error("Clone concrete items explicitly, then construct a new ItemStashSystem.");
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
    -- Containment graphs need an application-defined persistence policy.
    prepareSnapshot = function()
        error("Automatic item-container snapshots are unsupported; reconstruct through the public constructors and insertion methods.");
    end,

    validateSnapshot = function()
        error("Automatic item-container snapshots are unsupported; reconstruct through the public constructors and insertion methods.");
    end,
    maxItemsPerTab = math.huge,
},
{--PROTECTED
},
{--PUBLIC
    ItemStashSystem = function(this, cdat, oOwner, nTabs, nMaxItemsPerTab)
        nTabs = nTabs == nil and 1 or nTabs;
        nMaxItemsPerTab = nMaxItemsPerTab == nil and math.huge or nMaxItemsPerTab;
        Rules.integer(nTabs, 1);
        Rules.integer(nMaxItemsPerTab, 0, true);
        Rules.create(this, "stash", math.huge, oOwner);
        cdat.pri.maxItemsPerTab = nMaxItemsPerTab;

        for nIndex = 1, nTabs do
            this.addTab();
        end

    end,

    getOwner = function(this)
        return Rules.owner(this);
    end,

    getTabCount = function(this)
        return #Rules.state(this).children;
    end,

    getItemCount = function(this)
        return #Rules.items(this);
    end,

    getTab = function(this, cdat, nTab)
        Rules.integer(nTab, 1);
        return Rules.state(this).children[nTab];
    end,

    tabExistsAt = function(this, cdat, nTab)
        return this.getTab(nTab) ~= nil;
    end,

    eachTab = function(this)
        local tOutput = {};

        for nIndex, oTab in ipairs(Rules.state(this).children) do
            tOutput[nIndex] = oTab;
        end

        return ipairs(tOutput);
    end,

    eachItem = function(this)
        return ipairs(Rules.items(this));
    end,

    addTab = function(this, cdat, oTab)

        if (oTab == nil) then
            oTab = ItemSystem(cdat.pri.maxItemsPerTab, nil, this.getOwner());
        end

        assert(class.isinstance(oTab) and class.ischildorself(class.of(oTab), ItemSystem), "Expected an ItemSystem tab.");
        local bOK, sReason = Rules.adopt(this, oTab);
        return this, bOK, bOK and oTab or nil, sReason;
    end,

    removeTab = function(this, cdat, nTab)
        Rules.integer(nTab, 1);

        if (this.getTabCount() <= 1) then
            return nil, false, "A stash must retain at least one tab.";
        end

        local bOK, vResult = Rules.release(this, nTab);
        return bOK and vResult or nil, bOK, not bOK and vResult or nil;
    end,

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

    addItem = function(this, cdat, oItem, nTab)
        Rules.item(oItem);

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

    removeItem = function(this, cdat, oItem, oActor)
        local bFound, nTab = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local _, bOK, oRemoved, sReason = this.getTab(nTab).removeItem(oItem, oActor);
        return this, bOK, oRemoved, sReason;
    end,

    transferItemTo = function(this, cdat, oDestination, oItem, nTab, bReplace)
        local bFound, nSourceTab = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local oTarget = oDestination;

        if (class.isinstance(oDestination) and class.ischildorself(class.of(oDestination), ItemStashSystem)) then
            oTarget = oDestination.getTab(nTab);
        end

        local _, bOK, oRemoved, sReason = this.getTab(nSourceTab).transferItemTo(oTarget, oItem, bReplace);
        return this, bOK, oRemoved, sReason;
    end,

    clear = function(this)
        local bOK, vResult = Rules.clear(this);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    consumeItem = function(this, cdat, oItem, oActor)
        local bFound, nTab = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local _, bOK, oRemoved, sReason = this.getTab(nTab).consumeItem(oItem, oActor);
        return this, bOK, oRemoved, sReason;
    end,

    tradeItemTo = function(this, cdat, oDestination, oItem, oTrader, oRecipient, nTab)
        local bFound, nSourceTab = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local oTarget = oDestination;

        if (class.isinstance(oDestination) and class.ischildorself(class.of(oDestination), ItemStashSystem)) then
            oTarget = oDestination.getTab(nTab);
        end

        local _, bOK, oRemoved, sReason = this.getTab(nSourceTab).tradeItemTo(oTarget, oItem, oTrader, oRecipient);
        return this, bOK, oRemoved, sReason;
    end,

    isEnabled = function(this)
        return Rules.state(this).enabled;
    end,

    isLocked = function(this)
        return Rules.state(this).locked;
    end,

    setEnabled = function(this, cdat, bValue)
        Rules.setFlag(this, "enabled", bValue);
        return this;
    end,

    setLocked = function(this, cdat, bValue)
        Rules.setFlag(this, "locked", bValue);
        return this;
    end,

    validate = function(this)
        return Rules.check(this);
    end,

},
nil,
false,
nil
);
