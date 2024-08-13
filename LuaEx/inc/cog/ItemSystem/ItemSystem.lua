--TODO LOCALIZATION
local class = class;

--[[!
@fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Functions
@desc TODO
@ex TODO
!]]
local function validateItemInput(vItem)
    local cItem = class.of(vItem);

    if not (cItem) then
        error("Error in ItemSystem.\nOwner must be an instance of a class. Got type "..type(vItem)..".", 2);
    end

    if not (class.ischildorself(cItem, BaseItem)) then
        error("Error in ItemSystem.\nItem must be an instance of a BaseItem class or subclass.", 2);
    end

end







--[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem
    @desc STUFF HERE
    @parent <a href="#LuaEx.CoG.Component">Component</a>
!]]
return class("ItemSystem",
{--METAMETHODS
    --TODO clone

    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.removeItemSlot
    @desc TODO
    @ex TODO
    !]]
    __pairs = function(this, cdat)
        local tItems = cdat.pro.items;
        return next, tItems, nil;
    end,
},
{--STATIC PUBLIC
    --ItemSystem = function(stapub)
    --end,
},
{--PRIVATE

},
{--PROTECTED
    items       = {},
    maxItems    = math.huge,
},
{--PUBLIC
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.ItemSystem
    @desc The constructor for the <b>ItemSystem</b>.
    @ex TODO
    !]]
    ItemSystem = function(this, cdat, super, nMaxItems, tItems) --TODO allow for max items adjustment plus setter/getter
        local pro = cdat.pro;

        if (rawtype(nMaxItems) == "number") then
            nMaxItems = math.floor(nMaxItems);

            if (nMaxItems > 0) then
                pro.maxItems = nMaxItems;
            end

        end

        if (rawtype(tItems) == "table") then
            local tMyItems      = pro.items;
            local nMyMaxItems   = pro.maxItems;

            for _, vItem in pairs(tItems) do
                local nItemCount = #tMyItems;

                if (nItemCount < tMyMaxItems) then
                    validateItemInput(vItem);
                    tMyItems[nItemCount + 1] = vItem;
                end

            end

        end

    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.addItem
    @desc TODO
    @ex TODO
    !]]
    addItem__FNL = function(this, cdat, oItem)
        validateItemInput(oItem);
        local pro           = cdat.pro;
        local tItems        = pro.items;
        local nItemCount    = #tItems;
        local nMaxItems     = pro.maxItems;
        local bRet          = nItemCount < nMaxItems;

        if (bRet) then
            tItems[nItemCount + 1] = oItem;
        end

        return bRet, this;
    end,
    --TODO FINISH
    clear = function()
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.containsItem
    @desc TODO
    @ex TODO
    !]]
    containsItem__FNL = function(this, cdat, oItem)
        local bRet = false;
        local nRet = -1;
        validateItemInput(oItem);

        for nIndex, oExistingItem in pairs(cdat.pro.items) do

            if (oItem == oExistingItem) then
                bRet = true;
                nRet = nIndex;
                break;
            end

        end

        return bRet, nRet;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.containsItemAt
    @desc TODO
    @ex TODO
    !]]
    containsItemAt__FNL = function(this, cdat, oItem, nIndex)
        type.assert.custom(oSlot, "ItemSlot");
        type.assert.number(nIndex, true, true, false, true, false, 1);
        local bRet       = false;
        local tItems = cdat.pro.items;
        validateItemInput(oItem);

        if (tItems[nIndex]) then
            local oExistingItem = tItems[nIndex].getItem();
            bRet = oExistingItem and oExistingItem == oItem or false;
        end

        return bRet;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.getItemAt
    @desc TODO
    @ex TODO
    !]]
    getItemAt__FNL = function(this, cdat, nIndex)
        local pro = cdat.pro;
        type.assert.number(nIndex, true, true, false, true, false, 1, #pro.items);
        return pro.items[nIndex];
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.getItemCount
    @desc TODO
    @ex TODO
    !]]
    getItemCount__FNL = function(this, cdat)
        return #cdat.pro.items;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.getOwner
    @desc TODO
    @ex TODO
    !]]
    getOwner__FNL = function(this, cdat)
        return cdat.pro.owner;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.iterator
    @desc TODO
    @ex TODO
    !]]
    iterator__FNL = function(this, cdat) --5.1 compat
        local tItems = cdat.pro.items;
        return next, tItems, nil;
    end,
    --[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.ItemSystem.Methods.swapItems
    @desc TODO
    @ex TODO
    !]]
    swapItems__FNL = function(this, cdat, nIndex1, nIndex2)
        local tItems = cdat.pro.items;
        local nItems = #tItems;
        type.assert.number(nIndex1, true, true, false, true, false, 1, nItems);
        type.assert.number(nIndex2, true, true, false, true, false, 1, nItems);
        local bRet = nIndex1 ~= nIndex2;

        if (bRet) then
            tItems[nIndex1], tItems[nIndex2] = tItems[nIndex2], tItems[nIndex1];
        end

        return this, bRet;
    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
