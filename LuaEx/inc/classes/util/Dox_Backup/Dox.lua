--OMG use queues for output
--[[TODO
    Use MD for text
    Allow internal anchor links
    Allow external links
]]

local assert    = assert;
local class     = class;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local type      = type;

--TODO consider moving this to its own file and creating the enum using a static initializer
local eDoxLanguage = enum("DoxLanguage",
{
"ADA",          "ASSEMBLY_NASM",    "C",        "C_SHARP",      "C_PLUS_PLUS",
"CSS",          "DART",             "ELM",      "F_SHARP",      "FORTRAN",
"GO",           "GROOVY",           "HASKELL",  "HTML",         "JAVA",
"JAVASCRIPT",   "JULIA",            "KOTLIN",   "LUA",          "MATLAB",
"OBJECTIVE_C",  "PERL",             "PHP",      "PYTHON",       "RUBY",
"RUST",         "SCALA",            "SWIFT",    "TYPESCRIPT",   "XML"
},
{
DoxLanguage("Ada",              {".adb", ".ads"},                               "--",       "--",   "\\"),
DoxLanguage("Assembly (NASM)",  {".asm", ".s"},                                 "%{",       "%}",   "\\"),
DoxLanguage("C",                {".c", ".h"},                                   "/*",       "*/",   "\\"),
DoxLanguage("C#",               {".cs"},                                        "/*",       "*/",   "\\"),
DoxLanguage("C++",              {".cpp", ".cxx", ".cc", ".h", ".hh", ".hpp"},   "/*",       "*/",   "\\"),
DoxLanguage("CSS",              {".css"},                                       "/*",       "*/",   "\\"),
DoxLanguage("Dart",             {".dart"},                                      "/*",       "*/",   "\\"),
DoxLanguage("Elm",              {".elm"},                                       "{-",       "-}",   "\\"),
DoxLanguage("F#",               {".fs"},                                        "(*",       "*)",   "\\"),
DoxLanguage("Fortran",          {".f90"},                                       "!",        "\\n",  "\\"),
DoxLanguage("Go",               {".go"},                                        "/*",       "*/",   "\\"),
DoxLanguage("Groovy",           {".groovy"},                                    "/*",       "*/",   "\\"),
DoxLanguage("Haskell",          {".hs"},                                        "{-",       "-}",   "\\"),
DoxLanguage("HTML",             {".html"},                                      "<!--",     "-->",  "\\"),
DoxLanguage("Java",             {".java"},                                      "/*",       "*/",   "\\"),
DoxLanguage("JavaScript",       {".js"},                                        "/*",       "*/",   "\\"),
DoxLanguage("Julia",            {".jl"},                                        "#=",       "=#",   "\\"),
DoxLanguage("Kotlin",           {".kt", ".kts"},                                "/*",       "*/",   "\\"),
DoxLanguage("Lua",              {".lua"},                                       "--[[",     "]]",   "\\"),
DoxLanguage("Matlab",           {".m"},                                         "%{",       "%}",   "\\"),
DoxLanguage("Objective-C",      {".m", ".h"},                                   "/*",       "*/",   "\\"),
DoxLanguage("Perl",             {".pl", ".pm"},                                 "=pod",     "=cut", "\\"),
DoxLanguage("PHP",              {".php"},                                       "/*",       "*/",   "\\"),
DoxLanguage("Python",           {".py"},                                        '"""',      '"""',  "\\"),
DoxLanguage("Ruby",             {".rb"},                                        "=begin",   "=end", "\\"),
DoxLanguage("Rust",             {".rs"},                                        "/*",       "*/",   "\\"),
DoxLanguage("Scala",            {".scala"},                                     "/*",       "*/",   "\\"),
DoxLanguage("Swift",            {".swift"},                                     "/*",       "*/",   "\\"),
DoxLanguage("TypeScript",       {".ts"},                                        "/*",       "*/",   "\\"),
DoxLanguage("XML",              {".xml"},                                       "<!--",     "-->",  "\\"),
},
true);

--these block tags must exist within each dox block tag group and each block
local tRequiredNames = {
    [1] = "module",
    [2] = "name",
};

local tRequiredNamesMeta = {
    __call = function(__IGNORE__)
        local nIndex    = 0;
        local nMax      = #tRequiredNames;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return nIndex, tRequiredNames[nIndex];
            end

        end

    end,
    __len = function(__IGNORE__)
        return #tRequiredNames;
    end,
    __unm = function()
        local tRet = {};

        for nIndex, sName in pairs(tRequiredNames) do
            tRet[nIndex] = false;
        end

        return tRet;
    end,
    __index = function(t, k)
        error("Error accessing Dox.RequiredNames table.\nTo get a list of required names, use unary minus (__unm) metamethod.\nTo iterate over the list of names, call the table.", 3);
    end,
    __newindex = function(t, k, v)
        error("Attempt to modify read-only Dox.RequiredNames table.", 3);
    end,
};

--[[f!
    @mod dox
    @func escapePattern
    @desc Escapes special characters in a string so it can be used in a Lua pattern match.
    @param pattern A string containing the pattern to be escaped.
    @ret Returns the escaped string with special characters prefixed by a `%`.
!f]]
local function escapePatternOLD(pattern)
    return pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

local function escapePattern(pattern)
    -- Escape special characters in the pattern
    local escapedPattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")

    -- Remove leading and trailing whitespace from the escaped pattern
    escapedPattern = escapedPattern:gsub("^%s*(.-)%s*$", "%1")

    return escapedPattern
end

--[[
██████╗  ██████╗ ██╗  ██╗
██╔══██╗██╔═══██╗╚██╗██╔╝
██║  ██║██║   ██║ ╚███╔╝
██║  ██║██║   ██║ ██╔██╗
██████╔╝╚██████╔╝██╔╝ ██╗
╚═════╝  ╚═════╝ ╚═╝  ╚═╝]]
return class("Dox",
{--metamethods
    __tostring = function()
        --TODO this should display the open/close stuff +
    end,
},
{--static public
    MIME = enum("MIME", {"HTML", "MARKDOWN", "TXT"}, {"html", "MD", "txt"}, true),
    LANGUAGE = eDoxLanguage,
    RequiredNames = rawsetmetatable({}, tRequiredNamesMeta),
},
{--private
    blockTagGroups      = {}, --this contains groups of block tags group objects
    moduleBlockTagGroup = null,
    language            = null,
    --fileTypes           = null, --set by the language
    modules             = SortedDictionary(), --module objects indexed (and sorted) by name
    orphanBlocks        = {},
    name                = "",
    snippetClose        = "", --QUESTION How will this work now that we're using mutiple tag groups?
    snippetOpen         = "", --TODO add snippet info DO NOT ALLOW USER TO SET/GET THIS
    --Start 	= "##### START DOX [SUBCLASS NAME] SNIPPETS -->>> ID: ",
    --End 	= "#####   <<<-- END DOX [SUBCLASS NAME] SNIPPETS ID: ",
    tagOpen             = "",
    --toprocess           = {}, --this is a holding table for strings which need to be parsed for blocks
    buildBlocks = function(this, cdat, tModuleBlockStrings, tBlockStrings)
        local tModuleBlocks    = {};
        local tBlocks          = {};
        local sTempAtSymbol    = "DOXAtSymbole7fa52f71cfe48298a9ad784026556fb";
        local sTagOpen         = cdat.pri.tagOpen;
        local sEscapedTagOpen  = cdat.pri.language.value.getEscapeCharater()..sTagOpen;
        print(sEscapedTagOpen)
        --module blocks
        for sModuleTypeName, tModule in pairs(tModuleBlockStrings) do

            for nIndex, sBlock in pairs(tModule) do
                --replace the escaped @ symbols temporarily
                sBlock = sBlock:gsub(sEscapedTagOpen, sTempAtSymbol);

                --break the
                local tRawBlock = sBlock:totable(sTagOpen);

                for k, v in pairs(tRawBlock) do
                    --print(k, v)
                end
            end

        end
--TODO account for new lines (delete unescaped ones)
        --non-module blocks
        for _, tBlockTypes in pairs(tBlockStrings) do

            for sBlockType, tRawBlocks in pairs(tBlockTypes) do

                --print(sBlockType, serialize(tRawBlocks))
                for __, sRawBlock in pairs(tRawBlocks) do

                    --replace the escaped @ symbols temporarily
                    local sBlock = sRawBlock:gsub(sEscapedTagOpen, sTempAtSymbol);

                    --break the block up into items
                    local tBlockItems = sBlock:totable(sTagOpen);

                    --replace the @ symbols
                    for nItemIndex, sItem in pairs(tBlockItems) do
                        tBlockItems[nItemIndex] = sItem:gsub(sTempAtSymbol:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"), sTagOpen);
                    end



                    --build the block and add it to the return table
                    table.insert(tBlocks, DoxBlock(sBlockType, tBlockItems));
                end

            end

        end


        --print(serialize(tModuleBlockStrings))
        --print(serialize(tBlockStrings))
        return tBlocks
    end,
    extractBlockStrings = function(this, cdat, sInput)
        local tModuleBlockStrings   = null;
        local tBlockStrings         = {};
        local fTrim                 = string.trim;
        local oModuleBlockTagGroup  = cdat.pri.moduleBlockTagGroup;
        local fBlockTagGroups       = cdat.pub.blockTagGroups;
        local oDoxLanguage          = cdat.pri.language.value;
        local sOpenPrefix           = oDoxLanguage.getCommentOpen();
        local sCloseSuffix          = oDoxLanguage.getCommentClose();

        -- Helper function to extract blocks from input based on open and close tags
        local function extractFenceBlocks(sBlockTagGroupName, sInput, sOpen, sClose)
            local tRet           = {};

            if not (tRet[sBlockTagGroupName]) then
                tRet[sBlockTagGroupName] = {};
            end

            local sPattern = escapePattern(sOpenPrefix..sOpen).."(.-)"..escapePattern(sClose..sCloseSuffix);

            for sMatch in sInput:gmatch(sPattern) do
                table.insert(tRet[sBlockTagGroupName], fTrim(sMatch));
            end

            return tRet;
        end

        -- Extract module blocks
        local sModuleOpen   = oModuleBlockTagGroup.getBlockOpen();
        local sModuleClose  = oModuleBlockTagGroup.getBlockClose();
        tModuleBlockStrings = extractFenceBlocks(oModuleBlockTagGroup:getName(), sInput, sModuleOpen, sModuleClose);

        -- Extract non-module blocks
        for oBlockTagGroup in fBlockTagGroups() do--TODO check that is only 1 DTG!
            local sOpen         = oBlockTagGroup.getBlockOpen();
            local sClose        = oBlockTagGroup.getBlockClose();
            local tGroupBlocks  = extractFenceBlocks(oBlockTagGroup.getName(), sInput, sOpen, sClose);
            table.insert(tBlockStrings, tGroupBlocks);
        end

        --print(serialize(tModuleBlockStrings), serialize(tBlockStrings))
        return tModuleBlockStrings, tBlockStrings;
    end,
    processString = function(this, cdat, sInput)
        local pri                   = cdat.pri;
        local oModules              = pri.modules;
        local oModuleBlockTagGroup  = pri.moduleBlockTagGroup;

        --get all block strings from the input string
        local tModuleBlockStrings, tBlockStrings = pri.extractBlockStrings(sInput);

        --build block objects out of them
        local tModuleBlocks, tBlocks = pri.buildBlocks(tModuleBlockStrings, tBlockStrings);


    end,
},
{},--protected
{--public
    Dox = function(this, cdat, sName, sTagOpen, eLanguage, oModuleBlockTagGroup, ...)
        type.assert.string(sName,    "%S+", "Dox subclass name must not be blank.");
        type.assert.string(sTagOpen, "%S+", "Open tag symbol must not be blank.");
        type.assert.custom(eLanguage, "DoxLanguage");
        type.assert.custom(oModuleBlockTagGroup, "DoxBlockTagGroup");
        --type.assert.table(tfileTypes, "number", "string", 1);

        local pri               = cdat.pri;
        --pri.fileTypes           = Set();
        --TODO add mime types from language
        pri.language            = eLanguage;
        pri.name                = sName;
        pri.tagOpen             = sTagOpen;
        pri.moduleBlockTagGroup = oModuleBlockTagGroup;

        --TODO put block tags in order of display (as input)!
        local tBlockTagGroups = pri.blockTagGroups;

        for _, oBlockTagGroup in pairs({...} or arg) do
            type.assert.custom(oBlockTagGroup, "DoxBlockTagGroup");
            tBlockTagGroups[#tBlockTagGroups + 1] = clone(oBlockTagGroup);
        end

    end,
    addFileType = function(this, cdat, sType)
        type.assert.string(sType,    "%S+", "Mime type must not be blank.");
        cdat.pri.fileTypes.add(sType);
    end,
    blockTagGroups = function(this, cdat)
        local tBlockTagGroups = cdat.pri.blockTagGroups;
        local nIndex            = 0;
        local nMax              = #tBlockTagGroups;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return tBlockTagGroups[nIndex];
            end

        end

    end,
    export = function(this, cdat, pDir, eMimeType, bPulsar)

    end,
    getName = function(this, cdat)
        return cdat.pri.name;
    end,
    getTagOpen = function(this, cdat)
        return cdat.pri.tagOpen;
    end,
    importDirectory = function(this, cdat, pDir, bRecursion)
        type.assert.string(pDir, "%S+");
        local bRecurse = bRecursion;

        if (rawtype(bRecurse) ~= "boolean") then
            bRecurse = false;
        end
        --TODO rewrite this to check for .doxignore files
        local tFiles, tRel = io.dir(pDir, bRecurse, 0, cdat.pri.fileTypes);--TODO BUG FIX CHANGE this to use new mime table
        --TODO THROW ERROR FOR FAILURE
        for k, v in pairs(tFiles) do
            cdat.pub.importFile(v);
        end

    end,
    importFile = function(this, cdat, pFile)
        type.assert.string(pFile, "%S+");
        local hFile = io.open(pFile, "r");

        if not (hFile) then
            error("Error importing file to Dox.\nCould not open file: "..pFile);
        else
            local sContent = hFile:read("*all");
            cdat.pri.processString(sContent);
            hFile:close();
        end

    end,
    importString = function(this, cdat, sInput)
        type.assert.string(sInput);
        cdat.pri.processString(sInput);
    end,
    fileTypes = function(this, cdat)--TODO should I clone the set? probably/
        return cdat.pri.fileTypes;
    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
