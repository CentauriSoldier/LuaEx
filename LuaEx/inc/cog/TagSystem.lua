local class     = class;
local rawtype   = rawtype;
local string    = string;
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
},
{--STATIC PUBLIC
},
--TagSystem = function(stapub) end,
{--PRIVATE
    tags = {},
},
{--PROTECTED
    add = function(this, cdat, sTag, bDisabled)
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
    isEnabled = function(this, cdat, sTag)
        local bRet  = false;

        if (type(sTag) == "string") then
            sTag = sTag:upper();
            bRet = cdat.pri.tags[sTag] ~= nil and cdat.pri.tags[sTag];
        end

        return bRet;
    end,
    remove = function(this, cdat, sTag)
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
    setEnabled = function(this, cdat, sTag, bFlag)
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
    has = function(this, cdat, sTag)
        return type(sTag) == "string" and cdat.pri.tags[sTag:upper()] ~= nil;
    end,
},
{--PUBLIC
    --hasComponent = function(this, cdat, sName)
    --    return type(sName) == "string" and cdat.pri.components[sName] ~= nil;
    --end,
    TagSystem = function(this, cdat, super, cSubclass)
        super(TagSystem)
        local pri = cdat.pri;
        local pro = cdat.pro;

        pri.subclass    = cSubclass;
        pro.components  = createComponentManagementSystem(cSubclass);
    end,
},
nil,  --extending class
false,--if the class is final or limited
nil   --interface(s) (either nil, or interface(s))
);
