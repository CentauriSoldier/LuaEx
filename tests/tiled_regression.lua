local oMap = Tiled().create({width = 3, height = 3});
local nLayer = oMap.addLayer({attributes = {name = "Ground"}});
assert(oMap.getTile(nLayer, 0, 0).gid == 0);
local tNav = oMap.toAStar("created");
assert(#tNav.map.getNode("Ground", 1, 1).getNeighbors(true) == 4);
local Reader = require("LuaEx.inc.cog.tiled.Reader");
local function fails(fAction)

    assert(not pcall(fAction), "Expected invalid input to be rejected.");
end

local tFiles = {
    ["maps/world.tmx"] = [=[
        <map orientation="orthogonal" width="3" height="3" tilewidth="32" tileheight="32" custom="preserve">
            <properties>
                <property name="AStar" type="class" propertytype="Navigation"><properties>
                    <property name="aspects" type="class"><properties>
                        <property name="mud" type="float" value="0"/><property name="sand" type="float" value="0"/>
                    </properties></property>
                </properties></property>
                <property name="enabled" type="bool" value="true"/>
                <property name="asset" type="file" value="../assets/file.txt"/>
                <property name="target" type="object" value="7"/>
                <property name="enum" type="int" propertytype="Mode" value="2"/>
                <property name="list" type="list"><item type="int" value="3"/><item type="bool" value="false"/></property>
            </properties>
            <tileset firstgid="10" source="../tiles/basic.tsx"/>
            <group id="1" name="Terrain" offsetx="4" offsety="8" opacity="0.5" parallaxx="0.5">
                <layer id="2" name="Ground" width="3" height="3" offsetx="2" opacity="0.4">
                    <data encoding="csv">10,11,0, 0,11,10, 10,0,11</data>
                </layer>
                <imagelayer id="3" name="Backdrop"><image source="../assets/backdrop.png"/></imagelayer>
            </group>
            <objectgroup id="4" name="Objects"><object id="7" template="../templates/dragon.tx" x="16" y="16">
                <properties><property name="title" value="Ed's dragon"/></properties>
            </object></objectgroup>
            <extension preserved="yes"><data>unknown metadata</data></extension>
        </map>
    ]=],
    ["tiles/basic.tsx"] = [=[
        <tileset name="Terrain" tilewidth="32" tileheight="32" tilecount="2" columns="2">
            <image source="../assets/terrain.png" width="64" height="32"/>
            <tile id="1" type="Mud">
                <properties><property name="AStar" type="class"><properties>
                    <property name="aspects" type="class"><properties>
                        <property name="mud" type="float" value="0.75"/>
                    </properties></property>
                </properties></property></properties>
                <animation><frame tileid="0" duration="100"/><frame tileid="1" duration="200"/></animation>
                <objectgroup><object id="1" x="0" y="0" width="32" height="32"><ellipse/></object></objectgroup>
            </tile>
        </tileset>
    ]=],
    ["templates/dragon.tx"] = [=[
        <template><tileset firstgid="1" source="../tiles/basic.tsx"/>
            <object name="Dragon" gid="2147483650" width="32" height="32">
                <properties><property name="title" value="Bob's dragon"/>
                    <property name="icon" type="file" value="../assets/icon.png"/>
                </properties>
            </object>
        </template>
    ]=],
};
local nReads = 0;
local function readResource(sPath)

    nReads = nReads + 1;
    return assert(tFiles[sPath], "Missing fixture '"..sPath.."'.");
end

-- External resources, typed properties, group inheritance and template remapping.
local oTiled = Tiled("maps/world.tmx", readResource);
assert(class.ischildorself(class.getname(oTiled), CoG) and nReads == 3);
assert(oTiled.getMap().attributes.custom == "preserve");
assert(#oTiled.getLayers() == 4 and #oTiled.getObjects() == 1);
local tGround = oTiled.getLayer("Ground");
assert(tGround.offsetx == 6 and tGround.offsety == 8);
assert(math.abs(tGround.opacity - 0.2) < 0.00001 and tGround.parallaxx == 0.5);
local tProperties = oTiled.getProperties();
assert(tProperties.enabled.value and tProperties.enabled.type == "bool");
assert(tProperties.asset.value == "assets/file.txt" and tProperties.target.value == 7);
assert(tProperties.enum.propertyType == "Mode");
assert(tProperties.list.value[1].value == 3 and tProperties.list.value[2].value == false);
assert(oTiled.getTile(2, 0, 0).localID == 0);
assert(oTiled.getTile(2, 1, 0).definition.animation[2].duration == 200);
assert(oTiled.getTile(2, 2, 0).gid == 0 and oTiled.getTile(2, 3, 0) == nil);
assert(oTiled.getTilesets()[1].images[1].source == "assets/terrain.png");
assert(oTiled.getObject(7).attributes.gid == 2147483659);
assert(oTiled.getProperties(nil, 7).title.value == "Ed's dragon");
assert(oTiled.getProperties(nil, 7).icon.value == "assets/icon.png");
assert(not oTiled.getXML():find('template=', 1, true));
assert(oTiled.getXML():find('preserved="yes"', 1, true));

-- Queries and retained callback references never expose private state.
tGround.chunks[1].gids[1] = 0;
assert(oTiled.getTile(2, 0, 0).gid == 10);
local tRetained;
oTiled.edit(function(tRoot)
    tRetained = tRoot;
    tRoot.attributes.backgroundcolor = "#112233";
end);
tRetained.attributes.backgroundcolor = "changed later";
assert(oTiled.getMap().attributes.backgroundcolor == "#112233");
local sBefore = oTiled.getXML();
fails(function() oTiled.parse("<map/>"); end);
fails(function() oTiled.edit(function(tRoot) tRoot.attributes.tilewidth = "0"; end); end);
fails(function() oTiled.setTile(2, 0, 0, 1000); end);
assert(oTiled.getXML() == sBefore);
local tCycle = {};
tCycle.self = tCycle;
fails(function() oTiled.setProperty("cycle", tCycle); end);
assert(oTiled.getXML() == sBefore);

-- Edits, copy and native serialization retain external resources without file reads.
oTiled.setTile(2, 0, 0, 0xf000000b);
local tFlagged = oTiled.getTile(2, 0, 0);
assert(tFlagged.gid == 11 and tFlagged.flipHorizontal and tFlagged.flipVertical);
assert(tFlagged.flipDiagonal and tFlagged.rotateHex120);
oTiled.setProperty("note", "A & B\nline", "string");
oTiled.setProperty("list2", {1, 2, 3}, "list");
oTiled.setProperty("enabled", nil);
assert(oTiled.getProperties().note.value == "A & B\nline");
assert(oTiled.getProperties().list2.value[3].value == 3 and oTiled.getProperties().enabled == nil);
local nBeforeCopies = nReads;
local oCopy = clone(oTiled);
local oRestored = deserialize(serialize(oTiled));
assert(nReads == nBeforeCopies);
assert(oCopy.getTile(2, 0, 0).rawGID == 0xf000000b);
assert(oRestored.getTile(2, 0, 0).definition.properties.AStar.type == "class");
oCopy.setTile(2, 0, 0, 0);
assert(oTiled.getTile(2, 0, 0).gid == 11);
assert(tostring(clone(Tiled())) == "" and tostring(deserialize(serialize(Tiled()))) == "");
local sSaved;
oTiled.save("output/sub/world.tmx", function(sPath, sXML)
    assert(sPath == "output/sub/world.tmx");
    sSaved = sXML;
end);
assert(sSaved:find('../../tiles/basic.tsx', 1, true));
local oSaved = Tiled().parse(sSaved, "output/sub/world.tmx", readResource);
assert(oSaved.getProperties().asset.value == "assets/file.txt");
assert(oSaved.getProperties(nil, 7).icon.value == "assets/icon.png");

-- Every orientation has the same center-to-cell API, including negative coordinates.
for _, sOrientation in ipairs({"orthogonal", "isometric", "oblique", "staggered", "hexagonal"}) do
    for _, sAxis in ipairs({"x", "y"}) do
        for _, sIndex in ipairs({"odd", "even"}) do
            local oGrid = Tiled().create({orientation = sOrientation, width = 5, height = 5,
                tilewidth = 64, tileheight = 48, skewx = 12, skewy = -4,
                staggeraxis = sAxis, staggerindex = sIndex, hexsidelength = 16});
            local nLayer = oGrid.addLayer({attributes = {name = "Ground", offsetx = 7, offsety = -3}});
            for nX = -3, 3 do
                for nY = -3, 3 do
                    local nPX, nPY = oGrid.tileToPixel(nX, nY, nLayer);
                    local nRX, nRY = oGrid.pixelToTile(nPX, nPY, nLayer);
                    assert(nRX == nX and nRY == nY, "Projection failed for "..sOrientation.."/"..sAxis.."/"..sIndex);
                end
            end
            local tNavigation = oGrid.toAStar("orientation");
            local oCenter = tNavigation.map.getNode("Ground", 2, 2);
            assert(#oCenter.getNeighbors(true) == (sOrientation == "hexagonal" and 6 or 4));
            local oRover = oCenter.createRover();
            for _, oNeighbor in ipairs(oCenter.getNeighbors(true)) do
                assert(oCenter.canTraverseTo(oNeighbor, oRover));
                assert(AStar.Path(oCenter, oNeighbor, oRover).hasPath());
            end
            if (sOrientation == "staggered") then
                local oWrong = sAxis == "x" and tNavigation.map.getNode("Ground", 2, 3) or tNavigation.map.getNode("Ground", 3, 2);
                assert(not oCenter.canTraverseTo(oWrong, oRover));
            end
        end
    end
end
local oHex = Tiled().create({orientation = "hexagonal", staggeraxis = "x", hexsidelength = 16});
local nHX, nHY = oHex.pixelToTile(1, 1);
assert(nHX ~= 0 or nHY ~= 0, "Hex corners must use the polygon, not its bounding box.");

-- Programmatically create terrain and actors, then exercise actual rover cost/path rules.
local oCreated = Tiled().create({width = 3, height = 3});
local nTiles = oCreated.addLayer({attributes = {name = "Ground"}});
local nObjects = oCreated.addLayer({kind = "objectgroup", attributes = {name = "Actors"}});
oCreated.addTileset(tFiles["tiles/basic.tsx"]);
oCreated.setTile(nTiles, 1, 0, 2);
oCreated.setProperty("AStar", {aspects = {mud = 0, sand = 0}}, "class");
local nExit = oCreated.addObject(nObjects, {attributes = {name = "Exit"},
    properties = {AStar = {layer = "Ground", tileX = 2, tileY = 2}}});
local nActor = oCreated.addObject(nObjects, {attributes = {name = "Scout"}, properties = {
    AStar = {layer = "Ground", tileX = 0, tileY = 0, rover = true,
        affinities = {mud = 0.5}, aversions = {mud = 1}, abhors = {sand = true},
        types = {"scout"}, deniedTypes = {"enemy"}, allowedLayers = {Ground = true},
        retainsPointsOverCycle = false, movePoints = {max = 100, current = 100, cycleFlat = 10},
        ports = {nExit}, twoWay = false,
    },
}});
local tNavigation = oCreated.toAStar("game");
assert(type(tNavigation.map) == "AStarMap" and type(tNavigation.system) == "AStar");
local oRover = tNavigation.rovers[nActor];
assert(oRover.getAffinity("mud").getValue() == 0.5 and oRover.getAversion("mud").getValue() == 1);
assert(oRover.abhors("sand") and oRover.isType("scout") and oRover.getDeniedTypes()[1] == "ENEMY");
assert(oRover.getMovePoints() == 100 and not oRover.retainsPointsOverCycle());
local oMud = tNavigation.map.getNode("Ground", 1, 0);
assert(oMud.getAspectImpact("mud") == 0.75 and oMud.getEntryCost(oRover) == 13.75);
assert(tNavigation.map.getNode("Ground", 0, 1).getEntryCost(oRover) == 10);
local oStart = tNavigation.objectNodes[nActor];
local oEnd = tNavigation.objectNodes[nExit];
assert(oStart.hasPort(oEnd) and not oEnd.hasPort(oStart));
local oPath = AStar.Path(oStart, oEnd, oRover);
assert(oPath.hasPath() and oPath.getNodeCount() == 2);
assert(oPath.step() and oRover.getOwner() == oEnd);
oCreated.setProperty("AStar", {passable = false}, "class", nil, nTiles);
assert(tNavigation.map.getNode("Ground", 0, 1).isPassable(oRover));
assert(not oCreated.toAStar("changed").map.getNode("Ground", 0, 1).isPassable());
local oSupplied = AStar("mud", "sand");
assert(oCreated.toAStar("supplied", oSupplied).system == oSupplied);
fails(function() oCreated.toAStar("supplied", oSupplied); end);
fails(function() oCreated.toAStar("missing aspect", AStar()); end);

-- Infinite chunk holes are distinct from present empty cells; native origins stay negative.
local oInfinite = Tiled().create({orientation = "hexagonal", infinite = true, width = 0, height = 0, staggeraxis = "y", staggerindex = "even"});
local nInfinite = oInfinite.addLayer({attributes = {name = "Ground"}});
oInfinite.setTile(nInfinite, -2, -1, 0);
oInfinite.setTile(nInfinite, 0, 1, 0);
assert(oInfinite.getTile(nInfinite, -2, -1).gid == 0 and oInfinite.getTile(nInfinite, -1, -1) == nil);
local tInfinite = oInfinite.toAStar("infinite");
assert(tInfinite.bounds.x == -2 and tInfinite.bounds.y == -1 and tInfinite.bounds.width == 3 and tInfinite.bounds.height == 3);
assert(tInfinite.map.getNode("Ground", -2, -1).isPassable());
assert(not tInfinite.map.getNode("Ground", -1, -1).isPassable());
assert(oInfinite.toAStar("bounded", nil, {bounds = {x = -2, y = -1, width = 1, height = 1}}).bounds.width == 1);
local nGroup = oInfinite.addLayer({kind = "group", attributes = {name = "New group"}});
local nChild = oInfinite.addLayer({kind = "objectgroup", attributes = {name = "Child"}}, nGroup);
local nObject = oInfinite.addObject(nChild, {attributes = {x = 1, y = 2}});
oInfinite.setProperty("test", false, "bool", nil, nil, nObject);
assert(oInfinite.getProperties(nil, nObject).test.value == false);
oInfinite.removeObject(nObject);
assert(oInfinite.getObject(nObject) == nil);
oInfinite.removeLayer(nGroup);
assert(oInfinite.getLayer(nGroup) == nil and oInfinite.getLayer(nChild) == nil);

-- Payload decoding and delegated compression become self-contained CSV snapshots.
local sPrefix = '<map orientation="orthogonal" width="1" height="1" tilewidth="32" tileheight="32"><layer id="1" name="Ground" width="1" height="1">';
local sSuffix = '</layer></map>';
assert(Tiled().parse(sPrefix..'<data><tile gid="0"/></data>'..sSuffix).getTile(1, 0, 0).gid == 0);
assert(Tiled().parse(sPrefix..'<data encoding="base64">AAAAAA==</data>'..sSuffix).getTile(1, 0, 0).gid == 0);
for _, sFormat in ipairs({"zlib", "gzip", "zstd"}) do
    local sCompressed = sPrefix..'<data encoding="base64" compression="'..sFormat..'">eA==</data>'..sSuffix;
    fails(function() Tiled().parse(sCompressed); end);
    local nDecoded = 0;
    local oDecoded = Tiled().parse(sCompressed, nil, nil, function(sBytes, sCompression, nExpected)
        assert(sBytes == "x" and sCompression == sFormat and nExpected == 4);
        nDecoded = nDecoded + 1;
        return string.char(0, 0, 0, 0);
    end);
    assert(nDecoded == 1 and oDecoded.getXML():find('encoding="csv"', 1, true));
    assert(clone(oDecoded).getTile(1, 0, 0).gid == 0);
    assert(deserialize(serialize(oDecoded)).getTile(1, 0, 0).gid == 0);
end
fails(function() Tiled().parse(sPrefix..'<data encoding="csv">0,0</data>'..sSuffix); end);
fails(function() Tiled().parse(sPrefix..'<data encoding="csv">0,,</data>'..sSuffix); end);
fails(function() Tiled().parse(sPrefix..'<data encoding="csv">4294967296</data>'..sSuffix); end);
fails(function() Tiled().parse(sPrefix..'<data encoding="base64">AA=A</data>'..sSuffix); end);
local oSparse = Tiled().create();
oSparse.addTileset('<tileset name="Sparse" tilecount="1" columns="0"><tile id="9"><image source="gem.png"/></tile></tileset>');
assert(oSparse.resolveGID(10).localID == 9);
fails(function() oSparse.resolveGID(1); end);
local oTemplateOnly = Tiled().parse('<map orientation="orthogonal" width="1" height="1" tilewidth="32" tileheight="32"><objectgroup id="1"><object id="1" template="../templates/dragon.tx"/></objectgroup></map>', "maps/only.tmx", readResource);
assert(oTemplateOnly.getTilesets()[1].images[1].source == "assets/terrain.png");
assert(oTemplateOnly.getObject(1).attributes.gid == 2147483650);
assert(deserialize(serialize(oTemplateOnly)).getTilesets()[1].images[1].source == "assets/terrain.png");

-- Tile-definition edits embed external TSX locally and preserve its resource paths.
local oLocalized = clone(oTiled);
oLocalized.setTileProperty(10, "AStar", {aspects = {mud = 0.25}}, "class");
assert(oLocalized.resolveGID(10).definition.properties.AStar.value.aspects.value.mud.value == 0.25);
assert(oLocalized.getTilesets()[1].images[1].source == "assets/terrain.png");
assert(not oLocalized.getXML():find('source="../tiles/basic.tsx"', 1, true));
assert(oTiled.resolveGID(10).definition == nil);
oLocalized.setTileProperty(10, "AStar", nil);
assert(oLocalized.resolveGID(10).definition.properties.AStar == nil);
oLocalized.setTileProperty(10, "AStar", {aspects = {MUD = 0.5}}, "class");
assert(oLocalized.toAStar("case-insensitive").map.getNode("Ground", 2, 1).getAspectImpact("mud") == 0.5);
oLocalized.setAttribute("name", "Updated", nil, 7);
oLocalized.setAttribute("visible", false, 2);
assert(oLocalized.getObject(7).attributes.name == "Updated" and not oLocalized.getLayer(2).visible);
local oRebasedTiles = Tiled().create();
oRebasedTiles.addTileset(tFiles["tiles/basic.tsx"], nil, "tiles/basic.tsx");
assert(oRebasedTiles.getTilesets()[1].images[1].source == "assets/terrain.png");
assert(oCreated.getXML():find("<tileset", 1, true) < oCreated.getXML():find("<layer", 1, true));
assert(oTemplateOnly.getXML():find("<tileset", 1, true) < oTemplateOnly.getXML():find("<objectgroup", 1, true));

-- Odd pixel dimensions match Tiled's integer footprint rather than accumulating halves.
local oOddHex = Tiled().create({orientation = "hexagonal", tilewidth = 65, tileheight = 49, staggeraxis = "x", hexsidelength = 16});
local nOddX, nOddY = oOddHex.tileToPixel(2, 1);
assert(nOddX == 112 and nOddY == 72);
assert(Reader.path("C:/maps/world.tmx", "../tiles/basic.tsx") == "C:/tiles/basic.tsx");
assert(Reader.relative("C:/output/world.tmx", "C:/tiles/basic.tsx") == "../tiles/basic.tsx");
assert(Reader.path("https://example.com/maps/world.tmx", "../tiles/basic.tsx") == "https://example.com/tiles/basic.tsx");
fails(function() Tiled().parse(sPrefix..'<data encoding="csv">0 0</data>'..sSuffix); end);

-- Bad AStar settings fail before registering a map in a supplied system.
local oBadNavigation = Tiled().create();
oBadNavigation.addLayer({attributes = {name = "Ground"}});
oBadNavigation.setProperty("AStar", {passable = "invalid"}, "class");
local oCleanSystem = AStar();
fails(function() oBadNavigation.toAStar("bad", oCleanSystem); end);
assert(oCleanSystem.getMap("bad") == nil);
local tCyclicTemplateFiles = {
    ["a.tx"] = '<template><object template="b.tx"/></template>',
    ["b.tx"] = '<template><object template="a.tx"/></template>',
};
fails(function()
    Tiled().parse('<map orientation="orthogonal" width="1" height="1" tilewidth="32" tileheight="32"><objectgroup id="1"><object id="1" template="a.tx"/></objectgroup></map>', "", function(sPath)
        return assert(tCyclicTemplateFiles[sPath]);
    end);
end);

-- Native file output/load is also exercised in the virtual filesystem.
oCreated.save("/tiled-created.tmx");
assert(Tiled("/tiled-created.tmx").getObject(nActor).attributes.name == "Scout");

print("PASS Tiled: editing, TSX/templates, typed properties, all orientations, chunks, snapshots, compression delegation, native AStar terrain/rovers/ports/path movement");
