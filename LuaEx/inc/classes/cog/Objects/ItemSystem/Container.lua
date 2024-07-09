return class("Container",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Container = function(stapub)
    --end,
},
{--PRIVATE

},
{--PROTECTED
},
{--PUBLIC
    Container = function(this, cdat, super, oOwner, tItemSlots)
        super(Object());
        cdat.pro.owner = oOwner;
    end,
    getSlots = function()

    end,
},
ItemStore,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
