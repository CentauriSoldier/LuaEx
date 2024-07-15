--[[!
    @fqxn LuaEx.CoG.Classes.Actor
    @desc This is the base class for all classes which are intended to interact with the game world.
    @parent <a href="#LuaEx.CoG.CoG">CoG</a>
!]]
return class("Actor",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = Actor();
        return oNew;
    end,
},
{--STATIC PUBLIC
    ALLIANCE    = enum("Actor.ALLIANCE", {"FRIEND", "FOE", "NEUTRAL"}, nil, true),
    CLASS       = enum("Actor.CLASS", {"PC", "NPC"}, nil, true),
    COMPOSITION = enum("Actor.COMPOSITION", {"ORGANIC", "INORGANIC", "HYBRID"}, nil, true),
    TYPE        = enum("Actor.TYPE", {"NATURAL", "SUPERNATURAL"}, nil, true),

    --Actor = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    --TODO DOCS
    HealthPool__autoRA   = null,
    Inventory__autoRA    = null,
    Name__auto_F         = "",
    Targetor__autoRA     = null,--TODO add this!!!,

},
{--PUBLIC
    Actor = function(this, cdat)
        local pro = cdat.pro;
        pro.HealthPool = Pool(1, 1);
        cdat.pro.Inventory = ItemSlotManager();
        --TODO targetor
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
