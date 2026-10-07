local rawsetmetatable = rawsetmetatable;
local rawtype = rawtype;
local error = error;
local tostring = tostring;
local format = string.format;
local assertNumber = type.assert.number;
local _nPi = math.pi;
local _nTwoPi = 2 * _nPi;
local _nHuge = math.huge;

-- Validate before mutation, including numbers that cannot represent a circle.
--[[!
@fqxn LuaEx.Primitives.circle.Functions.validateNumber
@desc Validates finite numeric input and optionally rejects negative values before mutation.
!]]
local function validateNumber(vInput, sName, bNonNegative)
    if (rawtype(vInput) ~= "number" or vInput ~= vInput or
        vInput == _nHuge or vInput == -_nHuge) then
        error("Circle: '"..sName.."' must be a finite number.", 3);
    end

    assertNumber(vInput, bNonNegative);
end

--[[!
@fqxn LuaEx.Primitives.circle.Functions.validateRadius
@desc Validates radius and rejects overflow of derived size values.
!]]
local function validateRadius(nRadius)
    validateNumber(nRadius, "radius", true);
    if ((_nPi * nRadius) * nRadius == _nHuge or
        _nTwoPi * nRadius == _nHuge or 2.0 * nRadius == _nHuge) then
        error("Circle: radius is too large to represent its derived values.", 3);
    end
end

-- Custom circle primitive. Size properties share one authoritative radius.
--[[!
@fqxn LuaEx.Primitives.circle
@desc A table-like circle with writable center.x, center.y and radius. Diameter, circumference and area are calculated and read-only. Invalid writes raise errors without changing state. Ordinary metatable access cannot expose backing data; rawset and debug operations bypass normal Lua protections.
@param number nInpCenterX Finite center X coordinate.
@param number nInpCenterY Finite center Y coordinate.
@param number nInpRadius Non-negative finite radius whose derived values remain finite.
@param boolean|nil bSkipFirstUpdate Optional initial calculation deferral. The first read calculates dirty values.
@ret primitive A circle primitive.
!]]
return function(nInpCenterX, nInpCenterY, nInpRadius, bSkipFirstUpdate)
    validateNumber(nInpCenterX, "center.x", false);
    validateNumber(nInpCenterY, "center.y", false);
    validateRadius(nInpRadius);
    if (bSkipFirstUpdate ~= nil and rawtype(bSkipFirstUpdate) ~= "boolean") then
        error("Circle: skip-first-update must be a boolean.", 2);
    end

    local bDirty = true;
    local tCenterActual = {
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.center.x
        @desc Writable finite X coordinate of the center.
        !]]
        x = nInpCenterX,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.center.y
        @desc Writable finite Y coordinate of the center.
        !]]
        y = nInpCenterY,
    };
    local tActual = {
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.autoUpdate
        @desc Writable boolean, initially true. When false, radius writes defer calculation until a read or update call. Dirty values calculate once; clean reads do not recalculate. Enabling autoUpdate refreshes pending values.
        !]]
        autoUpdate = true,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.radius
        @desc Writable non-negative finite radius. Changes invalidate derived size values; autoUpdate determines eager or deferred calculation.
        !]]
        radius = nInpRadius,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.diameter
        @desc Read-only diameter, equal to twice the radius. Assigning it raises an error.
        !]]
        diameter = 0,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.circumference
        @desc Read-only circumference, equal to twice pi times radius. Assigning it raises an error.
        !]]
        circumference = 0,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.area
        @desc Read-only area, equal to pi times radius squared. Assigning it raises an error.
        !]]
        area = 0,
    };

    -- A clean circle does not repeat its calculations on subsequent reads.
    --[[!
    @fqxn LuaEx.Primitives.circle.Methods.update
    @desc Calculates derived values only when dirty. Call with dot syntax and no arguments. This method cannot be replaced.
    !]]
    local function update()
        if (bDirty) then
            local nRadius = tActual.radius;

            tActual.diameter = 2.0 * nRadius;
            tActual.circumference = _nTwoPi * nRadius;
            tActual.area = (_nPi * nRadius) * nRadius;
            bDirty = false;
        end
    end

    tActual.update = update;

    local tCenterDecoy = {};

    rawsetmetatable(tCenterDecoy, {
        __index = function(tInput, vKey)
            update();

            return tCenterActual[vKey];
        end,
        __newindex = function(tInput, vKey, vValue)
            if (vKey ~= "x" and vKey ~= "y") then
                error("Circle center: cannot set field '"..tostring(vKey).."'.", 2);
            end

            validateNumber(vValue, "center."..vKey, false);
            tCenterActual[vKey] = vValue;
        end,
        __metatable = false,
    });
    --[[!
    @fqxn LuaEx.Primitives.circle.Properties.center
    @desc The center coordinate proxy. Its reference is read-only; assign center.x or center.y to move the circle without changing size.
    !]]
    tActual.center = tCenterDecoy;

    local tDecoy = {};

    rawsetmetatable(tDecoy, {
        __index = function(tInput, vKey)
            update();

            return tActual[vKey];
        end,
        __newindex = function(tInput, vKey, vValue)
            if (vKey == "autoUpdate") then
                if (rawtype(vValue) ~= "boolean") then
                    error("Circle: autoUpdate must be a boolean.", 2);
                end

                tActual.autoUpdate = vValue;
                if (vValue) then
                    update();
                end

                return;
            end

            if (vKey ~= "radius") then
                error("Circle: cannot set field '"..tostring(vKey).."'.", 2);
            end

            local nRadius = vValue;

            validateRadius(nRadius);
            if (nRadius ~= tActual.radius) then
                tActual.radius = nRadius;
                bDirty = true;
            end

            if (tActual.autoUpdate) then
                update();
            end
        end,
        __type = "primitive",
        __subtype = "circle",
        -- Expose type metadata only, never backing data or metamethods.
        __metatable = {__type = "primitive", __subtype = "circle"},
        --[[!
        @fqxn LuaEx.Primitives.circle.Metamethods.__tostring
        @desc Formats center and size values after refreshing dirty data.
        !]]
        __tostring = function()
            update();

            return format(
                "Circle(center: (%.2f, %.2f), radius: %.2f, diameter: %.2f, circumference: %.2f, area: %.2f)",
                tCenterActual.x, tCenterActual.y, tActual.radius,
                tActual.diameter, tActual.circumference, tActual.area
            );
        end,
    });
    if (not bSkipFirstUpdate) then
        update();
    end

    return tDecoy;
end
