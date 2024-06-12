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

        super(  "DoxLua", sTitle, "!", "!", "@", eLanguage,
                fBlockTag({"parameter", "param", "par"},        "Parameter",            -bRequired,     bMultipleAllowed),
                fBlockTag({"scope"},                            "Scope",                -bRequired,     -bMultipleAllowed),--TODO make not reqwuired afte testing
                fBlockTag({"des", "desc", "description"},       "Description",          -bRequired,     -bMultipleAllowed),
                fBlockTag({"features"},                         "Features",             -bRequired,     -bMultipleAllowed),
                fBlockTag({"parent"},                           "Parent",               -bRequired,     -bMultipleAllowed),
                fBlockTag({"interface"},                        "Interface",            -bRequired,     bMultipleAllowed),
                fBlockTag({"depend", "dependency"},             "Dependency",           -bRequired,     bMultipleAllowed),
                fBlockTag({"ex", "example", "examples"},        "Example",              -bRequired,     bMultipleAllowed),
                fBlockTag({"planned"},                          "Planned Features",     -bRequired,     -bMultipleAllowed),
                fBlockTag({"todo"},                             "TODO",                 -bRequired,     bMultipleAllowed),
                fBlockTag({"changelog"},                        "Changelog",            -bRequired,     -bMultipleAllowed),
                fBlockTag({"author"},                           "Author",               -bRequired,     bMultipleAllowed),
                fBlockTag({"email"},                            "Email",                -bRequired,     -bMultipleAllowed),
                fBlockTag({"license"},                          "License",              -bRequired,     -bMultipleAllowed),
                fBlockTag({"www", "web", "website"},            "Website",              -bRequired,     -bMultipleAllowed),
                fBlockTag({"github"},                           "GitHub",               -bRequired,     -bMultipleAllowed),
                fBlockTag({"fb", "facebook"},                   "Facebook",             -bRequired,     -bMultipleAllowed),
                fBlockTag({"x", "twitter"},                     "X (Twitter)",          -bRequired,     -bMultipleAllowed),
                fBlockTag({"copy", "copyright"},                "Copyright",            -bRequired,     -bMultipleAllowed),
                fBlockTag({"return", "ret",},                   "Return",               -bRequired,     bMultipleAllowed)
        );
    end,
},--TODO ability to get sort order
Dox,    --extending class
true,    --if the class is final
nil    --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
);
