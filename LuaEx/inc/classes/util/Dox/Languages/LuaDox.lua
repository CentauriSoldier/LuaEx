return class("LuaDox",
{--metamethods

},
{--static public

},
{--private

},
{--protected

},
{--public
    LuaDox = function(this, cdat, super, sTitle)
        local fBlockTag         = DoxBlockTag;
        local eLanguage         = Dox.LANGUAGE.LUA;
        local bRequired         = true;
        local bMultipleAllowed  = true;

        type.assert.string(sTitle, "%S+", "Dox documentation title name must not be blank.");

        --TODO enums, class, constants, arrays, etc. block tag groups
        --local oArrayBlockTagGroup       = fBlockTagGroup("Array",       "Arrays",       "--[[a!", "!a]]", nil);
        --local oClassBlockTagGroup       = fBlockTagGroup("Class",       "Classes",      "--[[o!", "!o]]", nil); WTF would this not be modules?
        --local oConstantBlockTagGroup    = fBlockTagGroup("Constant",    "Constants",    "--[[c!", "!c]]", nil);
        --local oEnumBlockTagGroup        = fBlockTagGroup("Enum",        "Enums",        "--[[e!", "!e]]", nil);
--TODO move most of these inside dox as most languages could use them
        super("LuaDox", sTitle, "!", "!", "@", eLanguage);
    end,
},--TODO ability to get sort order
Dox,    --extending class
true,    --if the class is final
nil    --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
);
