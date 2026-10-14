--[[!
    @fqxn CoG.Tiled
    @desc An editable Tiled TMX map with typed properties, external TSX tilesets,
    templates, finite/infinite layers and a native CoG AStar bridge. All cell coordinates
    are zero-based, including negative infinite-map coordinates. Queries return copies.
    Loading and editing replace state only after the complete replacement validates.
    @ex
    local oTiled = Tiled("maps/world.tmx");
    local tTile = oTiled.getTile("Ground", 0, 0);
    local tNavigation = oTiled.toAStar("world");
    local oNode = tNavigation.map.getNode("Ground", 0, 0);
!]]
local Reader = require("LuaEx.inc.cog.tiled.Reader");
local Projection = require("LuaEx.inc.cog.tiled.Projection");
local Bridge = require("LuaEx.inc.cog.tiled.AStarBridge");


--[[!
    @fqxn CoG.Tiled.Helpers.requireMap
    @desc Checks that the object contains a loaded or programmatically created map.
    @ret table tMap Compiled private map.
!]]
local function requireMap(tPrivate)

    assert(tPrivate.map.raw ~= nil, "Tiled has no map; load, parse or create one first.");
    return tPrivate.map;
end


--[[!
    @fqxn CoG.Tiled.Helpers.commit
    @desc Parses and compiles temporary state before replacing the object's map.
    Source is regenerated after compilation so normalized payloads and expanded templates
    survive cloning and native serialization without a decompressor or file access.
!]]
local function commit(tPrivate, sSource, sPath, tResources, fRead, fDecompress)

    local tRoot = XML(sSource).getRoot();
    local tMap = Reader.compile(tRoot, sPath, tResources, fRead, fDecompress);
    local sCanonical = Reader.encode(tRoot);

    -- Nothing below runs when XML, resource resolution or map validation fails.
    tPrivate.source = sCanonical;
    tPrivate.path = sPath;
    tPrivate.resources = tResources;
    tPrivate.map = tMap;
end


--[[!
    @fqxn CoG.Tiled.Helpers.checkValue
    @desc Rejects cyclic property tables, unsupported values and excessive recursion.
    Shared acyclic tables are permitted and copied independently into XML properties.
!]]
local function checkValue(vValue, tActive, nDepth)

    assert(nDepth <= 128, "Tiled property nesting exceeds 128 levels.");
    if (rawtype(vValue) == "table") then
        assert(not tActive[vValue], "Tiled property tables must not be cyclic.");
        tActive[vValue] = true;
        for _, vChild in pairs(vValue) do
            checkValue(vChild, tActive, nDepth + 1);
        end
        tActive[vValue] = nil;
    else
        assert(rawtype(vValue) == "string" or rawtype(vValue) == "number" or rawtype(vValue) == "boolean", "Unsupported Tiled property value.");
    end
end


--[[!
    @fqxn CoG.Tiled.Helpers.makeElement
    @desc Creates an element from {attributes, properties, children}. Plain properties
    infer scalar/class types; explicit typed properties can be supplied as raw children.
    @ret table tElement Independent editable element.
!]]
local function makeElement(sName, tDefinition)

    assert(rawtype(tDefinition) == "table", "Tiled definition must be a table.");
    local tElement = Reader.element(sName);
    for sKey, vValue in pairs(tDefinition.attributes or {}) do
        assert(rawtype(sKey) == "string", "Tiled attribute names must be strings.");
        if (rawtype(vValue) == "boolean") then
            tElement.attributes[sKey] = vValue and "1" or "0";
        else
            tElement.attributes[sKey] = tostring(vValue);
        end
    end
    if (tDefinition.properties ~= nil) then
        checkValue(tDefinition.properties, {}, 0);
        local tProperties = Reader.element("properties");
        for sName, vValue in pairs(tDefinition.properties) do
            assert(rawtype(sName) == "string", "Tiled property names must be strings.");
            Reader.append(tProperties, Reader.propertyNode(sName, vValue));
        end
        Reader.append(tElement, tProperties);
    end
    for _, tChild in ipairs(tDefinition.children or {}) do
        Reader.append(tElement, clone(tChild));
    end
    return tElement;
end


--[[!
    @fqxn CoG.Tiled.Helpers.nextID
    @desc Chooses an unused positive layer/object ID and respects the map's next-ID hint.
    @ret number nID New ID.
!]]
local function nextID(tMap, bObject)

    local tRecords = bObject and tMap.objects or tMap.layers;
    local sName = bObject and "nextobjectid" or "nextlayerid";
    local nID = Reader.number(tMap.raw.attributes, sName, 1, true);
    for _, tRecord in ipairs(tRecords) do
        nID = math.max(nID, tRecord.id + 1);
    end
    return math.max(1, nID);
end


--[[!
    @fqxn CoG.Tiled.Helpers.target
    @desc Selects map, layer or object XML for property edits. Object ID takes precedence;
    the layer selector may be omitted for object properties.
    @ret table tNode Canonical target node.
!]]
local function target(tMap, vLayer, nObjectID)

    if (nObjectID ~= nil) then
        local tObject = tMap.objectsByID[nObjectID];
        assert(tObject, "Unknown Tiled object ID.");
        return tObject.raw;
    end
    if (vLayer ~= nil) then
        local tLayer = Reader.layer(tMap, vLayer);
        assert(tLayer, "Unknown Tiled layer.");
        return tLayer.raw;
    end
    return tMap.raw;
end


--[[!
    @fqxn CoG.Tiled.Helpers.putProperty
    @desc Replaces one named property in both XML indexes, or removes it for nil.
!]]
local function putProperty(tTarget, sName, tNew)

    local tProperties = Reader.child(tTarget, "properties");
    if (tProperties == nil and tNew ~= nil) then
        tProperties = Reader.element("properties");
        Reader.append(tTarget, tProperties);
    end
    if (tProperties ~= nil) then
        for nIndex = #tProperties.children, 1, -1 do
            local tOld = tProperties.children[nIndex];
            if (tOld.attributes.name == sName) then
                Reader.remove(tProperties, tOld);
            end
        end
        if (tNew ~= nil) then
            Reader.append(tProperties, tNew);
        end
    end
end

return class("Tiled",
{--METAMETHODS
    --[[!
        @fqxn CoG.Tiled.Metamethods.__clone
        @desc Rebuilds an independent editable map using cached resource source only.
        @ret Tiled oCopy Independent map object.
    !]]
    __clone = function(this, cdat)

        assert(class.of(this) == Tiled, "Tiled subclasses must define their own clone.");
        local oCopy = Tiled();
        if (cdat.pri.source ~= "") then
            oCopy.parse(cdat.pri.source, cdat.pri.path, function(sPath)
                assert(cdat.pri.resources[sPath], "Missing cached Tiled resource.");
                return cdat.pri.resources[sPath];
            end);
        end
        return oCopy;
    end,


    --[[!
        @fqxn CoG.Tiled.Metamethods.__tostring
        @desc Returns canonical TMX XML, or an empty string before a map is created.
        @ret string sXML Map XML.
    !]]
    __tostring = function(this, cdat)

        return cdat.pri.source;
    end,
},
{}, --STATIC PUBLIC
{--PRIVATE
    map = {},
    path = "",
    resources = {},
    source = "",

    --[[!
        @fqxn CoG.Tiled.Helpers.prepareSnapshot
        @desc Omits the derived query indexes; canonical XML and cached resources persist.
    !]]
    prepareSnapshot = function(tState)

        tState.pri.map = {};
    end,


    --[[!
        @fqxn CoG.Tiled.Helpers.validateSnapshot
        @desc Rebuilds query indexes from saved XML without reading external files.
    !]]
    validateSnapshot = function(tState)

        local tPrivate = tState.pri;
        assert(rawtype(tPrivate.source) == "string" and rawtype(tPrivate.path) == "string" and rawtype(tPrivate.resources) == "table", "Invalid Tiled snapshot.");
        for sPath, sSource in pairs(tPrivate.resources) do
            assert(rawtype(sPath) == "string" and rawtype(sSource) == "string", "Invalid Tiled resource snapshot.");
        end
        if (tPrivate.source ~= "") then
            commit(tPrivate, tPrivate.source, tPrivate.path, clone(tPrivate.resources), function(sPath)
                error("Missing cached Tiled resource '"..sPath.."'.");
            end);
        else
            tPrivate.map = {};
        end
    end,
},
{}, --PROTECTED
{--PUBLIC
    --[[!
        @fqxn CoG.Tiled.Methods.Tiled
        @desc Creates an unloaded object or loads a TMX file immediately.
        @param string|nil sPath Optional map path.
        @param function|nil fRead Optional resource reader (path) returning XML text.
        @param function|nil fDecompress Optional decoder (bytes, format, expectedByteCount).
    !]]
    Tiled = function(this, cdat, super, sPath, fRead, fDecompress)

        super();
        if (sPath ~= nil) then
            this.load(sPath, fRead, fDecompress);
        end
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.addLayer
        @desc Adds a tile, object, image or group layer. Settings use
        {kind, attributes, properties, children}; kind defaults to layer. A parent selector
        must identify a group. New finite tile layers contain empty GIDs.
        @param table tDefinition Layer settings.
        @param number|string|nil vParent Optional parent group ID/name.
        @ret number nID Assigned layer ID.
    !]]
    addLayer = function(this, cdat, tDefinition, vParent)

        local tMap = requireMap(cdat.pri);
        local nID = nextID(tMap, false);
        local sKind = tDefinition.kind or "layer";
        assert(sKind == "layer" or sKind == "objectgroup" or sKind == "imagelayer" or sKind == "group", "Invalid Tiled layer kind.");
        local tLayer = makeElement(sKind, tDefinition);
        tLayer.attributes.id = tostring(nID);

        if (sKind == "layer" and Reader.child(tLayer, "data") == nil) then
            local nWidth = Reader.number(tLayer.attributes, "width", tMap.attributes.width, true);
            local nHeight = Reader.number(tLayer.attributes, "height", tMap.attributes.height, true);
            tLayer.attributes.width = tostring(nWidth);
            tLayer.attributes.height = tostring(nHeight);
            local tData = Reader.element("data", {encoding = "csv"});
            if (not tMap.attributes.infinite) then
                local tEmpty = {};
                for nIndex = 1, nWidth * nHeight do
                    tEmpty[nIndex] = "0";
                end
                tData.content = {table.concat(tEmpty, ",")};
            end
            Reader.append(tLayer, tData);
        end

        this.edit(function(tRoot)
            local tParent = tRoot;
            if (vParent ~= nil) then
                local tTemporary = Reader.compile(tRoot, cdat.pri.path, clone(cdat.pri.resources));
                local tGroup = Reader.layer(tTemporary, vParent);
                assert(tGroup and tGroup.kind == "group", "Tiled layer parent must be a group.");
                tParent = tGroup.raw;
            end
            Reader.append(tParent, tLayer);
            tRoot.attributes.nextlayerid = tostring(nID + 1);
        end);
        return nID;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.addObject
        @desc Adds an object to an object layer from {attributes, properties, children}.
        Shape elements, text, tile GIDs and templates may be supplied in the definition.
        @param number|string vLayer Object layer ID or unique name.
        @param table tDefinition Object definition.
        @ret number nID Assigned object ID.
    !]]
    addObject = function(this, cdat, vLayer, tDefinition)

        local nID = nextID(requireMap(cdat.pri), true);
        local tObject = makeElement("object", tDefinition);
        tObject.attributes.id = tostring(nID);
        this.edit(function(tRoot)
            local tTemporary = Reader.compile(tRoot, cdat.pri.path, clone(cdat.pri.resources));
            local tLayer = Reader.layer(tTemporary, vLayer);
            assert(tLayer and tLayer.kind == "objectgroup", "Tiled objects require an object layer.");
            Reader.append(tLayer.raw, tObject);
            tRoot.attributes.nextobjectid = tostring(nID + 1);
        end);
        return nID;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.addTileset
        @desc Embeds TSX XML or a definition {attributes, properties, children} into the map.
        Image/tile/animation children follow the XML element shape exposed by getDocument.
        Relative image and file paths are interpreted relative to this map.
        @param string|table vDefinition TSX source text or programmatic definition.
        @param number|nil nFirstGID Optional GID base; default follows existing ranges.
        @param string|nil sSourcePath Optional containing TSX filename for rebasing its paths.
        @ret number nFirstGID Assigned global tile ID base.
    !]]
    addTileset = function(this, cdat, vDefinition, nFirstGID, sSourcePath)

        local tMap = requireMap(cdat.pri);
        if (nFirstGID == nil) then
            nFirstGID = 1;
            for _, tTileset in ipairs(tMap.tilesets) do
                nFirstGID = math.max(nFirstGID, tTileset.firstgid + tTileset.maxLocalID + 1);
            end
        end
        local tTileset = rawtype(vDefinition) == "string" and XML(vDefinition).getRoot() or makeElement("tileset", vDefinition);
        assert(tTileset.name == "tileset", "addTileset requires a tileset root.");
        tTileset.attributes.firstgid = tostring(nFirstGID);
        if (sSourcePath ~= nil) then
            assert(rawtype(sSourcePath) == "string", "Tileset source path must be a filename.");
            Reader.rebase(tTileset, sSourcePath, cdat.pri.path);
        end
        this.edit(function(tRoot)
            Reader.insertTileset(tRoot, tTileset);
        end);
        return nFirstGID;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.create
        @desc Creates/replaces an empty map from attribute settings. Defaults are orthogonal,
        1 by 1 cells, 32 by 32 pixels, and finite. Hex/staggered maps default to y/odd;
        hexsidelength defaults to half the tile size along the stagger axis.
        @param table|nil tSettings TMX map attributes, including orientation and infinite.
        @ret Tiled this Map object for chaining.
    !]]
    create = function(this, cdat, tSettings)

        tSettings = clone(tSettings or {});
        tSettings.orientation = tSettings.orientation or "orthogonal";
        tSettings.width = tSettings.width or 1;
        tSettings.height = tSettings.height or 1;
        tSettings.tilewidth = tSettings.tilewidth or 32;
        tSettings.tileheight = tSettings.tileheight or 32;
        tSettings.version = tSettings.version or "1.0";
        if (tSettings.orientation == "hexagonal" or tSettings.orientation == "staggered") then
            tSettings.staggeraxis = tSettings.staggeraxis or "y";
            tSettings.staggerindex = tSettings.staggerindex or "odd";
            if (tSettings.orientation == "hexagonal" and tSettings.hexsidelength == nil) then
                local nDimension = tSettings.staggeraxis == "x" and tSettings.tilewidth or tSettings.tileheight;
                tSettings.hexsidelength = math.floor(nDimension / 2);
            end
        end
        local tRoot = makeElement("map", {attributes = tSettings});
        commit(cdat.pri, Reader.encode(tRoot), "", {});
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.edit
        @desc Runs a program edit on an independent XML root and commits after validation.
        This permits editing every TMX field, including advanced tileset/object metadata.
        Keep children and content indexes consistent: an element appears in both arrays.
        External resources can be supplied by fRead when an edit introduces references.
        @param function fEdit Callback (rootElement); its return value is ignored.
        @param function|nil fRead Optional resource reader for new references.
        @param function|nil fDecompress Optional decoder for newly supplied compressed data.
        @ret Tiled this Map object for chaining.
    !]]
    edit = function(this, cdat, fEdit, fRead, fDecompress)

        assert(rawtype(fEdit) == "function", "Tiled edit requires a function.");
        local tRoot = clone(requireMap(cdat.pri).raw);
        fEdit(tRoot);

        -- Reparse the callback's tree so retaining a callback reference cannot mutate
        -- private state after the transaction has committed.
        commit(cdat.pri, Reader.encode(tRoot), cdat.pri.path, clone(cdat.pri.resources), fRead, fDecompress);
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getDocument
        @desc Copies the canonical XML map root, retaining unknown TMX fields and elements.
        @ret table tRoot Independent root for inspection or edit planning.
    !]]
    getDocument = function(this, cdat)

        return clone(requireMap(cdat.pri).raw);
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getLayer
        @desc Copies a layer selected by ID or unique exact name, including effective
        group offsets/visibility and its finite blocks or infinite chunks.
        @param number|string vLayer Layer selector.
        @ret table|nil tLayer Layer record, or nil when absent.
    !]]
    getLayer = function(this, cdat, vLayer)

        local tLayer = Reader.layer(requireMap(cdat.pri), vLayer);
        return tLayer and clone(tLayer) or nil;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getLayers
        @desc Copies all layers in depth-first draw order, including group records.
        @ret table tLayers Ordered layer records.
    !]]
    getLayers = function(this, cdat)

        return clone(requireMap(cdat.pri).layers);
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getMap
        @desc Copies interpreted map attributes and typed map properties.
        @ret table tMap Map metadata; layer/tileset queries supply their own records.
    !]]
    getMap = function(this, cdat)

        local tMap = requireMap(cdat.pri);
        return {attributes = clone(tMap.attributes), properties = clone(tMap.properties)};
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getObject
        @desc Copies an object by map-wide ID. Shape, text and other XML remain in raw.
        @param number nID Object ID.
        @ret table|nil tObject Object record, or nil when absent.
    !]]
    getObject = function(this, cdat, nID)

        local tObject = requireMap(cdat.pri).objectsByID[nID];
        return tObject and clone(tObject) or nil;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getObjects
        @desc Copies all objects or those in one object layer, preserving document order.
        @param number|string|nil vLayer Optional object layer selector.
        @ret table tObjects Ordered object records.
    !]]
    getObjects = function(this, cdat, vLayer)

        local tMap = requireMap(cdat.pri);
        if (vLayer == nil) then
            return clone(tMap.objects);
        end
        local tLayer = Reader.layer(tMap, vLayer);
        assert(tLayer and tLayer.kind == "objectgroup", "getObjects requires an object layer.");
        return clone(tLayer.objects);
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getProperties
        @desc Copies typed properties for the map, selected layer or object ID.
        @param number|string|nil vLayer Optional layer selector; nil selects map.
        @param number|nil nObjectID Optional object ID, taking precedence over layer.
        @ret table tProperties Named records with type, propertyType, value and rawValue.
    !]]
    getProperties = function(this, cdat, vLayer, nObjectID)

        local tNode = target(requireMap(cdat.pri), vLayer, nObjectID);
        return clone(Reader.properties(tNode, cdat.pri.path));
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getTile
        @desc Copies resolved terrain and flip/hex rotation flags at a native cell.
        GID 0 returns an empty tile record; absent finite/chunk cells return nil.
        @param number|string vLayer Tile layer selector.
        @param number nX Native column.
        @param number nY Native row.
        @ret table|nil tTile Resolved tile record.
    !]]
    getTile = function(this, cdat, vLayer, nX, nY)

        local tMap = requireMap(cdat.pri);
        local nGID = Reader.cell(Reader.layer(tMap, vLayer), nX, nY);
        return nGID ~= nil and clone(Reader.resolve(tMap, nGID)) or nil;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getTilesets
        @desc Copies tilesets in ascending firstgid order, with sparse local tile IDs,
        typed properties, resolved image paths, animation frames and raw collision XML.
        @ret table tTilesets Ordered tileset records.
    !]]
    getTilesets = function(this, cdat)

        return clone(requireMap(cdat.pri).tilesets);
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.getXML
        @desc Returns canonical editable TMX. Tile data is CSV and templates are expanded;
        external TSX references and unknown metadata are retained.
        @ret string sXML UTF-8 map XML.
    !]]
    getXML = function(this, cdat)

        requireMap(cdat.pri);
        return '<?xml version="1.0" encoding="UTF-8"?>\n'..cdat.pri.source.."\n";
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.load
        @desc Loads TMX plus required TSX/templates atomically. The host controls resource
        reading and decompression; callbacks are used for this operation only.
        @param string sPath Map file path.
        @param function|nil fRead Reader (path) returning XML; default uses io.open.
        @param function|nil fDecompress Decoder (bytes, format, expectedByteCount).
        @ret Tiled this Map object for chaining.
    !]]
    load = function(this, cdat, sPath, fRead, fDecompress)

        assert(rawtype(sPath) == "string" and sPath:match("%S"), "Tiled map path must be nonblank.");
        assert(fRead == nil or rawtype(fRead) == "function", "Tiled reader must be a function.");
        local fReader = fRead or Reader.readFile;
        return this.parse(fReader(sPath), sPath, fReader, fDecompress);
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.parse
        @desc Parses TMX text atomically. sPath identifies its containing file so relative
        resources resolve correctly; nil uses the current working directory.
        @param string sSource TMX source text.
        @param string|nil sPath Containing map filename, not a directory.
        @param function|nil fRead Optional XML resource reader.
        @param function|nil fDecompress Optional compressed tile decoder.
        @ret Tiled this Map object for chaining.
    !]]
    parse = function(this, cdat, sSource, sPath, fRead, fDecompress)

        assert(sPath == nil or rawtype(sPath) == "string", "Tiled source path must be a string.");
        assert(fRead == nil or rawtype(fRead) == "function", "Tiled reader must be a function.");
        assert(fDecompress == nil or rawtype(fDecompress) == "function", "Tiled decompressor must be a function.");
        commit(cdat.pri, sSource, sPath or "", {}, fRead, fDecompress);
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.pixelToTile
        @desc Finds the cell containing displayed map pixels for any supported orientation.
        An optional layer selector removes its inherited pixel offset before projection.
        Coordinates outside finite bounds remain valid grid coordinates.
        @param number nPixelX Displayed horizontal coordinate.
        @param number nPixelY Displayed vertical coordinate.
        @param number|string|nil vLayer Optional layer offset context.
        @ret number nX Native column.
        @ret number nY Native row.
    !]]
    pixelToTile = function(this, cdat, nPixelX, nPixelY, vLayer)

        local tMap = requireMap(cdat.pri);
        assert(rawtype(nPixelX) == "number" and rawtype(nPixelY) == "number" and nPixelX == nPixelX and nPixelY == nPixelY and
               math.abs(nPixelX) < math.huge and math.abs(nPixelY) < math.huge, "Tiled pixel coordinates must be finite numbers.");
        if (vLayer ~= nil) then
            local tLayer = Reader.layer(tMap, vLayer);
            assert(tLayer, "Unknown Tiled layer.");
            nPixelX = nPixelX - tLayer.offsetx;
            nPixelY = nPixelY - tLayer.offsety;
        end
        return Projection.pixelToTile(tMap.attributes, nPixelX, nPixelY);
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.removeLayer
        @desc Removes a layer and its descendants. Remaining layer/object IDs are retained.
        @param number|string vLayer Layer selector.
        @ret Tiled this Map object for chaining.
    !]]
    removeLayer = function(this, cdat, vLayer)

        this.edit(function(tRoot)
            local tMap = Reader.compile(tRoot, cdat.pri.path, clone(cdat.pri.resources));
            local tLayer = Reader.layer(tMap, vLayer);
            assert(tLayer, "Unknown Tiled layer.");
            local tParent = tLayer.parentID and tMap.layersByID[tLayer.parentID].raw or tRoot;
            Reader.remove(tParent, tLayer.raw);
        end);
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.removeObject
        @desc Removes an object by ID without renumbering other objects.
        @param number nID Object ID.
        @ret Tiled this Map object for chaining.
    !]]
    removeObject = function(this, cdat, nID)

        this.edit(function(tRoot)
            local tMap = Reader.compile(tRoot, cdat.pri.path, clone(cdat.pri.resources));
            local tObject = tMap.objectsByID[nID];
            assert(tObject, "Unknown Tiled object ID.");
            Reader.remove(tMap.layersByID[tObject.layerID].raw, tObject.raw);
        end);
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.resolveGID
        @desc Resolves a raw GID independently of cell placement, preserving transformation flags.
        @param number nGID Raw unsigned 32-bit global tile ID.
        @ret table tTile Copied tile/tileset record.
    !]]
    resolveGID = function(this, cdat, nGID)

        return clone(Reader.resolve(requireMap(cdat.pri), nGID));
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.save
        @desc Writes canonical TMX using a host writer or io.open, rebasing resource paths
        to the output filename. Use either absolute filenames throughout or relative
        filenames throughout. Saving does not change map state or external resource files.
        @param string sPath Output TMX filename.
        @param function|nil fWrite Optional writer (path, XML) whose errors propagate.
        @ret Tiled this Map object for chaining.
    !]]
    save = function(this, cdat, sPath, fWrite)

        assert(rawtype(sPath) == "string" and sPath:match("%S"), "Tiled output path must be nonblank.");
        local tRoot = this.getDocument();
        Reader.rebase(tRoot, cdat.pri.path, sPath);
        local sXML = '<?xml version="1.0" encoding="UTF-8"?>\n'..Reader.encode(tRoot).."\n";
        if (fWrite ~= nil) then
            assert(rawtype(fWrite) == "function", "Tiled writer must be a function.");
            fWrite(sPath, sXML);
        else
            local hFile, sReason = io.open(sPath, "wb");
            assert(hFile, "Cannot open Tiled output: "..tostring(sReason));
            local bOK, vResult, sWriteReason = pcall(hFile.write, hFile, sXML);
            local bClosed, sCloseReason = hFile:close();
            assert(bOK and vResult and bClosed, "Cannot write Tiled output: "..tostring(sCloseReason or sWriteReason or vResult));
        end
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.setAttribute
        @desc Sets/removes a map, layer or object attribute and validates the result.
        This covers names, positions, visibility, map geometry and other TMX attributes.
        Booleans become TMX 1/0 values. Nil removes the attribute.
        @param string sName Attribute name.
        @param string|number|boolean|nil vValue Attribute value, or nil to remove.
        @param number|string|nil vLayer Optional layer selector; nil selects map.
        @param number|nil nObjectID Optional object ID, taking precedence over layer.
        @ret Tiled this Map object for chaining.
    !]]
    setAttribute = function(this, cdat, sName, vValue, vLayer, nObjectID)

        assert(rawtype(sName) == "string", "Tiled attribute name must be a string.");
        assert(vValue == nil or rawtype(vValue) == "string" or rawtype(vValue) == "number" or rawtype(vValue) == "boolean", "Invalid Tiled attribute value.");
        this.edit(function(tRoot)
            local tMap = Reader.compile(tRoot, cdat.pri.path, clone(cdat.pri.resources));
            local tNode = target(tMap, vLayer, nObjectID);
            if (rawtype(vValue) == "boolean") then
                tNode.attributes[sName] = vValue and "1" or "0";
            else
                tNode.attributes[sName] = vValue ~= nil and tostring(vValue) or nil;
            end
        end);
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.setProperty
        @desc Sets or removes a typed map/layer/object property. Nil removes it. Plain nested
        tables create class members; specify list for contiguous arrays. Other explicit
        types include int, float, bool, string, file, color and object.
        @param string sName Property name.
        @param any vValue New value, or nil to remove.
        @param string|nil sType Optional TMX type; inferred when absent.
        @param string|nil sPropertyType Optional Tiled custom class/enum name.
        @param number|string|nil vLayer Optional layer selector.
        @param number|nil nObjectID Optional object ID, taking precedence over layer.
        @ret Tiled this Map object for chaining.
    !]]
    setProperty = function(this, cdat, sName, vValue, sType, sPropertyType, vLayer, nObjectID)

        assert(rawtype(sName) == "string", "Tiled property name must be a string.");
        local tNew;
        if (vValue ~= nil) then
            checkValue(vValue, {}, 0);
            tNew = Reader.propertyNode(sName, vValue, sType, sPropertyType);
        end
        this.edit(function(tRoot)
            local tMap = Reader.compile(tRoot, cdat.pri.path, clone(cdat.pri.resources));
            local tTarget = target(tMap, vLayer, nObjectID);
            putProperty(tTarget, sName, tNew);
        end);
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.setTile
        @desc Replaces a raw GID, including flags. Infinite maps allocate a one-cell chunk
        when painting outside existing chunks; finite maps require an existing cell.
        @param number|string vLayer Tile layer selector.
        @param number nX Native column.
        @param number nY Native row.
        @param number nGID Raw GID; 0 clears the cell.
        @ret Tiled this Map object for chaining.
    !]]
    setTile = function(this, cdat, vLayer, nX, nY, nGID)

        Reader.resolve(requireMap(cdat.pri), nGID);
        this.edit(function(tRoot)
            local tMap = Reader.compile(tRoot, cdat.pri.path, clone(cdat.pri.resources));
            local tLayer = Reader.layer(tMap, vLayer);
            local _, tChunk, nIndex = Reader.cell(tLayer, nX, nY);
            if (tChunk == nil) then
                assert(tMap.attributes.infinite, "Cannot paint outside a finite tile layer.");
                local tNew = Reader.element("chunk", {x = tostring(nX), y = tostring(nY), width = "1", height = "1"});
                tNew.content = {tostring(nGID)};
                Reader.append(Reader.child(tLayer.raw, "data"), tNew);
            else
                tChunk.gids[nIndex] = nGID;
                local tText = {};
                for nPosition, nValue in ipairs(tChunk.gids) do
                    tText[nPosition] = tostring(nValue);
                end
                tChunk.raw.content = {table.concat(tText, ",")};
            end
        end);
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.setTileProperty
        @desc Sets/removes a tile-definition property by GID. Creates an explicit tile
        definition when needed. An external TSX is embedded and its file paths rebased
        before editing, so only this map changes; the external TSX file remains untouched.
        @param number nGID Global tile ID, optionally including transformation flags.
        @param string sName Property name.
        @param any vValue New value, or nil to remove.
        @param string|nil sType Optional property type.
        @param string|nil sPropertyType Optional custom Tiled class/enum name.
        @ret Tiled this Map object for chaining.
    !]]
    setTileProperty = function(this, cdat, nGID, sName, vValue, sType, sPropertyType)

        assert(rawtype(sName) == "string", "Tiled property name must be a string.");
        local tNew;
        if (vValue ~= nil) then
            checkValue(vValue, {}, 0);
            tNew = Reader.propertyNode(sName, vValue, sType, sPropertyType);
        end
        this.edit(function(tRoot)
            local tMap = Reader.compile(tRoot, cdat.pri.path, clone(cdat.pri.resources));
            local tResolved = Reader.resolve(tMap, nGID);
            assert(tResolved.tileset ~= nil, "Empty cells have no tile-definition properties.");
            local tTileset = tResolved.tileset;
            local tDefinition = tTileset.raw;

            -- Localize an external definition before applying the map-specific edit.
            if (tTileset.reference.attributes.source ~= nil) then
                tDefinition = clone(tDefinition);
                Reader.rebase(tDefinition, tTileset.source, cdat.pri.path);
                tDefinition.attributes.firstgid = tostring(tTileset.firstgid);
                Reader.remove(tRoot, tTileset.reference);
                Reader.insertTileset(tRoot, tDefinition);
            end

            local tTile;
            for _, tChild in ipairs(tDefinition.children) do
                if (tChild.name == "tile" and tonumber(tChild.attributes.id) == tResolved.localID) then
                    tTile = tChild;
                    break;
                end
            end
            if (tTile == nil and tNew ~= nil) then
                tTile = Reader.element("tile", {id = tostring(tResolved.localID)});
                Reader.append(tDefinition, tTile);
            end
            if (tTile ~= nil) then
                putProperty(tTile, sName, tNew);
            end
        end);
        return this;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.tileToPixel
        @desc Gets the displayed center of a native cell in any map orientation.
        Optional layer context adds inherited group/layer pixel offsets.
        @param number nX Native column.
        @param number nY Native row.
        @param number|string|nil vLayer Optional layer selector.
        @ret number nPixelX Displayed center x.
        @ret number nPixelY Displayed center y.
    !]]
    tileToPixel = function(this, cdat, nX, nY, vLayer)

        local tMap = requireMap(cdat.pri);
        assert(rawtype(nX) == "number" and nX % 1 == 0 and rawtype(nY) == "number" and nY % 1 == 0, "Tiled cell coordinates must be integers.");
        local nPixelX, nPixelY = Projection.tileToPixel(tMap.attributes, nX, nY);
        if (vLayer ~= nil) then
            local tLayer = Reader.layer(tMap, vLayer);
            assert(tLayer, "Unknown Tiled layer.");
            nPixelX = nPixelX + tLayer.offsetx;
            nPixelY = nPixelY + tLayer.offsety;
        end
        return nPixelX, nPixelY;
    end,


    --[[!
        @fqxn CoG.Tiled.Methods.toAStar
        @desc Imports grouped AStar class properties into an independent native navigation
        map. Automatically creates a system when omitted. Returns native map/system, layers
        keyed by Tiled ID, objectNodes and rovers keyed by Tiled object ID, and bounds.
        Subsequent Tiled edits do not mutate an existing navigation map; import again under
        a new map name. A configureNode callback runs after native map registration, so a
        callback failure leaves that map registered in a supplied system.
        @param string sName Unique native AStar map name.
        @param AStar|nil oSystem Optional existing system with every required aspect.
        @param table|nil tOptions Optional layers, bounds and configureNode settings.
        @ret table tNavigation Native AStar bridge result.
    !]]
    toAStar = function(this, cdat, sName, oSystem, tOptions)

        return Bridge.create(requireMap(cdat.pri), sName, oSystem, tOptions);
    end,
},
CoG,   --extending class
false, --if the class is final
nil    --interfaces
);
