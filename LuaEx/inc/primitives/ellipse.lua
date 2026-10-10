local rawsetmetatable = rawsetmetatable;
local rawtype = rawtype;
local error = error;
local tostring = tostring;
local sqrt = math.sqrt;
local _nPi = math.pi;
local _nHuge = math.huge;

--[[!
@fqxn LuaEx.Primitives.ellipse.Functions.validateNumber
@desc Rejects nonnumeric, infinite and NaN input before mutation.
!]]
local function validateNumber(vInput, sName)
    if (rawtype(vInput) ~= "number" or vInput ~= vInput or
        vInput == _nHuge or vInput == -_nHuge) then
        error("Ellipse: '"..sName.."' must be a finite number.", 3);
    end
end

--[[!
@fqxn LuaEx.Primitives.ellipse.Functions.calculate
@desc Validates ordered full axis lengths and calculates area and circumference before mutation. Circumference uses Ramanujan's second approximation; circles and zero-minor-axis limits are handled exactly.
!]]
local function calculate(nMajorAxis, nMinorAxis)
    validateNumber(nMajorAxis, "majorAxis");
    validateNumber(nMinorAxis, "minorAxis");
    if (nMinorAxis < 0 or nMajorAxis < nMinorAxis) then
        error("Ellipse: axes must satisfy majorAxis >= minorAxis >= 0.", 3);
    end

    if (nMajorAxis == 0) then

        return 0, 0;
    end

    local nSemiMajor = nMajorAxis * 0.5;
    local nSemiMinor = nMinorAxis * 0.5;
    local nArea = (_nPi * nSemiMinor) * nSemiMajor;
    local nCircumference;

    if (nMinorAxis == 0) then
        nCircumference = 2.0 * nMajorAxis;
    elseif (nMajorAxis == nMinorAxis) then
        nCircumference = _nPi * nMajorAxis;
    else
        -- Normalize the ratio to avoid squaring large axis lengths.
        local nRatio = nMinorAxis / nMajorAxis;
        local nDifferenceRatio = (1 - nRatio) / (1 + nRatio);
        local nH = nDifferenceRatio * nDifferenceRatio;

        nCircumference = (_nPi * nSemiMajor) * (1 + nRatio) *
            (1 + 3 * nH / (10 + sqrt(4 - 3 * nH)));
    end

    validateNumber(nArea, "area");
    validateNumber(nCircumference, "circumference");

    return nArea, nCircumference;
end

--[[!
@fqxn LuaEx.Primitives.ellipse
@pulsarlua function ellipse
@desc An axis-aligned ellipse centered at X and Y. majorAxis and minorAxis are FULL lengths; formulas use half those lengths internally. The major axis lies along X and must be at least the minor axis. Area and circumference are read-only. Zero minor axis represents a degenerate segment, whose perimeter limit is twice the major-axis length; both axes zero represent a point. Invalid assignments preserve state. Rawset and debug tools bypass normal Lua protections.
@param number nCenterX Finite center X coordinate.
@param number nCenterY Finite center Y coordinate.
@param number nMajorAxis Full major-axis length.
@param number nMinorAxis Full minor-axis length, between zero and majorAxis.
@param boolean|nil bSkipFirstUpdate Defers publishing the initial calculated state until a read.
@ret primitive An ellipse primitive.
@example
local oEllipse = ellipse(0, 0, 10, 6);
oEllipse.majorAxis = 12;
oEllipse.center.x = 1.7;
!]]
return function(nCenterX, nCenterY, nMajorAxis, nMinorAxis, bSkipFirstUpdate)
    validateNumber(nCenterX, "center.x");
    validateNumber(nCenterY, "center.y");
    local nPendingArea, nPendingCircumference = calculate(nMajorAxis, nMinorAxis);

    if (bSkipFirstUpdate ~= nil and rawtype(bSkipFirstUpdate) ~= "boolean") then
        error("Ellipse: skip-first-update must be a boolean.", 2);
    end

    local bDirty = true;
    local tCenterActual = {
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Properties.center.x
        @pulsarlua number ellipse.center.x
        @desc Writable finite center X coordinate. Translation preserves area and circumference.
        !]]
        x = nCenterX,
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Properties.center.y
        @pulsarlua number ellipse.center.y
        @desc Writable finite center Y coordinate. Translation preserves area and circumference.
        !]]
        y = nCenterY,
    };
    local tActual = {
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Properties.autoUpdate
        @pulsarlua boolean ellipse.autoUpdate
        @desc Writable boolean, initially true. When false, calculated candidate results are published on the next read or update call. Candidates are calculated once before mutation to reject overflow atomically; clean reads never recalculate.
        !]]
        autoUpdate = true,
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Properties.majorAxis
        @pulsarlua number ellipse.majorAxis
        @desc Writable full major-axis length, at least minorAxis. Changing it refreshes derived values.
        !]]
        majorAxis = nMajorAxis,
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Properties.minorAxis
        @pulsarlua number ellipse.minorAxis
        @desc Writable full minor-axis length, non-negative and no greater than majorAxis.
        !]]
        minorAxis = nMinorAxis,
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Properties.area
        @pulsarlua number ellipse.area
        @desc Read-only area: pi times half-major-axis times half-minor-axis.
        !]]
        area = 0,
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Properties.circumference
        @pulsarlua number ellipse.circumference
        @desc Read-only perimeter. Uses Ramanujan's second approximation for noncircular, nondegenerate ellipses, not an exact perimeter formula.
        !]]
        circumference = 0,
    };

    --[[!
    @fqxn LuaEx.Primitives.ellipse.Methods.update
    @pulsarlua function ellipse.update
    @desc Publishes a dirty validated state once. Repeated clean calls do not repeat calculation. Call with dot syntax and no arguments.
    !]]
    local function update()
        if (bDirty) then
            tActual.area = nPendingArea;
            tActual.circumference = nPendingCircumference;
            bDirty = false;
        end
    end

    tActual.update = update;

    --[[!
    @fqxn LuaEx.Primitives.ellipse.Properties.center
    @pulsarlua table ellipse.center
    @desc Protected center proxy. Write center.x or center.y; replacing the center is disallowed.
    !]]
    tActual.center = rawsetmetatable({}, {
        __index = function(tInput, vKey)
            update();

            return tCenterActual[vKey];
        end,
        __newindex = function(tInput, vKey, vValue)
            if (vKey ~= "x" and vKey ~= "y") then
                error("Ellipse center: cannot set field '"..tostring(vKey).."'.", 2);
            end

            validateNumber(vValue, "center."..vKey);
            tCenterActual[vKey] = vValue;
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
                    error("Ellipse: autoUpdate must be a boolean.", 2);
                end

                tActual.autoUpdate = vValue;
                if (vValue) then
                    update();
                end

                return;
            end

            if (vKey ~= "majorAxis" and vKey ~= "minorAxis") then
                error("Ellipse: cannot set field '"..tostring(vKey).."'.", 2);
            end

            validateNumber(vValue, vKey);
            if (vValue ~= tActual[vKey]) then
                local nNewMajor = vKey == "majorAxis" and vValue or tActual.majorAxis;
                local nNewMinor = vKey == "minorAxis" and vValue or tActual.minorAxis;
                local nArea, nCircumference = calculate(nNewMajor, nNewMinor);

                tActual[vKey] = vValue;
                nPendingArea, nPendingCircumference = nArea, nCircumference;
                bDirty = true;
            end

            if (tActual.autoUpdate) then
                update();
            end
        end,
        __type = "primitive",
        __subtype = "ellipse",
        __metatable = {__type = "primitive", __subtype = "ellipse"},
    });
    if (not bSkipFirstUpdate) then
        update();
    end

    return tDecoy;
end
