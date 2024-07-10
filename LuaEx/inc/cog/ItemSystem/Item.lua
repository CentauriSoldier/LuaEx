--[[!
    @fqxn LuaEx.CoG.ItemSystem.Item
    @desc STUFF HERE
    @parent <a href="#LuaEx.CoG.Object">Object</a>
!]]
return class("Item",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = Item();
        --print(type(oNew))
        return oNew;
    end,
},
{--STATIC PUBLIC
    Item = function(stapub)
    end,
    --enum("Item.ACTION", {"DISCARD"}, nil, true),
},
{--PRIVATE

},
{--PROTECTED
    Item = function(this, cdat, super)
        super();

    end,
},
{--PUBLIC

},
Object,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
