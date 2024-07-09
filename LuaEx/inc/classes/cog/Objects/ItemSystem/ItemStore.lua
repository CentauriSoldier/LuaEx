return class("ItemStore",
{--METAMETHODS

},
{--STATIC PUBLIC
    --ItemStore = function(stapub)
    --end,
},
{--PRIVATE
    
},
{--PROTECTED
    owner = null,
},
{--PUBLIC
    ItemStore = function(this, cdat, cOwner, nItemSlots)
        super();
        cdat.pro.owner = cOwner;
    end,
    getOwner__FNL = function(this, cdat)
        return cdat.pro.owner;
    end,
    setOwner__FNL = function(this, cdat, oOwner)
        cdat.pro.owner = oOwner;
    end,
    getSlots__FNL = function(this, cdat)

    end,
},
Entity,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
