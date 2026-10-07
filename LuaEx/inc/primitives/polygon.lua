local rawsetmetatable = rawsetmetatable;
local rawtype = rawtype;
local error = error;
local tostring = tostring;
local select = select;
local pairs = pairs;
local abs = math.abs;
local max = math.max;
local min = math.min;
local sqrt = math.sqrt;
local atan2 = math.atan2;
local floor = math.floor;
local _nPi = math.pi;
local _nTau = 2 * _nPi;
local _nHuge = math.huge;
local _nTolerance = 1e-12;
local _nAnchorTL = SHAPE_ANCHOR_TOP_LEFT;
local _nAnchorTR = SHAPE_ANCHOR_TOP_RIGHT;
local _nAnchorBR = SHAPE_ANCHOR_BOTTOM_RIGHT;
local _nAnchorBL = SHAPE_ANCHOR_BOTTOM_LEFT;
local _nAnchorC = SHAPE_ANCHOR_CENTROID;
local _nAnchorDefault = SHAPE_ANCHOR_DEFAULT;

--[[!
@fqxn LuaEx.Primitives.polygon.Functions.validateNumber
@desc Rejects nonnumeric, infinite and NaN values before mutation.
!]]
local function validateNumber(vInput)
    if (rawtype(vInput) ~= "number" or vInput ~= vInput or
        vInput == _nHuge or vInput == -_nHuge) then
        error("Polygon: coordinates and calculated values must be finite numbers.", 3);
    end
end

--[[!
@fqxn LuaEx.Primitives.polygon.Functions.readVertices
@desc Copies a flat sequence of numeric X/Y pairs. At least three vertices and an even argument count are required.
!]]
local function readVertices(...)
    local nCount = select("#", ...);

    if (nCount < 6 or nCount % 2 ~= 0) then
        error("Polygon: expected at least three complete numeric X/Y pairs.", 3);
    end

    local tInputs = {...};
    local tVertices = {};

    for nIndex = 1, nCount, 2 do
        validateNumber(tInputs[nIndex]);
        validateNumber(tInputs[nIndex + 1]);
        tVertices[#tVertices + 1] = {x = tInputs[nIndex], y = tInputs[nIndex + 1]};
    end

    return tVertices;
end

--[[!
@fqxn LuaEx.Primitives.polygon.Functions.cross
@desc Returns the oriented normalized triangle cross product.
!]]
local function cross(tA, tB, tC)
    return (tB.x - tA.x) * (tC.y - tA.y) -
        (tB.y - tA.y) * (tC.x - tA.x);
end

--[[!
@fqxn LuaEx.Primitives.polygon.Functions.sign
@desc Classifies a normalized value with the geometry tolerance.
!]]
local function sign(nValue)
    if (abs(nValue) <= _nTolerance) then
        return 0;
    end

    return nValue > 0 and 1 or -1;
end

--[[!
@fqxn LuaEx.Primitives.polygon.Functions.onSegment
@desc Tests inclusion on a normalized segment, including endpoints.
!]]
local function onSegment(tA, tB, tPoint)
    return sign(cross(tA, tB, tPoint)) == 0 and
        tPoint.x >= min(tA.x, tB.x) - _nTolerance and
        tPoint.x <= max(tA.x, tB.x) + _nTolerance and
        tPoint.y >= min(tA.y, tB.y) - _nTolerance and
        tPoint.y <= max(tA.y, tB.y) + _nTolerance;
end

--[[!
@fqxn LuaEx.Primitives.polygon.Functions.intersects
@desc Tests normalized segment crossing, touching or overlap.
!]]
local function intersects(tA, tB, tC, tD)
    local nABC = sign(cross(tA, tB, tC));
    local nABD = sign(cross(tA, tB, tD));
    local nCDA = sign(cross(tC, tD, tA));
    local nCDB = sign(cross(tC, tD, tB));

    return (nABC * nABD < 0 and nCDA * nCDB < 0) or
        (nABC == 0 and onSegment(tA, tB, tC)) or
        (nABD == 0 and onSegment(tA, tB, tD)) or
        (nCDA == 0 and onSegment(tC, tD, tA)) or
        (nCDB == 0 and onSegment(tC, tD, tB));
end

--[[!
@fqxn LuaEx.Primitives.polygon.Functions.calculate
@desc Validates one simple, nonzero-area boundary and derives geometry. Coordinates are normalized for intersection tests and centroid calculation. Numerically ambiguous geometry is conservatively rejected at a relative tolerance of 1e-12. Validation compares edge pairs, taking quadratic time in vertex count.
!]]
local function calculate(tVertices)
    local nCount = #tVertices;
    local nOriginX, nOriginY = tVertices[1].x, tVertices[1].y;
    local nScale = 0;
    local tNormalized = {};
    local tBounds = {minX = nOriginX, maxX = nOriginX, minY = nOriginY, maxY = nOriginY};

    for nIndex = 1, nCount do
        local tPoint = tVertices[nIndex];
        validateNumber(tPoint.x);
        validateNumber(tPoint.y);

        local nX = tPoint.x * 1.0 - nOriginX;
        local nY = tPoint.y * 1.0 - nOriginY;
        validateNumber(nX);
        validateNumber(nY);
        tNormalized[nIndex] = {x = nX, y = nY};
        nScale = max(nScale, abs(nX), abs(nY));
        tBounds.minX = min(tBounds.minX, tPoint.x);
        tBounds.maxX = max(tBounds.maxX, tPoint.x);
        tBounds.minY = min(tBounds.minY, tPoint.y);
        tBounds.maxY = max(tBounds.maxY, tPoint.y);
    end

    if (nScale == 0) then
        error("Polygon: vertices must define a nonzero-area boundary.", 3);
    end

    for nIndex = 1, nCount do
        tNormalized[nIndex].x = tNormalized[nIndex].x / nScale;
        tNormalized[nIndex].y = tNormalized[nIndex].y / nScale;
    end

    local nTwiceArea, nCentroidX, nCentroidY = 0, 0, 0;
    local tEdges = {};
    local nPerimeter = 0;

    for nIndex = 1, nCount do
        local nNext = nIndex % nCount + 1;
        local tA, tB = tNormalized[nIndex], tNormalized[nNext];
        local nDX, nDY = tB.x - tA.x, tB.y - tA.y;
        local nLength = sqrt(nDX * nDX + nDY * nDY);

        if (nLength <= _nTolerance) then
            error("Polygon: duplicate or numerically indistinguishable adjacent vertices.", 3);
        end

        local nCross = tA.x * tB.y - tB.x * tA.y;
        nTwiceArea = nTwiceArea + nCross;
        nCentroidX = nCentroidX + (tA.x + tB.x) * nCross;
        nCentroidY = nCentroidY + (tA.y + tB.y) * nCross;

        local nSlope = nDX ~= 0 and nDY / nDX or nil;
        if (nSlope ~= nil) then
            validateNumber(nSlope);
        end

        tEdges[nIndex] = {
            start = tVertices[nIndex],
            stop = tVertices[nNext],
            length = nLength * nScale,
            deltaX = nDX * nScale,
            deltaY = nDY * nScale,
            slope = nSlope,
            slopeIsUndefined = nDX == 0,
            theta = atan2(nDY, nDX),
        };
        nPerimeter = nPerimeter + tEdges[nIndex].length;
    end

    for nIndex = 1, nCount do
        local nNext = nIndex % nCount + 1;
        local nFollowing = nNext % nCount + 1;
        local tA, tB, tC = tNormalized[nIndex], tNormalized[nNext], tNormalized[nFollowing];

        if (sign(cross(tA, tB, tC)) == 0 and
            (onSegment(tA, tB, tC) or onSegment(tB, tC, tA))) then
            error("Polygon: adjacent edges overlap or backtrack.", 3);
        end

        for nOther = nIndex + 1, nCount do
            local nOtherNext = nOther % nCount + 1;

            if (nOther ~= nNext and nOtherNext ~= nIndex and
                intersects(tA, tB, tNormalized[nOther], tNormalized[nOtherNext])) then
                error("Polygon: nonadjacent edges cross, touch or overlap.", 3);
            end
        end
    end

    if (abs(nTwiceArea) <= _nTolerance) then
        error("Polygon: zero-area or numerically ambiguous boundary.", 3);
    end

    local nWinding = nTwiceArea > 0 and 1 or -1;
    local tInterior, tExterior = {}, {};
    local bConcave, bRegular = false, true;

    for nIndex = 1, nCount do
        local nPrevious = (nIndex - 2) % nCount + 1;
        local nNext = nIndex % nCount + 1;
        local tA, tB, tC = tNormalized[nPrevious], tNormalized[nIndex], tNormalized[nNext];
        local nInX, nInY = tB.x - tA.x, tB.y - tA.y;
        local nOutX, nOutY = tC.x - tB.x, tC.y - tB.y;
        local nTurn = atan2(nInX * nOutY - nInY * nOutX,
            nInX * nOutX + nInY * nOutY);
        local nAngle = _nPi - nWinding * nTurn;
        tInterior[nIndex] = nAngle;
        tExterior[nIndex] = _nPi - nAngle;
        bConcave = bConcave or nAngle > _nPi + _nTolerance;

        if (nIndex > 1 and
            (abs(nAngle - tInterior[1]) > _nTolerance or
            abs(tEdges[nIndex].length / tEdges[1].length - 1) > _nTolerance)) then
            bRegular = false;
        end
    end

    local tCentroid = {
        x = nOriginX + nScale * (nCentroidX / (3 * nTwiceArea)),
        y = nOriginY + nScale * (nCentroidY / (3 * nTwiceArea)),
    };
    local tAnchors = {
        [_nAnchorTL] = {x = tBounds.minX, y = tBounds.minY},
        [_nAnchorTR] = {x = tBounds.maxX, y = tBounds.minY},
        [_nAnchorBR] = {x = tBounds.maxX, y = tBounds.maxY},
        [_nAnchorBL] = {x = tBounds.minX, y = tBounds.maxY},
        [_nAnchorC] = tCentroid,
    };
    local tData = {
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.verticesCount
        @desc Read-only number of vertices.
        !]]
        verticesCount = nCount,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.edgesCount
        @desc Read-only number of boundary edges, equal to verticesCount.
        !]]
        edgesCount = nCount,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.area
        @desc Read-only non-negative enclosed area.
        !]]
        area = (abs(nTwiceArea) * 0.5 * nScale) * nScale,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.perimeter
        @desc Read-only sum of boundary edge lengths.
        !]]
        perimeter = nPerimeter,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.isConcave
        @desc Read-only boolean: at least one interior angle exceeds pi.
        !]]
        isConcave = bConcave,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.isConvex
        @desc Read-only boolean: no interior angle exceeds pi; straight boundary subdivisions are allowed.
        !]]
        isConvex = not bConcave,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.isRegular
        @desc Read-only boolean: convex with equal edge lengths and equal interior angles, within the documented relative tolerance.
        !]]
        isRegular = bRegular and not bConcave,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.winding
        @desc Read-only Cartesian orientation: +1 counterclockwise, -1 clockwise.
        !]]
        winding = nWinding,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.sumOfInteriorAngles
        @desc Read-only interior-angle sum in radians, (vertex count - 2) times pi.
        !]]
        sumOfInteriorAngles = (nCount - 2) * _nPi,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.sumOfExteriorAngles
        @desc Read-only orientation-adjusted exterior-angle sum in radians, two pi.
        !]]
        sumOfExteriorAngles = _nTau,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.bounds
        @desc Read-only axis-aligned bounds exposing minX, maxX, minY and maxY.
        !]]
        bounds = tBounds,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.centroid
        @desc Read-only area centroid. Use the selected anchor to move the polygon; the centroid of a concave polygon may lie outside it.
        !]]
        centroid = tCentroid,
        anchors = tAnchors,
        edges = tEdges,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.interiorAngles
        @desc Read-only indexed interior angles in radians, including reflex angles above pi.
        !]]
        interiorAngles = tInterior,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Properties.exteriorAngles
        @desc Read-only indexed exterior angles in radians, defined as pi minus interior angle. Concave vertices have negative exterior angles.
        !]]
        exteriorAngles = tExterior,
    };

    for sKey, vValue in pairs(tData) do
        if (rawtype(vValue) == "number") then
            validateNumber(vValue);
        end
    end

    if (tData.area == 0) then
        error("Polygon: enclosed area is too small to represent.", 3);
    end

    validateNumber(tCentroid.x);
    validateNumber(tCentroid.y);

    for nIndex = 1, nCount do
        validateNumber(tEdges[nIndex].length);
        validateNumber(tEdges[nIndex].deltaX);
        validateNumber(tEdges[nIndex].deltaY);
    end

    return tData;
end

--[[!
@fqxn LuaEx.Primitives.polygon
@desc A simple polygon from at least three flat numeric X/Y pairs. Boundary edges follow input order and close last-to-first. Clockwise and counterclockwise boundaries are accepted; concave shapes are allowed. Crossings, nonadjacent touching, overlapping edges and zero-area shapes are rejected before mutation. No holes or automatic vertex reordering. All geometry is derived except vertices, selected anchor and autoUpdate. Top bounding anchors use minimum Y, preserving screen-coordinate naming. Numeric limits and a normalized 1e-12 tolerance may reject ambiguous inputs. Rawset and debug tools bypass ordinary Lua protections.
@param number ... Consecutive X/Y pairs, at least six numbers and an even count.
@ret primitive A polygon primitive.
@example
local oPolygon = polygon(0, 0, 4, 0, 4, 3, 0, 3);
oPolygon.vertices[1].x = -1;
oPolygon.setVertex(1, -1, -1);
oPolygon.anchorIndex = SHAPE_ANCHOR_TOP_LEFT;
oPolygon.setPosition(10, 20);
!]]
return function(...)
    local tVertices = readVertices(...);
    local tPending = calculate(tVertices);
    local tData = tPending;
    local bDirty = false;
    --[[!
    @fqxn LuaEx.Primitives.polygon.Properties.autoUpdate
    @desc Writable boolean. False defers publication until a read or update call. Geometry candidates are calculated before mutation for validation; reads never repeat calculation.
    !]]
    local bAutoUpdate = true;
    --[[!
    @fqxn LuaEx.Primitives.polygon.Properties.anchorIndex
    @desc Writable existing anchor constant or positive vertex index. Defaults to SHAPE_ANCHOR_DEFAULT, normally the area centroid. Selection changes the positioning reference without moving vertices.
    !]]
    local nAnchorIndex = _nAnchorDefault;

    --[[!
    @fqxn LuaEx.Primitives.polygon.Methods.update
    @desc Publishes dirty candidate geometry once. Candidates are calculated before coordinate mutation for atomic validation; clean reads do not repeat calculations.
    !]]
    local function update()
        if (bDirty) then
            tData = tPending;
            bDirty = false;
        end
    end

    --[[!
    @fqxn LuaEx.Primitives.polygon.Functions.commit
    @desc Validates a complete candidate before publishing any vertex changes.
    !]]
    local function commit(tCandidate)
        local tCandidateData = calculate(tCandidate);

        if (nAnchorIndex > 0 and nAnchorIndex > #tCandidate) then
            error("Polygon: replacement would remove the selected anchor vertex.", 3);
        end

        tVertices = tCandidate;
        tPending = tCandidateData;
        bDirty = true;

        if (bAutoUpdate) then
            update();
        end
    end

    --[[!
    @fqxn LuaEx.Primitives.polygon.Functions.copyVertices
    @desc Copies current internal coordinates for an isolated candidate.
    !]]
    local function copyVertices()
        local tCopy = {};

        for nIndex = 1, #tVertices do
            tCopy[nIndex] = {x = tVertices[nIndex].x, y = tVertices[nIndex].y};
        end

        return tCopy;
    end

    --[[!
    @fqxn LuaEx.Primitives.polygon.Functions.validateIndex
    @desc Validates an integer index into the current vertex sequence.
    !]]
    local function validateIndex(nIndex)
        if (rawtype(nIndex) ~= "number" or nIndex ~= floor(nIndex) or
            nIndex < 1 or nIndex > #tVertices) then
            error("Polygon: invalid vertex index.", 3);
        end
    end

    --[[!
    @fqxn LuaEx.Primitives.polygon.Methods.setVertex
    @desc Copies two numeric coordinates into one vertex and validates the complete candidate polygon once. Invalid edits preserve the old shape.
    @param number nIndex Vertex index.
    @param number nX New X coordinate.
    @param number nY New Y coordinate.
    !]]
    local function setVertex(nIndex, nX, nY)
        validateIndex(nIndex);
        validateNumber(nX);
        validateNumber(nY);

        if (nX == tVertices[nIndex].x and nY == tVertices[nIndex].y) then
            return;
        end

        local tCandidate = copyVertices();
        tCandidate[nIndex] = {x = nX, y = nY};
        commit(tCandidate);
    end

    --[[!
    @fqxn LuaEx.Primitives.polygon.Functions.getAnchor
    @desc Returns current selected anchor coordinates after refreshing derived data.
    !]]
    local function getAnchor()
        update();

        return nAnchorIndex > 0 and tVertices[nAnchorIndex] or tData.anchors[nAnchorIndex];
    end

    --[[!
    @fqxn LuaEx.Primitives.polygon.Methods.setPosition
    @desc Moves the selected anchor to numeric X/Y coordinates by translating every vertex together. Selection itself never moves the polygon.
    @param number nX Target anchor X coordinate.
    @param number nY Target anchor Y coordinate.
    !]]
    local function setPosition(nX, nY)
        validateNumber(nX);
        validateNumber(nY);

        local tAnchor = getAnchor();
        local nDX, nDY = nX * 1.0 - tAnchor.x, nY * 1.0 - tAnchor.y;
        validateNumber(nDX);
        validateNumber(nDY);

        if (nDX == 0 and nDY == 0) then
            return;
        end

        local tCandidate = copyVertices();

        for nIndex = 1, #tCandidate do
            tCandidate[nIndex].x = tCandidate[nIndex].x + nDX;
            tCandidate[nIndex].y = tCandidate[nIndex].y + nDY;
        end

        commit(tCandidate);
    end

    -- Read-only proxies resolve current data so retained references stay current.
    --[[!
    @fqxn LuaEx.Primitives.polygon.Functions.readonly
    @desc Creates a protected current-data proxy for derived scalar collections.
    !]]
    local function readonly(getValue)
        return rawsetmetatable({}, {
            __index = function(tInput, vKey)
                update();

                return getValue()[vKey];
            end,
            __len = function()
                update();

                return #getValue();
            end,
            __pairs = function()
                update();

                local tSnapshot = {};

                for vKey, vValue in pairs(getValue()) do
                    tSnapshot[vKey] = vValue;
                end

                return pairs(tSnapshot);
            end,
            __newindex = function()
                error("Polygon: derived data is read-only.", 2);
            end,
            __metatable = false,
        });
    end

    local tVertexProxies = {};
    local tEdgeProxies = {};
    local tAnchorProxies = {};

    --[[!
    @fqxn LuaEx.Primitives.polygon.Functions.vertexProxy
    @desc Returns a writable coordinate proxy associated with a vertex index.
    !]]
    local function vertexProxy(nIndex)
        if (not tVertexProxies[nIndex]) then
            tVertexProxies[nIndex] = rawsetmetatable({}, {
                __index = function(tInput, vKey)
                    update();
                    validateIndex(nIndex);

                    return tVertices[nIndex][vKey];
                end,
                __newindex = function(tInput, vKey, vValue)
                    validateIndex(nIndex);

                    if (vKey == "x") then
                        setVertex(nIndex, vValue, tVertices[nIndex].y);
                    elseif (vKey == "y") then
                        setVertex(nIndex, tVertices[nIndex].x, vValue);
                    else
                        error("Polygon: vertex coordinates are x and y.", 2);
                    end
                end,
                __metatable = false,
            });
        end

        return tVertexProxies[nIndex];
    end

    --[[!
    @fqxn LuaEx.Primitives.polygon.Properties.vertices
    @desc Protected indexed vertex collection. Write vertices[index].x or .y, or use setVertex for a two-coordinate edit. No table assignment; indices follow constructor order.
    !]]
    local tPublicVertices = rawsetmetatable({}, {
        __index = function(tInput, nIndex)
            if (rawtype(nIndex) == "number" and nIndex == floor(nIndex) and nIndex > #tVertices) then
                return nil;
            end

            validateIndex(nIndex);

            return vertexProxy(nIndex);
        end,
        __len = function()
            return #tVertices;
        end,
        __pairs = function()
            local nIndex = 0;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= #tVertices) then
                    return nIndex, vertexProxy(nIndex);
                end
            end;
        end,
        __newindex = function()
            error("Polygon: use numeric coordinate writes or setVertex.", 2);
        end,
        __metatable = false,
    });

    --[[!
    @fqxn LuaEx.Primitives.polygon.Properties.edges
    @desc Read-only indexed edges joining vertex i to i+1, with the final edge returning to vertex 1. Each exposes protected start/stop coordinates, length, deltaX, deltaY, slope, slopeIsUndefined and theta in radians.
    !]]
    local tPublicEdges = rawsetmetatable({}, {
        __index = function(tInput, nIndex)
            if (rawtype(nIndex) == "number" and nIndex == floor(nIndex) and nIndex > #tVertices) then
                return nil;
            end

            validateIndex(nIndex);

            if (not tEdgeProxies[nIndex]) then
                local tStart = readonly(function()
                    validateIndex(nIndex);

                    return tData.edges[nIndex].start;
                end);
                local tStop = readonly(function()
                    validateIndex(nIndex);

                    return tData.edges[nIndex].stop;
                end);
                tEdgeProxies[nIndex] = readonly(function()
                    validateIndex(nIndex);

                    local tEdge = tData.edges[nIndex];

                    return {
                        start = tStart, stop = tStop, length = tEdge.length,
                        deltaX = tEdge.deltaX, deltaY = tEdge.deltaY,
                        slope = tEdge.slope, slopeIsUndefined = tEdge.slopeIsUndefined,
                        theta = tEdge.theta,
                    };
                end);
            end

            return tEdgeProxies[nIndex];
        end,
        __len = function()
            return #tVertices;
        end,
        __pairs = function(tInput)
            local nIndex = 0;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= #tVertices) then
                    return nIndex, tInput[nIndex];
                end
            end;
        end,
        __newindex = function()
            error("Polygon: edges are derived and read-only.", 2);
        end,
        __metatable = false,
    });

    --[[!
    @fqxn LuaEx.Primitives.polygon.Properties.anchors
    @desc Read-only bounding-box corners and area centroid indexed by existing SHAPE_ANCHOR constants. The centroid may lie outside a concave polygon.
    !]]
    local tPublicAnchors = rawsetmetatable({}, {
        __index = function(tInput, nIndex)
            update();

            if (not tData.anchors[nIndex]) then
                error("Polygon: invalid anchor constant.", 2);
            end

            if (not tAnchorProxies[nIndex]) then
                tAnchorProxies[nIndex] = readonly(function()
                    return tData.anchors[nIndex];
                end);
            end

            return tAnchorProxies[nIndex];
        end,
        __pairs = function(tInput)
            local tIndices = {_nAnchorTL, _nAnchorTR, _nAnchorBR, _nAnchorBL, _nAnchorC};
            local nIndex = 0;

            return function()
                nIndex = nIndex + 1;

                local nAnchor = tIndices[nIndex];

                if (nAnchor ~= nil) then
                    return nAnchor, tInput[nAnchor];
                end
            end;
        end,
        __newindex = function()
            error("Polygon: use the selected anchor to translate the shape.", 2);
        end,
        __metatable = false,
    });

    --[[!
    @fqxn LuaEx.Primitives.polygon.Properties.anchor
    @desc Selected anchor coordinate proxy. Writing x or y translates the entire polygon. setPosition moves both coordinates atomically.
    !]]
    local tPublicAnchor = rawsetmetatable({}, {
        __index = function(tInput, vKey)
            return getAnchor()[vKey];
        end,
        __newindex = function(tInput, vKey, vValue)
            local tAnchor = getAnchor();

            if (vKey == "x") then
                setPosition(vValue, tAnchor.y);
            elseif (vKey == "y") then
                setPosition(tAnchor.x, vValue);
            else
                error("Polygon: anchor coordinates are x and y.", 2);
            end
        end,
        __metatable = false,
    });

    local tProperties = {
        vertices = tPublicVertices,
        edges = tPublicEdges,
        anchors = tPublicAnchors,
        anchor = tPublicAnchor,
        centroid = readonly(function() return tData.centroid; end),
        bounds = readonly(function() return tData.bounds; end),
        interiorAngles = readonly(function() return tData.interiorAngles; end),
        exteriorAngles = readonly(function() return tData.exteriorAngles; end),
        setVertex = setVertex,
        setPosition = setPosition,
        update = update,
    };
    local tDecoy = {};

    rawsetmetatable(tDecoy, {
        __index = function(tInput, vKey)
            update();

            if (vKey == "autoUpdate") then
                return bAutoUpdate;
            elseif (vKey == "anchorIndex") then
                return nAnchorIndex;
            elseif (tProperties[vKey] ~= nil) then
                return tProperties[vKey];
            elseif (rawtype(tData[vKey]) ~= "table") then
                return tData[vKey];
            end
        end,
        __newindex = function(tInput, vKey, vValue)
            if (vKey == "autoUpdate") then
                if (rawtype(vValue) ~= "boolean") then
                    error("Polygon: autoUpdate must be a boolean.", 2);
                end

                bAutoUpdate = vValue;

                if (vValue) then
                    update();
                end
            elseif (vKey == "anchorIndex") then
                update();

                if (rawtype(vValue) ~= "number" or
                    (not tData.anchors[vValue] and
                    (vValue ~= floor(vValue) or vValue < 1 or vValue > #tVertices))) then
                    error("Polygon: anchorIndex must be a vertex index or existing anchor constant.", 2);
                end

                nAnchorIndex = vValue;
            else
                error("Polygon: cannot set field '"..tostring(vKey).."'.", 2);
            end
        end,
        --[[!
        @fqxn LuaEx.Primitives.polygon.Metamethods.__call
        @desc Replaces the complete boundary atomically from flat numeric X/Y pairs. Vertex count may change, but replacement cannot remove a selected vertex anchor. Previously retained indexed proxies resolve the new vertex at that index.
        !]]
        __call = function(tInput, ...)
            commit(readVertices(...));

            return tDecoy;
        end,
        __type = "primitive",
        __subtype = "polygon",
        __metatable = {__type = "primitive", __subtype = "polygon"},
    });

    return tDecoy;
end
