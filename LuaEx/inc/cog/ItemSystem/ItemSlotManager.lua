--TODO LOCALIZATION

--[[!
@fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Functions
@desc TODO
@ex TODO
!]]
local function validateItemInput(vItem)
    local cItem = class.of(vItem);

    if not (cItem) then
        error("Error creating ItemSlotManager.\nOwner must be an instance of a class. Got type "..type(vItem)..".", 2);
    end

    if not (class.ischildorself(cItem, "Item")) then
        error("Error in ItemSlotManager.\nItem must be an instance of an Item class or subclass.", 2);
    end

end







--[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager
    @desc STUFF HERE
    @parent <a href="#LuaEx.CoG.Component">Component</a>
!]]
return class("ItemSlotManager",
{--METAMETHODS
    --TODO clone
},
{--STATIC PUBLIC
    --ItemSlotManager = function(stapub)
    --end,
},
{--PRIVATE
    itemSlots = {},
},
{--PROTECTED
},
{--PUBLIC
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.ItemSlotManager
    @desc The constructor for the <b>ItemSlotManager</b>. It's designed to be subclassed by classes such as <a href="#LuaEx.CoG.Systems.ItemSystem.Inventory">Inventory</a> and <a href="#LuaEx.CoG.Systems.ItemSystem.Container">Container</a>.
    @param Actor|Object oActor|oObject T
    @ex TODO
    !]]
    ItemSlotManager = function(this, cdat, super, tItemSlots, bPermitActor, bPermitComponent, bPermitObject)
        super(bPermitActor, bPermitComponent, bPermitObject);

        --[[if not (cOwner) then
            error("Error creating ItemSlotManager.\nOwner must be an instance of a class. Got type "..type(oOwner)..".");
        end

        if not (class.ischildorself(cOwner, Actor) or class.ischildorself(cOwner, ContainerObject) ) then
            error("Error creating ItemSlotManager.\nOwner must be an instance of an Actor or Object class or subclass. Got "..tostring(cOwner)..".");
        end]]

        --cdat.pro.owner = oOwner;

        if (rawtype(tItemSlots) == "table") then

            for _, vItemSlot in pairs(tItemSlots) do

                if (type(vItemSlot) ~= "ItemSlot") then
                    error("Error creating ItemSlotManager.\nExpected type ItemSlot. Got type ${type} at index ${index}." %
                    {type = type(vItemSlot), index = nIndex});
                end

                tItemSlots[#tItemSlots + 1] = vItemSlot;
            end

        end

    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.addItemSlot
    @desc TODO
    @ex TODO
    !]]
    addItemSlot = function(this, cdat, oSlot)
        type.assert.custom(oSlot, "ItemSlot");
        local tItemSlots = cdat.pro.itemSlots;
        tItemSlots[#tItemSlots + 1] = oSlot;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.containsItem
    @desc TODO
    @ex TODO
    !]]
    containsItem__FNL = function(this, cdat, oItem)
        local bRet = false;
        local nRet = -1;
        validateItemInput(oItem);

        for nIndex, oItemSlot in pairs(cdat.pro.itemSlots) do

            if (oItemSlot.isOccupied() and oItemSlot.getItem() == oItem) then
                bRet = true;
                nRet = nIndex;
                break;
            end

        end

        return bRet, nRet;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.containsItemAt
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
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.containsItemSlot
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
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.containsItemSlotAt
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
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.eachItemSlot
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
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.getItemAt
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
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.getItemCount
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
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.getItemSlotAt
    @desc TODO
    @ex TODO
    !]]
    getItemSlotAt__FNL = function(this, cdat, nIndex)
        return cdat.pro.itemSlots[nIndex] or nil;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.getItemSlotCount
    @desc Gets the total number of <a href="#LuaEx.CoG.Systems.ItemSystem.ItemSlot">ItemSlots</a>.
    @ret number nItemSlots The total number of <b>ItemSlots</b>.
    @ex local nItemSlots = oItemSlotManager.getItemSlotCount();
    !]]
    getItemSlotCount__FNL = function(this, cdat)
        return #cdat.pro.itemSlots;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.getOwner
    @desc TODO
    @ex TODO
    !]]
    getOwner__FNL = function(this, cdat)
        return cdat.pro.owner;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.removeItemSlot
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
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSlotManager.Methods.swapItems
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
Entity,--extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
