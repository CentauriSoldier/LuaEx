--LOCALIZATION
local class     = class;
local rawtype   = rawtype;
local ipairs    = ipairs;
local pairs     = pairs;
local string    = string;
local table     = table;
local utf8      = utf8;

local tEntities = {
    amp     = "&",
    apos    = "'",
    gt      = ">",
    lt      = "<",
    quot    = '"',
};

--[[!
    @fqxn LuaEx.Classes.XML.Helpers.isCharacter
    @desc Checks the XML 1.0 character ranges after UTF-8 decoding.
    @param number nCode Unicode codepoint.
    @ret boolean bAllowed Whether the character is legal in XML 1.0.
    @scope local
!]]
local function isCharacter(nCode)

    return nCode == 9 or nCode == 10 or nCode == 13
           or (nCode >= 0x20 and nCode <= 0xD7FF)
           or (nCode >= 0xE000 and nCode <= 0xFFFD)
           or (nCode >= 0x10000 and nCode <= 0x10FFFF);
end


--[[!
    @fqxn LuaEx.Classes.XML.Helpers.isNameStart
    @desc Checks XML 1.0 NameStartChar, including qualified names and Unicode ranges.
    @param number nCode Unicode codepoint.
    @ret boolean bAllowed Whether a name may start with this character.
    @scope local
!]]
local function isNameStart(nCode)

    if (nCode == 58 or nCode == 95 or (nCode >= 65 and nCode <= 90)
        or (nCode >= 97 and nCode <= 122)) then
        return true;
    end

    local tRanges = {
        {0xC0, 0xD6}, {0xD8, 0xF6}, {0xF8, 0x2FF}, {0x370, 0x37D},
        {0x37F, 0x1FFF}, {0x200C, 0x200D}, {0x2070, 0x218F},
        {0x2C00, 0x2FEF}, {0x3001, 0xD7FF}, {0xF900, 0xFDCF},
        {0xFDF0, 0xFFFD}, {0x10000, 0xEFFFF},
    };

    for _, tRange in ipairs(tRanges) do
        if (nCode >= tRange[1] and nCode <= tRange[2]) then
            return true;
        end
    end

    return false;
end


--[[!
    @fqxn LuaEx.Classes.XML.Helpers.isNameCharacter
    @desc Checks the additional characters allowed after the beginning of an XML name.
    @param number nCode Unicode codepoint.
    @ret boolean bAllowed Whether this codepoint belongs to a name.
    @scope local
!]]
local function isNameCharacter(nCode)

    return isNameStart(nCode) or nCode == 45 or nCode == 46 or nCode == 0xB7
           or (nCode >= 48 and nCode <= 57)
           or (nCode >= 0x300 and nCode <= 0x36F)
           or (nCode >= 0x203F and nCode <= 0x2040);
end


--[[!
    @fqxn LuaEx.Classes.XML.Helpers.parseDocument
    @desc Reads the supported UTF-8 XML 1.0 subset into an ordered document tree.
    Rejects malformed input and unsupported DTDs/encodings. Resolves predefined and
    numeric character references. Qualified names are preserved, not namespace-expanded.
    @param string sInput Complete XML source containing exactly one root element.
    @ret table tDocument Document with root, ordered content and declaration metadata.
    @scope local
!]]
local function parseDocument(sInput)

    assert(rawtype(sInput) == "string", "XML source must be a string.");

    -- Step 1: remove the UTF-8 BOM and normalize physical XML line endings.
    local sSource = sInput;

    if (sSource:sub(1, 3) == "\239\187\191") then
        sSource = sSource:sub(4);
    end

    sSource = sSource:gsub("\r\n", "\n"):gsub("\r", "\n");
    local nPosition = 1;
    local nLength = #sSource;
    local tDocument = { content = {}, declaration = {} };
    local tStack = {};

    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.fail
        @desc Raises a parser diagnostic using normalized line and character-column positions.
        @param string sReason Failure explanation.
        @param number|nil nAt Byte position; defaults to the current parser cursor.
        @scope local
    !]]
    local function fail(sReason, nAt)

        nAt = nAt or nPosition;
        local sPrefix = sSource:sub(1, nAt - 1);
        local _, nLines = sPrefix:gsub("\n", "");
        local sLine = sPrefix:match("([^\n]*)$") or "";
        local nColumn = (utf8.len(sLine) or #sLine) + 1;
        error("XML at line "..(nLines + 1)..", column "..nColumn..": "..sReason, 0);
    end

    -- Validate bytes before any name scanning assumes UTF-8 boundaries.
    local nCharacters, nInvalid = utf8.len(sSource);

    if (not nCharacters) then
        fail("Input is not valid UTF-8.", nInvalid);
    end

    for nAt, nCode in utf8.codes(sSource) do
        if (not isCharacter(nCode)) then
            fail("Forbidden XML character.", nAt);
        end
    end

    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.starts
        @desc Compares a literal token with the source at the current cursor.
        @param string sToken Token to check.
        @ret boolean bMatches Whether the source begins with this token at the cursor.
        @scope local
    !]]
    local function starts(sToken)

        return sSource:sub(nPosition, nPosition + #sToken - 1) == sToken;
    end

    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.skipSpace
        @desc Advances past XML whitespace after physical line-ending normalization.
        @ret boolean bSkipped Whether at least one whitespace character was consumed.
        @scope local
    !]]
    local function skipSpace()

        local nStart = nPosition;

        while (sSource:sub(nPosition, nPosition):match("[ \t\n]")) do
            nPosition = nPosition + 1;
        end

        return nPosition > nStart;
    end

    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.readName
        @desc Reads a valid Unicode XML name and advances by UTF-8 character boundaries.
        @ret string sName Literal qualified name; namespaces are not resolved here.
        @scope local
    !]]
    local function readName()

        local nStart = nPosition;

        if (nPosition > nLength or not isNameStart(utf8.codepoint(sSource, nPosition))) then
            fail("Expected an XML name.");
        end

        nPosition = utf8.offset(sSource, 2, nPosition) or nLength + 1;

        while (nPosition <= nLength and isNameCharacter(utf8.codepoint(sSource, nPosition))) do
            nPosition = utf8.offset(sSource, 2, nPosition) or nLength + 1;
        end

        return sSource:sub(nStart, nPosition - 1);
    end

    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.decode
        @desc Resolves predefined and numeric references in one pass, rejecting illegal codepoints.
        @param string sText Raw attribute or character data.
        @param number nAt Source byte offset for failure diagnostics.
        @ret string sDecoded Entity-decoded UTF-8 text.
        @scope local
    !]]
    local function decode(sText, nAt)

        local tParts = {};
        local nStart = 1;

        -- Resolve references once. Decoded ampersands are not interpreted a second time.
        while (true) do
            local nAmp = sText:find("&", nStart, true);

            if (not nAmp) then
                tParts[#tParts + 1] = sText:sub(nStart);
                break;
            end

            tParts[#tParts + 1] = sText:sub(nStart, nAmp - 1);
            local nEnd = sText:find(";", nAmp + 1, true);

            if (not nEnd) then
                fail("Unterminated entity reference.", nAt + nAmp - 1);
            end

            local sEntity = sText:sub(nAmp + 1, nEnd - 1);
            local sValue = tEntities[sEntity];

            if (not sValue) then
                local nCode;

                if (sEntity:match("^#%d+$")) then
                    nCode = tonumber(sEntity:sub(2), 10);
                elseif (sEntity:match("^#x%x+$")) then
                    nCode = tonumber(sEntity:sub(3), 16);
                end

                if (not nCode or not isCharacter(nCode)) then
                    fail("Unknown or invalid entity reference: &"..sEntity..";", nAt + nAmp - 1);
                end

                sValue = utf8.char(nCode);
            end

            tParts[#tParts + 1] = sValue;
            nStart = nEnd + 1;
        end

        return table.concat(tParts);
    end

    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.readAttributes
        @desc Reads whitespace-separated unique attributes with quoted values. Stops before
        the terminator, which the enclosing tag/declaration handler then consumes.
        @param string sTerminator Closing delimiter, either greater-than or question-mark/greater-than.
        @ret table tAttributes String values indexed by literal attribute names.
        @ret table tOrder Attribute-name sequence for XML declaration ordering checks.
        @scope local
    !]]
    local function readAttributes(sTerminator)

        local tAttributes = {};
        local tOrder = {};

        while (true) do
            local bSpace = skipSpace();

            if (starts(sTerminator) or (sTerminator == ">" and starts("/>"))) then
                break;
            end

            if (not bSpace) then
                fail("Attributes must be separated by whitespace.");
            end

            local sName = readName();

            if (tAttributes[sName] ~= nil) then
                fail("Duplicate attribute: "..sName..".");
            end

            skipSpace();

            if (not starts("=")) then
                fail("Expected '=' after attribute name.");
            end

            nPosition = nPosition + 1;
            skipSpace();
            local sQuote = sSource:sub(nPosition, nPosition);

            if (sQuote ~= '"' and sQuote ~= "'") then
                fail("Attribute values must be quoted.");
            end

            nPosition = nPosition + 1;
            local nStart = nPosition;
            local nEnd = sSource:find(sQuote, nStart, true);

            if (not nEnd) then
                fail("Unterminated attribute value.");
            end

            local sRaw = sSource:sub(nStart, nEnd - 1);

            if (sRaw:find("<", 1, true)) then
                fail("Literal '<' is forbidden in attributes.", nStart);
            end

            -- Literal attribute whitespace normalizes to spaces; numeric references remain exact.
            sRaw = sRaw:gsub("[\t\n]", " ");
            tAttributes[sName] = decode(sRaw, nStart);
            tOrder[#tOrder + 1] = sName;
            nPosition = nEnd + 1;
        end

        return tAttributes, tOrder;
    end

    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.append
        @desc Appends content to the current element or document, coalescing adjacent text.
        @param string|table vContent Decoded text or a markup node.
        @scope local
    !]]
    local function append(vContent)

        local tParent = tStack[#tStack];
        local tContent = tParent and tParent.content or tDocument.content;

        -- Mixed content retains exact ordering. Adjacent text/CDATA is coalesced.
        if (rawtype(vContent) == "string" and rawtype(tContent[#tContent]) == "string") then
            tContent[#tContent] = tContent[#tContent]..vContent;
        else
            tContent[#tContent + 1] = vContent;
        end
    end

    -- Step 2: scan markup with an explicit stack; quoted '>' never terminates a tag.
    while (nPosition <= nLength) do
        if (starts("<!--")) then
            local nEnd = sSource:find("-->", nPosition + 4, true);

            if (not nEnd) then
                fail("Unterminated comment.");
            end

            local sText = sSource:sub(nPosition + 4, nEnd - 1);

            if (sText:find("--", 1, true) or sText:sub(-1) == "-") then
                fail("Invalid '--' inside comment.");
            end

            append({ kind = "comment", text = sText });
            nPosition = nEnd + 3;
        elseif (starts("<![CDATA[")) then
            if (#tStack == 0) then
                fail("CDATA is only allowed inside the root element.");
            end

            local nEnd = sSource:find("]]>", nPosition + 9, true);

            if (not nEnd) then
                fail("Unterminated CDATA section.");
            end

            append(sSource:sub(nPosition + 9, nEnd - 1));
            nPosition = nEnd + 3;
        elseif (starts("<?")) then
            local nStart = nPosition;
            nPosition = nPosition + 2;
            local sTarget = readName();

            if (sTarget:lower() == "xml") then
                if (sTarget ~= "xml" or nStart ~= 1) then
                    fail("XML declaration must occur at the start of the document.", nStart);
                end

                local tDeclaration, tOrder = readAttributes("?>");

                if (sSource:sub(nStart, nPosition - 1):find("&", 1, true)) then
                    fail("Entity references are not allowed in the XML declaration.", nStart);
                end

                if (not tDeclaration.version) then
                    fail("XML declaration requires a version.", nStart);
                end

                if (tOrder[1] ~= "version" or tDeclaration.version ~= "1.0") then
                    fail("Only XML version 1.0 is supported.", nStart);
                end

                for nIndex, sField in ipairs(tOrder) do
                    if (sField ~= "version" and sField ~= "encoding" and sField ~= "standalone") then
                        fail("Unknown XML declaration field.", nStart);
                    end

                    if (sField == "encoding" and nIndex ~= 2) then
                        fail("Encoding must precede standalone in the XML declaration.", nStart);
                    end
                end

                if (tDeclaration.encoding and tDeclaration.encoding:upper() ~= "UTF-8") then
                    fail("Only UTF-8 XML encoding is supported.", nStart);
                end

                if (tDeclaration.standalone and tDeclaration.standalone ~= "yes"
                    and tDeclaration.standalone ~= "no") then
                    fail("Invalid standalone declaration.", nStart);
                end

                tDocument.declaration = tDeclaration;
                nPosition = nPosition + 2;
            else
                local nEnd = sSource:find("?>", nPosition, true);

                if (not nEnd) then
                    fail("Unterminated processing instruction.");
                end

                local sData = sSource:sub(nPosition, nEnd - 1);

                if (sData ~= "" and not sData:match("^[ \t\n]")) then
                    fail("Processing instruction target must be separated from its data.");
                end

                append({ kind = "processingInstruction", name = sTarget, text = sData });
                nPosition = nEnd + 2;
            end
        elseif (starts("<!")) then
            fail("DTD and other markup declarations are not supported.");
        elseif (starts("</")) then
            nPosition = nPosition + 2;
            local sName = readName();
            skipSpace();

            if (not starts(">")) then
                fail("Expected '>' after closing tag.");
            end

            local tParent = tStack[#tStack];

            if (not tParent or tParent.name ~= sName) then
                fail("Mismatched closing tag: "..sName..".");
            end

            tStack[#tStack] = nil;
            nPosition = nPosition + 1;
        elseif (starts("<")) then
            nPosition = nPosition + 1;
            local sName = readName();
            local tAttributes = readAttributes(">");
            local bEmpty = starts("/>");
            local tElement = {
                kind        = "element",
                name        = sName,
                attributes  = tAttributes,
                children    = {},
                content     = {},
            };
            local tParent = tStack[#tStack];

            if (tParent) then
                tParent.children[#tParent.children + 1] = tElement;
            elseif (tDocument.root) then
                fail("A document must have exactly one root element.");
            else
                tDocument.root = tElement;
            end

            append(tElement);

            if (not bEmpty) then
                tStack[#tStack + 1] = tElement;
            end

            nPosition = nPosition + (bEmpty and 2 or 1);
        else
            local nEnd = sSource:find("<", nPosition, true) or nLength + 1;
            local sText = sSource:sub(nPosition, nEnd - 1);

            if (#tStack == 0) then
                if (sText:find("[^ \t\n]")) then
                    fail("Text is not allowed outside the root element.");
                end

                append(sText);
            else
                if (sText:find("]]>", 1, true)) then
                    fail("']]>' is forbidden outside CDATA.");
                end

                append(decode(sText, nPosition));
            end

            nPosition = nEnd;
        end
    end

    -- Step 3: ensure the complete root boundary closed before returning any document.
    if (#tStack > 0) then
        fail("Unclosed element: "..tStack[#tStack].name..".");
    end

    if (not tDocument.root) then
        fail("Document has no root element.");
    end

    return tDocument;
end


--[[!
    @fqxn LuaEx.Classes.XML
    @desc Generic UTF-8 XML document object, independent of application-specific formats.
    Reads elements, string attributes, text, CDATA, comments and processing instructions.
    Tree getters return independent copies. Qualified names remain literal; DTD validation,
    external/custom entities, namespace expansion and alternate encodings are unsupported.
    Malformed or unsupported input raises with line/column context; replacement is atomic.
    @ex
    local document = XML('<catalog><entry name="example">Some text</entry></catalog>');
    local entry = document.getElements("entry")[1];
    print(entry.attributes.name, entry.content[1]);
!]]
return class("XML",
{--METAMETHODS
    --[[!
        @fqxn LuaEx.Classes.XML.Metamethods.__clone
        @desc Recreates an independent document from source. Subclasses must define their own copy.
        @ret XML oCopy Independent document.
    !]]
    __clone = function(this, cdat)

        assert(class.of(this) == XML, "XML subclasses must implement their own clone.");
        local oCopy = XML();

        if (cdat.pri.source ~= "") then
            oCopy.parse(cdat.pri.source);
        end

        return oCopy;
    end,
    --[[!
        @fqxn LuaEx.Classes.XML.Metamethods.__tostring
        @desc Returns the original source text; does not rewrite formatting.
        @ret string sSource Stored XML source, or empty for an unloaded document.
    !]]
    __tostring = function(this, cdat)

        return cdat.pri.source;
    end,
},
{}, --STATIC PUBLIC
{--PRIVATE
    document = {},
    source = "",

    -- Native LuaEx serialization persists source only; parsed data is a derived cache.
    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.prepareSnapshot
        @desc Removes parsed cache data from the copied snapshot, retaining source.
        @param table tState Class snapshot being prepared for serialization.
        @scope private
    !]]
    prepareSnapshot = function(tState)

        tState.pri.document = {};
    end,

    --[[!
        @fqxn LuaEx.Classes.XML.Helpers.validateSnapshot
        @desc Revalidates saved source and rebuilds its cache before class restoration.
        @param table tState Class snapshot being validated.
        @scope private
    !]]
    validateSnapshot = function(tState)

        assert(rawtype(tState.pri.source) == "string", "XML snapshot source must be a string.");
        tState.pri.document = tState.pri.source == "" and {} or parseDocument(tState.pri.source);
    end,
},
{}, --PROTECTED
{--PUBLIC
    --[[!
        @fqxn LuaEx.Classes.XML.Methods.XML
        @desc Creates an unloaded document, or parses supplied XML source immediately.
        @param string|nil sSource Optional complete source; nil creates an empty object.
        @scope public
    !]]
    XML = function(this, cdat, sSource)

        if (sSource ~= nil) then
            this.parse(sSource);
        end
    end,

    --[[!
        @fqxn LuaEx.Classes.XML.Methods.getDocument
        @desc Copies declaration metadata and ordered top-level content, including root.
        @ret table tDocument Independent document tree, or empty table before parsing.
        @scope public
    !]]
    getDocument = function(this, cdat)

        return clone(cdat.pri.document);
    end,

    --[[!
        @fqxn LuaEx.Classes.XML.Methods.getElements
        @desc Returns copies of elements matching a case-sensitive name in document order.
        Includes the root when it matches. Nil selects all elements.
        @param string|nil sName Exact qualified element name, or nil for all elements.
        @ret table tElements Independent ordered element records.
        @scope public
    !]]
    getElements = function(this, cdat, sName)

        assert(sName == nil or rawtype(sName) == "string", "Element name must be a string.");
        local tFound = {};
        local tRoot = cdat.pri.document.root;
        local tPending = tRoot and { tRoot } or {};

        -- Walk depth first without exposing the private cache or depending on recursion.
        while (#tPending > 0) do
            local tElement = table.remove(tPending);

            if (sName == nil or tElement.name == sName) then
                tFound[#tFound + 1] = tElement;
            end

            for nIndex = #tElement.children, 1, -1 do
                tPending[#tPending + 1] = tElement.children[nIndex];
            end
        end

        -- Copy the completed result graph once, preserving shared child references
        -- without repeatedly copying overlapping matched subtrees.
        return clone(tFound);
    end,

    --[[!
        @fqxn LuaEx.Classes.XML.Methods.getRoot
        @desc Returns a copied root element, retaining ordered text/child content.
        @ret table|nil tRoot Root record, or nil before parsing.
        @scope public
    !]]
    getRoot = function(this, cdat)

        return cdat.pri.document.root and clone(cdat.pri.document.root) or nil;
    end,

    --[[!
        @fqxn LuaEx.Classes.XML.Methods.getSource
        @desc Returns source exactly as supplied, including original whitespace and BOM.
        @ret string sSource Source text or empty before parsing.
        @scope public
    !]]
    getSource = function(this, cdat)

        return cdat.pri.source;
    end,

    --[[!
        @fqxn LuaEx.Classes.XML.Methods.load
        @desc Reads a file and parses it before replacing existing state. File errors and
        parse failures propagate; the previous valid document remains unchanged.
        @param string sPath XML file path.
        @ret XML this Document for chaining.
        @scope public
    !]]
    load = function(this, cdat, sPath)

        assert(rawtype(sPath) == "string" and sPath:find("%S"), "XML path must be nonblank.");
        local hFile, sReason = io.open(sPath, "rb");
        assert(hFile, "Cannot open XML file: "..tostring(sReason));
        local bOK, sSource = pcall(hFile.read, hFile, "*a");
        hFile:close();
        assert(bOK and sSource, "Cannot read XML file: "..tostring(sSource));
        return this.parse(sSource);
    end,

    --[[!
        @fqxn LuaEx.Classes.XML.Methods.parse
        @desc Parses replacement source into temporary state, committing only after success.
        Attribute values remain strings; consumers interpret domain-specific property types.
        @param string sSource Complete UTF-8 XML document.
        @ret XML this Document for chaining.
        @scope public
    !]]
    parse = function(this, cdat, sSource)

        -- Prepare first so malformed replacement cannot erase a valid document.
        local tDocument = parseDocument(sSource);
        cdat.pri.source = sSource;
        cdat.pri.document = tDocument;
        return this;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interfaces
);
