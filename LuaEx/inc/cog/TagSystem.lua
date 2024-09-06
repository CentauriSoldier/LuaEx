local class     = class;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local type      = type;

--[[!
    @fqxn LuaEx.CoG.Classes.CoG
    @desc <p>This is the base class for all CoG classes. The three child classes under CoG are:</p>
    <ul>
        <li><a href="#LuaEx.CoG.Actor"></a>Actor</li>
        <li><a href="#LuaEx.CoG.Entity"></a>Entity</li>
        <li><a href="#LuaEx.CoG.Object"></a>Object</li>
    </ul>
    <b>Note</b>: this class is limited and may be subclassed only by the classes listed above.
!]]
return class("TagSystem",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = TagSystem();
        return oNew;
    end,

    __len = function(this, cdat)
        return #cdat.pri.sortedTags;
    end,

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
    contains = function(this, cdat, sTag)
        return type(sTag) == "string" and cdat.pri.tags[sTag:upper()] ~= nil;
    end,
    isEnabled = function(this, cdat, sTag)
        local bRet  = false;

        if (type(sTag) == "string") then
            sTag = sTag:upper();
            bRet = cdat.pri.tags[sTag] ~= nil and cdat.pri.tags[sTag];
        end

        return bRet;
    end,
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
