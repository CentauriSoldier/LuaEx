--LOCALIZATION
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

return class("ItemSlot",
{--METAMETHODS
    __len = function(this)
        return this.getItemCount();
    end,

    __clone = function()
        error("Clone concrete items explicitly, then insert them into a new ItemSlot.");
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
    Name__autoA_ = "",
},
{--PUBLIC
    ItemSlot = function(this, cdat, vAllowedItems, nCapacity, oOwner, sName)
        nCapacity = nCapacity == nil and 1 or nCapacity;
        Rules.integer(nCapacity, 1);
        assert(sName == nil or rawtype(sName) == "string", "Name must be a string.");
        local oRegistry;

        if (vAllowedItems == nil) then
            oRegistry = ObjectRegistry({BaseItem});
        elseif (class.isinstance(vAllowedItems)) then
            assert(class.ischildorself(class.of(vAllowedItems), ObjectRegistry), "Expected an ObjectRegistry.");
            oRegistry = vAllowedItems;
        else
            oRegistry = ObjectRegistry(Rules.array(vAllowedItems));
        end

        Rules.create(this, "slot", nCapacity, oOwner, oRegistry);
        cdat.pro.Name = sName or "";
    end,

    getAllowed_Items = function(this)
        return Rules.state(this).registry;
    end,

    getCapacity = function(this)
        return Rules.state(this).capacity;
    end,

    getOwner = function(this)
        return Rules.owner(this);
    end,

    getSystem = function(this)
        return Rules.state(this).parent or null;
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

    isOccupied = function(this)
        return #Rules.state(this).items > 0;
    end,

    getItemCount = function(this)
        return #Rules.state(this).items;
    end,

    setCapacity = function(this, cdat, nCapacity)
        Rules.integer(nCapacity, 1);
        local bOK, sReason = Rules.transaction({this}, function()
            Rules.state(this).capacity = nCapacity;
        end);
        return this, bOK, sReason;
    end,

    get = function(this, cdat, nIndex)
        nIndex = nIndex == nil and 1 or Rules.integer(nIndex, 1);
        return Rules.state(this).items[nIndex];
    end,

    getItem = function(this, cdat, nIndex)
        return this.get(nIndex);
    end,

    eachItem = function(this)
        return ipairs(Rules.items(this));
    end,

    containsItem = function(this, cdat, oItem)
        Rules.item(oItem);
        local nIndex = Rules.indexOf(this, oItem);
        return nIndex ~= nil, nIndex or -1;
    end,

    canAccept = function(this, cdat, oItem, bReplace)
        Rules.item(oItem);
        -- Preview on projected membership, without changing real location.
        return Rules.preview(this, oItem, bReplace);
    end,

    set = function(this, cdat, oItem, bReplace)
        local bOK, vResult = Rules.add(this, oItem, bReplace);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    setItem = function(this, cdat, oItem, bReplace)
        return this.set(oItem, bReplace);
    end,

    remove = function(this, cdat, vItem, oActor)
        local bOK, vResult = Rules.remove(this, vItem, oActor);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    clear = function(this)
        local bOK, vResult = Rules.clear(this);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
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

    swapWith = function(this, cdat, oOther)
        assert(class.isinstance(oOther) and class.of(oOther) == ItemSlot, "Expected an ItemSlot.");
        local bOK, sReason = Rules.swap(this, oOther);
        return this, bOK, sReason;
    end,

    validate = function(this)
        return Rules.check(this);
    end,

},
nil,
true,
nil
);
