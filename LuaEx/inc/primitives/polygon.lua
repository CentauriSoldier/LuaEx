local rawsetmetatable = rawsetmetatable
local math = math
local sqrt = math.sqrt
local _nPi = math.pi
local floor = math.floor

local QUADRANT_I = QUADRANT_I
local QUADRANT_II = QUADRANT_II
local QUADRANT_III = QUADRANT_III
local QUADRANT_IV = QUADRANT_IV
local _nAnchorCount = SHAPE_ANCHOR_COUNT
local _nAnchorTL = SHAPE_ANCHOR_TOP_LEFT
local _nAnchorTR = SHAPE_ANCHOR_TOP_RIGHT
local _nAnchorBR = SHAPE_ANCHOR_BOTTOM_RIGHT
local _nAnchorBL = SHAPE_ANCHOR_BOTTOM_LEFT
local _nAnchorC = SHAPE_ANCHOR_CENTROID
local _nAnchorDefault = SHAPE_ANCHOR_DEFAULT

local SIDE_TRIANGLE_DIFFERENTIAL = 3
local SIDE_ANGLE_FACTOR_DIFFERENTIAL = 2
local SUM_OF_EXTERIOR_ANGLES = 360

local EPSILON = 1e-10

-- Helper function to compute the area of the polygon (Shoelace formula)
local function calculateArea(tVertices)
    local nSum = 0
    local nVertices = #tVertices
    for i = 1, nVertices do
        local tVertex1 = tVertices[i]
        local tVertex2 = i < nVertices and tVertices[i + 1] or tVertices[1]
        nSum = nSum + (tVertex1.x * tVertex2.y - tVertex1.y * tVertex2.x)
    end
    return math.abs(nSum) / 2
end

-- Helper function to compute the perimeter of the polygon
local function calculatePerimeter(tEdges)
    local perimeter = 0
    for _, edge in ipairs(tEdges) do
        perimeter = perimeter + edge.length
    end
    return perimeter
end

-- Function to update internal values like area, perimeter, centroid, etc.
local function update(tActual, tAnchors, tVertices, tEdges, nVertices, bPerimeterAndEdges, bAnchors, bArea, bAngles)
    -- Perimeter and edges
    if bPerimeterAndEdges then
        for nVertex = 1, nVertices do
            local tNewStart = tVertices[nVertex]
            local tNewStop = nVertex < nVertices and tVertices[nVertex + 1] or tVertices[1]
            local tEdge = tEdges[nVertex]
            local nNewStartX, nNewStartY = tNewStart.x, tNewStart.y
            local nNewStopX, nNewStopY = tNewStop.x, tNewStop.y

            tEdge.start.x, tEdge.start.y = nNewStartX, nNewStartY
            tEdge.stop.x, tEdge.stop.y = nNewStopX, nNewStopY

            tEdge.length = sqrt((nNewStopX - nNewStartX) ^ 2 + (nNewStopY - nNewStartY) ^ 2)
        end
        tActual.perimeter = calculatePerimeter(tEdges)
    end

    -- Anchors
    if bAnchors then
        local nSumX, nSumY = 0, 0
        local tAnchorTL = tAnchors[_nAnchorTL]
        local tAnchorTR = tAnchors[_nAnchorTR]
        local tAnchorBR = tAnchors[_nAnchorBR]
        local tAnchorBL = tAnchors[_nAnchorBL]

        -- Initialize anchor points
        local tPoint1 = tVertices[1]
        local nPoint1X, nPoint1Y = tPoint1.x, tPoint1.y
        tAnchorTL.x, tAnchorTL.y = nPoint1X, nPoint1Y
        tAnchorTR.x, tAnchorTR.y = nPoint1X, nPoint1Y
        tAnchorBR.x, tAnchorBR.y = nPoint1X, nPoint1Y
        tAnchorBL.x, tAnchorBL.y = nPoint1X, nPoint1Y

        for nVertex = 1, nVertices do
            local tPoint = tVertices[nVertex]
            local nX, nY = tPoint.x, tPoint.y

            nSumX = nSumX + nX
            nSumY = nSumY + nY

            -- Update anchor points based on vertex positions
            local nTLX, nTLY = tAnchorTL.x, tAnchorTL.y
            local nTRX, nTRY = tAnchorTR.x, tAnchorTR.y
            local nBRX, nBRY = tAnchorBR.x, tAnchorBR.y
            local nBLX, nBLY = tAnchorBL.x, tAnchorBL.y

            tAnchorTL.x = (nX < nTLX) and nX or nTLX
            tAnchorTL.y = (nY < nTLY) and nY or nTLY
            tAnchorTR.x = (nX > nTRX) and nX or nTRX
            tAnchorTR.y = (nY < nTRY) and nY or nTRY
            tAnchorBR.x = (nX > nBRX) and nX or nBRX
            tAnchorBR.y = (nY > nBRY) and nY or nBRY
            tAnchorBL.x = (nX < nBLX) and nX or nBLX
            tAnchorBL.y = (nY > nBLY) and nY or nBLY
        end

        local nCenterXY = nSumX / nVertices
        tAnchors[_nAnchorC].x = nCenterXY
        tAnchors[_nAnchorC].y = nCenterXY
    end

    -- Area
    if bArea then
        tActual.area = calculateArea(tVertices)
    end
end

-- Main function to create and return the polygon primitive
return function(tInpVertices, bSkipFirstUpdate)
    local tActual, tAnchors, tEdges, tVertices
    local bAutoUpdate = true
    local nVertices = #tInpVertices

    -- Initialize polygon attributes
    tActual = {
        autoUpdate = true,
        area = 0,
        perimeter = 0,
        isConcave = false,
        isRegular = false,
        verticesCount = nVertices,
    }

    -- Create anchors
    tAnchors = {
        [_nAnchorTL] = {x = -1, y = 1},
        [_nAnchorTR] = {x = 1, y = 1},
        [_nAnchorBR] = {x = 1, y = -1},
        [_nAnchorBL] = {x = -1, y = -1},
        [_nAnchorC] = {x = 0, y = 0},
    }

    -- Create vertices and edges
    tVertices = {}
    tEdges = {}

    for nIndex, tVertex in ipairs(tInpVertices) do

        -- validate tVertex
        if not (
            rawtype(tVertex) == "table" or
            (type(tVertex) == "primitive" and subtype(tVertex) == "point")
        ) then
            error("Vertex must be a table or a point primitive.", 2)
        end

        if not (rawtype(tVertex.x) == "number" and rawtype(tVertex.y) == "number") then
            error("Vertex must have numeric x and y fields.", 2)
        end

        local nX, nY = tVertex.x, tVertex.y;

        local nNextEdgeIndex = (nIndex % nVertices) + 1
        local tNextVertex = tInpVertices[nNextEdgeIndex]
        local nNextX, nNextY = tNextVertex.x, tNextVertex.y

        -- Create vertex
        local tVertexDecoy = {}
        local tVertexMeta = {
            __index = tVertex,
            __newindex = function(t, k, v)
                if tVertex[k] ~= nil then
                    tVertex[k] = v
                    if bAutoUpdate then
                        update(tActual, tAnchors, tVertices, tEdges, nVertices, true, true, true, false)
                    end
                end
            end
        }
        rawsetmetatable(tVertexDecoy, tVertexMeta)
        tVertices[nIndex] = tVertex
        -- Create edge
        local tStart = {x = nX, y = nY}
        local tStop = {x = nNextX, y = nNextY}
        local nLength = sqrt((nNextX - nX) ^ 2 + (nNextY - nY) ^ 2)
        local tEdge = {start = tStart, stop = tStop, length = nLength}
        tEdges[nIndex] = tEdge
    end

    -- Set up metatables for the public interface (decoys)
    local tDecoy = {}
    local tMeta = {
        __index = tActual,
        __newindex = function(t, k, v)
            if k == "autoUpdate" and type(v) == "boolean" then
                tActual.autoUpdate = v
                bAutoUpdate = v
            end
        end,
        __type = "primitive",
        __subtype = "polygon",
    }
    rawsetmetatable(tDecoy, tMeta)

    -- Update polygon attributes if not skipped
    if not bSkipFirstUpdate then
        update(tActual, tAnchors, tVertices, tEdges, nVertices, true, true, true, true)
    end

    -- Expose public access to the values
    local tPublic = setmetatable({}, {
        __index = tActual,
        __newindex = function(t, k, v)
            if k == "autoUpdate" and type(v) == "boolean" then
                tActual.autoUpdate = v
            end
        end
    })

    return tPublic
end
