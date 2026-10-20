--[[!
    @fqxn CoG.StructureSystem.CoGStructure
    @desc Unfinished CoGObject subclass placeholder. Its public constructor is empty and does not call the parent constructor. Inherited metadata/components are therefore not initialized by this constructor.
    @note No ability/structure gameplay behavior is implemented here. The structure class's actual declared name is CoGStructure (as spelled in source).
!]]
return class("CoGStructure",
{--METAMETHODS

},
{--STATIC PUBLIC
    --CoGStructure = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    --[[!
        @fqxn CoG.StructureSystem.CoGStructure.Methods.CoGStructure
        @pulsarlua function CoGStructure
        @desc Empty placeholder constructor. Accepts no user arguments and performs no CoGObject initialization.
    !]]
    CoGStructure = function(this, cdat)

    end,
},
CoGObject,  --extending class
false,       --if the class is final (or (if a table is provided) limited to certain subclasses)
nil          --interface(s) (either nil, or interface(s))
);

--[[!
    @fqxn CoG.StructureSystem.CoGStructure.InheritedCoGObject
    @inheritdoc CoG.CoGObject
!]]
