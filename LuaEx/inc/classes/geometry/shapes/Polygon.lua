--[[
Certainly! Here's a succinct bullet-point summary of the differences between regular, irregular, complex, simple, concave, and convex Polygons:

    Regular Polygon:
        All sides are of equal length.
        All interior angles are of equal measure.
        Examples: Equilateral triangle, square, regular pentagon.

    Irregular Polygon:
        Sides can have different lengths.
        Interior angles can have different measures.
        Examples: Rectangle, parallelogram, irregular hexagon.

    Complex Polygon:
        Contains intersecting edges within its interior.
        May have holes or self-intersections.
        Examples: Polygon with holes, star-shaped Polygon.

    Simple Polygon:
        No intersecting edges within its interior.
        Forms a single, continuous boundary.
        Examples: Triangle, rectangle, regular pentagon.

    Concave Polygon:
        Contains at least one interior angle greater than 180 degrees.
        Has at least one "cave" or indentation.
        Examples: Crescent, irregular concave Polygon.

    Convex Polygon:
        No interior angle is greater than 180 degrees.
        No edges intersect within the interior.
        Examples: Regular Polygons, convex quadrilateral.
]]

local tProtectedRepo            = {};
local tPrivate                  = {};

local QUADRANT_I                = QUADRANT_I;
local QUADRANT_II               = QUADRANT_II
local QUADRANT_III              = QUADRANT_III;
local QUADRANT_IV               = QUADRANT_IV;
local QUADRANT_O                = QUADRANT_O;
local QUADRANT_X                = QUADRANT_X;
local QUADRANT_X_NEG            = QUADRANT_X_NEG;
local QUADRANT_Y                = QUADRANT_Y;
local QUADRANT_Y_NEG            = QUADRANT_Y_NEG;
local SHAPE_ANCHOR_COUNT        = SHAPE_ANCHOR_COUNT;
local SHAPE_ANCHOR_TOP_LEFT     = SHAPE_ANCHOR_TOP_LEFT;
local SHAPE_ANCHOR_TOP_RIGHT    = SHAPE_ANCHOR_TOP_RIGHT;
local SHAPE_ANCHOR_BOTTOM_RIGHT = SHAPE_ANCHOR_BOTTOM_RIGHT;
local SHAPE_ANCHOR_BOTTOM_LEFT  = SHAPE_ANCHOR_BOTTOM_LEFT;
local SHAPE_ANCHOR_CENTROID     = SHAPE_ANCHOR_CENTROID;
local SHAPE_ANCHOR_DEFAULT      = SHAPE_ANCHOR_DEFAULT;
local class                     = class;
local deserialize               = deserialize;
local math                      = math;
local pairs                     = pairs;
local ipairs                    = ipairs;
local rawtype                   = rawtype;
local serialize                 = serialize;
local table                     = table;
local tostring                  = tostring;
local type                      = type;


local SIDE_TRIANGLE_DIFFERENTIAL        = 3;
local SIDE_ANGLE_FACTOR_DIFFERENTIAL    = 2;
local SUM_OF_EXTERIOR_ANGLES            = 360;
--[[
list of protected properties
area
anchorPoint
anchors
detector
edges         -
edgesCount
exteriorAngles
interiorAngles
perimeter
sumOfInteriorAngles
vertices     -
verticesCount
x
y

list of protected methods
updatePerimeterAndEdges
updateDetector
updateAnchors
updateArea
updateAngles

]]




return class("Polygon",
{--metamethods
    __tostring = function(this)
        local sRet = "";

        for k, v in pairs(tProtectedRepo[this]) do
            local sVType = type(v);

            if sVType == "number"       or sVType == "Point"     or
               sVType == "Line"         or sVType == "shape"     or
               sVType == "Polygon"      or sVType == "circle"     or
               sVType == "hexagon"      or sVType == "triangle" or
               sVType == "rectangle"    then
                sRet = sRet..tostring(k)..": "..tostring(v).."\r\n";
            end

        end

        return sRet;
    end,
},
{--static public
},
{--private
    anchors = {
        [SHAPE_ANCHOR_TOP_LEFT]         = {x = -1,  y = 1},
        [SHAPE_ANCHOR_TOP_RIGHT]        = {x = 1,   y = 1},
        [SHAPE_ANCHOR_BOTTOM_RIGHT]     = {x = 1,   y = -1},
        [SHAPE_ANCHOR_BOTTOM_LEFT]      = {x = -1,  y = -1},
        [SHAPE_ANCHOR_CENTROID]         = {x = 0,   y = 0},
    },
    anchorIndex = SHAPE_ANCHOR_DEFAULT;--this can be be set to a vertex ID or one of the shape anchor constants
    area        = 0,
    edges       = null, --an array of Lines
    isConcave   = false,
    isRegular   = false,
    perimeter   = 0,
    tweener     = {
        inProgress  = false,
        line        = Line(nil, nil, true),
        pot         = Potentiometer(0, 1, 0, 1, POT_CONTINUITY_NONE),
    },
    vertices    = null, --an array of Points
    --TODO create Points for calualtions which need them. That way, I don't have to create a new Point every calulation
},
--TODO make the constructor protected (once the class system allows it)
{--protected
--[[!
    @fqxn LuaEx.Classes.Geometry.Polygon
    @desc Used for creating various Polygons and handling Point
    detection and detector properties. The child class is responsible
    for creating vertices (upon construction) and storing them
    in the protected property of 'vertices' (a numerically-indexed
    table whose values are Points). The child class is also
    responsible for updating the Polygon whenever changes are
    made to size or position. This is done by calling super:update().
    It is expected, when creating the vertices, that a child class will
    insert them into the table starting with the first vertex and continuing
    around the Polygon clockwise.

    Protected fields and methods:
    anchorIndex
    area                     (number)
    edges                    (numerically-indexed table of Lines)
    perimeter                (number)
    isConcave                (boolean)  NO CHILD CLASS SHOULD MODIFY THIS VALUE;
    isRegular                (boolean)  NO CHILD CLASS SHOULD MODIFY THIS VALUE;
    tweener                    (table)
    vertices                 (numerically-indexed table of Points)
    verticesCount            (number) NO CHILD CLASS SHOULD MODIFY THIS VALUE TODO move to pri
    imporaVertices             (function)
    updateArea                (function)
    updateAnchors             (function)
    updateDetector             (function)
    updatePerimeterAndEdges (function)
]]
    Polygon = function(this, cdat, super, tVertices)
        local pri = cdat.pri;
        local pro = cdat.pro;
        super();

        --check the input
        if (rawtype(tVertices) ~= "table") then
            --TODO THROW ERROR
        end

        local nVertices = #tVertices;

        --create the vertices table
        pri.vertices = {};

        --create the edges table
        pri.edges = {};

        --check the input array data and add the Point values
        for nIndex, tPoint in ipairs(tVertices) do

            if (rawtype(tPoint["x"]) ~= "number" or rawtype(tPoint["y"]) ~= "number") then
                --TODO THROW ERROR
            end

            pri.vertices[nIndex] = oPoint.clone();

            local oStartPoint;
            local oEndPoint;
            local bMakeLine     = nIndex > 1;
            local bOnLastIndex  = nIndex == tVertices.length;

            --create the dLine from this Point to the last
            if (bMakeLine) then
                local nLastIndex = nIndex - 1;
                --determine which Point to use as start and end
                oStartPoint = bOnLastIndex and aVertices[aVertices.length]  or aVertices[nLastIndex];
                oEndPoint   = bOnLastIndex and aVertices[1]                 or aVertices[nIndex];
                --build the Points and the dLine
                pri.edges[nLastIndex] = dLine(oStartPoint.clone(), oEndPoint.clone(), true); --TODO think about if this should be updated or not here
            end

        end

        --create the edges
        --pri.edges       = {};--rawtype(pri.edges)            == "table"     and pri.edges             or {};
        --pri.area        = {};--rawtype(pri.area)             == "number" and pri.area                 or 0;
        --pri.isConcave   = false;
    ---    pri.isRegular   = false;
        --this can be be set to a vertex ID or one of the shape anchor constants
        --pri.anchorIndex = rawtype(pri.anchorIndex)     == "number" and pri.anchorIndex        or SHAPE_ANCHOR_DEFAULT;


        --setup the protected methods TODO IF I decide to pass these, they must be protected...but are they needed?
        --ALSO this will have to be done in a different way as these indices are currently nil
    --[[    pro.updateArea                  = updateArea;
        pro.updateAnchors               = updateAnchors;
        pro.updateDetector              = updateDetector;
        pro.updatePerimeterAndEdges     = updatePerimeterAndEdges;
        pro.updateAngles                = updateAngles;
    ]]
        --update the Polygon (if not skipped)
        if (not bSkipUpdate) then
            pro.updatePerimeterAndEdges();
            pro.updateDetector();
            pro.updateAnchors();
            pro.updateArea();
            pro.updateAngles();
        end

    end,
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
    end,
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
    end,
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

    end,
    updateDetector = function(this, cdat)
        local pri       = cdat.pri;
        pri.detector    = {};

        --calculate the poly
        local tLastPoint = pri.vertices[aVertices.length];
        local nLastX = tLastPoint.x;
        local nLastY = tLastPoint.y;

        for x = 1, aVertices.length do
            local tPoint = pri.vertices[x];
            local nX = tPoint.x;
            local nY = tPoint.y;
            -- Only store non-horizontal edges.
            if nY ~= nLastY then
                local index = #pri.detector;
                pri.detector[index+1] = nX;
                pri.detector[index+2] = nY;
                pri.detector[index+3] = (nLastX - nX) / (nLastY - nY);
            end

            nLastX = nX;
            nLastY = nY;
        end

    end,
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
    end,
},
{--public
    containsCoord = function(this, nX, nY)
        local tFields   = tProtectedRepo[this];
        local tDetector = pri.detector;
        local nDetector = #tDetector;
        local nLastPX   = tDetector[nDetector - 2];
        local nLastPY   = tDetector[nDetector - 1];
        local bInside   = false;

        for index = 1, #tDetector, 3 do
            local nPX = tDetector[index];
            local nPY = tDetector[index+1];
            local nDeltaX_Div_DeltaY = tDetector[index+2];

            if ((nPY > nY) ~= (nLastPY > nY)) and (nX < (nY - nPY) * nDeltaX_Div_DeltaY + nPX) then
                bInside = not bInside;
            end

            nLastPX = nPX;
            nLastPY = nPY;
        end

        return bInside;
    end,
    containsPoint = function(this, oPoint)
        local tFields   = tProtectedRepo[this];
        local tDetector = tFields.detector;
        local nDetector = #tDetector;
        local nLastPX   = tDetector[nDetector - 2];
        local nLastPY   = tDetector[nDetector - 1];
        local bInside   = false;

        for index = 1, #tDetector, 3 do
            local nPX = tDetector[index];
            local nPY = tDetector[index+1];
            local nDeltaX_Div_DeltaY = tDetector[index + 2];

            if ((nPY > oPoint.y) ~= (nLastPY > oPoint.y)) and (oPoint.x < (oPoint.y - nPY) * nDeltaX_Div_DeltaY + nPX) then
                bInside = not bInside;
            end

            nLastPX = nPX;
            nLastPY = nPY;
        end

        return bInside;
    end,
    deserialize = function(this)
        error("COMPLETE THIS")
    end,

    getSumofExteriorAngles = function()
        return SUM_OF_EXTERIOR_ANGLES;
    end,

    --gets the sum of all interior angles
    getSumofInteriorAngles = function(this)
        return tProtectedRepo[this].sumOfInteriorAngles;
    end,

--TODO should these return a copy of the Point?
    getPos = function(this)
        local tFields = tProtectedRepo[this];
        local oRet;

        if (tFields.vertices[tFields.anchorIndex] ~= nil) then--TODO is this right?
            oRet = tFields.vertices[tFields.anchorIndex];
        elseif (tFields.anchors[tFields.anchorIndex] ~= nil) then
            oRet = tFields.anchors[tFields.anchorIndex];
        end

    return oRet;
    end,

    getInteriorAngle = function(this, nVertex)
        return tProtectedRepo[this].interiorAngles[nVertex] or nil;
    end,

    getExteriorAngle = function(this, nVertex)
        return tProtectedRepo[this].exteriorAngles[nVertex] or nil;
    end,

    intersects = function(this, oOther)
        error("This function has not yet been written. Please refrain from using this function for the time being.");
    end,

    isConcave = function(this)--at least one angle that is greater than 180 degrees
        return tProtectedRepo[this].isConcave;
    end,

    isConvex = function(this)--no angle greater than 180 degrees
        return not tProtectedRepo[this].isConcave;
    end,

    isComplex = function(this)--when crossing over itself or has holes
        return false;
    end,

    isIrregular = function(this, oOther)
        return not tProtectedRepo[this].isRegular;
    end,

    isRegular = function(this)--when all sides are equal and all angles are equal
        return tProtectedRepo[this].isRegular;
    end,

    getAnchorIndex = function(this)
        return tProtectedRepo[this].anchorIndex;
    end,

    getArea = function(this)
        return tProtectedRepo[this].area;
    end,
    --TODO should these return a copy of the Point?
    getCentroid = function(this)
        return tProtectedRepo[this].anchors[SHAPE_ANCHOR_CENTROID];
    end,
--TODO should these return a copy
    getEdge = function(this, nIndex)
        return tProtectedRepo[this].edges[nIndex] or nil;
    end,
    --TODO return a copy (yes, because edges cannot be properly modified by the client; they must use the vertices)
    getEdges = function(this)
        return clone(tProtectedRepo[this].edges, false) or nil;
    end,

    getVertex = function(this, nIndex)--TODO check input value
        local oVertex = tProtectedRepo[this].vertices[nIndex];
        return Point(oVertex.x, oVertex.y);
    end,

    --scales the shape out from the centroid (or perhaps I can allow any anchor Point?)
    scale = function(this, nScale)

    end,

    serialize = function(this)
        return serialize.table(tProtectedRepo[this]);
    end,
    --TODO should this auto-update position or at least have an optional argument for that?
    setAnchorIndex = function(this, nIndex)
        local tFields    = tProtectedRepo[this];

        if (tFields.vertices[nIndex] ~= nil or tFields.anchors[nIndex] ~= nil) then
            tFields.anchorIndex = nIndex;
        end

        return this;
    end,

    setPos = function(this, nX, nY)
        local tFields = tProtectedRepo[this];
        local oPivot;
        local nXDelta;
        local nYDelta;

        if (tFields.vertices[tFields.anchorIndex] ~= nil) then
            oPivot = tFields.vertices[tFields.anchorIndex];
        elseif (tFields.anchors[tFields.anchorIndex] ~= nil) then
            oPivot = tFields.anchors[tFields.anchorIndex];
        end

        --get the delta values
        nXDelta = nX - oPivot.x;
        nYDelta = nY - oPivot.y;

        --shift the vertices by the delta values
        for x = 1, tFields.verticesCount do
            local oPoint = tFields.vertices[x];
            oPoint.x = oPoint.x + nXDelta;
            oPoint.y = oPoint.y + nYDelta;
        end

        --update the centroid and anchors
        updateAnchors(tFields);

        return this;
    end,

    setVertex = function(this, nIndex, oPoint)
        local tFields = tProtectedRepo[this];

        if (tFields.vertices[nIndex] ~= nil) then
            tFields.vertices[nIndex].x = oPoint.x;
            tFields.vertices[nIndex].y = oPoint.y;
            tFields:updatePerimeterAndEdges();
            tFields:updateDetector();
            tFields:updateAnchors();
            tFields:updateArea();
            tFields:updateAngles();
        end

        return this;
    end,

    setVertices = function(this, tPoints, nVerticesCount)
        local tFields = tProtectedRepo[this];

        if (#tPoints ~= nVerticesCount) then
            error("Cannot set vertices for shape. Expected #{expected} Points; given #{count} Points." % {expected  = nVerticesCount, count = #tPoints});
        end

        --TODO this function has been updated and, as such, these input arguments are wrong
        tFields:importVertices(tPoints, tFields.verticesCount);
        --TODO doesn't this need updated here?
        return this;
    end,

    translate = function(this, nX, nY)
        local tFields = tProtectedRepo[this];

        --update all vertices
        for nVertex, oVertex in ipairs(tFields.vertices) do
            oVertex.x = oVertex.x + nX;
            oVertex.y = oVertex.y + nY;
        end

        --update all anchors
        for nVertex, oVertex in ipairs(tFields.anchors) do
            oVertex.x = oVertex.x + nX;
            oVertex.y = oVertex.y + nY;
        end

        return this;
    end,

    translateTo = function(this, oPoint)
        local tFields = tProtectedRepo[this];

        --get the anchor Point and find the change in x and y
        local oAnchor = tFields.anchors[tFields.anchorIndex];
        local nDeltaX = oPoint.x - oAnchor.x;
        local nDeltaY = oPoint.y - oAnchor.y;

        --adjust all vertices to reflect that change
        for nVertex, oVertex in ipairs(tFields.vertices) do
            oVertex.x = oVertex.x + nDeltaX;
            oVertex.y = oVertex.y + nDeltaY;
        end

        --update all anchors
        for nVertex, oVertex in ipairs(tFields.anchors) do
            oVertex.x = oVertex.x + nDeltaX;
            oVertex.y = oVertex.y + nDeltaY;
        end

        return this;
    end,

--TODO allow arc tweening
    tween = function(this, oPoint, nStepDistance)
        local tFields     = tProtectedRepo[this];
        local oAnchor     = tFields.anchors[tFields.anchorIndex];

        if (oAnchor.x ~= oPoint.x or oAnchor.y ~= oPoint.y) then
            local tTweener     = tFields.tweener;
            local oPot         = tTweener.pot;
            local oLine     = tTweener.line;

            --setup the tweener if this is the first call
            if not (tTweener.inProgress) then
                tTweener.inProgress = true;
                oLine:setStart(oAnchor, true):setEnd(oPoint);
            end

                    --make sure we don't overstep
            if (nStepDistance > oLine:length()) then
                oAnchor.x = oPoint.x;
                oAnchor.y = oPoint.y;
                tTweener.inProgress = false;
            else

    --WAITING TO FINISH Line:getPointAtDistance method
                --update all vertices


                --update all anchors

                --check if we've arrived

            end

        end

    end,
},
shape,    --extending class
false,   --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
