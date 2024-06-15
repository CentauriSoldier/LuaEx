--TODO add option to get and print TODO, BUG, etc.

--TODO move this out
local tMarkdownToHTML = {
    ["*"]       = {"<em>", "</em>"},                    -- Emphasis
    ["_"]       = {"<em>", "</em>"},                    -- Emphasis
    ["**"]      = {"<strong>", "</strong>"},            -- Strong emphasis
    ["***"]     = {"<strong><em>", "</em></strong>"},   -- Strong emphasis
    --["__"]      = {"<strong>", "</strong>"},            -- Strong emphasis
    ["#"]       = {"<h1>", "</h1>"},                    -- Header 1
    ["##"]      = {"<h2>", "</h2>"},                    -- Header 2
    ["###"]     = {"<h3>", "</h3>"},                    -- Header 3
    ["####"]    = {"<h4>", "</h4>"},                    -- Header 4
    ["#####"]   = {"<h5>", "</h5>"},                    -- Header 5
    ["######"]  = {"<h6>", "</h6>"},                    -- Header 6
    ["```"]     = {"<code>", "</code>"},                -- Code block
    ["---"]     = {"<hr>", ""},                         -- Horizontal rule
    --["-"] = {"<ul><li>", "</li></ul>"}, -- Unordered list item
    --["+"] = {"<ul><li>", "</li></ul>"}, -- Unordered list item
    --["*"] = {"<ul><li>", "</li></ul>"}, -- Unordered list item
    --["1."] = {"<ol><li>", "</li></ol>"}, -- Ordered list item
}

local function markdownToHTML(sInput)
    local sRet = sInput;
--[[
    for sPattern, tTags in pairs(tMarkdownToHTML) do
        local sStartTag, sEndTag = tags[1], tags[2];

        local nIndex = 1;
        local nStart1, nEnd1, nStart2, nEnd2 = 1, 1, 1, 1;

        while (nStart1 and nEnd1 and nStart2 and nEnd2) do
             nStart1, nEnd1 = sInput:find(sPattern, nIndex);

             if (nStart1 and nEnd1) then
                 nIndex1 = 0;
                 nStart1, nEnd1 = sInput:find(sPattern, nIndex);

             end

        end

]]
        --sRet = sRet:gsub(escapedPattern, function(match)
            -- If not in a list item, apply markdown tags
        --    return startTag .. match:gsub(escapedPattern, "") .. endTag
        --end)
        --sRet = sRet:gsub(sPattern, )
    --end

    return sRet;
end












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

local eOutputType = enum("DoxOutput", {"HTML"});--, "MD"});

--TODO consider moving this to its own file and creating the enum using a static initializer
eDoxLanguage = enum("DoxLanguage",
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
local _tBuiltInBlockTags = {
    DoxBlockTag({"fqxn"},            "FQXN",       true,  false),
    DoxBlockTag({"ex", "example"},   "Example",    false, true, {"<code>", "</code>"}),
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
        local x = 0;
        --inject all block strings into finalized data table
        for sRawBlock, _ in pairs(pri.blockStrings) do
            --x = x + 1;
            --writeToFile("\\Sync\\Projects\\ZZZ Test\\"..x..".txt", sRawBlock)

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
                --local sOuterContent = [[<div class="container-fluid table-container"><table class="table table-striped"><tbody>]];
                local sOuterContent = [[<div class="container-fluid">]];

                local function splitStringBySpace(inputString, number)
                    local result = {}
                    local currentNumber = 1
                    local currentIndex = 1

                    while currentNumber <= number do
                        local endIndex = inputString:find(" ", currentIndex)
                        if not endIndex then
                            result[currentNumber] = inputString:sub(currentIndex)
                            currentIndex = #inputString + 2 -- Move currentIndex beyond the string length to break the loop
                        else
                            result[currentNumber] = inputString:sub(currentIndex, endIndex - 1)
                            currentIndex = endIndex + 1
                        end
                        currentNumber = currentNumber + 1
                    end

                    -- Fill remaining indices with empty strings
                    for i = currentNumber, number do
                        result[i] = ""
                    end

                    return result
                end


                --build the row (block item)
                for oBlockTag, sContent in oBlock.items() do
                    local sTableDataItems = "";
                    local nColumnCount    = oBlockTag.getColumnCount();
                    local sCurrent        = sContent;
                    local nStart          = 1;
                    local nEnd            = -1;
                    local tContent        = {};

                    -- Iterate over the number of columns
                    for x = 1, nColumnCount - 1 do
                        -- Find the index of the next space
                        local nStart, nEnd = sCurrent:find(" ", 1);

                        -- Check if a space is found
                        if not nStart then
                            error("Unable to find space for column " .. x)--TODO better message
                        end

                        -- Extract the substring between the current start and end indices
                        tContent[x] = sCurrent:sub(1, nEnd - 1);

                        -- Update sCurrent to start from the next character after the space
                        sCurrent = sCurrent:sub(nEnd + 1);
                    end

                    -- Add the remaining part of sCurrent as the last content item
                    tContent[nColumnCount] = sCurrent


                    for x = 1, #tContent do
                        local tWrapper   = oBlockTag.getcolumnWrapper(x);
                        local sWrapFront = tWrapper[1];
                        local sWrapBack  = tWrapper[2];
                        --sTableDataItems = sTableDataItems.."<td>"..sWrapFront..tContent[x]..sWrapBack.."</td>";
                        sTableDataItems = sTableDataItems.."   "..sWrapFront..tContent[x]..sWrapBack.."";
                    end




                    --sOuterContent = sOuterContent..[[<tr><td>${display}</td>${content}</tr>]] %
                    sOuterContent = sOuterContent..[[<div class="custom-section"><div class="section-title">${display}</div><div class="section-content"><p>${content}</p></div></div>]] %
                    {
                        display = oBlockTag.getDisplay(),
                        content = sTableDataItems,--TODO break up content into columns as needed
                    };
                end

                --local sOuterContent = sOuterContent..[[</tbody></table></div>]];
                local sOuterContent = sOuterContent..[[</div>]];

                --parse the final string for markdown
                sOuterContent = markdownToHTML(sOuterContent);
                --print(sOuterContent)
                --TODO gsub last newline

                --store the iterator for the items if last item or false
                --tContent[tActive] = bLastItem and oBlock.items or false;
                tContent[tActive] = sOuterContent;
                --TODO LEFT OFF HERE gotta get items working


                --if (sFQXN == "class")


                --set the call to get the content
                setmetatable(tActive, {
                    __call = function(t)
                        return tContent[tActive];
                    end,
                })
            end

        end

    end,
    [eOutputType.HTML.name] = {
        build = function(this, cdat)
            local pri        = cdat.pri;
            local tFunctions = pri[eOutputType.HTML.name];
            local sTitle     = pri.title;
            local pSource    = source.getpath();--TODO trim ending dir sep and dups
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
            local pSource    = source.getpath();--TODO trim ending dir sep and dups
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

        --import all built-in BlockTags
        for _, oBlockTag in ipairs(_tBuiltInBlockTags) do
            local oClonedBlockTag = clone(oBlockTag);
            table.insert(pri.blockTags, oClonedBlockTag);

            if (oBlockTag.isRequired()) then
                table.insert(pri.requiredBlockTags, oClonedBlockTag);
            end

        end

        --store all input BlockTags and log required ones found
        for nIndex, oBlockTag in ipairs({...} or arg) do
            --validate the type
            type.assert.custom(oBlockTag, "DoxBlockTag");

            --search for required blocktags conflicts
            for _, oBuiltInBlockTag in pairs(pri.blockTags) do

                for sAlias in oBuiltInBlockTag.aliases() do

                    if ( oBlockTag.hasAlias(sAlias) ) then
                        error(  "Error creating Dox subclass, '${subclass}'.\nBuilt-in BlockTag, '${display}', cannot be overriden or duplicated." %
                                {subclass = sName,
                                 display = oBuiltInBlockTag.getDisplay()},
                                 2);
                    end

                end

            end

            --clone the blocktag
            local oClonedBlockTag = clone(oBlockTag);

            --store the block tag
            table.insert(pri.blockTags, oClonedBlockTag);

            --if the BlockTag is required, store it
            if (oBlockTag.isRequired()) then
                table.insert(pri.requiredBlockTags, oClonedBlockTag);
            end

        end

        --TODO FIX check for duplicate aliases in all block tags...only one specific alias may exist in any block tag

    end,
    export_FNL = function(this, cdat, eOutputType, bPulsar)
        --type.assert.custom(eOutputType, "DoxOutput");
        eOutputType = Dox.OUTPUT.HTML -- TODO allow supporting other output types
        --TODO puslar snippets
        --print(type.isDoxOutput(cDoxOutput))
        cdat.pri[eOutputType.name].build(this, cdat);
    end,
    getLanguage_FNL = function(this, cdat)
        return cdat.pri.language;
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
