local deserialize               = deserialize;
local ipairs                    = ipairs;
local line                      = line;
local math                      = math;
local pairs                     = pairs;
local rawsetmetatable           = rawsetmetatable;
local rawtype                   = rawtype;
local serialize                 = serialize;
local table                     = table;
local tostring                  = tostring;
local type                      = type;

local atan2                     = math.atan2;
local floor                     = math.floor;
local sqrt                      = math.sqrt;
local _nPi                      = math.pi;

local QUADRANT_I                = QUADRANT_I;
local QUADRANT_II               = QUADRANT_II
local QUADRANT_III              = QUADRANT_III;
local QUADRANT_IV               = QUADRANT_IV;
local QUADRANT_O                = QUADRANT_O;
local QUADRANT_X                = QUADRANT_X;
local QUADRANT_X_NEG            = QUADRANT_X_NEG;
local QUADRANT_Y                = QUADRANT_Y;
local QUADRANT_Y_NEG            = QUADRANT_Y_NEG;
local _nAnchorCount             = SHAPE_ANCHOR_COUNT;
local _nAnchorTL                = SHAPE_ANCHOR_TOP_LEFT;
local _nAnchorTR                = SHAPE_ANCHOR_TOP_RIGHT;
local _nAnchorBR                = SHAPE_ANCHOR_BOTTOM_RIGHT;
local _nAnchorBL                = SHAPE_ANCHOR_BOTTOM_LEFT;
local _nAnchorC                 = SHAPE_ANCHOR_CENTROID;
local _nAnchorDefault           = SHAPE_ANCHOR_DEFAULT;

local SIDE_TRIANGLE_DIFFERENTIAL        = 3;
local SIDE_ANGLE_FACTOR_DIFFERENTIAL    = 2;
local SUM_OF_EXTERIOR_ANGLES            = 360;

local function update(tActual, tAnchors, tVertices, tEdges, nVertices, bPerimeterAndEdges, bAnchors, bArea, bAngles)

    --Perimeter And Edges
    if (bPerimeterAndEdges) then
        tActual.perimeter        = 0;

        for nVertex = 1, nVertices do
            local tNewStart = tVertices[nVertex];
            local tNewStop  = nVertex < nVertices and tVertices[nVertex + 1] or tVertices[1];

            local tEdge         = tEdges[nVertex];
            local tStart        = tEdge.start;
            local tStop         = tEdge.stop;
            local nNewStartX    = tNewStart.x
            local nNewStartY    = tNewStart.y
            local nNewStopX     = tNewStop.x
            local nNewStopY     = tNewStop.y

            tStart.x  = nNewStartX;
            tStart.y  = nNewStartY;
            tStop.x   = nNewStopX;
            tStop.y   = nNewStopY;

            tEdge.length    = sqrt( (nNewStopX - nNewStartX) ^ 2 + (nNewStopY - nNewStartY) ^ 2 );
            tActual.perimeter = tActual.perimeter + tEdge.length;
        end

    end


    --Anchors
    if (bAnchors) then
        local nSumX     = 0;
        local nSumY     = 0;
        local tAnchorTL = tAnchors[_nAnchorTL];  -- top left
        local tAnchorTR = tAnchors[_nAnchorTR];  -- top right
        local tAnchorBR = tAnchors[_nAnchorBR];  -- bottom right
        local tAnchorBL = tAnchors[_nAnchorBL];  -- bottom left

        -- Prep the 'corner' anchor points
        local tPoint1   = tVertices[1];
        local nPoint1X  = tPoint1.x;
        local nPoint1Y  = tPoint1.y;

        -- Top left, right - bottom left, right
        tAnchorTL.x = nPoint1X;
        tAnchorTL.y = nPoint1Y;
        tAnchorTR.x = nPoint1X;
        tAnchorTR.y = nPoint1Y;
        tAnchorBR.x = nPoint1X;
        tAnchorBR.y = nPoint1Y;
        tAnchorBL.x = nPoint1X;
        tAnchorBL.y = nPoint1Y;

        for nVertex = 1, nVertices do
            -- Process data for the centroid
            local tPoint    = tVertices[nVertex];
            local nX        = tPoint.x;
            local nY        = tPoint.y;

            nSumX = nSumX + nX;
            nSumY = nSumY + nY;

            -- Update the 'corner' anchor points
            local nTLX, nTLY = tAnchorTL.x, tAnchorTL.y;
            local nTRX, nTRY = tAnchorTR.x, tAnchorTR.y;
            local nBRX, nBRY = tAnchorBR.x, tAnchorBR.y;
            local nBLX, nBLY = tAnchorBL.x, tAnchorBL.y;

            -- Top left, top right, bottom right, bottom left
            tAnchorTL.x = (nX < nTLX) and nX or nTLX;
            tAnchorTL.y = (nY < nTLY) and nY or nTLY;
            tAnchorTR.x = (nX > nTRX) and nX or nTRX;
            tAnchorTR.y = (nY < nTRY) and nY or nTRY;
            tAnchorBR.x = (nX > nBRX) and nX or nBRX;
            tAnchorBR.y = (nY > nBRY) and nY or nBRY;
            tAnchorBL.x = (nX < nBLX) and nX or nBLX;
            tAnchorBL.y = (nY > nBLY) and nY or nBLY;
        end

        local nCenterXY = nSumX / nVertices;
        -- Update the centroid anchor
        tAnchors[_nAnchorC].x = nCenterXY;
        tAnchors[_nAnchorC].y = nCenterXY;
    end




    if (bArea) then--this algorithm doesn't work on complex Polygons, find one which does and check before returning the area
        local nSum = 0;

        for i = 1, nVertices do
            local tVertex1 = tVertices[i];
            local tVertex2 = i < nVertices and tVertices[i + 1] or tVertices[1];

            nSum = nSum + (tVertex1.x * tVertex2.y - tVertex1.y * tVertex2.x)
        end

        local nArea = nSum / 2;
        --make sure it's a positive number (since the loop goes clockwise instead of CCW)
        tActual.area = nArea >= 0 and nArea or -nArea;
    end




    if (bAngles) then
        act.interiorAngles          = {};
        act.exteriorAngles          = {};
        act.isConcave               = false;
        act.isRegular               = false;
        local nRegularityAngleMark  = 0;
        local nRegularityEdgeMark   = 0;
        local bRegularityFailed     = false;
        local tEdges                = act.edges;
        local nEdges                = #act.edges;


        for nLine = 1, act.edges.length do --use the number of vertices since it's the same as the number of edges
            local bIsFirstLine     = nLine == 1;

            --determine the Lines between which the angle will be
            local oLine1 = tEdges[nLine];
            local oLine2 = bIsFirstLine and tEdges[nEdges] or tEdges[nLine - 1];
            --[[create a ghost triangle by creating a third, ghost Line between
            the start of the first Line and the end of the second Line]]
            local oLine3 = dLine(oLine1:getEnd(), oLine2:getStart()); --ghost Line

            --get the length of each Line
            local nLength1 = oLine1.length;
            local nLength2 = oLine2.length;
            local nLength3 = oLine3.length;

            --get the angle opposite the ghost side using law of cosines (c^2 = a^2 + b^2 - 2ab*cos(C))
            local nTheta = math.deg(math.acos((nLength1 ^ 2 + nLength2 ^ 2 - nLength3 ^ 2) / (2 * nLength1 * nLength2)));

            --save the angle
            act.interiorAngles[nLine] = nTheta;

            --check for concavity
            if (nTheta > 180) then
                act.isConcave = true;
            end

            --regularity check init
            if (bIsFirstLine) then
                nRegularityAngleMark     = nTheta;
                nRegularityEdgeMark     = nLength1;
            end

            --regularity check
            if not (bRegularityFailed) then
                --[[check that this angle is the same as
                the last and the side, the same as the last]]
                bRegularityFailed = not (nRegularityAngleMark == nTheta and nRegularityEdgeMark == nLength1);
            end

            --if this is the last Line and all angles/edges are repectively equal
            if (not bRegularityFailed and nLine == nEdges) then
                act.isRegular = true;
            end

            --get the exterior angle: this allows for negative interior angles so all ext angles == 360 even on concave Polygons
            act.exteriorAngles[nLine] = 180 - act.interiorAngles[nLine];
        end

    end

end

return function(tInpVertices, bSkipFirstUpdate)
    local   tActual,            tAnalog,            tDecoy,         tMeta,
            tAnchors,           tAnchorsAnalog,     tAnchorsDecoy,  tAnchorsMeta,
            tEdgesActual,       tEdgesAnalog,       tEdgesDecoy,    tEdgesMeta,
            tVerticesActual,    tVerticesAnalog,    tVerticesDecoy, tVerticesMeta;

    local bAutoUpdate               = true;
    local nAnchorID                 = _nAnchorDefault

    --used for readability of the code when calling 'update'
    local bUpdatePerimeterAndEdges  = true;
    local bUpdateAnchors            = true;
    local bUpdateArea               = true;
    local bUpdateAngles             = true;

    local nVertices = #tInpVertices;

    --🅰🅲🆃🆄🅰🅻
    tActual = {
        anchorID        = _nAnchorDefault, --default anchor index
        area            = 0,
        autoUpdate      = true,
        --edges (added later)
        interiorAngles  = {}, --TODO
        exteriorAngles  = {}, --TODO
        isConcave       = false,
        isRegular       = false,
        perimeter       = 0,
        verticesCount   = nVertices,
        --[[tweener     = {
            inProgress  = false,
            line        = Line(nil, nil, true),
            pot         = Potentiometer(0, 1, 0, 1, POT_CONTINUITY_NONE),
        },]]
        --vertices (added later)
    };

    --🅰🅽🅲🅷🅾🆁🆂 TODO FINISH
    tAnchors = {
        [_nAnchorTL] = {x = -1,  y = 1},
        [_nAnchorTR] = {x = 1,   y = 1},
        [_nAnchorBR] = {x = 1,   y = -1},
        [_nAnchorBL] = {x = -1,  y = -1},
        [_nAnchorC]  = {x = 0,   y = 0},
    };
    tAnchorsDecoy   = { --TODO
        __index = tAnchors,
        __newindex = function(t, k, v) end,
    };
    tAnchorsMeta    = {};
    rawsetmetatable(tAnchorsDecoy, tAnchorsMeta);


    --🆅🅴🆁🆃🅸🅲🅴🆂
    tVertices           = {}; --actual
    tVerticesAnalog     = {}; --where subtables' actuals' decoys are stored, referenced by the decoy
    tVerticesDecoy      = {}; --returned to the user
    tVerticesMeta       = {};

    --🅴🅳🅶🅴🆂
    tEdges          = {}; --actual
    tEdgesAnalog    = {}; --where subtables' actuals' decoys are stored, referenced by the decoy
    tEdgesDecoy     = {}; --returned to the user
    tEdgesMeta      = {};

    for nIndex, tVertex in ipairs(tInpVertices) do        --TODO check order?
        local nX                = tVertex.x;
        local nY                = tVertex.y;
        local nNextEdgeIndex    = (nIndex % nVertices) + 1;
        local tNextVertex       = tInpVertices[nNextEdgeIndex];
        local nNextX            = tNextVertex.x;
        local nNextY            = tNextVertex.y;

        --create the vertex
        local tVertex       = {x = nX, y = nY};
        local tVertexDecoy  = {};
        local tVertexMeta   = {
            __index = tVertex,
            __newindex = function(t, k, v)

                if (tVertex[k] ~= nil) then
                    tVertex[k] = v;
                    --print("updating")
                    update( tActual, tAnchors, tVertices, tEdges, nVertices,
                            bUpdatePerimeterAndEdges,   bUpdateAnchors,
                            bUpdateArea,                not bUpdateAngles);
                end

            end,
            __metatable = false,
        };
        rawsetmetatable(tVertexDecoy, tVertexMeta);
        tVertices[nIndex]       = tVertex;
        tVerticesAnalog[nIndex] = tVertexDecoy;

        -- create line from the current vertex to next vertex
        local tStart        = {x = nX, y = nY};
        local tStartDecoy   = {};
        local tStartMeta    = {
            __index = tStart,
            __newindex = function(t, k, v) end,
        };
        rawsetmetatable(tStartDecoy, tStartMeta);

        local tStop      = {x = nNextX, y = nNextY};
        local tStopDecoy = {};
        local tStopMeta  = {
            __index = tStop,
            __newindex = function(t, k, v) end,
        };
        rawsetmetatable(tStopDecoy, tStopMeta);

        local nLength       = sqrt( (nNextX - nX) ^ 2 + (nNextY - nY) ^ 2 );
        local tEdge         = {start = tStart,      stop = tStop,       length = nLength};
        local tEdgeAnalog   = {start = tStartDecoy, stop = tStopDecoy,  length = nLength};
        local tEdgeDecoy    = {};
        local tEdgeMeta     = {
            __index = tEdgeAnalog,
            __newindex = function(t, k, v) end,
            __pairs = function(t, k)
                return next, tEdgeAnalog, nil;
            end,
        };
        rawsetmetatable(tEdgeDecoy, tEdgeMeta);

        tEdges[nIndex]       = tEdge;
        tEdgesAnalog[nIndex] = tEdgeDecoy;
    end



    rawsetmetatable(tVerticesDecoy,
    {
        __index = tVerticesAnalog,
        __newindex = function(t, k, v) end,
        __pairs = function()
            return next, tVertices, nil;
        end,
        __metatable = false,
    });

    rawsetmetatable(tEdgesDecoy,
    {
        __index = tEdgesAnalog,
        __newindex = function(t, k, v) end,
        __pairs = function(t, k)
            return next, tEdgesAnalog, nil;
        end,
        __metatable = false,
    });


    tActual.anchors     = tAnchorsDecoy;
    tActual.edges       = tEdgesDecoy;
    tActual.translate   = function(nX, nY)

        for nID, tPoint in ipairs(tAnchors) do
            tPoint.x = tPoint.x + nX;
            tPoint.y = tPoint.y + nY;
        end

        for nID, tPoint in ipairs(tVertices) do
            tPoint.x = tPoint.x + nX;
            tPoint.y = tPoint.y + nY;
        end

    end
    tActual.translateTo = function(nToX, nToY)
        local tAnchor = tAnchors[nAnchorID];
        local nDeltaX = nToX - tAnchor.x;
        local nDeltaY = nToY - tAnchor.y;

        for nID, tPoint in ipairs(tAnchors) do
            tPoint.x = tPoint.x + nX;
            tPoint.y = tPoint.y + nY;
        end

        for nID, tPoint in ipairs(tVertices) do
            tPoint.x = tPoint.x + nX;
            tPoint.y = tPoint.y + nY;
        end

    end
    tActual.update      = udpate;
    tActual.vertices    = tVerticesDecoy;

    tDecoy    = {};
    tMeta     = {
        __index     = tActual,
        __newindex  = function(t, k, v)

            if (k == "autoUpdate" and rawtype(v) == "boolean") then
                tActual.autoUpdate = v;
                bAutoUpdate = v;

            elseif (k == "anchorID" and rawtype(v) == "number") then
                local nOldID    = tActual.anchorID;
                local nVal      = floor(v);
                nVal            = ( nVal > 0 and nVal <= _nAnchorCount) and
                                    nVal or tActual.anchorID;

                tActual.anchorID    = nVal;
                nAnchorID           = nVal;
                --QUESTION SHOULD I AUTO UPDATE HERE?

            elseif (k == "x") then--TODO --sort of translate function

            end

        end,
        __type      = "primitive",
        __subtype   = "polygon",
    };
    rawsetmetatable(tDecoy, tMeta);
    --TODO add traslate and translateTo methods
    --update the polygon (if requested)
    if not (bSkipFirstUpdate) then
        --tActual.update();
    end

    --return it
    return tDecoy;
end
