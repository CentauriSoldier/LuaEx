--load in Dox's required files
local _pDoxRequirePath  = "LuaEx.inc.classes.util.Dox"
local _sDoxBanner       = require(_pDoxRequirePath..".Data.DoxBanner");
local _sDoxCSS          = require(_pDoxRequirePath..".Data.DoxCSS");
local _sDoxHTML         = require(_pDoxRequirePath..".Data.DoxHTML")
local _sDoxJS           = require(_pDoxRequirePath..".Data.DoxJS");

local _sPrismStable     = "1.29.0"; --TODO allow theme change
local _sPrismCSS        = '<link href="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/themes/prism-okaidia.min.css" rel="stylesheet" />' % {stable = _sPrismStable};
local _sPrismScript     = '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>' % {stable = _sPrismStable};
--FIX copy button missing!
--TODO remove <p> surrounding block items...
--TODO color dead anchor links
--TODO FINISH PLANNED add option to get and print TODO, BUG, etc.
--TODO parse sinlge-line comments too
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
--[[!
    @fqxn Classes.Utility.Dox.BlockTags
    @desc This is a list of all built-in <a href="#Classes.Utility.Dox.BlockTag">BlockTags</a>.
    <br>While subclasses (parsers) <i>may</i> provide their own, additional BlockTags, these are always guaranteed to be available.
!]]
local _bRequired            = true;
local _bMultipleAllowed     = true;
local _nExampleInsertPoint  = 6; --where in the table to put the Example BlockTag
local _tBuiltInBlockTags    = {--TODO allow modification and ordering --TODO add a bCombine Variable for block tags with (or using) plural form
    --[[!@fqxn Classes.Utility.Dox.BlockTags.FQXN
        @desc   Display: FQXN<br>
                Aliases:<br><ul><li>fqxn</li></ul>
                Required: <b>true</b><br>
                Multiple Allowed: <b>false</b><br>
                #Items: <b>1</b>
                <br><br>
                The <b>Fully</b> <b>Q</b>ualified Do<b>x</b> <b>N</b>ame (FQXN) is a required BlockTag that tells Dox how to organize the block in the final html.<br>
                It can be thought of as a unique web address, providing a unique landing page for all items within a block.<br>
                In addition, FQXNs can be used to create anchor links.
        @ex
        --create an anchor link in a comment block to another item.
        --\[\[!
            \@fqxn MyProject.MyClass.MyMethods.Method1
            \@desc This method does neat stuff then calls &lt;a href="MyProject.MyClass.MyMethods.Method2"&gt;Method2&lt;/a&gt;
        !\]\]
    !]]
    DoxBlockTag({"fqxn"},                               "FQXN",                 _bRequired,     -_bMultipleAllowed),
    --[[!@fqxn Classes.Utility.Dox.BlockTags.Scope
         @desc  Display: Scope<br>
                Aliases:<br><ul><li>scope</li></ul>
                Required: <b>false</b><br>
                Multiple Allowed: <b>false</b><br>
                #Items: <b>1</b>
    !]]
    DoxBlockTag({"scope"},                              "Scope",                -_bRequired,    -_bMultipleAllowed,   0,  {"<em>", "</em>"}),
    --[[!@fqxn Classes.Utility.Dox.BlockTags.Visibility @desc Display: Visibility<br>Aliases:<br><ul><li>vis</li>visi<li>visibility</li></ul>Required: <b>false</b><br>Multiple Allowed: <b>false</b><br>#Items: <b>1</b>!]]
    DoxBlockTag({"vis", "visi", "visibility"},          "Visibility",           -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"des", "desc", "description"},         "Description",          -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"parameter", "param", "par"},          "Parameter",            -_bRequired,    _bMultipleAllowed,    2,  {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag({"field"},                              "Field",                -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"prop", "property"},                   "Property",             -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"return", "ret"},                      "Return",               -_bRequired,    _bMultipleAllowed,    2,  {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    --NOTE: RESERVED FOR Example Block Tag (inserted during class contruction)
    DoxBlockTag({"code"},                               "Code",                 -_bRequired,    _bMultipleAllowed,    0,  {"<pre>", "</pre>"}),
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


--[[!
    @fqxn Classes.Utility.Dox.Functions.escapePattern
    @desc Escapes special characters in a string so it can be used in a Lua pattern match.
    <br>Used by the <a href="#Classes.Utility.Dox.Methods.extractBlockStrings">extractBlockStrings</a> method.
    @vis local
    @param string pattern A string containing the pattern to be escaped.
    @ret Returns the escaped string with special characters prefixed by a `%`.
!]]
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
--[[!
@fqxn Classes.Utility.Dox
@desc <strong>Dox</strong> auto-generates documentation for code by reading and parsing comment blocks.
<br><br>
<strong>Note</strong>: Dox is intended only to be used by being subclassed.
<br>Subclasses of Dox (called parsers), provide the required parameters to
<br>properly parse comments blocks for specific languages.
<br>Running Dox stand-alone without subclassing it will yield unpredictable results.
--...Meta End
@ex
    --\[\[!
        \@fqxn Classes.Utility.Dox
        \@desc <strong>Dox</strong> auto-generates documentation for code by reading and parsing comment blocks.
        <br>
        <br>Note: Dox is intended only to be used by being subclassed.
        <br>Subclasses of Dox (called parsers), provide the required parameters to
        <br>properly parse comments blocks for specific languages.
        <br>Running Dox stand-alone without subclassing it will yield unpredictable results.
        \@ex --Many Wow! How Yay! Much Meta!
        --...Meta End
    !\]\]
@ex
--for this example, we're using Lua

--create the Lua language object (with the project name)
local oDoxLua = DoxLua("MyProject");

--import a directory recursively (read & parse files)
local pImport = (pPathToMyProject, true);

--set the output path
oDoxLua.setOutputPath("C:\\Users\\MyUsername\\MyProject");

--export html help file.
oDoxLua.export(); --profit!
!]]
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
    --[[@qxn Classes.Utility.Dox.Properties]]
    blockOpen           = "",
    blockClose          = "",
    blockTags           = {},
    blockStrings        = {};
    finalized           = {}; --this is the final, processed data (updated using the refresh() method)
    html                = "", --this is updated on refresh
    mimeTypes           = SortedDictionary(), --TODO throw error on removal of last item
    name                = "",
    OutputPath_AUTO     = "",
    prismCSS            = "",
    --prismScripts        = {},
    requiredBlockTags   = {},
    snippetClose        = "",
    snippetOpen         = "", --TODO add snippet info DO NOT ALLOW USER TO SET/GET THIS
    syntax              = null,
    --Start 	        = "##### START DOX [SUBCLASS NAME] SNIPPETS -->>> ID: ",
    --End 	            = "#####   <<<-- END DOX [SUBCLASS NAME] SNIPPETS ID: ",
    tagOpen             = "",
    title               = "",
    --[[!
    @fqxn Classes.Utility.Dox.Methods.extractBlockStrings
    @vis private
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
    @fqxn Classes.Utility.Dox.Methods.refresh
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
            local sTitle     = pri.title;

            --update and write the html
            local sHTML = _sDoxHTML % {__DOX__CSS__ = _sDoxCSS};
            sHTML = sHTML % {
                __DOX_BANNER__URL__     = _sDoxBanner:gsub("\n", ''), --TODO allow custom banner
                __DOX__TITLE__          = sTitle,
                __DOX__PRISM_CSS__      = _sPrismCSS,
            };

            --inject the javascript
            sHTML = sHTML % {__DOX__INTERNAL_JS__ = "const userData = "..tFunctions.buildJS(this, cdat)};

            --insert the prism scripts for the found languages
            local sPrismScripts = tFunctions.generatePrismScripts(sHTML);
            sHTML = sHTML % {__DOX__PRISM__SCRIPTS__ = sPrismScripts};

            pri.html = sHTML;
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
        generatePrismScripts = function(sHTML)
            -- Define the mapping between language tags and script URLs
            local prismBaseURL = "https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/components/prism-" % {stable = _sPrismStable};
            local languages = {
                abap = "abap", abnf = "abnf", actionscript = "actionscript", ada = "ada", apacheconf = "apacheconf",
                apl = "apl", applescript = "applescript", aql = "aql", arduino = "arduino", arff = "arff",
                asciidoc = "asciidoc", asm6502 = "asm6502", aspnet = "aspnet", autohotkey = "autohotkey",
                autoit = "autoit", bash = "bash", basic = "basic", batch = "batch", bbcode = "bbcode",
                bison = "bison", brainfuck = "brainfuck", bro = "bro", c = "c", cil = "cil", clike = "clike",
                clojure = "clojure", cmake = "cmake", coffeescript = "coffeescript", core = "core", cpp = "cpp",
                crystal = "crystal", csharp = "csharp", csp = "csp", css = "css", cssExtras = "css-extras",
                d = "d", dart = "dart", diff = "diff", django = "django", docker = "docker", eiffel = "eiffel",
                elixir = "elixir", elm = "elm", erb = "erb", erlang = "erlang", flow = "flow", fortran = "fortran",
                fsharp = "fsharp", gcode = "gcode", gdscript = "gdscript", gedcom = "gedcom", gherkin = "gherkin",
                git = "git", glsl = "glsl", gml = "gml", go = "go", graphql = "graphql", groovy = "groovy",
                haml = "haml", handlebars = "handlebars", haskell = "haskell", haxe = "haxe", hcl = "hcl", hlsl = "hlsl",
                http = "http", ichigojam = "ichigojam", icon = "icon", inform7 = "inform7", ini = "ini", io = "io",
                j = "j", java = "java", javadoc = "javadoc", javastacktrace = "javastacktrace", jexl = "jexl",
                jolie = "jolie", jq = "jq", javascript = "javascript", jsExtras = "js-extras", jsTemplates = "js-templates",
                json = "json", json5 = "json5", jsonp = "jsonp", jsdoc = "jsdoc", jsx = "jsx", julia = "julia",
                keyman = "keyman", kotlin = "kotlin", latex = "latex", less = "less", lilypond = "lilypond", liquid = "liquid",
                lisp = "lisp", livescript = "livescript", llvm = "llvm", log = "log", lolcode = "lolcode", lua = "lua",
                makefile = "makefile", markdown = "markdown", markup = "markup", matlab = "matlab", mel = "mel",
                mizar = "mizar", mongodb = "mongodb", monkey = "monkey", moonscript = "moonscript", n1ql = "n1ql",
                nginx = "nginx", nim = "nim", nix = "nix", nsis = "nsis", objectivec = "objectivec", ocaml = "ocaml",
                opencl = "opencl", oz = "oz", parigp = "parigp", parser = "parser", pascal = "pascal", perl = "perl",
                php = "php", phpdoc = "phpdoc", phpExtras = "php-extras", plsql = "plsql", powershell = "powershell",
                processing = "processing", prolog = "prolog", properties = "properties", protobuf = "protobuf", pug = "pug",
                puppet = "puppet", pure = "pure", python = "python", q = "q", qml = "qml", qore = "qore", r = "r",
                reason = "reason", regex = "regex", renpy = "renpy", rest = "rest", rip = "rip", roboconf = "roboconf",
                ruby = "ruby", rust = "rust", sas = "sas", sass = "sass", scss = "scss", scala = "scala", scheme = "scheme",
                shell = "shell", smali = "smali", smalltalk = "smalltalk", smarty = "smarty", solidity = "solidity",
                solutionfile = "solutionfile", soy = "soy", sparql = "sparql", splunkSpl = "splunk-spl", sql = "sql",
                stylus = "stylus", swift = "swift", t4 = "t4", t4Cs = "t4-cs", t4Templating = "t4-templating",
                t4Vb = "t4-vb", tap = "tap", tcl = "tcl", textile = "textile", toml = "toml", tsx = "tsx",
                tt2 = "tt2", turtle = "turtle", twig = "twig", typescript = "typescript", vala = "vala", vbnet = "vbnet",
                velocity = "velocity", verilog = "verilog", vhdl = "vhdl", vim = "vim", visualBasic = "visual-basic",
                wasm = "wasm", wiki = "wiki", xeora = "xeora", xmlDoc = "xml-doc", xojo = "xojo", xquery = "xquery",
                yaml = "yaml", zig = "zig",
            }

            -- Set to store found languages to avoid duplicates
            local foundLanguages = {}

            -- Pattern to match the code blocks with language tags
            for lang in sHTML:gmatch('class=\\"language%-(%w+)\\"') do
            --for lang in sHTML:gmatch('class="language-lua"') do

                -- Check if the language is supported and add it to the set
                if languages[lang] then
                    foundLanguages[languages[lang]] = true
                else
                    foundLanguages[lang] = true
                end
            end

            -- Generate the script tags
            local scripts = {}
            table.insert(scripts, '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>' % {stable = _sPrismStable});
            for lang, _ in pairs(foundLanguages) do
                table.insert(scripts, string.format('<script src="%s%s.min.js"></script>', prismBaseURL, lang))
            end

            return table.concat(scripts, "\n")
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
    Dox = function(this, cdat, sName, sTitle, sBlockOpen, sBlockClose, sTagOpen, eSyntax, tMimeTypes, ...)
        type.assert.string(sName,       "%S+",      "Dox subclass name must not be blank.");
        type.assert.string(sTitle,      "%S+",      "Dox documentation title name must not be blank.");
        type.assert.string(sBlockOpen,  "%S+",      "Block Open symbol must not be blank.");
        type.assert.string(sBlockClose, "%S+",      "Block Close symbol must not be blank.");
        type.assert.string(sTagOpen,    "%S+",      "Tag Open symbol must not be blank.");
        type.assert.custom(eSyntax,     "Dox.SYNTAX");
        type.assert.table(tMimeTypes,   "number",   "DoxMime", 1);

        local pri               = cdat.pri;
        pri.blockOpen           = sBlockOpen;
        pri.blockClose          = sBlockClose;
        pri.name                = sName;
        pri.syntax              = eSyntax;
        pri.title               = sTitle;
        pri.tagOpen             = sTagOpen;
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

        --create and inject the example block tag (language-specific)
        table.insert(pri.blockTags, _nExampleInsertPoint,
        DoxBlockTag({"ex", "example"}, "Example", -_bRequired, _bMultipleAllowed, 0,
                    {"<pre><code class=\"language-"..eSyntax.value.getPrismName().."\">",
                     "</code></pre>"}));

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

        --for _, sPrismScript in ipairs(tPrismScripts) do
            --table.insert(pri.prismScripts, sPrismScript % {stable = _sPrismStable});
        --end

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
    export_FNL = function(this, cdat, eOutputType, bPulsar) --TODO puslar snippets
        --type.assert.custom(eOutputType, "DoxOutput");
        local pri = cdat.pri;
        eOutputType = Dox.OUTPUT.HTML -- TODO allow supporting other output types

        --TODO use proper directory separator
        local pHTMLOut = pri.OutputPath.."\\"..pri.title..".html";
        pri[eOutputType.name].build(this, cdat);

        local function writeFile(pFile, sContent)
            local hFile = io.open(pFile, "w");
            if not hFile then
                error("Error outputting Dox: Can't write to file, '"..pFile.."'.", 3)--TODO nice error message
            end

            hFile:write(sContent)
            hFile:close();
        end

        writeFile(pHTMLOut, pri.html);
    end,
    getHTML = function(this, cdat)
        return cdat.pri.html;
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
    refresh = function(this, cdat)
        dat.pri.refresh();
    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
