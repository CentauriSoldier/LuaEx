--TODO LOCALIZATION

--[[!
@fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Functions
@desc TODO
@ex TODO
!]]
local function validateItemInput(vItem)
    local cItem = class.of(vItem);

    if not (cItem) then
        error("Error in ItemSlotSystem.\nOwner must be an instance of a class. Got type "..type(vItem)..".", 2);
    end

    if not (class.ischildorself(cItem, BaseItem)) then
        error("Error in ItemSlotSystem.\nItem must be an instance of an BaseItem class or subclass.", 2);
    end

end







--[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem
    @desc STUFF HERE
    @parent <a href="#LuaEx.CoG.Component">Component</a>
!]]
return class("ItemSlotSystem",
{--METAMETHODS
    --TODO clone

    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.removeItemSlot
    @desc TODO
    @ex TODO
    !]]
    __pairs = function(this, cdat)
        local tItemSlots = cdat.pro.itemSlots;
        return next, tItemSlots, nil;
    end,
},
{--STATIC PUBLIC
    --ItemSlotSystem = function(stapub)
    --end,
},
{--PRIVATE

},
{--PROTECTED
    itemSlots = {},
},
{--PUBLIC
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.ItemSlotSystem
    @desc The constructor for the <b>ItemSlotSystem</b>.
    @ex TODO
    !]]
    ItemSlotSystem = function(this, cdat, super, tItemSlots)

        if (rawtype(tItemSlots) == "table") then

            for _, vItemSlot in pairs(tItemSlots) do

                if (type(vItemSlot) ~= "ItemSlot") then
                    error("Error creating ItemSlotSystem.\nExpected type ItemSlot. Got type ${type} at index ${index}." %
                    {type = type(vItemSlot), index = nIndex});
                end

                tItemSlots[#tItemSlots + 1] = vItemSlot;
            end

        end

    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.addItemSlot
    @desc TODO
    @ex TODO
    !]]
    addItemSlot = function(this, cdat, oSlot)
        type.assert.custom(oSlot, "ItemSlot");
        local tItemSlots = cdat.pro.itemSlots;
        tItemSlots[#tItemSlots + 1] = oSlot;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.containsItem
    @desc TODO
    @ex TODO
    !]]
    containsItem__FNL = function(this, cdat, oItem)
        local bRet = false;
        local nRet = -1;
        validateItemInput(oItem);

        for nIndex, oItemSlot in pairs(cdat.pro.itemSlots) do

            if (oItemSlot.isOccupied() and oItemSlot.get() == oItem) then
                bRet = true;
                nRet = nIndex;
                break;
            end

        end

        return bRet, nRet;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.containsItemAt
    @desc TODO
    @ex TODO
    !]]
    containsItemAt__FNL = function(this, cdat, oItem, nIndex)
        type.assert.custom(oSlot, "ItemSlot");
        type.assert.number(nIndex, true, true, false, true, false, 1);
        local bRet       = false;
        local tItemSlots = cdat.pro.itemSlots;
        validateItemInput(oItem);

        if (tItemSlots[nIndex]) then
            local oExistingItem = tItemSlots[nIndex].getItem();
            bRet = oExistingItem and oExistingItem == oItem or false;
        end

        return bRet;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.containsItemSlot
    @desc TODO
    @ex TODO
    !]]
    containsItemSlot__FNL = function(this, cdat, oSlot)
        type.assert.custom(oSlot, "ItemSlot");
        local bRet = false;
        local nRet = -1;

        for nIndex, oItemSlot in pairs(cdat.pro.itemSlots) do

            if (oItemSlot == oSlot) then
                bRet = true;
                nRet = nIndex;
                break;
            end

        end

        return bRet, nRet;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.containsItemSlotAt
    @desc TODO
    @ex TODO
    !]]
    containsItemSlotAt__FNL = function(this, cdat, oSlot, nIndex)
        type.assert.custom(oSlot, "ItemSlot");
        type.assert.number(nIndex, true, true, false, true, false, 1);
        local tItemSlots    = cdat.pro.itemSlots;
        return tItemSlots[nIndex] and tItemSlots[nIndex] == oSlot or false;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.eachItemSlot
    @desc TODO
    @ex TODO
    !]]
    eachItemSlot__FNL = function(this, cdat)
        local pro           = cdat.pro;
        local tItemsSlots   = pro.itemSlots;
        local nIndex        = 0;
        local nMax          = #tItemsSlots;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return nIndex, tItemsSlots[nIndex];
            end

        end

    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.getItemAt
    @desc TODO
    @ex TODO
    !]]
    getItemAt__FNL = function(this, cdat, nIndex)
        type.assert.number(nIndex, true, true, false, true, false, 1);
        local bRet;
        local tItemSlots = cdat.pro.itemSlots;

        if (tItemSlots[nIndex]) then
            bRet = tItemSlots[nIndex].getItem();
        end

        return bRet
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.getItemCount
    @desc TODO
    @ex TODO
    !]]
    getItemCount__FNL = function(this, cdat)
        local nRet = 0;

            for nIndex, oItemSlot in pairs(cdat.pro.ItemSlots) do

                if (oItemSlot.isOccupied()) then
                    nRet = nRet + 1;
                end

            end

        return nRet;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.getItemSlotAt
    @desc TODO
    @ex TODO
    !]]
    getItemSlotAt__FNL = function(this, cdat, nIndex)
        return cdat.pro.itemSlots[nIndex] or nil;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.getItemSlotCount
    @desc Gets the total number of <a href="#LuaEx.CoG.Systems.ItemSystem.ItemSlot">ItemSlots</a>.
    @ret number nItemSlots The total number of <b>ItemSlots</b>.
    @ex local nItemSlots = oItemSlotManager.getItemSlotCount();
    !]]
    getItemSlotCount__FNL = function(this, cdat)
        return #cdat.pro.itemSlots;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.getOwner
    @desc TODO
    @ex TODO
    !]]
    getOwner__FNL = function(this, cdat)
        return cdat.pro.owner;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.removeItemSlot
    @desc TODO
    @ex TODO
    !]]
    iterator__FNL = function(this, cdat) --5.1 compat
        local tItemSlots = cdat.pro.itemSlots;
        return next, tItemSlots, nil;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.removeItemSlot
    @desc TODO
    @ex TODO
    !]]
    removeItemSlot__FNL = function(this, cdat, nIndex)
        local tItemSlots   = cdat.pro.itemSlots;
        local nItemSlots    = #tItemSlots;
        type.assert.number(nIndex, true, true, false, true, false, 1, nItemSlots);
        table.remove(tItemSlots, nIndex);
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotSystem.Methods.swapItems
    @desc TODO
    @ex TODO
    !]]
    swapItems__FNL = function(this, cdat, nSlot1, nSlot2)
        local tItemSlots   = cdat.pro.itemSlots;
        local nItemSlots    = #tItemSlots;
        type.assert.number(nSlot1, true, true, false, true, false, 1, nItemSlots);
        type.assert.number(nSlot2, true, true, false, true, false, 1, nItemSlots);
        local bRet          = nSlot1 ~= nSlot2;

        if (bRet) then
            local oSlot1 = tItemSlots[nSlot1];
            local oSlot2 = tItemSlots[nSlot2];

            if (oSlot1.isOccupied() and oSlot2.isOccupied() and
                not (oSlot1.isLocked() or oSlot2.isLocked())) then

                local oItem1 = oSlot1.getItem();
                local oItem2 = oSlot2.getItem();
                oSlot1.setItem(oItem2, true);
                oSlot2.setItem(oItem1, true);
                bRet = true;
            end

        end

        return this, bRet;
    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
