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

},
{--PUBLIC
    Entity = function(this, cdat, super)
        super();
    end,
},
CoG,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
