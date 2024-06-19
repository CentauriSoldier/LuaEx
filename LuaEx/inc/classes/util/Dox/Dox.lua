--load in Dox's required files
local _pDoxRequirePath  = "LuaEx.inc.classes.util.Dox"
local _sDoxBanner       = require(_pDoxRequirePath..".Data.DoxBanner");
local _sDoxCSS          = require(_pDoxRequirePath..".Data.DoxCSS");
local _sDoxHTML         = require(_pDoxRequirePath..".Data.DoxHTML")
local _sDoxJS           = require(_pDoxRequirePath..".Data.DoxJS");

local _sPrismStable     = "1.29.0"; --TODO allow theme change
--local _sPrismCSS        = '<link href="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/themes/prism-okaidia.min.css" rel="stylesheet" />'; --TODO CEntralize this stuff here...
--local _sPrismScript     = '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>' & {stable};

local tPrismLanguages = {
"markup",
"css",
"clike",
"javascript",
"abap",
"actionscript",
"ada",
"apacheconf",
"apl",
"applescript",
"arduino",
"arff",
"asciidoc",
"asm6502",
"aspnet",
"autohotkey",
"autoit",
"bash",
"basic",
"batch",
"bison",
"brainfuck",
"bro",
"c",
"csharp",
"cpp",
"coffeescript",
"clojure",
"crystal",
"csp",
"css-extras",
"d",
"dart",
"diff",
"django",
"docker",
"eiffel",
"elixir",
"elm",
"erb",
"erlang",
"fsharp",
"flow",
"fortran",
"gedcom",
"gherkin",
"git",
"glsl",
"gml",
"go",
"graphql",
"groovy",
"haml",
"handlebars",
"haskell",
"haxe",
"http",
"hpkp",
"hsts",
"ichigojam",
"icon",
"inform7",
"ini",
"io",
"j",
"java",
"jolie",
"json",
"julia",
"keyman",
"kotlin",
"latex",
"less",
"liquid",
"lisp",
"livescript",
"lolcode",
"lua",
"makefile",
"markdown",
"markup-templating",
"matlab",
"mel",
"mizar",
"monkey",
"n4js",
"nasm",
"nginx",
"nim",
"nix",
"nsis",
"objectivec",
"ocaml",
"opencl",
"oz",
"parigp",
"parser",
"pascal",
"perl",
"php",
"php-extras",
"plsql",
"powershell",
"processing",
"prolog",
"properties",
"protobuf",
"pug",
"puppet",
"pure",
"python",
"q",
"qore",
"r",
"jsx",
"tsx",
"renpy",
"reason",
"rest",
"rip",
"roboconf",
"ruby",
"rust",
"sas",
"sass",
"scss",
"scala",
"scheme",
"smalltalk",
"smarty",
"sql",
"soy",
"stylus",
"swift",
"tap",
"tcl",
"textile",
"tt2",
"twig",
"typescript",
"vbnet",
"velocity",
"verilog",
"vhdl",
"vim",
"visual-basic",
"wasm",
"wiki",
"xeora",
"xojo",
"xquery",
"yaml"
};

local tLangName = {
"Markup",
"CSS",
"C_like",
"JavaScript",
"ABAP",
"ActionScript",
"Ada",
"Apache_Configuration",
"APL",
"AppleScript",
"Arduino",
"ARFF",
"AsciiDoc",
"6502_Assembly",
"ASP.NET_C_SHARP",
"AutoHotkey",
"AutoIt",
"Bash",
"BASIC",
"Batch",
"Bison",
"Brainfuck",
"Bro",
"C",
"C_SHARP",
"C_PLUS_PLUS",
"CoffeeScript",
"Clojure",
"Crystal",
"Content_Security_Policy",
"CSS_Extras",
"D",
"Dart",
"Diff",
"DjangoJinja2",
"Docker",
"Eiffel",
"Elixir",
"Elm",
"ERB",
"Erlang",
"F_SHARP",
"Flow",
"Fortran",
"GEDCOM",
"Gherkin",
"Git",
"GLSL",
"GameMaker_Language",
"Go",
"GraphQL",
"Groovy",
"Haml",
"Handlebars",
"Haskell",
"Haxe",
"HTTP",
"HTTP_Public_Key_Pins",
"HTTP_Strict_Transport_Security",
"IchigoJam",
"Icon",
"Inform_7",
"Ini",
"Io",
"J",
"Java",
"Jolie",
"JSON",
"Julia",
"Keyman",
"Kotlin",
"LaTeX",
"Less",
"Liquid",
"Lisp",
"LiveScript",
"LOLCODE",
"Lua",
"Makefile",
"Markdown",
"Markup_templating",
"MATLAB",
"MEL",
"Mizar",
"Monkey",
"N4JS",
"NASM",
"nginx",
"Nim",
"Nix",
"NSIS",
"Objective_C",
"OCaml",
"OpenCL",
"Oz",
"PARIGP",
"Parser",
"Pascal",
"Perl",
"PHP",
"PHP_Extras",
"PLSQL",
"PowerShell",
"Processing",
"Prolog",
"properties",
"Protocol_Buffers",
"Pug",
"Puppet",
"Pure",
"Python",
"Q_kdb_database",
"Qore",
"R",
"React_JSX",
"React_TSX",
"Ren'py",
"Reason",
"reST_reStructuredText",
"Rip",
"Roboconf",
"Ruby",
"Rust",
"SAS",
"Sass_Sass",
"Sass_Scss",
"Scala",
"Scheme",
"Smalltalk",
"Smarty",
"SQL",
"Soy_Closure_Template",
"Stylus",
"Swift",
"TAP",
"Tcl",
"Textile",
"Template_Toolkit_2",
"Twig",
"TypeScript",
"VB.Net",
"Velocity",
"Verilog",
"VHDL",
"vim",
"Visual_Basic",
"WebAssembly",
"Wiki_markup",
"Xeora",
"Xojo_REALbasic",
"XQuery",
"YAML",
};


local sEnum = [[enum("Dox.PRISM_LANGUAGE", ]]
local sNames = "{\n"
local sValues = "{\n"
for _, sLang in ipairs(tPrismLanguages) do
    sNames = sNames.."\""..tPrismLanguages[_]:upper().."\"\n";
    sValues = sValues.."\""..tLangName[_]:lower().."\"\n";
end
sNames = sNames.."}";
sValues = sValues.."}";
sEnum = sEnum.."\n"..sNames..",\n"..sValues.."\n);"

local pPL = "C:\\Users\\x\\DoxPrismLanguagesEnum.lua";
--local hFile = io.open(pPL, "r");
--hFile:write(sEnum);
--hFile:close();
--print(sEnum)
--enum("PRISM_LANGUAGE", {}, {})

--TODO FINISH PLANNED add option to get and print TODO, BUG, etc.

--TODO Allow internal anchor links
--TODO allow MoTD, custom banners etc.

local assert    = assert;
local class     = class;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local type      = type;

local eOutputType = enum("DoxOutput", {"HTML"});--, "MD"});



--these block tags are built-in to each Dox class
local _bRequired        = true;
local _bMultipleAllowed = true;
local _tBuiltInBlockTags = {--TODO allow modification and ordering --TODO add a bCombine Variable for block tags with (or using) plural form
    DoxBlockTag({"fqxn"},                               "FQXN",                 _bRequired,     -_bMultipleAllowed),
    DoxBlockTag({"scope"},                              "Scope",                -_bRequired,    -_bMultipleAllowed,   0,  {"<em>", "</em>"}),
    DoxBlockTag({"des", "desc", "description"},         "Description",          -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"parameter", "param", "par"},          "Parameter",            -_bRequired,    _bMultipleAllowed,    2,  {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag({"return", "ret",},                     "Return",               -_bRequired,    _bMultipleAllowed,    2,  {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag({"ex", "example"},                      "Example",              -_bRequired,    _bMultipleAllowed,    0,    {"<pre><code class=\"language-lua\">", "</code></pre>"}),
    DoxBlockTag({"features"},                           "Features",             -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"parent"},                             "Parent",               -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"interface"},                          "Interface",            -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"depend", "dependency"},               "Dependency",           -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"planned"},                            "Planned Features",     -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"todo"},                               "TODO",                 -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"issue"},                              "TODO",                 -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"changelog", "versionhistory"},        "Changelog",            -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"version", "ver"},                     "Version",              -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"author"},                             "Author",               -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"email"},                              "Email",                -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"license"},                            "License",              -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"www", "web", "website"},              "Website",              -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"github"},                             "GitHub",               -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"fb", "facebook"},                     "Facebook",             -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"x", "twitter"},                       "X (Twitter)",          -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"copy", "copyright"},                  "Copyright",            -_bRequired,    -_bMultipleAllowed),
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
    MIME   = enum("MIME", {"HTML", "MARKDOWN", "TXT"}, {"html", "MD", "txt"}, true),
    SYNTAX = require(_pDoxRequirePath..".DoxSyntaxEnum"),
    OUTPUT = eOutputType,
},
{--private
    blockOpen           = "",
    blockClose          = "",
    blockTags           = {},
    blockStrings        = {};
    finalized           = {}; --this is the final, processed data (updated using the refresh() method)
    mimeTypes           = SortedDictionary(), --TODO throw error on removal of last item
    name                = "",
    OutputPath_AUTO     = "",
    prismCSS            = "",
    prismScripts        = {},
    requiredBlockTags   = {},
    snippetClose        = "",
    snippetOpen         = "", --TODO add snippet info DO NOT ALLOW USER TO SET/GET THIS
    syntax              = null,
    --Start 	        = "##### START DOX [SUBCLASS NAME] SNIPPETS -->>> ID: ",
    --End 	            = "#####   <<<-- END DOX [SUBCLASS NAME] SNIPPETS ID: ",
    tagOpen             = "",
    title               = "",
    --[[!
    @fqxn LuaEx.Classes.Dox.Methods.extractBlockStrings
    @desc Extracts Dox comment blocks from a string input and stores them for later processing.
    @par string sInput The string from which the comment blocks should be extracted.
    !]]
    extractBlockStrings = function(this, cdat, sInput, oDoxMime)
        --local tBlockStrings         = {};
        local pri           = cdat.pri;
        local fTrim         = string.trim;
        local oDoxSyntax    = pri.syntax.value;
        local sOpenPrefix   = oDoxSyntax.getCommentOpen();
        local sCloseSuffix  = oDoxSyntax.getCommentClose();
        local sBlockOpen    = pri.blockOpen;
        local sBlockClose   = pri.blockClose;

        local sPattern = escapePattern(sOpenPrefix..sBlockOpen).."(.-)"..escapePattern(sBlockClose..sCloseSuffix);
        for sMatch in sInput:gmatch(sPattern) do
            local fPreProcessor = oDoxMime.getPreProcessor();
            local sUnprocessedBlock = fTrim(sMatch);
            local sBlock = fPreProcessor(sUnprocessedBlock);

            if not (pri.blockStrings[sBlock]) then
                pri.blockStrings[sBlock] = true;
            end

        end

    end,
    processBlockItem = function(this, cdat, oBlockTag, sContent)
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
        tContent[nColumnCount] = sCurrent;

        for x = 1, #tContent do
            local tWrapper   = oBlockTag.getcolumnWrapper(x);
            local sWrapFront = tWrapper[1];
            local sWrapBack  = tWrapper[2];
            --sTableDataItems = sTableDataItems.."<td>"..sWrapFront..tContent[x]..sWrapBack.."</td>";
            sTableDataItems = sTableDataItems.."   "..sWrapFront..tContent[x]..sWrapBack.."";
        end

        return [[<div class="custom-section"><div class="section-title">${display}</div><div class="section-content"><p>${content}</p></div></div>]] %
        {
            display = oBlockTag.getDisplay(),
            content = sTableDataItems,--TODO break up content into columns as needed
        };
    end,
    processBlockString = function(this, cdat)
        local pri = cdat.pri;
    end,
    --[[!
    @fqxn LuaEx.Classes.Dox.Methods.refresh
    @desc Refreshes the finalized data
    !]]
    refresh = function(this, cdat)
        local pri = cdat.pri;

        --reset the finalized data table
        pri.finalized = {};

        --inject all block strings into finalized data table
        for sRawBlock, _ in pairs(pri.blockStrings) do
            --create the DoxBlock
            local oBlock = DoxBlock(sRawBlock, pri.syntax, pri.tagOpen,
                                    pri.blockTags, pri.requiredBlockTags);

            local tActive = pri.finalized;

            for bLastItem, nFQXNIndex, sFQXN in oBlock.fqxn() do

                if not (tActive[sFQXN]) then
                    tActive[sFQXN] = setmetatable({}, {
                        __call = function(t)
                            return "";
                        end,
                    });
                end

                --update the active table variable
                tActive = tActive[sFQXN];
            end



            --create the content string
            local sContent = [[<div class="container-fluid">]];

            --build the row (block item)
            for oBlockTag, sRawInnerContent in oBlock.items() do
                local sInnerContent = pri.processBlockItem(oBlockTag, sRawInnerContent);
                sContent = sContent..sInnerContent;
            end

            --set the call to get the content
            setmetatable(tActive, {
                __call = function(t)
                    return sContent..[[</div>]];
                end,
            })

        end

    end,
    [eOutputType.HTML.name] = {
        build = function(this, cdat)
            local pri        = cdat.pri;
            local tFunctions = pri[eOutputType.HTML.name];
            local sTitle     = pri.title;--TODO FINISH use correct seperator
            local pHTMLOut   = cdat.pri.OutputPath.."\\"..sTitle..".html";--TODO use proper directory separator
            local pJSOut     = cdat.pri.OutputPath.."\\"..sTitle..".js";

            local function writeFile(pFile, sContent)
                local hFile = io.open(pFile, "w");
                if not hFile then
                    error("Error outputting Dox: Can't write to file, '"..pFile.."'.", 3)--TODO nice error message
                end
                hFile:write(sContent)
                hFile:close();
            end

            local sPrismScripts = "";
            local nMaxScripts   = pri.prismScripts;

            for nIndex, sScript in ipairs(pri.prismScripts) do
                local sNewLine = nIndex == nMaxScripts and "" or "\n";
                sPrismScripts = sPrismScripts..sScript..sNewLine;
            end

            --update and write the html
            sHTML = _sDoxHTML % {__DOX__CSS__ = _sDoxCSS};
            sHTML = sHTML % {
                __DOX_BANNER__URL__     = _sDoxBanner:gsub("\n", ''), --TODO allow custom banner
                __DOX__TITLE__          = sTitle,
                __DOX__PRISM_CSS__      = pri.prismCSS,
                __DOX__PRISM__SCRIPTS__ = sPrismScripts,
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
            local lineNumber = 0
            local bFound = false

            -- Read the input text line by line (split by newline character)
            for line in _sDoxJS:gmatch("[^\r\n]+") do
                lineNumber = lineNumber + 1

                -- Check if the search string is in the current line
                if bFound then
                    sRet = sRet .. line .. "\n"
                elseif string.find(line, "//—©_END_DOX_TESTDATA_©—", 1, true) then
                    bFound = true
                end
            end

            if not bFound then
                return nil, "String not found in the input"
            end

            local sJSON = tFunctions.buildJSONTable(this, cdat);
            return sJSON.."\n\n"..sRet;
        end,
        buildJSONTable = function(this, cdat) --TODO clean up
            local pri        = cdat.pri;
            local tFunctions = pri[eOutputType.HTML.name];

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
                        local value = subtable();
                        local subtableResult = processTable(subtable, indent .. "    ")
                        local newstring = indent .. '"' .. key .. '": {\n' ..
                                          indent .. '    "value": "' .. tFunctions.prepJSONString(value) .. '",\n' ..
                                          indent .. '    "subtable": ' .. (next(subtableResult) and "{\n" .. table.concat(subtableResult, ",\n") .. "\n" .. indent .. "    }" or "null") .. '\n' ..
                                          indent .. '}'
                        table.insert(result, newstring)
                    end

                    return result
                end

                local jsonResult = processTable(tbl, indentSpace)
                return "{\n" .. table.concat(jsonResult, ",\n") .. "\n" .. indentSpace .. "}"
            end

            -- Convert the Lua table to JSON format
            local nIndentSpaces = 4
            return luaTableToJson(cdat.pri.finalized, nIndentSpaces)
        end,
        prepJSONString = function (s)
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
        end,
    },
},
{},--protected
{--public
    Dox = function(this, cdat, sName, sTitle, sBlockOpen, sBlockClose, sTagOpen, eSyntax, tMimeTypes, sPrismCSS, tPrismScripts, ...)
        type.assert.string(sName,       "%S+",      "Dox subclass name must not be blank.");
        type.assert.string(sTitle,      "%S+",      "Dox documentation title name must not be blank.");
        type.assert.string(sBlockOpen,  "%S+",      "Block Open symbol must not be blank.");
        type.assert.string(sBlockClose, "%S+",      "Block Close symbol must not be blank.");
        type.assert.string(sTagOpen,    "%S+",      "Tag Open symbol must not be blank.");
        type.assert.custom(eSyntax,     "Dox.SYNTAX");
        type.assert.table(tMimeTypes,   "number",   "DoxMime", 1);
        type.assert.string(sPrismCSS,   "%S+",      "Prism css link must not be blank.");
        type.assert.table(tPrismScripts,"number",   "string", 1);

        local pri               = cdat.pri;
        pri.blockOpen           = sBlockOpen;
        pri.blockClose          = sBlockClose;
        pri.name                = sName;
        pri.syntax              = eSyntax;
        pri.title               = sTitle;
        pri.tagOpen             = sTagOpen;
        pri.prismCSS            = sPrismCSS % {stable = _sPrismStable};
        pri.requiredBlockTags   = {};

        for _, oDoxMime in pairs(tMimeTypes) do
            pri.mimeTypes.add(oDoxMime.getName(), oDoxMime);
        end

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

        for _, sPrismScript in ipairs(tPrismScripts) do
            table.insert(pri.prismScripts, sPrismScript % {stable = _sPrismStable});
        end

        --TODO FIX check for duplicate aliases in all block tags...only one specific alias may exist in any block tag

    end,
    addMimeType = function(this, cdat, oDoxMime)
        type.assert.custom(oDoxMime, "DoxMime");
        pri.mimeTypes.add(oDoxMime.getName(), oDoxMime);
    end,
    blockTags = function(this, cdat)
        local tBlockTags    = cdat.pri.blockTags;
        local nIndex        = 0;
        local nMax          = #tBlockTags;

        return function()
            nIndex = nIndex + 1;

            if (nIndex < nMax) then
                return clone(tBlockTags[nIndex]);
            end

        end

    end,
    export_FNL = function(this, cdat, eOutputType, bPulsar)
        --type.assert.custom(eOutputType, "DoxOutput");
        eOutputType = Dox.OUTPUT.HTML -- TODO allow supporting other output types
        --TODO puslar snippets
        --print(type.isDoxOutput(cDoxOutput))
        cdat.pri[eOutputType.name].build(this, cdat);
    end,
    getLanguage_FNL = function(this, cdat)
        return cdat.pri.syntax;
    end,
    getMimeTypes = function(this, cdat)
        --return clone(cdat.pri.mimeTypes);--TODO this must return an iterator
        return cdat.pri.mimeTypes;
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
        --local tFiles, tRel = io.dir(pDir, bRecurse, 0, cdat.pri.fileTypes);--TODO BUG FIX CHANGE this to use new mime table
        local tFiles, tRel = io.dir(pDir, bRecurse, 0);--TODO BUG FIX CHANGE this to use new mime table

        --TODO THROW ERROR FOR FAILURE
        for _, pFile in pairs(tFiles) do
            cdat.pub.importFile(pFile, true);
        end

        cdat.pri.refresh();
    end,
    importFile_FNL = function(this, cdat, pFile, bSkipRefresh)
        type.assert.string(pFile, "%S+");

        --get the path parts (to find the filetype)
        local tParts    = io.splitpath(pFile);
        --TODO THROW ERROR ON tParts Fail
        local sExt = tParts.extension:lower();
        local oActiveDoxMime;

        for sExt, oDoxMime in cdat.pri.mimeTypes() do

            if (sExt == oDoxMime.getName()) then
                oActiveDoxMime = oDoxMime;
                break;
            end

        end

        if (oActiveDoxMime) then
            local hFile = io.open(pFile, "r");

            if not (hFile) then
                error("Error importing file to Dox.\nCould not open file: '"..pFile.."'.");
            else

                local sContent = hFile:read("*all");
                cdat.pub.importString(sContent, oActiveDoxMime, true);
                --cdat.pri.extractBlockStrings(sContent);
                hFile:close();

                if not (bSkipRefresh) then
                    cdat.pri.refresh();
                end

            end

        end

    end,
    importString_FNL = function(this, cdat, sInput, oDoxMime, bSkipRefresh)
        --TODO assert mime object
        type.assert.string(sInput);
        local sWorking = sInput;

        cdat.pri.extractBlockStrings(sWorking, oDoxMime);

        if not (bSkipRefresh) then
            cdat.pri.refresh();
        end

    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
