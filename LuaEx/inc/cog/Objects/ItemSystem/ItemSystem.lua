--LOCALIZATION
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

local cItemSystem = class("ItemSystem",
{--METAMETHODS

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.__len
        @desc Returns the collection count used by the length operator; see the delegated count method.
    !]]
    __len = function(this)
        return this.getItemCount();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.__pairs
        @desc Iterates a copied membership list through the collection's public iterator.
    !]]
    __pairs = function(this)
        return this.eachItem();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.__clone
        @desc Requires callers to choose how concrete items are cloned before populating another container.
    !]]
    __clone = function()
        error("Clone concrete items explicitly, then insert them into a new ItemSystem.");
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE

    -- The class owns this table; Rules indexes the same table rather than storing separate state.
    state = {},

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.validateSnapshot
        @desc Checks saved fields before the generated class deserializer accepts them.
    !]]
    validateSnapshot = function(tState)
        Rules.validateSnapshot(tState.pri.state, "inventory");
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.prepareSnapshot
        @desc Prepares a copied class snapshot without changing the live inventory.
    !]]
    prepareSnapshot = function(tState)
        Rules.prepareSnapshot(tState.pri.state);
    end,
},
{--PROTECTED
},
{--PUBLIC

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.restoreRuntime
        @desc Internal reconnection after generated deserialization; retains saved
        membership and restores runtime lookups without permission callbacks.
    !]]
    restoreRuntime__FNL = function(this, cdat, tToken)
        Rules.restore(this, cdat.pri.state, tToken);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.ItemSystem
        @desc Creates an inventory with optional capacity, initial items and an external owner. Initial
        membership is validated as one transaction.
    !]]
    ItemSystem = function(this, cdat, nMaxItems, tItems, oOwner)
        nMaxItems = nMaxItems == nil and math.huge or nMaxItems;
        Rules.integer(nMaxItems, 0, true);
        cdat.pri.state = Rules.create(this, "inventory", nMaxItems, oOwner);

        -- Initial membership enters through the same whole-hierarchy validation as later edits.
        if (tItems ~= nil) then
            local tInput = Rules.array(tItems);
            local bOK, sReason = Rules.transaction({this}, function()

                for _, oItem in ipairs(tInput) do
                    Rules.item(oItem);
                    assert(oItem.getLocation() == null, "Initial item already has a location.");
                end

                -- Publish projected membership; the transaction commits item locations after validation.
                Rules.state(this).items = tInput;
            end);

            assert(bOK, sReason);
        end
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.setOwner
        @desc Reconnects the caller-owned owner after loading. The owner is not saved.
        @param object|null oOwner A class instance, or null to clear the owner.
        @ret ItemSystem this
    !]]
    setOwner = function(this, cdat, oOwner)
        Rules.setOwner(this, oOwner);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.getOwner
        @desc Resolves the owner through the container hierarchy; an outer owner takes precedence.
    !]]
    getOwner = function(this)
        return Rules.owner(this);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.getStash
        @desc Returns the containing stash, or null when this inventory is independent.
    !]]
    getStash = function(this)
        return Rules.state(this).parent or null;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.getMaxItems
        @desc Returns the item capacity; math.huge represents an unlimited inventory.
    !]]
    getMaxItems = function(this)
        return Rules.state(this).capacity;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.setMaxItems
        @desc Validates the proposed capacity and commits it only if all current items still fit.
    !]]
    setMaxItems = function(this, cdat, nCapacity)
        Rules.integer(nCapacity, 0, true);

        local bOK, sReason = Rules.transaction({this}, function()
            Rules.state(this).capacity = nCapacity;
        end);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.isEnabled
        @desc Returns this container's own enabled flag; mutations also check its ancestors.
    !]]
    isEnabled = function(this)
        return Rules.state(this).enabled;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.isLocked
        @desc Returns this container's own lock flag; mutations also check its ancestors.
    !]]
    isLocked = function(this)
        return Rules.state(this).locked;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.setEnabled
        @desc Sets the local enabled flag and returns this container. Ancestor restrictions still apply.
    !]]
    setEnabled = function(this, cdat, bValue)
        Rules.setFlag(this, "enabled", bValue);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.setLocked
        @desc Sets the local lock flag and returns this container. Locked ancestors still prevent edits.
    !]]
    setLocked = function(this, cdat, bValue)
        Rules.setFlag(this, "locked", bValue);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.addItem
        @desc Adds an unlocated item through the shared transaction rules; returns success, this and an optional
        reason.
    !]]
    addItem = function(this, cdat, oItem)
        local bOK, sReason = Rules.add(this, oItem);

        return bOK, this, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.removeItem
        @desc Removes the first item, a specified index or an exact item instance; an optional actor must have
        removal permission.
    !]]
    removeItem = function(this, cdat, vItem, oActor)
        local bOK, vResult = Rules.remove(this, vItem, oActor);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.clear
        @desc Removes items throughout this subtree in one transaction; returns this, success, removed items or
        a failure reason.
    !]]
    clear = function(this)
        local bOK, vResult = Rules.clear(this);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.containsItem
        @desc Looks for the exact item instance, returning its position when found and -1 when absent.
    !]]
    containsItem = function(this, cdat, oItem)
        Rules.item(oItem);
        local nIndex = Rules.indexOf(this, oItem);

        return nIndex ~= nil, nIndex or -1;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.containsItemAt
        @desc Checks exact item identity at the requested position rather than comparing item values.
    !]]
    containsItemAt = function(this, cdat, oItem, nIndex)
        Rules.item(oItem);
        Rules.integer(nIndex, 1);

        return rawequal(Rules.state(this).items[nIndex], oItem);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.getItemAt
        @desc Returns the item at a positive one-based index, or nil when that position is empty.
    !]]
    getItemAt = function(this, cdat, nIndex)
        Rules.integer(nIndex, 1);

        return Rules.state(this).items[nIndex];
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.getItemCount
        @desc Returns the number of items directly held by this inventory.
    !]]
    getItemCount = function(this)
        return #Rules.state(this).items;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.eachItem
        @desc Iterates a copied list of item references, keeping callers away from the live membership array.
    !]]
    eachItem = function(this)
        return ipairs(Rules.items(this));
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.iterator
        @desc Aliases eachItem so both entry points use the same copied membership list.
    !]]
    iterator = function(this)
        return this.eachItem();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.swapItems
        @desc Swaps the selected contents inside a transaction so capacity, eligibility and hierarchy rules all
        apply.
    !]]
    swapItems = function(this, cdat, nFirst, nSecond)
        Rules.integer(nFirst, 1);
        Rules.integer(nSecond, 1);

        local bOK, sReason = Rules.transaction({this}, function()
            Rules.editable(this);

            -- Swap references in place; item locations stay in this same inventory.
            local tItems = Rules.state(this).items;
            assert(nFirst ~= nSecond and tItems[nFirst] and tItems[nSecond], "Invalid swap indices.");
            tItems[nFirst], tItems[nSecond] = tItems[nSecond], tItems[nFirst];
        end);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.transferItemTo
        @desc Moves the exact item between leaf containers atomically; failures retain the original membership.
    !]]
    transferItemTo = function(this, cdat, oDestination, oItem, bReplace)
        local bOK, vResult = Rules.transfer(this, oDestination, oItem, bReplace);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.consumeItem
        @desc Checks the actor's consumption permission and removes the item. Gameplay effects remain the
        caller's responsibility.
    !]]
    consumeItem = function(this, cdat, oItem, oActor)
        assert(oActor ~= nil, "Consumption requires an actor.");
        local bOK, vResult = Rules.remove(this, oItem, oActor, "canConsumeBy");

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSystem.Methods.tradeItemTo
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
        @fqxn CoG.ItemSystem.ItemSystem.Methods.validate
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
Rules.registerPersistence(cItemSystem);

return cItemSystem;
