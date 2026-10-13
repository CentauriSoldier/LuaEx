-- Locate the repository from this example (native Lua and browser virtual files).
local sExampleSource = debug.getinfo(1, "S").source:gsub("^@", "")
local sSourcePath = sExampleSource:match("^(.*)[/\\]") or "."
local sRepositoryPath = sSourcePath
for _ = 1, 8 do
    local file = io.open(sRepositoryPath .. "/LuaEx/init.lua", "r")
    if file then file:close(); break end
    sRepositoryPath = sRepositoryPath .. "/.."
end
package.path = sRepositoryPath .. "/?.lua;" .. package.path
if not LUAEX_INIT then require("LuaEx.init") end
local D=require("examples.support.tutorial").new("AStar", "Detailed scenarios, boundary behavior, numeric settings, callbacks and persistence.")
local nativeAssert=assert
local function assert(condition,message) D.check(message or "Scenario invariant",condition);return nativeAssert(condition,message) end

--[[NOTE:
    This example uses ASCII cells instead of a graphical UI. A real game can
    use the same node list and cycle numbers to draw colored route segments:
    0 = this turn (green), 1 = next turn (red), 2 = the following turn (yellow).

    Constructing a Path only plans. Calling step moves the entire group one
    node. The caller cycles each rover when the next turn begins.
]]

--==============================================================================
D.section("Map and Terrain", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oAStar = AStar("Rock", "Sand", "Marsh");
local oGroundConfig = AStar.LayerConfig("Ground", "Rock", "Sand", "Marsh");
local oMap = oAStar.newMap("Nirn", AStar.MAP_TYPE_SQUARE, {oGroundConfig}, 7, 5);
local oGround = oMap.getLayer("ground");
local oStart = oGround.getNode(1, 1);
local oGoal = oGround.getNode(7, 5);
local tTerrain = {};

--All configured aspects start at intensity 1. Clear them for ordinary ground.
for nY = 1, oMap.getHeight() do
    for nX = 1, oMap.getWidth() do
        local oNode = oGround.getNode(nX, nY);
        tTerrain[oNode] = ".";

        for _, oAspect in ipairs(oNode.getAspects()) do
            local oImpactor = oAspect.getImpactor();
            oImpactor.setValue(0);
        end
    end
end

--A wall has an opening at the bottom. Rock is passable generally, but a rover
--that abhors Rock cannot enter it. Marsh changes each rover's individual fee.
for nY = 1, 4 do
    local oWall = oGround.getNode(4, nY);
    oWall.setPassable(false);
    tTerrain[oWall] = "#";
end

local oRock = oGround.getNode(2, 2);
local oRockAspect = oRock.getAspect("rock");
local oRockImpactor = oRockAspect.getImpactor();
oRockImpactor.setValue(1);
tTerrain[oRock] = "R";

for nX = 3, 5 do
    local oMarsh = oGround.getNode(nX, 5);
    local oAspect = oMarsh.getAspect("marsh");
    local oImpactor = oAspect.getImpactor();
    oImpactor.setValue(1);
    tTerrain[oMarsh] = "M";
end

--==============================================================================
D.section("Rovers", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oSoldier = oStart.createRover();
local oScout = oStart.createRover(false); --discard leftovers when the next cycle begins
local tGroup = {oSoldier, oScout};
oSoldier.addType("human");
oScout.addType("human");
oSoldier.setAbhors("rock", true);

local oAversion = oSoldier.getAversion("marsh");
local oAffinity = oScout.getAffinity("marsh");
oAversion.setValue(0.5); --Marsh costs this unit 15
oAffinity.setValue(0.5); --Marsh costs this unit 5

for _, oRover in ipairs(tGroup) do
    local oPoints = oRover.getMovePointPool();
    oPoints.set(30, Pool.ASPECT.MAX);
    oPoints.set(20, Pool.ASPECT.CYCLE_FLAT);
    oPoints.set(25);
end
assert(not oRock.isPassable(tGroup)); --one member's restriction blocks the group

local function printBudgets()
    print("Movement points: soldier="..oSoldier.getMovePoints()..", scout="..oScout.getMovePoints());
end

--==============================================================================
D.section("ASCII Rendering", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local tVisited = {};
local function printMap(oPath)
    local tRoute = {};

    if (oPath ~= nil) then
        for nIndex, oNode in ipairs(oPath.getNodes()) do
            local nCycle = oPath.getCycleForNode(nIndex);
            tRoute[oNode] = nCycle ~= nil and tostring(nCycle) or "!";
        end
    end

    print("     1   2   3   4   5   6   7");

    for nY = 1, oMap.getHeight() do
        local sRow = string.format("%2d  ", nY);

        for nX = 1, oMap.getWidth() do
            local oNode = oGround.getNode(nX, nY);
            local sCell = tTerrain[oNode];

            if (tVisited[oNode]) then sCell = "v"; end
            if (tRoute[oNode] ~= nil) then sCell = tRoute[oNode]; end
            if (tVisited[oNode]) then sCell = "v"; end
            if (oNode == oGoal) then sCell = "G"; end
            if (oNode == oStart and not tVisited[oNode]) then sCell = "S"; end
            if (oNode.containsRover(oSoldier)) then sCell = "U"; end

            sRow = sRow..string.format("[%2s]", sCell);
        end

        print(sRow);
    end

    print("U=group, S=start, G=goal, #=wall, R=rock, M=marsh, .=ground, v=visited");
    print("Route numbers=cycles from now; !=no predicted arrival with current settings");
    printBudgets();
end

print("Terrain before planning:");
printMap();

--==============================================================================
D.section("Plan Without Moving", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oPath = AStar.Path(oStart, oGoal, tGroup);
assert(oPath.hasPath() and oSoldier.getOwner() == oStart and oScout.getOwner() == oStart);
assert(oSoldier.getMovePoints() == 25 and oScout.getMovePoints() == 25);
print("\nPlanned route, including future turns:");
printMap(oPath);
print("Route nodes, including start: "..oPath.getNodeCount());
print("Soldier planned cost: "..oPath.getCost(oSoldier));
print("Scout planned cost: "..oPath.getCost(oScout));
print("Comparison cost (largest individual total): "..oPath.getCostTotal());
print("Future cycles to destination: "..oPath.getCycleCount());

--Callbacks observe both units after the group step and all payments commit.
oSoldier.setOnMoveCallback(function(oRover, oSource, oDestination)
    assert(oSoldier.getOwner() == oDestination and oScout.getOwner() == oDestination);
    local tPosition = oDestination.getPos();
    print("Group entered ("..tPosition.x..", "..tPosition.y..")");
end);
oPath.setOnStepCallback(function(oCurrentPath, tRovers, nIndex, nSteps, oCurrent, oPrevious)
    tVisited[oPrevious] = true;
    printBudgets();
end);

--==============================================================================
D.section("Execute and Cycle", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local nTurn = 0;

while (oPath.getNextNode() ~= nil) do
    if (not oPath.step()) then
        --A failed step moves and charges nobody. This example only changes
        --budgets between steps; a real game may need to replan changed terrain.
        nTurn = nTurn + 1;
        assert(nTurn <= 20, "Unexpected stalled route in this example.");
        print("\nBeginning turn "..nTurn..":");

        for _, oRover in ipairs(tGroup) do
            oRover.cycle();
        end

        oPath.refreshPreview(); --new cycle numbers are relative to the current turn
        printMap(oPath);
    end
end

assert(oSoldier.getOwner() == oGoal and oScout.getOwner() == oGoal);
print("\nArrived after "..nTurn.." future turns:");
printMap(oPath);
assert(not oPath.step()); --completed paths do not move or fire callbacks

--==============================================================================
D.section("Port Passage Rules", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oEntranceMap = oAStar.newMap("entrance", AStar.MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 1, 1);
local oCaveMap = oAStar.newMap("cave", AStar.MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 1, 1);
local oEntrance = oEntranceMap.getNode("ground", 1, 1);
local oCave = oCaveMap.getNode("ground", 1, 1);
oEntrance.addPort(oCave); --two-way by default; false would add only the outgoing direction
oEntrance.setPortPassageRule(oCave, function(oRover, oSource, oDestination)
    return oRover.isType("goblin");
end, true); --apply this rule in both directions

local oHuman = oEntrance.createRover();
local oGoblin = oEntrance.createRover();
oHuman.addType("human");
oGoblin.addType("goblin");
assert(oEntrance.isPassable(oHuman) and oCave.isPassable(oHuman));
assert(not oEntrance.canUsePort(oCave, oHuman));
assert(oEntrance.canUsePort(oCave, oGoblin));
assert(not oEntrance.canUsePort(oCave, {oHuman, oGoblin}));
assert(oEntrance.hasTwoWayPort(oCave));
print("\nCave: [entrance] <--- goblins only ---> [cave]");
print("Humans can occupy either node, but cannot use the cave port.");
assert(not AStar.Path(oEntrance, oCave, oHuman).hasPath());

local oCavePath = AStar.Path(oEntrance, oCave, oGoblin);
local oGoblinPoints = oGoblin.getMovePointPool();
oGoblinPoints.set(10, Pool.ASPECT.MAX);
oGoblinPoints.setFull();
assert(oCavePath.step() and oGoblin.getOwner() == oCave);
--Deferred payment still checks passage; teleportation bypasses the connection
--and its rule, while enforcing destination passability and layer permissions.
assert(not oHuman.move(oCave, true));
assert(oHuman.move(oCave, true, true));
oHuman.setLayerAllowed("ground", false);
assert(not oHuman.move(oEntrance, true, true));
oHuman.setLayerAllowed("ground", true);

--==============================================================================
D.section("Other Geometries", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local tGeometries = {
    {"hex flat", AStar.MAP_TYPE_HEX_FLAT, 6, {staggerAxis = "x", staggerIndex = "odd"}},
    {"hex pointed", AStar.MAP_TYPE_HEX_POINTED, 6, {staggerAxis = "y", staggerIndex = "even"}},
    {"square", AStar.MAP_TYPE_SQUARE, 4},
    {"triangle flat", AStar.MAP_TYPE_TRIANGLE_FLAT, 3},
    {"triangle pointed", AStar.MAP_TYPE_TRIANGLE_POINTED, 3},
};

for _, tGeometry in ipairs(tGeometries) do
    local oGeometryMap = oAStar.newMap(tGeometry[1], tGeometry[2], {AStar.LayerConfig("ground")}, 3, 3, tGeometry[4]);
    local oCenter = oGeometryMap.getNode("ground", 2, 2);
    local tNeighbors = oCenter.getNeighbors(true); --physical neighbors only
    assert(#tNeighbors == tGeometry[3]);
    print(tGeometry[1]..": "..#tNeighbors.." edge-sharing neighbors");
end

--For imported maps, supply originX/originY to preserve native coordinates,
--and map Tiled's staggeraxis/staggerindex into staggerAxis/staggerIndex.
--AStar supplies geometry and movement; loading the map file and drawing it
--remain responsibilities of the caller.
print("AStar example complete.");


D.section("Your square map", "A plain route costs ten points per move; planning does not move the rover.")
local w=D.input("width",5);local h=D.input("height",4)
local custom=AStar().newMap("custom",AStar.MAP_TYPE_SQUARE,{AStar.LayerConfig("ground")},w,h)
local first=custom.getNode("ground",1,1);local last=custom.getNode("ground",w,h)
local unit=first.createRover();unit.getMovePointPool().set(2000,Pool.ASPECT.MAX);unit.getMovePointPool().setFull()
local planned=AStar.Path(first,last,unit)
D.check("Custom route exists",planned.hasPath());D.check("Planning leaves owner at start",unit.getOwner()==first)
D.show("Nodes",planned.getNodeCount());D.show("Cost",planned.getCost(unit))
local limit=w*h+1;local steps=0
while planned.getNextNode() do assert(planned.step());steps=steps+1;assert(steps<=limit) end
D.check("Custom rover arrived",unit.getOwner()==last)

D.finish()
