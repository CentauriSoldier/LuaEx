return class("Object",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = Object();
        return oNew;
    end,
},
{--STATIC PUBLIC
    --Object = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    Object = function(this, cdat, super)
        super();
    end,
},
CoG,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
