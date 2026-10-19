--[[!
    @fqxn CoG.StructureSystem.BaseStucture
    @desc Unfinished BaseObject subclass placeholder. Its public constructor is empty and does not call the parent constructor. Inherited metadata/components are therefore not initialized by this constructor.
    @note No ability/structure gameplay behavior is implemented here. The structure class's actual declared name is BaseStucture (as spelled in source).
!]]
return class("BaseStucture",
{--METAMETHODS

},
{--STATIC PUBLIC
    --BaseStucture = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    --[[!
        @fqxn CoG.StructureSystem.BaseStucture.Methods.BaseStucture
        @pulsarlua function BaseStucture
        @desc Empty placeholder constructor. Accepts no user arguments and performs no BaseObject initialization.
    !]]
    BaseStucture = function(this, cdat)

    end,
},
BaseObject,  --extending class
false,       --if the class is final (or (if a table is provided) limited to certain subclasses)
nil          --interface(s) (either nil, or interface(s))
);

--[[!
    @fqxn CoG.StructureSystem.BaseStucture.InheritedBaseObject
    @inheritdoc CoG.BaseObject
!]]
