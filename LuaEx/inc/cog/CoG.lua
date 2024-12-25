return class("CoG",
{--METAMETHODS
},
{--STATIC PUBLIC
    --CoG = function(stapub) end,
},
{--PRIVATE
    blueprintium = null,
},
{--PROTECTED
},
{--PUBLIC
CoG = function(this, cdat)
    cdat.pri.blueprintium = Blueprintium();
end,
    fromBlueprint = function(this, cdat, sID, ...)--TODO
        local pro = cdat.pro;


    end,
    removeBlueprint__FNL = function(this, cdat, sID)--TODO

    end,
    getBlueprintium = function(this, cdat) --TODO move to pro after testing.
        return cdat.pri.blueprintium;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
