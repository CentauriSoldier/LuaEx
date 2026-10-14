--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge
    @desc Translates typed AStar properties into native CoG AStar maps, nodes, rovers
    and ports. Presentation orientation does not replace AStar movement rules.
!]]
local Reader = require("LuaEx.inc.cog.tiled.Reader");
local Projection = require("LuaEx.inc.cog.tiled.Projection");
local Bridge = {};


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.settings
    @desc Extracts the grouped AStar class property. Its propertytype is descriptive;
    its exact property name, AStar, selects the integration settings.
    @ret table tSettings Plain application settings, or empty when absent.
!]]
local function settings(tRecord)

    local tProperty = tRecord.properties.AStar;
    if (tProperty == nil) then
        return {};
    end
    assert(tProperty.type == "class", "The AStar property must be a Tiled class property.");
    local tSettings = Reader.values(tProperty.value);

    -- Native AStar names are case-insensitive. Normalize before inheritance merging,
    -- so a tile's MUD replaces a map's mud rather than creating a second aspect.
    for _, sField in ipairs({"aspects", "affinities", "aversions", "abhors"}) do
        local tValues = tSettings[sField];
        if (rawtype(tValues) == "table") then
            local tNormalized = {};
            for sName, vValue in pairs(tValues) do
                assert(rawtype(sName) == "string", "AStar aspect names must be strings.");
                local sUpper = sName:upper();
                assert(tNormalized[sUpper] == nil, "Duplicate AStar aspect ignoring case.");
                tNormalized[sUpper] = vValue;
            end
            tSettings[sField] = tNormalized;
        end
    end
    return tSettings;
end


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.merge
    @desc Recursively overlays settings, preserving parent fields absent from the child.
    @ret table tResult Independent merged settings.
!]]
local function merge(tBase, tOverride)

    local tResult = clone(tBase);
    for sKey, vValue in pairs(tOverride) do
        if (rawtype(vValue) == "table" and rawtype(tResult[sKey]) == "table") then
            tResult[sKey] = merge(tResult[sKey], vValue);
        else
            tResult[sKey] = clone(vValue);
        end
    end
    return tResult;
end


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.checkNumber
    @desc Checks finite numeric settings and an optional lower/upper bound.
!]]
local function checkNumber(nValue, sName, nMinimum, nMaximum)

    assert(rawtype(nValue) == "number" and nValue == nValue and math.abs(nValue) < math.huge,
           "AStar setting '"..sName.."' must be a finite number.");
    assert(nMinimum == nil or nValue >= nMinimum, "AStar setting '"..sName.."' is too small.");
    assert(nMaximum == nil or nValue <= nMaximum, "AStar setting '"..sName.."' is too large.");
end


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.collectAspects
    @desc Validates aspect names and their values while collecting the system vocabulary.
!]]
local function collectAspects(tValues, tNames, bBoolean, bIntensity)

    assert(rawtype(tValues) == "table", "AStar aspect settings must be a class property.");
    local tSeen = {};
    for sName, vValue in pairs(tValues) do
        assert(rawtype(sName) == "string" and sName:match("^[%a_][%w_]*$"), "Invalid AStar aspect name.");
        local sUpper = sName:upper();
        assert(not tSeen[sUpper], "Duplicate AStar aspect ignoring case.");
        tSeen[sUpper] = true;
        tNames[sUpper] = sUpper;

        if (bBoolean) then
            assert(rawtype(vValue) == "boolean", "AStar abhoration values must be boolean.");
        else
            checkNumber(vValue, sName, bIntensity and 0 or nil, bIntensity and 1 or nil);
        end
    end
end


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.checkSettings
    @desc Validates settings before creating a registered AStar map. Unrecognized fields
    remain available to configureNode callbacks rather than becoming game rules.
!]]
local function checkSettings(tSettings, tNames)

    for _, sName in ipairs({"passable", "rover", "twoWay", "retainsPointsOverCycle"}) do
        if (tSettings[sName] ~= nil) then
            assert(rawtype(tSettings[sName]) == "boolean", "AStar setting '"..sName.."' must be boolean.");
        end
    end
    for _, sName in ipairs({"aspects", "affinities", "aversions", "abhors"}) do
        if (tSettings[sName] ~= nil) then
            collectAspects(tSettings[sName], tNames, sName == "abhors", sName == "aspects");
        end
    end
    for _, sName in ipairs({"types", "deniedTypes", "ports"}) do
        local tList = tSettings[sName];
        if (tList ~= nil) then
            assert(rawtype(tList) == "table", "AStar '"..sName.."' requires a list property.");
            local nCount = 0;
            for nIndex, vValue in pairs(tList) do
                assert(rawtype(nIndex) == "number" and nIndex % 1 == 0 and nIndex >= 1 and nIndex <= #tList, "AStar list is not contiguous.");
                if (sName == "ports") then
                    checkNumber(vValue, "port object ID", 1);
                    assert(vValue % 1 == 0, "AStar port object IDs must be integers.");
                else
                    assert(rawtype(vValue) == "string" and vValue:match("%S"), "AStar rover type must be nonblank.");
                end
                nCount = nCount + 1;
            end
            assert(nCount == #tList, "AStar list is not contiguous.");
        end
    end
    if (tSettings.allowedLayers ~= nil) then
        assert(rawtype(tSettings.allowedLayers) == "table", "AStar allowedLayers requires a class property.");
        for sName, bAllowed in pairs(tSettings.allowedLayers) do
            assert(rawtype(sName) == "string" and sName:match("%S") and rawtype(bAllowed) == "boolean", "Invalid AStar layer permission.");
        end
    end
    if (tSettings.movePoints ~= nil) then
        assert(rawtype(tSettings.movePoints) == "table", "AStar movePoints requires a class property.");
        local tAllowed = {max = true, current = true, cycleFlat = true, cyclePercent = true};
        for sName, nValue in pairs(tSettings.movePoints) do
            assert(tAllowed[sName], "Unknown movement point setting '"..sName.."'.");
            checkNumber(nValue, sName, (sName == "max" or sName == "current") and 0 or nil);
        end
        assert(tSettings.movePoints.max == nil or tSettings.movePoints.max >= 1, "AStar movement capacity must be at least 1.");
        assert(tSettings.movePoints.current == nil or tSettings.movePoints.current <= (tSettings.movePoints.max or 1), "AStar current points exceed capacity.");
    end
end


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.effective
    @desc Resolves node defaults in order: map, tileset, tile, ancestor groups, layer.
    Explicit layer fields override the corresponding inherited fields.
    @ret table tSettings Effective node settings.
!]]
local function effective(tMap, tLayer, nGID)

    local tSettings = settings(tMap);
    local tTile = Reader.resolve(tMap, nGID);
    if (tTile.tileset ~= nil) then
        tSettings = merge(tSettings, settings(tTile.tileset));
        if (tTile.definition ~= nil) then
            tSettings = merge(tSettings, settings(tTile.definition));
        end
    end
    local tParents = {};
    local tCurrent = tLayer;
    while (tCurrent ~= nil) do
        table.insert(tParents, 1, tCurrent);
        tCurrent = tCurrent.parentID and tMap.layersByID[tCurrent.parentID] or nil;
    end
    for _, tParent in ipairs(tParents) do
        tSettings = merge(tSettings, settings(tParent));
    end
    return tSettings;
end


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.objectCell
    @desc Resolves explicit native tileX/tileY, or projects a TMX object anchor to the
    target tile layer. Isometric object pixels are unprojected Tiled coordinates.
    @ret number nX Native column.
    @ret number nY Native row.
!]]
local function objectCell(tMap, tObject, tSettings, tTarget)

    if (tSettings.tileX ~= nil or tSettings.tileY ~= nil) then
        checkNumber(tSettings.tileX, "tileX");
        checkNumber(tSettings.tileY, "tileY");
        assert(tSettings.tileX % 1 == 0 and tSettings.tileY % 1 == 0, "AStar native coordinates must be integers.");
        return tSettings.tileX, tSettings.tileY;
    end
    local tAttributes = tMap.attributes;
    local nX = tObject.attributes.x or 0;
    local nY = tObject.attributes.y or 0;
    if (tAttributes.orientation == "isometric") then
        local nTileX = nX / tAttributes.tileheight;
        local nTileY = nY / tAttributes.tileheight;
        nX = (nTileX - nTileY) * tAttributes.tilewidth / 2 + tAttributes.height * tAttributes.tilewidth / 2;
        nY = (nTileX + nTileY) * tAttributes.tileheight / 2;
    elseif (tAttributes.orientation == "oblique") then
        local nOriginalX = nX;
        nX = nX + nY * tAttributes.skewx / tAttributes.tileheight;
        nY = nY + nOriginalX * tAttributes.skewy / tAttributes.tilewidth;
    end
    local tObjectLayer = tMap.layersByID[tObject.layerID];
    return Projection.pixelToTile(tAttributes,
        nX + tObjectLayer.offsetx - tTarget.offsetx,
        nY + tObjectLayer.offsety - tTarget.offsety);
end


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.configureRover
    @desc Applies imported rover responses and movement settings through native AStar APIs.
    Callbacks and complex passage rules remain programmable after import.
!]]
local function configureRover(oRover, tSettings)

    for sName, nValue in pairs(tSettings.affinities or {}) do
        oRover.getAffinity(sName).setValue(nValue);
    end
    for sName, nValue in pairs(tSettings.aversions or {}) do
        oRover.getAversion(sName).setValue(nValue);
    end
    for sName, bValue in pairs(tSettings.abhors or {}) do
        oRover.setAbhors(sName, bValue);
    end
    for _, sType in ipairs(tSettings.types or {}) do
        oRover.addType(sType);
    end
    for _, sType in ipairs(tSettings.deniedTypes or {}) do
        oRover.addDeniedType(sType);
    end
    for sLayer, bAllowed in pairs(tSettings.allowedLayers or {}) do
        oRover.setLayerAllowed(sLayer, bAllowed);
    end

    -- Capacity must be established before current points are applied.
    local tPoints = tSettings.movePoints or {};
    local oPool = oRover.getMovePointPool();
    if (tPoints.max ~= nil) then
        oPool.set(tPoints.max, Pool.ASPECT.MAX);
    end
    if (tPoints.cycleFlat ~= nil) then
        oPool.set(tPoints.cycleFlat, Pool.ASPECT.CYCLE_FLAT);
    end
    if (tPoints.cyclePercent ~= nil) then
        oPool.set(tPoints.cyclePercent, Pool.ASPECT.CYCLE_PERCENT);
    end
    if (tPoints.current ~= nil) then
        oPool.set(tPoints.current, Pool.ASPECT.CURRENT);
    end
end


--[[!
    @fqxn CoG.Tiled.Helpers.AStarBridge.create
    @desc Creates an independent native AStar map. Options select tile layer IDs/names,
    optional finite bounds {x,y,width,height}, and a configureNode callback.
    Infinite maps use occupied chunk bounds; holes are blocked. Staggered diamonds
    use native four-edge staggered adjacency.
    @ret table tBridge Native system/map plus layer, object-node and rover lookup tables.
!]]
function Bridge.create(tMap, sName, oSystem, tOptions)

    tOptions = tOptions or {};
    assert(rawtype(tOptions) == "table", "Tiled AStar options must be a table.");
    assert(rawtype(sName) == "string" and sName:match("%S"), "AStar map name must be nonblank.");
    assert(tOptions.configureNode == nil or rawtype(tOptions.configureNode) == "function", "configureNode must be a function.");
    local tLayers = {};
    local tNames = {};
    local tLayerNames = {};
    local tSelected = {};
    local tSelections = tOptions.layers;

    if (tSelections == nil) then
        tSelections = {};
        for _, tLayer in ipairs(tMap.layers) do
            if (tLayer.kind == "layer") then
                tSelections[#tSelections + 1] = tLayer.id;
            end
        end
    end
    assert(rawtype(tSelections) == "table", "AStar layer selection must be an ordered list.");

    -- Validate data and collect aspect names before touching an existing AStar system.
    for _, vLayer in ipairs(tSelections) do
        local tLayer = Reader.layer(tMap, vLayer);
        assert(tLayer and tLayer.kind == "layer", "AStar selection must identify a tile layer.");
        assert(tLayer.name:match("%S") and not tLayerNames[tLayer.name:upper()], "AStar tile layer names must be nonblank and unique ignoring case.");
        tLayerNames[tLayer.name:upper()] = true;
        tSelected[tLayer.id] = true;
        tLayers[#tLayers + 1] = tLayer;
        for _, tChunk in ipairs(tLayer.chunks) do
            for _, nGID in ipairs(tChunk.gids) do
                checkSettings(effective(tMap, tLayer, nGID), tNames);
            end
        end
    end
    assert(#tLayers > 0, "AStar import requires at least one tile layer.");

    local tBounds = tOptions.bounds and clone(tOptions.bounds) or nil;
    if (tBounds == nil and not tMap.attributes.infinite) then
        tBounds = {x = 0, y = 0, width = tMap.attributes.width, height = tMap.attributes.height};
    elseif (tBounds == nil) then
        local nLeft, nTop, nRight, nBottom;
        for _, tLayer in ipairs(tLayers) do
            for _, tChunk in ipairs(tLayer.chunks) do
                nLeft = nLeft and math.min(nLeft, tChunk.x) or tChunk.x;
                nTop = nTop and math.min(nTop, tChunk.y) or tChunk.y;
                nRight = nRight and math.max(nRight, tChunk.x + tChunk.width) or tChunk.x + tChunk.width;
                nBottom = nBottom and math.max(nBottom, tChunk.y + tChunk.height) or tChunk.y + tChunk.height;
            end
        end
        assert(nLeft, "Empty infinite map needs explicit AStar bounds.");
        tBounds = {x = nLeft, y = nTop, width = nRight - nLeft, height = nBottom - nTop};
    end
    for _, sKey in ipairs({"x", "y", "width", "height"}) do
        checkNumber(tBounds[sKey], "bounds."..sKey);
        assert(tBounds[sKey] % 1 == 0, "AStar bounds must use integers.");
    end
    assert(tBounds.width > 0 and tBounds.height > 0, "AStar bounds require positive dimensions.");

    local tObjects = {};
    local tObjectLookup = {};
    for _, tObject in ipairs(tMap.objects) do
        local tSettings = settings(tObject);
        if (next(tSettings) ~= nil) then
            checkSettings(tSettings, tNames);
            local vLayer = tSettings.layer or (#tLayers == 1 and tLayers[1].id or nil);
            local tLayer = vLayer and Reader.layer(tMap, vLayer) or nil;
            assert(tLayer and tSelected[tLayer.id], "AStar object requires a selected target tile layer.");
            local nX, nY = objectCell(tMap, tObject, tSettings, tLayer);
            assert(nX >= tBounds.x and nX < tBounds.x + tBounds.width and nY >= tBounds.y and nY < tBounds.y + tBounds.height, "AStar object lies outside import bounds.");
            assert(Reader.cell(tLayer, nX, nY) ~= nil, "AStar object lies in an absent chunk cell.");
            local tPlan = {object = tObject, settings = tSettings, layer = tLayer, x = nX, y = nY};
            tObjects[#tObjects + 1] = tPlan;
            tObjectLookup[tObject.id] = tPlan;
        end
    end
    for _, tPlan in ipairs(tObjects) do
        for _, nTarget in ipairs(tPlan.settings.ports or {}) do
            assert(tObjectLookup[nTarget], "AStar port targets an object without AStar settings.");
        end
    end

    local tAspects = {};
    for sName in pairs(tNames) do
        tAspects[#tAspects + 1] = sName;
    end
    table.sort(tAspects);
    if (oSystem == nil) then
        oSystem = AStar(table.unpack(tAspects));
    else
        type.assert.custom(oSystem, "AStar");
        for _, sAspect in ipairs(tAspects) do
            assert(oSystem.aspectNames[sAspect], "AStar system lacks imported aspect '"..sAspect.."'.");
        end
    end
    assert(oSystem.getMap(sName) == nil, "AStar map name already exists.");

    local tConfigs = {};
    for _, tLayer in ipairs(tLayers) do
        tConfigs[#tConfigs + 1] = AStar.LayerConfig(tLayer.name, table.unpack(tAspects));
    end
    local tLayout = {originX = tBounds.x, originY = tBounds.y};
    local nType = ASTAR_MAP_TYPE_SQUARE;
    if (tMap.attributes.orientation == "hexagonal" or tMap.attributes.orientation == "staggered") then
        nType = tMap.attributes.staggeraxis == "x" and ASTAR_MAP_TYPE_HEX_FLAT or ASTAR_MAP_TYPE_HEX_POINTED;
        if (tMap.attributes.orientation == "staggered") then
            nType = ASTAR_MAP_TYPE_STAGGERED;
        end
        tLayout.staggerAxis = tMap.attributes.staggeraxis;
        tLayout.staggerIndex = tMap.attributes.staggerindex;
    end
    local oMap = oSystem.newMap(sName, nType, tConfigs, tBounds.width, tBounds.height, tLayout);
    local tResult = {system = oSystem, map = oMap, bounds = tBounds, layers = {}, objectNodes = {}, rovers = {}};

    -- Populate native nodes. Missing chunk cells are blocked; a present empty GID
    -- is a real cell and follows the same map/layer defaults as painted terrain.
    for _, tLayer in ipairs(tLayers) do
        tResult.layers[tLayer.id] = oMap.getLayer(tLayer.name);
        for nY = tBounds.y, tBounds.y + tBounds.height - 1 do
            for nX = tBounds.x, tBounds.x + tBounds.width - 1 do
                local oNode = oMap.getNode(tLayer.name, nX, nY);
                local nGID = Reader.cell(tLayer, nX, nY);
                local tSettings = nGID and effective(tMap, tLayer, nGID) or {};
                oNode.setPassable(nGID ~= nil and tSettings.passable ~= false);
                for _, sAspect in ipairs(tAspects) do
                    oNode.getAspect(sAspect).getImpactor().setValue(0);
                end
                for sAspect, nValue in pairs(tSettings.aspects or {}) do
                    oNode.getAspect(sAspect).getImpactor().setValue(nValue);
                end

                if (tOptions.configureNode ~= nil) then
                    local tTile = nGID and clone(Reader.resolve(tMap, nGID)) or nil;
                    tOptions.configureNode(oNode, tTile, clone(tSettings), nX, nY, tLayer.id);
                end
            end
        end
    end

    -- Objects can overlay node terrain, create rovers, and connect named object anchors.
    for _, tPlan in ipairs(tObjects) do
        local tSettings = tPlan.settings;
        local oNode = oMap.getNode(tPlan.layer.name, tPlan.x, tPlan.y);
        tResult.objectNodes[tPlan.object.id] = oNode;
        if (tSettings.passable ~= nil) then
            oNode.setPassable(tSettings.passable);
        end
        for sAspect, nValue in pairs(tSettings.aspects or {}) do
            oNode.getAspect(sAspect).getImpactor().setValue(nValue);
        end
        if (tSettings.rover) then
            local oRover = oNode.createRover(tSettings.retainsPointsOverCycle);
            configureRover(oRover, tSettings);
            tResult.rovers[tPlan.object.id] = oRover;
        end
    end
    for _, tPlan in ipairs(tObjects) do
        local oNode = tResult.objectNodes[tPlan.object.id];
        for _, nTarget in ipairs(tPlan.settings.ports or {}) do
            oNode.addPort(tResult.objectNodes[nTarget], tPlan.settings.twoWay ~= false);
        end
    end

    return tResult;
end

return Bridge;
