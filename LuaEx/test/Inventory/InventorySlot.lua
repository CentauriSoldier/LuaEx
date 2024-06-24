return class("InventorySlot",
{--METAMETHODS

},
{--STATIC PUBLIC
    _INIT = function(stapub)
    end,
},
{--PRIVATE

},
{--PROTECTED
    name            = "",
    allowedtypes    = {},
    item            = null,
},
{--PUBLIC
    InventorySlot = function(this, cdat, sName, tAllowedTypes)
        type.assert.string(sName, "%S+", "InventorySlot name cannot be blank.");
        local pro = cdat.pro;

        if (rawtype(tAllowedTypes) == "table") then

            for k, v in pairs(tAllowedTypes) do

                if not (class.of(v) == InventoryItem or class.derives(class.of(v), InventoryItem)) then
                    error("Error creating InventorySlot.\n", 3);--TODO ERROR
                end


            end

        else
            pro.allowedtypes[1] = "InventoryItem";
        end

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
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
