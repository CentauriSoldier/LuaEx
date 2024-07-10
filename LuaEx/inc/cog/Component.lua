--[[!
    @fqxn LuaEx.CoG.Component
    @desc This is a utility class intended to be used with and add functionality to the <a href="#LuaEx.CoG.Actor">Actor</a>, <a href="#LuaEx.CoG.Entity">Entity</a> and <a href="#LuaEx.CoG.Object">Object</a> classes.
    @parent <a href="#LuaEx.CoG.CoG">CoG</a>
!]]
return class("Component",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Component = function(stapub) end,
},
{--PRIVATE
    CanAttachToActor__autoRA    = null,
    CanAttachToEntity__autoRA   = null,
    CanAttachToObject__autoRA   = null,
    owner = null,
},
{--PROTECTED
    Component = function(this, cdat, super, bPermitActor, bPermitEntity, bPermitObject)
        local pri = cdat.pri;
        pri.owner = CoG();
        pri.CanAttachToActor    = type(bPermitActor)    == "boolean" and bPermitActor   or false;
        pri.CanAttachToEntity   = type(bPermitEntity)   == "boolean" and bPermitEntity  or false;
        pri.CanAttachToObject   = type(bPermitObject)   == "boolean" and bPermitObject  or false;

        super();
    end,
},
{--PUBLIC
    attach = function(this, cdat, oCoG)

    end,
    --[[!
    @fqxn LuaEx.CoG.Component.Methods.setOwner
    @desc TODO
    @ex TODO
    !]]
    setOwner__FNL = function(this, cdat, oOwner)
        cdat.pro.owner = oOwner;
    end,
},
CoG,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
