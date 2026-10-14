local ellipseFactory;
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
local function build(nCenterX, nCenterY, nMajorAxis, nMinorAxis, bSkipFirstUpdate)
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

    --[[!
    @fqxn LuaEx.Primitives.ellipse.Functions.getState
    @desc Copies defining geometry and update settings. Derived caches are not saved.
    @ret table tState Independent restoration data.
    @scope local
    !]]
    local function getState()

        return {
            centerX = tCenterActual.x,
            centerY = tCenterActual.y,
            majorAxis = tActual.majorAxis,
            minorAxis = tActual.minorAxis,
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
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Metamethods.__clone
        @desc Creates independent geometry from current defining inputs, retaining update settings.
        @ret primitive oCopy Independent ellipse primitive.
        !]]
        __clone = function()

            return ellipseFactory.deserialize(getState());
        end,
        --[[!
        @fqxn LuaEx.Primitives.ellipse.Metamethods.__serialize
        @desc Supplies fresh defining state for global serialize; derived values are recomputed.
        @ret table tState Restoration data.
        !]]
        __serialize = getState,
        __serialtype = "ellipse",
        __type = "primitive",
        __subtype = "ellipse",
        __metatable = {__type = "primitive", __subtype = "ellipse"},
    });
    if (not bSkipFirstUpdate) then
        update();
    end

    return tDecoy;
end

local ellipseFactoryActual = {
    --[[!
    @fqxn LuaEx.Primitives.ellipse.Functions.deserialize
    @pulsarlua function ellipse.deserialize
    @desc Validates saved defining state, rebuilds geometry and restores update settings.
    Invalid state raises before a restored object is returned. Derived values are not trusted.
    @param table tState State supplied by global serialize or the object's __serialize hook.
    @ret primitive oCopy Restored independent ellipse primitive.
    !]]
    deserialize = function(tState)

        type.assert.table(tState);
        local tAllowed = { centerX = true, centerY = true, majorAxis = true, minorAxis = true, autoUpdate = true };

        -- Step 1: reject unknown state fields before constructing an object.
        for sField in pairs(tState) do
            assert(tAllowed[sField], "Unknown ellipse restoration field.");
        end

        -- Step 2: require all defining coordinates/sizes as finite numbers.
        for _, sField in ipairs({ "centerX", "centerY", "majorAxis", "minorAxis" }) do
            local nValue = tState[sField];
            assert(rawtype(nValue) == "number" and nValue == nValue and math.abs(nValue) < math.huge,
                   "Invalid ellipse restoration number: "..sField);
        end

        assert(rawtype(tState.autoUpdate) == "boolean", "Restored autoUpdate must be boolean.");

        -- Step 3: constructor validation enforces geometry-specific constraints.
        local oCopy = build(tState.centerX, tState.centerY, tState.majorAxis, tState.minorAxis);
        oCopy.autoUpdate = tState.autoUpdate;
        return oCopy;
    end,
};
local ellipseFactoryMeta = {
    __call = function(this, ...)

        return build(...);
    end,
    __index = function(t, k)

        return ellipseFactoryActual[k] or nil;
    end,
    __newindex = function()

        error("ellipse factory members cannot be assigned directly.", 2);
    end,
    __type = "ellipsePrimitiveFactory",
};
ellipseFactory = {};
ellipseFactoryMeta.__clone = function() return ellipseFactory; end;
ellipseFactoryMeta.__serialize = function() return "ellipse"; end;
ellipseFactoryMeta.__metatable = table.readonly({
    __type = ellipseFactoryMeta.__type,
    __call = ellipseFactoryMeta.__call,
    __clone = ellipseFactoryMeta.__clone,
    __serialize = ellipseFactoryMeta.__serialize,
});
setmetatable(ellipseFactory, ellipseFactoryMeta);
require("LuaEx.lib.serializer").registerFactory(ellipseFactory, {name = "ellipse", types = {"ellipse"}});
return ellipseFactory;
