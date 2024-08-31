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
    Equipable__autoA_is     = false,
    Name__autoA_            = "", --leave as non-final so subclasses can alter it but create a public accessor only
    Quest__autoA_is         = false,
    Removable__autoA_is     = true,
    Sellable__autoA_is      = true,
    Tradable__autoA_is      = true,
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
