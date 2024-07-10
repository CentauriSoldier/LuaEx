return class("Boots",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Boots = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    Boots = function(this, cdat, super)
        super();
    end,
},
Item,       --extending class
true,       --if the class is final
IEquipable  --interface(s) (either nil, or interface(s))
);
