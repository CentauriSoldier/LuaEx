--TODO add option to get and print TODO, BUG, etc.

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


--[[*
    @module Dox
    @name DoxLanguage
*]]
local DoxLanguage = class("DoxLanguage",
{--metamethods

},
{--static public

},
{--private
    name            = "",
    fileTypes       = SortedDictionary(),
    commentOpen     = "",
    commentClose    = "",
    escapeCharacter = "",
},
{--protected

},
{--public
    DoxLanguage = function(this, cdat, sName, tFileTypes, sCommentOpen, sCommentClose, sEscapeCharacter)
        type.assert.string(sName,               "%S+");
        type.assert.table(tFileTypes,           "number", "string", 1);
        type.assert.string(sCommentOpen,        "%S+");
        type.assert.string(sCommentClose,       "[^\n]+");
        type.assert.string(sEscapeCharacter,    "%S+");

        local pri           = cdat.pri;
        pri.name            = sName;
        for _, sType in pairs(tFileTypes) do
            pri.fileTypes.add(sType); --TODO format this uniformly
        end
        pri.commentOpen     = sCommentOpen;
        pri.commentClose    = sCommentClose;
        pri.escapeCharacter = sEscapeCharacter;
    end,
    getCommentClose = function(this, cdat)
        return cdat.pri.commentClose;
    end,
    getCommentOpen = function(this, cdat)
        return cdat.pri.commentOpen;
    end,
    getEscapeCharater = function(this, cdat)
        return cdat.pri.escapeCharacter;
    end,
    getFileTypes = function(this, cdat)
        return clone(cdat.pri.fileTypes);
    end,
    getName = function(this, cdat)
        return cdat.pri.name;
    end,
},
nil,    --extending class
true,   --if the class is final
nil    --interface(s) (either nil, or interface(s))
);

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

--these block tags must exist each block (and in subclasses' input block tags)
local _tRequiredBlockTags = {
    DoxBlockTag({"fqxn"}, "FQXN", 1, true, false),
};

local DoxBlock = class("DoxBlock",
{--METAMETHODS

},
{--STATIC PUBLIC

},
{--PRIVATE
    --parseBlock
    --type        = "",
},
{--PROTECTED

},
{--PUBLIC
    DoxBlock = function(this, cdat, tBlockItems, tRequiredBlockTags)
        type.assert.table(tBlockItems, "number", "string", 1);

        local pri       = cdat.pri;



        --print(serialize(tBlockItems))


    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);

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
    MIME         = enum("MIME", {"HTML", "MARKDOWN", "TXT"}, {"html", "MD", "txt"}, true),
    LANGUAGE     = eDoxLanguage,
},
{--private
    blockOpen           = "",
    blockClose          = "",
    blockTags           = {},
    blockStrings        = {};
    finalized           = {}; --this is the final, processed data (updated using the refresh() method)
    language            = null,
    modules             = SortedDictionary(), --module objects indexed (and sorted) by name
    name                = "",
    requiredBlockTags   = {},
    snippetClose        = "",
    snippetOpen         = "", --TODO add snippet info DO NOT ALLOW USER TO SET/GET THIS
    --Start 	= "##### START DOX [SUBCLASS NAME] SNIPPETS -->>> ID: ",
    --End 	= "#####   <<<-- END DOX [SUBCLASS NAME] SNIPPETS ID: ",
    tagOpen             = "",
    --[[!
    @fqxn LuaEx.Classes.Dox.Methods.extractBlockStrings
    @desc Extracts Dox comment blocks from a string input and stores them for later processing.
    @par string sInput The string from which the comment blocks should be extracted.
    !]]
    extractBlockStrings = function(this, cdat, sInput)
        --local tBlockStrings         = {};
        local pri                   = cdat.pri;
        local fTrim                 = string.trim;
        local oDoxLanguage          = pri.language.value;
        local sOpenPrefix           = oDoxLanguage.getCommentOpen();
        local sCloseSuffix          = oDoxLanguage.getCommentClose();
        local sBlockOpen            = pri.blockOpen;
        local sBlockClose           = pri.blockClose;

        local sPattern = escapePattern(sOpenPrefix..sBlockOpen).."(.-)"..escapePattern(sBlockClose..sCloseSuffix);
        for sMatch in sInput:gmatch(sPattern) do
            local sBlock = fTrim(sMatch);

            if not (pri.blockStrings[sBlock]) then
                pri.blockStrings[sBlock] = true;
            end

        end

    end,
    getBlockTagForAlias = function(this, cdat, sAlias)
        local oRet;

        for _, oBlockTag in pairs(cdat.pri.blockTags) do

            if oBlockTag.hasAlias(sAlias) then
                oRet = oBlockTag;
                break;
            end

        end

        return oRet;
    end,
    parseBlockString = function(this, cdat, sRawBlock)
        local tRet = {};
        local pri              = cdat.pri;
        local sTempAtSymbol    = "DOXAtSymbole7fa52f71cfe48298a9ad784026556fb";
        local tBlockStrings    = pri.blockStrings;
        local sTagOpen         = pri.tagOpen;
        local sEscapedTagOpen  = pri.language.value.getEscapeCharater()..sTagOpen;

        --TODO account for new lines (delete unescaped ones)
        --process raw string blocks

        --replace the escaped @ symbols temporarily
        local sBlock = sRawBlock:gsub(sEscapedTagOpen, sTempAtSymbol);

        --break the block up into items
        local tBlockItems = sBlock:totable(sTagOpen)

        if not (tBlockItems) then
            error("Error parsing Dox block string: malformed block:\n'"..sBlock.."'");
        end

        --iterate over each block item
        for nItemIndex, sRawItem in pairs(tBlockItems) do
            --replace the @ symbols and trim trailing space
            local sItemInProcess = sRawItem:gsub(sTempAtSymbol:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"), sTagOpen):gsub("%s+$", "");--gsub("\n$", "");
            local sItem = sItemInProcess:match("%S.*%S");

            if not (sItem) then --validate the item is still good
                error("Error parsing Dox block string: malformed block item:\n'"..sItem.."'\n\nIn block string:\n'"..sBlock.."'");
            end

            local sAlias = sItem:match("%S+"); --get the alias

            if not (sAlias) then --validate the item alias
                error("Error parsing Dox block string: malformed block item:\n'"..sItem.."'\n\nIn block string:\n'"..sBlock.."'");
            end

            local oBlockTag = pri.getBlockTagForAlias(sAlias); --get the BlockTag object associated with the item

            if not (oBlockTag) then --make sure a BlockTag object was recovered
                error("Error parsing Dox block string:: invalid block item alias, '"..sAlias.."', in item:\n'"..sItem.."'\n\nIn block string:\n'"..sBlock.."'");
            end

            tRet[#tRet + 1] = {
                item            = sItem,
                blockTagObject  = oBlockTag,
            };
        end

        --print(serialize(tRet))
        return tRet;
    end,
    --[[!
    @desc Refreshes the finalized data
    !]]
    refresh = function(this, cdat)
        local pri = cdat.pri;

        for sBlock, _ in pairs(pri.blockStrings) do
            local pri = cdat.pri;

            --reset the finalized data table
            pri.finalized = {};

            --get the block data
            local tBlockData = pri.parseBlockString(sBlock);
            print((tBlockData))
            for _, oBlockTag in ipairs(pri.blockTags) do

            --ensure that all required tags are present
            --TODO LEFT OFF HERE
            end

        end

    end,
},
{},--protected
{--public
    Dox = function(this, cdat, sName, sBlockOpen, sBlockClose, sTagOpen, eLanguage, ...)
        type.assert.string(sName,       "%S+", "Dox subclass name must not be blank.");
        type.assert.string(sBlockOpen,  "%S+", "Block Open symbol must not be blank.");
        type.assert.string(sBlockClose, "%S+", "Block Close symbol must not be blank.");
        type.assert.string(sTagOpen,    "%S+", "Tag Open symbol must not be blank.");
        type.assert.custom(eLanguage,   "DoxLanguage");
        --type.assert.table(tfileTypes, "number", "string", 1);
--"DoxLua", "!", "!", "@", eLanguage,
        local pri               = cdat.pri;
        pri.blockOpen           = sBlockOpen;
        pri.blockClose          = sBlockClose;
        --pri.fileTypes           = Set();
        --TODO add mime types from language
        pri.language            = eLanguage;
        pri.name                = sName;
        pri.tagOpen             = sTagOpen;
        pri.requiredBlockTags   = {};

        --import all Dox-required BlockTags
        for _, oBlockTag in ipairs(_tRequiredBlockTags) do
            table.insert(pri.requiredBlockTags, clone(oBlockTag));
            table.insert(pri.blockTags, oBlockTag);
        end

        --store all input BlockTags and log required ones found
        for nIndex, oBlockTag in ipairs({...} or arg) do
            --validate the type
            type.assert.custom(oBlockTag, "DoxBlockTag");

            --search for required blocktags conflicts
            for _, oRequiredBlockTag in pairs(pri.requiredBlockTags) do

                for sAlias in oRequiredBlockTag.aliases() do

                    if ( oBlockTag.hasAlias(sAlias) ) then
                        error(  "Error creating Dox subclass, '${subclass}'.\nRequired alias, '${alias}', cannot be overriden or duplicated." %
                                {subclass = sName, alias = sAlias}, 2);
                    end

                end

            end

            --store the block tag
            table.insert(pri.blockTags, oBlockTag);

            --if the BlockTag is required, store it
            if (oBlockTag.isRequired()) then
                table.insert(pri.requiredBlockTags, oBlockTag);
            end

        end

        --TODO FIX check for duplicate aliases in all block tags...only one specific alias may exist in any block tag

    end,
    addFileType_FNL = function(this, cdat, sType)
        type.assert.string(sType,    "%S+", "Mime type must not be blank.");
        cdat.pri.fileTypes.add(sType);
    end,
    export_FNL = function(this, cdat, pDir, eMimeType, bPulsar)


    end,
    getBlockTagGroup_FNL = function(this, cdat)
        return cdat.pri.blockTagGroup;
    end,
    getName_FNL = function(this, cdat)
        return cdat.pri.name;
    end,
    getBlockClose_FNL = function(this, cdat)
        return cdat.pri.blockClose;
    end,
    getBlockOpen_FNL = function(this, cdat)
        return cdat.pri.blockOpen;
    end,
    getTagOpen_FNL = function(this, cdat)
        return cdat.pri.tagOpen;
    end,
    importDirectory_FNL = function(this, cdat, pDir, bRecursion)
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
    importFile_FNL = function(this, cdat, pFile)
        type.assert.string(pFile, "%S+");
        local hFile = io.open(pFile, "r");

        if not (hFile) then
            error("Error importing file to Dox.\nCould not open file: "..pFile);
        else
            local sContent = hFile:read("*all");
            cdat.pub.importString(sContent);
            --cdat.pri.extractBlockStrings(sContent);
            hFile:close();
        end

    end,
    importString_FNL = function(this, cdat, sInput)
        type.assert.string(sInput);
        cdat.pri.extractBlockStrings(sInput);

        cdat.pri.refresh();
    end,
    fileTypes_FNL = function(this, cdat)--TODO should I clone the set? probably/
        return cdat.pri.fileTypes;
    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
