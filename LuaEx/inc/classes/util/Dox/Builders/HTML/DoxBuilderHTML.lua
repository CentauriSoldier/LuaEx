--load in the builder's required files
local _pRequirePath     = "LuaEx.inc.classes.util.Dox.Builders.HTML.Data";
--local _sBanner          = require(_pRequirePath..".Banner");
local _sCSS             = require(_pRequirePath..".CSS");
local _sHTML            = require(_pRequirePath..".HTML")
local _sJS              = require(_pRequirePath..".JS");
local _tPrismLanguages  = require(_pRequirePath..".PrismLanguages");
local _sPrismStable     = "1.30.0"; --TODO allow theme change
local _sPrismCSS        = '<link href="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/themes/prism-okaidia.min.css" rel="stylesheet" />' % {stable = _sPrismStable};
local _sPrismScript     = '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>' % {stable = _sPrismStable};--why is this not being used? If not, delete it.
local _sDefaultFilename = "index";


return class("DoxBuilderHTML",
{--METAMETHODS

},
{--STATIC PUBLIC

},
{--PRIVATE
    buildJS = function(this, cdat, sIntro, tFinalizedData)
        local sRet          = "";
        local pri           = cdat.pri;
        local nLine         = 0; --TODO QUESTION is this used?
        local bFound        = false;
        local bIntro        = (rawtype(sIntro) == "string" and sIntro:find("%S+") ~= nil);
        local sIntro        = bIntro and sIntro or "";
        local sStartRead    = bIntro and "//—©_END_DOX_DEFAULT_INTRO_©—" or "//—©_END_DOX_TESTDATA_©—";
--
        --if a proper intro string has been provided, prep it
        if (bIntro) then
            sIntro = [[

    const doxData = {
        "Modules": {
            "value": `

            <div class="DOX_intro container">
                <div class="row">
                    <div class="col-lg-12">
                        <div class="p-5 rounded">

        ]]..sIntro:gsub("`", "\\`"):gsub("${", "\\${")..[[

                        </div>
                    </div>
                </div>
            </div>

        `,
        "subtable": userData
        }
    };

    ]];
        end

        -- Read the input text line by line (split by newline character)
        for sLine in _sJS:gmatch("[^\r\n]+") do
            nLine = nLine + 1;

            -- Check if the search string is in the current line
            if bFound then
                sRet = sRet .. sLine .. "\n";
            elseif string.find(sLine, sStartRead, 1, true) then
                bFound = true;
            end
        end

        if not bFound then
            return nil, "String not found in the input." --TODO better error message
        end

        local sUserData = "const userData = "..pri.buildJSONTable(tFinalizedData);
        return sUserData.."\n\n"..sIntro.."\n\n"..sRet;
    end,
    buildJSONTable = function(this, cdat, tFinalizedData) --TODO clean up
        local pri        = cdat.pri;

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
                    --prep the value
                    value = pri.prepJSONString(value):gsub('`', "\\`"):gsub("${", "\\${");
                    local subtableResult = processTable(subtable, indent .. "    ")
                    local newstring = indent .. '"' .. key:gsub(" ", "%%20") .. '": {\n' ..
                                      indent .. '    "value": `' .. value .. '`,\n' ..
                                      indent .. '    "subtable": ' .. (next(subtableResult) and "{\n" .. table.concat(subtableResult, ",\n") .. "\n" .. indent .. "    }" or "null") .. '\n' ..
                                      indent .. '}'
                    table.insert(result, newstring)
                end

                return result
            end

            local jsonResult = processTable(tbl, indentSpace);
            return "{\n" .. table.concat(jsonResult, ",\n") .. "\n" .. indentSpace .. "}"
        end

        -- Convert the Lua table to JSON format
        local nIndentSpaces = 4
        return luaTableToJson(tFinalizedData, nIndentSpaces)
    end,
    generatePrismScripts = function(this, cdat, sHTML)
        -- Define the mapping between language tags and script URLs
        local prismBaseURL = "https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/components/prism-" % {stable = _sPrismStable};

        -- Set to store found languages to avoid duplicates
        local tFoundLanguages = {};

        -- Pattern to match the code blocks with language tags
        for lang in sHTML:gmatch('class=\\"language%-(%w+)\\"') do
        --for lang in sHTML:gmatch('class="language-lua"') do

            -- Check if the language is supported and add it to the set
            if _tPrismLanguages[lang] then
                tFoundLanguages[_tPrismLanguages[lang]] = true;
            else
                tFoundLanguages[lang] = true;
            end

        end

        -- Generate the script tags
        local scripts = {}
        --insert the main prism js script
        table.insert(scripts, '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>' % {stable = _sPrismStable});

        --insert the js toolbar script
        table.insert(scripts, '<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/plugins/toolbar/prism-toolbar.js"></script>' % {stable = _sPrismStable});--TODO use stable insertion for static value at '1.20.0'

        --insert the various languages
        for lang, _ in pairs(tFoundLanguages) do
            table.insert(scripts, string.format('<script src="%s%s.min.js"></script>', prismBaseURL, lang))
        end

        return table.concat(scripts, "\n")
    end,
    prepJSONString = function(this, cdat, s)
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
{--PROTECTED
},
{--PUBLIC
    DoxBuilderHTML = function(this, cdat, super)
        local sCopyToClipBoardButton = '<button class="copy-to-clipboard-button" onclick="Dox.copyToClipboard(this)">Copy</button>';
        local pro = cdat.pro;

        pro.blockWrapper.open       = '<div class="container-fluid">';
        pro.blockWrapper.close      = '</div>';
        --pro.exampleWrapper.open     = '<pre><code class=\"language-';
        --pro.exampleWrapper.close    = '</code></pre>';
        --pro.exampleWrapper.close    = pro.exampleWrapper.close..'';--QUESTION WHAT IS THIS LINE HERE FOR?

        local tColumnWrappers = {
            ["Parameter(s)"] = {
                [1] = {"<strong><em>", "</em></strong>"},
                [2] = {"<em>", "</em>"},
            },
            ["Field(s)"] = {
                [1] = {"<strong><em>", "</em></strong>"},
                [2] = {"<em>", "</em>"},
            },
            ["Field(s) - Private"] = {
                [1] = {"<strong><em>", "</em></strong>"},
                [2] = {"<em>", "</em>"},
            },
            ["Field(s) - Protected"] = {
                [1] = {"<strong><em>", "</em></strong>"},
                [2] = {"<em>", "</em>"},
            },
            ["Field(s) - Public"] = {
                [1] = {"<strong><em>", "</em></strong>"},
                [2] = {"<em>", "</em>"},
            },
            ["Field(s) - Static Private"] = {
                [1] = {"<strong><em>", "</em></strong>"},
                [2] = {"<em>", "</em>"},
            },
            ["Field(s) - Static Public"] = {
                [1] = {"<strong><em>", "</em></strong>"},
                [2] = {"<em>", "</em>"},
            },
            ["Return(s)"] = {
                [1] = {"<strong><em>", "</em></strong>"},
                [2] = {"<em>", "</em>"},
            },
            ["Code"] = {
                [1] = {"<pre>", "</pre>"},
            },
            ["Example"] = { --TODO FINISH make this dynamic for the default prism language type NOTE: I can probably use metatables if i can get them to stop being infinitely recusive
                [1] = {"<pre><code class=\"language-lua\">", "</code></pre>"},
            },
            --[""] = {},
        };

        super("DoxBuilderHTML", DoxBuilder.MIME.HTML, sCopyToClipBoardButton, _sDefaultFilename, "<br>", tColumnWrappers);

        --[[set the DoxBlockTag column wrappers
        for sDisplay, oBlockTag in pro.eachBlockTag() do

            if (tColumnWrappers[sDisplay] ~= nil) then

                for _, tWrapper in ipairs(tColumnWrappers[sDisplay]) do
                    --TODO here's where the magic happens
                end

            end

        end]]

    end,
    build = function(this, cdat, sTitle, sIntro, tFinalizedData)
        type.assert.string(sTitle);
        local pri        = cdat.pri;

        --update and write the html
        local sHTML = _sHTML % {__DOX__CSS__ = _sCSS};
        sHTML = sHTML % {
            --__DOX_BANNER__URL__     = _sBanner:gsub("\n", ''), --TODO allow custom banner
            __DOX__TITLE__          = sTitle,
            __DOX__PRISM_CSS__      = _sPrismCSS,
        };

        --inject the javascript
        sHTML = sHTML % {__DOX__INTERNAL_JS__ = pri.buildJS(sIntro, tFinalizedData)};

--print(pri.buildJS("", tFinalizedData))
        --insert the prism scripts for the found languages
        local sPrismScripts = pri.generatePrismScripts(sHTML);
        sHTML = sHTML % {__DOX__PRISM__SCRIPTS__ = sPrismScripts};

        return sHTML;
    end,
    formatBlockContent = function(this, cdat, sID, sDisplay, sContent) --TODO FINISH move these into the refresh method now that it's done
        return [[<div class="custom-section"><div${id} class="section-title">${display}</div><div class="section-content">${content}</div></div>]] % {id = sID, display = sDisplay, content = sContent};
    end,
    formatCombinedBlockContent = function(this, cdat, sDisplay, sCombinedContent)
        --TODO note somewhere that combined items cannot have IDs (they are simply blank...all non examples are...but code should have IDs!!!! TODO that)
        return [[<div class="custom-section"><div${id} class="section-title">${display}</div><div class="section-content">${content}</div></div>]] % {id = "", display = sDisplay, content = sCombinedContent};
    end,
    --[[getExampleWrapper = function(this, cdat, eSyntax)
        type.assert.custom(eSyntax, "Dox.SYNTAX");
        local tRet = clone(cdat.pro.exampleWrapper);
        tRet.open = tRet.open..eSyntax.value.getPrismName()..'">';
        return tRet;
    end,]]
    refresh = function(this, cdat, tBlocks, fProcessBlockItem)
        local pro = cdat.pro;
        local pub = cdat.pub;

        local tBlockWrapper     = pro.blockWrapper;
        local sBuilderNewLine   = pro.newLine;
        local tInheritDocs      = {};
        local tFinalized        = {};

        --inject all block strings into finalized data table
        for _, oBlock in pairs(tBlocks) do
            local tActive = tFinalized;

            for bLastItem, nFQXNIndex, sFQXN in oBlock.fqxn() do --bLastItem is a boolean? Don't think so

                --create the active table if it doesn't exist
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

            --local tCombinedBlockItems   = {};
            local tToCombine = {};

            --check for and concat combineable items
            for oBlockTag, sRawInnerContent in oBlock.eachItem() do

                if not (oBlockTag.isUtil()) then
                    local bIsCombined = oBlockTag.isCombined();

                    if (bIsCombined) then
                        local sDisplay  = oBlockTag.getDisplay();

                        --create the blocktag index if it doesn't exist
                        if (tToCombine[sDisplay] == nil) then
                            tToCombine[sDisplay] = {};
                        end

                        --append the item to be combined
                        tToCombine[sDisplay][#tToCombine[sDisplay] + 1] = fProcessBlockItem(oBlockTag, sRawInnerContent);
                    end

                end

            end

            --create the content string
            local sContent = tBlockWrapper.open;
            --keep track of combined items so they don't duplicated
            local tCompletedDisplays = {};

            --build the row (block item)
            for oBlockTag, sRawInnerContent in oBlock.eachItem() do

                if not (oBlockTag.isUtil()) then
                    local sDisplay      = oBlockTag.getDisplay();
                    local sInnerContent = "";

                    --check for inheritdoc
                    if (sDisplay == "Inheritdoc") then
                        --store the table index with the value of the inner content to be processed later
                        tInheritDocs[tActive] = sRawInnerContent;
                    else

                        if not (tCompletedDisplays[sDisplay]) then
                            --process combineable items
                            if (oBlockTag.isCombined()) then
                                local sCombinedContent = "";

                                local nMaxItems = #tToCombine[sDisplay];
                                for nIndex, tBlockItemData in ipairs(tToCombine[sDisplay]) do
                                    local sNewLine = nIndex < nMaxItems and sNewLine or sBuilderNewLine;
                                    sCombinedContent = sCombinedContent..tBlockItemData.content..sNewLine;
                                end

                                sInnerContent = pub.formatCombinedBlockContent(sDisplay, sCombinedContent);

                                --delete the entry since we're done processing this display item
                                tCompletedDisplays[sDisplay] = true;

                            else --process non-combineable items
                                local tBlockItemData = fProcessBlockItem(oBlockTag, sRawInnerContent);
                                sInnerContent = pub.formatBlockContent(tBlockItemData.id, tBlockItemData.display, tBlockItemData.content);
                            end

                            sContent = sContent..sInnerContent;
                        end

                    end

                end

            end

            --set the call to get the content
            setmetatable(tActive, {
                __call = function(t)
                    return sContent..tBlockWrapper.close;
                end,
            });

        end

        --check for and apply inherited docs
        for tTargetIndex, sLinkRaw in pairs(tInheritDocs) do

            --create the potential link
            local tLink  = string.totable(sLinkRaw, '.');
            --build the index to validate
            local tIndex = tFinalized;

            --check the link's validity as it's built
            for __, sFQXN in pairs(tLink) do

                if (tIndex[sFQXN] == nil) then
                    error("Error creating inherited dox block. FQXN, '${fqxn}', is nil.\nThis is likey caused by the docs to be inherited, not existing.\nPlease check that the doc link exists." % {fqxn = sFQXN}); --TODO FINISH ERROR
                end

                tIndex = tIndex[sFQXN];
            end

            --get the replacement content
            local sFinalizedContent = tIndex();

            --if no error was thrown, the index is valid. Set the new content
            setmetatable(tTargetIndex, {
                __call = function(t)
                    return sFinalizedContent;
                end,
            });

        end

        return tFinalized;
    end,
},
DoxBuilder, --extending class
false,      --if the class is final
nil         --interface(s) (either nil, or interface(s))
);
