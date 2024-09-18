--[[!
    @fqxn CoG.ItemSystem.BaseItem
    @desc STUFF HERE
!]]
return class("BaseItem",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = BaseItem(); --TODO FINISH
        --print(type(oNew))
        return oNew;
    end,
},
{--STATIC PUBLIC
    --BaseItem = function(stapub)

    --end,
    --enum("Item.ACTION", {"DISCARD"}, nil, true),
},
{--PRIVATE
},
{--PROTECTED
    Consumable__autoA_is    = false,
    --Durable__autoA_is        TODO use a number value - -1 means inf
    Equipable__autoA_is     = false,
    --Exclusive__autoA_is only one allowed at a time
    --Inimitable__autoA_is TODO prevents copying or not
    Quest__autoA_is         = false,

    Removable__autoA_is     = true,
    --Repairable__autoA_is  TODO
    Sellable__autoA_is      = true,
    Stackable__autoA_is     = false,
    Tradable__autoA_is      = true,
    --Upgradeable__autoA_is  --TODO
    --Value__autoA_  TODO
    --Weight__autoA_ TODO

    BaseItem = function(this, cdat)


    end,
},
{--PUBLIC

},
BaseObject,  --extending class
false,       --if the class is final
nil          --interface(s) (either nil, or interface(s))
);
