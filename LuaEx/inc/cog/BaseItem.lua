--[[!
    @fqxn LuaEx.CoG.Systems.ItemSystem.Item
    @desc STUFF HERE
    @parent <a href="#LuaEx.CoG.Object">Object</a>
!]]
return class("BaseItem",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = BaseItem();
        --print(type(oNew))
        return oNew;
    end,
},
{--STATIC PUBLIC
    BaseItem = function(stapub)
    end,
    --enum("Item.ACTION", {"DISCARD"}, nil, true),
},
{--PRIVATE
},
{--PROTECTED
    Name__autoAF            = "",
    Quest__autoAFis         = false,
    Removable__autoAFis     = true,
    Sellable__autoAFis      = true,
    Tradable__autoAFis      = true,
    TagSystem__autoAF       = null,

    BaseItem = function(this, cdat, sName)
        local pro = cdat.pro;
        type.assert.string(sName, "%S+");

        pro.Name        = sName;
        pro.TagSystem   = TagSystem();
    end,
},
{--PUBLIC

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
