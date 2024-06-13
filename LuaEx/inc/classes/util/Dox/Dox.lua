--TODO add option to get and print TODO, BUG, etc.

--OMG use queues for output
--[[TODO
    Use MD for text
    Allow internal anchor links
    Allow external links
]]
function getsourcepath()
    --determine the call location
    local sPath = debug.getinfo(1, "S").source;
    --remove the calling filename
    local sFilenameRAW = sPath:match("^.+"..package.config:sub(1,1).."(.+)$");
    --make a pattern to account for case
    local sFilename = "";
    for x = 1, #sFilenameRAW do
        local sChar = sFilenameRAW:sub(x, x);

        if (sChar:find("[%a]")) then
            sFilename = sFilename.."["..sChar:upper()..sChar:lower().."]";
        else
            sFilename = sFilename..sChar;
        end

    end
    sPath = sPath:gsub("@", ""):gsub(sFilename, "");
    --remove the "/" at the end
    sPath = sPath:sub(1, sPath:len() - 1);

    return sPath;
end

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


local eOutputType = enum("DoxOutput", {"HTML", "MD"});

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
    DoxBlockTag({"fqxn"}, "FQXN", true, false),
};

local DoxBlock = class("DoxBlock",
{--METAMETHODS

},
{--STATIC PUBLIC

},
{--PRIVATE
    columns = 1,
    fqxn    = {};
    items   = {},
    getBlockTagForAlias = function(this, cdat, tBlockTags, sAlias)
        local oRet;

        for _, oBlockTag in pairs(tBlockTags) do

            if oBlockTag.hasAlias(sAlias) then
                oRet = oBlockTag;
                break;
            end

        end

        return oRet;
    end,
    getBlockData = function(this, cdat, sRawBlock, eLanguage, sTagOpen, tBlockTags)
        local pri   = cdat.pri;
        local tRet  = {};
        local sTempAtSymbol      = "DOXAtSymbole7fa52f71cfe48298a9ad784026556fb";
        local sEscapedTagOpen    = eLanguage.value.getEscapeCharater()..sTagOpen;

        --TODO account for new lines (delete unescaped ones)
        --replace the escaped @ symbols temporarily
        local sBlock = sRawBlock:gsub(sEscapedTagOpen, sTempAtSymbol);

        --break the block up into items
        local tBlockItems = sBlock:totable(sTagOpen);

        if not (tBlockItems) then
            error("Error creating DoxBlock object: malformed block:\n'"..sBlock.."'", 3);
        end

        --iterate over each block item
        for nItemIndex, sRawItem in ipairs(tBlockItems) do
            --replace the @ symbols and trim trailing space
            local sItemInProcess = sRawItem:gsub(sTempAtSymbol:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"), sTagOpen):gsub("%s+$", "");--gsub("\n$", "");
            local sItem = sItemInProcess:match("%S.*%S");

            --validate the item is still good
            if not (sItem) then
                error("Error creating DoxBlock object: malformed block item:\n'"..sItem.."'\n\nIn block string:\n'"..sBlock.."'", 3);
            end

            --get the alias
            local sAlias = sItem:match("%S+");

            --validate the item alias
            if not (sAlias) then
                error("Error creating DoxBlock object: malformed block item:\n'"..sItem.."'\n\nIn block string:\n'"..sBlock.."'", 3);
            end

            --get the BlockTag object associated with the item
            local oBlockTag = pri.getBlockTagForAlias(tBlockTags, sAlias);

            --make sure a BlockTag object was recovered
            if not (oBlockTag) then
                error("Error creating DoxBlock object: invalid block item alias, '"..sAlias.."', in item:\n'"..sItem.."'\n\nIn block string:\n'"..sBlock.."'", 3);
            end

            tRet[#tRet + 1] = {
                item            = sItem,
                blockTagObject  = oBlockTag,
            };
        end

        return tRet;
    end
},
{--PROTECTED

},
{--PUBLIC
    DoxBlock = function(this, cdat, sRawBlock, eLanguage, sTagOpen, tBlockTags, tRequiredBlockTags)
        local pri                = cdat.pri;
        type.assert.string(sRawBlock, "%S+", "Dox blockstring must not be blank.");
        --TODO asserts? Or, since this is internal, should I trust the input? Probably not.

        local tBlockData = pri.getBlockData(sRawBlock, eLanguage, sTagOpen, tBlockTags);

        --create a table for tracking required block tags found
        local tRequiredBlockTagsFound = {};
        for _, oBlockTag in pairs(tRequiredBlockTags) do
            tRequiredBlockTagsFound[oBlockTag] = false;--true if not found
        end

        --keeps track of block tag count
        local tBlockTagCounts = {};

        --process the block data
        for _, tLineData in ipairs(tBlockData) do
            local sRawItem      = tLineData.item;
            local oItemBlockTag = tLineData.blockTagObject;
            --log required block tags found
            for __, oRequiredBlockTag in pairs(tRequiredBlockTags) do

                if (oItemBlockTag == oRequiredBlockTag) then
                    --set as found
                    tRequiredBlockTagsFound[oRequiredBlockTag] = true;
                end
                break;

            end

            --log block tag count
            if not (tBlockTagCounts[oItemBlockTag]) then
                tBlockTagCounts[oItemBlockTag] = 0;
            end
            tBlockTagCounts[oItemBlockTag] = tBlockTagCounts[oItemBlockTag] + 1;

            --split the string into tag and contents
            local sTag, sContent = sRawItem:match("([^%s]*)%s(.*)");
            type.assert.string(sContent, "%S+", "Dox BlockTag content cannot be blank must not be blank.\n"..tostring(oItemBlockTag).."\n\nIn Block:\n"..sRawBlock);

            --store the content
            if (oItemBlockTag.getDisplay() == "FQXN") then

                local tFQXN = sContent:totable('.');

                if not (tFQXN) then
                    error("Error creating DoxBlock: invalid FQXN\n"..tostring(oItemBlockTag).."\n\nIn Block:\n"..sRawBlock, 3);
                end

                pri.fqxn = tFQXN;
            else
                table.insert(pri.items, {
                    blockTag    = oItemBlockTag,
                    content     = sContent,
                });
            end

        end

        --make sure all required block tags were found in the block
        for oBlockTag, bBlockTagFound in pairs(tRequiredBlockTagsFound) do

            if not (bBlockTagFound) then
                error("Error creating DoxBlock: required block tag missing\n"..tostring(oBlockTag).."\n\nIn Block:\n"..sRawBlock, 3);
            end

        end

        --check for disallowed multiples
        for oBlockTag, nCount in pairs(tBlockTagCounts) do
            if (not oBlockTag.isMultipleAllowed() and nCount > 1) then
                error("Error creating DoxBlock: multiple block tags not permitted: \n"..tostring(oBlockTag).."\n\nIn Block:\n"..sRawBlock.."\nTotal count: "..nCount..'.', 3);
            end

        end

    end,
    fqxn = function(this, cdat)
        local tFQXN = cdat.pri.fqxn;
        local nIndex    = 0;
        local nMax      = #tFQXN;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return nIndex == nMax, nIndex, tFQXN[nIndex];
            end

        end

    end,
    item = function(this, cdat, nIndex)
        local tItems = cdat.pri.items;
        local tItem = tItems[nIndex];--TODO error check
        return clone(tItem.blockTag), tItem.content;
    end,
    items = function(this, cdat)
        local tItems = cdat.pri.items;
        local nIndex    = 0;
        local nMax      = #tItems;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                local tItem = tItems[nIndex];
                return clone(tItem.blockTag), tItem.content;
            end

        end

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
    OUTPUT       = eOutputType,
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
    OutputPath_AUTO     = "",
    requiredBlockTags   = {},
    snippetClose        = "",
    snippetOpen         = "", --TODO add snippet info DO NOT ALLOW USER TO SET/GET THIS
    --Start 	= "##### START DOX [SUBCLASS NAME] SNIPPETS -->>> ID: ",
    --End 	= "#####   <<<-- END DOX [SUBCLASS NAME] SNIPPETS ID: ",
    tagOpen             = "",
    title               = "",
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
    --[[!
    @desc Refreshes the finalized data
    !]]
    refresh = function(this, cdat)
        local pri = cdat.pri;
        local tBlocks = {};

        --reset the finalized data table
        pri.finalized   = {};
        local tContent  = {};

        --inject all block strings into finalized data table
        for sRawBlock, _ in pairs(pri.blockStrings) do
            --create the DoxBlock
            local oBlock = DoxBlock(sRawBlock, pri.language, pri.tagOpen,
                                    pri.blockTags, pri.requiredBlockTags);

            local tActive = pri.finalized;

            for bLastItem, nFQXNIndex, sFQXN in oBlock.fqxn() do

                if not (tActive[sFQXN]) then
                    tActive[sFQXN] = {};
                end

                --update the active table variable
                tActive = tActive[sFQXN];

                --create the content string
                --<thead><tr><th>Tag</th><th>Info</th></tr></thead>
                local sOuterContent = [[<div class="container-fluid table-container"><table class="table table-striped"><tbody>]];



                for oBlockTag, sContent in oBlock.items() do
                    sOuterContent = sOuterContent..[[<tr><td>${display}</td><td>${content}</td></tr>]] %
                    {
                        display = oBlockTag.getDisplay(),
                        content = sContent,--TODO breakk up content into columns as needed
                    };
                end

                local sOuterContent = sOuterContent..[[</tbody></table></div>]];

                --TODO gsub last newline

                --store the iterator for the items if last item or false
                --tContent[tActive] = bLastItem and oBlock.items or false;
                tContent[tActive] = sOuterContent;
                --TODO LEFT OFF HERE gotta get items working

                --set the call to get the content
                setmetatable(tActive, {
                    __call = function(t)
                        return tContent[tActive];
                    end,
                })
            end

        end

        --pri.finalized = table.sortalphabetically(pri.finalized);
        --print(serialize(pri.finalized.LuaEx.class.instance.Functions));

    end,
    [eOutputType.HTML.name] = {
        build = function(this, cdat)
            local pri        = cdat.pri;
            local tFunctions = pri[eOutputType.HTML.name];
            local sTitle     = pri.title;
            local pSource    = io.normalizepath(getsourcepath());--TODO trim ending dir sep and dups
            local pCSS       = pSource.."\\Data\\Dox.css";
            local pBanner    = pSource.."\\Data\\Banner.txt";
            local pJS        = pSource.."\\Data\\Dox.js";
            local pHTML      = pSource.."\\Data\\Dox.html";
            local pHTMLOut   = cdat.pri.OutputPath.."\\"..sTitle..".html";--TODO use proper directory separator
            local pJSOut     = cdat.pri.OutputPath.."\\"..sTitle..".js";

            local function readFile(pFile)
                local hFile = io.open(pFile, "r");
                if not hFile then
                    error("Error outputting Dox: File '"..pFile.."' not found.", 3)--TODO nice error message
                end
                local sRet = hFile:read("*all");
                hFile:close();
                return sRet;
            end

            local function writeFile(pFile, sContent)
                local hFile = io.open(pFile, "w");
                if not hFile then
                    error("Error outputting Dox: Can't write to file, '"..pFile.."'.", 3)--TODO nice error message
                end
                hFile:write(sContent)
                hFile:close();
            end

            --read the html and helper files
            local sCSS      = readFile(pCSS);
            local sBanner   = readFile(pBanner);
            local sHTML     = readFile(pHTML);

            --update and write the html
            sHTML = sHTML % {css = sCSS};
            sHTML = sHTML % {
                bannerURL   = sBanner:gsub("\n", ''), --TODO allow custom banner
                title       = sTitle
            };

            --write the html file
            writeFile(pHTMLOut, sHTML);

            --build and write js to file
            local sJS = tFunctions.buildJS(this, cdat);
            writeFile(pJSOut, "const userData = "..sJS);--TODO local global var this string

        end,
        buildJS = function(this, cdat)
            local sRet       = "";
            local pri        = cdat.pri;
            local tFunctions = pri[eOutputType.HTML.name];
            local pSource    = io.normalizepath(getsourcepath());--TODO trim ending dir sep and dups
            local pJS        = pSource.."\\Data\\Dox.js";

            -- Open the input file in read mode
            local hFile = io.open(pJS, "r")
            if not hFile then
                return nil, "Input file not found"--TODO error messages
            end

            local lineNumber    = 0;
            local bFound        = false;

            -- Read the input file line by line
            for line in hFile:lines() do
                lineNumber = lineNumber + 1
                -- Check if the search string is in the current line
                if bFound then
                    sRet = sRet .. line .. "\n"
                elseif string.find(line, "//—©_END_DOX_TESTDATA_©—", 1, true) then --TODO make this a module global var
                    bFound = true
                end
            end

            hFile:close()

            if not bFound then
                return nil, "String not found in the input file"
            end

            local sJSON = tFunctions.buildJSONTable(this, cdat);

            return sJSON.."\n\n"..sRet;
        end,
        buildJSONTable = function(this, cdat) --TODO clean up
            --TODO base64!
            -- Function to escape special characters for JSON
            local function escapeStr(s)
                if type(s) ~= "string" then
                    return ""
                end
                s = s:gsub("\\", "\\\\")
                s = s:gsub('"', '\\"')
                s = s:gsub("\b", "\\b")
                s = s:gsub("\f", "\\f")
                s = s:gsub("\n", "\\n")
                s = s:gsub("\r", "\\r")
                s = s:gsub("\t", "\\t")
                return s
            end

            local function luaTableToJson(tbl, startIndent)
                startIndent = startIndent or 0
                local indentSpace = string.rep(" ", startIndent)

                local function processTable(t, indent)
                    local result = {}
                    local sortedKeys = {}

                    for key in pairs(t) do
                        table.insert(sortedKeys, key)
                    end
                    table.sort(sortedKeys)

                    for _, key in ipairs(sortedKeys) do
                        local subtable = t[key]
                        local value = subtable()
                        local subtableResult = processTable(subtable, indent .. "    ")
                        table.insert(result, string.format(
                            '%s"%s": {\n%s    "value": "%s",\n%s    "subtable": %s\n%s}',
                            indent, key, indent, escapeStr(value), indent, next(subtableResult) and "{\n" .. table.concat(subtableResult, ",\n") .. "\n" .. indent .. "    }" or "null", indent
                        ))
                    end

                    return result
                end

                local jsonResult = processTable(tbl, indentSpace)
                return "{\n" .. table.concat(jsonResult, ",\n") .. "\n" .. indentSpace .. "}"
            end

            -- Convert the Lua table to JSON format
            local nIndentSpaces = 4;
            return luaTableToJson(cdat.pri.finalized, nIndentSpaces);
        end,
    },
},
{},--protected
{--public
    Dox = function(this, cdat, sName, sTitle, sBlockOpen, sBlockClose, sTagOpen, eLanguage, ...)
        type.assert.string(sName,       "%S+", "Dox subclass name must not be blank.");
        type.assert.string(sTitle,      "%S+", "Dox documentation title name must not be blank.");
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
        pri.title               = sTitle;
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
    fileTypes_FNL = function(this, cdat)--TODO should I clone the set? probably/
        return cdat.pri.fileTypes;
    end,
    export_FNL = function(this, cdat, eOutputType, bPulsar)
        type.assert.custom(eOutputType, "DoxOutput");
        --TODO puslar snippets
        --print(type.isDoxOutput(cDoxOutput))
        cdat.pri[eOutputType.name].build(this, cdat);
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

        --print(serialize(cdat.pri.finalized))
        --for sIndex, tItem in pairs(cdat.pri.finalized) do
        --end

        --generate_full_html(cdat.pri.finalized, os.getenv("USERPROFILE").."\\Sync\\Projects\\GitHub\\DoxTest.html")


    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
