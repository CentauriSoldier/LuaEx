--LOCALIZATION
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

return class("ItemSlotSystem",
{--METAMETHODS
    __len = function(this)
        return this.getItemSlotCount();
    end,

    __pairs = function(this)
        return this.eachItemSlot();
    end,

    __clone = function()
        error("Clone concrete items explicitly, then construct a new ItemSlotSystem.");
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
    ItemSlotSystem = function(this, cdat, tItemSlots, oOwner)
        Rules.create(this, "slots", math.huge, oOwner);

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

    getOwner = function(this)
        return Rules.owner(this);
    end,

    getItemSlotCount = function(this)
        return #Rules.state(this).children;
    end,

    getItemCount = function(this)
        return #Rules.items(this);
    end,

    getItemSlotAt = function(this, cdat, nIndex)
        Rules.integer(nIndex, 1);
        return Rules.state(this).children[nIndex];
    end,

    getItemAt = function(this, cdat, nSlot, nItem)
        local oSlot = this.getItemSlotAt(nSlot);
        return oSlot and oSlot.get(nItem) or nil;
    end,

    eachItemSlot = function(this)
        local tOutput = {};

        for nIndex, oSlot in ipairs(Rules.state(this).children) do
            tOutput[nIndex] = oSlot;
        end

        return ipairs(tOutput);
    end,

    eachSlot = function(this)
        return this.eachItemSlot();
    end,

    eachItem = function(this)
        return ipairs(Rules.items(this));
    end,

    containsItemAt = function(this, cdat, oItem, nSlot)
        Rules.item(oItem);
        local oSlot = this.getItemSlotAt(nSlot);
        return oSlot ~= nil and oSlot.containsItem(oItem);
    end,

    containsItem = function(this, cdat, oItem)
        Rules.item(oItem);

        for nIndex, oSlot in this.eachItemSlot() do

            if (oSlot.containsItem(oItem)) then
                return true, nIndex;
            end

        end

        return false, -1;
    end,

    containsItemSlot = function(this, cdat, oSlot)
        assert(class.isinstance(oSlot) and class.of(oSlot) == ItemSlot, "Expected an ItemSlot.");

        for nIndex, oExisting in this.eachItemSlot() do

            if (rawequal(oExisting, oSlot)) then
                return true, nIndex;
            end

        end

        return false, -1;
    end,

    containsItemSlotAt = function(this, cdat, oSlot, nIndex)
        assert(class.isinstance(oSlot) and class.of(oSlot) == ItemSlot, "Expected an ItemSlot.");
        return rawequal(this.getItemSlotAt(nIndex), oSlot);
    end,

    addItemSlot = function(this, cdat, oSlot)
        assert(class.isinstance(oSlot) and class.of(oSlot) == ItemSlot, "Expected an ItemSlot.");
        local bOK, sReason = Rules.adopt(this, oSlot);
        return this, bOK, sReason;
    end,

    removeItemSlot = function(this, cdat, nIndex)
        local bOK, vResult = Rules.release(this, nIndex);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

    addItem = function(this, cdat, oItem, nSlot, bReplace)
        Rules.item(oItem);

        if (nSlot ~= nil) then
            local oSlot = this.getItemSlotAt(nSlot);

            if (not oSlot) then
                return this, false, nil, "Slot does not exist.";
            end

            local _, bOK, oRemoved, sReason = oSlot.set(oItem, bReplace);
            return this, bOK, oRemoved, sReason;
        end

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

    removeItem = function(this, cdat, oItem, oActor)
        local bFound, nIndex = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local _, bOK, oRemoved, sReason = this.getItemSlotAt(nIndex).remove(oItem, oActor);
        return this, bOK, oRemoved, sReason;
    end,

    transferItemTo = function(this, cdat, oDestination, oItem, nDestinationSlot, bReplace)
        local bFound, nIndex = this.containsItem(oItem);

        if (not bFound) then
            return this, false, nil, "Item was not found.";
        end

        local oTarget = oDestination;

        if (class.isinstance(oDestination) and class.ischildorself(class.of(oDestination), ItemSlotSystem)) then
            oTarget = oDestination.getItemSlotAt(nDestinationSlot);
        end

        local _, bOK, oRemoved, sReason = this.getItemSlotAt(nIndex).transferItemTo(oTarget, oItem, bReplace);
        return this, bOK, oRemoved, sReason;
    end,

    swapItems = function(this, cdat, nFirst, nSecond)
        local oFirst, oSecond = this.getItemSlotAt(nFirst), this.getItemSlotAt(nSecond);

        if (not oFirst or not oSecond) then
            return this, false, "Slot was not found.";
        end

        local _, bOK, sReason = oFirst.swapWith(oSecond);
        return this, bOK, sReason;
    end,

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

        if (oItem.getLocation() == null) then
            bOK, vResult = Rules.add(oSlot, oItem, false, false, fPermission);
        else
            bOK, vResult = Rules.transfer(oItem.getLocation(), oSlot, oItem, false, fPermission);
        end

        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
    end,

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

    clear = function(this)
        local bOK, vResult = Rules.clear(this);
        return this, bOK, bOK and vResult or nil, not bOK and vResult or nil;
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

    configureGrid = function(this, cdat, nWidth, nHeight)
        Rules.integer(nWidth, 1);
        Rules.integer(nHeight, 1);
        local bOK, sReason = Rules.transaction({this}, function()
            Rules.editable(this);
            Rules.state(this).width, Rules.state(this).height = nWidth, nHeight;
        end);
        return this, bOK, sReason;
    end,

    getGridSize = function(this)
        return Rules.state(this).width, Rules.state(this).height;
    end,

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

    placeItem = function(this, cdat, oItem, nX, nY)
        Rules.integer(nX, 0);
        Rules.integer(nY, 0);
        local tState = Rules.state(this);
        assert(tState.width, "Configure a grid first.");

        if (nX >= tState.width or nY >= tState.height) then
            return this, false, nil, "Coordinates are outside the grid.";
        end

        return this.addItem(oItem, nY * tState.width + nX + 1);
    end,

    getOccupantAt = function(this, cdat, nX, nY)
        Rules.integer(nX, 0);
        Rules.integer(nY, 0);
        local tState = Rules.state(this);
        assert(tState.width, "Configure a grid first.");

        if (nX >= tState.width or nY >= tState.height) then
            return nil;
        end

        local bOK, sReason = this.validate();
        assert(bOK, sReason);
        return Rules.occupant(this, nX, nY);
    end,

    validate = function(this)
        return Rules.check(this);
    end,

},
nil,
false,
nil
);
