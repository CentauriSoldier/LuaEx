local sImportError = "Cannot import column wrapper into DoxBuilder.";
--[[!
@fqxn Dox.Builders.DoxBuilder
@desc This is the class (when subclassed) that builds the output using Dox's finalized data.
!]]
return class("DoxBuilder",
{--METAMETHODS

},
{--STATIC PUBLIC
    MIME = enum("DoxBuilder.MIME", {"HTML", "LUACOMPLETERC", "MARKDOWN", "TXT"}, {"html", "luacompleterc", "MD", "txt"}, true),
},
{--PRIVATE
    mime = null,
},
{--PROTECTED
    blockWrapper = {
        open = "",
        close = "",
    },
    columnWrappers = {},
    copyToClipboardButton = "",
    defaultFilename = "",
    exampleWrapper = {
        open = "",
        close = "",
    },
    newLine = "",
--@param ... varargs Zero to nMaxColumnCount column wrappers. Each column wrapper should be a numerically-indexed table (of two) whose values are strings containing the start and end (respectively) column wrapper item.
    DoxBuilder = function(this, cdat, eMime, sCopyToClipBoardButton, sDefaultFilename, sNewLine, tColumnWrappers)
        type.assert.custom(eMime, "DoxBuilder.MIME");
        type.assert.string(sDefaultFilename);
        assert(sDefaultFilename:isfilesafe(), "Error creating DoxBuilder. Default filename must be a file-safe string.");

        --TODO assert copy to clipboard input
        local pri = cdat.pri;
        local pro = cdat.pro;

        pri.mime                    = eMime;
        pro.copyToClipboardButton   = type(sCopyToClipBoardButton) == "string" and sCopyToClipBoardButton or "";
        pro.defaultFilename         = sDefaultFilename;
        pro.newLine                 = rawtype(sNewLine) == "string" and sNewLine or "\n";

        --import column wrappers
        if (type(tColumnWrappers) == "table") then
            type.assert.table(tColumnWrappers, "string", "table", nil, nil, sImportError.."Expected wrapper tables.");--TODO Full message

            for sDisplay, tWrapper in pairs(tColumnWrappers) do
                type.assert.string(sDisplay, "%S+", sImportError.."Expected string index. Got "..type(sDisplay)..'.');
                type.assert.table(tWrapper, "number", "string", 2, 2, sImportError.."Expected numerically-indexed wrapper table with string values.");

                pro.columnWrappers[sDisplay] = {};

                for nIndex, sWrapper in ipairs(tWrapper) do
                    pro.columnWrappers[sDisplay][nIndex] = sWrapper;
                end

            end

        end

    end,
},
{--PUBLIC
    --[[!
    @fqxn Dox.Builders.DoxBuilder.Methods.build
    @desc This is the build method that does the heavy lifting in building the output file.
    <br><br>After the basic <em>this</em> and <em>cdat</em> parameters, this method must accept the following parameters in the following order:
    <ol>
        <li><em>(string)</em> <strong>sTitle</strong> The title of the documentation project.</li>
        <li><em>(string or nil)</em> <strong>vIntro</strong> The (optional) intro page code. If not provided here, the intro will be the default provided by Dox.</li>
        <li><em>(table)</em> <strong>tFinalizedData</strong> Dox's finalized data used to build the output document.</li>
        The finalized data table has keys of strings whose values are strings. The table is a heirarchical list of fqxn's (Fully Qualified Dox Names). The data for each item is stored in the <em><strong>__call</strong></em> metamethod. To extract the data from a given index, simply call it. A string will be returned containing the item's data.
    </ol>
    !]]
    build = function(this, cdat)
        error("Error in DoxBuilder. The 'build' method has not been defined in the child class.", 4);
    end,
    --TODO FINISH allow optional sDisplay input to clear only that wrapper
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.clearColumnWrappers
    @desc Removes all column wrappers.
    !]]
    clearColumnWrappers = function(this, cdat)
        pri.columnWrappers = {};
    end,
    --TODO FINISH
    --eachColumnWrapper = function() --TODO make this work using nIndex
    --    return next, clone(cdat.pri.columnWrappers[nColumn]), nil;
    --end,
    formatBlockContent = function(this, cdat, sID, sDisplay, sContent)
        error("Error in DoxBuilder. The 'formatNonCombinedBlockContent' method has not been defined in the child class.", 4);
    end,
    formatCombinedBlockContent = function(this, cdat, sDisplay, sCombinedContent)
        error("Error in DoxBuilder. The 'formatCombinedBlockContent' method has not been defined in the child class.", 4);
    end,
    --TODO FINISH DOCS
    getColumnWrapper = function(this, cdat, sDisplay, nColumn)
        local tColumnWrappers = cdat.pro.columnWrappers;
        local tRet = {
            [1] = "",
            [2] = "",
        };

        if (tColumnWrappers[sDisplay] ~= nil) then
            local tWrappers = tColumnWrappers[sDisplay];

            if (tWrappers[nColumn] ~= nil) then
                tRet = clone(tWrappers[nColumn]);
            end

        end

        return tRet;
    end,
    --TODO FINISH DOCS
    getColumnWrappers = function(this, cdat, sDisplay)
        local tColumnWrappers = cdat.pro.columnWrappers;
        local tRet = {};

        if (tColumnWrappers[sDisplay] ~= nil) then
            tRet = clone(tColumnWrappers[sDisplay]);
        end

        return tRet;
    end,
    --[[!
    @fqxn Dox.Builders.DoxBuilder.Methods.getColumnWrapperCount
    @desc Gets the total number of column wrappers in this <strong>DoxBuilder</strong>.
    @return number nColumnWrappers The number of the column wrappers in this <strong>DoxBuilder</strong>.
    !]]
    getColumnWrapperCount = function(this, cdat, sDisplay)
        local nRet = 0;
        local tColumnWrappers = cdat.pro.columnWrappers;

        if (tColumnWrappers[sDisplay] ~= nil) then

            for _, __ in pairs(tColumnWrappers[sDisplay]) do
                nRet = nRet + 1;
            end

        end

        return nRet;
    end,
    getCopyToClipboardButton = function(this, cdat)
        return cdat.pro.copyToClipboardButton;
    end,
    --[[!
    @fqxn Dox.Builders.DoxBuilder.Methods.getDefaultFilename
    @desc Returns the default filename of the final ouput document that is used if one is not provided by the user.
    @ret string sFilename The default filename.
    !]]
    getDefaultFilename = function(this, cdat)
        return cdat.pro.defaultFilename;
    end,
    getBlockWrapper = function(this, cdat)
        return clone(cdat.pro.blockWrapper);
    end,
    getMime = function(this, cdat)
        return cdat.pri.mime;
    end,
    getNewLine = function(this, cdat)
        return cdat.pro.newLine;
    end,
    getExampleWrapper = function(this, cdat, eSyntax)
        type.assert.custom(eSyntax, "Dox.SYNTAX");
        return clone(cdat.pro.exampleWrapper);
    end,
    --TODO FINISH DOCS
    setColumnWrapper = function(this, cdat, sDisplay, nColumn, sOpen, sClose)
        local pro = cdat.pro;
        local tColumnWrappers = pro.columnWrappers;
        type.assert.string(sDisplay, "%S+");
        type.assert.number(nColumn, true, true, false, true, false);
        type.assert.string(sOpen, "%S+");
        type.assert.string(sClose, "%S+");

        if (tColumnWrappers[sDisplay] ~= nil) then
            local nWrapperCount = this.getColumnWrapperCount(sDisplay);

            if (math.abs(nWrapperCount - nColumn) > 1) then
                error("Error setting column wrapper for item, '"..sDisplay.."'. Column index "..nColumn.." is out of bounds.");
            end

            tColumnWrappers[sDisplay][nColumn] = {
                [1] = sOpen,
                [2] = sClose,
            };
        end
        
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
