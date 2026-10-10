local rawsetmetatable = rawsetmetatable;
local rawtype = rawtype;
local error = error;
local tostring = tostring;
local format = string.format;
local sqrt = math.sqrt;
local abs = math.abs;
local max = math.max;
local atan2 = math.atan2;
local pairs = pairs;
local select = select;
local _nHuge = math.huge;

--[[!
@fqxn LuaEx.Primitives.line.Functions.validateNumber
@desc Rejects nonnumeric, infinite and NaN coordinates before mutation.
!]]
local function validateNumber(vInput)
    if (rawtype(vInput) ~= "number" or vInput ~= vInput or
        vInput == _nHuge or vInput == -_nHuge) then
        error("Line: coordinates must be finite numbers.", 3);
    end
end

--[[!
@fqxn LuaEx.Primitives.line.Functions.calculate
@desc Calculates one candidate state before committing endpoint changes. Standard coefficients are scaled so the larger absolute A or B is one. Unrepresentable results are rejected without mutation.
!]]
local function calculate(nStartX, nStartY, nStopX, nStopY)
    validateNumber(nStartX);
    validateNumber(nStartY);
    validateNumber(nStopX);
    validateNumber(nStopY);
    -- Float arithmetic avoids Lua integer overflow.
    local nDeltaX = nStopX * 1.0 - nStartX;
    local nDeltaY = nStopY * 1.0 - nStartY;

    validateNumber(nDeltaX);
    validateNumber(nDeltaY);
    local nScale = max(abs(nDeltaX), abs(nDeltaY));
    local tValues = {
        deltaX = nDeltaX,
        deltaY = nDeltaY,
        length = 0,
        midpointX = nStartX * 0.5 + nStopX * 0.5,
        midpointY = nStartY * 0.5 + nStopY * 0.5,
        slopeIsUndefined = nDeltaX == 0,
        isHorizontal = nDeltaY == 0 and nDeltaX ~= 0,
        isVertical = nDeltaX == 0 and nDeltaY ~= 0,
        yInterceptIsUndefined = true,
        xInterceptIsUndefined = true,
    };
    if (nScale == 0) then

        return tValues;
    end

    local nScaledX = nDeltaX / nScale;
    local nScaledY = nDeltaY / nScale;

    tValues.length = nScale * sqrt(nScaledX * nScaledX + nScaledY * nScaledY);
    tValues.theta = atan2(nDeltaY, nDeltaX);
    tValues.a = nScaledY;
    tValues.b = -nScaledX;
    tValues.c = -(tValues.a * nStartX + tValues.b * nStartY);
    if (nDeltaX ~= 0) then
        tValues.slope = nDeltaY / nDeltaX;
        tValues.yIntercept = nStartY - tValues.slope * nStartX;
        tValues.yInterceptIsUndefined = false;
    end

    if (nDeltaY ~= 0) then
        tValues.xIntercept = nStartX - (nDeltaX / nDeltaY) * nStartY;
        tValues.xInterceptIsUndefined = false;
    end

    for sKey, vValue in pairs(tValues) do
        if (rawtype(vValue) == "number") then
            validateNumber(vValue);
        end
    end

    return tValues;
end

--[[!
@fqxn LuaEx.Primitives.line
@pulsarlua function line
@desc A line segment defined by independently copied numeric endpoints. Only endpoints and autoUpdate are writable; derived values are read-only. Zero-length segments have no slope, angle, equation or unique intercepts. Invalid inputs and unrepresentable calculations leave the previous state intact. Rawset and debug tools bypass ordinary Lua protections.
@param number nStartX Start X coordinate.
@param number nStartY Start Y coordinate.
@param number nStopX Stop X coordinate.
@param number nStopY Stop Y coordinate.
@param boolean|nil bSkipFirstUpdate Defers publishing the initial calculated state until a read.
!]]
return function(nStartX, nStartY, nStopX, nStopY, bSkipFirstUpdate)
    if (bSkipFirstUpdate ~= nil and rawtype(bSkipFirstUpdate) ~= "boolean") then
        error("Line: skip-first-update must be a boolean.", 2);
    end

    local tPending = calculate(nStartX, nStartY, nStopX, nStopY);
    local bDirty = true;
    local tStart = {x = nStartX, y = nStartY};
    local tStop = {x = nStopX, y = nStopY};
    local tMidpoint = {};

    --[[!
    @fqxn LuaEx.Primitives.line.Properties.autoUpdate
    @pulsarlua boolean line.autoUpdate
    @desc Writable boolean, initially true. False defers publication of a validated calculated state until a read or update call. Calculations run once per changed write, never repeatedly on reads.
    !]]
    local tActual = {autoUpdate = true};
    local tDerivedKeys = {
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.a
        @pulsarlua number line.a
        @desc Read-only scaled A coefficient in A*x + B*y + C = 0. Nil for coincident endpoints.
        !]]
        "a",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.b
        @pulsarlua number line.b
        @desc Read-only scaled B coefficient in A*x + B*y + C = 0. Nil for coincident endpoints.
        !]]
        "b",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.c
        @pulsarlua number line.c
        @desc Read-only scaled C coefficient in A*x + B*y + C = 0. Nil for coincident endpoints.
        !]]
        "c",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.deltaX
        @pulsarlua number line.deltaX
        @desc Read-only stop X minus start X.
        !]]
        "deltaX",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.deltaY
        @pulsarlua number line.deltaY
        @desc Read-only stop Y minus start Y.
        !]]
        "deltaY",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.length
        @pulsarlua number line.length
        @desc Read-only Euclidean segment length, including zero.
        !]]
        "length",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.slope
        @pulsarlua number line.slope
        @desc Read-only deltaY/deltaX; nil when deltaX is zero.
        !]]
        "slope",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.slopeIsUndefined
        @pulsarlua boolean line.slopeIsUndefined
        @desc Read-only boolean indicating a zero deltaX, including coincident endpoints.
        !]]
        "slopeIsUndefined",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.isHorizontal
        @pulsarlua boolean line.isHorizontal
        @desc Read-only boolean: distinct endpoints with equal Y coordinates.
        !]]
        "isHorizontal",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.isVertical
        @pulsarlua boolean line.isVertical
        @desc Read-only boolean: distinct endpoints with equal X coordinates.
        !]]
        "isVertical",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.theta
        @pulsarlua number line.theta
        @desc Read-only directed angle in radians from the positive X axis; nil for coincident endpoints.
        !]]
        "theta",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.yIntercept
        @pulsarlua number line.yIntercept
        @desc Read-only supporting-line Y-axis crossing; nil if no unique crossing exists.
        !]]
        "yIntercept",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.yInterceptIsUndefined
        @pulsarlua boolean line.yInterceptIsUndefined
        @desc Read-only boolean indicating no unique Y-axis crossing.
        !]]
        "yInterceptIsUndefined",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.xIntercept
        @pulsarlua number line.xIntercept
        @desc Read-only supporting-line X-axis crossing; nil if no unique crossing exists.
        !]]
        "xIntercept",
        --[[!
        @fqxn LuaEx.Primitives.line.Properties.xInterceptIsUndefined
        @pulsarlua boolean line.xInterceptIsUndefined
        @desc Read-only boolean indicating no unique X-axis crossing.
        !]]
        "xInterceptIsUndefined",
    };

    --[[!
    @fqxn LuaEx.Primitives.line.Methods.update
    @pulsarlua function line.update
    @desc Publishes a dirty validated state once. Candidate calculations occur once per write to guarantee atomic validation; reads never repeat them. Call with dot syntax and no arguments.
    !]]
    local function update()
        if (bDirty) then
            for nIndex = 1, #tDerivedKeys do
                local sKey = tDerivedKeys[nIndex];

                tActual[sKey] = tPending[sKey];
            end

            tMidpoint.x = tPending.midpointX;
            tMidpoint.y = tPending.midpointY;
            tPending = nil;
            bDirty = false;
        end
    end

    tActual.update = update;

    --[[!
    @fqxn LuaEx.Primitives.line.Functions.setEndpoints
    @desc Validates all candidate coordinates and calculated values before committing either endpoint. Unchanged endpoints need no recalculation.
    !]]
    local function setEndpoints(nNewStartX, nNewStartY, nNewStopX, nNewStopY)
        if (nNewStartX == tStart.x and nNewStartY == tStart.y and
            nNewStopX == tStop.x and nNewStopY == tStop.y) then

            return;
        end

        local tValues = calculate(nNewStartX, nNewStartY, nNewStopX, nNewStopY);

        tStart.x, tStart.y = nNewStartX, nNewStartY;
        tStop.x, tStop.y = nNewStopX, nNewStopY;
        tPending = tValues;
        bDirty = true;
        if (tActual.autoUpdate) then
            update();
        end
    end

    --[[!
    @fqxn LuaEx.Primitives.line.Methods.setStart
    @pulsarlua function line.setStart
    @desc Sets start X/Y from two numbers and calculates the candidate once before mutation. Stop remains fixed.
    @param number nX Start X coordinate.
    @param number nY Start Y coordinate.
    @example
    oLine.setStart(2, 4);
    !]]
    local function setStart(nX, nY)
        setEndpoints(nX, nY, tStop.x, tStop.y);
    end

    --[[!
    @fqxn LuaEx.Primitives.line.Methods.setStop
    @pulsarlua function line.setStop
    @desc Sets stop X/Y from two numbers and calculates the candidate once before mutation. Start remains fixed.
    @param number nX Stop X coordinate.
    @param number nY Stop Y coordinate.
    @example
    oLine.setStop(4, 7);
    !]]
    local function setStop(nX, nY)
        setEndpoints(tStart.x, tStart.y, nX, nY);
    end

    tActual.setStart = setStart;
    tActual.setStop = setStop;

    --[[!
    @fqxn LuaEx.Primitives.line.Functions.makeEndpoint
    @desc Builds a protected endpoint proxy whose coordinate writes refresh the complete line state.
    !]]
    local function makeEndpoint(tPoint, bStart)

        return rawsetmetatable({}, {
            __index = function(tInput, vKey)
                update();

                return tPoint[vKey];
            end,
            __newindex = function(tInput, vKey, vValue)
                if (vKey ~= "x" and vKey ~= "y") then
                    error("Line: endpoint coordinates are x and y.", 2);
                end

                validateNumber(vValue);
                local nX = vKey == "x" and vValue or tPoint.x;
                local nY = vKey == "y" and vValue or tPoint.y;

                if (bStart) then
                    setEndpoints(nX, nY, tStop.x, tStop.y);
                else
                    setEndpoints(tStart.x, tStart.y, nX, nY);
                end
            end,
            __metatable = false,
        });
    end

    --[[!
    @fqxn LuaEx.Primitives.line.Properties.start
    @pulsarlua table line.start
    @desc Protected endpoint proxy: write start.x or start.y, or call setStart(x, y). Replacing start is disallowed.
    !]]
    tActual.start = makeEndpoint(tStart, true);
    --[[!
    @fqxn LuaEx.Primitives.line.Properties.stop
    @pulsarlua table line.stop
    @desc Protected endpoint proxy: write stop.x or stop.y, or call setStop(x, y). Replacing stop is disallowed.
    !]]
    tActual.stop = makeEndpoint(tStop, false);
    --[[!
    @fqxn LuaEx.Primitives.line.Properties.midpoint
    @pulsarlua table line.midpoint
    @desc Read-only midpoint proxy. Its x and y values refresh with the line and cannot be assigned.
    !]]
    tActual.midpoint = rawsetmetatable({}, {
        __index = function(tInput, vKey)
            update();

            return tMidpoint[vKey];
        end,
        __newindex = function()
            error("Line: midpoint is read-only.", 2);
        end,
        __metatable = false,
    });

    local tDecoy = {};

    rawsetmetatable(tDecoy, {
        __index = function(tInput, vKey)
            update();

            return tActual[vKey];
        end,
        __newindex = function(tInput, vKey, vValue)
            if (vKey == "autoUpdate") then
                if (rawtype(vValue) ~= "boolean") then
                    error("Line: autoUpdate must be a boolean.", 2);
                end

                tActual.autoUpdate = vValue;
                if (vValue) then
                    update();
                end
            else
                error("Line: cannot set field '"..tostring(vKey).."'.", 2);
            end
        end,
        --[[!
        @fqxn LuaEx.Primitives.line.Metamethods.__call
        @desc Sets both endpoints atomically from four numeric coordinates: start X/Y followed by stop X/Y. Calculations run once; table inputs are rejected.
        @example
        oLine(2, 4, 4, 7);
        !]]
        __call = function(tInput, ...)
            local nCount = select("#", ...);

            if (nCount ~= 4) then
                error("Line: expected four numeric coordinates.", 2);
            end

            setEndpoints(...);

            return tDecoy;
        end,
        __type = "primitive",
        __subtype = "line",
        __metatable = {__type = "primitive", __subtype = "line"},
        --[[!
        @fqxn LuaEx.Primitives.line.Metamethods.__tostring
        @desc Formats current endpoints and derived values; undefined slope and angle are shown as nil.
        !]]
        __tostring = function()
            update();

            return format("Line(start: (%.2f, %.2f), stop: (%.2f, %.2f), length: %.2f, slope: %s, theta: %s)",
                tStart.x, tStart.y, tStop.x, tStop.y, tActual.length,
                tostring(tActual.slope), tostring(tActual.theta));
        end,
    });
    if (not bSkipFirstUpdate) then
        update();
    end

    return tDecoy;
end
