local class = class;
local type  = type;
--[[!
    @fqxn LuaEx.CoG.Classes.Component
    @desc <p>This is a utility class intended to be used with and add functionality to the <a href="#LuaEx.CoG.Actor">Actor</a>, <a href="#LuaEx.CoG.Entity">Entity</a> and <a href="#LuaEx.CoG.Object">Object</a> classes.</p>
    <p>Every <a href="#LuaEx.CoG.Entity">CoG</a> has the ability to use <b>Components</b>. <b>Components</b>, such as <a href="#LuaEx.CoG.Systems.ItemSystem.Inventory"></a>Inventory</li></p>, can be added to certain <b>CoGs</b> as defined and restricted within each <b>Component</b>. Rather than making classes force their subclasses to use or not use every potential mechanism, it permits versatility by allowing functionality at a granular level.
    <br>
    For example, some creature subclass may need an inventory system while another does not. Instead of mandating an inventory system for all creatures, the superclass could allow each subclass to choose for itself whether it implemented that system.
    In order to prevent errors arrising from assumptions about functionality, <b>CoG</b> methods exist to check for <b>Components</b> before attempting to use them (in cases where there would otherwise be ambiguity).
    </p>
!]]
return class("Component",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Component = function(stapub) end,
},
{--PRIVATE
    CanAttachToActor__autoRA        = null,
    CanAttachToComponent__autoRA    = null,
    CanAttachToEntity__autoRA       = null,
    CanAttachToObject__autoRA       = null,
    permitted                       = {},
    ownerIsSet                      = false,
},
{--PROTECTED
    Component = function(this, cdat, super, bPermitActor, bPermitComponent, bPermitObject)
        super(Component);
        local pri = cdat.pri;
        --pri.owner = CoG();
        bPermitActor        = type(bPermitActor)        == "boolean" and bPermitActor       or false;
        bPermitComponent    = type(bPermitComponent)    == "boolean" and bPermitComponent   or false;
        bPermitObject       = type(bPermitObject)       == "boolean" and bPermitObject      or false;

        pri.CanAttachToActor        = bPermitActor;
        pri.CanAttachToComponent    = bPermitComponent;
        pri.CanAttachToObject       = bPermitObject;

        pri.permitted[Actor]        = bPermitActor;
        pri.permitted[Component]    = bPermitComponent;
        pri.permitted[Object]       = bPermitObject;
    end,
},
{--PUBLIC
    canAttach = function(this, cdat, cClass)
        local bRet = false;

        if (class.is(cClass)) then
            bRet = cdat.pri.permitted[cClass] or false;
        end

        return bRet;
    end,

    --[[!
    @fqxn LuaEx.CoG.Component.Methods.setOwner
    @desc TODO
    @ex TODO
    !]]
--[[    setOwner__FNL = function(this, cdat, oOwner)
        local pri   = cdat.pri;
        local pro   = cdat.pro;
        local bRet  = (not pri.ownerIsSet) and class.isinstance(oOwner) and
                      ;

        if (bRet) then
            pro.owner = oOwner;
        end

        return bRet;
    end,]]
},
ComponentHost,    --extending class
false,  --if the class is final or limited
nil     --interface(s) (either nil, or interface(s))
);
