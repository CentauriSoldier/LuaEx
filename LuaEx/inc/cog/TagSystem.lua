local class     = class;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local type      = type;

--[[!
@fqxn CoG.TagSystem
@desc A system for managing tags, including adding, removing, enabling,
and disabling them. It ensures tags are unique, case-insensitive, forced uppercase and sorted alphabetically.
!]]
return class("TagSystem",
{--METAMETHODS
    --[[!
    @fqxn CoG.TagSystem.Metamethods.__clone
    @desc Creates a copy of the TagSystem instance.
    @return TagSystem oTagSystem A new TagSystem instance identical to this one.
    !]]
    __clone = function(this, cdat)
        local oNew = TagSystem(); --TODO FINISH ALSO DO serialize/de
        return oNew;
    end,
    --[[!
    @fqxn CoG.TagSystem.Metamethods.__len
    @desc Returns the number of tags stored in the system.
    @return number nTags Number of tags in the system.
    !]]
    __len = function(this, cdat)
        return #cdat.pri.sortedTags;
    end,
    --[[!
    @fqxn CoG.TagSystem.Metamethods.__pairs
    @desc Iterates over all tags in sorted order.
    @return function fIterator An iterator function for tag pairs (tag, enabled status).
    !]]
    __pairs = function(this, cdat)
        local pri           = cdat.pri;
        local tTags         = pri.tags;
        local tSortedTags   = pri.sortedTags;
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
},
{--STATIC PUBLIC
},
--TagSystem = function(stapub) end,
{--PRIVATE
    tags            = {},
    sortedTags      = {},
},
{},--PROTECTED
{--PUBLIC
    TagSystem = function(this, cdat)
    end,
    --[[!
    @fqxn CoG.TagSystem.Methods.add
    @desc Adds a tag to the system if it does not exist.
    @param string sTag The tag to add.
    @param boolean|nil bDisabled A flag indicating if the tag should be disabled. If nil, it will be enabled by default.
    @return boolean bAdded True if the tag was added, false otherwise.
    !]]
    add = function(this, cdat, sTag, bDisabled)
        local bRet          = false;
        local pri           = cdat.pri;
        local tTags         = pri.tags;
        local tSortedTags   = pri.sortedTags;
        type.assert.string(sTag, "%S+");
        sTag = sTag:upper();

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
    @desc Adds multiple tags to the system at once.
    @param table tInputTags A numerically-indexed table of tags to add.
    @param boolean|nil bDisabled A flag indicating if the tags should be disabled. If nil, they will be enabled by default.
    @return number nTagsAdded The number of tags successfully added.
    !]]
    addMultiple = function(this, cdat, tInputTags, bDisabled)
        local nRet          = 0;
        local pri           = cdat.pri;
        local tTags         = pri.tags;
        local tSortedTags   = pri.sortedTags;
        type.assert.table(tInputTags, "number", "string", 1);

        for nIndex, sTag in pairs(tInputTags) do
            type.assert.string(sTag, "%S+");
            sTag = sTag:upper();

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
    @desc Checks if the system contains the specified tag.
    @param string sTag The tag to check.
    @return boolean bExists True if the tag exists, false otherwise.
    !]]
    contains = function(this, cdat, sTag)
        return type(sTag) == "string" and cdat.pri.tags[sTag:upper()] ~= nil;
    end,
    --[[!
    @fqxn CoG.TagSystem.Methods.isEnabled
    @desc Checks if the specified tag is enabled.
    @param string sTag The tag to check.
    @return boolean bEnabled True if the tag is enabled, false otherwise.
    !]]
    isEnabled = function(this, cdat, sTag)
        local bRet  = false;

        if (type(sTag) == "string") then
            sTag = sTag:upper();
            bRet = cdat.pri.tags[sTag] ~= nil and cdat.pri.tags[sTag];
        end

        return bRet;
    end,
    --[[!
    @fqxn CoG.TagSystem.Methods.eachTag
    @desc Iterates over each tag in the system. This is the same as the __pairs metamethod and exists for Lua 5.1 compatibility.
    @return function fIterator An iterator function for tag pairs (tag, enabled status).
    !]]
    eachTag = function(this, cdat)--lua 5.1 compat
        local pri           = cdat.pri;
        local tTags         = pri.tags;
        local tSortedTags   = pri.sortedTags;
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
    @desc Removes a tag from the system if it exists.
    @param string sTag The tag to remove.
    @return boolean bRemoved True if the tag was removed, false otherwise.
    !]]
    remove = function(this, cdat, sTag)
        local bRet          = false;
        local pri           = cdat.pri;
        local tTags         = pri.tags;
        local tSortedTags   = pri.sortedTags;
        type.assert.string(sTag, "%S+");
        sTag = sTag:upper();

        if (tTags[sTag] ~= nil) then
            tTags[sTag] = nil;

            for nExistingIndex, sExistingTag in pairs(tSortedTags) do

                if (sTag == sExistingTag) then
                    tSortedTags[nExistingIndex] = nil;
                    break;
                end

            end

            table.sort(tSortedTags);
            bRet = true;
        end

        return bRet;
    end,

    --TODO QUESTION, should this method return a table indicating which were removed? Same question for all multiple methods
    --[[!
    @fqxn CoG.TagSystem.Methods.removeMultiple
    @desc Removes multiple tags from the system at once.
    @param table tInputTags The table of tags to remove.
    @return number nRemoved The number of tags successfully removed.
    !]]
    removeMultiple = function(this, cdat, tInputTags)
        local nRet          = 0;
        local pri           = cdat.pri;
        local tAllTags      = pri.tags;
        local tSortedTags   = pri.sortedTags;
        type.assert.table(tInputTags, "number", "string", 1);

        for nIndex, sTag in pairs(tInputTags) do
            type.assert.string(sTag, "%S+");
            sTag = sTag:upper();

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
    @desc Sets the enabled/disabled status of a specific tag.
    @param string sTag The tag to update.
    @param boolean|nil bFlag The flag indicating the desired enabled status. If nil, the tag will be disabled.
    @return boolean bUpdated True if the tag's status was updated, false otherwise.
    !]]
    setEnabled = function(this, cdat, sTag, bFlag)
        local bRet  = false;
        local tTags = cdat.pri.tags;
        type.assert.string(sTag, "%S+");
        sTag = sTag:upper();
        bFlag = type(bFlag) == "boolean" and bFlag or false;

        if (tTags[sTag] ~= nil) then
            tTags[sTag] = bFlag;
            bRet = true;
        end

        return bRet;
    end,
    --[[!
    @fqxn CoG.TagSystem.Methods.setMultipleEnabled
    @desc Sets the enabled/disabled status of multiple tags.
    @param table tInputTags A numerically-indexed table of tags to update.
    @param boolean bFlag The flag indicating the desired enabled status.
    @return number nUpdated The number of tags whose status was updated.
    !]]
    setMultipleEnabled = function(this, cdat, tInputTags, bFlag)
        local nRet  = 0;
        local pri   = cdat.pri;
        local tTags = pri.tags;

        type.assert.table(tInputTags, "number", "string", 1);

        for nIndex, sTag in pairs(tInputTags) do
            type.assert.string(sTag, "%S+");
            sTag = sTag:upper();
            bFlag = type(bFlag) == "boolean" and bFlag or false;

            if (tTags[sTag] ~= nil) then
                tTags[sTag] = bFlag;
                nRet = nRet + 1;
            end

        end

        if (nRet > 0) then
            table.sort(pri.sortedTags);
        end

        return nRet;
    end,
},
nil,  --extending class
true, --if the class is final or limited
nil   --interface(s) (either nil, or interface(s))
);
