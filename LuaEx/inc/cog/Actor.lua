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
    --inventory            = null,
    HealthPool__autoRA   = null,
    Name__auto_F         = "",
    Targetor__autoRA     = null,--TODO add this!!!,

},
{--PUBLIC
    Actor = function(this, cdat, super)--sName, eAlliance, eClass, eComposition, eType)
        super(Actor);
        --type.assert.custom(eType, "Actor.TYPE");
        --type.assert.custom(eComposition, "Actor.COMPOSITION");
        local pro = cdat.pro;

        pro.HealthPool = Pool(1, 1);
        local oInventory = ItemSlotManager();

        cdat.pro.components.Inventory = oInventory;
    end,
    log = function(this, cdat, val)
        cdat.pro.log = val;
    end
},
Integrator,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
