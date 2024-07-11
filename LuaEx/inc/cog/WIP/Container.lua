--[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.Container
    @desc A child of the ItemSlotManager, <b>Container</b> is meant to provide item management for <a href="#LuaEx.CoG.Object">Objects</a>.
    @parent <a href="#LuaEx.CoG.Systems.ItemSystem.ItemSlotManager">ItemSlotManager</a>
!]]
return class("Container",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Container = function(stapub)
    --end,
},
{--PRIVATE

},
{--PROTECTED
},
{--PUBLIC
    Container = function(this, cdat, super, tItemSlots)
        super(tItemsSlots, false, false, true);
        --cdat.pro.owner = oOwner;
    end,
},
ItemSlotManager,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
