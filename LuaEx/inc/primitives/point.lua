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
return function(nX, nY)
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

    return rawsetmetatable({}, {
        __index = tActual,
        __newindex = function(tInput, vKey, vValue)
            if (vKey ~= "x" and vKey ~= "y") then
                error("Point: cannot set field '"..tostring(vKey).."'.", 2);
            end

            validateNumber(vValue, vKey);
            tActual[vKey] = vValue;
        end,
        __type = "primitive",
        __subtype = "point",
        __metatable = {__type = "primitive", __subtype = "point"},
    });
end
