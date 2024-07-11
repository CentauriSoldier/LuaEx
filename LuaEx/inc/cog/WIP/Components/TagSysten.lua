return class("TagSystem",
{--METAMETHODS

},
{--STATIC PUBLIC
    --TagSystem = function(stapub) end,
},
{--PRIVATE
    tags = {},
},
{--PROTECTED

},
{--PUBLIC
    TagSystem = function(this, cdat)

    end,
    addTag = function(this, cdat, sTag, bDisabled)
        local bRet  = false;
        local tTags = cdat.pri.tags;
        type.assert.string(sName, "%S+");
        sTag = sTag:upper();

        if (type(bDisabled) ~= "boolean") then
            bDisabled = false;
        end

        if (tTags[sTag] == nil) then
            tTags[sTag] = not bDisabled;
            bRet = true;
        end

        return bRet;
    end,
    isTagEnabled = function(this, cdat, sTag)
        local bRet  = false;

        if (type(sTag) == "string") then
            sTag = sTag:upper();
            bRet = cdat.pri.tags[sTag] ~= nil and cdat.pri.tags[sTag];
        end

        return bRet;
    end,
    removeTag = function(this, cdat, sTag)
        local bRet  = false;
        local tTags = cdat.pri.tags;
        type.assert.string(sName, "%S+");
        sTag = sTag:upper();

        if (tTags[sTag] ~= nil) then
            tTags[sTag] = nil;
            bRet = true;
        end

        return bRet;
    end,
    setTagEnabled = function(this, cdat, sTag, bFlag)
        local bRet  = false;
        local tTags = cdat.pri.tags;
        type.assert.string(sName, "%S+");
        sTag = sTag:upper();
        bFlag = type(bFlag) == "boolean" and bFlag or false;

        if (tTags[sTag] ~= nil) then
            tTags[sTag] = bFlag;
            bRet = true;
        end

        return bRet;
    end,
    hasTag = function(this, cdat, sTag)
        return type(sTag) == "string" and cdat.pri.tags[sTag:upper()] ~= nil;
    end,
},
Component,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
