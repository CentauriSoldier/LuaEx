local math = math;
local rawtype = rawtype;
local type = type;

local geometry = {};

local function validateFinite(nValue)
    type.assert.number(nValue);
    assert(rawtype(nValue) == "number" and nValue == nValue and
           nValue > -math.huge and nValue < math.huge, "Rectangle values must be finite numbers.");
end


local function validateRect(tRect, bDimensionsOnly)
    type.assert.table(tRect);
    validateFinite(tRect.width);
    validateFinite(tRect.height);
    assert(tRect.width >= 0 and tRect.height >= 0, "Rectangle dimensions must be nonnegative.");

    if (not bDimensionsOnly) then
        validateFinite(tRect.x);
        validateFinite(tRect.y);
        validateFinite(tRect.x + tRect.width);
        validateFinite(tRect.y + tRect.height);
    end
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.geometry.Functions.fitrect
    @desc Fits an inner rectangle's aspect ratio to the largest size inside an outer rectangle, allowing enlargement. Returns a new rectangle at the outer origin or centered when requested; inputs remain unchanged. Inner width/height must be positive or the result is nil; a zero-size outer dimension produces a zero-size result. Coordinates and dimensions must be finite, and dimensions nonnegative.
    @param table tOuter Outer rectangle with x, y, width, and height.
    @param table tInner Inner rectangle with width and height.
    @param boolean|nil bCenter Center the result; defaults to false.
    @ret table|nil tRet The fitted rectangle, or nil for a degenerate inner rectangle.
    @ex local tFit = math.geometry.fitrect({x=0, y=0, width=100, height=50}, {width=10, height=10}, true);
        print(tFit.x, tFit.width); -- 25 50
!]]
function geometry.fitrect(tOuter, tInner, bCenter)
    validateRect(tOuter);
    validateRect(tInner, true);
    assert(bCenter == nil or rawtype(bCenter) == "boolean", "Center flag must be a boolean or nil.");
    local tRet;

    if (tInner.width > 0 and tInner.height > 0) then
        -- Derive the limiting dimension without an incremental search.
        -- Multiplying normalized factors also avoids an overflowing scale.
        local nLargest = math.max(tInner.width, tInner.height);
        local nWidthFactor = tInner.width / nLargest;
        local nHeightFactor = tInner.height / nLargest;
        assert(nWidthFactor > 0 and nHeightFactor > 0, "Rectangle aspect ratio is too extreme to represent.");
        local nWidth, nHeight;

        if (tOuter.width * nHeightFactor <= tOuter.height * nWidthFactor) then
            nWidth = tOuter.width;
            nHeight = tOuter.width * nHeightFactor / nWidthFactor;
        else
            nHeight = tOuter.height;
            nWidth = tOuter.height * nWidthFactor / nHeightFactor;
        end

        validateFinite(nWidth);
        validateFinite(nHeight);
        local nX = tOuter.x;
        local nY = tOuter.y;

        if (bCenter) then
            nX = nX + (tOuter.width - nWidth) / 2;
            nY = nY + (tOuter.height - nHeight) / 2;
        end

        tRet = {x=nX, y=nY, width=nWidth, height=nHeight};
    end

    return tRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.geometry.Functions.rectcontains
    @desc Checks whether two rectangles overlap with positive area. Edge/corner contact and zero-area rectangles return false. This legacy name means overlap, not full containment; use rectcontainsfully for containment.
    @param table tMe First rectangle with x, y, width, and height.
    @param table tOther Second rectangle with x, y, width, and height.
    @ret boolean bRet Whether there is positive-area overlap.
    @ex print(math.geometry.rectcontains({x=0,y=0,width=10,height=10}, {x=5,y=5,width=10,height=10})); -- true
!]]
function geometry.rectcontains(tMe, tOther)
    validateRect(tMe);
    validateRect(tOther);

    return math.max(tMe.x, tOther.x) < math.min(tMe.x + tMe.width, tOther.x + tOther.width) and
           math.max(tMe.y, tOther.y) < math.min(tMe.y + tMe.height, tOther.y + tOther.height);
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.geometry.Functions.rectcontainsfully
    @desc Checks whether the first rectangle contains the entire second rectangle, including its boundary. Equal rectangles and contained zero-area rectangles qualify.
    @param table tMe Containing rectangle with x, y, width, and height.
    @param table tOther Candidate rectangle with x, y, width, and height.
    @ret boolean bRet Whether the second rectangle is fully contained.
    @ex print(math.geometry.rectcontainsfully({x=0,y=0,width=10,height=10}, {x=2,y=2,width=3,height=3})); -- true
!]]
function geometry.rectcontainsfully(tMe, tOther)
    validateRect(tMe);
    validateRect(tOther);

    return tOther.x >= tMe.x and tOther.y >= tMe.y and
           tOther.x + tOther.width <= tMe.x + tMe.width and
           tOther.y + tOther.height <= tMe.y + tMe.height;
end


return geometry;
