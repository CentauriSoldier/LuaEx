-- Shared containment rules. Class facades keep their public naming conventions.
local M = {};
local tStates = setmetatable({}, {__mode = "k"});
local bBusy = false;
local bCommittingLocations = false;

function M.canWriteLocation()
    return not bBusy or bCommittingLocations;
end
local tAttachments = setmetatable({}, {__mode = "k"});
local tHosts = setmetatable({}, {__mode = "k"});

function M.registerAttachment(oItem, oHost, fSetHost)
    assert(not bBusy, "Attachment mutations are forbidden inside prerequisite callbacks.");
    tAttachments[oItem] = {host = oHost, setHost = fSetHost};

    if (oHost ~= null) then
        tHosts[oHost] = tHosts[oHost] or {};
        tHosts[oHost][#tHosts[oHost] + 1] = oItem;
    end

end

function M.attachments(oHost)
    local tOutput = {};

    for nIndex, oItem in ipairs(tHosts[oHost] or {}) do
        tOutput[nIndex] = oItem;
    end

    return tOutput;
end

function M.attach(oItem, oHost)
    assert(not bBusy, "Attachment mutations are forbidden inside prerequisite callbacks.");
    bBusy = true;
    local bOK, sReason = pcall(function()
        assert(oItem.getLocation() == null, "Remove the item from storage before attaching it.");
        assert(oItem.getAttached_To() == null, "Detach the item from its current host first.");
        assert(oItem.canAttachTo(oHost), "Attachment host is not permitted.");
        local oAncestor = oHost;

        while oAncestor ~= null do
            assert(not rawequal(oAncestor, oItem), "Attachment would create a cycle.");
            oAncestor = tAttachments[oAncestor] and tAttachments[oAncestor].host or null;
        end

        tAttachments[oItem].setHost(oHost);
        tAttachments[oItem].host = oHost;
        tHosts[oHost] = tHosts[oHost] or {};
        tHosts[oHost][#tHosts[oHost] + 1] = oItem;
    end);
    bBusy = false;
    return bOK, not bOK and tostring(sReason) or nil;
end

function M.detach(oItem, oActor)
    assert(not bBusy, "Attachment mutations are forbidden inside prerequisite callbacks.");
    bBusy = true;
    local bOK, sReason = pcall(function()
        local tAttachment = tAttachments[oItem];
        assert(tAttachment.host ~= null, "Item is not attached.");
        assert(oItem.canDetachBy(oActor), "Actor may not detach this item.");
        local tItems = tHosts[tAttachment.host];

        for nIndex, oExisting in ipairs(tItems) do

            if (rawequal(oItem, oExisting)) then
                table.remove(tItems, nIndex);
                break;
            end

        end

        tAttachment.setHost(null);
        tAttachment.host = null;
    end);
    bBusy = false;
    return bOK, not bOK and tostring(sReason) or nil;
end

local function copy(tInput)
    local tOutput = {};

    for k, v in pairs(tInput) do
        tOutput[k] = v;
    end

    return tOutput;
end

function M.integer(nValue, nMin, bUnlimited)
    assert(rawtype(nValue) == "number" and nValue >= nMin and
           ((bUnlimited and nValue == math.huge) or (nValue < math.huge and nValue % 1 == 0)),
           "Expected an integer >= "..nMin..".");
    return nValue;
end

function M.array(tInput)
    assert(rawtype(tInput) == "table" and not class.isinstance(tInput), "Expected an entries array.");
    local nCount = 0;

    for k in pairs(tInput) do
        M.integer(k, 1);
        nCount = nCount + 1;
    end

    for nIndex = 1, nCount do
        assert(tInput[nIndex] ~= nil, "Entries must form a dense array.");
    end

    return copy(tInput);
end

function M.item(oItem)
    assert(class.isinstance(oItem) and class.ischildorself(class.of(oItem), BaseItem), "Expected a BaseItem instance.");
end

function M.state(oContainer)
    assert(tStates[oContainer], "Expected an item container.");
    return tStates[oContainer];
end

function M.create(oContainer, sKind, nCapacity, oOwner, oRegistry)
    assert(not bBusy, "Container mutations are forbidden inside prerequisite callbacks.");
    assert(oOwner == nil or oOwner == null or class.isinstance(oOwner), "Owner must be a class instance or null.");
    local tState = {kind = sKind, capacity = nCapacity, owner = oOwner or null,
                    registry = oRegistry, items = {}, children = {}, enabled = true, locked = false};
    tStates[oContainer] = tState;
    return tState;
end

local function root(oContainer)
    local tSeen = {};

    while tStates[oContainer].parent do
        assert(not tSeen[oContainer], "Container hierarchy contains a cycle.");
        tSeen[oContainer] = true;
        oContainer = tStates[oContainer].parent;
    end

    return oContainer;
end

function M.scopes(oContainer)
    local tScopes = {};

    while oContainer do
        tScopes[#tScopes + 1] = oContainer;
        oContainer = M.state(oContainer).parent;
    end

    return tScopes;
end

function M.owner(oContainer)
    local oOwner = null;

    for _, oScope in ipairs(M.scopes(oContainer)) do

        if (M.state(oScope).owner ~= null) then
            oOwner = M.state(oScope).owner;
        end

    end

    return oOwner;
end

function M.items(oContainer)
    local tOutput = {};
    local function visit(oCurrent)
        local tState = M.state(oCurrent);

        for _, oItem in ipairs(tState.items) do
            tOutput[#tOutput + 1] = oItem;
        end

        for _, oChild in ipairs(tState.children) do
            visit(oChild);
        end

    end;
    visit(oContainer);
    return tOutput;
end

local function validate(oRoot)
    local tSeen = {};
    local function visit(oContainer)
        local tState = M.state(oContainer);
        assert(#tState.items <= tState.capacity, "Container capacity exceeded.");
        local tScopes = M.scopes(oContainer);

        for _, oItem in ipairs(tState.items) do
            M.item(oItem);
            assert(oItem.getAttached_To() == null, "Attached items cannot occupy a separate storage location.");
            assert(not tSeen[oItem], "The same item instance cannot occupy multiple locations.");
            tSeen[oItem] = true;

            if (tState.registry) then
                local bAllowed, sReason = tState.registry.allows(oItem, oContainer);
                assert(bAllowed, sReason or "Slot eligibility rejected the item.");
            end

            local bStorage, bAllowedStorage = false, false;

            for _, oScope in ipairs(tScopes) do

                if (M.state(oScope).kind == "inventory" or M.state(oScope).kind == "stash") then
                    bStorage = true;
                end

                if (oItem.getStorable_In().allows(oScope, oItem)) then
                    bAllowedStorage = true;
                end

            end

            assert(not bStorage or bAllowedStorage, "Item is not storable in this container hierarchy.");
        end

        local tItems = M.items(oContainer);

        -- Only actual rule owners need scans. Empty defaults avoid quadratic work.
        for _, oRuleOwner in ipairs(tItems) do
            local oConflicts = oRuleOwner.getExclusive_With();

            if (oConflicts.getCount() > 0 and oRuleOwner.getExclusive_In().allows(oContainer, oRuleOwner)) then

                for _, oOther in ipairs(tItems) do

                    if (not rawequal(oRuleOwner, oOther)) then
                        assert(not oConflicts.allows(oOther, oRuleOwner, oContainer), "Exclusive items conflict in this container.");
                    end

                end

            end

        end

        for _, oChild in ipairs(tState.children) do
            assert(rawequal(M.state(oChild).parent, oContainer), "Container parent is inconsistent.");
            visit(oChild);
        end

        if (tState.width) then
            local tCells = {};
            assert(#tState.children == 1.0 * tState.width * tState.height, "Grid dimensions do not match its slots.");

            for nIndex, oSlot in ipairs(tState.children) do
                local nX, nY = (nIndex - 1) % tState.width, math.floor((nIndex - 1) / tState.width);

                for _, oItem in ipairs(M.state(oSlot).items) do
                    local tPattern = oItem.getSlot_Pattern().getSlots();

                    if (#tPattern == 0) then
                        tPattern = {{x = 0, y = 0}};
                    end

                    for _, tOffset in ipairs(tPattern) do
                        local x, y = nX + tOffset.x, nY + tOffset.y;
                        assert(x >= 0 and x < tState.width and y >= 0 and y < tState.height, "Item pattern extends outside the grid.");
                        local nCell = y * tState.width + x + 1;
                        assert(not tCells[nCell], "Item patterns overlap; grid slots hold one footprint each.");
                        local tCell = M.state(tState.children[nCell]);
                        assert(tCell.registry.allows(oItem, tState.children[nCell]), "A footprint slot rejects the item.");
                        tCells[nCell] = oItem;
                    end

                end

            end

            tState.cells = tCells;
        end

    end;
    visit(oRoot);
end

-- Mutate projected membership, validate complete affected roots, then update all
-- location references. Failure restores every container; callbacks cannot reenter.
function M.transaction(tTouched, fMutation, bPreview)
    assert(not bBusy, "Container mutations are forbidden inside prerequisite callbacks.");
    local tSnapshots, tOldLocations, tRoots = {}, {}, {};

    for oContainer, tState in pairs(tStates) do
        local tSnapshot = copy(tState);
        tSnapshot.items, tSnapshot.children = copy(tState.items), copy(tState.children);
        tSnapshots[oContainer] = tSnapshot;

        for _, oItem in ipairs(tState.items) do
            assert(rawequal(oItem.getLocation(), oContainer), "Item location is inconsistent with container membership.");
            tOldLocations[oItem] = oContainer;
        end

    end

    for _, oContainer in ipairs(tTouched) do
        tRoots[root(oContainer)] = true;
    end

    bBusy = true;
    local tResult = table.pack(pcall(function()
        local tReturns = table.pack(fMutation());

        for _, oContainer in ipairs(tTouched) do
            tRoots[root(oContainer)] = true;
        end

        for oRoot in pairs(tRoots) do
            validate(oRoot);
        end

        if (bPreview) then
            return table.unpack(tReturns, 1, tReturns.n);
        end

        local tNewLocations = {};

        for oContainer, tState in pairs(tStates) do

            for _, oItem in ipairs(tState.items) do
                assert(not tNewLocations[oItem], "Item already belongs to another container.");
                tNewLocations[oItem] = oContainer;
                local oPrevious = tOldLocations[oItem] or null;
                assert(rawequal(oItem.getLocation(), oPrevious), "Item must be removed from its previous location first.");
            end

        end

        bCommittingLocations = true;

        for oItem, oOldLocation in pairs(tOldLocations) do

            if (not rawequal(oOldLocation, tNewLocations[oItem])) then
                oItem.setLocation(tNewLocations[oItem] or null, oOldLocation);
            end

        end

        for oItem, oNewLocation in pairs(tNewLocations) do

            if (not tOldLocations[oItem]) then
                oItem.setLocation(oNewLocation, null);
            end

        end

        return table.unpack(tReturns, 1, tReturns.n);
    end));
    bCommittingLocations = false;
    bBusy = false;

    if (not tResult[1] or bPreview) then

        for oContainer, tSnapshot in pairs(tSnapshots) do
            tStates[oContainer] = tSnapshot;
        end

        if (not tResult[1]) then
            return false, tostring(tResult[2]);
        end
    end

    return true, table.unpack(tResult, 2, tResult.n);
end

function M.editable(oContainer)

    for _, oScope in ipairs(M.scopes(oContainer)) do
        local tState = M.state(oScope);
        assert(tState.enabled and not tState.locked, "Container is disabled or locked.");
    end

end

function M.footprintEditable(oSlot, oItem)
    local oParent = M.state(oSlot).parent;

    if (not oParent or not M.state(oParent).width) then
        return;
    end

    local tGrid = M.state(oParent);
    local nAnchor;

    for nIndex, oExisting in ipairs(tGrid.children) do

        if (rawequal(oExisting, oSlot)) then
            nAnchor = nIndex;
            break;
        end

    end

    local x, y = (nAnchor - 1) % tGrid.width, math.floor((nAnchor - 1) / tGrid.width);
    local tOffsets = oItem.getSlot_Pattern().getSlots();

    if (#tOffsets == 0) then
        tOffsets = {{x = 0, y = 0}};
    end

    for _, tOffset in ipairs(tOffsets) do
        local nX, nY = x + tOffset.x, y + tOffset.y;
        assert(nX >= 0 and nX < tGrid.width and nY >= 0 and nY < tGrid.height, "Footprint is outside the grid.");
        M.editable(tGrid.children[nY * tGrid.width + nX + 1]);
    end

end

function M.indexOf(oContainer, oItem)

    for nIndex, oExisting in ipairs(M.state(oContainer).items) do

        if (rawequal(oItem, oExisting)) then
            return nIndex;
        end

    end

end

function M.add(oContainer, oItem, bReplace, bPreview, fPermission)
    M.item(oItem);
    assert(bReplace == nil or rawtype(bReplace) == "boolean", "Replacement flag must be a boolean.");
    return M.transaction({oContainer}, function()
        M.editable(oContainer);
        M.footprintEditable(oContainer, oItem);

        if (fPermission) then
            assert(fPermission(), "Action permission rejected the item.");
        end
        assert(oItem.getAttached_To() == null, "Attached items cannot be stored separately from their host.");
        assert(oItem.getLocation() == null, "Item must be transferred from its current location.");
        local tState = M.state(oContainer);
        assert(tState.kind == "slot" or tState.kind == "inventory", "Select a leaf slot or inventory tab.");
        local oRemoved;

        if (#tState.items >= tState.capacity) then
            assert(bReplace, "Container is full.");
            M.footprintEditable(oContainer, tState.items[1]);
            oRemoved = table.remove(tState.items, 1);
        end

        tState.items[#tState.items + 1] = oItem;
        return oRemoved;
    end, bPreview);
end

function M.preview(oContainer, oItem, bReplace)
    local bOK, vResult = M.add(oContainer, oItem, bReplace, true);
    return bOK, not bOK and vResult or nil;
end

function M.remove(oContainer, vItem, oActor, sPermission)
    local nIndex;

    if (vItem == nil) then
        nIndex = 1;
    elseif (class.isinstance(vItem)) then
        M.item(vItem);
        nIndex = M.indexOf(oContainer, vItem);
    else
        nIndex = M.integer(vItem, 1);
    end

    return M.transaction({oContainer}, function()
        M.editable(oContainer);
        assert(nIndex and M.state(oContainer).items[nIndex], "Item was not found.");
        local oItem = M.state(oContainer).items[nIndex];

        if (oActor ~= nil) then
            assert(oItem[sPermission or "canRemoveBy"](oActor), "Actor is not permitted to perform this action.");
        end
        M.footprintEditable(oContainer, M.state(oContainer).items[nIndex]);
        return table.remove(M.state(oContainer).items, nIndex);
    end);
end

function M.transfer(oSource, oDestination, oItem, bReplace, fPermission)
    M.item(oItem);
    assert(bReplace == nil or rawtype(bReplace) == "boolean", "Replacement flag must be a boolean.");
    return M.transaction({oSource, oDestination}, function()
        assert(not rawequal(oSource, oDestination), "Source and destination must differ.");
        M.editable(oSource);
        M.editable(oDestination);
        M.footprintEditable(oSource, oItem);
        M.footprintEditable(oDestination, oItem);

        if (fPermission) then
            assert(fPermission(), "Action permission rejected the transfer.");
        end
        local nIndex = M.indexOf(oSource, oItem);
        assert(nIndex, "Source does not contain this item.");
        local tDestination = M.state(oDestination);
        assert(tDestination.kind == "slot" or tDestination.kind == "inventory", "Select a destination slot or tab.");
        local oRemoved;
        table.remove(M.state(oSource).items, nIndex);

        if (#tDestination.items >= tDestination.capacity) then
            assert(bReplace, "Destination is full.");
            M.footprintEditable(oDestination, tDestination.items[1]);
            oRemoved = table.remove(tDestination.items, 1);
        end

        tDestination.items[#tDestination.items + 1] = oItem;
        return oRemoved;
    end);
end

function M.swap(oFirst, oSecond)
    return M.transaction({oFirst, oSecond}, function()
        assert(not rawequal(oFirst, oSecond), "Cannot swap a container with itself.");
        M.editable(oFirst);
        M.editable(oSecond);
        local tFirst, tSecond = M.state(oFirst), M.state(oSecond);

        for _, oItem in ipairs(tFirst.items) do
            M.footprintEditable(oFirst, oItem);
            M.footprintEditable(oSecond, oItem);
        end

        for _, oItem in ipairs(tSecond.items) do
            M.footprintEditable(oFirst, oItem);
            M.footprintEditable(oSecond, oItem);
        end

        tFirst.items, tSecond.items = tSecond.items, tFirst.items;
    end);
end

function M.clear(oContainer)
    return M.transaction({oContainer}, function()
        local tRemoved = M.items(oContainer);
        local function visit(oCurrent)
            M.editable(oCurrent);
            local tState = M.state(oCurrent);

            for _, oItem in ipairs(tState.items) do
                M.footprintEditable(oCurrent, oItem);
            end

            tState.items = {};

            for _, oChild in ipairs(tState.children) do
                visit(oChild);
            end

        end;
        visit(oContainer);
        return tRemoved;
    end);
end

function M.adopt(oContainer, oChild)
    return M.transaction({oContainer, oChild}, function()
        M.editable(oContainer);
        assert(not M.state(oChild).parent, "Container already belongs to another system.");
        local oAncestor = oContainer;

        while oAncestor do
            assert(not rawequal(oAncestor, oChild), "Cannot create a containment cycle.");
            oAncestor = M.state(oAncestor).parent;
        end

        M.state(oContainer).children[#M.state(oContainer).children + 1] = oChild;
        M.state(oChild).parent = oContainer;
    end);
end

function M.release(oContainer, nIndex)
    M.integer(nIndex, 1);
    return M.transaction({oContainer}, function()
        M.editable(oContainer);
        local tState = M.state(oContainer);
        local oChild = tState.children[nIndex];
        assert(oChild, "Child container was not found.");
        M.editable(oChild);
        assert(#M.items(oChild) == 0, "Empty the container before removing it.");
        table.remove(tState.children, nIndex);
        M.state(oChild).parent = nil;
        return oChild;
    end);
end

function M.setFlag(oContainer, sFlag, bValue)
    assert(not bBusy, "Container mutations are forbidden inside prerequisite callbacks.");
    assert(rawtype(bValue) == "boolean", "Flag must be a boolean.");
    M.state(oContainer)[sFlag] = bValue;
end

function M.check(oContainer)
    local bOK, sReason = M.transaction({oContainer}, function() end, true);
    return bOK, not bOK and tostring(sReason) or nil;
end

function M.occupant(oGrid, nX, nY)
    local tState = M.state(oGrid);

    for nIndex, oSlot in ipairs(tState.children) do
        local nAnchorX, nAnchorY = (nIndex - 1) % tState.width, math.floor((nIndex - 1) / tState.width);

        for _, oItem in ipairs(M.state(oSlot).items) do
            local oPattern = oItem.getSlot_Pattern();

            if ((oPattern.getSlotCount() == 0 and nX == nAnchorX and nY == nAnchorY) or
                oPattern.contains(nX - nAnchorX, nY - nAnchorY)) then
                return oItem;
            end

        end

    end

end

return M;
