local rawsetmetatable = rawsetmetatable;
local rawtype = rawtype;
local error = error;
local tostring = tostring;
local _nPi = math.pi;
local _nTau = 2 * _nPi;
local _nHuge = math.huge;

--[[!
@fqxn LuaEx.Primitives.circlearc.Functions.validateNumber
@desc Rejects nonnumeric, infinite and NaN inputs before mutation.
!]]
local function validateNumber(vInput, sName)
    if (rawtype(vInput) ~= "number" or vInput ~= vInput or
        vInput == _nHuge or vInput == -_nHuge) then
        error("Circle arc: '"..sName.."' must be a finite number.", 3);
    end
end

--[[!
@fqxn LuaEx.Primitives.circlearc.Functions.getSweep
@desc Returns the counterclockwise sweep in radians, wrapping through zero. Equal angles give zero. A nonzero difference of whole turns gives one full turn; other differences wrap into one turn.
!]]
local function getSweep(nStartAngle, nEndAngle)
    validateNumber(nStartAngle, "startAngle");
    validateNumber(nEndAngle, "endAngle");
    local nDifference = nEndAngle * 1.0 - nStartAngle;

    validateNumber(nDifference, "angle difference");
    if (nDifference == 0) then

        return 0;
    end

    local nSweep = nDifference % _nTau;

    return nSweep == 0 and _nTau or nSweep;
end

--[[!
@fqxn LuaEx.Primitives.circlearc.Functions.validateGeometry
@desc Validates radius, angles and representability of arc length and sector area before changing state.
!]]
local function validateGeometry(nRadius, nStartAngle, nEndAngle)
    validateNumber(nRadius, "radius");
    if (nRadius < 0) then
        error("Circle arc: radius must be non-negative.", 3);
    end

    local nSweep = getSweep(nStartAngle, nEndAngle);

    -- Multiplication order supports a zero sweep and avoids integer overflow.
    validateNumber((nSweep * nRadius) * 0.5 * nRadius, "sector area");
    validateNumber(nSweep * nRadius, "arc length");

    return nSweep;
end

--[[!
@fqxn LuaEx.Primitives.circlearc
@desc A circular arc defined by a center, radius and two angles in radians. Its direction is counterclockwise in Cartesian coordinates; on a screen with downward-positive Y it appears clockwise. Angles wrap through zero. Equal angles give zero arc; nonzero whole-turn differences give a full circle. Length and sector area are read-only. Invalid assignments preserve existing state. Rawset and debug tools bypass normal Lua protections.
@param number nCenterX Finite center X coordinate.
@param number nCenterY Finite center Y coordinate.
@param number nRadius Non-negative finite radius.
@param number nStartAngle Start angle in radians from the positive X axis.
@param number nEndAngle End angle in radians from the positive X axis.
@param boolean|nil bSkipFirstUpdate Optional initial calculation deferral until a read.
@ret primitive A circle arc primitive.
@example
local oArc = circlearc(0, 0, 4, 0, math.pi / 2);
oArc.radius = 6;
oArc.center.x = 10;
!]]
return function(nCenterX, nCenterY, nRadius, nStartAngle, nEndAngle, bSkipFirstUpdate)
    validateNumber(nCenterX, "center.x");
    validateNumber(nCenterY, "center.y");
    local nSweep = validateGeometry(nRadius, nStartAngle, nEndAngle);

    if (bSkipFirstUpdate ~= nil and rawtype(bSkipFirstUpdate) ~= "boolean") then
        error("Circle arc: skip-first-update must be a boolean.", 2);
    end

    local bDirty = true;
    local tCenterActual = {
        --[[!
        @fqxn LuaEx.Primitives.circlearc.Properties.center.x
        @desc Writable finite center X coordinate; moving the center does not change size.
        !]]
        x = nCenterX,
        --[[!
        @fqxn LuaEx.Primitives.circlearc.Properties.center.y
        @desc Writable finite center Y coordinate; moving the center does not change size.
        !]]
        y = nCenterY,
    };
    local tActual = {
        --[[!
        @fqxn LuaEx.Primitives.circlearc.Properties.autoUpdate
        @desc Writable boolean, initially true. False defers derived updates until a read or update call. Clean values are not recalculated.
        !]]
        autoUpdate = true,
        --[[!
        @fqxn LuaEx.Primitives.circlearc.Properties.radius
        @desc Writable non-negative finite radius. Changes invalidate derived values.
        !]]
        radius = nRadius,
        --[[!
        @fqxn LuaEx.Primitives.circlearc.Properties.startAngle
        @desc Writable finite start angle in radians. Changing it updates the counterclockwise sweep.
        !]]
        startAngle = nStartAngle,
        --[[!
        @fqxn LuaEx.Primitives.circlearc.Properties.endAngle
        @desc Writable finite end angle in radians. Lower end angles wrap through zero.
        !]]
        endAngle = nEndAngle,
        --[[!
        @fqxn LuaEx.Primitives.circlearc.Properties.length
        @desc Read-only non-negative arc length: radius times counterclockwise sweep.
        !]]
        length = 0,
        --[[!
        @fqxn LuaEx.Primitives.circlearc.Properties.area
        @desc Read-only non-negative sector area: half the radius squared times sweep. This is the wedge including the center, not circular-segment area.
        !]]
        area = 0,
    };

    --[[!
    @fqxn LuaEx.Primitives.circlearc.Methods.update
    @desc Refreshes dirty arc length and sector area once. Call with dot syntax and no arguments. Repeated clean calls do not recalculate.
    !]]
    local function update()
        if (bDirty) then
            tActual.length = nSweep * tActual.radius;
            tActual.area = (nSweep * tActual.radius) * 0.5 * tActual.radius;
            bDirty = false;
        end
    end

    tActual.update = update;

    --[[!
    @fqxn LuaEx.Primitives.circlearc.Properties.center
    @desc Protected coordinate proxy. Change center.x or center.y individually; the center reference itself is read-only.
    !]]
    tActual.center = rawsetmetatable({}, {
        __index = function(tInput, vKey)
            update();

            return tCenterActual[vKey];
        end,
        __newindex = function(tInput, vKey, vValue)
            if (vKey ~= "x" and vKey ~= "y") then
                error("Circle arc center: cannot set field '"..tostring(vKey).."'.", 2);
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
                    error("Circle arc: autoUpdate must be a boolean.", 2);
                end

                tActual.autoUpdate = vValue;
                if (vValue) then
                    update();
                end

                return;
            end

            if (vKey ~= "radius" and vKey ~= "startAngle" and vKey ~= "endAngle") then
                error("Circle arc: cannot set field '"..tostring(vKey).."'.", 2);
            end

            validateNumber(vValue, vKey);
            local nNewRadius = vKey == "radius" and vValue or tActual.radius;
            local nNewStart = vKey == "startAngle" and vValue or tActual.startAngle;
            local nNewEnd = vKey == "endAngle" and vValue or tActual.endAngle;
            local nNewSweep = validateGeometry(nNewRadius, nNewStart, nNewEnd);

            if (vValue ~= tActual[vKey]) then
                tActual[vKey] = vValue;
                nSweep = nNewSweep;
                bDirty = true;
            end

            if (tActual.autoUpdate) then
                update();
            end
        end,
        __type = "primitive",
        __subtype = "circle_arc",
        __metatable = {__type = "primitive", __subtype = "circle_arc"},
    });
    if (not bSkipFirstUpdate) then
        update();
    end

    return tDecoy;
end
