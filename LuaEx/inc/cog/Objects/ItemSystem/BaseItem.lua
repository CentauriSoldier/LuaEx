local function validateAffix(vAffix)
    local cAffix = class.of(vAffix);

    if not (cAffix) then
        error("Error in modifying Item with affix.\nAffix must be an instance of a class. Got type "..type(vAffix)..".", 2);
    end

    if not (class.ischildorself(cAffix, Affix)) then
        error("Error in modifying Item with affix.\nAffix must be an instance of an Affix subclass.", 2);
    end
end

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
    Rarity__auto__          = false,
    Removable__autoA_is     = true,
    --Repairable__autoA_is  TODO
    Sellable__autoA_is      = true,
    Stackable__autoA_is     = false,
    TagSystem__autoAF       = null,
    Tradable__autoA_is      = true,
    --Upgradeable__autoA_is  --TODO
    --Value__autoA_  TODO
    --Weight__autoA_ TODO

    BaseItem = function(this, cdat, sName, sDescription, eRarity, wEventrix)
        local pro = cdat.pro;
        type.assert.string(sName, "%S+");
        type.assert.string(sDescription, "%S+");
        type.assert.custom(eRarity, "Rarity.LEVEL");

        pro.Eventrix    = eventrix(wEventrix); --TODO clone these?
        pro.Name        = sName;
        pro.Description = sDescription;
        pro.Rarity      = eRarity;
        pro.TagSystem   = TagSystem();

    end,
},
{--PUBLIC

},
BaseObject,  --extending class
false,       --if the class is final
nil          --interface(s) (either nil, or interface(s))
);
