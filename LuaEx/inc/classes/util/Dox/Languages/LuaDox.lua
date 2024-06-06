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
    LuaDox = function(this, cdat, super)
        local fBlockTag         = DoxBlockTag;
        local eLanguage         = Dox.LANGUAGE.LUA;
        local bRequired         = true;
        local bMultipleAllowed  = true;


        --TODO enums, class, constants, arrays, etc. block tag groups
        --local oArrayBlockTagGroup       = fBlockTagGroup("Array",       "Arrays",       "--[[a!", "!a]]", nil);
        --local oClassBlockTagGroup       = fBlockTagGroup("Class",       "Classes",      "--[[o!", "!o]]", nil); WTF would this not be modules?
        --local oConstantBlockTagGroup    = fBlockTagGroup("Constant",    "Constants",    "--[[c!", "!c]]", nil);
        --local oEnumBlockTagGroup        = fBlockTagGroup("Enum",        "Enums",        "--[[e!", "!e]]", nil);

        super(  "DoxLua", "!", "!", "@", eLanguage,
                fBlockTag({"parameter", "param", "par"},        "Parameter",            3,  -bRequired,     bMultipleAllowed),
                fBlockTag({"scope"},                            "Scope",                1,  bRequired,      -bMultipleAllowed),
                fBlockTag({"des", "desc", "description"},       "Description",          1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"features"},                         "Features",             1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"parent"},                           "Parent",               1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"interface"},                        "Interface",            1,  -bRequired,     bMultipleAllowed),
                fBlockTag({"depend", "dependency"},             "Dependency",           1,  -bRequired,     bMultipleAllowed),
                fBlockTag({"ex", "example", "examples"},        "Example",              1,  -bRequired,     bMultipleAllowed),
                fBlockTag({"planned"},                          "Planned Features",     1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"todo"},                             "TODO",                 1,  -bRequired,     bMultipleAllowed),
                fBlockTag({"changelog"},                        "Changelog",            1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"author"},                           "Author",               1,  -bRequired,     bMultipleAllowed),
                fBlockTag({"email"},                            "Email",                1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"license"},                          "License",              1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"www", "web", "website"},            "Website",              1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"github"},                           "GitHub",               1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"fb", "facebook"},                   "Facebook",             1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"x", "twitter"},                     "X (Twitter)",          1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"copy", "copyright"},                "Copyright",            1,  -bRequired,     -bMultipleAllowed),
                fBlockTag({"return", "ret",},                   "Return",               2,  -bRequired,     bMultipleAllowed)
        );
    end,
},
Dox,    --extending class
true,    --if the class is final
nil    --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
);
