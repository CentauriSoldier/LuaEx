--TODO LOCALIZATION
local class = class;

--[[!
    @fqxn CoG.ItemSystem
    @desc The item system is designed to be used for inventories, equipment, and other such applications.
    <br>
    <hr>
    <h4>Components</h4>
    <ul>
        <li>
            <h6><a href="#CoG.ItemSystem.BaseItem">BaseItem</a><h6>
            <p>The entire system is predecated on the <b>BaseItem</b> which must be extended in order to be used.</p>
        </li>
            <h6><a href="#CoG.ItemSystem.ItemSystem">ItemSystem</a><h6>
            <p>The <b>ItemSytem</b> is used to create systems such as inventories.
            <br>It has obligatory methods such as those used to add, remove, count and check for the existence of items.
            <br>It is suitable for many purposes as-is and may be extended for futher customization.</p>
        <li>
            <h6><a href="#CoG.ItemSystem.ItemStashSystem">ItemStashSystem</a><h6>
            <p>This system has virtual tabs that each contain an <b>ItemSystem</b> and is designed to used for things like inventory pages or a player's item stash.</p>
        </li>
        <li>
            <h6><a href="#CoG.ItemSystem.ItemSlot">ItemSlot</a><h6>
            <p>Allows the containment of items as well specifiying which subtypes of items may be contained inside.
            <br>This permits/restricts the containment of specific <b>BaseItem</b> subclasses within an <b>ItemSlot</b>.</p>
        </li>
        <li>
            <h6><a href="#CoG.ItemSystem.ItemSlotSystem">ItemSlotSystem</a><h6>
            <p>This operates much like the <b>ItemSystem</b> except that instead of hosting items, it hosts <b>ItemSlots</b>.
            <br>This is designed to be used for things like player equipment systems or other such applications where one may wish to restict the type of items permitted in a given <b>ItemSlot</b>.</p>
        </li>
    </ul>
!]]


--[[!
@fqxn CoG.ItemSystem.ItemSystem.Functions.validateItemInput
@vis static private
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
    @fqxn CoG.ItemSystem.ItemSystem
    @desc STUFF HERE    
!]]
return class("ItemSystem",
{--METAMETHODS
    --TODO clone

    --[[!
    @fqxn CoG.ItemSystem.ItemSystem.Methods.removeItemSlot
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
    @fqxn CoG.ItemSystem.ItemSystem.ItemSystem
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
    @fqxn CoG.ItemSystem.ItemSystem.Methods.addItem
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
    @fqxn CoG.ItemSystem.ItemSystem.Methods.containsItem
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
    @fqxn CoG.ItemSystem.ItemSystem.Methods.containsItemAt
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
    @fqxn CoG.ItemSystem.ItemSystem.Methods.getItemAt
    @desc TODO
    @ex TODO
    !]]
    getItemAt__FNL = function(this, cdat, nIndex)
        local pro = cdat.pro;
        type.assert.number(nIndex, true, true, false, true, false, 1, #pro.items);
        return pro.items[nIndex];
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSystem.Methods.getItemCount
    @desc TODO
    @ex TODO
    !]]
    getItemCount__FNL = function(this, cdat)
        return #cdat.pro.items;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSystem.Methods.getOwner
    @desc TODO
    @ex TODO
    !]]
    getOwner__FNL = function(this, cdat)
        return cdat.pro.owner;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSystem.Methods.iterator
    @desc TODO
    @ex TODO
    !]]
    iterator__FNL = function(this, cdat) --5.1 compat
        local tItems = cdat.pro.items;
        return next, tItems, nil;
    end,
    --[[!
    @fqxn CoG.ItemSystem.ItemSystem.Methods.swapItems
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
