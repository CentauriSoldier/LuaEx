--[[!
@fqxn CoG.TagSystem
@desc A lightweight system for managing unique, case-insensitive tags. Leading and
trailing whitespace is trimmed, tags are stored uppercase, and iteration is
alphabetical. Disabled tags remain members and count toward length and equality.
Methods use dot calls: oTags.add("GHOST"). Instance state is private to build.
@ex
local oTags = TagSystem();
oTags.addMultiple({" Ghost ", "Undead"});
!]]
local function normalizeTag(sTag)

    -- Normalize before every mutation so spelling variants share one stored key.
    type.assert.string(sTag, "%S+");
    return sTag:match("^%s*(.-)%s*$"):upper();
end

-- Validate the complete batch before mutating any instance; empty batches are valid.
local function normalizeTags(tInputTags)

    type.assert.table(tInputTags, "number", "string");
    local tNormalized = {};

    for nIndex, sTag in pairs(tInputTags) do
        tNormalized[#tNormalized + 1] = normalizeTag(sTag);
    end

    return tNormalized;
end

--[[!
@fqxn CoG.TagSystem.Methods.TagSystem
@pulsarlua function TagSystem
@desc Creates an empty TagSystem with independent private storage.
@return TagSystem oTags The new object.
!]]
local function build()

    local tTags       = {};
    local tSortedTags = {};

    local TagSystem;
    TagSystem = {
        --[[!
        @fqxn CoG.TagSystem.Methods.add
        @pulsarlua function TagSystem.add
        @desc Adds a tag to the system if it does not exist.
        @param string sTag The tag to add.
        @param boolean|nil bDisabled A flag indicating if the tag should be disabled. If nil, it will be enabled by default.
        @return boolean bAdded True if the tag was added, false otherwise.
        !]]
        add = function(sTag, bDisabled)

            local bRet          = false;
            type.assert.string(sTag, "%S+");
            sTag = normalizeTag(sTag);

            if (type(bDisabled) ~= "boolean") then
                bDisabled = false;
            end

            if (tTags[sTag] == nil) then
                tTags[sTag] = not bDisabled;
                tSortedTags[#tSortedTags + 1] = sTag;
                table.sort(tSortedTags);
                bRet = true;
            end

            return bRet;
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.addMultiple
        @pulsarlua function TagSystem.addMultiple
        @desc Adds multiple tags to the system at once.
        @param table tInputTags A numerically-indexed table of tags to add.
        @param boolean|nil bDisabled A flag indicating if the tags should be disabled. If nil, they will be enabled by default.
        @return number nTagsAdded The number of tags successfully added.
        !]]
        addMultiple = function(tInputTags, bDisabled)

            local nRet          = 0;
            tInputTags = normalizeTags(tInputTags);

            for nIndex, sTag in pairs(tInputTags) do
                type.assert.string(sTag, "%S+");
                sTag = normalizeTag(sTag);

                if (type(bDisabled) ~= "boolean") then
                    bDisabled = false;
                end

                if (tTags[sTag] == nil) then
                    tTags[sTag] = not bDisabled;
                    tSortedTags[#tSortedTags + 1] = sTag;
                    nRet = nRet + 1;
                end

            end

            if (nRet > 0) then
                table.sort(tSortedTags);
            end

            return nRet;
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.contains
        @pulsarlua function TagSystem.contains
        @desc Checks if the system contains the specified tag. Blank or non-string inputs return false.
        @param string sTag The tag to check.
        @return boolean bExists True if the tag exists, false otherwise.
        !]]
        contains = function(sTag)

            return type(sTag) == "string" and tTags[sTag:match("^%s*(.-)%s*$"):upper()] ~= nil;
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.isEnabled
        @pulsarlua function TagSystem.isEnabled
        @desc Checks if the specified tag is enabled. Blank or non-string inputs return false.
        @param string sTag The tag to check.
        @return boolean bEnabled True if the tag is enabled, false otherwise.
        !]]
        isEnabled = function(sTag)

            local bRet  = false;

            if (type(sTag) == "string" and sTag:find("%S")) then
                sTag = normalizeTag(sTag);
                bRet = tTags[sTag] ~= nil and tTags[sTag];
            end

            return bRet;
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.hasSameTags
        @pulsarlua function TagSystem.hasSameTags
        @desc Checks exact tag membership without considering enabled status. Tag order does not affect the result.
        @param TagSystem oOther The tag system to compare.
        @return boolean bSame True if both systems contain exactly the same tags.
        !]]
        hasSameTags = function(oOther)

            type.assert.custom(oOther, "TagSystem");
            local bRet = #tSortedTags == #oOther;

            if (bRet) then

                for sTag, bEnabled in TagSystem.eachTag() do

                    if not (oOther.contains(sTag)) then
                        bRet = false;
                        break;
                    end
                end
            end

            return bRet;
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.eachTag
        @pulsarlua function TagSystem.eachTag
        @desc Iterates over each tag in the system. This is the same as the __pairs metamethod and exists for Lua 5.1 compatibility.
        @return function fIterator An iterator function for tag pairs (tag, enabled status).
        !]]
        eachTag = function()--lua 5.1 compat

            -- Walk the sorted list, then read flags from the membership table.
            -- Do not add or remove tags while an iterator is in progress.
            local nMax          = #tSortedTags;
            local nIndex        = 0;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= nMax) then
                    local sTag = tSortedTags[nIndex];
                    return sTag, tTags[sTag];
                end
            end
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.remove
        @pulsarlua function TagSystem.remove
        @desc Removes a tag from the system if it exists.
        @param string sTag The tag to remove.
        @return boolean bRemoved True if the tag was removed, false otherwise.
        !]]
        remove = function(sTag)

            local bRet          = false;
            type.assert.string(sTag, "%S+");
            sTag = normalizeTag(sTag);

            if (tTags[sTag] ~= nil) then
                tTags[sTag] = nil;

                for nExistingIndex, sExistingTag in pairs(tSortedTags) do

                    if (sTag == sExistingTag) then
                        table.remove(tSortedTags, nExistingIndex);
                        break;
                    end

                end

                table.sort(tSortedTags);
                bRet = true;
            end

            return bRet;
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.removeMultiple
        @pulsarlua function TagSystem.removeMultiple
        @desc Removes multiple tags from the system at once.
        @param table tInputTags The table of tags to remove.
        @return number nRemoved The number of tags successfully removed.
        !]]
        removeMultiple = function(tInputTags)

            local nRet          = 0;
            local tAllTags      = tTags;
            tInputTags = normalizeTags(tInputTags);

            for nIndex, sTag in pairs(tInputTags) do
                type.assert.string(sTag, "%S+");
                sTag = normalizeTag(sTag);

                if (tAllTags[sTag] ~= nil) then
                    tAllTags[sTag] = nil;
                    nRet = nRet + 1;

                    for nExistingIndex, sExistingTag in pairs(tSortedTags) do

                        if (sTag == sExistingTag) then
                            table.remove(tSortedTags, nExistingIndex);
                            break;
                        end

                    end

                end

            end

            if (nRet > 0) then
                table.sort(tSortedTags);
            end

            return nRet;
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.setEnabled
        @pulsarlua function TagSystem.setEnabled
        @desc Sets the enabled/disabled status of a specific tag.
        @param string sTag The tag to update.
        @param boolean|nil bFlag The flag indicating the desired enabled status. If nil, the tag will be disabled.
        @return boolean bUpdated True if the tag's status was updated, false otherwise.
        !]]
        setEnabled = function(sTag, bFlag)

            local bRet  = false;
            
            type.assert.string(sTag, "%S+");
            sTag = normalizeTag(sTag);
            bFlag = type(bFlag) == "boolean" and bFlag or false;

            if (tTags[sTag] ~= nil) then
                tTags[sTag] = bFlag;
                bRet = true;
            end

            return bRet;
        end,

        --[[!
        @fqxn CoG.TagSystem.Methods.setMultipleEnabled
        @pulsarlua function TagSystem.setMultipleEnabled
        @desc Sets the enabled/disabled status of multiple tags.
        @param table tInputTags A numerically-indexed table of tags to update.
        @param boolean bFlag The flag indicating the desired enabled status.
        @return number nUpdated The number of distinct existing tags updated, including tags already set to the requested status.
        !]]
        setMultipleEnabled = function(tInputTags, bFlag)

            local nRet  = 0;
            local tSeen = {};

            tInputTags = normalizeTags(tInputTags);

            for nIndex, sTag in pairs(tInputTags) do
                type.assert.string(sTag, "%S+");
                sTag = normalizeTag(sTag);
                bFlag = type(bFlag) == "boolean" and bFlag or false;

                if (tTags[sTag] ~= nil and not tSeen[sTag]) then
                    tTags[sTag] = bFlag;
                    tSeen[sTag] = true;
                    nRet = nRet + 1;
                end

            end

            if (nRet > 0) then
                table.sort(tSortedTags);
            end

            return nRet;
        end,

    };

    local TagSystemDecoy = {};
    local TagSystemMeta = {
        __type = "TagSystem",
        __index = function(t, k)

            return TagSystem[k] or nil;
        end,
        __newindex = function(t, k, v)

            error("TagSystem members cannot be assigned directly. Use its methods.", 2);
        end,
        -- Includes disabled tags, matching contains() and hasSameTags().
        __len = function()

            return #tSortedTags;
        end,
        __pairs = function()

            return TagSystem.eachTag();
        end,

        --[[!
        @fqxn CoG.TagSystem.Metamethods.__serialize
        @desc Returns a fresh state table preserving tags and enabled flags for global serialize().
        @return table tState State containing a tags table mapping names to enabled flags.
        !]]
        __serialize = function()

            local tState = {tags = {}};

            for sTag, bEnabled in TagSystem.eachTag() do
                tState.tags[sTag] = bEnabled;
            end

            return tState;
        end,

        --[[!
        @fqxn CoG.TagSystem.Metamethods.__clone
        @desc Creates an independent copy preserving tags and enabled flags for global clone().
        @return TagSystem oCopy The copied object.
        !]]
        __clone = function()

            local oCopy = build();

            -- add() expects a disabled flag, the inverse of the stored enabled flag.

            for sTag, bEnabled in TagSystem.eachTag() do
                oCopy.add(sTag, not bEnabled);
            end

            return oCopy;
        end,
    };

    setmetatable(TagSystemDecoy, TagSystemMeta);
    return TagSystemDecoy;
end

local TagSystemFactory = {
    --[[!
    @fqxn CoG.TagSystem.Methods.deserialize
    @pulsarlua function TagSystem.deserialize
    @desc Restores an independent TagSystem from a state table produced by __serialize.
    @param table tState State containing a tags table mapping normalized names to enabled flags.
    @return TagSystem oTags The restored object.
    !]]
    deserialize = function(tState)

        type.assert.table(tState);
        type.assert.table(tState.tags, "string", "boolean");
        local tSeen = {};
        local oTags = build();

        for sTag, bEnabled in pairs(tState.tags) do
            local sNormalized = normalizeTag(sTag);
            assert(not tSeen[sNormalized], "Duplicate normalized tag in TagSystem state.");
            tSeen[sNormalized] = true;
            oTags.add(sNormalized, not bEnabled);
        end

        return oTags;
    end,
};

local TagSystemFactoryMeta = {
    __call = build,
    __index = function(t, k)

        return TagSystemFactory[k] or nil;
    end,
    __newindex = function(t, k, v)

        error("TagSystem factory members cannot be assigned directly.", 2);
    end,
};
local TagSystemFactoryDecoy = {};
TagSystemFactoryMeta.__type = "TagSystemFactory";
TagSystemFactoryMeta.__clone = function() return TagSystemFactoryDecoy; end;
TagSystemFactoryMeta.__serialize = function() return "TagSystem"; end;
TagSystemFactoryMeta.__metatable = table.readonly({
    __type = TagSystemFactoryMeta.__type,
    __call = TagSystemFactoryMeta.__call,
    __clone = TagSystemFactoryMeta.__clone,
    __serialize = TagSystemFactoryMeta.__serialize,
});

setmetatable(TagSystemFactoryDecoy, TagSystemFactoryMeta);
require("LuaEx.lib.serializer").registerFactory(TagSystemFactoryDecoy, {name = "TagSystem", types = {"TagSystem"}});
return TagSystemFactoryDecoy;
