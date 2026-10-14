--[[!
    @fqxn CoG.Tiled.Helpers.Reader
    @desc Interprets TMX/TSX/XML templates without adding Tiled behavior to XML.
    Canonical XML trees retain unknown elements and attributes. Tile payloads are
    normalized to CSV so editing and snapshots do not depend on a decompressor.
!]]
local Reader = {};
local tLayerKinds = {layer = true, objectgroup = true, imagelayer = true, group = true};
local tNumericAttributes = {
    "id", "width", "height", "tilewidth", "tileheight", "x", "y", "offsetx", "offsety",
    "opacity", "parallaxx", "parallaxy", "hexsidelength", "skewx", "skewy", "rotation",
    "firstgid", "tilecount", "columns", "margin", "spacing", "gid", "duration", "tileid",
};


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.child
    @desc Finds the first direct XML child with an exact element name.
    @ret table|nil tChild Matching element.
!]]
function Reader.child(tNode, sName)

    for _, tChild in ipairs(tNode.children) do
        if (tChild.name == sName) then
            return tChild;
        end
    end
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.text
    @desc Concatenates direct character content, excluding comments and child elements.
    @ret string sText Decoded XML text.
!]]
function Reader.text(tNode)

    local tParts = {};

    for _, vPart in ipairs(tNode.content) do
        if (rawtype(vPart) == "string") then
            tParts[#tParts + 1] = vPart;
        end
    end

    return table.concat(tParts);
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.element
    @desc Creates a new XML element with independent attribute, child and content tables.
    @ret table tElement Editable XML element.
!]]
function Reader.element(sName, tAttributes)

    return {
        kind = "element",
        name = sName,
        attributes = tAttributes or {},
        children = {},
        content = {},
    };
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.append
    @desc Appends a child to both XML indexes, preserving their shared reference.
!]]
function Reader.append(tParent, tChild)

    tParent.children[#tParent.children + 1] = tChild;
    tParent.content[#tParent.content + 1] = tChild;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.insertTileset
    @desc Inserts a tileset before layers so Tiled encounters GID definitions before
    object/layer references when opening exported XML.
!]]
function Reader.insertTileset(tRoot, tTileset)

    for nIndex, tChild in ipairs(tRoot.children) do
        local bBeforeTileset = tChild.name == "tileset" and tonumber(tChild.attributes.firstgid) > tonumber(tTileset.attributes.firstgid);
        if (tLayerKinds[tChild.name] or bBeforeTileset) then
            table.insert(tRoot.children, nIndex, tTileset);
            for nContent, vContent in ipairs(tRoot.content) do
                if (vContent == tChild) then
                    table.insert(tRoot.content, nContent, tTileset);
                    return;
                end
            end
        end
    end
    Reader.append(tRoot, tTileset);
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.remove
    @desc Removes an element from its parent's child and ordered-content indexes.
!]]
function Reader.remove(tParent, tChild)

    for _, sField in ipairs({"children", "content"}) do
        for nIndex = #tParent[sField], 1, -1 do
            if (tParent[sField][nIndex] == tChild) then
                table.remove(tParent[sField], nIndex);
            end
        end
    end
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.path
    @desc Resolves a resource relative to its containing file, normalizing separators
    and dot segments. Does not apply a filesystem access policy.
    @ret string sPath Resource path for the host reader.
!]]
function Reader.path(sContainingFile, sResource)

    sResource = sResource:gsub("\\", "/");
    local sCombined = sResource;

    if (not sResource:match("^/") and not sResource:match("^%a:") and not sResource:match("^%a[%w+.-]*://")) then
        local sDirectory = (sContainingFile or ""):gsub("\\", "/"):match("^(.*)/") or "";
        sCombined = sDirectory == "" and sResource or sDirectory.."/"..sResource;
    end
    if (sCombined:match("^%a[%w+.-]*://[^/]+$")) then
        return sCombined;
    end

    -- Keep drive roots and UNC roots while eliminating ordinary dot segments.
    local sPrefix = sCombined:match("^%a[%w+.-]*://[^/]+/") or sCombined:match("^%a:/") or sCombined:match("^//") or sCombined:match("^/") or "";
    local tParts = {};

    for sPart in sCombined:sub(#sPrefix + 1):gmatch("[^/]+") do
        if (sPart == ".." and #tParts > 0 and tParts[#tParts] ~= "..") then
            table.remove(tParts);
        elseif (sPart ~= "." and sPart ~= "") then
            if (sPart ~= ".." or sPrefix == "") then
                tParts[#tParts + 1] = sPart;
            end
        end
    end

    return sPrefix..table.concat(tParts, "/");
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.relative
    @desc Expresses a resolved resource relative to another containing filename.
    Different absolute roots retain an absolute reference. Absolute and relative map
    filenames must not be mixed because Lua provides no portable current-directory API.
    @ret string sReference Rebased file reference.
!]]
function Reader.relative(sContainingFile, sTarget)

    sContainingFile = Reader.path("", sContainingFile);
    sTarget = Reader.path("", sTarget);
    if (sTarget:match("^%a[%w+.-]*://")) then
        return sTarget;
    end
    local sDirectory = sContainingFile:match("^(.*)/") or "";
    local sBaseRoot = sDirectory:match("^%a:/") or sDirectory:match("^/") or "";
    local sTargetRoot = sTarget:match("^%a:/") or sTarget:match("^/") or "";
    assert((sBaseRoot == "") == (sTargetRoot == ""), "Tiled rebasing requires both filenames to be absolute or both relative.");
    if (sBaseRoot ~= sTargetRoot) then
        return sTarget;
    end
    local tBase = {};
    local tTarget = {};
    for sPart in sDirectory:gmatch("[^/]+") do
        tBase[#tBase + 1] = sPart;
    end
    for sPart in sTarget:gmatch("[^/]+") do
        tTarget[#tTarget + 1] = sPart;
    end
    local nCommon = 0;
    while (tBase[nCommon + 1] ~= nil and tBase[nCommon + 1] == tTarget[nCommon + 1]) do
        nCommon = nCommon + 1;
    end
    local tReference = {};
    for _ = nCommon + 1, #tBase do
        tReference[#tReference + 1] = "..";
    end
    for nIndex = nCommon + 1, #tTarget do
        tReference[#tReference + 1] = tTarget[nIndex];
    end
    return #tReference > 0 and table.concat(tReference, "/") or ".";
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.rebase
    @desc Moves an element's file references between containing files, including nested
    class/list file properties. Object IDs and ordinary string properties remain unchanged.
!]]
function Reader.rebase(tNode, sOldPath, sNewPath)

    local tAttributes = tNode.attributes;
    local tFileAttributes = {};
    if (tNode.name == "image" or tNode.name == "tileset") then
        tFileAttributes[#tFileAttributes + 1] = "source";
    elseif (tNode.name == "object") then
        tFileAttributes[#tFileAttributes + 1] = "template";
    elseif (tNode.name == "export") then
        tFileAttributes[#tFileAttributes + 1] = "target";
    end
    for _, sName in ipairs(tFileAttributes) do
        if (tAttributes[sName] ~= nil) then
            tAttributes[sName] = Reader.relative(sNewPath, Reader.path(sOldPath, tAttributes[sName]));
        end
    end
    if (tAttributes.type == "file" and (tNode.name == "property" or tNode.name == "item")) then
        local sValue = tAttributes.value or Reader.text(tNode);
        tAttributes.value = Reader.relative(sNewPath, Reader.path(sOldPath, sValue == "" and "." or sValue));
        tNode.content = {};
        tNode.children = {};
    end
    for _, tChild in ipairs(tNode.children) do
        Reader.rebase(tChild, sOldPath, sNewPath);
    end
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.readFile
    @desc Reads a resource in binary mode and closes its handle on read failure.
    @ret string sSource Complete file contents.
!]]
function Reader.readFile(sPath)

    local hFile, sReason = io.open(sPath, "rb");
    assert(hFile, "Cannot open Tiled resource '"..sPath.."': "..tostring(sReason));
    local bOK, sSource = pcall(hFile.read, hFile, "*a");
    hFile:close();
    assert(bOK and rawtype(sSource) == "string", "Cannot read Tiled resource '"..sPath.."'.");
    return sSource;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.number
    @desc Reads a finite numeric attribute, using a default only when absent.
    @ret number nValue Validated attribute value.
!]]
function Reader.number(tAttributes, sName, nDefault, bInteger)

    local sValue = tAttributes[sName];
    local nValue = sValue == nil and nDefault or tonumber(sValue);
    assert(rawtype(nValue) == "number" and nValue == nValue and math.abs(nValue) < math.huge,
           "Invalid Tiled numeric attribute '"..sName.."'.");
    assert(not bInteger or nValue % 1 == 0, "Tiled attribute '"..sName.."' must be an integer.");
    return nValue;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.attributes
    @desc Copies raw attributes and converts known numeric and visibility fields.
    Unknown attributes retain their original strings.
    @ret table tAttributes Interpreted attribute values.
!]]
function Reader.attributes(tNode)

    local tResult = clone(tNode.attributes);

    for _, sName in ipairs(tNumericAttributes) do
        if (tResult[sName] ~= nil) then
            tResult[sName] = Reader.number(tNode.attributes, sName, 0);
        end
    end

    for _, sName in ipairs({"visible", "infinite"}) do
        if (tResult[sName] ~= nil) then
            assert(tResult[sName] == "0" or tResult[sName] == "1", "Invalid Tiled boolean attribute '"..sName.."'.");
            tResult[sName] = tResult[sName] == "1";
        end
    end

    return tResult;
end

local readValue;


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.properties
    @desc Reads named properties as records retaining type, propertytype, value and raw XML.
    Class values contain named property records; lists contain ordered property records.
    @ret table tProperties Named typed properties.
!]]
function Reader.properties(tNode, sPath)

    local tResult = {};
    local tProperties = Reader.child(tNode, "properties");

    if (tProperties ~= nil) then
        for _, tProperty in ipairs(tProperties.children) do
            if (tProperty.name == "property") then
                local sName = tProperty.attributes.name;
                assert(sName ~= nil and tResult[sName] == nil, "Missing or duplicate Tiled property name.");
                tResult[sName] = readValue(tProperty, sPath);
            end
        end
    end

    return tResult;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.readValue
    @desc Interprets one typed property or list item. Unknown types remain readable raw values.
    @ret table tProperty Typed property record.
!]]
readValue = function(tNode, sPath)

    local sType = tNode.attributes.type or "string";
    local sRaw = tNode.attributes.value or Reader.text(tNode);
    local vValue = sRaw;

    if (sType == "class") then
        vValue = Reader.properties(tNode, sPath);
    elseif (sType == "list") then
        vValue = {};

        for _, tChild in ipairs(tNode.children) do
            if (tChild.name == "item") then
                vValue[#vValue + 1] = readValue(tChild, sPath);
            end
        end
    elseif (sType == "int" or sType == "float" or sType == "object") then
        vValue = tonumber(sRaw == "" and "0" or sRaw);
        assert(vValue and vValue == vValue and math.abs(vValue) < math.huge, "Invalid numeric Tiled property.");
        assert(sType == "float" or vValue % 1 == 0, "Tiled integer property contains a fraction.");
    elseif (sType == "bool") then
        assert(sRaw == "true" or sRaw == "false" or sRaw == "", "Invalid boolean Tiled property.");
        vValue = sRaw == "true";
    elseif (sType == "file") then
        vValue = Reader.path(sPath, sRaw == "" and "." or sRaw);
    elseif (sType == "color" and sRaw == "") then
        vValue = "#00000000";
    end

    return {type = sType, propertyType = tNode.attributes.propertytype, value = vValue, rawValue = sRaw, raw = tNode};
end;


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.values
    @desc Unwraps typed properties into plain values for application callbacks.
    The regular property queries retain the original type metadata.
    @ret table tValues Plain nested property values.
!]]
function Reader.values(tProperties)

    local tResult = {};

    for vKey, tProperty in pairs(tProperties) do
        if (tProperty.type == "class" or tProperty.type == "list") then
            tResult[vKey] = Reader.values(tProperty.value);
        else
            tResult[vKey] = tProperty.value;
        end
    end

    return tResult;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.propertyNode
    @desc Builds typed XML properties from plain Lua values. Nested tables become class
    properties unless type=list is explicitly requested; cycles are rejected by the caller.
    @ret table tNode Property or item element.
!]]
function Reader.propertyNode(sName, vValue, sType, sPropertyType)

    if (sType == nil) then
        local sLuaType = rawtype(vValue);
        local tTypes = {string = "string", number = "float", boolean = "bool", table = "class"};
        sType = tTypes[sLuaType];
        if (sLuaType == "table" and rawtype(next(vValue)) == "number") then
            sType = "list";
        end
        assert(sType ~= nil, "Unsupported Tiled property value type.");
    end

    local tNode = Reader.element(sName == nil and "item" or "property", {name = sName, type = sType, propertytype = sPropertyType});

    if (sType == "class" or sType == "list") then
        assert(rawtype(vValue) == "table", "Tiled structured property requires a table.");
        local tParent = tNode;

        if (sType == "class") then
            tParent = Reader.element("properties");
            Reader.append(tNode, tParent);
        end

        local tKeys = {};
        for vKey in pairs(vValue) do
            assert(sType == "list" and rawtype(vKey) == "number" or sType == "class" and rawtype(vKey) == "string",
                   "Invalid structured Tiled property key.");
            tKeys[#tKeys + 1] = vKey;
        end
        table.sort(tKeys);

        for nIndex, vKey in ipairs(tKeys) do
            assert(sType ~= "list" or vKey == nIndex, "Tiled lists must be contiguous.");
            local vName = sType == "class" and vKey or nil;
            Reader.append(tParent, Reader.propertyNode(vName, vValue[vKey]));
        end
    else
        assert(rawtype(vValue) == "string" or rawtype(vValue) == "number" or rawtype(vValue) == "boolean",
               "Tiled scalar properties require a scalar value.");
        tNode.attributes.value = tostring(vValue);
    end

    return tNode;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.decodeGID
    @desc Separates all four high GID flags, including hexagonal rotation flags.
    @ret table tGID Raw GID, base ID and transformation booleans.
!]]
function Reader.decodeGID(nGID)

    assert(rawtype(nGID) == "number" and nGID % 1 == 0 and nGID >= 0 and nGID <= 0xffffffff,
           "Tiled GID must be an unsigned 32-bit integer.");
    return {
        rawGID = nGID,
        gid = nGID & 0x0fffffff,
        flipHorizontal = nGID & 0x80000000 ~= 0,
        flipVertical = nGID & 0x40000000 ~= 0,
        flipDiagonal = nGID & 0x20000000 ~= 0,
        rotateHex60 = nGID & 0x20000000 ~= 0,
        rotateHex120 = nGID & 0x10000000 ~= 0,
    };
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.decodeData
    @desc Decodes a finite payload or chunk, validates every GID and normalizes XML to CSV.
    Compression is delegated to the host callback (bytes, format, expectedByteCount).
    @ret table tGIDs Ordered row-major GIDs.
!]]
local function decodeData(tNode, sEncoding, sCompression, nCount, fDecompress)

    local tGIDs = {};
    local sText = Reader.text(tNode);

    if (sEncoding == "csv") then
        assert(sCompression == nil, "Compression is only valid for base64 tile data.");
        local nPosition = 1;
        while (true) do
            local nComma = sText:find(",", nPosition, true);
            local sPart = sText:sub(nPosition, nComma and nComma - 1 or #sText);
            local sNumber = sPart:match("^%s*(%d+)%s*$");
            if (sNumber ~= nil) then
                tGIDs[#tGIDs + 1] = tonumber(sNumber);
            else
                assert(nComma == nil and sPart:match("^%s*$") and (#tGIDs > 0 or nCount == 0), "Malformed Tiled CSV tile data.");
            end
            if (nComma == nil) then
                break;
            end
            nPosition = nComma + 1;
        end
    elseif (sEncoding == "base64") then
        local sEncoded = sText:gsub("%s", "");
        assert(#sEncoded % 4 == 0 and sEncoded:match("^[A-Za-z0-9+/]*=?=?$"), "Malformed Tiled base64 data or padding.");
        local sBytes = base64.dec(sEncoded);

        if (sCompression ~= nil) then
            assert(sCompression == "zlib" or sCompression == "gzip" or sCompression == "zstd", "Unknown Tiled compression.");
            assert(rawtype(fDecompress) == "function", "Compressed Tiled data requires a host decompressor.");
            sBytes = fDecompress(sBytes, sCompression, nCount * 4);
        end

        assert(rawtype(sBytes) == "string" and #sBytes == nCount * 4, "Tiled tile data has an incorrect byte count.");

        for nPosition = 1, #sBytes, 4 do
            local nA, nB, nC, nD = sBytes:byte(nPosition, nPosition + 3);
            tGIDs[#tGIDs + 1] = nA + nB * 256 + nC * 65536 + nD * 16777216;
        end
    elseif (sEncoding == nil) then
        assert(sCompression == nil, "Compression requires base64 tile data.");

        for _, tTile in ipairs(tNode.children) do
            assert(tTile.name == "tile", "Unexpected element in XML tile data.");
            tGIDs[#tGIDs + 1] = Reader.number(tTile.attributes, "gid", 0, true);
        end
    else
        error("Unsupported Tiled tile encoding '"..tostring(sEncoding).."'.");
    end

    assert(#tGIDs == nCount, "Tiled tile count does not match layer or chunk dimensions.");
    local tText = {};

    for nIndex, nGID in ipairs(tGIDs) do
        Reader.decodeGID(nGID);
        tText[nIndex] = tostring(nGID);
    end

    -- CSV becomes the portable, editable representation, even for imported compression.
    tNode.children = {};
    tNode.content = {table.concat(tText, ",")};
    return tGIDs;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.resource
    @desc Obtains an XML resource from the per-map cache or the host file reader.
    Cached XML trees are copied before use so failed edits cannot alter saved resources.
    @ret table tRoot Resource root element.
!]]
local function resource(tContext, sPath, sExpected)

    local sSource = tContext.resources[sPath];

    if (sSource == nil) then
        sSource = tContext.read(sPath);
        assert(rawtype(sSource) == "string", "Tiled resource reader must return XML text.");
        tContext.resources[sPath] = sSource;
    end

    local tRoot = XML(sSource).getRoot();
    assert(tRoot.name == sExpected, "Expected Tiled "..sExpected.." resource at '"..sPath.."'.");
    return tRoot;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.record
    @desc Interprets an XML element while keeping its raw node for editing and export.
    @ret table tRecord Attributes, typed properties and raw source node.
!]]
local function record(tNode, sPath)

    return {kind = tNode.name, attributes = Reader.attributes(tNode), properties = Reader.properties(tNode, sPath), raw = tNode};
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.tileset
    @desc Resolves an embedded or external tileset, retaining sparse tile IDs, images,
    collision shapes, animation and other raw tileset metadata.
    @ret table tTileset Parsed tileset record.
!]]
local function tileset(tNode, tContext)

    local nFirst = Reader.number(tNode.attributes, "firstgid", 0, true);
    assert(nFirst > 0 and nFirst <= 0x0fffffff, "Invalid tileset firstgid.");
    local sPath = tContext.path;
    local tDefinition = tNode;

    if (tNode.attributes.source ~= nil) then
        sPath = Reader.path(tContext.path, tNode.attributes.source);
        tDefinition = resource(tContext, sPath, "tileset");
    end

    local tResult = record(tDefinition, sPath);
    tResult.firstgid = nFirst;
    tResult.source = sPath;
    tResult.reference = tNode;
    tResult.tiles = {};
    tResult.images = {};
    tResult.maxLocalID = -1;
    local nCount = Reader.number(tDefinition.attributes, "tilecount", 0, true);
    assert(nCount >= 0, "Tileset tilecount must not be negative.");
    tResult.maxLocalID = nCount - 1;

    for _, tChild in ipairs(tDefinition.children) do
        if (tChild.name == "image") then
            local tImage = record(tChild, sPath);
            if (tChild.attributes.source ~= nil) then
                tImage.source = Reader.path(sPath, tChild.attributes.source);
            end
            tResult.images[#tResult.images + 1] = tImage;
        elseif (tChild.name == "tile") then
            local nID = Reader.number(tChild.attributes, "id", -1, true);
            assert(nID >= 0 and tResult.tiles[nID] == nil, "Missing or duplicate tileset tile ID.");
            local tTile = record(tChild, sPath);
            tTile.images = {};
            tTile.animation = {};

            for _, tPart in ipairs(tChild.children) do
                if (tPart.name == "image") then
                    local tImage = record(tPart, sPath);
                    if (tPart.attributes.source ~= nil) then
                        tImage.source = Reader.path(sPath, tPart.attributes.source);
                    end
                    tTile.images[#tTile.images + 1] = tImage;
                elseif (tPart.name == "animation") then
                    for _, tFrame in ipairs(tPart.children) do
                        tTile.animation[#tTile.animation + 1] = Reader.attributes(tFrame);
                    end
                end
            end

            tResult.tiles[nID] = tTile;
            tResult.maxLocalID = math.max(tResult.maxLocalID, nID);
        end
    end

    assert(nFirst + tResult.maxLocalID <= 0x0fffffff, "Tileset GID range overflows.");
    return tResult;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.resolve
    @desc Resolves a raw GID against ascending tilesets. Empty cells have no tileset.
    Sparse image collections require an explicitly defined local tile.
    @ret table tTile Transformation flags, tileset and optional explicit tile definition.
!]]
function Reader.resolve(tMap, nGID)

    local tResult = Reader.decodeGID(nGID);

    if (tResult.gid == 0) then
        return tResult;
    end

    for nIndex = #tMap.tilesets, 1, -1 do
        local tTileset = tMap.tilesets[nIndex];

        if (tResult.gid >= tTileset.firstgid) then
            local nLocal = tResult.gid - tTileset.firstgid;
            assert(nLocal <= tTileset.maxLocalID, "Tiled GID lies outside its tileset.");
            assert(#tTileset.images > 0 or tTileset.tiles[nLocal] ~= nil, "Tiled GID references a missing image-collection tile.");
            tResult.localID = nLocal;
            tResult.tileset = tTileset;
            tResult.definition = tTileset.tiles[nLocal];
            return tResult;
        end
    end

    error("Tiled GID does not reference a tileset.");
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.templateObject
    @desc Expands template defaults and instance overrides. Template tile GIDs are remapped
    into the map's tileset range; template cycles are rejected.
    @ret table tObject Expanded object element, independent of the template cache.
!]]
local function templateObject(tNode, tContext, tMap, tSeen, sContainingFile)

    if (tNode.attributes.template == nil) then
        return tNode;
    end

    local sPath = Reader.path(sContainingFile, tNode.attributes.template);
    assert(not tSeen[sPath], "Cyclic Tiled object template.");
    tSeen[sPath] = true;
    local tTemplate = resource(tContext, sPath, "template");
    local tBase = Reader.child(tTemplate, "object");
    assert(tBase, "Tiled template has no object.");
    tBase = templateObject(tBase, tContext, tMap, tSeen, sPath);
    local tTileset = Reader.child(tTemplate, "tileset");

    if (tBase.attributes.gid ~= nil and tTileset ~= nil and tNode.attributes.gid == nil) then
        assert(tTileset.attributes.source, "Template tilesets must reference TSX files.");
        local sTSX = Reader.path(sPath, tTileset.attributes.source);
        local tTarget;

        for _, tExisting in ipairs(tMap.tilesets) do
            if (tExisting.source == sTSX) then
                tTarget = tExisting;
                break;
            end
        end

        if (tTarget == nil) then
            local nFirst = 1;
            for _, tExisting in ipairs(tMap.tilesets) do
                nFirst = math.max(nFirst, tExisting.firstgid + tExisting.maxLocalID + 1);
            end
            -- Embed the TSX so the expanded map no longer depends on the template path.
            local tEmbedded = resource(tContext, sTSX, "tileset");
            tEmbedded.attributes.firstgid = tostring(nFirst);
            Reader.rebase(tEmbedded, sTSX, tContext.path);
            local tTemporary = {path = tContext.path, resources = tContext.resources, read = tContext.read};
            tTarget = tileset(tEmbedded, tTemporary);
            tTarget.source = sTSX;
            Reader.insertTileset(tMap.raw, tEmbedded);
            tMap.tilesets[#tMap.tilesets + 1] = tTarget;
        end

        local tGID = Reader.decodeGID(tonumber(tBase.attributes.gid));
        local nLocal = tGID.gid - Reader.number(tTileset.attributes, "firstgid", 1, true);
        assert(nLocal >= 0 and nLocal <= tTarget.maxLocalID, "Template tile lies outside its tileset.");
        tBase.attributes.gid = tostring((tGID.rawGID & 0xf0000000) | (tTarget.firstgid + nLocal));
    end

    -- Merge explicit instance attributes and properties over the template defaults.
    Reader.rebase(tBase, sPath, sContainingFile);
    local tMerged = clone(tBase);
    for sKey, sValue in pairs(tNode.attributes) do
        if (sKey ~= "template") then
            tMerged.attributes[sKey] = sValue;
        end
    end
    tMerged.attributes.template = nil;

    for _, tChild in ipairs(tNode.children) do
        local tPrevious = Reader.child(tMerged, tChild.name);

        if (tChild.name == "properties" and tPrevious ~= nil) then
            for _, tProperty in ipairs(tChild.children) do
                for nIndex = #tPrevious.children, 1, -1 do
                    local tOld = tPrevious.children[nIndex];
                    if (tOld.attributes.name == tProperty.attributes.name) then
                        Reader.remove(tPrevious, tOld);
                    end
                end
                Reader.append(tPrevious, clone(tProperty));
            end
        else
            if (tPrevious ~= nil) then
                Reader.remove(tMerged, tPrevious);
            end
            Reader.append(tMerged, clone(tChild));
        end
    end

    tSeen[sPath] = nil;
    return tMerged;
end

local readLayers;


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.readLayers
    @desc Walks nested layers in draw order, combining visibility, opacity, offsets and
    parallax. Finite layers and infinite chunks keep zero-based native coordinates.
!]]
readLayers = function(tParent, tContext, tMap, tInherited, tOutput)

    -- Template expansion may insert a tileset before the current root layer.
    -- Walk a stable child list so that insertion cannot revisit that layer.
    local tChildren = {table.unpack(tParent.children)};
    for _, tNode in ipairs(tChildren) do
        if (tLayerKinds[tNode.name]) then
            local tLayer = record(tNode, tContext.path);
            local tAttributes = tLayer.attributes;
            local nID = Reader.number(tNode.attributes, "id", -1, true);
            assert(nID > 0 and tMap.layersByID[nID] == nil, "Missing or duplicate Tiled layer ID.");
            tLayer.id = nID;
            tLayer.name = tAttributes.name or "";
            tLayer.parentID = tInherited.id;
            tLayer.offsetx = tInherited.offsetx + (tAttributes.offsetx or 0);
            tLayer.offsety = tInherited.offsety + (tAttributes.offsety or 0);
            tLayer.visible = tInherited.visible and tAttributes.visible ~= false;
            tLayer.opacity = tInherited.opacity * (tAttributes.opacity or 1);
            tLayer.parallaxx = tInherited.parallaxx * (tAttributes.parallaxx or 1);
            tLayer.parallaxy = tInherited.parallaxy * (tAttributes.parallaxy or 1);
            tLayer.children = {};
            tLayer.objects = {};
            tLayer.chunks = {};
            tMap.layersByID[nID] = tLayer;
            tMap.layers[#tMap.layers + 1] = tLayer;
            tOutput[#tOutput + 1] = tLayer;

            if (tNode.name == "group") then
                readLayers(tNode, tContext, tMap, tLayer, tLayer.children);
            elseif (tNode.name == "layer") then
                local tData = Reader.child(tNode, "data");
                assert(tData, "Tiled tile layer has no data.");
                local sEncoding = tData.attributes.encoding;
                local sCompression = tData.attributes.compression;
                local bChunks = Reader.child(tData, "chunk") ~= nil;

                if (bChunks) then
                    assert(tMap.attributes.infinite, "Chunks require an infinite map.");
                    for _, tChunk in ipairs(tData.children) do
                        assert(tChunk.name == "chunk", "Unexpected element in chunk data.");
                        local tBlock = Reader.attributes(tChunk);
                        tBlock.x = Reader.number(tChunk.attributes, "x", 0, true);
                        tBlock.y = Reader.number(tChunk.attributes, "y", 0, true);
                        tBlock.width = Reader.number(tChunk.attributes, "width", 0, true);
                        tBlock.height = Reader.number(tChunk.attributes, "height", 0, true);
                        assert(tBlock.width > 0 and tBlock.height > 0, "Tiled chunks require positive dimensions.");

                        for _, tPrevious in ipairs(tLayer.chunks) do
                            assert(tBlock.x + tBlock.width <= tPrevious.x or tPrevious.x + tPrevious.width <= tBlock.x or
                                   tBlock.y + tBlock.height <= tPrevious.y or tPrevious.y + tPrevious.height <= tBlock.y,
                                   "Overlapping Tiled chunks.");
                        end

                        tBlock.gids = decodeData(tChunk, sEncoding, sCompression, tBlock.width * tBlock.height, tContext.decompress);
                        tBlock.raw = tChunk;
                        tLayer.chunks[#tLayer.chunks + 1] = tBlock;
                    end
                elseif (tMap.attributes.infinite and #tData.children == 0 and Reader.text(tData):match("^%s*$")) then
                    -- A newly created infinite layer has no painted chunks yet.
                    tData.content = {};
                else
                    assert(not tMap.attributes.infinite, "Infinite Tiled tile layers require chunk data.");
                    local nWidth = Reader.number(tNode.attributes, "width", 0, true);
                    local nHeight = Reader.number(tNode.attributes, "height", 0, true);
                    assert(nWidth >= 0 and nHeight >= 0, "Invalid tile layer dimensions.");
                    tLayer.chunks[1] = {
                        x = Reader.number(tNode.attributes, "x", 0, true),
                        y = Reader.number(tNode.attributes, "y", 0, true),
                        width = nWidth,
                        height = nHeight,
                        gids = decodeData(tData, sEncoding, sCompression, nWidth * nHeight, tContext.decompress),
                        raw = tData,
                    };
                end

                tData.attributes.encoding = "csv";
                tData.attributes.compression = nil;
            elseif (tNode.name == "objectgroup") then
                -- Expand templates into the canonical tree before indexing objects.
                for nIndex, tObject in ipairs(tNode.children) do
                    if (tObject.name == "object") then
                        local tExpanded = templateObject(tObject, tContext, tMap, {}, tContext.path);

                        if (tExpanded ~= tObject) then
                            tNode.children[nIndex] = tExpanded;
                            for nContent, vContent in ipairs(tNode.content) do
                                if (vContent == tObject) then
                                    tNode.content[nContent] = tExpanded;
                                end
                            end
                        end

                        local tObjectRecord = record(tExpanded, tContext.path);
                        local nObjectID = Reader.number(tExpanded.attributes, "id", -1, true);
                        assert(nObjectID > 0 and tMap.objectsByID[nObjectID] == nil, "Missing or duplicate Tiled object ID.");
                        tObjectRecord.id = nObjectID;
                        tObjectRecord.layerID = nID;
                        tMap.objectsByID[nObjectID] = tObjectRecord;
                        tMap.objects[#tMap.objects + 1] = tObjectRecord;
                        tLayer.objects[#tLayer.objects + 1] = tObjectRecord;
                    end
                end
            end
        end
    end
end;


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.compile
    @desc Validates a map tree and builds query indexes. Callers supply a disposable tree
    and resource cache so loading and editing can commit atomically after success.
    @ret table tMap Compiled map, referencing its canonical editable tree.
!]]
function Reader.compile(tRoot, sPath, tResources, fRead, fDecompress)

    assert(tRoot.name == "map", "Tiled requires a TMX map root.");
    local tMap = record(tRoot, sPath);
    local tAttributes = tMap.attributes;
    local tOrientations = {orthogonal = true, isometric = true, staggered = true, hexagonal = true, oblique = true};
    assert(tOrientations[tAttributes.orientation], "Unsupported Tiled map orientation.");
    tAttributes.width = Reader.number(tRoot.attributes, "width", 0, true);
    tAttributes.height = Reader.number(tRoot.attributes, "height", 0, true);
    tAttributes.tilewidth = Reader.number(tRoot.attributes, "tilewidth", 0, true);
    tAttributes.tileheight = Reader.number(tRoot.attributes, "tileheight", 0, true);
    assert(tAttributes.width >= 0 and tAttributes.height >= 0, "Tiled map dimensions must not be negative.");
    assert(tAttributes.tilewidth > 0 and tAttributes.tileheight > 0, "Tiled tile dimensions must be positive.");
    tAttributes.infinite = tAttributes.infinite or false;
    tAttributes.skewx = tAttributes.skewx or 0;
    tAttributes.skewy = tAttributes.skewy or 0;
    tAttributes.hexsidelength = Reader.number(tRoot.attributes, "hexsidelength", 0, true);

    if (tAttributes.orientation == "hexagonal" or tAttributes.orientation == "staggered") then
        assert(tAttributes.staggeraxis == "x" or tAttributes.staggeraxis == "y", "Tiled staggeraxis must be x or y.");
        assert(tAttributes.staggerindex == "odd" or tAttributes.staggerindex == "even", "Tiled staggerindex must be odd or even.");
        local nLimit = tAttributes.staggeraxis == "x" and tAttributes.tilewidth or tAttributes.tileheight;
        assert(tAttributes.hexsidelength >= 0 and tAttributes.hexsidelength <= nLimit, "Invalid hex side length.");
    elseif (tAttributes.orientation == "oblique") then
        assert(tAttributes.tilewidth * tAttributes.tileheight ~= tAttributes.skewx * tAttributes.skewy, "Singular oblique map projection.");
    end

    local tContext = {path = sPath, resources = tResources, read = fRead or Reader.readFile, decompress = fDecompress};
    tMap.tilesets = {};
    tMap.layers = {};
    tMap.rootLayers = {};
    tMap.layersByID = {};
    tMap.objects = {};
    tMap.objectsByID = {};

    for _, tChild in ipairs(tRoot.children) do
        if (tChild.name == "tileset") then
            tMap.tilesets[#tMap.tilesets + 1] = tileset(tChild, tContext);
        end
    end

    table.sort(tMap.tilesets, function(tA, tB) return tA.firstgid < tB.firstgid; end);
    for nIndex = 2, #tMap.tilesets do
        local tPrevious = tMap.tilesets[nIndex - 1];
        assert(tPrevious.firstgid + tPrevious.maxLocalID < tMap.tilesets[nIndex].firstgid, "Overlapping Tiled tileset GID ranges.");
    end

    readLayers(tRoot, tContext, tMap, {offsetx = 0, offsety = 0, opacity = 1, visible = true, parallaxx = 1, parallaxy = 1}, tMap.rootLayers);

    -- Check references after templates have added any needed tilesets.
    for _, tLayer in ipairs(tMap.layers) do
        for _, tChunk in ipairs(tLayer.chunks) do
            for _, nGID in ipairs(tChunk.gids) do
                Reader.resolve(tMap, nGID);
            end
        end
    end
    for _, tObject in ipairs(tMap.objects) do
        if (tObject.attributes.gid ~= nil) then
            Reader.resolve(tMap, tObject.attributes.gid);
        end
    end

    return tMap;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.layer
    @desc Finds a layer by ID or unique exact name. Ambiguous names require an ID.
    @ret table|nil tLayer Matching layer.
!]]
function Reader.layer(tMap, vLayer)

    if (rawtype(vLayer) == "number") then
        return tMap.layersByID[vLayer];
    end
    assert(rawtype(vLayer) == "string", "Tiled layer selector must be an ID or name.");
    local tFound;

    for _, tLayer in ipairs(tMap.layers) do
        if (tLayer.name == vLayer) then
            assert(tFound == nil, "Ambiguous Tiled layer name; use its ID.");
            tFound = tLayer;
        end
    end

    return tFound;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.cell
    @desc Finds a native cell in a finite block or infinite chunk. Empty GID 0 differs
    from an absent cell, which returns nil.
    @ret number|nil nGID Raw tile ID.
    @ret table|nil tChunk Containing chunk.
    @ret number|nil nIndex Row-major position in that chunk.
!]]
function Reader.cell(tLayer, nX, nY)

    assert(tLayer and tLayer.kind == "layer", "Tiled cell queries require a tile layer.");
    assert(rawtype(nX) == "number" and nX % 1 == 0 and rawtype(nY) == "number" and nY % 1 == 0, "Tiled cell coordinates must be integers.");

    for _, tChunk in ipairs(tLayer.chunks) do
        if (nX >= tChunk.x and nX < tChunk.x + tChunk.width and nY >= tChunk.y and nY < tChunk.y + tChunk.height) then
            local nIndex = (nY - tChunk.y) * tChunk.width + nX - tChunk.x + 1;
            return tChunk.gids[nIndex], tChunk, nIndex;
        end
    end
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.escape
    @desc Escapes XML text and attributes, retaining literal attribute whitespace via references.
    @ret string sEscaped XML-safe text.
!]]
local function escape(sValue, bAttribute)

    sValue = sValue:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;");
    if (bAttribute) then
        sValue = sValue:gsub('"', "&quot;"):gsub("\n", "&#10;"):gsub("\r", "&#13;"):gsub("\t", "&#9;");
    end
    return sValue;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Reader.encode
    @desc Writes a canonical element tree as UTF-8 XML. Attributes are sorted for stable
    output; unknown elements, text, comments and processing instructions survive editing.
    @ret string sXML Serialized XML element.
!]]
function Reader.encode(tNode)

    local tParts = {"<", tNode.name};
    local tNames = {};
    for sName in pairs(tNode.attributes) do
        tNames[#tNames + 1] = sName;
    end
    table.sort(tNames);

    for _, sName in ipairs(tNames) do
        tParts[#tParts + 1] = " "..sName..'="'..escape(tostring(tNode.attributes[sName]), true)..'"';
    end

    if (#tNode.content == 0) then
        tParts[#tParts + 1] = "/>";
    else
        tParts[#tParts + 1] = ">";
        for _, vPart in ipairs(tNode.content) do
            if (rawtype(vPart) == "string") then
                tParts[#tParts + 1] = escape(vPart, false);
            elseif (vPart.kind == "element") then
                tParts[#tParts + 1] = Reader.encode(vPart);
            elseif (vPart.kind == "comment") then
                tParts[#tParts + 1] = "<!--"..vPart.text.."-->";
            elseif (vPart.kind == "processingInstruction") then
                tParts[#tParts + 1] = "<?"..vPart.name.." "..vPart.text.."?>";
            end
        end
        tParts[#tParts + 1] = "</"..tNode.name..">";
    end

    return table.concat(tParts);
end

return Reader;
