--LOCALIZATION
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

return class("ItemSystem",
{--METAMETHODS
    __len = function(this)
        return this.getItemCount();
    end,

    __pairs = function(this)
        return this.eachItem();
    end,

    __clone = function()
        error("Clone concrete items explicitly, then insert them into a new ItemSystem.");
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
},
{--PROTECTED
},
{--PUBLIC
    ItemSystem = function(this, cdat, nMaxItems, tItems, oOwner)
        nMaxItems = nMaxItems == nil and math.huge or nMaxItems;
        Rules.integer(nMaxItems, 0, true);
        Rules.create(this, "inventory", nMaxItems, oOwner);

        if (tItems ~= nil) then
            local tInput = Rules.array(tItems);
            local bOK, sReason = Rules.transaction({this}, function()

                for _, oItem in ipairs(tInput) do
                    Rules.item(oItem);
                    assert(oItem.getLocation() == null, "Initial item already has a location.");
                end

                Rules.state(this).items = tInput;
            end);
            assert(bOK, sReason);
        end

    end,

    getOwner = function(this)
        return Rules.owner(this);
    end,

    getStash = function(this)
        return Rules.state(this).parent or null;
    end,

    getMaxItems = function(this)
        return Rules.state(this).capacity;
    end,

    setMaxItems = function(this, cdat, nCapacity)
        Rules.integer(nCapacity, 0, true);
        local bOK, sReason = Rules.transaction({this}, function()
            Rules.state(this).capacity = nCapacity;
        end);
        return this, bOK, sReason;
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

    addItem = function(this, cdat, oItem)
        local bOK, sReason = Rules.add(this, oItem);
        return bOK, this, sReason;
    end,

    removeItem = function(this, cdat, vItem, oActor)
        local bOK, vResult = Rules.remove(this, vItem, oActor);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    clear = function(this)
        local bOK, vResult = Rules.clear(this);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    containsItem = function(this, cdat, oItem)
        Rules.item(oItem);
        local nIndex = Rules.indexOf(this, oItem);
        return nIndex ~= nil, nIndex or -1;
    end,

    containsItemAt = function(this, cdat, oItem, nIndex)
        Rules.item(oItem);
        Rules.integer(nIndex, 1);
        return rawequal(Rules.state(this).items[nIndex], oItem);
    end,

    getItemAt = function(this, cdat, nIndex)
        Rules.integer(nIndex, 1);
        return Rules.state(this).items[nIndex];
    end,

    getItemCount = function(this)
        return #Rules.state(this).items;
    end,

    eachItem = function(this)
        return ipairs(Rules.items(this));
    end,

    iterator = function(this)
        return this.eachItem();
    end,

    swapItems = function(this, cdat, nFirst, nSecond)
        Rules.integer(nFirst, 1);
        Rules.integer(nSecond, 1);
        local bOK, sReason = Rules.transaction({this}, function()
            Rules.editable(this);
            local tItems = Rules.state(this).items;
            assert(nFirst ~= nSecond and tItems[nFirst] and tItems[nSecond], "Invalid swap indices.");
            tItems[nFirst], tItems[nSecond] = tItems[nSecond], tItems[nFirst];
        end);
        return this, bOK, sReason;
    end,

    transferItemTo = function(this, cdat, oDestination, oItem, bReplace)
        local bOK, vResult = Rules.transfer(this, oDestination, oItem, bReplace);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    consumeItem = function(this, cdat, oItem, oActor)
        assert(oActor ~= nil, "Consumption requires an actor.");
        local bOK, vResult = Rules.remove(this, oItem, oActor, "canConsumeBy");
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    tradeItemTo = function(this, cdat, oDestination, oItem, oTrader, oRecipient)
        local bOK, vResult = Rules.transfer(this, oDestination, oItem, false, function()
            return oItem.canTradeBy(oTrader) and oItem.canTradeTo(oRecipient);
        end);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    validate = function(this)
        return Rules.check(this);
    end,

},
nil,
false,
nil
);
