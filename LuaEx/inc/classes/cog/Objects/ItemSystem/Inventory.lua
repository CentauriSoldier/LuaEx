return class("Inventory",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Inventory = function(stapub)
    --end,
},
{--PRIVATE

},
{--PROTECTED
},
{--PUBLIC
    Inventory = function(this, cdat, super, oOwner, tItemSlots)
        super(Actor());
        cdat.pro.owner = oOwner;
    end,
    getSlots = function()

    end,
},
ItemStore,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
