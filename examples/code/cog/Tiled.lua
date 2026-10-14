-- Independent code tutorial. Run it from Examples.html or a native LuaEx runtime.
-- Find the repository so the same sample maps work in both environments.
local sExampleSource = debug.getinfo(1, "S").source:gsub("^@", "");
local sRepositoryPath = sExampleSource:match("^(.*)[/\\]") or ".";

for nAttempt = 1, 8 do
    local hFile = io.open(sRepositoryPath.."/LuaEx/init.lua", "r");
    if (hFile ~= nil) then
        hFile:close();
        break;
    end
    sRepositoryPath = sRepositoryPath.."/..";
end

package.path = sRepositoryPath.."/?.lua;"..package.path;
if (not LUAEX_INIT) then
    require("LuaEx.init");
end

local D = require("examples.support.tutorial").new("Tiled maps", "Real TMX maps, terrain properties, native rover responses and AStar routes.");
local tSamples = {"square", "hex-flat", "hex-pointy"}; -- Edit this list to select maps.

for _, sSample in ipairs(tSamples) do
    D.section(sSample, "Load the map and its external TSX. The map's objects contain the scout and destination settings.");
    local sPath = sRepositoryPath.."/examples/resources/tiled/"..sSample..".tmx";
    local oTiled = Tiled(sPath);
    local tMap = oTiled.getMap();
    D.show("Orientation", tMap.attributes.orientation);
    if (tMap.attributes.orientation == "hexagonal") then
        D.show("Stagger axis", tMap.attributes.staggeraxis);
        D.show("Stagger index", tMap.attributes.staggerindex);
    end

    -- Import the typed AStar properties into native nodes and the object-defined rover.
    local tNavigation = oTiled.toAStar(sSample);
    local oRover = tNavigation.rovers[1];
    local oStart = tNavigation.objectNodes[1];
    local oDestination = tNavigation.objectNodes[2];
    local oMud = tNavigation.map.getNode("Ground", 1, 2);
    D.equal("Imported mud intensity", oMud.getAspectImpact("mud"), 0.75);
    D.equal("Imported scout affinity", oRover.getAffinity("mud").getValue(), 0.5);
    D.equal("Imported scout aversion", oRover.getAversion("mud").getValue(), 1);
    D.equal("Mud entry cost for this scout", oMud.getEntryCost(oRover), 13.75);
    D.check("Wall blocks entry", not tNavigation.map.getNode("Ground", 3, 2).isPassable(oRover));

    D.section("Cell coordinates", "Cell-to-pixel queries use the same center anchor for square and both hex grids.");
    local nPixelX, nPixelY = oTiled.tileToPixel(1, 2, "Ground");
    local nColumn, nRow = oTiled.pixelToTile(nPixelX, nPixelY, "Ground");
    D.check("Cell center converts back to the same tile", nColumn == 1 and nRow == 2);

    D.section("Native AStar route", "Plan and execute a route with the imported rover and its movement-point pool.");
    local oPath = AStar.Path(oStart, oDestination, oRover);
    D.check("A route around the wall exists", oPath.hasPath());
    D.show("Route cost", oPath.getCost(oRover));
    D.show("Route node count", oPath.getNodeCount());
    local tRoute = {};
    for _, oNode in ipairs(oPath.getNodes()) do
        tRoute[oNode.getX()..":"..oNode.getY()] = true;
    end

    print("Logical grid: . grass, m mud, # wall, * route, S scout, E destination");
    for nY = 0, tMap.attributes.height - 1 do
        local tRow = {};
        for nX = 0, tMap.attributes.width - 1 do
            local nGID = oTiled.getTile("Ground", nX, nY).gid;
            local sCell = ({[1] = ".", [2] = "m", [3] = "#"})[nGID];
            if (tRoute[nX..":"..nY]) then
                sCell = "*";
            end
            if (nX == 0 and nY == 2) then
                sCell = "S";
            elseif (nX == 6 and nY == 2) then
                sCell = "E";
            end
            tRow[#tRow + 1] = sCell;
        end
        print(table.concat(tRow, " "));
    end

    -- Execute the planned route using the imported movement-point pool.
    for nStep = 1, oPath.getNodeCount() - 1 do
        D.check("Execute route step "..nStep, oPath.step());
    end
    D.check("Scout reaches the destination", oRover.getOwner() == oDestination);

    D.section("Edit the map", "Change an independent copy and import its new terrain into AStar.");
    local oEdited = clone(oTiled);
    oEdited.setTile("Ground", 3, 2, 1);
    D.equal("Original wall remains intact", oTiled.getTile("Ground", 3, 2).gid, 3);
    D.check("Edited wall becomes passable", oEdited.toAStar(sSample.."_edited").map.getNode("Ground", 3, 2).isPassable());
end

D.section("Create a map in Lua", "The same class can create and edit a map without reading a TMX file.");
local oCreated = Tiled().create({orientation = "hexagonal", width = 3, height = 3, staggeraxis = "y", staggerindex = "odd"});
local nGround = oCreated.addLayer({attributes = {name = "Ground"}});
oCreated.setProperty("AStar", {passable = true}, "class", nil, nGround);
local tCreated = oCreated.toAStar("created");
D.equal("Interior hex has six neighbors", #tCreated.map.getNode("Ground", 1, 1).getNeighbors(true), 6);
D.note("Open examples/resources/tiled/*.tmx in Tiled to inspect the sample maps and their terrain images.");
D.finish();
