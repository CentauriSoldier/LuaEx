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
        local fBlockTagGroup    = DoxBlockTagGroup;
        local eLanguage         = Dox.LANGUAGE.LUA;
        local bRequired         = true;
        local bMultipleAllowed  = true;
        local bIsModule         = true;

        --create the module block fence group
        local oModuleBlockTagGroup = fBlockTagGroup("Module", "Modules", bIsModule, eLanguage, "*", "*",
            fBlockTag({"authors"},                        "Authors",          1,  bRequired,    -bMultipleAllowed),
            fBlockTag({"copy", "copyright"},              "Copyright",        1,  bRequired,    -bMultipleAllowed),
            fBlockTag({"depend", "dependencies"},         "Dependencies",     1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"email"},                          "Email",            1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"fb", "facebook"},                 "Facebook",         1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"features"},                       "Features",         1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"github"},                         "GitHub",           1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"license"},                        "License",          1,  bRequired,    -bMultipleAllowed),
            fBlockTag({"des", "desc", "description"},     "Description",      1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"module"},                         "Module",           1,  bRequired,    -bMultipleAllowed),
            fBlockTag({"name"},                           "Name",             1,  bRequired,    -bMultipleAllowed),
            fBlockTag({"planned"},                        "Planned Features", 1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"todo"},                           "TODO",             1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"use", "usage"},                   "Usage",            1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"ver", "version"},                 "Version",          1,  bRequired,    -bMultipleAllowed),
            fBlockTag({"verhistory", "versionhistory"},   "Version History",  1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"www", "web", "website"},          "Website",          1,  -bRequired,   -bMultipleAllowed),
            fBlockTag({"x", "twitter"},                   "X (Twitter)",      1,  -bRequired,   -bMultipleAllowed));

        --create the function block fence group
        local oFunctionBlockTagGroup = fBlockTagGroup("Function",    "Functions", -bIsModule, eLanguage, "f!",   "!f",
            fBlockTag({"des", "desc", "description"},    "Description",   1,  bRequired,   -bMultipleAllowed),
            fBlockTag({"ex", "example", "examples"},     "Example",       1, -bRequired,   bMultipleAllowed),
            fBlockTag({"module"},                        "Module",        1,  bRequired,   -bMultipleAllowed),
            fBlockTag({"name"},                          "Name",          2,  bRequired,   -bMultipleAllowed),
            fBlockTag({"parameter", "param"},            "Parameter",     2, -bRequired,   bMultipleAllowed),
            fBlockTag({"return", "ret",},                "Return",        2, -bRequired,   bMultipleAllowed),
            fBlockTag({"scope"},                         "Scope",         1,  bRequired,   -bMultipleAllowed),
            fBlockTag({"usage", "use"},                  "Usage",         1, -bRequired,   bMultipleAllowed));

            local oClassBlockTagGroup = fBlockTagGroup("Class",    "Classes", -bIsModule, eLanguage, "c!",   "!c",
                fBlockTag({"des", "desc", "description"},    "Description",   1,  bRequired,   -bMultipleAllowed),
                fBlockTag({"ex", "example", "examples"},     "Example",       1, -bRequired,   bMultipleAllowed),
                fBlockTag({"module"},                        "Module",        1,  bRequired,   -bMultipleAllowed),
                fBlockTag({"name"},                          "Name",          2,  bRequired,   -bMultipleAllowed),
                fBlockTag({"parent"},                        "Parameter",     2, -bRequired,   -bMultipleAllowed),
                fBlockTag({"interface"},                     "Return",        2, -bRequired,   bMultipleAllowed),
                fBlockTag({"scope"},                         "Scope",         1,  bRequired,   -bMultipleAllowed),
                fBlockTag({"usage", "use"},                  "Usage",         1, -bRequired,   bMultipleAllowed));
        --TODO enums, class, constants, arrays, etc. block tag groups
        --local oArrayBlockTagGroup       = fBlockTagGroup("Array",       "Arrays",       "--[[a!", "!a]]", nil);
        --local oClassBlockTagGroup       = fBlockTagGroup("Class",       "Classes",      "--[[o!", "!o]]", nil); WTF would this not be modules?
        --local oConstantBlockTagGroup    = fBlockTagGroup("Constant",    "Constants",    "--[[c!", "!c]]", nil);
        --local oEnumBlockTagGroup        = fBlockTagGroup("Enum",        "Enums",        "--[[e!", "!e]]", nil);

        --combine the block tag groups into a table for the super call



        super("DoxLua", "@", eLanguage, oModuleBlockTagGroup, oFunctionBlockTagGroup);
    end,
},
Dox,    --extending class
true,    --if the class is final
nil    --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
);
