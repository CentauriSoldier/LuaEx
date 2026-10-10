--[[!
    @fqxn CoG.AStar.AStar
    @desc <p>AStar is an versatile A* pathfinding system designed for detailed game development.
    It has weighted <a href="#LuaEx.CoG.AStar.AStarNode">Nodes</a> that respond to the
    <a href="#LuaEx.CoG.AStar.AStarRover">Rovers</a> moving through them. That is, a
    <b>Node's</b> weight is based not only on the <b>Node</b> properties but also on the
    <b>Rover's</b> affinities or aversions to that node.
    <br>For example, a human walking on solid, flat ground would move much faster than if he were
    walking on a muddy slope.
    <br><br>
    The system uses various private, public and publicly-available classes.
    <h4>Private Classes</h4>
    <ul>
        <li><a href="#LuaEx.CoG.AStar.AStarAspect">AStarAspect</a></li>
        <li><a href="#LuaEx.CoG.AStar.AStarLayer">AStarLayer</a></li>
        <li><a href="#LuaEx.CoG.AStar.AStarMap">AStarMap</a></li>
        <li><a href="#LuaEx.CoG.AStar.AStarNode">AStarNode</a></li>
        <li><a href="#LuaEx.CoG.AStar.AStarRover">AStarRover</a></li>
    </ul>
    <h4>Public Classes</h4>
    <ul>
        <li><a href="#LuaEx.CoG.AStar.AStar">AStar</a></li>
    </ul>
    <h4>Publicly-available Classes</h4>
    <ul>
        <li><a href="#LuaEx.CoG.AStar.AStarLayerConfig">AStarLayerConfig</a></li>
        <li><a href="#LuaEx.CoG.AStar.AStarPath">AStarPath</a></li>
    </ul>
    These two classes are available in <b>AStar's</b> static public table.
    <b>AStar.LayerConfig</b>
    <b>AStar.Path</b>
    <br>Create maps with newMap, configure rover Pools, construct AStar.Path for preview and call path.step to execute one group move.
    @ex
    local oAStar         = AStar("Rock", "Sand", "Marsh");
    local oASLayerConfig = AStar.LayerConfig("Rock", "Sand");
    local oMap           = oAStar.newMap("Nirn", ASTAR_MAP_TYPE_HEX_FLAT, {oASLayerConfig}, 40, 40, {staggerAxis = "x", staggerIndex = "odd"});
!]]


--[[
Alter these to fit your game.
]]
--[[enum("ASTAR",           {"MAP", "NODE", "PATH", "ROVER"});
enum("ASTAR_LAYER",     {"SUBTERRAIN", "SUBMARINE", "MARINE", "TERRAIN", "AIR", "SPACE"}, {
    enum("ASTAR_LAYER_SUBTERRAIN",  {"sd", "sd", "sd", "sd", "sd"}),
    enum("ASTAR_LAYER_SUBMARINE",   {"PRESSURE", "SALINITY", "sd", "sd", "sd"}),
    enum("ASTAR_LAYER_MARINE",      {"sd", "sd", "sd", "sd", "sd"}),
    enum("ASTAR_LAYER_TERRAIN",     {"AQUIFER", "COMPACTION", "DETRITUS", "FORAGEABILITY", "FORESTATION",
                                      "GRADE", "ICINESS", "PALUDALISM", "ROCKINESS", "ROAD", "SNOWINESS",
                                      "TEMPERATURE", "TOXICITY", "VERDURE"}),
    enum("ASTAR_LAYER_AIR",         {"sd", "sd", "sd", "sd", "sd"}),
    enum("ASTAR_LAYER_SPACE",       {"sd", "sd", "sd", "sd", "sd"}),
});
]]

--🅲🅾🅽🆂🆃🅰🅽🆃🆂 --also exposed as read-only AStar static values
constant("ASTAR_MAP_TYPE_HEX_FLAT",         0);
constant("ASTAR_MAP_TYPE_HEX_POINTED",      1);
constant("ASTAR_MAP_TYPE_SQUARE",           2);
constant("ASTAR_MAP_TYPE_TRIANGLE_FLAT",    3);
constant("ASTAR_MAP_TYPE_TRIANGLE_POINTED", 4);
constant("ASTAR_NODE_ENTRY_COST_BASE",      10); --the central cost upon which all other costs & cost mechanics are predicated
constant("ASTAR_NODE_ENTRY_COST_MIN",       1);
constant("ASTAR_NODE_ENTRY_COST_MAX_RATE",  12);
constant("ASTAR_NODE_ENTRY_COST_MAX",       ASTAR_NODE_ENTRY_COST_BASE * ASTAR_NODE_ENTRY_COST_MAX_RATE);

--🅻🅾🅲🅰🅻🅸🆉🅰🆃🅸🅾🅽
local ASTAR_MAP_TYPE_HEX_FLAT         = ASTAR_MAP_TYPE_HEX_FLAT;
local ASTAR_MAP_TYPE_HEX_POINTED      = ASTAR_MAP_TYPE_HEX_POINTED;
local ASTAR_MAP_TYPE_SQUARE           = ASTAR_MAP_TYPE_SQUARE;
local ASTAR_MAP_TYPE_TRIANGLE_FLAT    = ASTAR_MAP_TYPE_TRIANGLE_FLAT;
local ASTAR_MAP_TYPE_TRIANGLE_POINTED = ASTAR_MAP_TYPE_TRIANGLE_POINTED;
local ASTAR_NODE_ENTRY_COST_BASE      = ASTAR_NODE_ENTRY_COST_BASE;
local ASTAR_NODE_ENTRY_COST_MIN       = ASTAR_NODE_ENTRY_COST_MIN;
local ASTAR_NODE_ENTRY_COST_MAX_RATE  = ASTAR_NODE_ENTRY_COST_MAX_RATE;
local ASTAR_NODE_ENTRY_COST_MAX       = ASTAR_NODE_ENTRY_COST_MAX;

local assert       = assert;
local class        = class;
local math         = math;
local rawtype      = rawtype;
local setmetatable = setmetatable;
local table        = table;
local type         = type;
local Protean      = Protean;

--🅳🅴🅲🅻🅰🆁🅰🆃🅸🅾🅽🆂
local AStar;
local AStarMap;
local AStarLayer;
local AStarLayerConfig;
local AStarNode;
local AStarAspect;
local AStarPath;
local AStarRover;
local AStarUtil;
local _tNodeData  = setmetatable({}, {__mode = "k"});
local _tRoverData = setmetatable({}, {__mode = "k"});

local DEFAULT_ASPECT_IMPACTOR_BASE_VALUE = 1;


AStarUtil = {
    mapTypeIsValid = function(nType)
        return  rawtype(nType) == "number" and
            (   nType == ASTAR_MAP_TYPE_HEX_FLAT        or
                nType == ASTAR_MAP_TYPE_HEX_POINTED     or
                nType == ASTAR_MAP_TYPE_SQUARE          or
                nType == ASTAR_MAP_TYPE_TRIANGLE_FLAT      or
                nType == ASTAR_MAP_TYPE_TRIANGLE_POINTED
            );
    end,
    setupActualDecoy = function(tActual, tDecoy, sError, nLength)
        setmetatable(tDecoy, {
            __index = function(t, k)
                return tActual[k];
            end,
            __newindex = function(t, k, v)
                error(sError);
            end,
            __len = function()
                return nLength or #tActual;
            end,
            __pairs = function(t)
                return next, tActual, nil;
            end
        });
    end,
};



                --[[░█████╗░░██████╗██████╗░███████╗░█████╗░████████╗
                    ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗╚══██╔══╝
                    ███████║╚█████╗░██████╔╝█████╗░░██║░░╚═╝░░░██║░░░
                    ██╔══██║░╚═══██╗██╔═══╝░██╔══╝░░██║░░██╗░░░██║░░░
                    ██║░░██║██████╔╝██║░░░░░███████╗╚█████╔╝░░░██║░░░
                    ╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚══════╝░╚════╝░░░░╚═╝░░░]]
--[[!
@fqxn CoG.AStar.AStarAspect
@desc A named aspect belonging to a node. Its Protean impactor represents the aspect's intensity from 0 to 1 and automatically recalculates when its values change.
!]]
AStarAspect = class("AStarAspect",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarAspect = function(stapub) end,
},
{--PRIVATE
    --[[!
    @fqxn CoG.AStar.AStarAspect.getImpactor
    @pulsarlua function AStarAspect.getImpactor
    @desc Gets the aspect's impactor. Its final value is bounded from 0 to 1; the returned Protean can be modified.
    @ret Protean oImpactor The aspect's impactor.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oAspect = oNode.getAspect("mud");
    local oImpactor = oAspect.getImpactor();
    oImpactor.setValue(0.5);
    assert(oNode.getAspectImpact("mud") == 0.5);
    !]]
    Impactor__autoRF    = null,--a percentage referencing the extremity of the aspect (0%-100%)
    --[[!
    @fqxn CoG.AStar.AStarAspect.getName
    @pulsarlua function AStarAspect.getName
    @desc Gets the aspect's name.
    @ret string sName The name supplied to the constructor.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oAspect = oNode.getAspect("mud");
    assert(oAspect.getName() == "MUD");
    !]]
    Name__autoRF        = null,
    --[[!
    @fqxn CoG.AStar.AStarAspect.getOwner
    @pulsarlua function AStarAspect.getOwner
    @desc Gets the node that owns this aspect.
    @ret AStarNode oOwner The owning node.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oAspect = oNode.getAspect("mud");
    assert(oAspect.getOwner() == oNode);
    !]]
    Owner__autoRF       = null,
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.AStar.AStarAspect.AStarAspect
    @desc Creates an aspect with an automatically calculated impactor. The default intensity is 1 (100%), bounded from 0 to 1.
    @param string sName The aspect name; must contain a non-whitespace character.
    @param AStarNode oAStarNode The node that owns this aspect.
    @ret AStarAspect oAspect The new aspect.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oAspect = oNode.getAspect("mud");
    assert(type(oAspect) == "AStarAspect"); --created by the node from its layer configuration
    !]]
    AStarAspect = function(this, cdat, sName, oAStarNode)
        local pri = cdat.pri;

        type.assert.string(sName, "%S+");
        type.assert.custom(oAStarNode, "AStarNode");

        pri.Name     = sName;
        pri.Owner    = oAStarNode;
        pri.Impactor = Protean(DEFAULT_ASPECT_IMPACTOR_BASE_VALUE, 0, 0, 0, 0, 0, 0, 0, 1, nil, false);
    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);



                    --[[██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░
                        ██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗
                        ██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝
                        ██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗
                        ███████╗██║░░██║░░░██║░░░███████╗██║░░██║
                        ╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝]]
--[[!
@fqxn CoG.AStar.AStarLayer
@desc Owns one configured grid of nodes within a map.
!]]
AStarLayer = class("AStarLayer",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarLayer = function(stapub) end,
},
{--PRIVATE
    --[[!
    @fqxn CoG.AStar.AStarLayer.getID
    @pulsarlua function AStarLayer.getID
    @desc Gets this layer's ordered map-local ID.
    @ret number nID The layer ID.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    assert(oLayer.getID() == 1);
    !]]
    ID__autoRF    = null,
    --config    = oConfig,
    --[[!
    @fqxn CoG.AStar.AStarLayer.getOwner
    @pulsarlua function AStarLayer.getOwner
    @desc Gets the map that owns this layer.
    @ret AStarMap oMap The owning map.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    assert(oLayer.getOwner() == oMap);
    !]]
    Owner__autoRF = null,
    --[[!
    @fqxn CoG.AStar.AStarLayer.getName
    @pulsarlua function AStarLayer.getName
    @desc Gets the uppercase layer name.
    @ret string sName The layer name.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    assert(oLayer.getName() == "GROUND");
    !]]
    Name__autoRF  = null,
    nodes         = {},
    nodeColumns     = {},
    nodesDecoy    = {}, --a decoy table for returning to the client
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.AStar.AStarLayer.AStarLayer
    @desc Creates a layer and its node grid using the supplied configuration.
    @param AStarMap oAStarMap The owning map.
    @param number nLayerID The positive integer layer ID.
    @param AStarLayerConfig oConfig The layer configuration.
    @param number nWidth The positive integer grid width.
    @param number nHeight The positive integer grid height.
    @ret AStarLayer oLayer The new layer.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    assert(type(oLayer) == "AStarLayer"); --created with the map
    !]]
    AStarLayer = function(this, cdat, oAStarMap, nLayerID, oConfig, nWidth, nHeight)
        type.assert.custom(oAStarMap, "AStarMap");
        type.assert.custom(oConfig, "AStarLayerConfig");
        type.assert.number(nLayerID, true, true, false, true, false, 1, math.maxinteger);
        type.assert.number(nWidth, true, true, false, true, false, 1, math.maxinteger);
        type.assert.number(nHeight, true, true, false, true, false, 1, math.maxinteger);

        local pri    = cdat.pri;
        local tNodes = pri.nodes;

        pri.ID    = nLayerID;
        pri.Name  = oConfig.getName();
        pri.Owner = oAStarMap;

        AStarUtil.setupActualDecoy( pri.nodeColumns,
                                    pri.nodesDecoy,
                                    "Attempting to modify read-only nodes table for layer, '"..pri.Name.."'.", nWidth);

        --get the aspects that will be on the node
        local tAspects = oConfig.getAspects();

        --create the nodes
        local tOrigin = oAStarMap.getOrigin();

        for x = tOrigin.x, tOrigin.x + nWidth - 1 do
            tNodes[x] = {};
            pri.nodeColumns[x] = {};
            AStarUtil.setupActualDecoy(tNodes[x], pri.nodeColumns[x], "Attempt to modify read-only node column.", nHeight);

            for y = tOrigin.y, tOrigin.y + nHeight - 1 do
                tNodes[x][y] = AStarNode(this, x, y, tAspects);
            end

        end

    end,
    --[[!
    @fqxn CoG.AStar.AStarLayer.containsRoverAt
    @pulsarlua function AStarLayer.containsRoverAt
    @desc Checks whether a rover occupies the specified node. Returns false outside the grid.
    @param AStarRover oRover The rover to check.
    @param number nX The integer x coordinate.
    @param number nY The integer y coordinate.
    @ret boolean bContains Whether the rover occupies that node.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    local oRover = oLayer.createRoverAt(1, 1);
    assert(oLayer.containsRoverAt(oRover, 1, 1));
    !]]
    containsRoverAt = function(this, cdat, oRover, nX, nY)
        type.assert.number(nX, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.number(nY, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.custom(oRover, "AStarRover");
        local bRet   = false;
        local pri    = cdat.pri;
        local tNodes = pri.nodes;

        if (tNodes[nX] and tNodes[nX][nY]) then
            bRet = tNodes[nX][nY].containsRover(oRover);
        end

        return bRet;
    end,
    --[[!
    @fqxn CoG.AStar.AStarLayer.createRoverAt
    @pulsarlua function AStarLayer.createRoverAt
    @desc Creates a rover at the specified node. Returns nil outside the grid.
    @param number nX The integer x coordinate.
    @param number nY The integer y coordinate.
    @param boolean|nil bRetainsPointsOverCycle Whether unused points carry into the next cycle; defaults to true.
    @ret AStarRover|nil oRover The new rover, or nil when the node is absent.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    local oRover = oLayer.createRoverAt(1, 1, false);
    assert(not oRover.getRetainsPointsOverCycle());
    !]]
    createRoverAt = function(this, cdat, nX, nY, bRetainsPointsOverCycle)
        type.assert.number(nX, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.number(nY, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        local pri    = cdat.pri;
        local tNodes = pri.nodes;

        local oRover;

        if (bRetainsPointsOverCycle ~= nil) then
            type.assert.custom(bRetainsPointsOverCycle, "boolean");
        end

        if (tNodes[nX] and tNodes[nX][nY]) then
            local oNode = tNodes[nX][nY];
            oRover = oNode.createRover(bRetainsPointsOverCycle);
        end

        return oRover;
    end,


    --[[!
    @fqxn CoG.AStar.AStarLayer.getNode
    @pulsarlua function AStarLayer.getNode
    @desc Gets the node at the supplied coordinates.
    @param number nX The integer x coordinate.
    @param number nY The integer y coordinate.
    @ret AStarNode|nil oNode The node, or nil outside the grid.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    assert(oLayer.getNode(1, 1) ~= nil and oLayer.getNode(4, 1) == nil);
    !]]
    getNode = function(this, cdat, nX, nY)
        type.assert.number(nX, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.number(nY, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        local tNodes = cdat.pri.nodesDecoy[nX];

        local oNode;

        if (tNodes ~= nil) then
            oNode = tNodes[nY];
        end

        return oNode;
    end,

    --[[!
    @fqxn CoG.AStar.AStarLayer.getNodes
    @pulsarlua function AStarLayer.getNodes
    @desc Gets a read-only view of the node grid. Both the outer grid and its columns reject assignments. Nodes remain accessible through their methods.
    @ret table tNodes The grid indexed by x, then y.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    local tNodes = oLayer.getNodes();
    assert(tNodes[1][1] == oLayer.getNode(1, 1));
    !]]
    getNodes = function(this, cdat)
        return cdat.pri.nodesDecoy;
    end,


    --[[!
    @fqxn CoG.AStar.AStarLayer.hasNode
    @pulsarlua function AStarLayer.hasNode
    @desc Checks whether a node belongs to this layer.
    @param AStarNode oNode The node to check.
    @ret boolean bHasNode Whether this layer owns the node.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    assert(oLayer.hasNode(oLayer.getNode(1, 1)));
    !]]
    hasNode = function(this, cdat, oNode)
        type.assert.custom(oNode, "AStarNode");
        return oNode.getOwner() == this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarLayer.hasNodeAt
    @pulsarlua function AStarLayer.hasNodeAt
    @desc Checks whether a node exists at the supplied coordinates.
    @param number nX The integer x coordinate.
    @param number nY The integer y coordinate.
    @ret boolean bHasNode Whether the node exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oLayer = oMap.getLayer("ground");
    assert(oLayer.hasNodeAt(1, 1) and not oLayer.hasNodeAt(4, 1));
    !]]
    hasNodeAt = function(this, cdat, nX, nY)
        type.assert.number(nX, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.number(nY, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        local tNodes = cdat.pri.nodes;
        return tNodes[nX] ~= nil and tNodes[nX][nY] ~= nil;
    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);


--[[██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░░█████╗░███╗░░██╗███████╗██╗░██████╗░
    ██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██╔══██╗████╗░██║██╔════╝██║██╔════╝░
    ██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ██║░░╚═╝██║░░██║██╔██╗██║█████╗░░██║██║░░██╗░
    ██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██║░░██╗██║░░██║██║╚████║██╔══╝░░██║██║░░╚██╗
    ███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ╚█████╔╝╚█████╔╝██║░╚███║██║░░░░░██║╚██████╔╝
    ╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ░╚════╝░░╚════╝░╚═╝░░╚══╝╚═╝░░░░░╚═╝░╚═════╝░]]
--[[!
@fqxn CoG.AStar.AStarLayerConfig
@desc Defines a layer name and an ordered list of zero or more aspect names. Names are stored in uppercase.
!]]
local AStarLayerConfig = class("AStarLayerConfig",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarLayerConfig = function(stapub) end,
},
{--PRIVATE
    aspects         = {},
    aspectsByName   = {},
    aspectsDecoy    = {},
    --[[!
    @fqxn CoG.AStar.AStarLayerConfig.getName
    @pulsarlua function AStarLayerConfig.getName
    @desc Gets the uppercase layer name.
    @ret string sName The layer name.
    @ex
    local oConfig = AStar.LayerConfig("ground", "mud");
    assert(oConfig.getName() == "GROUND");
    !]]
    Name__autoRF    = null,
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.AStar.AStarLayerConfig.AStarLayerConfig
    @pulsarlua function AStar.LayerConfig
    @desc Creates a layer configuration. Aspect order is preserved, and duplicate names are rejected without regard to case. Zero aspects are allowed.
    @param string sName A layer name containing a non-whitespace character.
    @param string ... Aspect names, each containing a non-whitespace character.
    @ret AStarLayerConfig oConfig The new configuration.
    @ex
    local oConfig = AStar.LayerConfig("ground", "mud");
    assert(type(oConfig) == "AStarLayerConfig");
    !]]
    AStarLayerConfig = function(this, cdat, sName, ...)
        local tInputAspects = {...};

        type.assert.string(sName, "%S+");
        type.assert.table(tInputAspects, "number", "string");

        for nIndex = 1, select("#", ...) do
            type.assert.string(tInputAspects[nIndex], "%S+");
        end

        --The owning map validates configured aspects against its AStar system.

        local pri = cdat.pri;
        pri.Name  = sName:upper();

        --add all user aspects
        local tAspects = pri.aspects;
        for _, sAspect in ipairs(tInputAspects) do
            local sAspectName = sAspect:upper();
            assert(pri.aspectsByName[sAspectName] == nil, "Duplicate aspect name, '"..sAspectName.."'.");

            tAspects[#tAspects + 1] = sAspectName;
            pri.aspectsByName[sAspectName] = sAspectName;
        end

        AStarUtil.setupActualDecoy(pri.aspects, pri.aspectsDecoy, "Attempt to modify read-only LayerConfig Aspects table.");
    end,
    --[[!
    @fqxn CoG.AStar.AStarLayerConfig.getAspect
    @pulsarlua function AStarLayerConfig.getAspect
    @desc Gets a configured aspect name using a case-insensitive lookup.
    @param string sAspect The aspect name.
    @ret string|nil sName The uppercase name, or nil when absent.
    @ex
    local oConfig = AStar.LayerConfig("ground", "mud");
    assert(oConfig.getAspect("Mud") == "MUD");
    !]]
    getAspect = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        return cdat.pri.aspectsByName[sAspect:upper()] or nil;
    end,
    --[[!
    @fqxn CoG.AStar.AStarLayerConfig.getAspects
    @pulsarlua function AStarLayerConfig.getAspects
    @desc Gets a read-only view of the ordered aspect names.
    @ret table tAspects The ordered uppercase names.
    @ex
    local oConfig = AStar.LayerConfig("ground", "mud");
    assert(oConfig.getAspects()[1] == "MUD");
    !]]
    getAspects = function(this, cdat)
        return cdat.pri.aspectsDecoy;
    end,
    --[[!
    @fqxn CoG.AStar.AStarLayerConfig.hasAspect
    @pulsarlua function AStarLayerConfig.hasAspect
    @desc Checks whether an aspect is configured using a case-insensitive lookup.
    @param string sAspect The aspect name.
    @ret boolean bHasAspect Whether the aspect is configured.
    @ex
    local oConfig = AStar.LayerConfig("ground", "mud");
    assert(oConfig.hasAspect("mud") and not oConfig.hasAspect("snow"));
    !]]
    hasAspect = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        return cdat.pri.aspectsByName[sAspect:upper()] ~= nil;
    end
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);



                --[[███╗░░░███╗░█████╗░██████╗░
                    ████╗░████║██╔══██╗██╔══██╗
                    ██╔████╔██║███████║██████╔╝
                    ██║╚██╔╝██║██╔══██║██╔═══╝░
                    ██║░╚═╝░██║██║░░██║██║░░░░░
                    ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░░░░]]
--[[!
@fqxn CoG.AStar.AStarMap
@desc Owns an ordered collection of layers sharing a map type and grid dimensions.
!]]
AStarMap = class("AStarMap",
{--METAMETHODS
    --[[!
    @fqxn CoG.AStar.AStarMap.__tostring
    @desc Describes map name, dimensions, geometry, layer names and node count per layer.
    @ret string sDescription The map description.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(tostring(oMap):find("world", 1, true));
    !]]
    __tostring = function(this, cdat)
        local pri = cdat.pri;

        local sRet = pri.Name..' ('..pri.Width.." x "..pri.Height..')';
        sRet = sRet.."\nType: "..pri.Type;
        sRet = sRet.."\nLayers: ";

        for nLayerID, oLayer in pairs(pri.Layers) do
            sRet = sRet.."\n\t"..nLayerID.." ("..oLayer.getName()..'): ';
        end
        sRet = sRet.."\nNodes per layer: "..(pri.Width * pri.Height);

        return sRet;
    end,
},
{--STATIC PUBLIC
    --AStarMap = function(stapub) end,
},
{--PRIVATE
    --[[!
    @fqxn CoG.AStar.AStarMap.getLayers
    @pulsarlua function AStarMap.getLayers
    @desc Gets a read-only view of the layers in configuration order.
    @ret table tLayers The ordered layers.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(#oMap.getLayers() == 1);
    !]]
    Layers          = {},--(ORDERED BY ID)
    layersDecoy     = {},--a decoy table for returning layers to the client
    layersByName    = {},
    --[[!
    @fqxn CoG.AStar.AStarMap.getName
    @pulsarlua function AStarMap.getName
    @desc Gets the map name supplied at construction.
    @ret string sName The map name.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oMap.getName() == "world");
    !]]
    Name__autoRF    = null,
    --[[!
    @fqxn CoG.AStar.AStarMap.getOwner
    @pulsarlua function AStarMap.getOwner
    @desc Gets the AStar object that owns this map.
    @ret AStar oAStar The owning system.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oMap.getOwner() == oSystem);
    !]]
    Owner__autoRF   = null,
    --[[!
    @fqxn CoG.AStar.AStarMap.getType
    @pulsarlua function AStarMap.getType
    @desc Gets the declared map geometry type.
    @ret number nType The map type constant.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oMap.getType() == ASTAR_MAP_TYPE_SQUARE);
    !]]
    Type__autoRF    = null,
    --[[!
    @fqxn CoG.AStar.AStarMap.getWidth
    @pulsarlua function AStarMap.getWidth
    @desc Gets the grid width shared by the layers.
    @ret number nWidth The width.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oMap.getWidth() == 3);
    !]]
    Width__autoRF   = null,
    --[[!
    @fqxn CoG.AStar.AStarMap.getHeight
    @pulsarlua function AStarMap.getHeight
    @desc Gets the grid height shared by the layers.
    @ret number nHeight The height.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oMap.getHeight() == 2);
    !]]
    Height__autoRF  = null,
    originX         = 1,
    originY         = 1,
    staggerAxis     = null,
    staggerIndex    = null,
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.AStar.AStarMap.AStarMap
    @desc Creates a map and its layers. Requires an ordered, nonempty list of layer configurations with unique names. Every configured aspect must belong to the owning AStar.
    @param AStar oAStar The owning system.
    @param string sName A nonblank map name.
    @param number nMapType A declared map type constant.
    @param table tLayerConfigs The ordered layer configurations.
    @param number nWidth The positive integer grid width.
    @param number nHeight The positive integer grid height.
    @param table|nil tLayout Optional originX/originY (default 1) and paired staggerAxis/staggerIndex settings.
    @ret AStarMap oMap The new map.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(type(oMap) == "AStarMap"); --created with newMap
    !]]
    AStarMap = function(this, cdat, oAStar, sName, nMapType, tLayerConfigs, nWidth, nHeight, tLayout)
        local pri = cdat.pri;

        --check the input
        type.assert.custom(oAStar, "AStar");
        type.assert.string(sName, "%S+");
        type.assert.number(nMapType);
        assert(AStarUtil.mapTypeIsValid(nMapType), "Invalid AStarMap type.");
        type.assert.number(nWidth, true, true, false, true, false, 1, math.maxinteger);
        type.assert.number(nHeight, true, true, false, true, false, 1, math.maxinteger);
        type.assert.table(tLayerConfigs, "number", "AStarLayerConfig", 1);

        local nConfigs    = 0;
        local tLayerNames = {};

        for nLayerID, oConfig in pairs(tLayerConfigs) do
            type.assert.number(nLayerID, true, true, false, true, false, 1, #tLayerConfigs);
            local sLayerName = oConfig.getName();
            assert(tLayerNames[sLayerName] == nil, "Duplicate layer name, '"..sLayerName.."'.");
            tLayerNames[sLayerName] = true;
            nConfigs = nConfigs + 1;

            for _, sAspect in ipairs(oConfig.getAspects()) do
                assert(oAStar.aspectNames[sAspect] ~= nil, "Unknown AStar aspect, '"..sAspect.."'.");
            end

        end

        assert(nConfigs == #tLayerConfigs, "Layer configurations must be a contiguous ordered list.");

        if (tLayout ~= nil) then
            type.assert.table(tLayout, "string");

            for sKey in pairs(tLayout) do
                assert(sKey == "originX" or sKey == "originY" or sKey == "staggerAxis" or sKey == "staggerIndex", "Unknown map layout setting, '"..sKey.."'.");
            end

            if (tLayout.originX ~= nil) then
                type.assert.number(tLayout.originX, false, false, false, true, false, -math.maxinteger, math.maxinteger);
                pri.originX = tLayout.originX;
            end

            if (tLayout.originY ~= nil) then
                type.assert.number(tLayout.originY, false, false, false, true, false, -math.maxinteger, math.maxinteger);
                pri.originY = tLayout.originY;
            end

            if (tLayout.staggerAxis ~= nil or tLayout.staggerIndex ~= nil) then
                type.assert.string(tLayout.staggerAxis);
                type.assert.string(tLayout.staggerIndex);
                assert(tLayout.staggerAxis == "x" or tLayout.staggerAxis == "y", "Stagger axis must be x or y.");
                assert(tLayout.staggerIndex == "odd" or tLayout.staggerIndex == "even", "Stagger index must be odd or even.");
                pri.staggerAxis  = tLayout.staggerAxis;
                pri.staggerIndex = tLayout.staggerIndex;
            end

        end

        assert(pri.originX <= math.maxinteger - (nWidth - 1), "Map x bounds overflow.");
        assert(pri.originY <= math.maxinteger - (nHeight - 1), "Map y bounds overflow.");

        pri.Name   = sName;
        pri.Owner  = oAStar;
        pri.Type   = nMapType;
        pri.Width  = nWidth;
        pri.Height = nHeight;


        AStarUtil.setupActualDecoy( pri.Layers,
                                    pri.layersDecoy,
                                    "Attempting to modifer read-only layers table for map, '"..pri.Name.."'.");

        --create the layers and their nodes
        for nLayerID, oConfig in ipairs(tLayerConfigs) do
            --create the actual layer elements
            local oLayer = AStarLayer(this, nLayerID, oConfig, nWidth, nHeight);
            pri.Layers[nLayerID] = oLayer;
            pri.layersByName[oConfig.getName()] = oLayer;
        end

    end,
    getLayers = function(this, cdat)
        return cdat.pri.layersDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarMap.getLayer
    @pulsarlua function AStarMap.getLayer
    @desc Gets a layer using a case-insensitive name lookup.
    @param string sLayer A nonblank layer name.
    @ret AStarLayer|nil oLayer The layer, or nil when absent.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oMap.getLayer("GROUND") == oMap.getLayer("ground"));
    !]]
    getLayer = function(this, cdat, sLayer)
        type.assert.string(sLayer, "%S+");
        return cdat.pri.layersByName[sLayer:upper()] or nil;
    end,
    --[[!
    @fqxn CoG.AStar.AStarMap.getNode
    @pulsarlua function AStarMap.getNode
    @desc Gets a node by layer name and coordinates. Layer lookup is case-insensitive.
    @param string sLayer A nonblank layer name.
    @param number nX The integer x coordinate.
    @param number nY The integer y coordinate.
    @ret AStarNode|nil oNode The node, or nil when the layer or position is absent.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oMap.getNode("ground", 1, 1) ~= nil);
    !]]
    getNode = function(this, cdat, sLayer, nX, nY)
        type.assert.string(sLayer, "%S+");
        type.assert.number(nX, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.number(nY, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        local oLayer = cdat.pri.layersByName[sLayer:upper()] or nil;

        local oNode;

        if (oLayer ~= nil) then
            oNode = oLayer.getNode(nX, nY);
        end

        return oNode;
    end,
    --[[!
    @fqxn CoG.AStar.AStarMap.getOrigin
    @pulsarlua function AStarMap.getOrigin
    @desc Gets the native coordinates of the first grid cell. Existing maps default to x = 1, y = 1. Imported maps can preserve zero or negative origins.
    @ret table tOrigin A new table with x and y fields.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local tOrigin = oMap.getOrigin();
    assert(tOrigin.x == 1 and tOrigin.y == 1);
    !]]
    getOrigin = function(this, cdat)
        return {x = cdat.pri.originX, y = cdat.pri.originY};
    end,

    --[[!
    @fqxn CoG.AStar.AStarMap.getStagger
    @pulsarlua function AStarMap.getStagger
    @desc Gets the explicitly supplied stagger axis and index. No staggering convention is inferred when none was supplied. Parity refers to native map coordinates.
    @ret table tStagger A new table with axis and index fields, or an empty table when unspecified.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oHex = oSystem.newMap("hex", ASTAR_MAP_TYPE_HEX_FLAT, {AStar.LayerConfig("ground")}, 2, 2,
        {staggerAxis = "x", staggerIndex = "odd"});
    local tStagger = oHex.getStagger();
    assert(tStagger.axis == "x" and tStagger.index == "odd");
    !]]
    getStagger = function(this, cdat)
        local pri = cdat.pri;
        return {axis = pri.staggerAxis ~= null and pri.staggerAxis or nil, index = pri.staggerIndex ~= null and pri.staggerIndex or nil};
    end,

    --[[!
    @fqxn CoG.AStar.AStarMap.getSize
    @pulsarlua function AStarMap.getSize
    @desc Gets a new table containing the grid dimensions.
    @ret table tSize A table with width and height fields.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local tSize = oMap.getSize();
    assert(tSize.width == 3 and tSize.height == 2);
    !]]
    getSize = function(this, cdat)
        local pri = cdat.pri;
        return {width = pri.Width, height = pri.Height};
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);


                --[[███╗░░██╗░█████╗░██████╗░███████╗
                    ████╗░██║██╔══██╗██╔══██╗██╔════╝
                    ██╔██╗██║██║░░██║██║░░██║█████╗░░
                    ██║╚████║██║░░██║██║░░██║██╔══╝░░
                    ██║░╚███║╚█████╔╝██████╔╝███████╗
                    ╚═╝░░╚══╝░╚════╝░╚═════╝░╚══════╝]]
local function collectRovers(...)
    local nInputs = select("#", ...);
    local tRovers = {...};

    --allow for individual rover args or a table of rovers
    if (nInputs == 1 and type(tRovers[1]) == "table") then
        tRovers = tRovers[1];
        type.assert.table(tRovers, "number", "AStarRover");
        local nItems = 0;

        for nIndex, oRover in pairs(tRovers) do
            type.assert.number(nIndex, true, true, false, true, false, 1, #tRovers);
            nItems = nItems + 1;
        end

        assert(nItems == #tRovers, "Rovers must be a contiguous ordered list.");
    else

        for nIndex = 1, nInputs do
            type.assert.custom(tRovers[nIndex], "AStarRover");
        end

    end

    return tRovers;
end

--[[!
@fqxn CoG.AStar.AStarNode
@desc A location in a layer. Owns terrain aspects, resident rovers and outgoing port connections. Entry cost depends on each rover's affinities and aversions; passability depends on the node flag, active aspects and resident rover restrictions. Ports may be one-way or two-way.
!]]
AStarNode = class("AStarNode",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarNode = function(stapub) end,
},
{--PRIVATE
    aspects         = {},
    aspectsDecoy    = {},
    aspectsByName   = {},
    baseCost        = ASTAR_NODE_ENTRY_COST_BASE,
    isPassable      = true,
    owner           = null, --set by the node constructor
    ports           = {}, --nodes that are logically but not physically adjacent (indexed by object)
    portsDecoy      = {},
    portPassageRules    = {},
    rovers          = {}, --indexed by object, values are boolean
    roversDecoy     = {}, --decoy table to return to the client
    type            = null,--set from the owning map during construction
    --[[!
    @fqxn CoG.AStar.AStarNode.getX
    @pulsarlua function AStarNode.getX
    @desc Gets the node's native x coordinate.
    @ret number nX The integer coordinate.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(oNode.getX() == 1);
    !]]
    X__autoAF       = 0,
    --[[!
    @fqxn CoG.AStar.AStarNode.getY
    @pulsarlua function AStarNode.getY
    @desc Gets the node's native y coordinate.
    @ret number nY The integer coordinate.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(oNode.getY() == 1);
    !]]
    Y__autoAF       = 0,
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.AStar.AStarNode.AStarNode
    @desc Creates a node belonging to a layer, with its position, map type and zero or more aspects. Aspect names are stored in uppercase; each aspect starts with full intensity.
    @param AStarLayer oAStarLayer The owning layer.
    @param number nX The integer x coordinate in the map's native coordinate system.
    @param number nY The integer y coordinate in the map's native coordinate system.
    @param table tAspects An ordered list of aspect names; an empty list is allowed.
    @ret AStarNode oNode The new node.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(type(oNode) == "AStarNode"); --created with its layer
    !]]
    AStarNode = function(this, cdat, oAStarLayer, nX, nY, tAspects)
        type.assert.custom(oAStarLayer, "AStarLayer");
        type.assert.number(nX, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.number(nY, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.table(tAspects, "number", "string");

        local nAspects = 0;

        for nIndex, sAspect in pairs(tAspects) do
            type.assert.number(nIndex, true, true, false, true, false, 1, #tAspects);
            type.assert.string(sAspect, "%S+");
            nAspects = nAspects + 1;
        end

        assert(nAspects == #tAspects, "Aspects must be a contiguous ordered list.");

        local pri = cdat.pri;
        _tNodeData[this] = pri;
        pri.owner  = oAStarLayer;
        local oMap = oAStarLayer.getOwner();
        pri.type   = oMap.getType();
        pri.X      = nX;
        pri.Y      = nY;

        for nIndex, sAspect in ipairs(tAspects) do
            type.assert.string(sAspect, "%S+");
            sAspect = sAspect:upper();
            assert(pri.aspectsByName[sAspect] == nil, "Duplicate aspect name, '"..sAspect.."'.");
            local oAspect = AStarAspect(sAspect, this);
            pri.aspects[nIndex]         = oAspect;
            pri.aspectsByName[sAspect]  = oAspect;
        end
        AStarUtil.setupActualDecoy(pri.rovers,  pri.roversDecoy,    "Attempting to modifer read-only rovers table for node at x. "..pri.X..", y. "..pri.Y..".");
        AStarUtil.setupActualDecoy(pri.aspects, pri.aspectsDecoy,   "Attempting to modifer read-only aspects table for node at x. "..pri.X..", y. "..pri.Y..".");
        AStarUtil.setupActualDecoy(pri.ports,   pri.portsDecoy,     "Attempting to modifer read-only ports table for node at x. "..pri.X..", y. "..pri.Y..".");
    end,
    --[[!
    @fqxn CoG.AStar.AStarNode.addPort
    @pulsarlua function AStarNode.addPort
    @desc Adds an outgoing port connection. By default, also updates the reverse connection. A one-way operation leaves any existing reverse connection unchanged.
    @param AStarNode oNode The connected node.
    @param boolean|nil bTwoWay Whether to update both directions; defaults to true. False updates only this node's outgoing connection.
    @param function|nil fPassageRule An optional predicate (rover, sourceNode, destinationNode) returning boolean. Applied to each direction added; omitted rules preserve existing rules. Keep predicates side-effect-free for route planning.
    @ret AStarNode oNode This node, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oExit = oMap.getNode("ground", 3, 2);
    oNode.addPort(oExit, false);
    assert(oNode.hasPort(oExit) and not oExit.hasPort(oNode));
    !]]
    addPort = function(this, cdat, oNode, bTwoWay, fPassageRule)
        type.assert.custom(oNode, "AStarNode");

        if (bTwoWay ~= nil) then
            type.assert.custom(bTwoWay, "boolean");
        end

        if (fPassageRule ~= nil) then
            type.assert.custom(fPassageRule, "function");
        end

        cdat.pri.ports[oNode] = true;

        if (fPassageRule ~= nil) then
            cdat.pri.portPassageRules[oNode] = fPassageRule;
        end

        if (bTwoWay ~= false) then
            local tOther = cdat.ins[oNode].pri;
            tOther.ports[this] = true;

            if (fPassageRule ~= nil) then
                tOther.portPassageRules[this] = fPassageRule;
            end
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.containsRover
    @pulsarlua function AStarNode.containsRover
    @desc Checks whether the supplied rover occupies this node.
    @param AStarRover oRover The rover to check.
    @ret boolean bContains Whether the rover is registered on this node.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oNode.containsRover(oRover));
    !]]
    containsRover = function(this, cdat, oRover)
        type.assert.custom(oRover, "AStarRover");
        return rawtype(cdat.pri.rovers[oRover]) ~= "nil";
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.createRover
    @pulsarlua function AStarNode.createRover
    @desc Creates a rover on this node and registers it as an occupant.
    @param boolean|nil bRetainsPointsOverCycle Whether unused points carry into the next cycle; defaults to true.
    @ret AStarRover oRover The new rover.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover(false);
    assert(oRover.getOwner() == oNode and not oRover.getRetainsPointsOverCycle());
    !]]
    createRover = function(this, cdat, bRetainsPointsOverCycle)
        local pri    = cdat.pri;
        local oRover = AStarRover(this, bRetainsPointsOverCycle);
        pri.rovers[oRover]  = true;

        return oRover;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getAspect
    @pulsarlua function AStarNode.getAspect
    @desc Gets an aspect using a case-insensitive name lookup.
    @param string sAspect A nonblank aspect name.
    @ret AStarAspect|nil oAspect The aspect, or nil when absent.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(oNode.getAspect("mud").getName() == "MUD");
    !]]
    getAspect = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        sAspect = sAspect:upper();
        return cdat.pri.aspectsByName[sAspect] or nil;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getAspects
    @pulsarlua function AStarNode.getAspects
    @desc Gets a read-only view of the node's ordered aspects. The aspect objects and their Protean impactors remain modifiable through their methods.
    @ret table tAspects The ordered aspect objects.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(#oNode.getAspects() == 1);
    !]]
    getAspects = function(this, cdat)
        return cdat.pri.aspectsDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getAspectImpact
    @pulsarlua function AStarNode.getAspectImpact
    @desc Gets an aspect's calculated intensity using a case-insensitive name lookup.
    @param string sAspect A nonblank aspect name.
    @ret number|nil nImpact The final intensity from 0 to 1, or nil when the aspect is absent.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(oNode.getAspectImpact("mud") == 1);
    !]]
    getAspectImpact = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        sAspect = sAspect:upper();
        local oAspect = cdat.pri.aspectsByName[sAspect] or nil;

        local nImpact;

        if (oAspect ~= nil) then
            local oImpactor = oAspect.getImpactor();
            nImpact = oImpactor.getValue();
        end

        return nImpact;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getEntryCost
    @pulsarlua function AStarNode.getEntryCost
    @desc Calculates the entry cost for one rover. Each active aspect contributes base cost times its own intensity times the difference between rover aversion and affinity. Contributions are added to the base cost and the result is clamped to the configured cost bounds. Aspects do not compound on each other. This calculation does not check passability or spend movement points.
    @param AStarRover oRover The rover whose affinities and aversions determine the cost.
    @ret number nCost The bounded entry cost for this rover.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oNode.getEntryCost(oRover) == 10);
    !]]
    getEntryCost = function(this, cdat, oRover)
        type.assert.custom(oRover, "AStarRover");
        local pri       = cdat.pri;
        local nBaseCost = pri.baseCost;
        local nRet      = nBaseCost;

        --iterate over all of this node's aspects
        for sAspect, oAspect in pairs(pri.aspectsByName) do
            local oImpactor = oAspect.getImpactor();
            local nImpact   = oImpactor.getValue();

            --operate on this aspect only if it has an impact on the node
            if (nImpact > 0) then
                local oAffinity = oRover.getAffinity(sAspect);
                local oAversion = oRover.getAversion(sAspect);
                local nAffinity = oAffinity.getValue();
                local nAversion = oAversion.getValue();
--[[Let F   = Final Entry Cost
Let M   = total of independently weighted affinity/aversion contributions
Let B   = Node base cost
Let Naf = node aspect intensity
Let Raf = rover affinity value
Let Rav = rover aversion value
M = M + B * Naf * (Rav - Raf);

F = math.clamp(B + M, ASTAR_NODE_ENTRY_COST_MIN, ASTAR_NODE_ENTRY_COST_MAX);]]
                --apply this aspect's intensity only to its own affinity/aversion contribution
                nRet = nRet + nBaseCost * nImpact * (nAversion - nAffinity);

            end

        end

        return math.clamp(nRet, ASTAR_NODE_ENTRY_COST_MIN, ASTAR_NODE_ENTRY_COST_MAX);
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getEntryCosts
    @pulsarlua function AStarNode.getEntryCosts
    @desc Calculates a separate entry cost for each supplied rover. Costs are indexed by rover and are not summed together. Does not check passability or spend movement points. No rovers produces an empty table.
    @param AStarRover|table ... Individual rovers, or one ordered table of rovers.
    @ret table tCosts The entry costs indexed by rover object.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oFirst = oNode.createRover();
    local oSecond = oNode.createRover();
    local tCosts = oNode.getEntryCosts({oFirst, oSecond});
    assert(tCosts[oFirst] == 10 and tCosts[oSecond] == 10);
    !]]
    getEntryCosts = function(this, cdat, ...)
        local tRovers = collectRovers(...);
        local tCosts  = {};

        for _, oRover in ipairs(tRovers) do
            tCosts[oRover] = this.getEntryCost(oRover);
        end

        return tCosts;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getNeighbors
    @pulsarlua function AStarNode.getNeighbors
    @desc Gathers edge-sharing neighbors and destinations of outgoing ports without duplicates or this node itself. Does not filter by passability or movement points. Hex maps require explicit staggerAxis and staggerIndex settings. Square maps use four edge-sharing neighbors. Triangular maps use three edge-sharing neighbors: even native x+y points up for flat triangles or left for pointed triangles; odd parity reverses the direction.
    @param boolean|nil bPhysicalOnly True excludes outgoing ports; defaults to false.
    @ret table tNeighbors A new ordered list of neighboring nodes. Physical neighbors precede ports; port order is unspecified.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    oNode.addPort(oMap.getNode("ground", 3, 2), false);
    assert(#oNode.getNeighbors() == 3 and #oNode.getNeighbors(true) == 2);
    !]]
    getNeighbors = function(this, cdat, bPhysicalOnly)
        if (bPhysicalOnly ~= nil) then
            type.assert.custom(bPhysicalOnly, "boolean");
        end

        local pri        = cdat.pri;
        local tNeighbors = {};
        local tSeen      = {};
        local oLayer     = pri.owner;
        local oMap       = oLayer.getOwner();
        local tStagger   = oMap.getStagger();


        local function addNeighbor(oNode)

            if (oNode ~= nil and oNode ~= this and not tSeen[oNode]) then
                tSeen[oNode] = true;
                tNeighbors[#tNeighbors + 1] = oNode;
            end

        end

        local function addAt(nX, nY)
            addNeighbor(oLayer.getNode(nX, nY));
        end

        if (pri.type == ASTAR_MAP_TYPE_HEX_FLAT or pri.type == ASTAR_MAP_TYPE_HEX_POINTED) then
            assert(tStagger.axis ~= nil and tStagger.index ~= nil, "Hex neighbor generation requires explicit staggerAxis and staggerIndex map settings.");
            local nCoordinate = tStagger.axis == "x" and pri.X or pri.Y;
            local nParity     = tStagger.index == "odd" and 1 or 0;
            local nShift      = nCoordinate % 2 == nParity and 1 or 0;

            --stagger parity uses native coordinates, including zero and negative origins
            if (tStagger.axis == "x") then
                addAt(pri.X, pri.Y - 1);
                addAt(pri.X, pri.Y + 1);
                addAt(pri.X - 1, pri.Y + nShift - 1);
                addAt(pri.X - 1, pri.Y + nShift);
                addAt(pri.X + 1, pri.Y + nShift - 1);
                addAt(pri.X + 1, pri.Y + nShift);
            else
                addAt(pri.X - 1, pri.Y);
                addAt(pri.X + 1, pri.Y);
                addAt(pri.X + nShift - 1, pri.Y - 1);
                addAt(pri.X + nShift, pri.Y - 1);
                addAt(pri.X + nShift - 1, pri.Y + 1);
                addAt(pri.X + nShift, pri.Y + 1);
            end
        elseif (pri.type == ASTAR_MAP_TYPE_SQUARE) then
            addAt(pri.X - 1, pri.Y);
            addAt(pri.X + 1, pri.Y);
            addAt(pri.X, pri.Y - 1);
            addAt(pri.X, pri.Y + 1);
        elseif (pri.type == ASTAR_MAP_TYPE_TRIANGLE_FLAT) then
            --even native x+y points up; odd points down
            local nDirection = (pri.X % 2 + pri.Y % 2) % 2 == 0 and 1 or -1;
            addAt(pri.X - 1, pri.Y);
            addAt(pri.X + 1, pri.Y);
            addAt(pri.X, pri.Y + nDirection);
        elseif (pri.type == ASTAR_MAP_TYPE_TRIANGLE_POINTED) then
            --even native x+y points left; odd points right
            local nDirection = (pri.X % 2 + pri.Y % 2) % 2 == 0 and 1 or -1;
            addAt(pri.X, pri.Y - 1);
            addAt(pri.X, pri.Y + 1);
            addAt(pri.X + nDirection, pri.Y);
        else
            error("Unsupported map type for neighbor generation.");
        end

        --ports are outgoing connections and may lead to other layers or maps
        if (not bPhysicalOnly) then
            for oNode in pairs(pri.ports) do
                addNeighbor(oNode);
            end
        end

        return tNeighbors;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getOwner
    @pulsarlua function AStarNode.getOwner
    @desc Gets the layer that owns this node.
    @ret AStarLayer oLayer The owning layer.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(oNode.getOwner() == oMap.getLayer("ground"));
    !]]
    getOwner = function(this, cdat)
        return cdat.pri.owner;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getPassable
    @pulsarlua function AStarNode.getPassable
    @desc Gets the node's general passability flag without checking any rover's restrictions.
    @ret boolean bPassable The general passability flag.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    oNode.setPassable(false);
    assert(not oNode.getPassable());
    !]]
    getPassable = function(this, cdat)
        return cdat.pri.isPassable;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getPorts
    @pulsarlua function AStarNode.getPorts
    @desc Gets a read-only view of this node's outgoing port connections. Keys are destination nodes and values are true. A connection appears here whether it is one-way or two-way.
    @ret table tPorts The outgoing connections, indexed by destination node.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oExit = oMap.getNode("ground", 3, 2);
    oNode.addPort(oExit, false);
    assert(oNode.getPorts()[oExit] == true);
    !]]
    getPorts = function(this, cdat)
        return cdat.pri.portsDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getPos
    @pulsarlua function AStarNode.getPos
    @desc Gets a new table containing the node's coordinates.
    @ret table tPosition A table with x and y fields.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local tPosition = oNode.getPos();
    assert(tPosition.x == 1 and tPosition.y == 1);
    !]]
    getPos = function(this, cdat)
        local pri = cdat.pri;
        return {x = pri.X, y = pri.Y};
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getRovers
    @pulsarlua function AStarNode.getRovers
    @desc Gets a read-only view of the rovers occupying this node. Keys are rover objects and values are true.
    @ret table tRovers The resident rovers, indexed by rover object.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oNode.getRovers()[oRover] == true);
    !]]
    getRovers = function(this, cdat)
        return cdat.pri.roversDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.getPortPassageRule
    @pulsarlua function AStarNode.getPortPassageRule
    @desc Gets the rule for this node's outgoing port. Node occupancy is independent of port passage.
    @param AStarNode oNode The port destination.
    @ret function|nil fRule The predicate, or nil for an unrestricted or absent port.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oExit = oMap.getNode("ground", 3, 2);
    local fRule = function(oRover) return oRover.isType("goblin"); end;
    oNode.addPort(oExit, false, fRule);
    assert(oNode.getPortPassageRule(oExit) == fRule);
    !]]
    getPortPassageRule = function(this, cdat, oNode)
        type.assert.custom(oNode, "AStarNode");
        return cdat.pri.portPassageRules[oNode];
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.setPortPassageRule
    @pulsarlua function AStarNode.setPortPassageRule
    @desc Sets or clears an existing outgoing port's rule. Does not change node passability. Each predicate receives (rover, sourceNode, destinationNode) and must return boolean. Keep it side-effect-free: planning may evaluate it repeatedly. A two-way update requires both directions to exist and uses the same function in each direction.
    @param AStarNode oNode The destination.
    @param function|nil fRule The predicate; nil clears the restriction.
    @param boolean|nil bTwoWay True updates both directions; defaults to false.
    @ret AStarNode oSource This node.
    @ex
    local oSystem   = AStar();
    local oMap      = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 3, 1);
    local oEntrance = oMap.getNode("ground", 1, 1);
    local oExit     = oMap.getNode("ground", 3, 1);
    oEntrance.addPort(oExit);
    oEntrance.setPortPassageRule(oExit, function(oRover, oSource, oDestination)
        return oRover.isType("goblin");
    end, true);
    local oHuman = oEntrance.createRover();
    assert(oEntrance.isPassable(oHuman) and not oEntrance.canUsePort(oExit, oHuman));
    oHuman.addType("goblin");
    assert(oEntrance.canUsePort(oExit, oHuman));
    !]]
    setPortPassageRule = function(this, cdat, oNode, fRule, bTwoWay)
        type.assert.custom(oNode, "AStarNode");

        if (fRule ~= nil) then
            type.assert.custom(fRule, "function");
        end

        if (bTwoWay ~= nil) then
            type.assert.custom(bTwoWay, "boolean");
        end

        local pri    = cdat.pri;
        local tOther = cdat.ins[oNode].pri;
        assert(pri.ports[oNode] == true, "An outgoing port is required before setting its passage rule.");
        assert(not bTwoWay or tOther.ports[this] == true, "A reverse port is required for a two-way rule update.");
        pri.portPassageRules[oNode] = fRule;

        if (bTwoWay) then
            tOther.portPassageRules[this] = fRule;
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.canUsePort
    @pulsarlua function AStarNode.canUsePort
    @desc Checks outgoing port existence and passage permission for every supplied rover, independently of node passability, occupancy, movement points and the rovers' current positions. A missing port returns false; a port without a rule allows passage.
    @param AStarNode oNode The destination.
    @param AStarRover|table ... One or more rovers, individually or in an ordered table.
    @ret boolean bAllowed Whether every rover may use this port.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oExit = oMap.getNode("ground", 3, 2);
    oNode.addPort(oExit, false);
    assert(oNode.canUsePort(oExit, oNode.createRover()));
    !]]
    canUsePort = function(this, cdat, oNode, ...)
        type.assert.custom(oNode, "AStarNode");
        local tRovers = collectRovers(...);
        local pri     = cdat.pri;
        local bRet    = pri.ports[oNode] == true;
        local fRule   = pri.portPassageRules[oNode];
        assert(#tRovers > 0, "Port passage requires at least one rover.");

        if (bRet and fRule ~= nil) then
            for _, oRover in ipairs(tRovers) do
                local bAllowed = fRule(oRover, this, oNode);
                type.assert.custom(bAllowed, "boolean");

                if (not bAllowed) then
                    bRet = false;
                    break;
                end
            end
        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.canTraverseTo
    @pulsarlua function AStarNode.canTraverseTo
    @desc Checks whether a physical edge or an allowed outgoing port connects this node to the destination for every supplied rover. A physical edge permits traversal independently of any parallel port restriction. Destination passability and movement budgets are checked separately by planning and movement.
    @param AStarNode oNode The destination.
    @param AStarRover|table ... One or more rovers, individually or in an ordered table.
    @ret boolean bConnected Whether a permitted connection exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oNode.canTraverseTo(oMap.getNode("ground", 2, 1), oRover));
    !]]
    canTraverseTo = function(this, cdat, oNode, ...)
        type.assert.custom(oNode, "AStarNode");
        local tRovers = collectRovers(...);
        local bRet    = false;
        assert(#tRovers > 0, "Traversal requires at least one rover.");

        for _, oNeighbor in ipairs(this.getNeighbors(true)) do
            if (oNeighbor == oNode) then
                bRet = true;
                break;
            end
        end

        if (not bRet) then
            bRet = this.canUsePort(oNode, tRovers);
        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.hasAspect
    @pulsarlua function AStarNode.hasAspect
    @desc Checks whether this node has an aspect using a case-insensitive name lookup.
    @param string sAspect A nonblank aspect name.
    @ret boolean bHasAspect Whether the aspect exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(oNode.hasAspect("mud") and not oNode.hasAspect("snow"));
    !]]
    hasAspect = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        sAspect = sAspect:upper();
        local tAspects = cdat.pri.aspectsByName;
        return rawtype(tAspects[sAspect]) ~= "nil";
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.hasPort
    @pulsarlua function AStarNode.hasPort
    @desc Checks whether this node has an outgoing port to the supplied node. Does not require a reverse connection.
    @param AStarNode oNode The destination node to check.
    @ret boolean bHasPort Whether the outgoing connection exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oExit = oMap.getNode("ground", 3, 2);
    oNode.addPort(oExit, false);
    assert(oNode.hasPort(oExit));
    !]]
    hasPort = function(this, cdat, oNode)
        type.assert.custom(oNode, "AStarNode");
        return cdat.pri.ports[oNode] == true;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.hasTwoWayPort
    @pulsarlua function AStarNode.hasTwoWayPort
    @desc Checks whether both nodes have an outgoing port to each other. Returns false immediately when either node has no outgoing ports.
    @param AStarNode oNode The node to check.
    @ret boolean bTwoWay Whether the connection exists in both directions.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oExit = oMap.getNode("ground", 3, 2);
    oNode.addPort(oExit);
    assert(oNode.hasTwoWayPort(oExit));
    !]]
    hasTwoWayPort = function(this, cdat, oNode)
        type.assert.custom(oNode, "AStarNode");
        local tPorts = cdat.pri.ports;
        local bRet   = false;

        if (next(tPorts) ~= nil) then
            local tOtherPorts = cdat.ins[oNode].pri.ports;

            if (next(tOtherPorts) ~= nil) then
                bRet = tPorts[oNode] == true and tOtherPorts[this] == true;
            end
        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.hasPorts
    @pulsarlua function AStarNode.hasPorts
    @desc Checks whether this node has any outgoing port connections. Incoming-only connections do not count.
    @ret boolean bHasPorts Whether at least one outgoing connection exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    assert(not oNode.hasPorts());
    oNode.addPort(oMap.getNode("ground", 3, 2));
    assert(oNode.hasPorts());
    !]]
    hasPorts = function(this, cdat)
        return next(cdat.pri.ports) ~= nil;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.isPassable
    @pulsarlua function AStarNode.isPassable
    @desc Checks whether the node can be entered by every supplied rover. A false general passability flag blocks entry. Otherwise, entry is denied if any rover is forbidden from the layer, abhors an active aspect or a resident rover refuses entry to it. With no rovers supplied, returns the general passability flag. Movement points are not checked here.
    @param AStarRover|table ... Individual rovers, or one table containing the rovers to check.
    @ret boolean bPassable Whether all supplied rovers may enter.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oNode.isPassable(oRover));
    oRover.setAbhors("mud", true);
    assert(not oNode.isPassable(oRover));
    !]]
    isPassable = function(this, cdat, ...)
        local tRovers = collectRovers(...);
        local pri     = cdat.pri;
        local bRet    = pri.isPassable;

        if (bRet) then
            for _, oRover in ipairs(tRovers) do
                bRet = oRover.isAllowedOnLayer(pri.owner);

                if (bRet) then
                    for _, oAspect in pairs(pri.aspectsByName) do
                        local oImpactor = oAspect.getImpactor();

                        if (oImpactor.getValue() > 0 and oRover.abhors(oAspect.getName())) then
                            bRet = false;
                            break;
                        end
                    end
                end

                if (bRet) then
                    for oResident in pairs(pri.rovers) do
                        if (not oResident.allowsEntryTo(oRover)) then
                            bRet = false;
                            break;
                        end
                    end
                end

                if (not bRet) then
                    break;
                end
            end
        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.removePort
    @pulsarlua function AStarNode.removePort
    @desc Removes an outgoing port connection. By default, also updates the reverse connection. A one-way operation leaves any existing reverse connection unchanged.
    @param AStarNode oNode The connected node.
    @param boolean|nil bTwoWay Whether to update both directions; defaults to true. False updates only this node's outgoing connection.
    @ret AStarNode oNode This node, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oExit = oMap.getNode("ground", 3, 2);
    oNode.addPort(oExit);
    oNode.removePort(oExit);
    assert(not oNode.hasPort(oExit) and not oExit.hasPort(oNode));
    !]]
    removePort = function(this, cdat, oNode, bTwoWay)
        type.assert.custom(oNode, "AStarNode");

        if (bTwoWay ~= nil) then
            type.assert.custom(bTwoWay, "boolean");
        end

        cdat.pri.ports[oNode] = nil;
        cdat.pri.portPassageRules[oNode] = nil;

        if (bTwoWay ~= false) then
            cdat.ins[oNode].pri.ports[this] = nil;
            cdat.ins[oNode].pri.portPassageRules[this] = nil;
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.setPassable
    @pulsarlua function AStarNode.setPassable
    @desc Sets the node's general passability flag. Non-boolean inputs leave the flag unchanged. Rover-specific restrictions are still checked by isPassable when the flag is true.
    @param boolean bPassable Whether the node is generally passable.
    @ret nil vReturn No return value.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    oNode.setPassable(false);
    assert(not oNode.isPassable());
    !]]
    setPassable = function(this, cdat, bPassable)

        if (rawtype(bPassable) == "boolean") then
            cdat.pri.isPassable = bPassable;
        end

    end,

    --[[!
    @fqxn CoG.AStar.AStarNode.togglePassable
    @pulsarlua function AStarNode.togglePassable
    @desc Inverts the node's general passability flag. Does not alter rover-specific restrictions.
    @ret nil vReturn No return value.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    oNode.togglePassable();
    assert(not oNode.getPassable());
    !]]
    togglePassable = function(this, cdat)
        cdat.pri.isPassable = not cdat.pri.isPassable;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);




--Pathfinding follows outgoing ports, including connections to other layers and maps.
--[[
Abhoration.
If a rover is abhorant to one or more of a node's
    aspects, it cannot move onto that node. It is,
    for that rover, immpassible even if it is an
    otherwise-passable node.

How entry cost is calculated.
* A rover desires to enter a node
* Assuming the rover is not abhorant to any of the
    node's aspects, the following equation is run
    for each of a node's aspects (if the aspect is > 0).
    Let F   = Final Entry Cost
    Let M   = total of independently weighted affinity/aversion contributions
    Let B   = Node base cost
    Let Naf = node aspect intensity
    Let Raf = rover affinity value
    Let Rav = rover aversion value
    M = M + B * Naf * (Rav - Raf);

    F = math.clamp(B + M, ASTAR_NODE_ENTRY_COST_MIN, ASTAR_NODE_ENTRY_COST_MAX);


    Note. since aspects, affinities and aversion are
    proteans, the client can affect the final values
    very granularly using penalties and bonuses if
    desired.

Regarding Groups.
* If one rover in a group is abhorant to a node
    or restricted from entry onto a layer,the
    entire group is restricted from entry.
* The farthest a group may go in a path is limited
    by the rover which can move the least distance.
                        ]]
                        --[[██████╗░░█████╗░████████╗██╗░░██╗
                            ██╔══██╗██╔══██╗╚══██╔══╝██║░░██║
                            ██████╔╝███████║░░░██║░░░███████║
                            ██╔═══╝░██╔══██║░░░██║░░░██╔══██║
                            ██║░░░░░██║░░██║░░░██║░░░██║░░██║
                            ╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝]]

local function pathNodeSystem(oNode)
    local oLayer = oNode.getOwner();
    local oMap   = oLayer.getOwner();
    local oAStar = oMap.getOwner();
    return oAStar;
end

local function pathLabelDominates(tLeft, tRightCosts, nRightProgress, tRovers)
    local bRet = true;
    local bStrictlyCheaper = true;

    for _, oRover in ipairs(tRovers) do
        local nLeft = tLeft.costs[oRover];
        local nRight = tRightCosts[oRover];
        bStrictlyCheaper = bStrictlyCheaper and nLeft < nRight;

        if (nLeft > nRight) then
            bRet = false;
            break;
        end
    end

    --A route strictly cheaper for every member cannot lose a total-cost tie.
    --This also discards positive-cost cycles regardless of apparent prefix progress.
    return bRet and (bStrictlyCheaper or tLeft.progress >= nRightProgress);
end

local function findPath(oStart, oEnd, tRovers)
    local oSystem = pathNodeSystem(oStart);
    local tCosts  = {};
    local tOpen   = {};
    local tLabels = {};
    local tNodes  = {};
    local tTotals = {};
    local oResult;

    for _, oRover in ipairs(tRovers) do
        tCosts[oRover] = 0;
        tTotals[oRover] = 0;
    end

    local tStart = {node = oStart, costs = tCosts, score = 0, previous = nil, active = true, progress = 1, withinBudget = true};
    tOpen[1] = tStart;
    tLabels[oStart] = {tStart};

    --A zero heuristic is admissible for every geometry and arbitrary port shortcuts.
    --Keep nondominated cost vectors: one scalar per node loses valid group routes.
    while (#tOpen > 0) do
        local nBest = 1;

        for nIndex = 2, #tOpen do
            if (tOpen[nIndex].score < tOpen[nBest].score) then
                nBest = nIndex;
            end
        end

        local tCurrent = table.remove(tOpen, nBest);

        if (oResult ~= nil and tCurrent.score > oResult.score) then
            break;
        end

        if (tCurrent.active) then
            if (tCurrent.node == oEnd) then
                if (oResult == nil or tCurrent.progress > oResult.progress) then
                    oResult = tCurrent;
                end
            else
                for _, oNeighbor in ipairs(tCurrent.node.getNeighbors()) do
                    if (pathNodeSystem(oNeighbor) == oSystem and tCurrent.node.canTraverseTo(oNeighbor, tRovers) and oNeighbor.isPassable(tRovers)) then
                        local tEntry        = oNeighbor.getEntryCosts(tRovers);
                        local tNext         = {};
                        local nScore        = 0;
                        local bDominated    = false;
                        local bWithinBudget = tCurrent.withinBudget;
                        local nProgress     = tCurrent.progress;
                        local tExisting     = tLabels[oNeighbor] or {};

                        for _, oRover in ipairs(tRovers) do
                            tNext[oRover] = tCurrent.costs[oRover] + tEntry[oRover];
                            nScore = math.max(nScore, tNext[oRover]);
                            local oPoints = oRover.getMovePointPool();
                            bWithinBudget = bWithinBudget and tNext[oRover] <= oPoints.get();
                        end

                        if (bWithinBudget) then
                            nProgress = nProgress + 1;
                        end

                        for _, tLabel in ipairs(tExisting) do
                            if (tLabel.active and pathLabelDominates(tLabel, tNext, nProgress, tRovers)) then
                                bDominated = true;
                                break;
                            end
                        end

                        if (not bDominated) then
                            for _, tLabel in ipairs(tExisting) do
                                if (tLabel.active and pathLabelDominates({costs = tNext, progress = nProgress}, tLabel.costs, tLabel.progress, tRovers)) then
                                    tLabel.active = false;
                                end
                            end

                            local tNextLabel = {node = oNeighbor, costs = tNext, score = nScore, previous = tCurrent, active = true, progress = nProgress, withinBudget = bWithinBudget};
                            tExisting[#tExisting + 1] = tNextLabel;
                            tLabels[oNeighbor] = tExisting;
                            tOpen[#tOpen + 1] = tNextLabel;
                        end
                    end
                end
            end
        end
    end

    if (oResult ~= nil) then
        tTotals = oResult.costs;
        local tCurrent = oResult;

        while (tCurrent ~= nil) do
            table.insert(tNodes, 1, tCurrent.node);
            tCurrent = tCurrent.previous;
        end
    end

    return tNodes, tTotals, oResult ~= nil;
end

local function previewPath(pri)
    local tBudgets     = {};
    local tCycles      = {};
    local nCycle       = 0;
    local nReachable   = 0;
    local bCanContinue = true;

    --Read values only. Neither clone callbacks nor live Pool events run in a preview.
    for _, oRover in ipairs(pri.rovers) do
        local oPoints = oRover.getMovePointPool();
        tBudgets[oRover] = {
            current = oPoints.get(),
            available = oPoints.get(Pool.ASPECT.AVAILABLE),
            regen = oPoints.get(Pool.ASPECT.CYCLE),
            retains = oRover.getRetainsPointsOverCycle(),
        };
    end

    if (pri.found) then
        tCycles[pri.currentStep] = 0;
        nReachable = pri.currentStep;
    end

    for nIndex = pri.currentStep + 1, #pri.nodes do
        if (bCanContinue) then
            local tEntry = pri.nodes[nIndex].getEntryCosts(pri.rovers);
            local nWait  = 0;

            for _, oRover in ipairs(pri.rovers) do
                local tBudget = tBudgets[oRover];
                local nCost   = tEntry[oRover];

                if (tBudget.current < nCost) then
                    if (nCost > tBudget.available or tBudget.regen <= 0 or
                        (not tBudget.retains and tBudget.regen < nCost)) then
                        bCanContinue = false;
                    else
                        local nNeeded = tBudget.retains and math.ceil((nCost - tBudget.current) / tBudget.regen) or 1;
                        nWait = math.max(nWait, nNeeded);
                    end
                end
            end

            if (bCanContinue and nWait > 0) then
                --A group waits together; recheck everyone after applying those cycles.
                for _, oRover in ipairs(pri.rovers) do
                    local tBudget  = tBudgets[oRover];
                    local nCurrent = tBudget.retains and tBudget.current + nWait * tBudget.regen or tBudget.regen;
                    tBudget.current = math.max(0, math.min(tBudget.available, nCurrent));

                    if (tBudget.current < tEntry[oRover]) then
                        bCanContinue = false;
                    end
                end
                nCycle = nCycle + nWait;
            end

            if (bCanContinue) then
                tCycles[nIndex] = nCycle;

                for _, oRover in ipairs(pri.rovers) do
                    tBudgets[oRover].current = tBudgets[oRover].current - tEntry[oRover];
                end

                if (nCycle == 0) then
                    nReachable = nIndex;
                end
            end
        end
    end

    pri.cycles             = tCycles;
    pri.reachableNodeCount = nReachable;
    pri.cycleCount         = pri.found and bCanContinue and nCycle or null;
end

--[[!
@fqxn CoG.AStar.AStarPath
@desc A planned group route. Construction searches passable nodes and outgoing ports without moving rovers or changing movement Pools. Costs remain separate per rover; route selection minimizes the largest individual total, then favors the longest prefix affordable by the entire group this turn. Node lists include the start, whose entry cost is not charged. Cycle 0 is the current turn; later cycle numbers describe future turns using each rover's capacity, regeneration and point-retention setting. Previews assume these settings and entry costs remain unchanged. Exact group search retains nondominated individual cost vectors; maps with many competing cost combinations can require substantially more time and memory than a single-rover search.
!]]
AStarPath = class("AStarPath",
{--METAMETHODS
},
{--STATIC PUBLIC
},
{--PRIVATE
    cost                = {},
    currentStep         = 1,
    lastStep            = 0,
    nodes               = {},
    nodesDecoy          = {},
    onStep              = null,
    rovers              = {},
    roversDecoy         = {},
    totalSteps          = 0,
    found               = false,
    stepping            = false,
    cycles              = {},
    reachableNodeCount  = 0,
    cycleCount          = null,
},
{--PROTECTED
},
{--PUBLIC
    --[[!
    @fqxn CoG.AStar.AStarPath.AStarPath
    @desc Plans a route for one or more distinct rovers at the start node. Endpoints must belong to the same AStar system. No route produces an empty node list and hasPath false; insufficient movement points do not prevent route construction.
    @param AStarNode oStartNode The starting node.
    @param AStarNode oEndNode The destination node.
    @param AStarRover|table ... Individual rovers or one contiguous ordered rover list.
    @ret AStarPath oPath The planned path.
    @ex
    local oSystem = AStar();
    local oMap    = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 3, 1);
    local oStart  = oMap.getNode("ground", 1, 1);
    local oRover  = oStart.createRover();
    oRover.getMovePointPool().set(20, Pool.ASPECT.MAX);
    oRover.getMovePointPool().set(10, Pool.ASPECT.CYCLE_FLAT);
    local oPath = AStar.Path(oStart, oMap.getNode("ground", 3, 1), oRover);
    assert(oPath.hasPath() and oPath.getNodeCount() == 3);
    assert(oPath.getCycleForNode(3) == 2);
    !]]
    AStarPath = function(this, cdat, oStartNode, oEndNode, ...)
        type.assert.custom(oStartNode, "AStarNode");
        type.assert.custom(oEndNode, "AStarNode");
        assert(pathNodeSystem(oStartNode) == pathNodeSystem(oEndNode), "Path endpoints must belong to the same AStar system.");
        local tRovers = collectRovers(...);
        local tSeen   = {};
        local pri     = cdat.pri;
        assert(#tRovers > 0, "A path requires at least one rover.");

        for _, oRover in ipairs(tRovers) do
            assert(not tSeen[oRover], "A path cannot contain duplicate rovers.");
            assert(oRover.getOwner() == oStartNode, "Every path rover must occupy the starting node.");
            tSeen[oRover] = true;
            pri.rovers[#pri.rovers + 1] = oRover;
        end

        pri.nodes, pri.cost, pri.found = findPath(oStartNode, oEndNode, pri.rovers);
        pri.totalSteps = math.max(0, #pri.nodes - 1);
        AStarUtil.setupActualDecoy(pri.nodes, pri.nodesDecoy, "Attempt to modify path nodes.");
        AStarUtil.setupActualDecoy(pri.rovers, pri.roversDecoy, "Attempt to modify path rovers.");
        previewPath(pri);
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.hasPath
    @pulsarlua function AStarPath.hasPath
    @desc Checks whether a passable route was found, independently of movement points.
    @ret boolean bFound Whether the route exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.hasPath());
    !]]
    hasPath = function(this, cdat)
        return cdat.pri.found;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getCost
    @pulsarlua function AStarPath.getCost
    @desc Gets the total entry cost captured during route construction for a member rover, excluding the start. Later cost changes and payments do not alter this planned total.
    @param AStarRover oRover A member of this path.
    @ret number nCost The rover's cumulative cost; zero when no route exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getCost(oRover) == 30);
    !]]
    getCost = function(this, cdat, oRover)
        type.assert.custom(oRover, "AStarRover");
        assert(cdat.pri.cost[oRover] ~= nil, "Rover is not a member of this path.");
        return cdat.pri.cost[oRover];
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getCostTotal
    @pulsarlua function AStarPath.getCostTotal
    @desc Gets the largest individual cumulative cost captured during route construction, used to compare routes. This is not a sum of group members' costs or a group payment.
    @ret number nCost The route comparison cost; zero when no route exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getCostTotal() == 30);
    !]]
    getCostTotal = function(this, cdat)
        local nRet = 0;
        for _, nCost in pairs(cdat.pri.cost) do
            nRet = math.max(nRet, nCost);
        end
        return nRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getNextNode
    @pulsarlua function AStarPath.getNextNode
    @desc Gets the next node after the current path position without advancing or moving.
    @ret AStarNode|nil oNode The next node, or nil at the end or when no route exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getNextNode() ~= nil);
    !]]
    getNextNode = function(this, cdat)
        return cdat.pri.nodes[cdat.pri.currentStep + 1];
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getNodes
    @pulsarlua function AStarPath.getNodes
    @desc Gets the ordered route including the starting node.
    @ret table tNodes A read-only node view; empty when no route exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getNodes()[1] == oNode);
    !]]
    getNodes = function(this, cdat)
        return cdat.pri.nodesDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getNodeCount
    @pulsarlua function AStarPath.getNodeCount
    @desc Gets the number of route nodes, including the start.
    @ret number nCount The node count.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getNodeCount() == 4);
    !]]
    getNodeCount = function(this, cdat)
        return #cdat.pri.nodes;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getRovers
    @pulsarlua function AStarPath.getRovers
    @desc Gets the path's distinct ordered rover members.
    @ret table tRovers A read-only rover view.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getRovers()[1] == oRover);
    !]]
    getRovers = function(this, cdat)
        return cdat.pri.roversDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getCycleForNode
    @pulsarlua function AStarPath.getCycleForNode
    @desc Gets the preview cycle for a route node. Zero means reachable this turn. Nil means the index is before the current path position, outside the route, or that a rover cannot afford this or a preceding remaining node under the current capacity and regeneration settings.
    @param number nIndex The positive integer route-node index.
    @ret number|nil nCycle The number of future cycles required, or nil.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getCycleForNode(4) == 0);
    !]]
    getCycleForNode = function(this, cdat, nIndex)
        type.assert.number(nIndex, true, true, false, true, false, 1, math.maxinteger);
        return cdat.pri.cycles[nIndex];
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getReachableNodeCount
    @pulsarlua function AStarPath.getReachableNodeCount
    @desc Gets the last node index reachable this turn, including nodes already traversed. At construction this is the number of reachable prefix nodes, including the start.
    @ret number nCount The reachable node count; zero when no route exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getReachableNodeCount() == 4);
    !]]
    getReachableNodeCount = function(this, cdat)
        return cdat.pri.reachableNodeCount;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.getCycleCount
    @pulsarlua function AStarPath.getCycleCount
    @desc Gets future cycles needed to reach the destination under the preview settings.
    @ret number|nil nCycles Zero when reachable now, or nil when no route exists or progress cannot finish with the current settings.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    assert(oPath.getCycleCount() == 0);
    !]]
    getCycleCount = function(this, cdat)
        local vRet = cdat.pri.cycleCount;
        return vRet ~= null and vRet or nil;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.setOnStepCallback
    @pulsarlua function AStarPath.setOnStepCallback
    @desc Sets the step callback, or clears it for non-function input. Runs once after a successful committed group step and after rover exit, entry and move callbacks. Receives (path, rovers, currentNodeIndex, totalSteps, currentNode, previousNode); totalSteps excludes the start. Installing a callback does not execute the path.
    @param function|nil fFunc The callback.
    @ret AStarPath oPath This path.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    local nCalls = 0;
    oPath.setOnStepCallback(function() nCalls = nCalls + 1; end);
    assert(oPath.step() and nCalls == 1);
    !]]
    setOnStepCallback = function(this, cdat, fFunc)
        cdat.pri.onStep = rawtype(fFunc) == "function" and fFunc or null;
        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.refreshPreview
    @pulsarlua function AStarPath.refreshPreview
    @desc Recalculates cycle boundaries from the current path position and live budgets without moving, paying or replanning the route. Useful after cycling rovers or changing movement settings.
    @ret AStarPath oPath This path.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(100, Pool.ASPECT.MAX);
    oPoints.setFull();
    local oPath = AStar.Path(oNode, oMap.getNode("ground", 3, 2), oRover);
    oPoints.set(0);
    oPoints.set(10, Pool.ASPECT.CYCLE_FLAT);
    oPath.refreshPreview();
    assert(oPath.getCycleCount() == 3);
    !]]
    refreshPreview = function(this, cdat)
        previewPath(cdat.pri);
        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarPath.step
    @pulsarlua function AStarPath.step
    @desc Advances every member one node along the planned route. Rechecks current positions, traversal permission, destination passability and each budget before changing state. A failed check or completed route returns false with no movement, payment or callbacks. Success moves and charges the entire group, advances the path and refreshes preview before callbacks. Reentrant movement is blocked until notifications finish. Callback errors do not undo success: remaining notifications are attempted and the first error is rethrown.
    @ret boolean bMoved Whether the group advanced one node.
    @ex
    local oSystem = AStar();
    local oMap    = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 2, 1);
    local oStart  = oMap.getNode("ground", 1, 1);
    local oRover  = oStart.createRover();
    oRover.getMovePointPool().set(10, Pool.ASPECT.MAX);
    oRover.getMovePointPool().setFull();
    local oPath = AStar.Path(oStart, oMap.getNode("ground", 2, 1), oRover);
    assert(oPath.step() and oRover.getMovePointPool().get() == 0);
    assert(not oPath.step()); --already at the destination
    !]]
    step = function(this, cdat)
        local pri          = cdat.pri;
        local oSource      = pri.nodes[pri.currentStep];
        local oDestination = pri.nodes[pri.currentStep + 1];
        local tPayments    = {};
        local tCallbacks   = {};
        local bRet         = pri.found and not pri.stepping and oDestination ~= nil;

        if (bRet) then
            for _, oRover in ipairs(pri.rovers) do
                local tRover = _tRoverData[oRover];

                if (tRover.moving or tRover.owner ~= oSource) then
                    bRet = false;
                    break;
                end
            end
        end

        if (bRet) then
            bRet = oSource.canTraverseTo(oDestination, pri.rovers) and oDestination.isPassable(pri.rovers);
        end

        if (bRet) then
            local tCosts = oDestination.getEntryCosts(pri.rovers);

            for _, oRover in ipairs(pri.rovers) do
                local tRover  = _tRoverData[oRover];
                local oPoints = tRover.movePoints;
                tPayments[oRover] = tCosts[oRover];

                if (oPoints.get() < tCosts[oRover]) then
                    bRet = false;
                    break;
                end

                tCallbacks[#tCallbacks + 1] = {rover = oRover, callbacks = {tRover.onExitNode, tRover.onEnterNode, tRover.onMove}};
            end
        end

        if (bRet) then
            pri.stepping = true;

            for _, oRover in ipairs(pri.rovers) do
                _tRoverData[oRover].moving = true;
            end

            local fOnStep = pri.onStep;
            local bCommitted, sError = pcall(Pool.withDeferredEvents, function()
                --Commit all occupancy and positions before any payment can notify.
                for _, oRover in ipairs(pri.rovers) do
                    _tNodeData[oSource].rovers[oRover] = nil;
                    _tNodeData[oDestination].rovers[oRover] = true;
                    _tRoverData[oRover].owner = oDestination;
                end

                pri.lastStep    = pri.currentStep;
                pri.currentStep = pri.currentStep + 1;

                for _, oRover in ipairs(pri.rovers) do
                    _tRoverData[oRover].movePoints.adjust(-tPayments[oRover]);
                end

                previewPath(pri);
            end);

            if (bCommitted) then
                sError = nil;
            end

            --Each callback sees the whole group's committed state.
            for _, tEntry in ipairs(tCallbacks) do
                for _, fCallback in ipairs(tEntry.callbacks) do
                    local bCalled, sCallbackError = pcall(fCallback, tEntry.rover, oSource, oDestination);

                    if (not bCalled and sError == nil) then
                        sError = sCallbackError;
                    end
                end
            end

            if (rawtype(fOnStep) == "function") then
                local bCalled, sCallbackError = pcall(fOnStep, this, pri.roversDecoy, pri.currentStep, pri.totalSteps, oDestination, oSource);

                if (not bCalled and sError == nil) then
                    sError = sCallbackError;
                end
            end

            for _, oRover in ipairs(pri.rovers) do
                _tRoverData[oRover].moving = false;
            end

            pri.stepping = false;

            if (sError ~= nil) then
                error(sError, 0);
            end
        end

        return bRet;
    end,
},
nil,
false,
nil
);


--Dox comments provide the current API documentation.
--The earlier infused-help draft below is retained for reference.
--[[create the help for this module
local tAStarRoverInfo = {};
local tAStarRoverHelp = {
    addDeniedType = {
                    title = "addDeniedType",
                    desc = "Adds an item to the list of types that are denied entry to a node this rover occupies."..
                        "\nAdding an asterisk ('*') will deny all types."..
                        "\nNote. No matter what types a rover denies, it cannot deny entry to other rovers which share one of its own types."..
                        "\nIn addition, a rover cannot add a denied type that matches one of its own types.",
                    example = "",
                },
};
local fAStarRoverHelp = infusedhelp(tAStarRoverInfo, tAStarRoverHelp);]]

                --[[██████╗░░█████╗░██╗░░░██╗███████╗██████╗░
                    ██╔══██╗██╔══██╗██║░░░██║██╔════╝██╔══██╗
                    ██████╔╝██║░░██║╚██╗░██╔╝█████╗░░██████╔╝
                    ██╔══██╗██║░░██║░╚████╔╝░██╔══╝░░██╔══██╗
                    ██║░░██║╚█████╔╝░░╚██╔╝░░███████╗██║░░██║
                    ╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝
                    Note. unlike other classes, this one directly accesses/modifies node
                    info without calling node class methods. This design style is allowed
                    since rovers techincally and practically belong to node objects.
                    ]]
local function noOpMoveCallback() end

--[[!
@fqxn CoG.AStar.AStarRover
@desc Represents a unit occupying one node, with individual terrain responses, movement budget, layer permissions and movement callbacks.
!]]
AStarRover = class("AStarRover",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarRover = function(stapub) end,
},
{--PRIVATE
    allowedLayers       = {}, --object and uppercase-name permission overrides
    abhorations         = {}, --unlike most other tables, it's index by aspect name (string)
    abhorationsDecoy    = {},
    affinities          = {},
    affinitiesByName    = {},
    affinitiesDecoy     = {},
    aversions           = {},
    aversionsByName     = {},
    aversionsDecoy      = {},
    deniedTypes         = {}, --used for preventing entry into occupied nodes which contain rovers of these types
    deniedTypesByName   = {},
    deniedTypesDecoy    = {},
    --[[!
    @fqxn CoG.AStar.AStarRover.RetainsPointsOverCycle
    @desc Whether unused movement points carry into the next cycle. Defaults to true. Generates getRetainsPointsOverCycle and setRetainsPointsOverCycle; both methods are final. False clears CURRENT before applying regeneration.
    @ex
    local oSystem = AStar();
    local oMap    = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 1, 1);
    local oRover  = oMap.getNode("ground", 1, 1).createRover(false);
    assert(not oRover.getRetainsPointsOverCycle());
    oRover.setRetainsPointsOverCycle(true);
    assert(oRover.getRetainsPointsOverCycle());
    !]]
    --[[!
    @fqxn CoG.AStar.AStarRover.getRetainsPointsOverCycle
    @pulsarlua function AStarRover.getRetainsPointsOverCycle
    @desc Gets whether unused movement points carry into the next cycle. Defaults to true.
    @ret boolean bRetains Whether leftover points are retained.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oRover.getRetainsPointsOverCycle());
    !]]
    --[[!
    @fqxn CoG.AStar.AStarRover.setRetainsPointsOverCycle
    @pulsarlua function AStarRover.setRetainsPointsOverCycle
    @desc Sets whether unused movement points carry into the next cycle. False clears current points before regeneration on the next rover.cycle call. Does not immediately change movement points.
    @param boolean bRetains The retention setting.
    @ret AStarRover oRover This rover.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.setRetainsPointsOverCycle(false);
    assert(not oRover.getRetainsPointsOverCycle());
    !]]
    RetainsPointsOverCycle__auto_F = true,
    movePoints          = Pool(1, 0), --caller-configurable capacity and regeneration
    onEnterNode         = noOpMoveCallback,
    onExitNode          = noOpMoveCallback,
    moving              = false,
    onMove              = noOpMoveCallback,
    owner               = null,--oAStarNode,
    types               = {}, --the types I am (for example, [FactionName])
    typesByName         = {},
    typesDecoy          = {},
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.AStar.AStarRover.AStarRover
    @desc Creates a rover owned by the supplied node, with neutral affinities and aversions for every aspect in its AStar system and zero movement points.
    @param AStarNode oAStarNode The initial owning node.
    @param boolean|nil bRetainsPointsOverCycle Whether unused points carry into the next cycle; defaults to true.
    @ret AStarRover oRover The new rover.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(type(oRover) == "AStarRover" and oRover.getOwner() == oNode);
    !]]
    AStarRover = function(this, cdat, oAStarNode, bRetainsPointsOverCycle)
        type.assert.custom(oAStarNode, "AStarNode");

        if (bRetainsPointsOverCycle ~= nil) then
            type.assert.custom(bRetainsPointsOverCycle, "boolean");
            cdat.pri.RetainsPointsOverCycle = bRetainsPointsOverCycle;
        end

        local pri = cdat.pri;
        _tRoverData[this] = pri;
        pri.owner    = oAStarNode;
        local oLayer = oAStarNode.getOwner();
        local oMap   = oLayer.getOwner();
        local oAStar = oMap.getOwner();

        --create the proteans for affinities & aversions and booleans for abhorations
        for _, sAspect in pairs(oAStar.aspectNames) do
            --abhorations
            pri.abhorations[sAspect] = false;

            --affinities
            local oAffinity = Protean();
            pri.affinities[#pri.affinities + 1]     = oAffinity;
            pri.affinitiesByName[sAspect]               = oAffinity;

            --aversions
            local oAversion = Protean();
            pri.aversions[#pri.aversions + 1]   = oAversion;
            pri.aversionsByName[sAspect]            = oAversion;
        end

        AStarUtil.setupActualDecoy(pri.abhorations, pri.abhorationsDecoy,   "SETUP ERROR");
        AStarUtil.setupActualDecoy(pri.affinities,  pri.affinitiesDecoy,    "SETUP ERROR");
        AStarUtil.setupActualDecoy(pri.aversions,   pri.aversionsDecoy,     "SETUP ERROR");
        AStarUtil.setupActualDecoy(pri.deniedTypes, pri.deniedTypesDecoy, "Attempt to modify read-only denied types table.");
        AStarUtil.setupActualDecoy(pri.types,       pri.typesDecoy,         "SETUP ERROR");
    end,
    --[[!
    @fqxn CoG.AStar.AStarRover.abhors
    @pulsarlua function AStarRover.abhors
    @desc Checks whether this rover abhors the named aspect. Names are matched in uppercase; an unknown aspect returns false.
    @param string sAspect A nonblank aspect name.
    @ret boolean bAbhors Whether this rover abhors the aspect.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.setAbhors("mud", true);
    assert(oRover.abhors("MUD"));
    !]]
    abhors = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        sAspect = sAspect:upper();
        return cdat.pri.abhorations[sAspect] or false;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.addDeniedType
    @pulsarlua function AStarRover.addDeniedType
    @desc Adds a type denied entry to nodes occupied by this rover. An asterisk denies all unlike types. A type already owned by this rover cannot be denied. Names are stored in uppercase.
    @param string sType A nonblank type name.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.addDeniedType("enemy");
    assert(oRover.hasDeniedType("ENEMY"));
    !]]
    addDeniedType = function(this, cdat, sType)
        type.assert.string(sType, "%S+");
        sType = sType:upper();
        local pri = cdat.pri;

        if (rawtype(sType) == "string" and sType:gsub("%s", "") ~= ""   and
            rawtype(pri.deniedTypesByName[sType]) == "nil"          and
            rawtype(pri.typesByName[sType]) == "nil")               then

            pri.deniedTypes[#pri.deniedTypes + 1]   = sType;
            pri.deniedTypesByName[sType]            = true;
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.addType
    @pulsarlua function AStarRover.addType
    @desc Adds an uppercase rover type unless it is already present or explicitly denied.
    @param string sType A nonblank type name.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.addType("goblin");
    assert(oRover.isType("GOBLIN"));
    !]]
    addType = function(this, cdat, sType)
        type.assert.string(sType, "%S+");
        sType = sType:upper();
        local pri = cdat.pri;

        if (rawtype(sType) == "string" and sType:gsub("%s", "") ~= ""   and
            rawtype(pri.typesByName[sType]) == "nil"                and
            rawtype(pri.deniedTypesByName[sType]) == "nil")         then

            pri.types[#pri.types + 1]   = sType;
            pri.typesByName[sType]          = true;
        end

        return this;
    end,

    --[[allows all types by default.
        same types are always allowed
    ]]
    --[[!
    @fqxn CoG.AStar.AStarRover.allowsEntryTo
    @pulsarlua function AStarRover.allowsEntryTo
    @desc Checks whether another rover may enter a node occupied by this rover. A shared type always allows entry; otherwise the wildcard or a matching denied type blocks entry.
    @param AStarRover other The other rover.
    @ret boolean bAllowed Whether the other rover may enter.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oOther = oNode.createRover();
    oOther.addType("enemy");
    oRover.addDeniedType("enemy");
    assert(not oRover.allowsEntryTo(oOther));
    !]]
    allowsEntryTo = function(this, cdat, other)
        type.assert.custom(other, "AStarRover");
        local bRet         = true;
        local pri          = cdat.pri;
        local tMyTypes     = pri.typesByName;
        local tDeniedTypes = pri.deniedTypesByName;
        local tItsTypes    = cdat.ins[other].pri.typesByName;

        local bSharesType = false;

        --look for a shared type
        for sMyType, _ in pairs(tMyTypes) do

            if (rawtype(tItsTypes[sMyType]) ~= "nil") then
                bSharesType = true;
                break;
            end

        end

        --only look for denied types if this and the other don't share a type
        if (not bSharesType and #pri.deniedTypes > 0) then
            bRet = rawtype(tDeniedTypes["*"]) == "nil";

            --this gets skipped if all (unlike) types are denied
            if (bRet) then

                --look for a denied type
                for sItsType, _ in pairs(tItsTypes) do

                    if (rawtype(tDeniedTypes[sItsType]) ~= "nil") then
                        bRet = false;
                        break;
                    end

                end

            end

        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getAbhorations
    @pulsarlua function AStarRover.getAbhorations
    @desc Gets a read-only view of the aspect abhoration flags, indexed by aspect name.
    @ret table tValues The read-only collection view.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.setAbhors("mud", true);
    assert(oRover.getAbhorations().MUD == true);
    !]]
    getAbhorations = function(this, cdat)
        return cdat.pri.abhorationsDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getAffinity
    @pulsarlua function AStarRover.getAffinity
    @desc Gets the affinity Protean for an aspect by case-insensitive name, or nil when absent.
    @param string sAspect A nonblank aspect name.
    @ret Protean|nil oResponse The aspect response, or nil.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oAffinity = oRover.getAffinity("mud");
    oAffinity.setValue(0.5);
    assert(oNode.getEntryCost(oRover) == 5);
    !]]
    getAffinity = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        sAspect = sAspect:upper();
        return cdat.pri.affinitiesByName[sAspect] or nil;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getAffinites
    @pulsarlua function AStarRover.getAffinites
    @desc Gets a read-only ordered view of the affinity Proteans. Retains the original method spelling.
    @ret table tValues The read-only collection view.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(#oRover.getAffinites() == 1); --original spelling
    !]]
    getAffinites = function(this, cdat)
        return cdat.pri.affinitiesDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getAversion
    @pulsarlua function AStarRover.getAversion
    @desc Gets the aversion Protean for an aspect by case-insensitive name, or nil when absent.
    @param string sAspect A nonblank aspect name.
    @ret Protean|nil oResponse The aspect response, or nil.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oAversion = oRover.getAversion("mud");
    oAversion.setValue(1);
    assert(oNode.getEntryCost(oRover) == 20);
    !]]
    getAversion = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        sAspect = sAspect:upper();
        return cdat.pri.aversionsByName[sAspect] or nil;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getAversions
    @pulsarlua function AStarRover.getAversions
    @desc Gets a read-only ordered view of the aversion Proteans.
    @ret table tValues The read-only collection view.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(#oRover.getAversions() == 1);
    !]]
    getAversions = function(this, cdat)
        return cdat.pri.aversionsDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getAffinities
    @pulsarlua function AStarRover.getAffinities
    @desc Gets the affinity Proteans using the correctly spelled alias for getAffinites.
    @ret table tValues The read-only collection view.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oRover.getAffinities() == oRover.getAffinites());
    !]]
    getAffinities = function(this, cdat)
        return this.getAffinites();
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getDeniedTypes
    @pulsarlua function AStarRover.getDeniedTypes
    @desc Gets a read-only ordered view of the uppercase denied type names.
    @ret table tValues The read-only collection view.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.addDeniedType("enemy");
    assert(oRover.getDeniedTypes()[1] == "ENEMY");
    !]]
    getDeniedTypes = function(this, cdat)
        return cdat.pri.deniedTypesDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getTypes
    @pulsarlua function AStarRover.getTypes
    @desc Gets a read-only ordered view of this rover's uppercase type names.
    @ret table tValues The read-only collection view.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.addType("goblin");
    assert(oRover.getTypes()[1] == "GOBLIN");
    !]]
    getTypes = function(this, cdat)
        return cdat.pri.typesDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getOnEnterNodeCallback
    @pulsarlua function AStarRover.getOnEnterNodeCallback
    @desc Gets the entry callback, or nil when absent.
    @ret function|nil fCallback The installed callback, or nil.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local fCallback = function() end;
    oRover.setOnEnterNodeCallback(fCallback);
    assert(oRover.getOnEnterNodeCallback() == fCallback);
    !]]
    getOnEnterNodeCallback = function(this, cdat)
        return cdat.pri.onEnterNode ~= noOpMoveCallback and cdat.pri.onEnterNode or nil;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getOnExitNodeCallback
    @pulsarlua function AStarRover.getOnExitNodeCallback
    @desc Gets the exit callback, or nil when absent.
    @ret function|nil fCallback The installed callback, or nil.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local fCallback = function() end;
    oRover.setOnExitNodeCallback(fCallback);
    assert(oRover.getOnExitNodeCallback() == fCallback);
    !]]
    getOnExitNodeCallback = function(this, cdat)
        return cdat.pri.onExitNode ~= noOpMoveCallback and cdat.pri.onExitNode or nil;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.setOnMoveCallback
    @pulsarlua function AStarRover.setOnMoveCallback
    @desc Sets the movement callback or clears it for non-function input. Called after a successful committed move, following exit and entry callbacks, with (rover, sourceNode, destinationNode).
    @param function|nil vFunc The callback; non-functions clear it.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local nCalls = 0;
    oRover.setOnMoveCallback(function() nCalls = nCalls + 1; end);
    assert(oRover.move(oMap.getNode("ground", 2, 1), true) and nCalls == 1);
    !]]
    setOnMoveCallback = function(this, cdat, vFunc)
        cdat.pri.onMove = rawtype(vFunc) == "function" and vFunc or noOpMoveCallback;
        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getOnMoveCallback
    @pulsarlua function AStarRover.getOnMoveCallback
    @desc Gets the movement callback, or nil when absent.
    @ret function|nil fCallback The installed callback, or nil.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local fCallback = function() end;
    oRover.setOnMoveCallback(fCallback);
    assert(oRover.getOnMoveCallback() == fCallback);
    !]]
    getOnMoveCallback = function(this, cdat)
        return cdat.pri.onMove ~= noOpMoveCallback and cdat.pri.onMove or nil;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getOwner
    @pulsarlua function AStarRover.getOwner
    @desc Gets the node currently occupied by this rover.
    @ret AStarNode oNode The owning node.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oRover.getOwner() == oNode);
    !]]
    getOwner = function(this, cdat)
        return cdat.pri.owner;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.hasDeniedType
    @pulsarlua function AStarRover.hasDeniedType
    @desc Checks whether an uppercase type name is explicitly in the denied list.
    @param string sType A nonblank type name.
    @ret boolean bDenied Whether the type is explicitly denied.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.addDeniedType("enemy");
    assert(oRover.hasDeniedType("enemy"));
    !]]
    hasDeniedType = function(this, cdat, sType)
        type.assert.string(sType, "%S+");
        sType = sType:upper();
        return  rawtype(sType) == "string"  and
                rawtype(cdat.pri.deniedTypesByName[sType]) ~= "nil";
    end,

    --help = fAStarRoverHelp,

    --[[!
    @fqxn CoG.AStar.AStarRover.setLayerAllowed
    @pulsarlua function AStarRover.setLayerAllowed
    @desc Sets an explicit layer permission. All layers are allowed by default. Layer object overrides take precedence over name overrides; names are matched in uppercase.
    @param AStarLayer|string vLayer A layer instance or nonblank name.
    @param boolean bAllowed Whether entry is allowed.
    @ret AStarRover oRover This rover.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.setLayerAllowed("ground", false);
    assert(not oRover.isAllowedOnLayer("ground"));
    !]]
    setLayerAllowed = function(this, cdat, vLayer, bAllowed)
        type.assert.custom(bAllowed, "boolean");

        if (type(vLayer) == "string") then
            type.assert.string(vLayer, "%S+");
            vLayer = vLayer:upper();
        else
            type.assert.custom(vLayer, "AStarLayer");
        end

        cdat.pri.allowedLayers[vLayer] = bAllowed;
        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.isAllowedOnLayer
    @pulsarlua function AStarRover.isAllowedOnLayer
    @desc Checks layer permission. All layers are allowed by default; an object override takes precedence over its uppercase name override.
    @param AStarLayer|string vLayer A layer object or nonblank name.
    @ret boolean bAllowed Whether entry onto the layer is allowed.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oRover.isAllowedOnLayer(oMap.getLayer("ground")));
    !]]
    isAllowedOnLayer = function(this, cdat, vLayer)
        local tAllowed = cdat.pri.allowedLayers;
        local bRet;

        if (type(vLayer) == "string") then
            type.assert.string(vLayer, "%S+");
            bRet = tAllowed[vLayer:upper()] ~= false;
        else
            type.assert.custom(vLayer, "AStarLayer");

            if (tAllowed[vLayer] ~= nil) then
                bRet = tAllowed[vLayer];
            else
                bRet = tAllowed[vLayer.getName()] ~= false;
            end
        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.isOnLayer
    @pulsarlua function AStarRover.isOnLayer
    @desc Checks the current layer by uppercase name or exact layer identity.
    @param AStarLayer|string vLayer A layer object or nonblank name.
    @ret boolean bOnLayer Whether this rover currently occupies the layer.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    assert(oRover.isOnLayer("ground"));
    !]]
    isOnLayer = function(this, cdat, vLayer)
        local bRet   = false;
        local sType  = type(vLayer);
        local oNode  = cdat.pri.owner;
        local oLayer = oNode.getOwner();

        if (sType == "string") then
            bRet = oLayer.getName() == vLayer:upper();
        elseif (sType == "AStarLayer") then
            bRet = oLayer == vLayer;
        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.isType
    @pulsarlua function AStarRover.isType
    @desc Checks whether this rover has the named type, ignoring case.
    @param string sType A nonblank type name.
    @ret boolean bHasType Whether this rover has the type.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.addType("goblin");
    assert(oRover.isType("goblin"));
    !]]
    isType = function(this, cdat, sType)
        type.assert.string(sType, "%S+");
        sType = sType:upper();
        return  rawtype(sType) == "string"  and
                rawtype(cdat.pri.typesByName[sType]) ~= "nil";
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getMovePoints
    @pulsarlua function AStarRover.getMovePoints
    @desc Gets the current available movement points as a number. Use getMovePointPool to configure capacity, regeneration, reservations or modifiers.
    @ret number nPoints The current movement points.
    @ex
    local oSystem = AStar();
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 1, 1);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(30, Pool.ASPECT.MAX);
    oPoints.set(20);
    assert(oRover.getMovePoints() == 20);
    !]]
    getMovePoints = function(this, cdat)
        local oPoints = cdat.pri.movePoints;
        return oPoints.get();
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.getMovePointPool
    @pulsarlua function AStarRover.getMovePointPool
    @desc Gets the caller-configurable movement-point Pool, initially zero with capacity 1 and zero regeneration. Configure MAX for capacity and CYCLE_FLAT or CYCLE_PERCENT for regeneration. Movement deducts entry cost from CURRENT without changing capacity or regeneration.
    @ret Pool oPoints The movement-point budget.
    @ex
    local oSystem = AStar();
    local oMap    = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 2, 1);
    local oRover  = oMap.getNode("ground", 1, 1).createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(30, Pool.ASPECT.MAX);
    oPoints.set(10, Pool.ASPECT.CYCLE_FLAT);
    oPoints.setFull();
    assert(oPoints.get() == 30);
    assert(oPoints.get(Pool.ASPECT.CYCLE) == 10);
    !]]
    getMovePointPool = function(this, cdat)
        return cdat.pri.movePoints;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.cycle
    @pulsarlua function AStarRover.cycle
    @desc Cycles this rover's movement-point Pool using its configured regeneration and available capacity. When RetainsPointsOverCycle is false, clears unused points before regeneration. Does not move the rover. The caller determines when turns or cycles occur.
    @param number|nil nMultiplier The regeneration multiplier; defaults to 1, as for Pool.cycle.
    @ret AStarRover oRover This rover.
    @ex
    local oSystem = AStar();
    local oMap    = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 1, 1);
    local oRover  = oMap.getNode("ground", 1, 1).createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(30, Pool.ASPECT.MAX);
    oPoints.set(10, Pool.ASPECT.CYCLE_FLAT);
    oRover.cycle();
    assert(oPoints.get() == 10);
    !]]
    cycle = function(this, cdat, nMultiplier)
        if (nMultiplier ~= nil) then
            type.assert.custom(nMultiplier, "number");
            assert(nMultiplier == nMultiplier and nMultiplier ~= math.huge and nMultiplier ~= -math.huge, "Cycle multiplier must be finite.");
        end

        local pri     = cdat.pri;
        local oPoints = pri.movePoints;

        if (not pri.RetainsPointsOverCycle) then
            oPoints.setEmpty();
        end

        oPoints.cycle(nMultiplier);
        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.move
    @pulsarlua function AStarRover.move
    @desc Moves to one destination node in the same AStar system. Ordinary movement requires edge adjacency or an outgoing port permitted by its passage rule; teleportation skips connection and port-rule checks. All moves enforce destination passability and layer permission. Successful moves update occupancy, owner and payment before callbacks. Failed checks change no state and fire no callbacks. No intermediate nodes are visited.
    @param AStarNode oNode The destination.
    @param boolean|nil bDeferCost True skips payment; defaults to false.
    @param boolean|nil bTeleport True bypasses adjacency; defaults to false.
    @ret boolean bMoved Whether the move succeeded.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oPoints = oRover.getMovePointPool();
    oPoints.set(10, Pool.ASPECT.MAX);
    oPoints.setFull();
    assert(oRover.move(oMap.getNode("ground", 2, 1)) and oPoints.get() == 0);
    !]]
    move = function(this, cdat, oNode, bDeferCost, bTeleport)
        type.assert.custom(oNode, "AStarNode");

        if (bDeferCost ~= nil) then
            type.assert.custom(bDeferCost, "boolean");
        end

        if (bTeleport ~= nil) then
            type.assert.custom(bTeleport, "boolean");
        end

        local pri               = cdat.pri;
        local oSource           = pri.owner;
        local oDestinationLayer = oNode.getOwner();

        local bRet = not pri.moving and oSource ~= oNode;

        if (bRet) then
            local oSourceLayer      = oSource.getOwner();
            local oSourceMap        = oSourceLayer.getOwner();
            local oSourceAStar      = oSourceMap.getOwner();
            local oDestinationMap   = oDestinationLayer.getOwner();
            local oDestinationAStar = oDestinationMap.getOwner();

            bRet = oSourceAStar == oDestinationAStar;
        end

        if (bRet) then
            bRet = this.isAllowedOnLayer(oDestinationLayer) and oNode.isPassable(this);
        end

        if (bRet and not bTeleport) then
            bRet = oSource.canTraverseTo(oNode, this);
        end

        if (bRet) then
            local nCost = bDeferCost and 0 or oNode.getEntryCost(this);
            bRet = bDeferCost == true or pri.movePoints.get() >= nCost;

            if (bRet) then
                pri.moving = true;
                _tNodeData[oSource].rovers[this] = nil;
                _tNodeData[oNode].rovers[this] = true;
                pri.owner = oNode;
                local sError;

                if (not bDeferCost) then
                    local bPaid, sPaymentError = pcall(pri.movePoints.adjust, -nCost);

                    if (not bPaid) then
                        sError = sPaymentError;
                    end

                end

                --callbacks observe a committed successful move; failures do not undo movement
                for _, fCallback in ipairs({pri.onExitNode, pri.onEnterNode, pri.onMove}) do

                    if (rawtype(fCallback) == "function") then
                        local bCalled, sCallbackError = pcall(fCallback, this, oSource, oNode);

                        if (not bCalled and sError == nil) then
                            sError = sCallbackError;
                        end

                    end

                end

                pri.moving = false;

                if (sError ~= nil) then
                    error(sError);
                end
            end

        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.moveToLayer
    @pulsarlua function AStarRover.moveToLayer
    @desc Moves to a destination belonging to the specified layer by delegating to move. A mismatched destination returns false. Deferred cost and teleport flags retain the same meaning as move.
    @param AStarLayer oLayer The destination layer.
    @param AStarNode oNode The destination node.
    @param boolean|nil bDeferCost True skips payment; defaults to false.
    @param boolean|nil bTeleport True bypasses adjacency; defaults to false.
    @ret boolean bMoved True if move succeeds; false if ownership does not match or movement is rejected.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oLayer = oMap.getLayer("ground");
    assert(oRover.moveToLayer(oLayer, oLayer.getNode(2, 1), true));
    !]]
    moveToLayer = function(this, cdat, oLayer, oNode, bDeferCost, bTeleport)
        type.assert.custom(oLayer, "AStarLayer");
        type.assert.custom(oNode, "AStarNode");

        local bRet = false;

        if (oNode.getOwner() == oLayer) then
            bRet = this.move(oNode, bDeferCost, bTeleport);
        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.moveToMap
    @pulsarlua function AStarRover.moveToMap
    @desc Moves to a destination in the specified map and layer by delegating to move. Mismatched ownership returns false. The destination must belong to the same AStar system.
    @param AStarMap oMap The destination map.
    @param AStarLayer oLayer The destination layer.
    @param AStarNode oNode The destination node.
    @param boolean|nil bDeferCost True skips payment; defaults to false.
    @param boolean|nil bTeleport True bypasses adjacency; defaults to false.
    @ret boolean bMoved True if move succeeds; false if ownership does not match or movement is rejected.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local oOtherMap = oSystem.newMap("other", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground")}, 1, 1);
    local oLayer = oOtherMap.getLayer("ground");
    assert(oRover.moveToMap(oOtherMap, oLayer, oLayer.getNode(1, 1), true, true));
    !]]
    moveToMap = function(this, cdat, oMap, oLayer, oNode, bDeferCost, bTeleport)
        type.assert.custom(oMap, "AStarMap");
        type.assert.custom(oLayer, "AStarLayer");
        type.assert.custom(oNode, "AStarNode");

        local oLayerMap  = oLayer.getOwner();
        local oNodeLayer = oNode.getOwner();
        local bRet       = false;

        if (oLayerMap == oMap and oNodeLayer == oLayer) then
            bRet = this.move(oNode, bDeferCost, bTeleport);
        end

        return bRet;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.removeDeniedType
    @pulsarlua function AStarRover.removeDeniedType
    @desc Removes a denied type using a case-insensitive lookup. An absent type leaves the list unchanged.
    @param string sType A nonblank type name.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.addDeniedType("enemy");
    oRover.removeDeniedType("enemy");
    assert(not oRover.hasDeniedType("enemy"));
    !]]
    removeDeniedType = function(this, cdat, sType)
        type.assert.string(sType, "%S+");
        sType = sType:upper();
        local pri = cdat.pri;

        if (rawtype(sType) == "string" and sType:gsub("%s", "") ~= "" and
            rawtype(pri.deniedTypesByName[sType]) ~= "nil") then

            table.remove(pri.deniedTypes, table.getindex(pri.deniedTypes, sType));
            pri.deniedTypesByName[sType] = nil;
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.removeType
    @pulsarlua function AStarRover.removeType
    @desc Removes a rover type using a case-insensitive lookup. An absent type leaves the list unchanged.
    @param string sType A nonblank type name.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.addType("goblin");
    oRover.removeType("goblin");
    assert(not oRover.isType("goblin"));
    !]]
    removeType = function(this, cdat, sType)
        type.assert.string(sType, "%S+");
        sType = sType:upper();
        local pri = cdat.pri;

        if (rawtype(sType) == "string" and sType:gsub("%s", "") ~= "" and
            rawtype(pri.typesByName[sType]) ~= "nil") then

                table.remove(pri.types, table.getindex(pri.types, sType));
                pri.typesByName[sType] = nil;
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.setAbhors
    @pulsarlua function AStarRover.setAbhors
    @desc Sets the abhoration flag for a known aspect when the supplied flag is boolean. Unknown aspects leave state unchanged.
    @param string sAspect A nonblank aspect name.
    @param boolean bAbhors The requested abhoration flag.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.setAbhors("mud", true);
    assert(oRover.abhors("mud"));
    !]]
    setAbhors = function(this, cdat, sAspect, bAbhors)
        type.assert.string(sAspect, "%S+");
        sAspect = sAspect:upper();
        local pri          = cdat.pri;
        local tAbhorations = pri.abhorations;

        if (rawtype(tAbhorations[sAspect]) ~= "nil" and
            rawtype(bAbhors) == "boolean") then
            tAbhorations[sAspect] = bAbhors;
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.setOnEnterNodeCallback
    @pulsarlua function AStarRover.setOnEnterNodeCallback
    @desc Sets the entry callback or clears it for non-function input. Called only after a successful committed move, with (rover, sourceNode, destinationNode). Intermediate nodes are not visited by a teleport.
    @param function|nil vFunc The callback; non-functions clear it.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local nCalls = 0;
    oRover.setOnEnterNodeCallback(function() nCalls = nCalls + 1; end);
    assert(oRover.move(oMap.getNode("ground", 2, 1), true) and nCalls == 1);
    !]]
    setOnEnterNodeCallback = function(this, cdat, vFunc)
        local pri   = cdat.pri;
        local sType = rawtype(vFunc);

        if (sType == "function") then
            pri.onEnterNode = vFunc;
        else
            pri.onEnterNode = noOpMoveCallback;
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.setOnExitNodeCallback
    @pulsarlua function AStarRover.setOnExitNodeCallback
    @desc Sets the exit callback or clears it for non-function input. Called only after a successful committed move, with (rover, sourceNode, destinationNode).
    @param function|nil vFunc The callback; non-functions clear it.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    local nCalls = 0;
    oRover.setOnExitNodeCallback(function() nCalls = nCalls + 1; end);
    assert(oRover.move(oMap.getNode("ground", 2, 1), true) and nCalls == 1);
    !]]
    setOnExitNodeCallback = function(this, cdat, vFunc)
        local pri   = cdat.pri;
        local sType = rawtype(vFunc);

        if (sType == "function") then
            pri.onExitNode = vFunc;
        else
            pri.onExitNode = noOpMoveCallback;
        end

        return this;
    end,

    --[[!
    @fqxn CoG.AStar.AStarRover.toggleAbhors
    @pulsarlua function AStarRover.toggleAbhors
    @desc Inverts the abhoration flag of a known aspect. Unknown aspects leave state unchanged.
    @param string sAspect A nonblank aspect name.
    @ret AStarRover oRover This rover, for chaining.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    local oNode = oMap.getNode("ground", 1, 1);
    local oRover = oNode.createRover();
    oRover.toggleAbhors("mud");
    assert(oRover.abhors("mud"));
    !]]
    toggleAbhors = function(this, cdat, sAspect)
        type.assert.string(sAspect, "%S+");
        sAspect = sAspect:upper();
        local pri          = cdat.pri;
        local tAbhorations = pri.abhorations;

        if (rawtype(tAbhorations[sAspect]) ~= "nil") then
            tAbhorations[sAspect] = not tAbhorations[sAspect];
        end

        return this;
    end,
},
nil,   --extending class
true, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);



















            --[[░█████╗░░██████╗████████╗░█████╗░██████╗░
                ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗
                ███████║╚█████╗░░░░██║░░░███████║██████╔╝
                ██╔══██║░╚═══██╗░░░██║░░░██╔══██║██╔══██╗
                ██║░░██║██████╔╝░░░██║░░░██║░░██║██║░░██║
                ╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝]]

--[[!
@fqxn CoG.AStar.AStar
@desc Owns the available aspect names and named maps. Exposes LayerConfig and Path factories for configuring layers and planning group movement.
!]]
return class("AStar",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStar = function(stapub) end,
    LayerConfig = AStarLayerConfig,
    Path        = AStarPath,
    --[[!
    @fqxn CoG.AStar.AStar.Constants
    @desc Read-only static geometry and entry-cost constants. MAP_TYPE_HEX_FLAT, MAP_TYPE_HEX_POINTED, MAP_TYPE_SQUARE, MAP_TYPE_TRIANGLE_FLAT and MAP_TYPE_TRIANGLE_POINTED select geometry. NODE_ENTRY_COST_BASE is 10, MIN is 1, MAX_RATE is 12 and MAX is 120. Existing ASTAR_ global names retain identical values. Costs may be fractional.
    @ex
    assert(AStar.MAP_TYPE_SQUARE == ASTAR_MAP_TYPE_SQUARE);
    assert(AStar.NODE_ENTRY_COST_MAX == 120);
    !]]
    MAP_TYPE_HEX_FLAT__RO = ASTAR_MAP_TYPE_HEX_FLAT,
    MAP_TYPE_HEX_POINTED__RO = ASTAR_MAP_TYPE_HEX_POINTED,
    MAP_TYPE_SQUARE__RO = ASTAR_MAP_TYPE_SQUARE,
    MAP_TYPE_TRIANGLE_FLAT__RO = ASTAR_MAP_TYPE_TRIANGLE_FLAT,
    MAP_TYPE_TRIANGLE_POINTED__RO = ASTAR_MAP_TYPE_TRIANGLE_POINTED,
    NODE_ENTRY_COST_BASE__RO = ASTAR_NODE_ENTRY_COST_BASE,
    NODE_ENTRY_COST_MIN__RO = ASTAR_NODE_ENTRY_COST_MIN,
    NODE_ENTRY_COST_MAX_RATE__RO = ASTAR_NODE_ENTRY_COST_MAX_RATE,
    NODE_ENTRY_COST_MAX__RO = ASTAR_NODE_ENTRY_COST_MAX,
},
{--PRIVATE
    aspectNames         = {}, --a list of all aspects available to this AStar object
    aspectNamesRet      = {}, --decoy table for use by client
    aspectNamesByName   = {},
    maps                = {}, --indexed by map name
    mapsDecoy           = {},
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.AStar.AStar.aspectNames
    @pulsarlua table AStar.aspectNames
    @desc A read-only, case-insensitive lookup of this system's uppercase aspect names. Length gives the aspect count; pairs visits the names in alphabetically sorted numeric order. No aspects may be added after construction.
    @ret table tNames The aspect-name view.
    @ex
    local oSystem = AStar("rock", "mud");
    assert(oSystem.aspectNames.mud == "MUD" and #oSystem.aspectNames == 2);
    local tNames = {};
    for nIndex, sName in pairs(oSystem.aspectNames) do
        tNames[nIndex] = sName;
    end
    assert(tNames[1] == "MUD" and tNames[2] == "ROCK");
    !]]
    aspectNames__RO     = null,
    --[[!
    @fqxn CoG.AStar.AStar.AStar
    @pulsarlua function AStar
    @desc Creates a system with zero or more unique aspect names. Names must be Lua identifiers and are stored in uppercase and sorted alphabetically. Duplicates are rejected without regard to case.
    @param string ... The available aspect names.
    @ret AStar oSystem The new system.
    @ex
    local oSystem = AStar("mud", "rock");
    assert(oSystem.aspectNames.MUD == "MUD" and #oSystem.aspectNames == 2);
    !]]
    AStar = function(this, cdat, ...)
        local pri           = cdat.pri;
        local tInputAspects = {...};
        local tAspects      = {};
        local tSeen         = {};

        for nIndex = 1, select("#", ...) do
            local sAspect = tInputAspects[nIndex];
            type.assert.string(sAspect, "^[%a_][%w_]*$");
            sAspect = sAspect:upper();
            assert(not tSeen[sAspect], "Duplicate aspect name, '"..sAspect.."'.");
            tSeen[sAspect] = true;
            tAspects[#tAspects + 1] = sAspect;
        end

        table.sort(tAspects);

        for nIndex, sAspect in ipairs(tAspects) do
            pri.aspectNames[nIndex] = sAspect;
            pri.aspectNamesByName[sAspect] = sAspect;
        end

        local tPublicAspects = {};
        setmetatable(tPublicAspects, {
            __index = function(t, vKey)
                local sRet;

                if (rawtype(vKey) == "string") then
                    sRet = pri.aspectNamesByName[vKey:upper()];
                end

                return sRet;
            end,
            __len = function(t)
                return #pri.aspectNames;
            end,
            __newindex = function(t, k, v)
                error("Cannot manually add or alter system aspects.");
            end,
            __pairs = function(t)
                return next, pri.aspectNames, nil;
            end,
        });

        cdat.pub.aspectNames = tPublicAspects;
        AStarUtil.setupActualDecoy(pri.maps, pri.mapsDecoy, "Attempt to modify read-only maps table.");
    end,

    --[[!
    @fqxn CoG.AStar.AStar.getMap
    @pulsarlua function AStar.getMap
    @desc Gets a map by its exact, case-sensitive name.
    @param string sName A nonblank map name.
    @ret AStarMap|nil oMap The map, or nil when absent.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oSystem.getMap("world") == oMap and oSystem.getMap("WORLD") == nil);
    !]]
    getMap = function(this, cdat, sName)
        type.assert.string(sName, "%S+");
        return cdat.pri.maps[sName];
    end,

    --[[!
    @fqxn CoG.AStar.AStar.getMaps
    @pulsarlua function AStar.getMaps
    @desc Gets a read-only view of maps indexed by their exact names.
    @ret table tMaps The map view.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oSystem.getMaps().world == oMap);
    !]]
    getMaps = function(this, cdat)
        return cdat.pri.mapsDecoy;
    end,

    --[[!
    @fqxn CoG.AStar.AStar.getNode
    @pulsarlua function AStar.getNode
    @desc Gets a node by exact map name, case-insensitive layer name and native coordinates.
    @param string sMap A nonblank map name.
    @param string sLayer A nonblank layer name.
    @param number nX The integer x coordinate.
    @param number nY The integer y coordinate.
    @ret AStarNode|nil oNode The node, or nil when the map, layer or position is absent.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oSystem.getNode("world", "GROUND", 1, 1) == oMap.getNode("ground", 1, 1));
    !]]
    getNode = function(this, cdat, sMap, sLayer, nX, nY)
        type.assert.string(sMap, "%S+");
        type.assert.string(sLayer, "%S+");
        type.assert.number(nX, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        type.assert.number(nY, false, false, false, true, false, -math.maxinteger, math.maxinteger);
        local oMap = cdat.pri.maps[sMap];
        local oNode;

        if (oMap ~= nil) then
            oNode = oMap.getNode(sLayer, nX, nY);
        end

        return oNode;
    end,

    --[[!
    @fqxn CoG.AStar.AStar.newMap
    @pulsarlua function AStar.newMap
    @desc Creates and registers a named map. Existing exact names return nil without replacing the map. Layer configurations must be nonempty, ordered, uniquely named and use this system's aspects. Native origins default to 1. Hex maps require explicit staggerAxis and staggerIndex settings for neighbor generation, corresponding to Tiled's staggeraxis and staggerindex values. This method does not parse Tiled files.
    @param string sName A nonblank, case-sensitive map name.
    @param number nType A supported map geometry constant.
    @param table tLayers An ordered list of AStar.LayerConfig objects.
    @param number nWidth The positive integer grid width.
    @param number nHeight The positive integer grid height.
    @param table|nil tLayout Optional originX, originY, staggerAxis and staggerIndex.
    @ret AStarMap|nil oMap The new map, or nil when its name already exists.
    @ex
    local oSystem = AStar("mud");
    local oMap = oSystem.newMap("world", ASTAR_MAP_TYPE_SQUARE, {AStar.LayerConfig("ground", "mud")}, 3, 2);
    assert(oMap.getWidth() == 3 and oMap.getHeight() == 2);
    assert(oSystem.newMap("world") == nil); --existing exact name is preserved
    !]]
    newMap = function(this, cdat, sName, nType, tLayers, nWidth, nHeight, tLayout)
        type.assert.string(sName, "%S+");
        local pri = cdat.pri;
        local oMap;

        if (pri.maps[sName] == nil) then
            oMap = AStarMap(this, sName, nType, tLayers, nWidth, nHeight, tLayout);
            pri.maps[sName] = oMap;
        end

        return oMap;
    end,
},
nil,  --extending class
true, --if the class is final
nil   --interface(s) (either nil, or interface(s))
);
