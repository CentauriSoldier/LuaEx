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
                return nIndex == nMax, tFQXN[nIndex];
            end

        end

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
            local tBlock = {};

            --create the DoxBlock
            local tBlock = DoxBlock(sRawBlock, pri.language, pri.tagOpen,
                                    pri.blockTags, pri.requiredBlockTags);

            local tActive = pri.finalized;

            for bLastItem, sFQXN in tBlock.fqxn() do

                if not (tActive[sFQXN]) then
                    tActive[sFQXN] = {};
                end

                --update the active table variable
                tActive = tActive[sFQXN];

                --store the iterator for the items if last item or false
                tContent[tActive] = bLastItem and tBlock.items or false;
--TODO LEFT OFF HERE gotta get items working
                --set the call to get the content
                setmetatable(tActive, {
                    __call = function(t)
                        --print(tContent[tActive])
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

            local sCode = [[
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>${title} Documentation</title>
                <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
                <style>
                    ${css}
                </style>
            </head>
            <body>
                <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p" crossorigin="anonymous"></script>
                <!-- Topbar -->
                <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
                    <a class="navbar-brand" href="#">
                        <img src="https://via.placeholder.com/150" width="30" height="30" class="d-inline-block align-top mr-2" alt="">
                        ${title} Documentation
                    </a>
                </nav>

                <!-- Content -->
                <div class="container-fluid">
                    <div class="row">
            			<!-- Sidebar Wrapper -->
            			<div class="col-lg-1 bg-dark text-light">
            				<div class="sidebar-wrapper">
            					<!-- Sidebar 1 -->
            					<div class="sidebar">
            						<div class="text-center">
            							<h2>Modules</h2>
            						</div>
            						<ul id="menu1" class="nav flex-column"></ul>
            					</div>
            				</div>
            			</div>

            			<!-- Sidebar Wrapper -->
            			<div class="col-lg-2 bg-dark text-light">
            				<div class="sidebar-wrapper">
            					<!-- Sidebar 2 -->
            					<div class="sidebar">
            						<div class="text-center">
            							<h2 id="menu2itemtitle"></h2>
            						</div>
            						<ul id="menu2" class="nav flex-column"></ul>
            					</div>
            				</div>
            			</div>

                        <!-- Main Panel and Bars -->
                        <div class="col-lg-8 bg-light position-relative">
                            <div class="content-wrapper">

                                <!-- Breadcrumb bar -->
                                <nav aria-label="breadcrumb">
                                    <ol class="breadcrumb breadcrumb-wrapper" id="breadcrumb"></ol>
                                </nav>

                                <!-- Content -->
                                <div id="content">Select an item to see details.</div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Footer -->
                <footer class="footer bg-light">
                    <div class="container">
                        <span class="text-muted">Footer Bar</span>
                    </div>
                </footer>

                <!-- JS Code -->
                <script>
                const documentationData = ${jsontable}

                ${javascript}
                </script>

            </body>
            </html>
            ]] %
            {
                css        = tFunctions.getCSS(this, cdat);
                jsontable  = tFunctions.buildJSONTable(this, cdat),
                javascript = tFunctions.getJavaScript(this, cdat),
                title      = sTitle,
            };

            --print(tFunctions.buildJSONTable(this, cdat))
            -- Write HTML code to a file
            local file = io.open(cdat.pri.OutputPath, "w")
            file:write(sCode)
            file:close()
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

            local function luaTableToJson(tbl)
                local function processTable(t)
                    local result = {}

                    -- Create a table to store sorted keys
                    local sortedKeys = {}
                    for key in pairs(t) do
                        table.insert(sortedKeys, key)
                    end
                    -- Sort keys alphabetically
                    table.sort(sortedKeys)

                    -- Insert sorted keys into the JSON table in order
                    for _, key in ipairs(sortedKeys) do
                        local subtable = t[key]
                        local value = subtable()
                        local subtableResult = processTable(subtable)
                        result[#result + 1] = '"' .. key .. '":{ "value":"' .. escapeStr(value) .. '", "subtable":' .. (next(subtableResult) and "{" .. table.concat(subtableResult, ",") .. "}" or "null") .. '}'
                    end

                    return result
                end

                local jsonResult = processTable(tbl)
                return "{" .. table.concat(jsonResult, ",") .. "}"
            end


            -- Convert the Lua table to JSON format
            return luaTableToJson(cdat.pri.finalized);
        end,
        getCSS = function(this, cdat)
            return [[
            @media (max-width: 768px) {
                .col-lg-1, .col-lg-2, .col-lg-8 {
                    flex: 0 0 100%; /* Make columns full width on small screens */
                    max-width: 100%;
                }
            }

            /* General font scaling for headings and other elements */
            h1, h2, h3, h4, h5, h6,
            .breadcrumb, .breadcrumb-wrapper, .topbar,
            .sidebar, .list-group-item, .footer {
                font-size: calc(1vw + 1vh + 0.5vmin);
            }

            /* Specific adjustments for individual elements */
            .breadcrumb {
                background: none;
                margin-bottom: 4px;
            }

            .breadcrumb-wrapper {
                background-color: #ffc107;
                padding: 5px 20px;
            }

            .topbar {
                background-color: #17a2b8;
                color: white;
                padding: 10px 20px;
            }

            .sidebar-wrapper {
                height: calc(100vh - 126px); /* Adjusted height */
                overflow-y: auto; /* Add scrollbar if content exceeds height */
            }

            .sidebar {
                background-color: #343a40;
                color: white;
                padding: 10px;
            }

            .content-wrapper {
                padding: 0 20px;
            }

            .scrollable-list {
                overflow-x: auto;
                white-space: nowrap;
            }

            .list-group {
                display: flex;
                padding: 0;
            }

            .list-group-item {
                flex: 0 0 auto;
                margin-right: 10px; /* Adjust spacing between items */
            }

            .footer {
                background-color: #f8f9fa;
                color: #6c757d;
                padding: 10px 20px;
                height: 40px; /* Set the height to 40 pixels */
                position: absolute;
                bottom: 0;
                width: 100%;
            }
            /* Adjust container for Sidebar 1 and Sidebar 2 */
            .row {
                display: flex; /* Use flexbox */
                flex-wrap: nowrap; /* Prevent wrapping */
            }
            /* Remove margin and padding from Sidebar 1 and Sidebar 2 */
            .col-lg-1, .col-lg-2 {
                padding: 0 !important; /* Remove padding */
                margin: 0 !important; /* Remove margin */
            }
            /* Sidebar 1 specific adjustments */
            .col-lg-1 {
                flex: 0 0 auto; /* Don't grow or shrink */
                width: auto; /* Auto width */
                max-width: none; /* No maximum width */
            }

            /* Sidebar 2 specific adjustments */
            .col-lg-2 {
                flex: 0 0 auto; /* Don't grow or shrink */
                width: auto; /* Auto width */
                max-width: none; /* No maximum width */
            }
            /* Remove margin and padding from Sidebar 1 and Sidebar 2 */
            .col-lg-1, .col-lg-2 {
                padding: 0 !important; /* Remove padding */
                margin: 0 !important; /* Remove margin */
            }
            ]];
        end,
        getJavaScript = function(this, cdat)
            return [[
            // Global variable to store the current path
    		let currentPath = '';


    		// Load top-level modules into the sidebar
    		function loadSidebar() {
    			const menu = document.getElementById('menu1');
    			menu.innerHTML = '';
    			for (const module in documentationData) {
    				const li = document.createElement('li');
    				li.className = 'nav-item';
    				const a = document.createElement('a');
    				a.href = '#';
    				a.className = 'nav-link';
    				a.textContent = module;
    				a.onclick = function() {
    					currentPath = module; // Update the current path
    					updateBreadcrumb();
    					loadSidebar2(documentationData[module].subtable); // Load the second sidebar
    					const newValue = getPropertyByPath(documentationData, currentPath, "value");
    						if (newValue) {
    								content.innerHTML = newValue;
    						}
    				};
    				li.appendChild(a);
    				menu.appendChild(li);
    			}
    		}



    		function getPropertyByPath(obj, path, property) {
    			const parts = path.split('.');
    			let current = obj;

    			for (let part of parts) {
    				if (current[part]) {
    					//current = current[part].subtable !== null ? current[part].subtable : current[part];
    					current = current[part][property] !== null ? current[part][property] : current[part];
    				} else {
    					return undefined;
    				}
    			}
    			return current;
    		}

    		function updateBreadcrumb() {
    			const breadcrumb = document.getElementById('breadcrumb');
    			const content = document.getElementById('content');
    			const parts = currentPath.split('.');
    			let currentData = documentationData;
    			breadcrumb.innerHTML = '';

    			parts.forEach((part, index) => {
    				let li = document.createElement('li');
    				li.className = 'breadcrumb-item';

    				if (index === parts.length - 1) {
    					li.textContent = part;
    					li.className += ' active';
    					li.setAttribute('aria-current', 'page');
    				} else {
    					let a = document.createElement('a');
    					a.href = '#';
    					a.textContent = part;
    					a.onclick = function() {
    						currentPath = parts.slice(0, index + 1).join('.');
    						updateBreadcrumb();
    						const newData = getPropertyByPath(documentationData, currentPath, "subtable");
    						const newValue = getPropertyByPath(documentationData, currentPath, "value");
    						if (newData) {
    							loadSidebar2(newData);
    						}
    						if (newValue) {
    							content.innerHTML = newValue;
    						}
    					};
    					li.appendChild(a);
    				}

    				breadcrumb.appendChild(li);

    				if (currentData && currentData[part]) {
    					currentData = currentData[part].subtable || currentData[part];
    				}
    			});

    			//if (currentData && typeof currentData.value === 'string') {
    			//    content.innerHTML = currentData.value;
    		   // } else {
    			 //   content.innerHTML = 'Select a subitem to see details.';
    		   // }
    		}


    		function loadSidebar2(data) {
    			const menu2 = document.getElementById('menu2');
    			menu2.innerHTML = '';

    			Object.keys(data).forEach(key => {
    				const li = document.createElement('li');
    				li.className = 'nav-item';
    				const a = document.createElement('a');
    				a.className = 'nav-link';
    				a.href = '#';
    				a.textContent = key;
    				a.onclick = function() {
    					currentPath += `.${key}`;
    					updateBreadcrumb();
    					const subtable = data[key].subtable;
    					if (subtable) {
    						loadSidebar2(subtable);
    					} else {
    						menu2.innerHTML = '<em>' + key + '</em>'; // Clear menu2 if there's no subtable
    					}
    					if (data[key].value) {
    						document.getElementById('content').innerHTML = data[key].value;
    					}
    				};
    				document.getElementById('menu2itemtitle').innerHTML = currentPath.split('.').pop();;
    				li.appendChild(a);
    				menu2.appendChild(li);
    			});
    		}


    		// Initial load
    		loadSidebar();
    		updateBreadcrumb('Home');
            ]];
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
