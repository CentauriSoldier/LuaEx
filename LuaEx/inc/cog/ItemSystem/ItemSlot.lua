--TODO LOCALIZATION
local class             = class;
local oItemPlaceholder;


--[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlot.isAllowedItem
    @scope Local
    @desc Designed
!]]
local function isAllowedItem(this, cdat, vInput)
    local bRet  = class.isinstance(vInput);
    local pro   = cdat.pro;

    if (bRet) then

        for _, cType in pairs(pro.allowedTypes) do
            local cInput = class.of(vInput);

            if (cInput == cType or class.ischild(cInput, cType)) then
                bRet = true;
                break;
            end

        end

    end

    return bRet;
end

--[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlot
    @desc Designed to hold and manage Items.
    @parent <a href="#LuaEx.CoG.Entity">Entity</a>
!]]
return class("ItemSlot",
{--METAMETHODS

},
{--STATIC PUBLIC
    ItemSlot = function(stapub)
        --oItemPlaceholder = Item();
    end,
},
{--PRIVATE
    placeholderItem     = null;
},
{--PROTECTED
    allowedTypes        = {},
    Enabled__auto_Fis   = true,
    item                = oItemPlaceholder,
    Locked__auto_Fis    = false,
    Name__autoAF        = "",
    Occupied__autoAAis  = false,
    Owner__auto_F       = null,--TODO set
},
{--PUBLIC
    ItemSlot = function(this, cdat, super, sName, tAllowedTypes)
        super(false, true, false, false);

        ---cdat.pri.placeholderItem = Item();
        type.assert.string(sName, "%S+", "ItemSlot name cannot be blank.");
        local pro = cdat.pro;

        pro.Name = sName;

        if (rawtype(tAllowedTypes) == "table") then

            for _, cItemClass in pairs(tAllowedTypes) do
                local sTypeError = "";
                local bError = false;

                --check only class input
                if (class.is(cItemClass)) then

                    --process only the Item class or its subclasses
                    if (cItemClass == Item or class.ischild(cItemClass, Item)) then
                        pro.allowedTypes[#pro.allowedTypes + 1] = cItemClass;

                    else--throw error if there's a type mismatch
                        bError      = true;
                        sTypeError  = class.getname(cItemClass);
                    end

                else --throw error if there's a type mismatch
                    bError      = true;
                    sTypeError  = type(cItemClass);
                end

                if (bError) then
                    error("Error creating ItemSlot.\nAllowed types must be of type Item (or Item subclass). Got type: "..sTypeError, 3);
                end

            end

        end

        --default to Item if no allowed types were provided
        if (#pro.allowedTypes < 1) then
            pro.allowedTypes[1] = ItemSlot;
        end

    end,


    getItem__FNL = function(this, cdat)
        local pro = cdat.pro;
        return pro.Occupied and pro.item or nil;
    end,

    removeItem__FNL = function(this, cdat)
        local pro   = cdat.pro;
        local bRet  = not pro.Locked and pro.Occupied;

        if (bRet) then
            pro.item     = oItemPlaceholder;
            pro.Occupied = false;
        end

        return this, bRet;
    end,



    setItem__FNL = function(this, cdat, vItem, bForceRemoval)
        local pro = cdat.pro;

        if not (isAllowedItem(this, cdat, vItem)) then
            error("Error adding Item to ItemSlot. Not an Item or Item type not allowed.");
        end

        local bRet = not pro.Locked and (not pro.Occupied or bForceRemoval);

        if (bRet) then
            pro.item     = vItem;
            pro.Occupied = true;
        end

        return this, bRet;
    end,

    equip = function(this, oCreature, oItem)
        local pro = cdat.pro;
        cdat.pro.OnEquip(this, oCreature);
    end,

    unequip = function(this, cdat, oItem)
        local pro = cdat.pro;
        cdat.pro.OnUnequip(this, pro.owner);
    end,

    setOnEquipEvent = function(this, cdat, fEvent)
        local bRet = false;

        if (type(fEvent) == "function") then
            cdat.pro.onEquip = fEvent;
            bRet = true;
        end

        return bRet;
    end,

    setOnUnequipEvent = function(this, fEvent)
        local bRet = false;

        if (type(fEvent) == "function") then
            cdat.pro.onUnequip = fEvent;
            bRet = true;
        end

        return bRet;
    end,
},
Entity,   --extending class
true, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
