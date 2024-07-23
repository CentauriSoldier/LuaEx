return class("Solid",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Solid = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    surfaceArea = 0,
    volume      = 0,
    Solid = function(this, cdat)

    end,
},
{--PUBLIC
    getSurfaceArea__FNL = function(this, cdat)
        return cdat.pro.surfaceArea;
    end,

    getVolume__FNL = function(this, cdat)
        return cdat.pro.volume;
    end,    
},
nil,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
