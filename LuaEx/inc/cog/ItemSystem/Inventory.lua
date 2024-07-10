--[[!
    @fqxn LuaEx.CoG.ItemSystem.Inventory
    @desc A child of the ItemSlotManager, <b>Inventory</b> is meant to provide items management for <a href="#LuaEx.CoG.Actor">Actors</a>.
    @parent <a href="#LuaEx.CoG.ItemSystem.ItemSlotManager">ItemSlotManager</a>
!]]
return class("Inventory",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Inventory = function(stapub)
    --end,
},
{--PRIVATE

},
{--PROTECTED
},
{--PUBLIC
    Inventory = function(this, cdat, super, tItemSlots)
        super(tItemSlots, true, false, false);
        --cdat.pro.owner = oOwner;
    end,
},
ItemSlotSystem,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
