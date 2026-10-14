-- Tiled owns terrain data; native AStar owns routes, costs, movement and cave rules.
-- The webpage receives plain display data and sends actions back to this example.
local oTiled;
local tNavigation;
local oRover;
local oPath;
local sMap = "square";
local sCreature = "SCOUT";
local sTool = "goal";
local nAffinity = 0.5;
local nAversion = 1;
local nMoves = 0;
local nTurn = 0;
local sMessage = "Choose a creature, step its route, or edit the map.";


--[[!
    @fqxn Examples.Tiled.plan
    @desc Replans from the current native rover node without spending movement points.
!]]
local function plan()

    oPath = AStar.Path(oRover.getOwner(), tNavigation.objectNodes[2], oRover);
end


--[[!
    @fqxn Examples.Tiled.rebuild
    @desc Imports the edited map, installs a native goblin-only cave passage rule and
    applies the selected rover responses. Editing/rebuilding returns the rover to spawn.
!]]
local function rebuild()

    -- Keep the selected creature settings in the map, so TMX export retains them.
    oTiled.setProperty("AStar", {
        layer = "Ground", tileX = 0, tileY = 2, rover = true, types = {sCreature},
        affinities = {mud = nAffinity}, aversions = {mud = nAversion},
        movePoints = {max = 200, current = 40, cycleFlat = 40},
    }, "class", nil, nil, 1);
    tNavigation = oTiled.toAStar("visual");
    oRover = tNavigation.rovers[1];
    oRover.getAffinity("mud").setValue(nAffinity);
    oRover.getAversion("mud").setValue(nAversion);
    local oEntrance = tNavigation.objectNodes[3];
    local oExit = tNavigation.objectNodes[4];
    oEntrance.setPortPassageRule(oExit, function(oVisitor)
        return oVisitor.isType("GOBLIN");
    end, true);
    nMoves = 0;
    nTurn = 0;
    plan();
end


--[[!
    @fqxn Examples.Tiled.loadMap
    @desc Loads a real TMX/TSX sample and adds cave objects with typed AStar settings.
!]]
local function loadMap(sName)

    assert(sName == "square" or sName == "hex-flat" or sName == "hex-pointy", "Unknown sample map.");
    sMap = sName;
    oTiled = Tiled("/examples/resources/tiled/"..sName..".tmx");
    local nEntranceX, nEntranceY = oTiled.tileToPixel(1, 1);
    local nExitX, nExitY = oTiled.tileToPixel(5, 3);
    local nEntrance = oTiled.addObject("Actors", {attributes = {name = "Cave entrance", x = nEntranceX, y = nEntranceY},
        properties = {AStar = {layer = "Ground", tileX = 1, tileY = 1}}});
    local nExit = oTiled.addObject("Actors", {attributes = {name = "Cave exit", x = nExitX, y = nExitY},
        properties = {AStar = {layer = "Ground", tileX = 5, tileY = 3}}});
    assert(nEntrance == 3 and nExit == 4);
    oTiled.setProperty("AStar", {layer = "Ground", tileX = 1, tileY = 1, ports = {nExit}}, "class", nil, nil, nEntrance);
    rebuild();
end


--[[!
    @fqxn Examples.Tiled.view
    @desc Publishes projected cell centers and native route/rover costs for presentation.
!]]
local function view()

    local tMap = oTiled.getMap().attributes;
    local oPosition = oRover.getOwner();
    local tState = {
        visual = "tiled", sample = sMap, creature = sCreature, tool = sTool,
        orientation = tMap.orientation, axis = tMap.staggeraxis or "", side = tMap.hexsidelength,
        width = tMap.width, height = tMap.height, tilewidth = tMap.tilewidth, tileheight = tMap.tileheight,
        affinity = nAffinity, aversion = nAversion, points = oRover.getMovePoints(),
        moves = nMoves, turn = nTurn, message = sMessage, cells = {}, route = {}, caves = {},
        hasPath = oPath.hasPath(), complete = oPath.getNextNode() == nil,
        cost = oPath.hasPath() and oPath.getCost(oRover) or 0,
        rover = {x = oPosition.getX(), y = oPosition.getY()},
    };

    for nY = 0, tMap.height - 1 do
        for nX = 0, tMap.width - 1 do
            local nPX, nPY = oTiled.tileToPixel(nX, nY, "Ground");
            local oNode = tNavigation.map.getNode("Ground", nX, nY);
            tState.cells[#tState.cells + 1] = {
                x = nX, y = nY, px = nPX, py = nPY,
                gid = oTiled.getTile("Ground", nX, nY).gid,
                passable = oNode.isPassable(oRover), cost = oNode.getEntryCost(oRover),
            };
        end
    end
    for _, oNode in ipairs(oPath.getNodes()) do
        local nPX, nPY = oTiled.tileToPixel(oNode.getX(), oNode.getY(), "Ground");
        tState.route[#tState.route + 1] = {x = oNode.getX(), y = oNode.getY(), px = nPX, py = nPY};
    end
    for _, nID in ipairs({3, 4}) do
        local oNode = tNavigation.objectNodes[nID];
        tState.caves[#tState.caves + 1] = {x = oNode.getX(), y = oNode.getY()};
    end
    local oGoal = tNavigation.objectNodes[2];
    tState.goal = {x = oGoal.getX(), y = oGoal.getY()};
    tState.cavesAllowed = tNavigation.objectNodes[3].canUsePort(tNavigation.objectNodes[4], oRover);
    return tState;
end


--[[!
    @fqxn Examples.Tiled.workbench_action
    @desc Handles presentation requests through real Tiled and AStar APIs.
!]]
function workbench_action(sAction, tPayload)

    if (sAction == "map") then
        loadMap(tPayload.sample);
        sMessage = "Loaded "..sMap.." from TMX and TSX.";
    elseif (sAction == "creature") then
        assert(tPayload.creature == "SCOUT" or tPayload.creature == "GOBLIN", "Unknown creature.");
        sCreature = tPayload.creature;
        rebuild();
        sMessage = sCreature == "GOBLIN" and "Goblin may use the paired caves." or "Scout must walk around the wall.";
    elseif (sAction == "responses") then
        assert(tPayload.affinity >= 0 and tPayload.affinity <= 1 and tPayload.aversion >= 0 and tPayload.aversion <= 1, "Responses must be between 0 and 1.");
        nAffinity = tPayload.affinity;
        nAversion = tPayload.aversion;
        oRover.getAffinity("mud").setValue(nAffinity);
        oRover.getAversion("mud").setValue(nAversion);
        plan();
        sMessage = "Replanned with the rover's updated mud responses.";
    elseif (sAction == "tool") then
        assert(tPayload.tool == "goal" or tPayload.tool == "grass" or tPayload.tool == "mud" or tPayload.tool == "wall", "Unknown map tool.");
        sTool = tPayload.tool;
    elseif (sAction == "cell") then
        local nX, nY = tPayload.x, tPayload.y;
        assert(oTiled.getTile("Ground", nX, nY), "Cell outside map.");
        if (sTool == "goal") then
            if (not tNavigation.map.getNode("Ground", nX, nY).isPassable(oRover)) then
                sMessage = "Choose a passable destination.";
                return view();
            end
            oTiled.setProperty("AStar", {layer = "Ground", tileX = nX, tileY = nY}, "class", nil, nil, 2);
            local nPX, nPY = oTiled.tileToPixel(nX, nY);
            oTiled.setAttribute("x", nPX, nil, 2);
            oTiled.setAttribute("y", nPY, nil, 2);
        else
            if ((nX == 0 and nY == 2) or (nX == 1 and nY == 1) or (nX == 5 and nY == 3)) then
                sMessage = "Keep the spawn and cave cells clear.";
                return view();
            end
            oTiled.setTile("Ground", nX, nY, ({grass = 1, mud = 2, wall = 3})[sTool]);
        end
        rebuild();
        sMessage = "Map edited and imported again; rover returned to spawn.";
    elseif (sAction == "step") then
        if (oPath.getNextNode() == nil) then
            sMessage = oPath.hasPath() and "Destination reached." or "No route exists.";
        elseif (oPath.step()) then
            nMoves = nMoves + 1;
            sMessage = oPath.getNextNode() == nil and "Destination reached." or "Moved through native AStar.";
        else
            sMessage = "Movement paused; advance the turn to replenish points.";
        end
    elseif (sAction == "turn") then
        oRover.cycle();
        nTurn = nTurn + 1;
        plan();
        sMessage = "Advanced rover cycle and replanned.";
    elseif (sAction == "reset") then
        loadMap(sMap);
        sMessage = "Restored the original sample map.";
    elseif (sAction == "save") then
        oTiled.setProperty("AStar", {
            layer = "Ground", tileX = oRover.getOwner().getX(), tileY = oRover.getOwner().getY(),
            rover = true, types = {sCreature}, affinities = {mud = nAffinity}, aversions = {mud = nAversion},
            movePoints = {max = 200, current = oRover.getMovePoints(), cycleFlat = 40},
        }, "class", nil, nil, 1);
        local nPX, nPY = oTiled.tileToPixel(oRover.getOwner().getX(), oRover.getOwner().getY());
        oTiled.setAttribute("x", nPX, nil, 1);
        oTiled.setAttribute("y", nPY, nil, 1);
        return {xml = oTiled.getXML(), name = sMap.."-edited.tmx"};
    elseif (sAction ~= "view") then
        error("Unknown Tiled action.");
    end
    return view();
end

local D = require("examples.support.tutorial").new("Visual Tiled maps", "Real TMX terrain and native AStar movement with scout/goblin cave permissions.");
D.section("Maps", "Switch between square, flat-top hex and pointy-top hex TMX samples.");
D.section("Creatures", "Scout and goblin are native AStar rovers with editable mud responses.");
D.section("Caves", "Paired object-defined ports use a native goblin-only passage predicate.");
D.section("Routes", "The displayed route and costs come from AStar.Path.");
D.section("Editing", "Click cells to edit Tiled terrain or change the destination, then rebuild navigation.");
D.section("Movement", "Step moves the rover; Next turn advances its movement Pool cycle.");
loadMap(sMap);
return view();
