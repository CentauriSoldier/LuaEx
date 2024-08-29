--[[!
@fqxn Dox.Components.DoxBuilder
@desc This is the class (when subclassed) that builds the output using Dox's finalized data.
!]]
return class("DoxBuilder",
{--METAMETHODS

},
{--STATIC PUBLIC
    MIME = enum("DoxBuilder.MIME", {"HTML", "MARKDOWN", "TXT"}, {"html", "MD", "txt"}, true),
},
{--PRIVATE
    mime = null,
},
{--PROTECTED
    blockWrapper = {
        open = "",
        close = "",
    },
    copyToClipboardButton = "",
    defaultFilename = "",
    exampleWrapper = {
        open = "",
        close = "",
    },
},
{--PUBLIC
    DoxBuilder = function(this, cdat, eMime, sCopyToClipBoardButton, sDefaultFilename)
        type.assert.custom(eMime, "DoxBuilder.MIME");
        type.assert.string(sDefaultFilename, "%S+");
        assert(sDefaultFilename:isfilesafe(), "Error creating DoxBuilder. Default filename must be a file-safe string.");

        --TODO assert copy to clipboard input
        local pri = cdat.pri;
        local pro = cdat.pro;

        pri.mime                    = eMime;
        pro.copyToClipboardButton   = sCopyToClipBoardButton;
        pro.defaultFilename         = sDefaultFilename;
    end,
    --[[!
    @fqxn Dox.Components.DoxBuilder.Methods.build
    @desc This is the build method that does the heavy lifting in building the output file.
    <br><br>After the basic <em>this</em> and <em>cdat</em> parameters, this method must accept the following parameters in the following order:
    <ol>
        <li><em>(string)</em> <strong>sTitle</strong> The title of the documentation project.</li>
        <li><em>(string or nil)</em> <strong>vIntro</strong> The (optional) intro page code. If not provided here, the intro will be the default provided by Dox.</li>
        <li><em>(table)</em> <strong>tFinalizedData</strong> Dox's finalized data used to build the output document.</li>
        The finalized data table has keys of strings whose values are strings. The table is a heirarchical list of fqxn's (Fully Qualified Dox Names). The data for each item is stored in the <em><strong>__call</strong></em> metamethod. To extract teh data from a given index, simply call it. A string will be returned containing the item's data.
    </ol>
    !]]
    build = function(this, cdat)
        error("Error in DoxBuilder. The 'build' method has not been defined", 4);
    end,
    getCopyToClipboardButton = function(this, cdat)
        return cdat.pro.copyToClipboardButton;
    end,
    getDefaultFilename = function(this, cdat)
        return cdat.pro.defaultFilename;
    end,
    getBlockWrapper = function(this, cdat)
        return clone(cdat.pro.blockWrapper);
    end,
    getMime = function(this, cdat)
        return cdat.pri.mime;
    end,
    getExampleWrapper = function(this, cdat, eSyntax)
        type.assert.custom(eSyntax, "Dox.SYNTAX");
        return clone(cdat.pro.exampleWrapper);
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
