local _nExampleInsertPoint  = 6; --where in the _tBuiltInBlockTags table to put the Example BlockTag
local _pStaticsRequirePath  = "LuaEx.inc.classes.util.Dox.Statics";
local _eSyntax              = require(_pStaticsRequirePath..".DoxSyntaxEnum");
local _tBuiltInBlockTags    = require(_pStaticsRequirePath..".BuiltInBlockTags");

local assert    = assert;
local class     = class;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local type      = type;

local _eOutputType = enum("DoxOutput", {"HTML"});--, "MD"});


--[[!
@fqxn Dox.Glossary
@desc This contains terms and definitions not otherwise found in the Dox documentation.
!]]

--[[!
@fqxn Dox.Glossary.FQXN
@desc This is the Fully Qualified Dox Name of a given item.
<br>For example, the FQXN of this specific document item that you're reading now is <strong>Dox.Glossary.FQXN</strong>.
<br>
<br>FQXNs are used to not only arrange documentation hierarchically, but also to create internal anchor links. For example, to link to this documentation item, a link is created as follows:
<br>&lt;a href=&quot;#Dox.Glossary.FQXN&quot;&gt;Dox.Glossary.FQXN&lt;/a&gt;
<br><br>
<strong>Note</strong>: Whether FQXNs may contain spaces is up to each <a href="#Dox.Components.DoxBuilder">DoxBuilder</a>.<br>For example, the <a href="#Dox.Components.DoxBuilderHTML">DoxBuilderHTML</a> allows spaces seemlessly in FQXNs and handles them at several points in the code so the links still function properly while maintaining the visual spaces in the FQXN names.
!]]

--[[!
    @fqxn Dox.Functions.escapePattern
    @desc Escapes special characters in a string so it can be used in a Lua pattern match.
    <br>Used by the <a href="#Classes.Dox.Methods.extractBlockStrings">extractBlockStrings</a> method.
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
@fqxn Dox
@bug In an FQXN with multiple spaces, only the first is handled correcly.
@desc <strong>Dox</strong> auto-generates documentation for code by reading and parsing comment blocks.
<br><br>
Note: Dox is intended only to be used by being subclassed.
<br>Subclasses of Dox (called parsers), provide the required parameters to properly parse comments blocks for specific languages.
<br><a href="https://imgflip.com/i/910ysh"><img style="width: 200px; height: 200px" class="rounded float-left img-thumbnail" src="https://i.imgflip.com/910ysh.jpg" title="made at imgflip.com"/></a>
<br>--...Meta End
@ex
    --\[\[!
        \@fqxn Dox
        \@desc &lt;strong&gt;Dox&lt;/strong&gt; auto-generates documentation for code by reading and parsing comment blocks.
        <br>&lt;br&gt;
        <br>&lt;br&gt;Note:Dox is intended only to be used by being subclassed.
        <br>&lt;br&gt;Subclasses of Dox (called parsers), provide the required parameters to properly parse comments blocks for specific languages.
        \@ex&lt;br&gt;--Many Wow! How Yay! Much Meta!
        <br>&lt;br&gt;--...Meta End
    !\]\]
@ex
--for this example, we're using Lua

--create the Lua language parser object (with the project name)
local oDoxLua = DoxLua("MyProject");

--import a directory recursively (read & parse files)
local pImport = "C:\\Path\\To\\My\\Project"

local function importFiles(pDir)

    for _, pFile in pairs(io.listfiles(pDir, false, nil, "lua")) do
        oDoxLua.importFile(pFile, true); --don't refresh the data until we're done importing
        --print(pFile);
    end

end

local tFolders = io.listdirs(pImport, true, importFiles); --set recursion to true

--set the output path
oDoxLua.setOutputPath("C:\\Users\\MyUsername\\MyProject");

--\[\[we don't need to set a Dox.BUILDER since it defaults
    to Dox.BUILDER.HTML and that's what we want\]\]

--refresh the data
oDoxLua.refresh();

--export html help file.
oDoxLua.export(); --profit!
@prifi string blockOpen Set during contruction, this is the string that tells Dox when to <strong>start</strong> reading a <a href="#Dox.Components.DoxBlock">DoxBlock</a>.
@prifi string blockClose Set during contruction, this is the string that tells Dox when to <strong>stop</strong> reading a <a href="#Dox.Components.DoxBlock">DoxBlock</a>.
@prifi table blockTags A complete list of <a href="#Dox.Components.DoxBlockTag">DoxBlockTags</a> available to the instance.
<br>It's built during construction by first importing all built-in <a href="#Dox.Components.DoxBlockTag">DoxBlockTags</a>, then by creating and inserting the example <strong>BlockTags</strong> and finally by inputting all input varargs (input <strong>BlockTags</strong>) if any are provided.--TODO FINISH
@summary
Below is the layout and hierarchy of Dox and all its elements.
<!-- Parsers -->
    <div class="accordion-item">
      <h2 class="accordion-header" id="headingParsers">
        <button class="accordion-button" type="button" data-bs-toggle="collapse"
                data-bs-target="#collapseParsers" aria-expanded="true" aria-controls="collapseParsers">
          📦 Parsers
        </button>
      </h2>
      <div id="collapseParsers" class="accordion-collapse collapse show"
           aria-labelledby="headingParsers" data-bs-parent="#doxAccordion">
        <div class="accordion-body">
          <p>Language-specific modules that scan your source for <code>--\[\[! … \]\]</code> blocks and <code>\@tags</code>, then emit <strong>DoxBlockTag</strong> objects.</p>
          <ul>
            <li><code>DoxSyntax.lua</code> – core tokenizer, finds raw tags and text</li>
            <li><code>DoxLua.lua</code>, <code>DoxCPP.lua</code>, etc. – apply comment-style rules and normalize into <code>DoxBlockTag</code></li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Components -->
    <div class="accordion-item">
      <h2 class="accordion-header" id="headingComponents">
        <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#collapseComponents" aria-expanded="false" aria-controls="collapseComponents">
          🔧 Components
        </button>
      </h2>
      <div id="collapseComponents" class="accordion-collapse collapse"
           aria-labelledby="headingComponents" data-bs-parent="#doxAccordion">
        <div class="accordion-body">
          <p>Core in-memory models and the abstract builder interface.</p>
          <ul>
            <li><strong>DoxBlockTag.lua</strong> – represents one <code>\@tag</code> (name, type, description)</li>
            <li><strong>DoxBlock.lua</strong> – groups tags &amp; text into a logical block</li>
            <li><strong>DoxBuilder.lua</strong> – abstract base with <code>refresh()</code> and <code>build()</code> signatures</li>
            <li><strong>DoxMime.lua</strong> – escaping &amp; formatting helpers</li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Builders -->
    <div class="accordion-item">
      <h2 class="accordion-header" id="headingBuilders">
        <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#collapseBuilders" aria-expanded="false" aria-controls="collapseBuilders">
          🏗️ Builders
        </button>
      </h2>
      <div id="collapseBuilders" class="accordion-collapse collapse"
           aria-labelledby="headingBuilders" data-bs-parent="#doxAccordion">
        <div class="accordion-body">
          <div class="row">
            <div class="col-md-6">
              <h5>HTML Builder</h5>
              <ul>
                <li><code>DoxBuilderHTML.lua</code> – nests by FQXN, injects CSS/JS, outputs HTML page</li>
                <li><code>Data/dox.css</code> &amp; <code>prism.js</code> for styling &amp; highlighting</li>
              </ul>
            </div>
            <div class="col-md-6">
              <h5>PulsarLua Builder</h5>
              <ul>
                <li><code>DoxBuilderPulsarLua.lua</code> – filters <code>\@display PulsarLua</code>, builds nested table, emits JSON (to adapt for CSON snippets)</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Integration -->
    <div class="accordion-item">
      <h2 class="accordion-header" id="headingIntegration">
        <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#collapseIntegration" aria-expanded="false" aria-controls="collapseIntegration">
          🔄 How It Fits Together
        </button>
      </h2>
      <div id="collapseIntegration" class="accordion-collapse collapse"
           aria-labelledby="headingIntegration" data-bs-parent="#doxAccordion">
        <div class="accordion-body">
          <ol>
            <li><strong>Parse</strong> source → <code>DoxBlockTag</code> → <code>DoxBlock</code></li>
            <li><strong>Refresh</strong> in builder → nest by FQXN → <code>tFinalizedData</code></li>
            <li><strong>Build</strong> in builder → serialize to HTML/JSON/CSON</li>
            <li><strong>Output</strong> injected into docs or editor snippets</li>
          </ol>
        </div>
      </div>
    </div>

  </div>
</div>
@todo <!--TODO-->
<ul>
    <li>allow user to suround content block with (optional tags) tags...</li>
    <li>color dead anchor links</li>
    <li>add option to get and print TODO, BUG, etc.</li>
    <li>parse single-line comments too</li>
    <li>add tooltip with \@des info (if available) in sidemenu items</li>
    <li>allow custom BlockTag sort order (in what order items are displayed in the output)</li>
    <li>allow escaping . in FQXN</li>
    <li>fix bug in fqxns with multiple-spaces</li>
</ul>

!]]
return class("Dox",
{--metamethods
    __tostring = function()
        --TODO this should display the open/close stuff +
    end,
},
{--static public
    --TODO move this out to the builder section and call it in
    BUILDER = enum("Dox.BUILDER", {"HTML", "PULSAR_LUA"}, {DoxBuilderHTML(), DoxBuilderPulsarLua()}, true),
    OUTPUT  = _eOutputType,
    SYNTAX  = _eSyntax,
},
{--private
    --[[@qxn Classes.Dox.Fields]]
    blockOpen           = "",
    blockClose          = "",
    blockTags           = {},
    blockStrings        = {},
    builder             = null,
    --[[!@fqxn Dox.Fields.Private @field finalized The finalized data once imported items have been refreshed.!]]
    finalized           = {}; --this is the final, processed data (updated using the refresh() method in the subclass)
    html                = "", --this is updated on refresh
    Intro__auto_F       = "", --the custom welcome message (if any)
    mimeTypes           = SortedDictionary(), --TODO throw error on removal of last item
    name                = "",
    output              = "",
    OutputPath__auto__  = "",
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
    @fqxn Dox.Methods.extractBlockStrings
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
        local oBuilder        = cdat.pri.builder.value;
        -- Iterate over the number of columns
        for x = 1, nColumnCount - 1 do
            -- Find the index of the next space
            local nStart, nEnd = sCurrent:find(" ", 1);

            -- Check if a space is found
            if not nStart then
                error("Unable to find space for column " .. x.." in block:\n"..sContent)--TODO better message
            end

            -- Extract the substring between the current start and end indices
            tContent[x] = sCurrent:sub(1, nEnd - 1);

            -- Update sCurrent to start from the next character after the space
            sCurrent = sCurrent:sub(nEnd + 1);
        end

        -- Add the remaining part of sCurrent as the last content item
        tContent[nColumnCount] = sCurrent;

        for x = 1, #tContent do
            local tWrapper   = oBuilder.getColumnWrapper(oBlockTag.getDisplay(), x);
            --local tWrapper   = oBlockTag.getColumnWrapper(x);
            local sWrapFront = tWrapper[1];
            local sWrapBack  = tWrapper[2];
            --sTableDataItems = sTableDataItems.."<td>"..sWrapFront..tContent[x]..sWrapBack.."</td>";
            sTableDataItems = sTableDataItems.."   "..sWrapFront..tContent[x]..sWrapBack.."";
        end

        local sDisplay = oBlockTag.getDisplay();
        local sID = "";

        if (sDisplay == "Example") then
            sDisplay = sDisplay.." "..oBuilder.getCopyToClipboardButton();
            sID = ' id="'..string.uuid()..'"'
        end

        return {
            id = sID,
            display = sDisplay,
            content = sTableDataItems,--TODO break up content into columns as needed
        };
    end,
    processBlockString = function(this, cdat)
        local pri = cdat.pri;
    end,
    --[[!
    @fqxn Dox.Methods.refresh
    @desc Refreshes the finalized data
    !]]
    refresh = function(this, cdat)
        local pri       = cdat.pri;
        local oBuilder  = pri.builder.value;

        --create all the blocks
        local tBlocks = {};
        local nBlockID = 0;

        for sRawBlock, _ in pairs(pri.blockStrings) do
            nBlockID = nBlockID + 1;
            --create the DoxBlock
            tBlocks[nBlockID] = DoxBlock(   sRawBlock,      pri.syntax,     pri.tagOpen,
                                            pri.blockTags,  pri.requiredBlockTags);
        end

        --call the builder's refresh method and reset the finalized data table
        local tFinalized = oBuilder.refresh(tBlocks, pri.processBlockItem);

        if not (type(tFinalized) == "table") then
            error("Error refreshing Dox data in method, 'refresh' in builder, '"..oBuilder.getName().."'. Method must return a table value. Got type, "..type(tFinalized)..".", 2);
        end

        pri.finalized = tFinalized;
    end,
},
{--protected
    Dox = function(this, cdat, sName, sTitle, sBlockOpen, sBlockClose, sTagOpen, eSyntax, tMimeTypes, ...)
        type.assert.string(sName,       "%S+",      "Dox subclass name must not be blank.");
        type.assert.string(sTitle,      "%S+",      "Dox documentation title name must not be blank.");
        type.assert.string(sBlockOpen,  "%S+",      "Block Open symbol must not be blank.");
        type.assert.string(sBlockClose, "%S+",      "Block Close symbol must not be blank.");
        type.assert.string(sTagOpen,    "%S+",      "Tag Open symbol must not be blank.");
        type.assert.custom(eSyntax,     "Dox.SYNTAX");
        type.assert.table(tMimeTypes,   "number",   "DoxMime", 1);

        local pri               = cdat.pri;
        pri.syntax              = eSyntax;
        pri.builder             = Dox.BUILDER.HTML; --default builder, can be changed later
                                  --pri.builder.value.setSyntax(cdat.pri.syntax);
        pri.blockOpen           = sBlockOpen;
        pri.blockClose          = sBlockClose;
        pri.name                = sName;
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
        --local tExampleWrapper = pri.builder.value.getExampleWrapper(eSyntax);
        --table.insert(pri.blockTags,
        --    DoxBlockTag({"ex", "example"}, "Example", false, true, false, false, 0)--,
                        --{tExampleWrapper.open, tExampleWrapper.close})
        --);

        --store all input BlockTags and log required ones found
        for nIndex, oBlockTag in ipairs({...} or arg) do
            --validate the type
            type.assert.custom(oBlockTag, "DoxBlockTag");

            --search for required blocktags conflicts
            for _, oBuiltInBlockTag in pairs(pri.blockTags) do

                for sAlias in oBuiltInBlockTag.eachAlias() do

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
    eachBlockTag__FNL = function(this, cdat)
        local nIndex    = 0;
        local nMax      = #cdat.pri.blockTags;

        while nIndex < nMax do
            local oBlockTag = cdat.pri.blockTags[nIndex];
            return oBlockTag.getDisplay(), oBlockTag;
        end

    end,
    getBlockTagByDisplay__FNL = function(this, cdat, sDisplay)
        type.assert.string(sDisplay, "%S+");
        local vRet;

        for _, oBlockTag in ipairs(cdat.pri.blockTags) do

            if (oBlockTag.getDisplay() == sDisplay) then
                vRet = oBlockTag;
                break;
            end

        end

        return vRet;
    end,
},
{--public
    addMimeType__FNL = function(this, cdat, oDoxMime)
        type.assert.custom(oDoxMime, "DoxMime");
        pri.mimeTypes.add(oDoxMime.getName(), oDoxMime);
    end,
    --[[!
    @fqxn Dox.Methods.eachBlockTag
    @desc Returns an iterator that returns each <a href="#Dox.Components.DoxBlockTag">DoxBlockTag</a> available to the instance.
    @return function fIterator The iterator.
    !]]
    eachBlockTag__FNL = function(this, cdat)
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
    export__FNL = function(this, cdat, sFilename, bPulsar)
        local pri           = cdat.pri;
        local eBuilder      = pri.builder;
        local cBuilder      = pri.builder.value;
        local eBuilderMime  = cBuilder.getMime();
        --print(serialize(pri.finalized))
        --get or create the filename (or use the builder's default)
        sFilename = (rawtype(sFilename) == "string" and sFilename:isfilesafe())         and
                    sFilename                                                           or
                    (pri.title:isfilesafe() and pri.title or cBuilder.getDefaultFilename());

        --TODO use proper directory separator
        local pOut = pri.OutputPath.."\\"..sFilename.."."..eBuilderMime.value;
        pri.output = cBuilder.build(pri.title, pri.Intro, pri.finalized);--TODO clone table?

        local function writeFile(pFile, sContent)
            local hFile = io.open(pFile, "w");
            if not hFile then
                error("Error outputting Dox: Can't write to file, '"..pFile.."'.", 3)--TODO nice error message
            end

            hFile:write(sContent)
            hFile:close();
        end

        writeFile(pOut, pri.output);
    end,
    getOutput__FNL = function(this, cdat)
        return cdat.pri.output;
    end,
    getSyntax__FNL = function(this, cdat)
        return cdat.pri.syntax;
    end,
    getMimeTypes__FNL = function(this, cdat)
        --return clone(cdat.pri.mimeTypes);--TODO this must return an iterator
        return cdat.pri.mimeTypes;
    end,
    getName__FNL = function(this, cdat)
        return cdat.pri.name;
    end,
    getBlockClose__FNL = function(this, cdat)
        return cdat.pri.blockClose;
    end,
    getBlockOpen__FNL = function(this, cdat)
        return cdat.pri.blockOpen;
    end,
    getTagOpen__FNL = function(this, cdat)
        return cdat.pri.tagOpen;
    end,
    --[[importDirectory__FNL = function(this, cdat, pDir, bRecursion)
        type.assert.string(pDir, "%S+");
        local bRecurse = bRecursion;

        if (rawtype(bRecurse) ~= "boolean") then
            bRecurse = false;
        end
        --TODO rewrite this to check for .doxignore files and .git!!!!!!!
        --local tFiles, tRel = io.dir(pDir, bRecurse, 0, cdat.pri.fileTypes);--TODO BUG FIX CHANGE this to use new mime table
        --local tMimeTypes = {};

    --    for _, sType in cdat.pri.mimeTypes() do
        --    tMimeTypes[#tMimeTypes + 1] = sType;
        --end

        local tFiles, tRel = io.dir(pDir, bRecurse, 0);--TODO BUG FIX CHANGE this to use new mime table

        --TODO THROW ERROR FOR FAILURE
        for _, pFile in pairs(tFiles) do
            cdat.pub.importFile(pFile, true);
        end

        cdat.pri.refresh();
    end,]]
    importFile__FNL = function(this, cdat, pFile)--, bSkipRefresh)
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

                --if not (bSkipRefresh) then
                --    cdat.pri.refresh();
                --end

            end

        end

    end,
    importFiles__FNL = function(this, cdat, tFiles)--, bSkipRefresh)
        type.assert.table(tFiles, "number", "string", 1);

        for nIndex, pFile in pairs(tFiles) do
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

                    --if not (bSkipRefresh) then
                    --    cdat.pri.refresh();
                    --end

                end

            end

        end

    end,
    importString__FNL = function(this, cdat, sInput, oDoxMime)--, bSkipRefresh)
        --TODO assert mime object
        type.assert.string(sInput);
        local sWorking = sInput;

        cdat.pri.extractBlockStrings(sWorking, oDoxMime);

        --if not (bSkipRefresh) then
        --    cdat.pri.refresh();
        --end

    end,
    refresh__FNL = function(this, cdat)
        cdat.pri.refresh();
    end,
    setBuilder__FNL = function(this, cdat, eBuilder)
        type.assert.custom(eBuilder, "Dox.BUILDER");
        cdat.pri.builder = eBuilder;
        --eBuilder.value.setSyntax(cdat.pri.syntax);
    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
