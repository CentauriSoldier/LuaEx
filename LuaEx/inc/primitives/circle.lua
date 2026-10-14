local circleFactory;
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
@pulsarlua function circle
@desc A table-like circle with writable center.x, center.y and radius. Diameter, circumference and area are calculated and read-only. Invalid writes raise errors without changing state. Ordinary metatable access cannot expose backing data; rawset and debug operations bypass normal Lua protections.
@param number nInpCenterX Finite center X coordinate.
@param number nInpCenterY Finite center Y coordinate.
@param number nInpRadius Non-negative finite radius whose derived values remain finite.
@param boolean|nil bSkipFirstUpdate Optional initial calculation deferral. The first read calculates dirty values.
@ret primitive A circle primitive.
!]]
local function build(nInpCenterX, nInpCenterY, nInpRadius, bSkipFirstUpdate)
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
        @pulsarlua number circle.center.x
        @desc Writable finite X coordinate of the center.
        !]]
        x = nInpCenterX,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.center.y
        @pulsarlua number circle.center.y
        @desc Writable finite Y coordinate of the center.
        !]]
        y = nInpCenterY,
    };
    local tActual = {
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.autoUpdate
        @pulsarlua boolean circle.autoUpdate
        @desc Writable boolean, initially true. When false, radius writes defer calculation until a read or update call. Dirty values calculate once; clean reads do not recalculate. Enabling autoUpdate refreshes pending values.
        !]]
        autoUpdate = true,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.radius
        @pulsarlua number circle.radius
        @desc Writable non-negative finite radius. Changes invalidate derived size values; autoUpdate determines eager or deferred calculation.
        !]]
        radius = nInpRadius,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.diameter
        @pulsarlua number circle.diameter
        @desc Read-only diameter, equal to twice the radius. Assigning it raises an error.
        !]]
        diameter = 0,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.circumference
        @pulsarlua number circle.circumference
        @desc Read-only circumference, equal to twice pi times radius. Assigning it raises an error.
        !]]
        circumference = 0,
        --[[!
        @fqxn LuaEx.Primitives.circle.Properties.area
        @pulsarlua number circle.area
        @desc Read-only area, equal to pi times radius squared. Assigning it raises an error.
        !]]
        area = 0,
    };

    -- A clean circle does not repeat its calculations on subsequent reads.
    --[[!
    @fqxn LuaEx.Primitives.circle.Methods.update
    @pulsarlua function circle.update
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
    @pulsarlua table circle.center
    @desc The center coordinate proxy. Its reference is read-only; assign center.x or center.y to move the circle without changing size.
    !]]
    tActual.center = tCenterDecoy;

    local tDecoy = {};

    --[[!
    @fqxn LuaEx.Primitives.circle.Functions.getState
    @desc Copies defining geometry and update settings. Derived caches are not saved.
    @ret table tState Independent restoration data.
    @scope local
    !]]
    local function getState()

        return {
            centerX = tCenterActual.x,
            centerY = tCenterActual.y,
            radius = tActual.radius,
            autoUpdate = tActual.autoUpdate,
        };
    end

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
        --[[!
        @fqxn LuaEx.Primitives.circle.Metamethods.__clone
        @desc Creates independent geometry from current defining inputs, retaining update settings.
        @ret primitive oCopy Independent circle primitive.
        !]]
        __clone = function()

            return circleFactory.deserialize(getState());
        end,
        --[[!
        @fqxn LuaEx.Primitives.circle.Metamethods.__serialize
        @desc Supplies fresh defining state for global serialize; derived values are recomputed.
        @ret table tState Restoration data.
        !]]
        __serialize = getState,
        __serialtype = "circle",
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

local circleFactoryActual = {
    --[[!
    @fqxn LuaEx.Primitives.circle.Functions.deserialize
    @pulsarlua function circle.deserialize
    @desc Validates saved defining state, rebuilds geometry and restores update settings.
    Invalid state raises before a restored object is returned. Derived values are not trusted.
    @param table tState State supplied by global serialize or the object's __serialize hook.
    @ret primitive oCopy Restored independent circle primitive.
    !]]
    deserialize = function(tState)

        type.assert.table(tState);
        local tAllowed = { centerX = true, centerY = true, radius = true, autoUpdate = true };

        -- Step 1: reject unknown state fields before constructing an object.
        for sField in pairs(tState) do
            assert(tAllowed[sField], "Unknown circle restoration field.");
        end

        -- Step 2: require all defining coordinates/sizes as finite numbers.
        for _, sField in ipairs({ "centerX", "centerY", "radius" }) do
            local nValue = tState[sField];
            assert(rawtype(nValue) == "number" and nValue == nValue and math.abs(nValue) < math.huge,
                   "Invalid circle restoration number: "..sField);
        end

        assert(rawtype(tState.autoUpdate) == "boolean", "Restored autoUpdate must be boolean.");

        -- Step 3: constructor validation enforces geometry-specific constraints.
        local oCopy = build(tState.centerX, tState.centerY, tState.radius);
        oCopy.autoUpdate = tState.autoUpdate;
        return oCopy;
    end,
};
local circleFactoryMeta = {
    __call = function(this, ...)

        return build(...);
    end,
    __index = function(t, k)

        return circleFactoryActual[k] or nil;
    end,
    __newindex = function()

        error("circle factory members cannot be assigned directly.", 2);
    end,
    __type = "circlePrimitiveFactory",
};
circleFactory = {};
circleFactoryMeta.__clone = function() return circleFactory; end;
circleFactoryMeta.__serialize = function() return "circle"; end;
circleFactoryMeta.__metatable = table.readonly({
    __type = circleFactoryMeta.__type,
    __call = circleFactoryMeta.__call,
    __clone = circleFactoryMeta.__clone,
    __serialize = circleFactoryMeta.__serialize,
});
setmetatable(circleFactory, circleFactoryMeta);
require("LuaEx.lib.serializer").registerFactory(circleFactory, {name = "circle", types = {"circle"}});
return circleFactory;
