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

local function update(tActual)

    updatePerimeterAndEdges = function(this, cdat)
        local pri            = cdat.pri;
        pri.perimeter        = 0;
        local aVertices      = pri.vertices;
        local nVerticesCount = aVertices.length;

        for i = 1, nVerticesCount do
            local oPoint1 = aVertices[i];
            local oPoint2 = i < nVerticesCount and aVertices[i + 1] or aVertices[1];

            pri.edges[i].setStart(oPoint1, true);
            pri.edges[i].setEnd(oPoint2);

            pri.perimeter = pri.perimeter + pri.edges[i]:getLength();
        end

        pri.edgesCount = #pri.edges;
    end



    updateAnchors = function(this, cdat)
        local pri                   = cdat.pri;
        local nSumX                 = 0;
        local nSumY                 = 0;
        local aVertices             = pri.vertices;
        local nVertices             = aVertices.length;
        local oAnchorTopLeft        = pri.anchors[SHAPE_ANCHOR_TOP_LEFT];
        local oAnchorTopRight       = pri.anchors[SHAPE_ANCHOR_TOP_RIGHT];
        local oAnchorBottomRight    = pri.anchors[SHAPE_ANCHOR_BOTTOM_RIGHT];
        local oAnchorBottomLeft     = pri.anchors[SHAPE_ANCHOR_BOTTOM_LEFT];

        --prep the 'corner' anchor Points
        local tPoint1   = aVertices[1];
        local nPoint1X  = tPoint1.getX();
        local nPoint1Y  = tPoint1.getY();

        --top left, right - bottom left, right
        oAnchorTopLeft.set(nPoint1X, nPoint1Y);
        oAnchorTopRight.set(nPoint1X, nPoint1Y);
        oAnchorBottomRight.set(nPoint1X, nPoint1Y);
        oAnchorBottomLeft.set(nPoint1X, nPoint1Y);

        for x = 1, nVertices do
            --process data for the centroid
            local oPoint    = aVertices[x];
            local nPointX   = oPoint.getX();
            local nPointY   = oPoint.getY();

            nSumX = nSumX + nPointX;
            nSumY = nSumY + nPointY;

            --update the 'corner' anchor Points
            local nAnchorTopLeftX,      nAnchorTopLeftY     = oAnchorTopLeft.get();
            local nAnchorTopRightX,     nAnchorTopRightY    = oAnchorTopRight.get();
            local nAnchorBottomRightX,  nAnchorBottomRightY = oAnchorBottomRight.get();
            local nAnchorBottomLeftX,   nAnchorBottomLeftY  = oAnchorBottomLeft.get();

            --top left, top right, bottom right, bottom left
            oAnchorTopLeft.set(     nPointX < nAnchorTopLeftX       and nPointX or nAnchorTopLeftX,
                                    nPointY < nAnchorTopLeftY       and nPointY or nAnchorTopLeftY);
            oAnchorTopRight.set(    nPointX > nAnchorTopRightX      and nPointX or nAnchorTopRightX,
                                    nPointY < nAnchorTopRightY      and nPointY or nAnchorTopRightY);
            oAnchorBottomRight.set( nPointX > nAnchorBottomRightX   and nPointX or nAnchorBottomRightX,
                                    nPointY > nAnchorBottomRightY   and nPointY or nAnchorBottomRightY);
            oAnchorBottomLeft.set(  nPointX < nAnchorBottomLeftX    and nPointX or nAnchorBottomLeftX,
                                    nPointY > nAnchorBottomLeftY    and nPointY or nAnchorBottomLeftY);
        end

        --update the centroid anchor
        pri.anchors[SHAPE_ANCHOR_CENTROID].x = nSumX / nVertices;--pri.centroid.x;
        pri.anchors[SHAPE_ANCHOR_CENTROID].y = nSumY / nVertices;--pri.centroid.y;
    end




    updateArea = function(this, cdat, pri)--this algorithm doesn't work on complex Polygons, find one which does and check before returning the area
        local pri               = cdat.pri;
        local nSum              = 0;
        local aVertices         = pri.vertices;
        local nVerticesCount    = #aVertices;

        for i = 1, nVerticesCount do
            local oPoint1 = aVertices[i];
            local oPoint2 = i < nVerticesCount and aVertices[i + 1] or aVertices[1];

            nSum = nSum + (oPoint1.getX() * oPoint2.getY() - oPoint1.getY() * oPoint2.getX())
        end

        pri.area = nSum / 2;
        --make sure it's a positive number (since the loop goes clockwise instead of CCW)
        pri.area = pri.area >= 0 and pri.area or -pri.area;
    end




    updateAngles = function(this, cdat)
        local pri                   = cdat.pri;
        pri.interiorAngles          = {};
        pri.exteriorAngles          = {};
        pri.isConcave               = false;
        pri.isRegular               = false;
        local nRegularityAngleMark  = 0;
        local nRegularityEdgeMark   = 0;
        local bRegularityFailed     = false;
        local tEdges                = pri.edges;
        local nEdges                = #pri.edges;


        for nLine = 1, pri.edges.length do --use the number of vertices since it's the same as the number of edges
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
            pri.interiorAngles[nLine] = nTheta;

            --check for concavity
            if (nTheta > 180) then
                pri.isConcave = true;
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
                pri.isRegular = true;
            end

            --get the exterior angle: this allows for negative interior angles so all ext angles == 360 even on concave Polygons
            pri.exteriorAngles[nLine] = 180 - pri.interiorAngles[nLine];
        end

    end

end

return function(tVertices, bSkipFirstUpdate)
    local   tActual,            tDecoy,         tMeta,
            tAnchorsActual,     tAnchorsDecoy,  tAnchorsMeta,
            tEdgesActual,       tEdgesDecoy,    tEdgesMeta,
            tVerticesActual,    tVerticesDecoy, tVerticesMeta;

    local bAutoUpdate = true;
    local nVertices = #tVertices;

    --🅰🅲🆃🆄🅰🅻
    tActual = {
        area        = 0,
        --edges (added later)
        isConcave   = false,
        isRegular   = false,
        perimeter   = 0,
        --[[tweener     = {
            inProgress  = false,
            line        = Line(nil, nil, true),
            pot         = Potentiometer(0, 1, 0, 1, POT_CONTINUITY_NONE),
        },]]
        --vertices (added later)
    };

    --🅰🅽🅲🅷🅾🆁🆂 TODO FINISH
    tAnchorsActual = {
        [_nAnchorTL] = {x = -1,  y = 1},
        [_nAnchorTR] = {x = 1,   y = 1},
        [_nAnchorBR] = {x = 1,   y = -1},
        [_nAnchorBL] = {x = -1,  y = -1},
        [_nAnchorC]  = {x = 0,   y = 0},
    }

    --🆅🅴🆁🆃🅸🅲🅴🆂
    tVerticesActual = {};
    tVerticesDecoy  = {};
    tVerticesMeta   = {

    };

    --🅴🅳🅶🅴🆂
    tEdgesActual    = {};
    tEdgesDecoy     = {};
    tEdgesMeta      = {};

    for nIndex, tVertex in ipairs(tVertices) do        --TODO check order?
        local nNextEdgeIndex    = (nIndex % nVertices) + 1;
        local tNextVertex       = tVertices[nNextEdgeIndex];
        local nX                = tVertex.x;
        local nY                = tVertex.y;
        --copy the vertex
        tVerticesActual[nIndex] = {x = nX, y = nY};
        -- Add line from current vertex to next vertex
        tEdgesActual[nIndex] = line(nX, nY, tNextVertex.x, tNextVertex.y);
    end

    rawsetmetatable(tVerticesDecoy,
    {
        __index = tVerticesActual,
        __newindex = function(t, k, v)

            if (tVerticesActual[k] ~= nil) then
                tVerticesActual[k] = v;
                ---TODO calcs
            end

        end,
    });

    rawsetmetatable(tEdgesDecoy,
    {
        __index = tEdgesActual,
        __newindex = function(t, k, v)

            if (tEdgesActual[k] ~= nil) then
                tEdgesActual[k] = v;
                ---TODO calcs
            end

        end,
    });


    tActual.vertices = tVerticesDecoy;
    tActual.edges    = tEdgesDecoy;



    tDecoy    = {};
    tMeta     = {
        __index     = tActual,
        __newindex  = function(t, k, v)

            if (k == "autoUpdate" and rawtype(v) == "boolean") then
                tActual.autoUpdate = v;
                bAutoUpdate = v;
            end

        end,
        __type      = "primitive",
        __subtype   = "polygon",
    };
    rawsetmetatable(tDecoy, tMeta);

    --update the polygon (if requested)
    if not (bSkipFirstUpdate) then
        --tActual.update();
    end

    --return it
    return tDecoy;
end
