--[[!
    @fqxn LuaEx.CoG.Entity
    @desc This is the base class for all support classes which are intended to provide additional functionality to Actor and Object classes and subclasses.
    @parent <a href="#LuaEx.CoG.CoG">CoG</a>
!]]
return class("Entity",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = Entity();
        return oNew;
    end,
},
{--STATIC PUBLIC
},
--Entity = function(stapub) end,
{--PRIVATE

},
{--PROTECTED
    Entity = function(this, cdat, super)
        super();
    end,
},
{--PUBLIC

},
CoG,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
