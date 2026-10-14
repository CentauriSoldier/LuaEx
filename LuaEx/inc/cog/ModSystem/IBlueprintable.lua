--[[!
    @fqxn CoG.ModSystem.Interfaces.IBlueprintable
    @desc Declares the public static blueprint validation and construction
    methods. Participating classes also declare a Blueprint defaults table,
    which Factorium checks during registerClass. Factorium enforces validation;
    callers invoke the class factory themselves to create objects.
!]]
return interface("IBlueprintable",
{--metamethods

},
{--static public
    -- Factorium calls this with a completed definition copy. Return true or
    -- false, reason; each participating ancestor's validator must also pass.
    "validateBlueprint",
    -- The caller supplies a definition and optional runtime context. Object
    -- construction stays in the class; the repository never calls this method.
    "fromBlueprint",

},
{--private

},
{--protected

},
{--public

},
nil    --extending interface
);
