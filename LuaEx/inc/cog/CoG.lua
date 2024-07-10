--[[!
    @fqxn LuaEx.CoG
    @desc <b>C</b>ode <b>o</b>f <b>G</b>aming is a Lua framework containing support scripts, classes and interfaces such as STUFF HERE and more.
!]]

--[[!
    @fqxn LuaEx.CoG.CoG
    @desc This is the base class for all CoG classes. The four child classes under CoG are:
    <br>
    <ul>
        <li><a href="#LuaEx.CoG.Actor"></a>Actor</li>
        <li><a href="#LuaEx.CoG.Entity"></a>Entity</li>
        <li><a href="#LuaEx.CoG.Object"></a>Object</li>
        <li><a href="#LuaEx.CoG.Component"></a>Component</li>
    </ul>
    Every other class is a decendant of one of these three classes.
!]]
return class("CoG",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = CoG();
        return oNew;
    end,
},
{--STATIC PUBLIC
},
--CoG = function(stapub) end,
{--PRIVATE
    componentRegistry   = {},
    components          = {},
},
{--PROTECTED
    CoG = function(this, cdat)

    end,
},
{--PUBLIC
    addComponent = function(this, cdat, sName, oComponent)
        type.assert.string(sName, "%S+");
        local bRet = false;
        local cComponent = class.of(oComponent);
        local tComponents = cdat.pri.components;

        if (cComponent and class.isparent(Component, cComponent) and tComponents[sName] == nil) then
            tComponents[sName] = oComponent;
            bRet = true;
        end

        return bRet;
    end,
    getComponent = function(this, cdat, sName)
        type.assert.string(sName, "%S+");
        return cdat.pri.components[sName] or nil;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
