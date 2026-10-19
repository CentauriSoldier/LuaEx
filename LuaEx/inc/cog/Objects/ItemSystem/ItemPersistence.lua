--[[!
    @fqxn CoG.ItemSystem.ItemPersistence
    @desc Internal serializer adapters for inventory identities and shared permission registries. Load tokens isolate independent graph restorations. Owners remain external. This module uses the existing serializer factory protocol and does not define a separate save format for gameplay callers.
!]]
-- Inventory adapters use the serializer's existing factory protocol.
local M = {};

-- These weak indexes do not keep otherwise unreachable objects or load tokens alive.
-- IDs identify saved inventory members; contexts keep separate loads from sharing members.
local tIDs = setmetatable({}, {__mode = "k"});
local tContexts = setmetatable({}, {__mode = "k"});
local tWrappers = setmetatable({}, {__mode = "k"});
local nNextID = 0;

--[[!
    @fqxn CoG.ItemSystem.ItemPersistence.identify
    @desc Assigns an inventory-local identity for registry references in snapshots.
!]]
function M.identify(oObject)

    -- Repeated references reuse the same ID instead of creating multiple saved identities.
    if (not tIDs[oObject]) then
        nNextID = nNextID + 1;
        tIDs[oObject] = nNextID;
    end

    return tIDs[oObject];
end

-- The serializer supplies one opaque token for an entire graph restoration.
-- Registries can load before their referenced containers, so each token owns a waiting list.
local function context(tToken)

    if (not tContexts[tToken]) then
        tContexts[tToken] = {objects = {}, pending = {}};
    end

    return tContexts[tToken];
end

--[[!
    @fqxn CoG.ItemSystem.ItemPersistence.reconnect
    @desc Resolves registry entries against objects from this load operation only.
!]]
function M.reconnect(nID, oObject, tToken)
    type.assert.number(nID);
    local tContext = context(tToken);

    -- Reconnection can be reached both by a factory adapter and by a containing inventory.
    for _, oExisting in pairs(tContext.objects) do
        if (rawequal(oExisting, oObject)) then
            return;
        end
    end

    -- A different object cannot claim an ID that this load operation already resolved.
    assert(not tContext.objects[nID], "Duplicate saved inventory identity.");
    tContext.objects[nID] = oObject;

    -- Complete registry entries deferred while this object had not yet been constructed.
    for _, oRegistry in ipairs(tContext.pending[nID] or {}) do
        oRegistry.add(oObject);
    end

    tContext.pending[nID] = nil;
    M.identify(oObject);
end

-- A lightweight snapshot object adapts registries without changing either registry class.
local tRegistryMeta = {
    __type = "InventoryRegistrySnapshot",
    __serialize = function(tWrapper)
        local oRegistry = tWrapper.registry;
        local tEntries = {};

        -- Store inventory members by ID to avoid inverse object cycles. Other entries,
        -- such as class references, use the serializer's ordinary value protocol.
        for _, vEntry in oRegistry.eachEntry() do
            tEntries[#tEntries + 1] = tIDs[vEntry] and {id = tIDs[vEntry]} or {value = vEntry};
        end

        -- Capture the actual prerequisite explicitly; generated class snapshots omit function fields.
        return {
            kind         = type(oRegistry),
            entries      = tEntries,
            prerequisite = oRegistry.getPrerequisite(),
            default      = oRegistry.getDefaultPrerequisite()
        };
    end,
};

-- The generic registration API requires a callable factory. The restore adapter below
-- constructs the real registry; the marker factory itself never creates gameplay objects.
local oFactory = setmetatable({}, {__call = function() end});
require("LuaEx.lib.serializer").registerFactory(oFactory, {
    name = "InventoryRegistrySnapshot", types = {"InventoryRegistrySnapshot"},
    restore = function(tState, tToken)

        -- Validate the descriptor before constructing a mutable permission registry.
        assert(tState.kind == "ObjectRegistry" or tState.kind == "CoGRegistry", "Invalid inventory registry kind.");
        type.assert.table(tState.entries);
        type.assert.custom(tState.default, "boolean", "Invalid default prerequisite.");
        type.assert.custom(tState.prerequisite, "function", "Invalid inventory prerequisite.");
        local oRegistry = (tState.kind == "ObjectRegistry" and ObjectRegistry or CoGRegistry)({}, tState.prerequisite, tState.default);
        local tContext = context(tToken);

        -- Some referenced members load first; others resolve later through reconnect.
        for _, tEntry in ipairs(tState.entries) do
            if (tEntry.id) then
                type.assert.number(tEntry.id);

                if (tContext.objects[tEntry.id]) then
                    oRegistry.add(tContext.objects[tEntry.id]);
                else

                    -- Keep the registry waiting for this exact identity within this load only.
                    tContext.pending[tEntry.id] = tContext.pending[tEntry.id] or {};
                    table.insert(tContext.pending[tEntry.id], oRegistry);
                end
            else
                oRegistry.add(tEntry.value);
            end
        end

        return oRegistry;
    end,
});

--[[!
    @fqxn CoG.ItemSystem.ItemPersistence.registry
    @desc Preserves an inventory registry's callback through the general serializer.
    Registry objects shared by multiple inventory fields retain their identity.
!]]
function M.registry(oRegistry)

    -- Preserve absent registries on container kinds that do not use slot eligibility.
    if (oRegistry == nil or type.isnull(oRegistry)) then
        return oRegistry;
    end

    -- Reuse a wrapper for a shared registry so the serialized graph preserves its sharing.
    if (not tWrappers[oRegistry]) then
        tWrappers[oRegistry] = setmetatable({registry = oRegistry}, tRegistryMeta);
    end

    return tWrappers[oRegistry];
end

return M;
