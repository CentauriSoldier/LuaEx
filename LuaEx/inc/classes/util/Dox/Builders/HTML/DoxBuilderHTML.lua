--load in the builder's required files
local _pRequirePath     = "LuaEx.inc.classes.util.Dox.Builders.HTML.Data";
--local _sBanner          = require(_pRequirePath..".Banner");
local _sCSS             = require(_pRequirePath..".CSS");
local _sHTML            = require(_pRequirePath..".HTML")
local _sJS              = require(_pRequirePath..".JS");
local _tPrismLanguages  = require(_pRequirePath..".PrismLanguages");
local _sPrismStable     = "1.29.0"; --TODO allow theme change
local _sPrismCSS        = '<link href="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/themes/prism-okaidia.min.css" rel="stylesheet" />' % {stable = _sPrismStable};
local _sPrismScript     = '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>' % {stable = _sPrismStable};--why is this not eing used? If not, delete it.

return class("DoxBuilderHTML",
{--METAMETHODS

},
{--STATIC PUBLIC

},
{--PRIVATE
    buildJS = function(this, cdat, tFinalizedData)
        local sRet          = "";
        local pri           = cdat.pri;
        local lineNumber    = 0;
        local bFound        = false;

        -- Read the input text line by line (split by newline character)
        for line in _sJS:gmatch("[^\r\n]+") do
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

        local sJSON = pri.buildJSONTable(tFinalizedData);
        return sJSON.."\n\n"..sRet;
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
                    local subtableResult = processTable(subtable, indent .. "    ")
                    local newstring = indent .. '"' .. key .. '": {\n' ..
                                      indent .. '    "value": "' .. pri.prepJSONString(value) .. '",\n' ..
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
                tFoundLanguages[_tPrismLanguages[lang]] = true
            else
                tFoundLanguages[lang] = true
            end
        end

        -- Generate the script tags
        local scripts = {}
        --insert the main prism js script
        table.insert(scripts, '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>' % {stable = _sPrismStable});

        --insert the js toolbar script
        table.insert(scripts, '<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.20.0/plugins/toolbar/prism-toolbar.js"></script>');--TODO use stable insertion for static value at '1.20.0'

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
        super(DoxBuilder.MIME.HTML, sCopyToClipBoardButton);
        local pro = cdat.pro;

        pro.blockWrapper.open       = '<div class="container-fluid">';
        pro.blockWrapper.close      = '</div>';
        pro.exampleWrapper.open     = '<pre><code class=\"language-';
        pro.exampleWrapper.close    = '</code></pre>';
        pro.exampleWrapper.close    = pro.exampleWrapper.close..
        '';
    end,
    build = function(this, cdat, sTitle, tFinalizedData)
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
        sHTML = sHTML % {__DOX__INTERNAL_JS__ = "const userData = "..pri.buildJS(tFinalizedData)};

        --insert the prism scripts for the found languages
        local sPrismScripts = pri.generatePrismScripts(sHTML);
        sHTML = sHTML % {__DOX__PRISM__SCRIPTS__ = sPrismScripts};

        return sHTML;
    end,
    getExampleWrapper = function(this, cdat, eSyntax)
        type.assert.custom(eSyntax, "Dox.SYNTAX");
        local tRet = clone(cdat.pro.exampleWrapper);
        tRet.open = tRet.open..eSyntax.value.getPrismName()..'">';
        return tRet;
    end,
},
DoxBuilder, --extending class
false,      --if the class is final
nil         --interface(s) (either nil, or interface(s))
);
