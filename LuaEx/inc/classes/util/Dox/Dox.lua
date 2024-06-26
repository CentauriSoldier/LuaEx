local _nExampleInsertPoint  = 6; --where in the _tBuiltInBlockTags table to put the Example BlockTag
local _pStaticsRequirePath  = "LuaEx.inc.classes.util.Dox.Statics";
local _eSyntax              = require(_pStaticsRequirePath..".DoxSyntaxEnum");
local _tBuiltInBlockTags    = require(_pStaticsRequirePath..".BuiltInBlockTags");

--FIX copy button missing!
--TODO @inheritdoc if possible...
--TODO allow user to suround content block with (optional tags) tags...
--TODO color dead anchor links
--TODO FINISH PLANNED add option to get and print TODO, BUG, etc.
--TODO parse sinlge-line comments too
--TODO Allow internal anchor links
--TODO allow MoTD, custom banners etc.
--TODO ad dtooltip with @des info (if available) in sidemenu items

local assert    = assert;
local class     = class;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local type      = type;

local eOutputType = enum("DoxOutput", {"HTML"});--, "MD"});



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
        \@desc &lt;strong&gt;Dox&lt;/strong&gt; auto-generates documentation for code by reading and parsing comment blocks.
        <br>&lt;br&gt;
        <br>&lt;br&gt;&lt;strong&gt;Note&lt;/strong&gt;: Dox is intended only to be used by being subclassed.
        <br>&lt;br&gt;Subclasses of Dox (called parsers), provide the required parameters to
        <br>&lt;br&gt;properly parse comments blocks for specific languages.
        <br>&lt;br&gt;Running Dox stand-alone without subclassing it will yield unpredictable results.
        \@ex --Many Wow! How Yay! Much Meta!
        --...Meta End
    !\]\]
@ex
--for this example, we're using Lua

--create the Lua language parser object (with the project name)
local oDoxLua = DoxLua("MyProject");

--import a directory recursively (read & parse files)
oDoxLua.importDirectory(pPathToMyProject, true);

--set the output path
oDoxLua.setOutputPath("C:\\Users\\MyUsername\\MyProject");

--\[\[we don't need to set a Dox.BUILDER since it defaults
    to Dox.BUILDER.HTML and that's what we want\]\]

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
    --TODO move this out to the builder section and call it in
    BUILDER = enum("Dox.BUILDER", {"HTML"}, {DoxBuilderHTML()}, true),
    OUTPUT  = eOutputType,
    SYNTAX  = _eSyntax,
},
{--private
    --[[@qxn Classes.Utility.Dox.Properties]]
    blockOpen           = "",
    blockClose          = "",
    blockTags           = {},
    blockStrings        = {};
    builder             = null,
    --[[!@fqxn Classes.Utility.Dox.Fields.Private @field finalized The finalized data once imported items have been refreshed.!]]
    finalized           = {}; --this is the final, processed data (updated using the refresh() method)
    html                = "", --this is updated on refresh
    mimeTypes           = SortedDictionary(), --TODO throw error on removal of last item
    name                = "",
    output              = "",
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

        --TODO BUG FIX This CANNOT be here...it has to be gotten from the DoxBuilder
        return [[<div class="custom-section"><div class="section-title">${display}</div><div class="section-content">${content}</div></div>]] %
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
        local tBlockWrapper = pri.builder.value.getBlockWrapper();

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


            --TODO BUG FIX This CANNOT be here...it has to be gotten from the DoxBuilder
            --create the content string
            local sContent = tBlockWrapper.open;

            --build the row (block item)
            for oBlockTag, sRawInnerContent in oBlock.items() do
                local sInnerContent = pri.processBlockItem(oBlockTag, sRawInnerContent);
                sContent = sContent..sInnerContent;
            end

            --set the call to get the content
            setmetatable(tActive, {
                __call = function(t)
                    return sContent..tBlockWrapper.close;
                end,
            })

        end

    end,
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
        pri.builder             = Dox.BUILDER.HTML; --default builder
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
        local tExampleWrapper = pri.builder.value.getExampleWrapper(eSyntax);
        table.insert(pri.blockTags, _nExampleInsertPoint,
            DoxBlockTag({"ex", "example"}, "Example", false, true, 0,
                        {tExampleWrapper.open, tExampleWrapper.close})
        );

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
    export_FNL = function(this, cdat, bPulsar) --TODO puslar snippets
        local pri           = cdat.pri;
        local eBuilder      = pri.builder;
        local cBuilder      = pri.builder.value;
        local eBuilderMime  = cBuilder.getMime();

        --TODO use proper directory separator
        local pOut = pri.OutputPath.."\\"..pri.title.."."..eBuilderMime.value;
        pri.output = cBuilder.build(pri.title, pri.finalized);--TODO clone table?

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
    getOutput = function(this, cdat)
        return cdat.pri.output;
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
    setBuilder = function(this, cdat, eBuilder)
        assert(type.isa(eBuilder, Dox.BUILDER), "Error setting Dox Builder.\nExpected type DoxBuilder (subclass). Got type "..type(eBuilder)..'.');
        cdat.pri.builder = eBuilder;
    end,
},
nil,    --extending class
false,  --if the class is final
nil     --interface(s) (either nil, or interface(s))
);
