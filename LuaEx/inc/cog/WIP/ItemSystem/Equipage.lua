return class("Equipage",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Equipage = function(stapub)
    --end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    Equipage = function(this, cdat, super, oOwner, tSlots)
        super(class.is(oOwner) and Actor);
        --init the owner slot;
        cdat.pro.owner = Actor();
        cdat.pro.owner = (type.isnil(oOwner) or type.isnull(oOwner))
                          and cdat.pro.owner or oOwner;--????
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
Entity,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
