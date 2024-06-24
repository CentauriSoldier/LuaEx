return class("Inventory",
{--METAMETHODS

},
{--STATIC PUBLIC
    _INIT = function(stapub)
    end,
},
{--PRIVATE

},
{--PROTECTED
    owner = null,
},
{--PUBLIC
    Inventory = function(this, cdat, oOwner, tSlots)
        cdat.pro.owner = (type.isnil(oOwner) or type.isnull(oOwner))
                          and cdat.pro.owner or oOwner;

    end,
    getOwner = function(this, cdat)
        return cdat.pro.owner;
    end,
    setOwner = function(this, cdat, oOwner)
        cdat.pro.owner = (type.isnil(oOwner) or type.isnull(oOwner))
                          and cdat.pro.owner or oOwner;
    end,
    getSlots = function()

    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
