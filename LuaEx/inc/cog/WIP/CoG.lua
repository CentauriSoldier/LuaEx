local class     = class;
local rawtype   = rawtype;
local string    = string;
local type      = type;


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

},
{--PROTECTED
    CoG = function(this, cdat, cSubclass)
        local pri = cdat.pri;
        local pro = cdat.pro;
    end,


},
{--PUBLIC
    --hasComponent = function(this, cdat, sName)
    --    return type(sName) == "string" and cdat.pri.components[sName] ~= nil;
    --end,

},
nil,                            --extending class
{"Integrator", "Entity"},  --if the class is final or limited
nil                             --interface(s) (either nil, or interface(s))
);
