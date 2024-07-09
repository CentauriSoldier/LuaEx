return class("Item",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = Item();
        --print(type(oNew))
        return oNew;
    end,
},
{--STATIC PUBLIC
    Item = function(stapub)
    end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    Item = function(this, cdat, super)
        super();

    end,
},
Object,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
