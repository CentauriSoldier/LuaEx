--LOCALIZATION
local rawtype   = rawtype;
local type      = type;
local table     = table;
local math      = math;
local ipairs    = ipairs;
local pairs     = pairs;

-- Configuration is assembled and locked before this factory loads.
local tConfigured = luaex.cog.config.StatusTracker;
local tScopes     = {};
local tPaths      = {};
local tExports    = {};

-- Named tables are categories; numeric entries are terminal effect names.
-- Only the recursion stack is marked, allowing shared config tables in different branches.
local function buildCategory(sCategory, tCategory, tStack)

    assert(type(tCategory) == "table", "StatusTracker categories must be ordinary tables.");
    assert(not tStack[tCategory], "StatusTracker configuration cannot contain cycles.");
    tStack[tCategory] = true;
    local tNames, tValues, tChildren, tSeen = {}, {}, {}, {};
    local nEffects = 0;

    for k, v in pairs(tCategory) do
        if (rawtype(k) == "number") then
            assert(k >= 1 and k % 1 == 0, "StatusTracker effects must form a dense list.");
            nEffects = nEffects + 1;
        else
            assert(rawtype(k) == "string" and k:match("^[A-Z][A-Z0-9_]*$"),
                   "StatusTracker category names must use UPPERCASE_WITH_UNDERSCORES.");
            assert(type(v) == "table", "StatusTracker named entries must be category tables.");
            tChildren[#tChildren + 1] = k;
        end
    end

    for nIndex = 1, nEffects do
        local sName = tCategory[nIndex];
        assert(rawtype(sName) == "string" and sName:match("^[A-Z][A-Z0-9_]*$"),
               "StatusTracker effects must be a dense list of UPPERCASE_WITH_UNDERSCORES names.");
        assert(not tSeen[sName], "Duplicate StatusTracker member name.");
        tSeen[sName] = true;
        tNames[#tNames + 1] = sName;
    end

    table.sort(tChildren);
    for _, sName in ipairs(tChildren) do
        assert(not tSeen[sName], "StatusTracker effect and category names cannot collide.");
        tSeen[sName] = true;
        tNames[#tNames + 1] = sName;
        tValues[#tNames] = buildCategory(sName, tCategory[sName], tStack);
    end

    assert(#tNames > 0, "StatusTracker categories must contain an effect or category.");
    tStack[tCategory] = nil;
    return enum(sCategory, tNames, tValues, true);
end

-- Index final enum objects after nesting, because nested definitions acquire new identities.
local function indexCategory(eCategory, sPath)

    local tScope = { path = sPath, names = {}, known = {}, effects = {}, absolute = {} };
    tScopes[eCategory] = tScope;
    tPaths[sPath] = tScope;

    for _, eMember in eCategory() do
        local sName = eMember.name;
        local sAbsolute = sPath.."."..sName;

        if (enum.isenum(eMember)) then
            local tChild = indexCategory(eMember, sAbsolute);
            for _, sChildName in ipairs(tChild.names) do
                local sRelative = sName.."."..sChildName;
                tScope.names[#tScope.names + 1] = sRelative;
                tScope.known[sRelative] = true;
            end
            for eEffect, sChildName in pairs(tChild.effects) do
                tScope.effects[eEffect] = sName.."."..sChildName;
            end
            for sEffectPath, sChildName in pairs(tChild.absolute) do
                tScope.absolute[sEffectPath] = sName.."."..sChildName;
            end
        else
            tScope.names[#tScope.names + 1] = sName;
            tScope.known[sName] = true;
            tScope.effects[eMember] = sName;
            tScope.absolute[sAbsolute] = sName;
        end
    end

    return tScope;
end

type.assert.custom(tConfigured, "table", "StatusTracker config must be a table.");
for sName, tCategory in pairs(tConfigured) do
    assert(rawtype(sName) == "string" and sName:match("^[A-Z][A-Z0-9_]*$"),
           "StatusTracker top-level names must be UPPERCASE_WITH_UNDERSCORES categories.");
    local eCategory = buildCategory(sName, tCategory, {});
    tExports[sName] = eCategory;
    indexCategory(eCategory, sName);
end

--[[!
@fqxn CoG.StatusTracker
@desc A lightweight configured-status tracker with private per-instance state.
Duration is nonnegative; active state is separate. Reaching zero deactivates only
statuses whose doesExpire flag is true. Cycling uses a unit chosen by the caller.
No inheritance, gameplay effects, stacking, resistance or RNG policy is imposed.
Methods use dot calls and accept descendant effect enums or exact scoped paths.
@ex
local oStatuses = StatusTracker(StatusTracker.ALL_THINGS.PEOPLE);
-- After defining ALL_THINGS.PEOPLE = {"HASTENED"} in the user CoG config:
oStatuses.activate("HASTENED", 5, true);
oStatuses.cycle(1);
!]]

--[[!
@fqxn CoG.StatusTracker.Helpers.validateDuration
@desc Requires a finite nonnegative duration or time step. Fractions are permitted.
@param number nDuration Duration expressed in the caller's chosen time unit.
@scope local
!]]
local function validateDuration(nDuration)

    -- Negative sentinels are unnecessary because doesExpire controls expiration.
    assert(rawtype(nDuration) == "number" and nDuration == nDuration
           and nDuration >= 0 and nDuration < math.huge,
           "Status duration must be a finite nonnegative number.");
end


--[[!
@fqxn CoG.StatusTracker.Helpers.validateState
@desc Validates complete serialized state before allocating live storage. Unknown names,
extra fields and inconsistent active expiring statuses are rejected.
@param table tState State containing a configured category scope path and relative status records.
@scope local
!]]
local function validateState(tState)

    -- Step 1: require the expected outer shape rather than trusting serialized data.
    type.assert.table(tState);
    type.assert.table(tState.statuses);
    local tScope = tPaths[tState.scope];
    assert(tScope, "Saved StatusTracker scope must name a configured category.");

    for sKey in pairs(tState) do
        assert(sKey == "statuses" or sKey == "scope", "Unknown StatusTracker state field.");
    end

    -- Step 2: validate every saved record and prohibit unknown configured names.
    for sName, tStatus in pairs(tState.statuses) do
        assert(rawtype(sName) == "string", "Saved status keys must be configured names.");
        assert(tScope.known[sName], "Saved status is outside the configured scope.");
        type.assert.table(tStatus);
        validateDuration(tStatus.duration);
        assert(rawtype(tStatus.active) == "boolean", "Status active state must be boolean.");
        assert(rawtype(tStatus.doesExpire) == "boolean", "Status expiration flag must be boolean.");

        for sKey in pairs(tStatus) do
            assert(sKey == "duration" or sKey == "active" or sKey == "doesExpire",
                   "Unknown StatusTracker status field.");
        end

        assert(not (tStatus.active and tStatus.doesExpire and tStatus.duration == 0),
               "An active expiring status must have a positive duration.");
    end

    return tScope;
end

--[[!
@fqxn CoG.StatusTracker.Methods.StatusTracker
@pulsarlua function StatusTracker
@desc Creates independent storage for descendants of a configured category. Initially inactive, duration zero,
and doesExpire true. The optional state argument is private to clone/deserialization.
@param enum eScope Configured category enum; terminal effect members are rejected.
@ret StatusTracker oStatuses New tracker.
!]]
local function build(tScope, tState)

    local tNames = tScope.names;
    -- Resolve exact descendant identities or scoped paths without walking the enum tree.
    local function fGetName(vEffect)

        local sName = tScope.effects[vEffect];
        if (not sName and rawtype(vEffect) == "string") then
            sName = tScope.known[vEffect] and vEffect or tScope.absolute[vEffect];
        end
        assert(sName, "Unknown StatusTracker effect or effect outside this scope.");
        return sName;
    end

    -- Step 1: validate restoration input before constructing any live records.
    if (tState ~= nil) then
        assert(validateState(tState) == tScope, "StatusTracker restoration scope mismatch.");
    end

    local tStatuses = {};

    -- Step 2: create this instance's records without sharing mutable status tables.
    for _, sName in ipairs(tNames) do
        local tSaved = tState and tState.statuses[sName];
        tStatuses[sName] = {
            duration    = tSaved and tSaved.duration or 0,
            active      = tSaved and tSaved.active or false,
            doesExpire  = tSaved == nil or tSaved.doesExpire,
        };
    end

    --[[!
    @fqxn CoG.StatusTracker.Helpers.getState
    @desc Copies all configured records for iteration, cloning and serialization.
    Does not expose this instance's private mutable status tables.
    @ret table tState Independent statuses map.
    @scope local
    !]]
    local function getState()

        local tCopy = { scope = tScope.path, statuses = {} };

        for _, sName in ipairs(tNames) do
            local tStatus = tStatuses[sName];
            tCopy.statuses[sName] = {
                duration    = tStatus.duration,
                active      = tStatus.active,
                doesExpire  = tStatus.doesExpire,
            };
        end

        return tCopy;
    end

    local StatusTrackerDecoy = {};
    local StatusTracker;
    StatusTracker = {
        --[[!
        @fqxn CoG.StatusTracker.Methods.activate
        @desc Activates a configured status with optional duration/expiration overrides.
        Omitted arguments retain current settings. An expiring zero-duration status remains
        inactive. Reapplication replaces supplied settings rather than stacking.
        @param string|enum vEffect Configured status.
        @param number|nil nDuration Optional finite nonnegative duration.
        @param boolean|nil bDoesExpire Optional expiration flag.
        @ret boolean bActive Resulting active state.
        !]]
        activate = function(vEffect, nDuration, bDoesExpire)

            -- Step 1: validate every argument before changing the record.
            local sName = fGetName(vEffect);

            if (nDuration ~= nil) then
                validateDuration(nDuration);
            end

            assert(bDoesExpire == nil or rawtype(bDoesExpire) == "boolean",
                   "Status expiration flag must be boolean.");

            -- Step 2: apply only supplied settings, preserving explicit false/zero.
            local tStatus = tStatuses[sName];

            if (nDuration ~= nil) then
                tStatus.duration = nDuration;
            end

            if (bDoesExpire ~= nil) then
                tStatus.doesExpire = bDoesExpire;
            end

            -- Step 3: indefinite statuses may remain active even at duration zero.
            tStatus.active = not tStatus.doesExpire or tStatus.duration > 0;
            return tStatus.active;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.deactivate
        @desc Explicitly stops a status, including one that does not expire. Retains its settings.
        @param string|enum vEffect Configured status.
        @ret boolean bChanged True if it was active before this call.
        !]]
        deactivate = function(vEffect)

            local tStatus = tStatuses[fGetName(vEffect)];
            local bRet = tStatus.active;
            tStatus.active = false;
            return bRet;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.isActive
        @desc Reports explicit active state, independently of an indefinite status's duration.
        @param string|enum vEffect Configured status.
        @ret boolean bActive Current active flag.
        !]]
        isActive = function(vEffect)

            return tStatuses[fGetName(vEffect)].active;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.getDuration
        @desc Returns remaining duration in the caller's time unit.
        @param string|enum vEffect Configured status.
        @ret number nDuration Finite nonnegative duration.
        !]]
        getDuration = function(vEffect)

            return tStatuses[fGetName(vEffect)].duration;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.setDuration
        @desc Replaces duration without activating an inactive status. Zero deactivates an
        expiring status, but leaves a non-expiring status's active state unchanged.
        @param string|enum vEffect Configured status.
        @param number nDuration Finite nonnegative remaining duration.
        @ret StatusTracker oStatuses This tracker for chaining.
        !]]
        setDuration = function(vEffect, nDuration)

            -- Validate before committing, then reconcile expiration only.
            local tStatus = tStatuses[fGetName(vEffect)];
            validateDuration(nDuration);
            tStatus.duration = nDuration;

            if (tStatus.doesExpire and nDuration == 0) then
                tStatus.active = false;
            end

            return StatusTrackerDecoy;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.adjustDuration
        @desc Adds a finite signed delta, clamping at zero. Never converts underflow to infinity.
        Overflow is rejected before mutation; adjustment does not activate an inactive status.
        @param string|enum vEffect Configured status.
        @param number nDelta Finite signed duration change.
        @ret StatusTracker oStatuses This tracker for chaining.
        !]]
        adjustDuration = function(vEffect, nDelta)

            local tStatus = tStatuses[fGetName(vEffect)];
            assert(rawtype(nDelta) == "number" and nDelta == nDelta and math.abs(nDelta) < math.huge,
                   "Duration adjustment must be a finite number.");
            local nDuration = math.max(0, tStatus.duration + nDelta);
            return StatusTracker.setDuration(vEffect, nDuration);
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.doesExpire
        @desc Reports whether reaching zero automatically deactivates this status.
        @param string|enum vEffect Configured status.
        @ret boolean bDoesExpire Current expiration policy.
        !]]
        doesExpire = function(vEffect)

            return tStatuses[fGetName(vEffect)].doesExpire;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.setDoesExpire
        @desc Changes expiration policy. Enabling expiration at zero immediately deactivates.
        Disabling expiration does not automatically activate an inactive status.
        @param string|enum vEffect Configured status.
        @param boolean bFlag Whether reaching zero should stop the status.
        @ret StatusTracker oStatuses This tracker for chaining.
        !]]
        setDoesExpire = function(vEffect, bFlag)

            local tStatus = tStatuses[fGetName(vEffect)];
            assert(rawtype(bFlag) == "boolean", "Status expiration flag must be boolean.");
            tStatus.doesExpire = bFlag;

            if (bFlag and tStatus.duration == 0) then
                tStatus.active = false;
            end

            return StatusTrackerDecoy;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.cycle
        @desc Advances active timers by the caller's chosen amount. Durations clamp at zero;
        only statuses with doesExpire=true deactivate there. Inactive timers do not advance.
        @param number|nil nStep Finite nonnegative step; defaults to one.
        @ret number nExpired Count deactivated by this cycle.
        !]]
        cycle = function(nStep)

            -- Step 1: reject invalid time steps before modifying any status.
            nStep = nStep == nil and 1 or nStep;
            validateDuration(nStep);
            local nRet = 0;

            -- Step 2: update active records in configured order, never below zero.
            for _, sName in ipairs(tNames) do
                local tStatus = tStatuses[sName];

                if (tStatus.active) then
                    tStatus.duration = math.max(0, tStatus.duration - nStep);

                    if (tStatus.doesExpire and tStatus.duration == 0) then
                        tStatus.active = false;
                        nRet = nRet + 1;
                    end
                end
            end

            return nRet;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.eachStatus
        @desc Iterates scope-relative paths and copied records in deterministic configured order.
        Includes inactive statuses. Later tracker changes do not alter the snapshot.
        @ret function fIterator Iterator returning name, state record.
        !]]
        eachStatus = function()

            local tSnapshot = getState().statuses;
            local nIndex = 0;

            return function()

                nIndex = nIndex + 1;
                local sName = tNames[nIndex];

                if (sName) then
                    return sName, tSnapshot[sName];
                end
            end;
        end,

        --[[!
        @fqxn CoG.StatusTracker.Methods.clear
        @desc Deactivates all statuses and clears durations, retaining expiration settings.
        @ret number nCleared Number of previously active statuses.
        !]]
        clear = function()

            local nRet = 0;

            for _, sName in ipairs(tNames) do
                local tStatus = tStatuses[sName];

                if (tStatus.active) then
                    nRet = nRet + 1;
                end

                tStatus.active = false;
                tStatus.duration = 0;
            end

            return nRet;
        end,
    };

    local StatusTrackerMeta = {
        __type = "StatusTracker",
        __index = function(t, k)

            return StatusTracker[k] or nil;
        end,
        __newindex = function(t, k, v)

            error("StatusTracker members cannot be assigned directly. Use its methods.", 2);
        end,
        -- Length counts active statuses; iteration includes all configured statuses.
        __len = function()

            local nRet = 0;

            for _, sName in ipairs(tNames) do
                if (tStatuses[sName].active) then
                    nRet = nRet + 1;
                end
            end

            return nRet;
        end,
        __pairs = function()

            return StatusTracker.eachStatus();
        end,
        --[[!
        @fqxn CoG.StatusTracker.Metamethods.__serialize
        @desc Returns fresh plain state containing the selected scope path and descendant status records.
        @ret table tState Duration, active and doesExpire data by configured name.
        !]]
        __serialize = getState,
        --[[!
        @fqxn CoG.StatusTracker.Metamethods.__clone
        @desc Creates an independent tracker preserving active state, timers and flags.
        @ret StatusTracker oCopy Independent clone.
        !]]
        __clone = function()

            return build(tScope, getState());
        end,
    };

    setmetatable(StatusTrackerDecoy, StatusTrackerMeta);
    return StatusTrackerDecoy;
end

local StatusTrackerFactory = {
    --[[!
    @fqxn CoG.StatusTracker.Methods.deserialize
    @desc Restores independent private state using the current configured status names.
    @param table tState Plain state produced by __serialize.
    @ret StatusTracker oStatuses Restored tracker.
    !]]
    deserialize = function(tState)

        return build(validateState(tState), tState);
    end,
};

local StatusTrackerFactoryMeta = {
    __call = function(this, ...)

        assert(select("#", ...) == 1, "StatusTracker requires one configured category enum.");
        local tScope = tScopes[(...)];
        assert(tScope, "StatusTracker scope must be a configured category enum, not an effect.");
        return build(tScope);
    end,
    __index = function(t, k)

        return StatusTrackerFactory[k] or tExports[k];
    end,
    __newindex = function(t, k, v)

        error("StatusTracker factory members cannot be assigned directly.", 2);
    end,
};
local StatusTrackerFactoryDecoy = {};
StatusTrackerFactoryMeta.__type = "StatusTrackerFactory";
StatusTrackerFactoryMeta.__clone = function() return StatusTrackerFactoryDecoy; end;
StatusTrackerFactoryMeta.__serialize = function() return "StatusTracker"; end;
StatusTrackerFactoryMeta.__metatable = table.readonly({
    __type = StatusTrackerFactoryMeta.__type,
    __call = StatusTrackerFactoryMeta.__call,
    __clone = StatusTrackerFactoryMeta.__clone,
    __serialize = StatusTrackerFactoryMeta.__serialize,
});

setmetatable(StatusTrackerFactoryDecoy, StatusTrackerFactoryMeta);
require("LuaEx.lib.serializer").registerFactory(StatusTrackerFactoryDecoy, {name = "StatusTracker", types = {"StatusTracker"}});
return StatusTrackerFactoryDecoy;
