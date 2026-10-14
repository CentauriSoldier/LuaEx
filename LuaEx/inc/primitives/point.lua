local pointFactory;
local rawsetmetatable = rawsetmetatable;
local rawtype = rawtype;
local error = error;
local tostring = tostring;
local _nHuge = math.huge;

--[[!
@fqxn LuaEx.Primitives.point.Functions.validateNumber
@desc Rejects nonnumeric, infinite and NaN coordinates before mutation.
!]]
local function validateNumber(vInput, sName)
    if (rawtype(vInput) ~= "number" or vInput ~= vInput or
        vInput == _nHuge or vInput == -_nHuge) then
        error("Point: '"..sName.."' must be a finite number.", 3);
    end
end

--[[!
@fqxn LuaEx.Primitives.point
@pulsarlua function point
@desc A small table-like object for storing validated X and Y coordinates. Coordinates accept integers, floats and negative values. Omitted coordinates default to zero. Line accepts its numeric coordinates rather than the point object itself. Ordinary metatable access cannot expose backing data; rawset and debug tools bypass normal Lua protections.
@param number|nil nX Initial X coordinate; defaults to zero.
@param number|nil nY Initial Y coordinate; defaults to zero.
@ret primitive A point primitive.
@example
local oPoint = point(1.7, -2);
oPoint.x = 4;
local oLine = line(oPoint.x, oPoint.y, 6, 8);
!]]
local function build(nX, nY)
    if (nX == nil) then
        nX = 0;
    end

    if (nY == nil) then
        nY = 0;
    end

    validateNumber(nX, "x");
    validateNumber(nY, "y");

    local tActual = {
        --[[!
        @fqxn LuaEx.Primitives.point.Properties.x
        @pulsarlua number point.x
        @desc Writable finite X coordinate. Invalid assignments leave the previous value intact.
        !]]
        x = nX,
        --[[!
        @fqxn LuaEx.Primitives.point.Properties.y
        @pulsarlua number point.y
        @desc Writable finite Y coordinate. Invalid assignments leave the previous value intact.
        !]]
        y = nY,
    };

    --[[!
    @fqxn LuaEx.Primitives.point.Functions.getState
    @desc Copies defining geometry and update settings. Derived caches are not saved.
    @ret table tState Independent restoration data.
    @scope local
    !]]
    local function getState()

        return {
            x = tActual.x,
            y = tActual.y,
        };
    end

    return rawsetmetatable({}, {
        __index = tActual,
        __newindex = function(tInput, vKey, vValue)
            if (vKey ~= "x" and vKey ~= "y") then
                error("Point: cannot set field '"..tostring(vKey).."'.", 2);
            end

            validateNumber(vValue, vKey);
            tActual[vKey] = vValue;
        end,
        --[[!
        @fqxn LuaEx.Primitives.point.Metamethods.__clone
        @desc Creates independent geometry from current defining inputs, retaining update settings.
        @ret primitive oCopy Independent point primitive.
        !]]
        __clone = function()

            return pointFactory.deserialize(getState());
        end,
        --[[!
        @fqxn LuaEx.Primitives.point.Metamethods.__serialize
        @desc Supplies fresh defining state for global serialize; derived values are recomputed.
        @ret table tState Restoration data.
        !]]
        __serialize = getState,
        __serialtype = "point",
        __type = "primitive",
        __subtype = "point",
        __metatable = {__type = "primitive", __subtype = "point"},
    });
end

local pointFactoryActual = {
    --[[!
    @fqxn LuaEx.Primitives.point.Functions.deserialize
    @pulsarlua function point.deserialize
    @desc Validates saved defining state, rebuilds geometry and restores update settings.
    Invalid state raises before a restored object is returned. Derived values are not trusted.
    @param table tState State supplied by global serialize or the object's __serialize hook.
    @ret primitive oCopy Restored independent point primitive.
    !]]
    deserialize = function(tState)

        type.assert.table(tState);
        local tAllowed = { x = true, y = true };

        -- Step 1: reject unknown state fields before constructing an object.
        for sField in pairs(tState) do
            assert(tAllowed[sField], "Unknown point restoration field.");
        end

        -- Step 2: require all defining coordinates/sizes as finite numbers.
        for _, sField in ipairs({ "x", "y" }) do
            local nValue = tState[sField];
            assert(rawtype(nValue) == "number" and nValue == nValue and math.abs(nValue) < math.huge,
                   "Invalid point restoration number: "..sField);
        end

        -- Step 3: constructor validation enforces geometry-specific constraints.
        local oCopy = build(tState.x, tState.y);
        return oCopy;
    end,
};
local pointFactoryMeta = {
    __call = function(this, ...)

        return build(...);
    end,
    __index = function(t, k)

        return pointFactoryActual[k] or nil;
    end,
    __newindex = function()

        error("point factory members cannot be assigned directly.", 2);
    end,
    __type = "pointPrimitiveFactory",
};
pointFactory = {};
pointFactoryMeta.__clone = function() return pointFactory; end;
pointFactoryMeta.__serialize = function() return "point"; end;
pointFactoryMeta.__metatable = table.readonly({
    __type = pointFactoryMeta.__type,
    __call = pointFactoryMeta.__call,
    __clone = pointFactoryMeta.__clone,
    __serialize = pointFactoryMeta.__serialize,
});
setmetatable(pointFactory, pointFactoryMeta);
require("LuaEx.lib.serializer").registerFactory(pointFactory, {name = "point", types = {"point"}});
return pointFactory;
