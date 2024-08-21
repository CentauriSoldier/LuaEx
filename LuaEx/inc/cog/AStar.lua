--[[!
    @fqxn CoG.Classes.AStar
    @desc <p>AStar is an versatile A* pathfinding system designed for detailed game development.
    It has weighted <a href="#LuaEx.CoG.Classes.AStarNode">Nodes</a> that respond to the
    <a href="#LuaEx.CoG.Classes.AStarRover">Rovers</a> moving through them. That is, a
    <b>Node's</b> weight is based not only on the <b>Node</b> properties but also on the
    <b>Rover's</b> affinities or aversions to that node.
    <br>For example, a human walking on solid, flat ground would move much faster than if he were
    walking on a muddy slope.
    <br><br>
    The system uses various private, public and publicly-available classes.
    <h4>Private Classes</h4>
    <ul>
        <li><a href="#LuaEx.CoG.Classes.AStarAspect">AStarAspect</a></li>
        <li><a href="#LuaEx.CoG.Classes.AStarLayer">AStarLayer</a></li>
        <li><a href="#LuaEx.CoG.Classes.AStarMap">AStarMap</a></li>
        <li><a href="#LuaEx.CoG.Classes.AStarNode">AStarNode</a></li>
        <li><a href="#LuaEx.CoG.Classes.AStarRover">AStarRover</a></li>
    </ul>
    <h4>Public Classes</h4>
    <ul>
        <li><a href="#LuaEx.CoG.Classes.AStar">AStar</a></li>
    </ul>
    <h4>Publicly-available Classes</h4>
    <ul>
        <li><a href="#LuaEx.CoG.Classes.AStarLayerConfig">AStarLayerConfig</a></li>
        <li><a href="#LuaEx.CoG.Classes.AStarPath">AStarPath</a></li>
    </ul>
    These two classes are available in <b>AStar's</b> static public table.
    <b>AStar.LayerConfig</b>
    <b>AStar.Path</b>
    TODO usage
    @ex
    local oAStar = AStar("Rock", "Sand", "Marsh");
    local oASLayerConfig = AStar.LayerConfig("Rock", "Sand");
    local oMap = oAStar.newMap("Nirn", ASTAR_MAP_TYPE_HEX_FLAT, {oASLayerConfig}, 40, 40);
!]]


--[[
Alter these to fit your game.
]]
--[[enum("ASTAR", 			{"MAP", "NODE", "PATH", "ROVER"});
enum("ASTAR_LAYER", 	{"SUBTERRAIN", "SUBMARINE", "MARINE", "TERRAIN", "AIR", "SPACE"}, {
    enum("ASTAR_LAYER_SUBTERRAIN", 	{"sd", "sd", "sd", "sd", "sd"}),
    enum("ASTAR_LAYER_SUBMARINE", 	{"PRESSURE", "SALINITY", "sd", "sd", "sd"}),
    enum("ASTAR_LAYER_MARINE", 		{"sd", "sd", "sd", "sd", "sd"}),
    enum("ASTAR_LAYER_TERRAIN", 	{"AQUIFER", "COMPACTION", "DETRITUS", "FORAGEABILITY", "FORESTATION",
                                      "GRADE", "ICINESS", "PALUDALISM", "ROCKINESS", "ROAD", "SNOWINESS",
                                      "TEMPERATURE", "TOXICITY", "VERDURE"}),
    enum("ASTAR_LAYER_AIR", 		{"sd", "sd", "sd", "sd", "sd"}),
    enum("ASTAR_LAYER_SPACE", 		{"sd", "sd", "sd", "sd", "sd"}),
});
]]

--🅲🅾🅽🆂🆃🅰🅽🆃🆂--TODO make this static public values!
constant("ASTAR_MAP_TYPE_HEX_FLAT", 		0);
constant("ASTAR_MAP_TYPE_HEX_POINTED", 		1);
constant("ASTAR_MAP_TYPE_SQUARE", 			2);
constant("ASTAR_MAP_TYPE_TRIANGLE_FLAT", 	3);
constant("ASTAR_MAP_TYPE_TRIANGLE_POINTED", 4);
constant("ASTAR_NODE_ENTRY_COST_BASE", 		10); --the central cost upon which all other costs & cost mechanics are predicated
constant("ASTAR_NODE_ENTRY_COST_MIN", 		1);
constant("ASTAR_NODE_ENTRY_COST_MAX_RATE",	12);
constant("ASTAR_NODE_ENTRY_COST_MAX", 		ASTAR_NODE_ENTRY_COST_BASE * ASTAR_NODE_ENTRY_COST_MAX_RATE);

--🅻🅾🅲🅰🅻🅸🆉🅰🆃🅸🅾🅽
local ASTAR_MAP_TYPE_HEX_FLAT 			= ASTAR_MAP_TYPE_HEX_FLAT;
local ASTAR_MAP_TYPE_HEX_POINTED 		= ASTAR_MAP_TYPE_HEX_POINTED;
local ASTAR_MAP_TYPE_SQUARE 			= ASTAR_MAP_TYPE_SQUARE;
local ASTAR_MAP_TYPE_TRIANGLE_FLAT 		= ASTAR_MAP_TYPE_TRIANGLE_FLAT;
local ASTAR_MAP_TYPE_TRIANGLE_POINTED	= ASTAR_MAP_TYPE_TRIANGLE_POINTED;
local ASTAR_NODE_ENTRY_COST_BASE		= ASTAR_NODE_ENTRY_COST_BASE;
local ASTAR_NODE_ENTRY_COST_MIN 		= ASTAR_NODE_ENTRY_COST_MIN;
local ASTAR_NODE_ENTRY_COST_MAX_RATE 	= ASTAR_NODE_ENTRY_COST_MAX_RATE;
local ASTAR_NODE_ENTRY_COST_MAX 		= ASTAR_NODE_ENTRY_COST_MAX;
local PROTEAN_BASE_BONUS 				= Protean.BASE_BONUS;
local PROTEAN_BASE_PENALTY 				= Protean.BASE_PENALTY;
local PROTEAN_MULTIPLICATIVE_BONUS 		= Protean.MULTIPLICATIVE_BONUS;
local PROTEAN_MULTIPLICATIVE_PENALTY 	= Protean.MULTIPLICATIVE_PENALTY;
local PROTEAN_ADDATIVE_BONUS 			= Protean.ADDATIVE_BONUS;
local PROTEAN_ADDATIVE_PENALTY 			= Protean.ADDATIVE_PENALTY;
local PROTEAN_VALUE_BASE 				= Protean.VALUE_BASE;
local PROTEAN_VALUE_FINAL 				= Protean.VALUE_FINAL;
local PROTEAN_LIMIT_MIN 				= Protean.LIMIT_MIN;
local PROTEAN_LIMIT_MAX 				= Protean.LIMIT_MAX;

local assert		= assert;
local class 		= class;
local math 			= math;
local rawtype 		= rawtype;
local setmetatable	= setmetatable;
local table 		= table;
local type 			= type;
local Protean		= Protean;

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

local DEFAULT_ASPECT_IMPACTOR_BASE_VALUE = 1;


AStarUtil = {
    clampNodeEntryCost = function(nValue)
           local nRet 	= nValue 	>= ASTAR_NODE_ENTRY_COST_MIN and nValue or ASTAR_NODE_ENTRY_COST_MIN;
       nRet 		= nValue 	<= ASTAR_NODE_ENTRY_COST_MAX and nValue or ASTAR_NODE_ENTRY_COST_MAX;
       return nRet;--TODO should this be floored?
    end,
    mapDimmIsValid = function(nValue)
        return rawtype(nValue) 	== "number" and nValue	> 0 and nValue == math.floor(nValue);
    end,
    mapTypeIsValid = function(nType)
        return 	rawtype(nType) == "number" and
            (	nType == ASTAR_MAP_TYPE_HEX_FLAT 		or
                nType == ASTAR_MAP_TYPE_HEX_POINTED 	or
                nType == ASTAR_MAP_TYPE_SQUARE		    or
                nType == ASTAR_MAP_TYPE_HEX_TRIANGLE
            );
    end,
    isNonBlankString = function(vVal)
        return rawtype(vVal) == "string" and vVal:gsub("%s", "") ~= "";
    end,
    layersAreValid = function(tLayers)
        local bRet = false;

        if (rawtype(tLayers) == "table" and #tLayers > 0) then
            bRet = true;

            for k, v in pairs(tLayers) do

                if ( rawtype(k) ~= "number" or not (rawtype(v) == "string" and v:gsub("5s", "") ~= "") ) then
                    bRet = false;
                    break;
                end

            end

        end

        return bRet;
    end,
    setupActualDecoy = function(tActual, tDecoy, sError)
        setmetatable(tDecoy, {
            __index = function(t, k)
                return tActual[k] or nil;
            end,
            __newindex = function(t, k, v)
                error(sError);
            end,
            __len = function()
                return #tActual;
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
@fqxn CoG.Classes.AStarAspect
@desc TODO
!]]
AStarAspect = class("AStarAspect",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarAspect = function(stapub) end,
},
{--PRIVATE
    --[[!
    @fqxn CoG.Classes.AStarAspect.getImpactor
    @desc TODO
    !]]
    Impactor__autoRF	= null,--a percentage referencing the extremity of the aspect (0%-100%)
    --[[!
    @fqxn CoG.Classes.AStarAspect.getName
    @desc TODO
    !]]
    Name__autoRF        = null,
    --[[!
    @fqxn CoG.Classes.AStarAspect.getOwner
    @desc TODO
    !]]
    Owner__autoRF       = null,
},
{--PROTECTED

},
{--PUBLIC
    AStarAspect = function(this, cdat, sName, oAStarNode)
        local pri = cdat.pri;

        type.assert.string(sName, "%S+");
        type.assert.custom(oAStarNode, "AStarNode");

        pri.Name        = sName;
        pri.Owner       = oAStarNode;
        pri.Impactor    = Protean(DEFAULT_ASPECT_IMPACTOR_BASE_VALUE, 0, 0, 0, 0, 0, 0, 0, 1, nil, true); --TODO CHECK VALUES input
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
AStarLayer = class("AStarLayer",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarLayer = function(stapub) end,
},
{--PRIVATE
    --[[!
    @fqxn CoG.Classes.AStarLayer.getID
    @desc TODO
    !]]
    ID__autoRF	  = null,
    --config 	= oConfig,
    --[[!
    @fqxn CoG.Classes.AStarLayer.getOwner
    @desc TODO
    !]]
    Owner__autoRF = null,
    --[[!
    @fqxn CoG.Classes.AStarLayer.getName
    @desc TODO
    !]]
    Name__autoRF  = null,
    nodes 		  = {},
    nodesDecoy	  = {}, --a decoy table for returning to the client
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.Classes.AStarLayer.AStarLayer
    @desc TODO
    !]]
    AStarLayer = function(this, cdat, oAStarMap, nLayerID, oConfig, nWidth, nHeight)
        local pri       = cdat.pri;
        local tNodes    = pri.nodes;

        AStarUtil.setupActualDecoy(	pri.nodes,
                                    pri.nodesDecoy,
                                    "Attempting to modify read-only nodes table for layer, '"..pri.Name.."'.");

        pri.ID      = nLayerID;
        pri.Name    = oConfig.getName();
        pri.Owner   = oAStarMap;
        --get the aspects that will be on the node
        local tAspects = oConfig.getAspects();

        --create the nodes
        for x = 1, nWidth do
            tNodes[x] = {};

            for y = 1, nHeight do
                tNodes[x][y] = AStarNode(this, x, y, tAspects);
            end

        end

    end,
    --[[!
    @fqxn CoG.Classes.AStarLayer.containsRoverAt
    @desc TODO
    !]]
    containsRoverAt = function(this, cdat, oRover, nX, nY)
        local bRet		= false;
        local pri 	= cdat.pri;
        local tNodes 	= pri.nodes;

        if (tNodes[nX] and tNodes[nX][nY]) then
            bRet = tNodes[nX][nY].containsRover(oRover);
        end

        return bRet;
    end,
    --[[!
    @fqxn CoG.Classes.AStarLayer.createRoverAt
    @desc TODO
    !]]
    createRoverAt = function(this, cdat, nX, nY)--TODO assert
        local pri 	= cdat.pri;
        local tNodes 	= pri.nodes;

        if (tNodes[nX] and tNodes[nX][nY]) then
            return tNodes[nX][nY].createRover();
        end

    end,


    --[[!
    @fqxn CoG.Classes.AStarLayer.getNode
    @desc TODO
    !]]
    getNode = function(this, cdat, nX, nY)
        local tNodes = cdat.pri.nodesDecoy[nX];

        if (tNodes) then
            return tNodes[nY] or nil;
        end

    end,

    --[[!
    @fqxn CoG.Classes.AStarLayer.getNodes
    @desc TODO
    !]]
    getNodes = function(this, cdat)
        return cdat.pri.nodesDecoy;
    end,


    --[[!
    @fqxn CoG.Classes.AStarLayer.hasNode
    @desc TODO
    !]]
    hasNode = function(this, cdat, oNode)
        assert(type(oNode) == "AStarNode", "Port must be of type, AStarNode.");
        return oNode.getOwner() == this;
    end,

    --[[!
    @fqxn CoG.Classes.AStarLayer.hasNodeAt
    @desc TODO
    !]]
    hasNodeAt = function(this, cdat, nX, nY)
        local tNodes = cdat.pri.nodes;
        return rawtype(tNodes[nX]) ~= "nil" and rawtype(tNodes[nX][nY]) ~= "nil"; --TODO no need for type checking here,  just check for nil
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
@fqxn CoG.Classes.AStarLayerConfig
@desc TODO
!]]
local AStarLayerConfig = class("AStarLayerConfig",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarLayerConfig = function(stapub) end,
},
{--PRIVATE
    aspects         = {}, --TODO make decoy table for this
    --[[!
    @fqxn CoG.Classes.AStarLayerConfig.getName
    @desc TODO
    !]]
    Name__autoRF	= null,
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.Classes.AStarLayerConfig.AStarLayerConfig
    @desc TODO
    !]]
    AStarLayerConfig = function(this, cdat, sName, ...)
        local tInputAspects = {...} or arg;

        --TODO assertions | also make sure each aspect is in the AStar Object before adding to the layer

        local pri = cdat.pri;
        pri.Name = sName:upper();

        --add all user aspects
        local tAspects = pri.aspects;
        for _, sAspect in pairs(tInputAspects) do
            tAspects[#tAspects + 1] = sAspect:upper();
        end
    end,
    --[[!
    @fqxn CoG.Classes.AStarLayerConfig.getAspect
    @desc TODO
    !]]
    getAspect = function(this, cdat, sAspect)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        return cdat.pri.aspects[sAspect] or nil;
    end,
    --[[!
    @fqxn CoG.Classes.AStarLayerConfig.getAspects
    @desc TODO
    !]]
    getAspects = function(this, cdat)
        return cdat.pri.aspects; --TODO decoy this
    end,
    --[[!
    @fqxn CoG.Classes.AStarLayerConfig.hasAspect
    @desc TODO
    !]]
    hasAspect = function(this, cdat, sAspect)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        return rawtype(cdat.pri.aspects[sAspect] ~= nil);
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
@fqxn CoG.Classes.AStarMap
@desc TODO
!]]
AStarMap = class("AStarMap",
{--METAMETHODS
    __tostring = function(this, cdat)
        local pri = cdat.pri;

        local sRet = pri.Name..' ('..pri.Width.." x "..pri.Height..')';
        sRet = sRet.."\nType: "..pri.Type;
        sRet = sRet.."\nLayers: ";

        for nLayerID, oLayer in pairs(pri.Layers) do
            sRet = sRet.."\n\t"..nLayerID.." ("..oLayer.getName()..'): ';
        end
        --TODO layer and node info

        return sRet;
    end,
},
{--STATIC PUBLIC
    --AStarMap = function(stapub) end,
},
{--PRIVATE
    --[[!
    @fqxn CoG.Classes.AStarMap.getLayers
    @desc TODO
    !]]
    Layers__autoAF	= {},--(ORDERED BY ID)
    layersDecoy		= {},--a decoy table for returning layers to the client
    layersByName	= {},
    --[[!
    @fqxn CoG.Classes.AStarMap.getName
    @desc TODO
    !]]
    Name__autoRF	= null,
    --[[!
    @fqxn CoG.Classes.AStarMap.getOwner
    @desc TODO
    !]]
    Owner__autoRF	= null,
    --[[!
    @fqxn CoG.Classes.AStarMap.getType
    @desc TODO
    !]]
    Type__autoRF	= null,
    --[[!
    @fqxn CoG.Classes.AStarMap.getWidth
    @desc TODO
    !]]
    Width__autoRF	= null,
    --[[!
    @fqxn CoG.Classes.AStarMap.getHeight
    @desc TODO
    !]]
    Height__autoRF  = null,
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.Classes.AStarMap.AStarMap
    @desc TODO
    !]]
    AStarMap = function(this, cdat, oAStar, sName, nMapType, tLayerConfigs, nWidth, nHeight, ...)
        --local tLayerConfigs = arg or {...}; --TODO check the keywords
        local pri = cdat.pri;

        --check the input
        assert(AStarUtil.isNonBlankString(sName), 	"Argument 1. AStarMap name must be a non-blank string.");
        assert(AStarUtil.mapTypeIsValid(nMapType), 	"Argument 2. AStarMap type is invalid.");
        assert(AStarUtil.mapDimmIsValid(nWidth),	"Argument 4. AStarMap width must be a positive integer.");
        assert(AStarUtil.mapDimmIsValid(nHeight),	"Argument 5. AStarMap height must be a positive integer.");

        --TODO assert(#tLayerConfigs > 0)
        --TODO assert(type(oLayerConfigs) == "AStarLayerConfig", 	"Argument 3. must be an AStarLayerConfig object.\nGot type, '"..type(type(tLayerConfig)).."'");

        pri.Name    = sName;
        pri.Owner   = oAStar;
        pri.Type    = nMapType;
        pri.Width   = nWidth;
        pri.Height  = nHeight;


        AStarUtil.setupActualDecoy(	pri.Layers,
                                    pri.layersDecoy,
                                    "Attempting to modifer read-only layers table for map, '"..pri.Name.."'.");

        --create the layers and their nodes
        for nLayerID, oConfig in pairs(tLayerConfigs) do
            --create the actual layer elements
            local oLayer = AStarLayer(this, nLayerID, oConfig, nWidth, nHeight);
            pri.Layers[nLayerID] = oLayer;
            pri.layersByName[oConfig.getName()] = oLayer;
        end

    end,
    --[[!
    @fqxn CoG.Classes.AStarMap.getLayer
    @desc TODO
    !]]
    getLayer = function(this, cdat, sLayer)
        assert(rawtype(sLayer) == "string", "Layer name must be of type string.");
        return cdat.pri.layersByName[sLayer:upper()] or nil;
    end,
    --[[!
    @fqxn CoG.Classes.AStarMap.getNode
    @desc TODO
    !]]
    getNode = function(this, cdat, sLayer, nX, nY)
        local oLayer = cdat.pri.layersByName[sLayer] or nil;

        if (oLayer) then
            return cdat.pri.layersByName[sLayer].getNode(nX, nY);
        end

    end,
    --[[!
    @fqxn CoG.Classes.AStarMap.getSize
    @desc TODO
    !]]
    getSize = function(this, cdat)
        local pri = cdat.pri;
        return {width = pri.width, height = pri.height};
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
--[[!
@fqxn CoG.Classes.AStarNode
@desc TODO
!]]
AStarNode = class("AStarNode",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarNode = function(stapub) end,
},
{--PRIVATE
    aspects 		= {},
    aspectsDecoy	= {},
    aspectsByName 	= {},
    baseCost 		= ASTAR_NODE_ENTRY_COST_BASE,
    isPassable		= true,
    owner			= null, --TODO oAStarLayer,
    ports			= {}, --nodes that are logically but not physically adjacent (indexed by object)
    portsDecoy		= {},
    rovers			= {}, --indexed by object, values are boolean
    roversDecoy 	= {}, --decoy table to return to the client
    type			= null,--TODO oAStarLayer.getOwner().getType(),
    X__autoAF		= 0,
    Y__autoAF		= 0,
},
{--PROTECTED

},
{--PUBLIC
    AStarNode = function(this, cdat, oAStarLayer, nX, nY, tAspects)
        local pri = cdat.pri;

        for nIndex, sAspect in pairs(tAspects) do
            local oAspect 				= AStarAspect(sAspect, this);
            pri.aspects[nIndex] 		= oAspect;
            pri.aspectsByName[sAspect] 	= oAspect;
        end
        print("Creating: "..nX..", "..nY)
        AStarUtil.setupActualDecoy(pri.rovers, 	pri.roversDecoy, 	"Attempting to modifer read-only rovers table for node at x. "..pri.X..", y. "..pri.Y..".");--TODO these messages are static...make them dynamic using cdat
        AStarUtil.setupActualDecoy(pri.aspects, pri.aspectsByName, 	"Attempting to modifer read-only aspects table for node at x. "..pri.X..", y. "..pri.Y..".");
        AStarUtil.setupActualDecoy(pri.ports, 	pri.portsDecoy, 	"Attempting to modifer read-only ports table for node at x. "..pri.X..", y. "..pri.Y..".");
    end,
    addPort = function(this, cdat, oNode)
        assert(type(oNode) == "AStarNode", "Port must be of type, AStarNode.");
        cdat.pri.ports[oNode] = true;
        tRepo[oNode].ports[this] = true;
        return this;
    end,

    containsRover = function(this, cdat, oRover)
        return rawtype(cdat.pri.rovers[oRover]) ~= "nil";
    end,

    createRover = function(this, cdat)
        local pri 			= cdat.pri;
        local oRover 			= AStarRover(this);
        pri.rovers[oRover] 	= true;

        return oRover;
    end,

    getAspect = function(this, cdat, sAspect)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        return cdat.pri.aspectsByName[sAspect] or nil;
    end,

    getAspects = function(this, cdat)
        return cdat.pri.aspectsDecoy;
    end,

    getAspectImpact = function(this, cdat, sAspect)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        local oAspect = cdat.pri.aspectsByName[sAspect] or nil;

        if (oAspect) then
            return oAspect.getImpactor().get();
        end

    end,

    getEntryCost = function(this, cdat, oRover)--TODO set this up for multiple rovers
        assert(type(oRover) == "AStarRover", "Rover must be of type, AStarRover.");
        local pri	= cdat.pri;
        local nBaseCost = tRepo.nodes.baseCost;
        local nRet 	= nBaseCost;

        --iterate over all of this node's aspects
        for sApect, oAspect in pairs(pri.aspectsByName) do
            local nImpact = oAspect.getImpactor().get();

            --operate on this aspect only if it has an impact on the node
            if (nImpact > 0) then
                local tRoverAffinities 	= oRover.getAffinites();
                local tRoverAversions 	= oRover.getAversions();
--[[Let F 	= Final Entry Cost
Let M	= total value of all affinity/aversion values
Let B	= Node base cost
Let Naf	= node affinity value
Let Raf = rover affinity value
Let Rav	= rover aversion value
M = M + B * (Rav - Raf);

F = math.clamp(B + Naf * M, ASTAR_NODE_ENTRY_COST_MIN, ASTAR_NODE_ENTRY_COST_MAX);]]
                --go through the rover's affinities
                --for

            end

        end

        return nRet;
    end,

    getNeighbors = function(this, cdat)
        local pri = cdat.pri;

        if (pri.type == ASTAR_MAP_TYPE_HEX_FLAT) then
        elseif (pri.type == ASTAR_MAP_TYPE_HEX_POINTED) then
        elseif (pri.type == ASTAR_MAP_TYPE_SQUARE) then
        elseif (pri.type == ASTAR_MAP_TYPE_TRIANGLE_FLAT) then
        elseif (pri.type == ASTAR_MAP_TYPE_TRIANGLE_POINTED) then
            --TODO finish this
        end

    end,

    getOwner = function(this, cdat)
        return cdat.pri.owner;
    end,

    getPassable = function(this, cdat)
        return cdat.pri.isPassable;
    end,

    getPorts = function(this, cdat)
        return cdat.pri.portsDecoy;
    end,

    getPos = function(this, cdat)
        local pri = cdat.pri;
        return {x = pri.X, y = pri.Y};
    end,

    getRovers = function(this, cdat)
        return cdat.pri.roversDecoy;
    end,

    hasAspect = function(this, cdat, sAspect)
        local tAspects = cdat.pri.aspectsByName;
        return rawtype(tAspects[sAspect]) ~= "nil";
    end,

    hasPort = function(this, cdat, oNode)
        assert(type(oNode) == "AStarNode", "Port must be of type, AStarNode.");
        return 	type(cdat.pri.ports[oNode] == "AStarPort") and
                type(tRepo[oNode].ports[this] == "AStarPort");
    end,

    hasPorts = function(this, cdat)
        return #cdat.pri.ports > 0;
    end,

    isPassable = function(this, cdat, ...)
        local pri 		= cdat.pri;
        local tAspects		= pri.aspectsByName;
        local tLocalRovers	= pri.rovers;
        local bRet 			= pri.isPassable;

        --TODO check rover var args!!!!

        if (bRet) then
        local tOutRovers = {...} or arg;
        --allow for individual rover args or a table of rovers
        tOutRovers = (type(tOutRovers[1]) == "table") and tOutRovers[1] or tOutRovers;

            for _, oOutRover in pairs(tOutRovers) do
                assert(type(oOutRover) == "AStarRover", "Attempt to check node passability for non-AStarRover. Value given was of type "..type(oOutRover).." at index "..tostring(_)..".")

                --check for abhorations
                for __, oAspect in pairs(tAspects) do

                    if (oAspect.getImpactor().get() > 0) then

                        if (oOutRover.abhors(oAspect.getName())) then
                            bRet = false;
                            break;
                        end

                    end

                end

                if (bRet) then

                    --check for disallowed rover types
                    for oLocalRover, ___ in pairs(tLocalRovers) do

                        if not (oLocalRover.allowsEntryTo(oOutRover)) then
                            bRet = false;
                            break;
                        end

                    end

                end

            end

        end

        return bRet;
    end,

    removePort = function(this, cdat, oNode)
        assert(type(oNode) == "AStarNode", "Port must be of type, AStarNode.");

        if (cdat.pri.ports[oNode] and tRepo[oNode].ports[this]) then
            cdat.pri.ports[oNode] = nil;
            tRepo[oNode].ports[this] = nil;
        end

        return this;
    end,

    setPassable = function(this, cdat, bPassable)

        if (rawtype(bPassable) == "boolean") then
            cdat.pri.isPassable = bPassable;
        end

    end,

    togglePassable = function(this, cdat)
        cdat.pri.isPassable = not cdat.pri.isPassable;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);




--TODO account for caves/portals/etc. when doing pathfinding...add this functionality
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
    Let F 	= Final Entry Cost
    Let M	= total value of all affinity/aversion values
    Let B	= Node base cost
    Let Naf	= node affinity value
    Let Raf = rover affinity value
    Let Rav	= rover aversion value
    M = M + B * (Rav - Raf);

    F = math.clamp(B + Naf * M, ASTAR_NODE_ENTRY_COST_MIN, ASTAR_NODE_ENTRY_COST_MAX);


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

AStarPath = class("AStarPath",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarPath = function(stapub) end,
},
{--PRIVATE
    cost 		= {}, --indexed by rover object | values are cost for each rover
    currentStep	= 1, --refers to the nodes table index
    lastStep	= -1,
    nodes 		= {},
    notesDecoy	= {},
    onStep		= nil, --client-defined function or nil
    rovers 		= {},
    roversDecoy	= {},
    totalSteps	= {},
},
{--PROTECTED

},
{--PUBLIC
    AStarPath = function(this, cdat, oStartNode, oEndNode, ...)
        local tRovers = {...} or arg;
        tRovers = (type(tRovers[1]) == "table") and tRovers[1] or tRovers;

        --TODO check the rovers table
        --TODO make sure the listed rovers are at the starting node


        --get the layer nodes
        local oLayer 	= oStartNode.getOwner();
        local tNodes	= oLayer.getNodes();

        --setup the pathfinding table
        local tData 	= {};

        for _, oNode in pairs(tNodes) do
            tData[oNode] = {
                f			= 0, -- g + h
                g			= 0, --distance from start
                h			= 0, --distance to destination
                previous	= nil,
            };
        end

        --create the lists
        local tOpen 	= {};
        local tClosed 	= {};

        local oCurrent	= oStartNode;
    end,
    getCost = function(this, cdat, oRover)

    end,

    getCostTotal = function(this, cdat)

    end,

    getNextNode = function(this, cdat)

    end,

    getNodes = function(this, cdat)

    end,

    getNodeCount = function(this, cdat)

    end,

    getRovers = function(this, cdat)

    end,

    setOnStepCallback = function(this, cdat, fFunc)

        if (type(fFunc) == "function") then
            cdat.pri.onStep = fFunc;
        else
            cdat.pri.onStep = nil;
        end

        return this;
    end,

    step = function(this, cdat) --TODO finish this
        local pri = cdat.pri;

        if (pri.onStep) then
            local oCurrentStep 	= pri.nodes[pri.currentStep] 	or nil;
            local oLastStep 	= pri.nodes[pri.lastStep] 		or nil;

            onStep(	this, 					pri.roversDecoy,
                    pri.currentStep,	pri.totalSteps,
                    oCurrentStep, 			oLastStep);
        end


    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);






--TODO move help to another module for readability (and pull the data in here)
--TODO on second thought, why not parse this file for dox (or dox-lie) text and create the help fro that?
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
AStarRover = class("AStarRover",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStarRover = function(stapub) end,
},
{--PRIVATE
    allowedLayers		= {}, --TODO finish this and allow rovers to move layers (and maps?)
    abhorations			= {}, --unlike most other tables, it's index by aspect name (string)
    abhorationsDecoy	= {},
    affinities 			= {},
    affinitiesByName	= {},
    affinitiesDecoy 	= {},
    aversions	 		= {},
    aversionsByName	 	= {},
    aversionsDecoy 		= {},
    deniedTypes			= {}, --used for preventing entry into occupied nodes which contain rovers of these types
    deniedTypesByName	= {},
    deniedTypesDecoy	= {},
    movePoints			= Protean(),--TODO finsih this!!!!!!
    onEnterNode			= nil,
    onExitNode			= nil,
    owner 				= null,--oAStarNode,
    types				= {}, --the types I am (for example, [FactionName])
    typesByName			= {},
    typesDecoy			= {},
},
{--PROTECTED

},
{--PUBLIC
    AStarRover = function(this, cdat, cdat, oAStarNode)
        local pri 	= cdat.pri;
        local oLayer 	= oAStarNode.getOwner();
        local oMap 		= oLayer.getOwner();
        local oAStar	= oMap.getOwner();

        --create the proteans for affinities & aversions and booleans for abhorations
        for _, sAspect in pairs(oAStar.aspectNames) do
            --abhorations
            pri.abhorations[sAspect] = false;

            --affinities
            local oAffinity = protean();
            pri.affinities[#pri.affinities + 1] 	= oAffinity;
            pri.affinitiesByName[sAspect] 				= oAffinity;

            --aversions
            local oAversion = protean();
            pri.aversions[#pri.aversions + 1]	= oAversion;
            pri.aversionsByName[sAspect]	 		= oAversion;
        end

        AStarUtil.setupActualDecoy(pri.abhorations, pri.abhorationsDecoy, 	"SETUP ERROR");
        AStarUtil.setupActualDecoy(pri.affinities, 	pri.affinitiesDecoy, 	"SETUP ERROR");
        AStarUtil.setupActualDecoy(pri.aversions, 	pri.aversionsDecoy,		"SETUP ERROR");
        AStarUtil.setupActualDecoy(pri.types, 		pri.typesDecoy,			"SETUP ERROR");
    end,
    abhors = function(this, cdat, sAspect)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        return cdat.pri.abhorations[sAspect] or false;
    end,

    addDeniedType = function(this, cdat, sType)
        local pri = cdat.pri;

        if (rawtype(sType) == "string" and sType:gsub("%s", "") ~= "" 	and
            rawtype(pri.deniedTypesByName[sType]) == "nil"			and
            rawtype(pri.typesByName[sType]) == "nil") 				then

            pri.deniedTypes[#pri.deniedTypes + 1] 	= sType;
            pri.deniedTypesByName[sType] 			= true;
        end

        return this;
    end,

    addType = function(this, cdat, sType)
        local pri = cdat.pri;

        if (rawtype(sType) == "string" and sType:gsub("%s", "") ~= "" 	and
            rawtype(pri.typesByName[sType]) == "nil"				and
            rawtype(pri.deniedTypesByName[sType]) == "nil") 		then

            pri.types[#pri.types + 1] 	= sType;
            pri.typesByName[sType] 			= true;
        end

        return this;
    end,

    --[[allows all types by default.
        same types are always allowed
    ]]
    allowsEntryTo = function(this, cdat, other) --TODO finish
        assert(type(other) == "AStarRover", "Attempt to check entry allowance on non-AStarRover type. Value given was of type "..rawtype(other)..".");
        local bRet 			= true;
        local pri 		    = cdat.pri;
        local tMyTypes		= pri.typesByName;
        local tDeniedTypes 	= pri.deniedTypesByName;
        local tItsTypes		= cdat.ins[other].typesByName;

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

    getAbhorations = function(this, cdat)
        return cdat.pri.abhorationsDecoy;
    end,

    getAffinity = function(this, cdat, sAspect)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        return cdat.pri.affinitiesByName[sAspect] or nil;
    end,

    getAffinites = function(this, cdat)
        return cdat.pri.affinitiesDecoy;
    end,

    getAversion = function(this, cdat, sAspect)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        return cdat.pri.aversionsByName[sAspect] or nil;
    end,

    getAversions = function(this, cdat)
        return cdat.pri.aversionsDecoy;
    end,

    getOnMoveCallback = function(this, cdat)
        return cdat.pri.onMove;
    end,

    getOwner = function(this, cdat)
        return cdat.pri.owner;
    end,

    hasDeniedType = function(this, cdat, sType)
        return 	rawtype(sType) == "string" 	and
                rawtype(cdat.pri.deniedTypesByName[sType]) ~= "nil";--TODO why use type here? Why not just check nil?
    end,

    --help = fAStarRoverHelp,

    isAllowedOnLayer = function(this, cdat, vLayer)--TODO finsih this
        local bRet = false;
        local sType = type(vLayer);

        if (sType == "string") then

        elseif (sType == "AStarLayer") then

        end

        return bRet;
    end,

    isOnLayer = function(this, cdat, vLayer)
        local bRet = false;
        local sType = type(vLayer);

        if (sType == "string") then
            bRet = cdat.pri.owner.getOwner().getName() == vLayer:upper();
        elseif (sType == "AStarLayer") then
            bRet = cdat.pri.owner.getOwner().getName() == vLayer.getName();
        end

        return bRet;
    end,

    isType = function(this, cdat, sType)
        return 	rawtype(sType) == "string" 	and
                rawtype(cdat.pri.typesByName[sType]) ~= "nil";
    end,

    move = function(this, cdat, oNode)

    end,

    moveToLayer = function(this, cdat, oLayer, oNode)

    end,

    moveToMap = function(this, cdat, oMap, oLayer, oNode)

    end,

    removeDeniedType = function(this, cdat, sType)--TODO check for type before adding
        local pri = cdat.pri;

        if (rawtype(sType) == "string" and sType:gsub("%s", "") ~= "" and
            rawtype(pri.deniedTypesByName[sType]) ~= "nil") then

            table.remove(pri.deniedTypes, table.getindex(pri.deniedTypes, sType));
            pri.deniedTypesByName[sType] = nil;
        end

        return this;
    end,

    removeType = function(this, cdat, sType)--TODO check for denied type before adding
        local pri = cdat.pri;

        if (rawtype(sType) == "string" and sType:gsub("%s", "") ~= "" and
            rawtype(pri.typesByName[sType]) ~= "nil") then

                table.remove(pri.types, table.getindex(pri.types, sType));
                pri.typesByName[sType] = nil;
        end

        return this;
    end,

    setAbhors = function(this, cdat, sAspect, bAbhors)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        local pri 		= cdat.pri;
        local tAbhorations 	= pri.abhorations;

        if (rawtype(tAbhorations[sAspect]) ~= "nil" and
            rawtype(bAbhors) == "boolean") then
            tAbhorations[sAspect] = bAbhors;
        end

        return this;
    end,

    setOnEnterNodeCallback = function(this, cdat, vFunc)
        local pri 	= cdat.pri;
        local sType 	= rawtype(vFunc);

        if (sType == "function") then
            pri.onEnterNode = vFunc;
        else
            pri.onEnterNode = nil;
        end

        return this;
    end,

    setOnExitNodeCallback = function(this, cdat, vFunc)
        local pri 	= cdat.pri;
        local sType 	= rawtype(vFunc);

        if (sType == "function") then
            pri.onExitNode = vFunc;
        else
            pri.onExitNode = nil;
        end

        return this;
    end,

    toggleAbhors = function(this, cdat, sAspect)--TODO CHECK TYPE AND UPPER THIS PARAMETER
        local pri 		= cdat.pri;
        local tAbhorations 	= pri.abhorations;

        if (rawtype(tAbhorations[sAspect]) ~= "nil") then
            tAbhorations[sAspect] = -tAbhorations[sAspect];
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
@fqxn CoG.Classes.AStar
@desc stuff
!]]
return class("AStar",
{--METAMETHODS

},
{--STATIC PUBLIC
    --AStar = function(stapub) end,
    LayerConfig = AStarLayerConfig,
    Path        = AStarPath,
},
{--PRIVATE
    aspectNames			= {}, --a list of all aspects available to this AStar object
    aspectNamesRet		= {}, --decoy table for use by client
    aspectNamesByName	= {},
    maps 				= {}, --indexed by map name
    mapsDecoy			= {},
},
{--PROTECTED

},
{--PUBLIC
    aspectNames__RO     = null,
    AStar = function(this, cdat, ...)
        local pri           = cdat.pri;
        local tAspectsRAW   = {...} or arg;
        local tAspects      = {};

        --TODO assertions for aspects | must be variable-compliant

        --upper all the aspects
        for nIndex, sAspectRAW in pairs(tAspectsRAW) do
            tAspects[#tAspects + 1] = sAspectRAW:upper();
        end

        --sort the aspects alphabetically
        table.sort(tAspects);

        --add all aspects for the AStar object
        for nIndex, sAspect in pairs(tAspects) do
            pri.aspectNames[nIndex] 		= sAspect;
            pri.aspectNamesByName[sAspect] 	= sAspect;
        end

        -- create the publicly-accesible aspects table
        local tPublicAspect = {};

        --setup the aspectNames metatable
        setmetatable(tPublicAspect, {
            __index = function(t, k)
                local _, kUpper = pcall(string.upper, k);
                return pri.aspectNamesByName[kUpper] or nil;
            end,
            __len = function(t)
                return #pri.aspectNames;
            end,
            __newindex = function(t, k, v)
                error("Cannot manually ad aspects to aspects table nor alter existing ones."); --TODO allow string additions?
            end,
            __pairs = function(t)
                return next, pri.aspectNames, nil;--TODO check this for encapsulation
            end
        });

        cdat.pub.aspectNames = tPublicAspect;

        AStarUtil.setupActualDecoy(pri.maps, pri.mapsDecoy, "Attempt to modify read-only maps table.");

    end,
    getMap = function(this, cdat, sName)
        return cdat.pri.maps[sName] or nil;
    end,

    getMaps = function(this, cdat)
        return cdat.pri.mapsDecoy;
    end,

    getNode = function(this, cdat, sMap, sLayer, nX, nY)
        local oMap = cdat.pri.maps[sMap] or nil;

        if (oMap) then
            return oMap.getNode(sLayer, nX, nY);
        end

    end,

    newMap = function(this, cdat, sName, nType, tLayers, nWidth, nHeight)
        local pri = cdat.pri;
        --TODO assert name
        --create the map (only if doesn't already exist)
        if (rawtype(pri.maps[sName]) == "nil") then
            pri.maps[sName] = AStarMap(this, sName, nType, tLayers, nWidth, nHeight);
            return pri.maps[sName];
        end

    end,
},
nil,  --extending class
true, --if the class is final
nil   --interface(s) (either nil, or interface(s))
);
