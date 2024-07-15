local class     = class;
local rawtype   = rawtype;
local string    = string;
local type      = type;


--[[type.assert.string(sName, "%S+");
local bRet          = false;
local pri           = cdat.pri;
local cComponent    = class.of(oComponent);
local tComponents   = pri.components;

if (cComponent and class.isparent(Component, cComponent) and tComponents[sName] == nil and
    oComponent.canAttachToClass(pri.subclass)) then
    tComponents[sName] = oComponent;
    bRet = true;
end

return bRet;]]

local function createComponentManagementSystemOLD(cSubclass)
    local tCMSActual = {};
    local tCMSNames  = {};
    local tCMSDecoy  = {};
    local nCount     = 0;

    local tCMSMeta   = {
        __call = function(t)
            local nIndex = 0;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= nCount) then
                    local tEntry = tCMSActual[nIndex];
                    return tEntry.name, tEntry.component;
                end

            end

            end,
        __index = function(t, sName)
            return tCMSActual[sName] or nil;
        end,
        __len = function()
            return nCount;
        end,
        __newindex = function(t, sName, oComponent)
            local cComponent    = class.of(oComponent);

            if (rawtype(sName) == "string" and cComponent and class.isparent(Component, cComponent) and tCMSNames[sName] == nil and
                oComponent.canAttach(cSubclass)) then
                tCMSNames[sName]    = true;
                nCount              = nCount + 1;
                tCMSActual[nCount]  = { name = sName,
                                        component = oComponent};
            end

        end,

    };

    setmetatable(tCMSDecoy, tCMSMeta);

    return tCMSDecoy;
end



local function createComponentManagementSystem(cSubclass)
    local tCMSActual = {};
    local tCMSNames  = {};
    local tCMSDecoy  = {};
    local nCount     = 0;

    local tCMSMeta   = {
        __call = function(t)
            local nIndex = 0;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= nCount) then
                    local tEntry = tCMSActual[nIndex];
                    return tEntry.name, tEntry.component;
                end

            end

            end,
        __index = function(t, sName)
            return tCMSActual[sName] or nil;
        end,
        __len = function()
            return nCount;
        end,
        __newindex = function(t, sName, oComponent)

            if (rawtype(sName) == "string" and class.of(oComponent) and tCMSNames[sName] == nil) then
                tCMSNames[sName]    = true;
                nCount              = nCount + 1;
                tCMSActual[nCount]  = { name = sName,
                                        component = oComponent};
            end

        end,

    };

    setmetatable(tCMSDecoy, tCMSMeta);

    return tCMSDecoy;
end

--[[!
    @fqxn LuaEx.CoG
    @desc <b>C</b>ode <b>o</b>f <b>G</b>aming is a Lua framework containing support scripts, classes and interfaces such as STUFF HERE and more.
!]]

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
return class("Integrator",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = Integrator();
        return oNew;
    end,
},
{--STATIC PUBLIC
},
--Integrator = function(stapub) end,
{--PRIVATE
    subclass            = null,
    tags                = {},
},
{--PROTECTED
    components          = null,
    Integrator = function(this, cdat, super, cSubclass)
        super(Integrator)
        local pri = cdat.pri;
        local pro = cdat.pro;

        pri.subclass    = cSubclass;
        pro.components  = createComponentManagementSystem(cSubclass);
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
    removeComponent = function(this, cdat, oComponent)
        --TODO or not...
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
{--PUBLIC
    --hasComponent = function(this, cdat, sName)
    --    return type(sName) == "string" and cdat.pri.components[sName] ~= nil;
    --end,

},
CoG,                               --extending class
{"Actor", "Item", "Object", "Structure"},  --if the class is final or limited
nil                                --interface(s) (either nil, or interface(s))
);
--[[
CoG: Base class for all entities in the game framework, providing essential functionalities and serving as the root for all subclasses.

Subclass (Unnamed): Subclass for all entities that can have components and tags, encompassing both interactive and static entities.

    Actor: Entities with behaviors or actions (NPCs, players, animals, vehicles).
    Structure: Buildings and constructions (houses, bridges, mountains).
    Item: Usable items (potions, guns, swords, armor, keys).
    Object: Static objects that can be interacted with (trees that can be cut down, rocks that can be mined).

Environment: Represents natural settings and terrain.

Entity: Abstract systems and components driving game mechanics.
]]
