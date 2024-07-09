return class("Actor",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = Actor();
        return oNew;
    end,
},
{--STATIC PUBLIC
    --Actor = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    inventory = null,
},
{--PUBLIC
    Actor = function(this, cdat, super)
        super();
    end,
},
CoG,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
