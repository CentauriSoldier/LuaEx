--TODO LOCALIZATION

--[[!
@fqxn CoG.ItemSystem.ItemSlotSystem.Functions
@desc TODO
@ex TODO
!]]
local function validateItemInput(vItem)
    local cItem = class.of(vItem);

    if not (cItem) then
        error("Error in ItemSlotSystem.\nOwner must be an instance of a class. Got type "..type(vItem)..".", 2);
    end

    if not (class.ischildorself(cItem, BaseItem)) then
        error("Error in ItemSlotSystem.\nItem must be an instance of a BaseItem class or subclass.", 2);
    end

end







--[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem
    @desc STUFF HERE
!]]
return class("ItemSlotSystem",
{--METAMETHODS
    --TODO clone

    --[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.removeItemSlot
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
    itemSlots   = {},
    owner       = null,
},
{--PUBLIC
    --[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem.ItemSlotSystem
    @desc The constructor for the <b>ItemSlotSystem</b>.
    @ex TODO
    !]]
    ItemSlotSystem = function(this, cdat, tItemSlots, oOwner)
        local pro = cdat.pro;

        if (rawtype(tItemSlots) == "table") then
            type.assert.table(tItemSlots, "number", "ItemSlot", 1);

            for nIndex, vItemSlot in ipairs(tItemSlots) do
                tItemSlots[nIndex] = clone(vItemSlot);
            end

        end

        --TODO FINISH check owner type
        pro.owner = oOwner;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.addItemSlot
    @desc TODO
    @ex TODO
    !]]
    addItemSlot__FNL = function(this, cdat, oSlot)
        type.assert.custom(oSlot, "ItemSlot");
        local tItemSlots = cdat.pro.itemSlots;
        tItemSlots[#tItemSlots + 1] = oSlot;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.containsItem
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
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.containsItemAt
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
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.containsItemSlot
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
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.containsItemSlotAt
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
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.eachItemSlot
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
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getItemAt
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
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getItemCount
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
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getItemSlotAt
    @desc TODO
    @ex TODO
    !]]
    getItemSlotAt__FNL = function(this, cdat, nIndex)
        return cdat.pro.itemSlots[nIndex] or nil;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getItemSlotCount
    @desc Gets the total number of <a href="#CoG.ItemSystem.ItemSlot">ItemSlots</a>.
    @ret number nItemSlots The total number of <b>ItemSlots</b>.
    @ex local nItemSlots = oItemSlotManager.getItemSlotCount();
    !]]
    getItemSlotCount__FNL = function(this, cdat)
        return #cdat.pro.itemSlots;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.getOwner
    @desc TODO
    @ex TODO
    !]]
    getOwner__FNL = function(this, cdat)
        return cdat.pro.owner;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.eachSlot
    @desc TODO
    @ex TODO
    !]]
    eachSlot__FNL = function(this, cdat) --5.1 compat QUESTION Isn't this redundant? 
        local tItemSlots = cdat.pro.itemSlots;
        return next, tItemSlots, nil;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.removeItemSlot
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
    @fqxn CoG.ItemSystem.ItemSlotSystem.Methods.swapItems
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
