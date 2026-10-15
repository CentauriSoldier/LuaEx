--LOCALIZATION
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

local cItemSlotSystem = class("ItemSlotSystem",
{--METAMETHODS

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.__len
        @desc Returns the collection count used by the length operator; see the delegated count method.
    !]]
    __len = function(this)
        return this.getItemSlotCount();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.__pairs
        @desc Iterates a copied membership list through the collection's public iterator.
    !]]
    __pairs = function(this)
        return this.eachItemSlot();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.__clone
        @desc Requires callers to choose how concrete items are cloned before populating another container.
    !]]
    __clone = function()
        error("Clone concrete items explicitly, then construct a new ItemSlotSystem.");
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE

    -- The class owns this table; Rules indexes the same table rather than storing separate state.
    state = {},

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.validateSnapshot
        @desc Checks saved fields before the generated class deserializer accepts them.
    !]]
    validateSnapshot = function(tState)
        Rules.validateSnapshot(tState.pri.state, "slots");
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.prepareSnapshot
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
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.restoreRuntime
        @desc Internal reconnection after generated deserialization; retains saved
        membership and restores runtime lookups without permission callbacks.
    !]]
    restoreRuntime__FNL = function(this, cdat, tToken)
        Rules.restore(this, cdat.pri.state, tToken);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.ItemSlotSystem
        @desc Creates a slot system and adopts any supplied slots in one transaction, rejecting slots already
        owned by another system.
    !]]
    ItemSlotSystem = function(this, cdat, tItemSlots, oOwner)
        cdat.pri.state = Rules.create(this, "slots", math.huge, oOwner);

        -- Adopt supplied slots as a group so partial adoption cannot survive a failed check.
        if (tItemSlots ~= nil) then
            local tSlots = Rules.array(tItemSlots);
            local tTouched = {this};

            for _, oSlot in ipairs(tSlots) do
                assert(class.isinstance(oSlot) and class.of(oSlot) == ItemSlot, "Expected an ItemSlot.");
                tTouched[#tTouched + 1] = oSlot;
            end

            local bOK, sReason = Rules.transaction(tTouched, function()

                for _, oSlot in ipairs(tSlots) do
                    assert(not Rules.state(oSlot).parent, "Slot already belongs to a system.");
                    Rules.state(oSlot).parent = this;
                end

                Rules.state(this).children = tSlots;
            end);

            assert(bOK, sReason);
        end
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.setOwner
        @desc Reconnects the caller-owned owner after loading. The owner is not saved.
        @param object|null oOwner A class instance, or null to clear the owner.
        @ret ItemSlotSystem this
    !]]
    setOwner = function(this, cdat, oOwner)
        Rules.setOwner(this, oOwner);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getOwner
        @desc Resolves the owner through the container hierarchy; an outer owner takes precedence.
    !]]
    getOwner = function(this)
        return Rules.owner(this);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getItemSlotCount
        @desc Returns the number of child slots, including empty slots.
    !]]
    getItemSlotCount = function(this)
        return #Rules.state(this).children;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getItemCount
        @desc Counts items across every child slot rather than counting the slots themselves.
    !]]
    getItemCount = function(this)
        return #Rules.items(this);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getItemSlotAt
        @desc Returns the slot at a positive one-based index, or nil when absent.
    !]]
    getItemSlotAt = function(this, cdat, nIndex)
        Rules.integer(nIndex, 1);

        return Rules.state(this).children[nIndex];
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getItemAt
        @desc Selects a child slot, then returns its requested item; nItem defaults to that slot's first item.
    !]]
    getItemAt = function(this, cdat, nSlot, nItem)
        local oSlot = this.getItemSlotAt(nSlot);

        return oSlot and oSlot.get(nItem) or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.eachItemSlot
        @desc Copies the ordered child-slot list and returns an ipairs iterator over those references.
    !]]
    eachItemSlot = function(this)
        local tOutput = {};

        for nIndex, oSlot in ipairs(Rules.state(this).children) do
            tOutput[nIndex] = oSlot;
        end

        return ipairs(tOutput);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.eachSlot
        @desc Aliases eachItemSlot and preserves its copied-list iteration behavior.
    !]]
    eachSlot = function(this)
        return this.eachItemSlot();
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.eachItem
        @desc Iterates a copied list of item references, keeping callers away from the live membership array.
    !]]
    eachItem = function(this)
        return ipairs(Rules.items(this));
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.containsItemAt
        @desc Checks whether the selected slot contains the exact item instance.
    !]]
    containsItemAt = function(this, cdat, oItem, nSlot)
        Rules.item(oItem);
        local oSlot = this.getItemSlotAt(nSlot);

        return oSlot ~= nil and oSlot.containsItem(oItem);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.containsItem
        @desc Searches child slots for an exact item instance; returns success and the slot index, or false and
        -1.
    !]]
    containsItem = function(this, cdat, oItem)
        Rules.item(oItem);

        for nIndex, oSlot in this.eachItemSlot() do

            if (oSlot.containsItem(oItem)) then
                return true, nIndex;
            end
        end

        return false, -1;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.containsItemSlot
        @desc Searches for the exact slot instance and returns success plus its one-based index or -1.
    !]]
    containsItemSlot = function(this, cdat, oSlot)
        assert(class.isinstance(oSlot) and class.of(oSlot) == ItemSlot, "Expected an ItemSlot.");

        for nIndex, oExisting in this.eachItemSlot() do

            if (rawequal(oExisting, oSlot)) then
                return true, nIndex;
            end
        end

        return false, -1;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.containsItemSlotAt
        @desc Compares the requested child position with the exact supplied slot instance.
    !]]
    containsItemSlotAt = function(this, cdat, oSlot, nIndex)
        assert(class.isinstance(oSlot) and class.of(oSlot) == ItemSlot, "Expected an ItemSlot.");

        return rawequal(this.getItemSlotAt(nIndex), oSlot);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.addItemSlot
        @desc Adopts an independent ItemSlot and validates the complete affected hierarchies.
    !]]
    addItemSlot = function(this, cdat, oSlot)
        assert(class.isinstance(oSlot) and class.of(oSlot) == ItemSlot, "Expected an ItemSlot.");
        local bOK, sReason = Rules.adopt(this, oSlot);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.removeItemSlot
        @desc Releases an empty child slot; nonempty or protected slots cannot be removed.
    !]]
    removeItemSlot = function(this, cdat, nIndex)
        local bOK, vResult = Rules.release(this, nIndex);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.addItem
        @desc Uses the requested slot, or tries slots in order until one accepts the item. Automatic selection
        does not replace existing items.
    !]]
    addItem = function(this, cdat, oItem, nSlot, bReplace)
        Rules.item(oItem);

        -- An explicit target uses only that slot; automatic selection below tries slots in order.
        if (nSlot ~= nil) then
            local oSlot = this.getItemSlotAt(nSlot);

            if (not oSlot) then
                return this, false, nil, "Slot does not exist.";
            end

            local _, bOK, oRemoved, sReason = oSlot.set(oItem, bReplace);

            return this, bOK, oRemoved, sReason;
        end

        -- Automatic placement preserves existing occupants; replacement applies only to an explicit target.
        local sReason = "No eligible slot has room.";

        for _, oSlot in this.eachItemSlot() do
            local _, bOK, oRemoved, sFailure = oSlot.set(oItem);

            if (bOK) then
                return this, true, oRemoved;
            end

            sReason = sFailure;
        end

        return this, false, nil, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.removeItem
        @desc Finds the item's child slot and delegates removal while preserving the system-facing result tuple.
    !]]
    removeItem = function(this, cdat, oItem, oActor)
        local bFound, nIndex = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local _, bOK, oRemoved, sReason = this.getItemSlotAt(nIndex).remove(oItem, oActor);

        return this, bOK, oRemoved, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.transferItemTo
        @desc Finds the source slot and resolves a destination system to its requested child slot before
        transferring.
    !]]
    transferItemTo = function(this, cdat, oDestination, oItem, nDestinationSlot, bReplace)
        local bFound, nIndex = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        -- A destination system is a parent container; resolve its leaf slot before transferring.
        local oTarget = oDestination;

        if (class.isinstance(oDestination) and class.ischildorself(class.of(oDestination), ItemSlotSystem)) then
            oTarget = oDestination.getItemSlotAt(nDestinationSlot);
        end

        local _, bOK, oRemoved, sReason = this.getItemSlotAt(nIndex).transferItemTo(oTarget, oItem, bReplace);

        return this, bOK, oRemoved, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.swapItems
        @desc Swaps the selected contents inside a transaction so capacity, eligibility and hierarchy rules all
        apply.
    !]]
    swapItems = function(this, cdat, nFirst, nSecond)
        local oFirst, oSecond = this.getItemSlotAt(nFirst), this.getItemSlotAt(nSecond);

        if (not oFirst or not oSecond) then
            return this, false, "Slot was not found.";
        end

        local _, bOK, sReason = oFirst.swapWith(oSecond);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.equipItem
        @desc Checks equipment permission inside the transaction, adding an unlocated item or transferring an
        already stored item.
    !]]
    equipItem = function(this, cdat, oItem, oActor, nSlot)
        Rules.item(oItem);
        local oSlot = this.getItemSlotAt(nSlot);

        if (not oSlot) then
            return this, false, nil, "Slot was not found.";
        end

        local fPermission = function()
            return oItem.canEquipBy(oActor);
        end;

        local bOK, vResult;

        -- Unstored items are added; stored items must transfer so their old location is cleared atomically.
        if (oItem.getLocation() == null) then
            bOK, vResult = Rules.add(oSlot, oItem, false, false, fPermission);
        else
            bOK, vResult = Rules.transfer(oItem.getLocation(), oSlot, oItem, false, fPermission);
        end

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.unequipItem
        @desc Finds the item's slot and checks unequip permission before transferring it to the destination.
    !]]
    unequipItem = function(this, cdat, oItem, oActor, oDestination)
        local bFound, nIndex = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local bOK, vResult = Rules.transfer(this.getItemSlotAt(nIndex), oDestination, oItem, false, function()
            return oItem.canUnequipBy(oActor);
        end);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.clear
        @desc Removes items throughout this subtree in one transaction; returns this, success, removed items or
        a failure reason.
    !]]
    clear = function(this)
        local bOK, vResult = Rules.clear(this);

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.isEnabled
        @desc Returns this container's own enabled flag; mutations also check its ancestors.
    !]]
    isEnabled = function(this)
        return Rules.state(this).enabled;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.isLocked
        @desc Returns this container's own lock flag; mutations also check its ancestors.
    !]]
    isLocked = function(this)
        return Rules.state(this).locked;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.setEnabled
        @desc Sets the local enabled flag and returns this container. Ancestor restrictions still apply.
    !]]
    setEnabled = function(this, cdat, bValue)
        Rules.setFlag(this, "enabled", bValue);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.setLocked
        @desc Sets the local lock flag and returns this container. Locked ancestors still prevent edits.
    !]]
    setLocked = function(this, cdat, bValue)
        Rules.setFlag(this, "locked", bValue);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.configureGrid
        @desc Assigns positive grid dimensions in a transaction; slot count and all existing footprints must
        fit.
    !]]
    configureGrid = function(this, cdat, nWidth, nHeight)
        Rules.integer(nWidth, 1);
        Rules.integer(nHeight, 1);
        local bOK, sReason = Rules.transaction({this}, function()
            Rules.editable(this);

            -- Shared validation checks slot count, bounds, overlap and eligibility before commit.
            Rules.state(this).width, Rules.state(this).height = nWidth, nHeight;
        end);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getGridSize
        @desc Returns width and height, or nil values while grid placement is disabled.
    !]]
    getGridSize = function(this)
        return Rules.state(this).width, Rules.state(this).height;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.disableGrid
        @desc Checks that the system and every slot are editable, then clears grid dimensions and derived
        occupancy.
    !]]
    disableGrid = function(this)
        local bOK, sReason = Rules.transaction({this}, function()
            Rules.editable(this);
            local tState = Rules.state(this);

            for _, oSlot in ipairs(tState.children) do
                Rules.editable(oSlot);
            end

            tState.width, tState.height, tState.cells = nil, nil, nil;
        end);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.placeItem
        @desc Converts zero-based grid coordinates to a one-based anchor slot and delegates insertion.
    !]]
    placeItem = function(this, cdat, oItem, nX, nY)
        Rules.integer(nX, 0);
        Rules.integer(nY, 0);
        local tState = Rules.state(this);
        assert(tState.width, "Configure a grid first.");

        if (nX >= tState.width or nY >= tState.height) then
            return this, false, nil, "Coordinates are outside the grid.";
        end

        -- Grid coordinates start at zero; child slots use a one-based row-major index.
        return this.addItem(oItem, nY * tState.width + nX + 1);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getOccupantAt
        @desc Validates current grid rules and returns the item covering the cell, including footprints anchored
        in another slot.
    !]]
    getOccupantAt = function(this, cdat, nX, nY)
        Rules.integer(nX, 0);
        Rules.integer(nY, 0);
        local tState = Rules.state(this);
        assert(tState.width, "Configure a grid first.");

        if (nX >= tState.width or nY >= tState.height) then
            return nil;
        end

        -- Recheck mutable patterns and registries before answering occupancy from their current values.
        local bOK, sReason = this.validate();
        assert(bOK, sReason);

        return Rules.occupant(this, nX, nY);
    end,

    --[[!
        @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.validate
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
Rules.registerPersistence(cItemSlotSystem);

return cItemSlotSystem;
