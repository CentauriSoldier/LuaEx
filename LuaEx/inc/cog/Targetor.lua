--[[!
@fqxn CoG.Targetor
@desc A lightweight targeting factory with Types, Targetable, Immunities, and
Interdictors category objects. Configure categories using flat, nonempty tables
of target types. Each vararg table is one TargetGroup. Strings are validated,
trimmed, uppercased, deduplicated, and sorted. Groups match exactly regardless
of order. Public checks accept Targetor objects. Restrictions always win.
The group {"*"} means every group outside Types and cannot coexist with other
groups in its category. Empty categories mean none.
@ex
local oGhost = Targetor();
oGhost.Types.add({"GHOST", "UNDEAD"});
local oHunter = Targetor();
oHunter.Targetable.add({"UNDEAD", "GHOST"}, {"BEAST"});
assert(oHunter.canTarget(oGhost));
!]]

local function normalizeGroup(tInput, sCategory)

    -- Sort a new copy rather than the caller's table. Identity includes every
    -- normalized member; no subset or partial group match is permitted.
    type.assert.table(tInput, "number", "string", 1);
    local tGroup = {};
    local tSeen = {};

    for nIndex, sType in pairs(tInput) do
        assert(nIndex >= 1 and nIndex % 1 == 0, "TargetGroup indices must be positive integers.");
        type.assert.string(sType, "%S+");
        sType = sType:match("^%s*(.-)%s*$"):upper();

        if not (tSeen[sType]) then
            tSeen[sType] = true;
            tGroup[#tGroup + 1] = sType;
        end
    end
    assert(not tSeen["*"] or (#tGroup == 1 and sCategory ~= "Types"),
           "The wildcard must be a standalone group outside Types.");
    table.sort(tGroup);
    return tGroup;
end

local function groupsEqual(tLeft, tRight)

    local bEqual = #tLeft == #tRight;

    if (bEqual) then

        for nIndex, sType in ipairs(tLeft) do

            if (sType ~= tRight[nIndex]) then
                bEqual = false;
                break;
            end
        end
    end

    return bEqual;
end

local function findGroup(tGroups, tGroup)

    local nFound;

    for nIndex, tExisting in ipairs(tGroups) do

        if (groupsEqual(tExisting, tGroup)) then
            nFound = nIndex;
            break;
        end
    end

    return nFound;
end

local function copyGroups(tGroups)

    local tCopy = {};

    for nIndex, tGroup in ipairs(tGroups) do
        local tNewGroup = {};

        for nType, sType in ipairs(tGroup) do
            tNewGroup[nType] = sType;
        end
        tCopy[nIndex] = tNewGroup;
    end

    return tCopy;
end

-- Keep explicit nil arguments visible so they fail validation.
local function normalizeBatch(sCategory, ...)

    local tGroups = {};

    for nIndex = 1, select("#", ...) do
        local tGroup = normalizeGroup(select(nIndex, ...), sCategory);

        if not (findGroup(tGroups, tGroup)) then
            tGroups[#tGroups + 1] = tGroup;
        end
    end

    return tGroups;
end

local function validateWildcard(tGroups)

    local bWildcard = false;

    for _, tGroup in ipairs(tGroups) do
        bWildcard = bWildcard or tGroup[1] == "*";
    end
    assert(not bWildcard or #tGroups == 1, "A wildcard category cannot contain other groups.");
end

--[[!
@fqxn CoG.Targetor.Methods.Targetor
@pulsarlua function Targetor
@desc Creates an empty Targetor. Populate its categories with add or set.
@return Targetor oTargetor The new object.
!]]
local function build(tState)

    local tCategories = {Types = {}, Targetable = {}, Immunities = {}, Interdictors = {}};
    local Targetor = {};
    local TargetorDecoy = {};

    for sCategory in pairs(tCategories) do
        local Category = {};

        --[[!
        @fqxn CoG.Targetor.Categories.Methods.add
        @desc Adds one or more flat TargetGroup tables. Duplicate groups are ignored.
        The entire batch is validated before mutation. Zero arguments changes nothing.
        @param table ... Each argument is one nonempty TargetGroup.
        @return number nAdded Number of distinct groups added.
        !]]
        Category.add = function(...)

            local tInput = normalizeBatch(sCategory, ...);
            -- Stage the complete result so a wildcard conflict leaves storage intact.
            local tNew = copyGroups(tCategories[sCategory]);
            local nAdded = 0;

            for _, tGroup in ipairs(tInput) do

                if not (findGroup(tNew, tGroup)) then
                    tNew[#tNew + 1] = tGroup;
                    nAdded = nAdded + 1;
                end
            end
            validateWildcard(tNew);
            tCategories[sCategory] = tNew;
            return nAdded;
        end;

        --[[!
        @fqxn CoG.Targetor.Categories.Methods.set
        @desc Replaces the category with the supplied TargetGroups after validating
        the complete batch. Zero arguments clears it.
        @param table ... Each argument is one nonempty TargetGroup.
        !]]
        Category.set = function(...)

            local tNew = normalizeBatch(sCategory, ...);
            validateWildcard(tNew);
            tCategories[sCategory] = tNew;
        end;

        --[[!
        @fqxn CoG.Targetor.Categories.Methods.remove
        @desc Removes exact groups after validating the entire batch. Removing {"*"}
        removes a wildcard; removing an ordinary group does not alter a wildcard.
        @param table ... Each argument is one nonempty TargetGroup.
        @return number nRemoved Number of distinct groups removed.
        !]]
        Category.remove = function(...)

            local tInput = normalizeBatch(sCategory, ...);
            local tNew = copyGroups(tCategories[sCategory]);
            local nRemoved = 0;

            for _, tGroup in ipairs(tInput) do
                local nIndex = findGroup(tNew, tGroup);

                if (nIndex) then
                    table.remove(tNew, nIndex);
                    nRemoved = nRemoved + 1;
                end
            end
            tCategories[sCategory] = tNew;
            return nRemoved;
        end;

        --[[!
        @fqxn CoG.Targetor.Categories.Methods.get
        @desc Returns independent copies of the stored TargetGroups for inspection.
        @return table tGroups The list of groups, or an empty table.
        !]]
        Category.get = function()

            -- Copies prevent callers from bypassing validation through returned data.
            return copyGroups(tCategories[sCategory]);
        end;

        --[[!
        @fqxn CoG.Targetor.Categories.Methods.clear
        @desc Removes all groups from this category.
        !]]
        Category.clear = function()

            tCategories[sCategory] = {};
        end;

        --[[!
        @fqxn CoG.Targetor.Categories.Methods.has
        @desc Checks whether any of the other Targetor's Types groups matches this
        category. A wildcard matches every object, including an untyped one.
        This is a category match only; canTarget evaluates all restrictions.
        @param Targetor oOther The object whose Types are checked.
        @return boolean bMatches Whether there is a match.
        !]]
        Category.has = function(oOther)

            type.assert.custom(oOther, "Targetor");
            local tGroups = tCategories[sCategory];
            local bMatches = #tGroups == 1 and tGroups[1][1] == "*";
            -- Category matching is separate from the final permission decision.

            if not (bMatches) then
                local tTypes = oOther.Types.get();

                for _, tGroup in ipairs(tTypes) do

                    if (findGroup(tGroups, tGroup)) then
                        bMatches = true;
                        break;
                    end
                end
            end

            return bMatches;
        end;

        local CategoryDecoy = {};
        local CategoryMeta = {
            __index = function(t, k)

                return Category[k] or nil;
            end,
            __newindex = function(t, k, v)

                error("Targetor categories must be changed through their methods.", 2);
            end,
            __len = function()

                return #tCategories[sCategory];
            end,
        };
        setmetatable(CategoryDecoy, CategoryMeta);
        Targetor[sCategory] = CategoryDecoy;
    end

    --[[!
    @fqxn CoG.Targetor.Methods.isImmuneTo
    @pulsarlua function Targetor.isImmuneTo
    @desc Checks whether this object's Immunities match the source's Types.
    @param Targetor oSource The source object.
    @return boolean bImmune Whether this object is immune to the source.
    !]]
    Targetor.isImmuneTo = function(oSource)

        return Targetor.Immunities.has(oSource);
    end;

    --[[!
    @fqxn CoG.Targetor.Methods.isInterdictedBy
    @pulsarlua function Targetor.isInterdictedBy
    @desc Checks whether this object's Interdictors match the candidate's Types.
    @param Targetor oCandidate The potential target.
    @return boolean bBlocked Whether this object's interdictors block the candidate.
    !]]
    Targetor.isInterdictedBy = function(oCandidate)

        return Targetor.Interdictors.has(oCandidate);
    end;

    --[[!
    @fqxn CoG.Targetor.Methods.canTarget
    @pulsarlua function Targetor.canTarget
    @desc Requires a typed candidate matching Targetable, no candidate immunity to
    this source, and no source interdictor against the candidate. Restrictions win.
    @param Targetor oCandidate The potential target.
    @return boolean bAllowed Whether this source can target the candidate.
    !]]
    Targetor.canTarget = function(oCandidate)

        type.assert.custom(oCandidate, "Targetor");
        local bAllowed = #oCandidate.Types > 0 and Targetor.Targetable.has(oCandidate);
        -- Immunities belongs to the candidate; Interdictors belongs to this source.

        if (bAllowed) then
            bAllowed = not oCandidate.Immunities.has(TargetorDecoy);
        end

        if (bAllowed) then
            bAllowed = not Targetor.isInterdictedBy(oCandidate);
        end

        return bAllowed;
    end;

    -- Nested lists belong only to serialized storage, never public entry input.

    if (tState ~= nil) then
        type.assert.table(tState, "string", "table");

        for sCategory, tGroups in pairs(tState) do
            assert(tCategories[sCategory] ~= nil, "Unknown Targetor state category.");
            type.assert.table(tGroups, "number", "table");
            local tNew = {};

            for nIndex, tGroup in pairs(tGroups) do
                assert(nIndex >= 1 and nIndex % 1 == 0, "State indices must be positive integers.");
                tNew[#tNew + 1] = normalizeGroup(tGroup, sCategory);
            end
            Targetor[sCategory].set(table.unpack(tNew));
        end
    end

    local function getState()

        local tCopy = {};

        for sCategory, tGroups in pairs(tCategories) do
            tCopy[sCategory] = copyGroups(tGroups);
        end

        return tCopy;
    end

    local TargetorMeta = {
        __type = "Targetor",
        __index = function(t, k)

            return Targetor[k] or nil;
        end,
        __newindex = function(t, k, v)

            error("Targetor members cannot be assigned directly.", 2);
        end,

        --[[!
        @fqxn CoG.Targetor.Metamethods.__serialize
        @desc Returns independent plain category state for global serialize().
        @return table tState The category state.
        !]]
        __serialize = getState,
        --[[!
        @fqxn CoG.Targetor.Metamethods.__clone
        @desc Creates an independent copy with all category groups preserved.
        @return Targetor oCopy The copied object.
        !]]
        __clone = function()

            return build(getState());
        end,
    };
    setmetatable(TargetorDecoy, TargetorMeta);
    return TargetorDecoy;
end

local TargetorFactory = {
    --[[!
    @fqxn CoG.Targetor.Methods.deserialize
    @pulsarlua function Targetor.deserialize
    @desc Restores independent storage from the state produced by __serialize.
    @param table tState The serialized category state.
    @return Targetor oTargetor The restored object.
    !]]
    deserialize = function(tState)

        type.assert.table(tState, "string", "table");
        return build(tState);
    end,
};
local TargetorFactoryMeta = {
    __call = function(this, ...)

        assert(select("#", ...) == 0, "Use Targetor() and configure its categories with flat TargetGroup tables.");
        return build();
    end,
    __index = function(t, k)

        return TargetorFactory[k] or nil;
    end,
    __newindex = function(t, k, v)

        error("Targetor factory members cannot be assigned directly.", 2);
    end,
};
local TargetorFactoryDecoy = {};
TargetorFactoryMeta.__type = "TargetorFactory";
TargetorFactoryMeta.__clone = function() return TargetorFactoryDecoy; end;
TargetorFactoryMeta.__serialize = function() return "Targetor"; end;
TargetorFactoryMeta.__metatable = table.readonly({
    __type = TargetorFactoryMeta.__type,
    __call = TargetorFactoryMeta.__call,
    __clone = TargetorFactoryMeta.__clone,
    __serialize = TargetorFactoryMeta.__serialize,
});
setmetatable(TargetorFactoryDecoy, TargetorFactoryMeta);
require("LuaEx.lib.serializer").registerFactory(TargetorFactoryDecoy, {name = "Targetor", types = {"Targetor"}});
return TargetorFactoryDecoy;
