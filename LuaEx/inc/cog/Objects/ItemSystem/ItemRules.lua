--[[!
    @fqxn CoG.ItemSystem.ItemRules
    @desc Internal module coordinating container state, attachment indexes, transactions, eligibility, footprints and persistence. Functions use dot calls. State references are live internal tables; gameplay code should use the public container APIs. Argument assertions can raise errors; transaction validation failures return false and a reason. Permission callbacks inspect projected state and cannot reenter mutations.
!]]
-- Shared containment rules used by the public container classes.
-- Leaf slots and inventories own item arrays; slot systems and stashes own child arrays.
-- A child's parent link points outward, so edits can check restrictions across the entire hierarchy.
local M = {};
local Persistence = require("LuaEx.inc.cog.Objects.ItemSystem.ItemPersistence");

-- Weak keys prevent runtime indexes from keeping otherwise unreachable containers alive.
local tStates = setmetatable({}, {__mode = "k"});
-- Permission callbacks inspect projected membership while bBusy blocks nested mutations.
-- Only the final location-commit phase permits coordinated inverse-link writes.
local bBusy = false;
local bCommittingLocations = false;

--[[!
    @fqxn CoG.ItemSystem.ItemRules.canWriteLocation
    @desc Allow normal writes outside a transaction and coordinated location writes during its final commit. Permission
    callbacks cannot write locations.
!]]
function M.canWriteLocation()

    return not bBusy or bCommittingLocations;
end

-- Each item indexes its inverse host holder; each host indexes its forward child array.
local tAttachments = setmetatable({}, {__mode = "k"});
local tHosts = setmetatable({}, {__mode = "k"});

--[[!
    @fqxn CoG.ItemSystem.ItemRules.registerHost
    @desc Indexes the attachment array owned by a CoG class and reconnects its
    loaded children. Repeated registration of the same array changes nothing.
!]]
function M.registerHost(oHost, tItems, tToken)

    if (rawequal(tHosts[oHost], tItems)) then
        return;
    end

    tHosts[oHost] = tItems;

    for _, oItem in ipairs(tItems) do
        oItem.restoreItemRuntime(tToken);
        assert(tAttachments[oItem].host == null or rawequal(tAttachments[oItem].host, oHost), "Conflicting saved attachment hosts.");
        tAttachments[oItem].host = oHost;
    end
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.registerAttachment
    @desc Indexes an item's declared attachment holder. Host membership shares
    the host's declared array, so future saves include current attachment edits.
!]]
function M.registerAttachment(oItem, tAttachment)
    assert(not bBusy, "Attachment mutations are forbidden inside prerequisite callbacks.");
    tAttachments[oItem] = tAttachment;
    local oHost = tAttachment.host;

    if (oHost ~= null) then
        if (not tHosts[oHost]) then
            tHosts[oHost] = {};
        end

        local bFound = false;

        for _, oExisting in ipairs(tHosts[oHost]) do
            bFound = bFound or rawequal(oExisting, oItem);
        end

        if (not bFound) then
            tHosts[oHost][#tHosts[oHost] + 1] = oItem;
        end
    end
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.attachments
    @desc Copy the host's attachment list so callers cannot edit its indexed membership.
!]]
function M.attachments(oHost)
    local tOutput = {};

    for nIndex, oItem in ipairs(tHosts[oHost] or {}) do
        tOutput[nIndex] = oItem;
    end

    return tOutput;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.attach
    @desc Check storage, permission and ancestry before updating both attachment indexes. The busy guard blocks
    mutations from callbacks.
!]]
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

        tAttachments[oItem].host = oHost;
        tHosts[oHost] = tHosts[oHost] or {};
        tHosts[oHost][#tHosts[oHost] + 1] = oItem;
    end);

    bBusy = false;

    return bOK, not bOK and tostring(sReason) or nil;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.detach
    @desc Check actor permission before removing this item from the host list and clearing its inverse host link.
!]]
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

        tAttachment.host = null;
    end);

    bBusy = false;

    return bOK, not bOK and tostring(sReason) or nil;
end

-- Copy arrays and state fields shallowly: contained object identities must remain unchanged.
local function copy(tInput)
    local tOutput = {};

    for k, v in pairs(tInput) do
        tOutput[k] = v;
    end

    return tOutput;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.integer
    @desc Accept integers at or above the minimum, allowing positive infinity only for explicitly unlimited capacities.
!]]
function M.integer(nValue, nMin, bUnlimited)
    assert(rawtype(nValue) == "number" and nValue >= nMin and
           ((bUnlimited and nValue == math.huge) or (nValue < math.huge and nValue % 1 == 0)),
           "Expected an integer >= "..nMin..".");

    return nValue;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.array
    @desc Validate positive integer keys and reject holes, then shallow-copy entries while retaining item identities.
!]]
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.item
    @desc Require a BaseItem or subclass instance before calling item-specific methods.
!]]
function M.item(oItem)
    assert(class.isinstance(oItem) and class.ischildorself(class.of(oItem), BaseItem), "Expected a BaseItem instance.");
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.state
    @desc Find indexed container state, lazily reconnecting supported instances created by generated deserialization.
!]]
function M.state(oContainer)

    if (not tStates[oContainer] and class.isinstance(oContainer) and
        (type.isItemSlot(oContainer) or type.isItemSystem(oContainer) or
         type.isItemSlotSystem(oContainer) or type.isItemStashSystem(oContainer))) then
        oContainer.restoreRuntime();
    end

    assert(tStates[oContainer], "Expected an item container.");

    return tStates[oContainer];
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.create
    @desc Create the state owned by the container class and index that same table for all shared rules.
!]]
function M.create(oContainer, sKind, nCapacity, oOwner, oRegistry)
    assert(not bBusy, "Container mutations are forbidden inside prerequisite callbacks.");
    assert(oOwner == nil or oOwner == null or class.isinstance(oOwner), "Owner must be a class instance or null.");
    local tState = {
        persistenceID = Persistence.identify(oContainer),
        kind          = sKind,
        capacity      = nCapacity,
        owner         = oOwner or null,
        registry      = oRegistry,
        items         = {},
        children      = {},
        enabled       = true,
        locked        = false
    };
    tStates[oContainer] = tState;

    return tState;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.validateSnapshot
    @desc Validates declared container state before generated class restoration.
    Saved membership is restored without firing gameplay permission callbacks.
!]]
function M.validateSnapshot(tState, sKind)
    type.assert.table(tState);
    M.integer(tState.persistenceID, 1);
    assert(tState.kind == sKind, "Saved container kind does not match its class.");
    M.integer(tState.capacity, sKind == "slot" and 1 or 0, sKind ~= "slot");
    type.assert.custom(tState.enabled, "boolean");
    type.assert.custom(tState.locked, "boolean");
    assert(type.isnull(tState.owner) or class.isinstance(tState.owner), "Invalid saved container owner.");
    M.array(tState.items);
    M.array(tState.children);
    assert(#tState.items <= tState.capacity, "Saved container exceeds capacity.");

    if (sKind == "slot") then
        assert(type.isObjectRegistry(tState.registry), "Invalid saved slot registry.");
    end

    if (sKind == "slot" or sKind == "inventory") then
        assert(#tState.children == 0, "Leaf containers cannot contain child containers.");
    else
        assert(#tState.items == 0, "Parent containers cannot store items directly.");
    end

    if (sKind == "stash") then
        assert(#tState.children > 0, "A saved stash must retain a tab.");
    end

    if (tState.parent ~= nil) then
        assert(class.isinstance(tState.parent), "Invalid saved container parent.");
    end

    assert((tState.width == nil) == (tState.height == nil), "Incomplete saved grid dimensions.");

    if (tState.width ~= nil) then
        assert(sKind == "slots", "Only slot systems support grids.");
        M.integer(tState.width, 1);
        M.integer(tState.height, 1);
        assert(#tState.children == tState.width * tState.height, "Saved grid dimensions do not match slots.");
    end

    tState.cells = nil; -- Derived occupancy is rebuilt on the first grid query.
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.prepareSnapshot
    @desc Omits the external owner, inverse parent link and derived occupancy cache.
    Runtime restoration reconnects child containers and item locations. The caller
    reconnects the owner with setOwner. Saving a tab does not include its stash.
!]]
function M.prepareSnapshot(tState)
    tState.registry = Persistence.registry(tState.registry);

    -- Owners remain external; inverse parent links and derived occupancy are rebuilt after loading.
    tState.owner = null;
    tState.parent = nil;
    tState.cells = nil;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.restore
    @desc Reconnects the runtime lookup to state owned by the restored class.
!]]
function M.restore(oContainer, tState, tToken)
    assert(not bBusy, "Cannot restore containers inside prerequisite callbacks.");

    if (rawequal(tStates[oContainer], tState)) then
        return;
    end

    -- Preserve the class-owned state table so future snapshots observe subsequent edits.
    tStates[oContainer] = tState;
    tState.persistenceID = Persistence.identify(oContainer);

    -- Recover omitted inverse parent links from the saved forward child arrays.
    for _, oChild in ipairs(tState.children) do
        oChild.restoreRuntime();
        local tChild = M.state(oChild);
        assert(tChild.parent == nil or rawequal(tChild.parent, oContainer), "Conflicting saved container parents.");
        tChild.parent = oContainer;
    end

    -- Restore each item's runtime holders before reconnecting its inverse location.
    for _, oItem in ipairs(tState.items) do
        oItem.restoreItemRuntime(tToken);
        local oPrevious = oItem.getLocation();
        assert(oPrevious == null or rawequal(oPrevious, oContainer), "Conflicting saved item locations.");

        if (oPrevious == null) then
            oItem.setLocation(oContainer, null);
        end
    end
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.validateRestored
    @desc Checks decoded membership and hierarchy after this container's runtime
    links have been reconnected. Does not call user permission functions.
!]]
function M.validateRestored(oContainer)
    local tState = M.state(oContainer);
    assert(#tState.items <= tState.capacity, "Restored container exceeds capacity.");
    local tSeen = {};

    -- Check ancestry independently from the membership uniqueness checks below.
    local oCurrent = oContainer;

    while (oCurrent) do
        assert(not tSeen[oCurrent], "Saved container hierarchy contains a cycle.");
        tSeen[oCurrent] = true;
        oCurrent = M.state(oCurrent).parent;
    end

    tSeen = {};

    for _, oItem in ipairs(tState.items) do
        M.item(oItem);
        assert(not tSeen[oItem] and rawequal(oItem.getLocation(), oContainer), "Inconsistent saved item membership.");
        assert(type.isnull(oItem.getAttached_To()), "Attached items cannot also be stored separately.");
        tSeen[oItem] = true;
    end

    tSeen = {};

    for _, oChild in ipairs(tState.children) do
        assert(not tSeen[oChild] and rawequal(M.state(oChild).parent, oContainer), "Inconsistent saved container parent.");
        assert((tState.kind == "stash" and type.isItemSystem(oChild)) or
               (tState.kind == "slots" and type.isItemSlot(oChild)), "Invalid saved child container type.");
        tSeen[oChild] = true;
    end

    if (tState.parent) then
        local nFound = 0;

        for _, oChild in ipairs(M.state(tState.parent).children) do
            if (rawequal(oChild, oContainer)) then
                nFound = nFound + 1;
            end
        end

        assert(nFound == 1, "Saved parent does not contain its child exactly once.");
    end

    -- Expand anchor-relative footprints into cells and reject out-of-bounds cells or overlap.
    if (tState.width) then
        local tCells = {};

        for nIndex, oSlot in ipairs(tState.children) do
            local nX = (nIndex - 1) % tState.width;
            local nY = math.floor((nIndex - 1) / tState.width);

            for _, oItem in ipairs(M.state(oSlot).items) do
                local tPattern = oItem.getSlot_Pattern().getSlots();

                if (#tPattern == 0) then
                    tPattern = {{x = 0, y = 0}};
                end

                for _, tOffset in ipairs(tPattern) do
                    local nCellX, nCellY = nX + tOffset.x, nY + tOffset.y;
                    assert(nCellX >= 0 and nCellX < tState.width and nCellY >= 0 and nCellY < tState.height, "Saved item footprint is outside its grid.");
                    local nCell = nCellY * tState.width + nCellX + 1;
                    assert(not tCells[nCell], "Saved item footprints overlap.");
                    tCells[nCell] = oItem;
                end
            end
        end

        tState.cells = tCells;
    end
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.discard
    @desc Removes runtime indexes for a rejected restored object. Live source
    objects and their declared state are unaffected.
!]]
function M.discard(oObject)
    tStates[oObject], tAttachments[oObject], tHosts[oObject] = nil, nil, nil;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.validateAttachments
    @desc Checks unique attachment membership and exact host identity after loading.
!]]
function M.validateAttachments(oHost)
    local tSeen = {};

    for _, oItem in ipairs(tHosts[oHost] or {}) do
        M.item(oItem);
        assert(not tSeen[oItem] and rawequal(oItem.getAttached_To(), oHost), "Inconsistent saved attachment.");
        tSeen[oItem] = true;
    end
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.validateAttachment
    @desc Rejects conflicting locations, missing host membership and attachment
    cycles after all loaded objects have reconnected their declared state.
!]]
function M.validateAttachment(oItem)
    local oHost = oItem.getAttached_To();
    local tSeen = {[oItem] = true};

    while (oHost ~= null) do
        assert(type.isCoG(oHost) and not tSeen[oHost], "Invalid saved attachment host or cycle.");
        tSeen[oHost] = true;
        oHost = tAttachments[oHost] and tAttachments[oHost].host or null;
    end

    oHost = oItem.getAttached_To();

    if (oHost ~= null) then
        local nFound = 0;

        for _, oChild in ipairs(tHosts[oHost] or {}) do
            if (rawequal(oChild, oItem)) then
                nFound = nFound + 1;
            end
        end

        assert(nFound == 1 and oItem.getLocation() == null, "Inconsistent saved attachment host membership.");
    end
end

-- A leaf edit also affects the rules defined by its outermost stash or slot system.
local function root(oContainer)
    local tSeen = {};

    while tStates[oContainer].parent do
        assert(not tSeen[oContainer], "Container hierarchy contains a cycle.");
        tSeen[oContainer] = true;
        oContainer = tStates[oContainer].parent;
    end

    return oContainer;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.scopes
    @desc Collect the selected container followed by each ancestor, in outward order.
!]]
function M.scopes(oContainer)
    local tScopes = {};

    while oContainer do
        tScopes[#tScopes + 1] = oContainer;
        oContainer = M.state(oContainer).parent;
    end

    return tScopes;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.owner
    @desc Keep the outermost non-null owner so a containing system can define ownership for its children.
!]]
function M.owner(oContainer)
    local oOwner = null;

    for _, oScope in ipairs(M.scopes(oContainer)) do

        if (M.state(oScope).owner ~= null) then
            oOwner = M.state(oScope).owner;
        end
    end

    return oOwner;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.items
    @desc Collect item references recursively in child order into an independent output array.
!]]
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

-- Validate projected membership while item locations still describe the last committed state.
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

            -- Inventory storage requires an allowed scope somewhere in the hierarchy.
            -- A standalone equipment slot does not itself introduce that storage requirement.
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

        -- Exclusivity applies across this entire subtree, including sibling tabs or slots.
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

        -- Membership stores anchors only; footprints can cover several other child slots.
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.transaction
    @desc Snapshot state, project a mutation, validate affected roots and commit inverse locations. Errors and previews
    restore the snapshot.
!]]
function M.transaction(tTouched, fMutation, bPreview)
    assert(not bBusy, "Container mutations are forbidden inside prerequisite callbacks.");
    local tSnapshots, tOldLocations, tRoots = {}, {}, {};

    -- Copy indexed state and its membership arrays before exposing projected changes to callbacks.
    for oContainer, tState in pairs(tStates) do
        local tSnapshot = copy(tState);
        tSnapshot.items, tSnapshot.children = copy(tState.items), copy(tState.children);
        tSnapshots[oContainer] = tSnapshot;

        for _, oItem in ipairs(tState.items) do
            assert(rawequal(oItem.getLocation(), oContainer), "Item location is inconsistent with container membership.");
            tOldLocations[oItem] = oContainer;
        end
    end

    -- Capture old roots before adoption or release can change the hierarchy.
    for _, oContainer in ipairs(tTouched) do
        tRoots[root(oContainer)] = true;
    end

    bBusy = true;

    local tResult = table.pack(pcall(function()
        local tReturns = table.pack(fMutation());

        -- Include the new roots too so both sides of a hierarchy change are checked.
        for _, oContainer in ipairs(tTouched) do
            tRoots[root(oContainer)] = true;
        end

        for oRoot in pairs(tRoots) do
            validate(oRoot);
        end

        -- Preview validates the proposed arrangement but never commits inverse location links.
        if (bPreview) then
            return table.unpack(tReturns, 1, tReturns.n);
        end

        -- Derive final inverse locations only after every affected root accepts projected membership.
        local tNewLocations = {};

        for oContainer, tState in pairs(tStates) do

            for _, oItem in ipairs(tState.items) do
                assert(not tNewLocations[oItem], "Item already belongs to another container.");
                tNewLocations[oItem] = oContainer;
                local oPrevious = tOldLocations[oItem] or null;
                assert(rawequal(oItem.getLocation(), oPrevious), "Item must be removed from its previous location first.");
            end
        end

        -- Open the coordinated location-write phase only after user permission checks have finished.
        bCommittingLocations = true;

        for oItem, oOldLocation in pairs(tOldLocations) do

            if (not rawequal(oOldLocation, tNewLocations[oItem])) then
                oItem.setLocation(tNewLocations[oItem] or null, oOldLocation);
            end
        end

        -- Newly stored items had no previous membership for the preceding update loop to visit.
        for oItem, oNewLocation in pairs(tNewLocations) do

            if (not tOldLocations[oItem]) then
                oItem.setLocation(oNewLocation, null);
            end
        end

        return table.unpack(tReturns, 1, tReturns.n);
    end));

    bCommittingLocations = false;
    bBusy = false;

    -- Restore fields in place on failure or preview. Replacing the state table would
    -- disconnect this runtime index from the state held by the class instance.
    if (not tResult[1] or bPreview) then

        for oContainer, tSnapshot in pairs(tSnapshots) do
            local tState = tStates[oContainer];

            for k in pairs(tState) do
                tState[k] = nil;
            end

            for k, v in pairs(tSnapshot) do
                tState[k] = v;
            end
        end

        if (not tResult[1]) then
            return false, tostring(tResult[2]);
        end
    end

    return true, table.unpack(tResult, 2, tResult.n);
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.editable
    @desc Require the container and all its ancestors to be enabled and unlocked.
!]]
function M.editable(oContainer)

    for _, oScope in ipairs(M.scopes(oContainer)) do
        local tState = M.state(oScope);
        assert(tState.enabled and not tState.locked, "Container is disabled or locked.");
    end
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.footprintEditable
    @desc For a grid slot, require every cell covered by this item's relative footprint to be editable.
!]]
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.indexOf
    @desc Return the one-based position of this exact item instance, or nil when absent.
!]]
function M.indexOf(oContainer, oItem)

    for nIndex, oExisting in ipairs(M.state(oContainer).items) do

        if (rawequal(oItem, oExisting)) then
            return nIndex;
        end
    end
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.add
    @desc Project insertion into a leaf container, optionally displacing its first item when full. The transaction
    validates the result.
!]]
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

        -- Replacement displaces the first occupant; complete validation can still reject the change.
        if (#tState.items >= tState.capacity) then
            assert(bReplace, "Container is full.");
            M.footprintEditable(oContainer, tState.items[1]);
            oRemoved = table.remove(tState.items, 1);
        end

        tState.items[#tState.items + 1] = oItem;

        return oRemoved;
    end, bPreview);
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.preview
    @desc Use the insertion path in preview mode, restoring membership without changing item locations.
!]]
function M.preview(oContainer, oItem, bReplace)
    local bOK, vResult = M.add(oContainer, oItem, bReplace, true);

    return bOK, not bOK and vResult or nil;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.remove
    @desc Resolve the default item, exact instance or index; check access and optional actor permission before removal.
!]]
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.transfer
    @desc Project source removal and destination insertion together, returning any displaced destination item.
!]]
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

        -- Project both halves before validation so a transfer is never observed as a duplicate.
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.swap
    @desc Exchange complete membership arrays after checking access to both containers and all affected footprints.
!]]
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.clear
    @desc Collect removed items and recursively clear leaf membership; commit every inverse location together.
!]]
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.adopt
    @desc Adopt an independent child only when its ancestry cannot form a cycle; validate both affected roots.
!]]
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.release
    @desc Release an editable, empty child and clear its parent link in one transaction.
!]]
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.setFlag
    @desc Require a boolean and block callback reentry before changing a local container flag.
!]]
function M.setFlag(oContainer, sFlag, bValue)
    assert(not bBusy, "Container mutations are forbidden inside prerequisite callbacks.");
    assert(rawtype(bValue) == "boolean", "Flag must be a boolean.");
    M.state(oContainer)[sFlag] = bValue;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.check
    @desc Preview an empty mutation to validate current rules without committing changes.
!]]
function M.check(oContainer)
    local bOK, sReason = M.transaction({oContainer}, function() end, true);

    return bOK, not bOK and tostring(sReason) or nil;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.occupant
    @desc Search anchors and relative patterns for the item covering a grid cell. Empty patterns cover their anchor
    only.
!]]
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

--[[!
    @fqxn CoG.ItemSystem.ItemRules.setOwner
    @desc Reconnects an external owner without changing saved membership.
!]]
function M.setOwner(oContainer, oOwner)
    assert(not bBusy, "Owner changes are forbidden inside prerequisite callbacks.");
    assert(type.isnull(oOwner) or class.isinstance(oOwner), "Owner must be a class instance or null.");
    M.state(oContainer).owner = oOwner;
end

--[[!
    @fqxn CoG.ItemSystem.ItemRules.registerPersistence
    @desc Uses the general serializer factory extension to reconnect inventory
    indexes after the existing generated class deserializer restores fields.
!]]
local tPersistenceClasses = setmetatable({}, {__mode = "k"});
function M.registerPersistence(cObject, bItem)

    if (tPersistenceClasses[cObject]) then
        return;
    end

    local sName = class.getname(cObject);

    -- Let generated deserialization restore fields, then reconnect inventory-only runtime indexes.
    local function fRestore(tState, tToken)
        local oObject = cObject.deserialize(tState);
        local nID = bItem and tState.BaseItem.pri.persistenceID or tState[sName].pri.state.persistenceID;

        -- Publish the loaded identity before resolving links that can point back to this object.
        Persistence.reconnect(nID, oObject, tToken);
        local bOK, sReason = pcall(function()
            if (bItem) then
                oObject.restoreItemRuntime();
                M.validateAttachment(oObject);
                M.validateAttachments(oObject);
            else
                oObject.restoreRuntime(tToken);
                M.validateRestored(oObject);
            end
        end);

        if (not bOK) then
            M.discard(oObject);
            error(sReason);
        end

        return oObject;
    end

    -- Use the existing generic factory extension; register the adapter only once per class.
    require("LuaEx.lib.serializer").registerFactory(cObject, {name = sName, types = {sName}, restore = fRestore});
    tPersistenceClasses[cObject] = true;
end

return M;
