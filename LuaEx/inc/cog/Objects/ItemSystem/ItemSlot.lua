--[[!
    @fqxn CoG.ItemSystem.ItemSlot
    @desc A final leaf container for individual items, with a mutable ObjectRegistry eligibility filter. Default capacity is one; stacking counts instances rather than quantities. Standalone slots do not require inventory storage eligibility. Containment/footprint rules apply when adopted into a system.
!]]
--LOCALIZATION
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

local cItemSlot = class("ItemSlot",
{--METAMETHODS

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.__len
        @desc Returns the collection count used by the length operator; see the delegated count method.
    !]]
    __len = function(this)
        return this.getItemCount();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.__clone
        @desc Requires callers to choose how concrete items are cloned before populating another container.
    !]]
    __clone = function()
        error("Clone concrete items explicitly, then insert them into a new ItemSlot.");
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE

    -- The class owns this table; Rules indexes the same table rather than storing separate state.
    state = {},

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.validateSnapshot
        @desc Checks saved fields before the generated class deserializer accepts them.
    !]]
    validateSnapshot = function(tState)
        Rules.validateSnapshot(tState.pri.state, "slot");
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.prepareSnapshot
        @desc Prepares a copied class snapshot without changing the live inventory.
    !]]
    prepareSnapshot = function(tState)
        Rules.prepareSnapshot(tState.pri.state);
    end,
},
{--PROTECTED
    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.getName
        @pulsarlua function ItemSlot.getName
        @desc Returns the slot name, initially empty when omitted. Generated non-final getter; no setter.
        @ret string vValue Stored value/reference.
    !]]
    Name__autoA_ = "",
},
{--PUBLIC

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.restoreRuntime
        @desc Internal reconnection after generated deserialization; retains saved
        membership and restores runtime lookups without permission callbacks.
    !]]
    restoreRuntime__FNL = function(this, cdat, tToken)
        Rules.restore(this, cdat.pri.state, tToken);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.ItemSlot
        @desc Creates a leaf slot with an eligibility registry, capacity, optional owner and name. Omitted
        eligibility allows BaseItem instances.
    !]]
    ItemSlot = function(this, cdat, vAllowedItems, nCapacity, oOwner, sName)
        nCapacity = nCapacity == nil and 1 or nCapacity;
        Rules.integer(nCapacity, 1);
        assert(sName == nil or rawtype(sName) == "string", "Name must be a string.");
        local oRegistry;

        -- Omission creates a permissive BaseItem registry. A supplied registry is retained;
        -- a supplied entry array is validated and used to construct a new registry.
        if (vAllowedItems == nil) then
            oRegistry = ObjectRegistry({BaseItem});
        elseif (class.isinstance(vAllowedItems)) then
            assert(class.ischildorself(class.of(vAllowedItems), ObjectRegistry), "Expected an ObjectRegistry.");
            oRegistry = vAllowedItems;
        else
            oRegistry = ObjectRegistry(Rules.array(vAllowedItems));
        end

        cdat.pri.state = Rules.create(this, "slot", nCapacity, oOwner, oRegistry);
        cdat.pro.Name = sName or "";
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.getAllowed_Items
        @desc Returns the slot's mutable eligibility registry by reference.
    !]]
    getAllowed_Items = function(this)
        return Rules.state(this).registry;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.getCapacity
        @desc Returns the maximum number of individual item instances this slot can hold.
    !]]
    getCapacity = function(this)
        return Rules.state(this).capacity;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.setOwner
        @desc Reconnects the caller-owned owner after loading. The owner is not saved.
        @param object|null oOwner A class instance, or null to clear the owner.
        @ret ItemSlot this This container.
    !]]
    setOwner = function(this, cdat, oOwner)
        Rules.setOwner(this, oOwner);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.getOwner
        @desc Resolves the owner through the container hierarchy; an outer owner takes precedence.
    !]]
    getOwner = function(this)
        return Rules.owner(this);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.getSystem
        @desc Returns the containing slot system, or null for an independent slot.
    !]]
    getSystem = function(this)
        return Rules.state(this).parent or null;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.isEnabled
        @desc Returns this container's own enabled flag; mutations also check its ancestors.
    !]]
    isEnabled = function(this)
        return Rules.state(this).enabled;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.isLocked
        @desc Returns this container's own lock flag; mutations also check its ancestors.
    !]]
    isLocked = function(this)
        return Rules.state(this).locked;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.setEnabled
        @desc Sets the local enabled flag and returns this container. Ancestor restrictions still apply.
    !]]
    setEnabled = function(this, cdat, bValue)
        Rules.setFlag(this, "enabled", bValue);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.setLocked
        @desc Sets the local lock flag and returns this container. Locked ancestors still prevent edits.
    !]]
    setLocked = function(this, cdat, bValue)
        Rules.setFlag(this, "locked", bValue);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.isOccupied
        @desc Reports whether this slot holds at least one item.
    !]]
    isOccupied = function(this)
        return #Rules.state(this).items > 0;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.getItemCount
        @desc Returns the number of individual items currently in this slot.
    !]]
    getItemCount = function(this)
        return #Rules.state(this).items;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.setCapacity
        @desc Commits a positive capacity only when the existing contents still fit.
    !]]
    setCapacity = function(this, cdat, nCapacity)
        Rules.integer(nCapacity, 1);

        -- Validate against current contents before committing the proposed capacity.
        local bOK, sReason = Rules.transaction({this}, function()
            Rules.state(this).capacity = nCapacity;
        end);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.get
        @desc Returns the item at a positive one-based index, defaulting to the first item; an empty position
        yields nil.
    !]]
    get = function(this, cdat, nIndex)
        nIndex = nIndex == nil and 1 or Rules.integer(nIndex, 1);

        return Rules.state(this).items[nIndex];
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.getItem
        @desc Aliases get and preserves its default index and empty-position behavior.
    !]]
    getItem = function(this, cdat, nIndex)
        return this.get(nIndex);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.eachItem
        @desc Iterates a copied list of item references, keeping callers away from the live membership array.
    !]]
    eachItem = function(this)
        return ipairs(Rules.items(this));
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.containsItem
        @desc Looks for the exact item instance, returning its position when found and -1 when absent.
    !]]
    containsItem = function(this, cdat, oItem)
        Rules.item(oItem);
        local nIndex = Rules.indexOf(this, oItem);

        return nIndex ~= nil, nIndex or -1;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.canAccept
        @desc Runs the complete proposed insertion as a preview, then restores membership without changing item
        locations.
    !]]
    canAccept = function(this, cdat, oItem, bReplace)
        Rules.item(oItem);

        -- Preview on projected membership, without changing real location.
        return Rules.preview(this, oItem, bReplace);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.set
        @desc Inserts an unlocated item; optional replacement displaces the first item when full. Returns this,
        success, displaced item and reason.
    !]]
    set = function(this, cdat, oItem, bReplace)
        local bOK, vResult = Rules.add(this, oItem, bReplace);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.setItem
        @desc Aliases set, including its replacement policy and result tuple.
    !]]
    setItem = function(this, cdat, oItem, bReplace)
        return this.set(oItem, bReplace);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.remove
        @desc Removes the first item, a positive index or an exact instance. Returns this, success, removed item
        and reason.
    !]]
    remove = function(this, cdat, vItem, oActor)
        local bOK, vResult = Rules.remove(this, vItem, oActor);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.clear
        @desc Removes items throughout this subtree in one transaction; returns this, success, removed items or
        a failure reason.
    !]]
    clear = function(this)
        local bOK, vResult = Rules.clear(this);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.transferItemTo
        @desc Moves the exact item between leaf containers atomically; failures retain the original membership.
    !]]
    transferItemTo = function(this, cdat, oDestination, oItem, bReplace)
        local bOK, vResult = Rules.transfer(this, oDestination, oItem, bReplace);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.consumeItem
        @desc Checks the actor's consumption permission and removes the item. Gameplay effects remain the
        caller's responsibility.
    !]]
    consumeItem = function(this, cdat, oItem, oActor)
        assert(oActor ~= nil, "Consumption requires an actor.");
        local bOK, vResult = Rules.remove(this, oItem, oActor, "canConsumeBy");

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.tradeItemTo
        @desc Checks both trading permissions before moving the item atomically; pricing and payment belong to
        the caller.
    !]]
    tradeItemTo = function(this, cdat, oDestination, oItem, oTrader, oRecipient)
        local bOK, vResult = Rules.transfer(this, oDestination, oItem, false, function()
            return oItem.canTradeBy(oTrader) and oItem.canTradeTo(oRecipient);
        end);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.swapWith
        @desc Exchanges complete slot contents atomically; both slots must accept the resulting contents.
    !]]
    swapWith = function(this, cdat, oOther)
        assert(class.isinstance(oOther) and class.of(oOther) == ItemSlot, "Expected an ItemSlot.");
        local bOK, sReason = Rules.swap(this, oOther);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlot.Methods.validate
        @desc Previews validation of the current hierarchy and rolls back projected state; returns success and
        an optional reason.
    !]]
    validate = function(this)
        return Rules.check(this);
    end,

},
nil,
true,
nil
);

-- Attach runtime reconnection through the general serializer's existing factory extension.
Rules.registerPersistence(cItemSlot);

return cItemSlot;
