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
    Durability__autoA_      = -1, -- -1 means inf
    Equipable__autoA_is     = false,
    Exclusive__autoA_is     = false, --only one may exist in player's possession
    Inimitable__autoA_is    = false, -- cannot be copied
    Quest__autoA_is         = false,
    Removable__autoA_is     = true,
    Repairable__autoA_is    = false,
    Sellable__autoA_is      = true,
    Stackable__autoA_is     = false,
    Tradable__autoA_is      = true,
    Upgradeable__autoA_is   = false,
    Value__autoA_           = 0,
    Weight__autoA_          = 0,

    BaseItem = function(this, cdat, sName, sDescription, eRarity, wEventrix,
                        bConsumable, nDurability, bEquipable, bExclusive,
                        bInimitable, bQuest, bRemovable, bRepairable, bSellable,
                        bStackable, bTradable, bUpgradeable, nValue, nWeight)
        local pro = cdat.pro;
        super(sName, sDescription, eRarity, wEventrix);

        pro.Consumable  = type(bConsumable)     == "boolean"    and bConsumable     or false;
        pro.Durability  = type(nDurability)     == "number"     and nDurability     or -1;
        pro.Equipable   = type(bEquipable)      == "boolean"    and bEquipable      or false;
        pro.Exclusive   = type(bExclusive)      == "boolean"    and bExclusive      or false;
        pro.Inimitable  = type(bInimitable)     == "boolean"    and bInimitable     or false;
        pro.Quest       = type(bQuest)          == "boolean"    and bQuest          or false;
        pro.Removable   = type(bRemovable)      == "boolean"    and bRemovable      or true;
        pro.Repairable  = type(bRepairable)     == "boolean"    and bRepairable     or false;
        pro.Sellable    = type(bSellable)       == "boolean"    and bSellable       or true;
        pro.Stackable   = type(bStackable)      == "boolean"    and bStackable      or false;
        pro.Tradable    = type(bTradable)       == "boolean"    and bTradable       or true;
        pro.Upgradeable = type(bUpgradeable)    == "boolean"    and bUpgradeable    or false;
        pro.Value       = type(nValue)          == "number"     and nValue          or 0;
        pro.Weight      = type(nWeight)         == "number"     and nWeight         or 0;

    end,
},
{--PUBLIC

},
BaseObject,  --extending class
false,       --if the class is final
nil          --interface(s) (either nil, or interface(s))
);
