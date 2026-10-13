--LOCALIZATION
local class = class;

local function validateCoordinate(nValue)
    assert(rawtype(nValue) == "number" and nValue == nValue and
           nValue ~= math.huge and nValue ~= -math.huge and nValue % 1 == 0,
           "SlotPattern coordinates must be finite integers.");
end

local function copySlots(tInput)
    assert(rawtype(tInput) == "table", "SlotPattern requires a table of relative slots.");
    local tSlots = {};
    local tSeen = {};
    local nCount = 0;

    for nIndex, tSlot in pairs(tInput) do
        assert(rawtype(nIndex) == "number" and nIndex >= 1 and nIndex % 1 == 0,
               "SlotPattern slots must use positive integer indices.");
        assert(rawtype(tSlot) == "table", "Each slot must be a table containing x and y.");
        validateCoordinate(tSlot.x);
        validateCoordinate(tSlot.y);

        for sField in pairs(tSlot) do

            assert(sField == "x" or sField == "y", "Unknown slot coordinate field.");
        end

        local nX, nY = tSlot.x, tSlot.y;
        tSeen[nX] = tSeen[nX] or {};
        assert(not tSeen[nX][nY], "SlotPattern contains duplicate coordinates.");
        tSeen[nX][nY] = true;
        tSlots[nIndex] = {x = nX, y = nY};
        nCount = nCount + 1;
    end

    for nIndex = 1, nCount do
        assert(tSlots[nIndex] ~= nil, "SlotPattern slot lists cannot contain holes.");
    end

    return tSlots;
end

--[[!
    @fqxn CoG.ItemSystem.SlotPattern
    @desc An occupied-slot layout using relative integer x/y coordinates.
    The origin is the caller's placement anchor; negative offsets are allowed.
    Slot count is derived from occupied coordinates, not the bounding rectangle.
    Empty patterns are valid. Inputs and returned layouts are copied independently.
    This describes geometry only; containers decide fit, occupancy and placement.
    @ex
    local oPattern = SlotPattern({{x = 0, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}});
    assert(oPattern.getSlotCount() == 3); --L shape inside a 2-by-2 bounding box
!]]
return class("SlotPattern",
{--METAMETHODS
    __clone = function(this, cdat)
        return SlotPattern(cdat.pri.slots);
    end,

    __len = function(this, cdat)
        return #cdat.pri.slots;
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
    slots = {},

    validateSnapshot = function(tState)
        assert(rawtype(tState.pri) == "table", "Invalid SlotPattern snapshot.");
        tState.pri.slots = copySlots(tState.pri.slots);
    end,

},
{--PROTECTED
},
{--PUBLIC
    SlotPattern = function(this, cdat, tSlots)

        if (tSlots ~= nil) then
            this.setSlots(tSlots);
        end

    end,

    setSlots = function(this, cdat, tSlots)
        -- Validate and copy everything before replacing the current layout.
        cdat.pri.slots = copySlots(tSlots);
        return this;
    end,

    getSlots = function(this, cdat)
        return copySlots(cdat.pri.slots);
    end,

    getSlotCount = function(this, cdat)
        return #cdat.pri.slots;
    end,

    contains = function(this, cdat, nX, nY)
        validateCoordinate(nX);
        validateCoordinate(nY);

        for _, tSlot in ipairs(cdat.pri.slots) do

            if (tSlot.x == nX and tSlot.y == nY) then
                return true;
            end

        end

        return false;
    end,

    eachSlot = function(this, cdat)
        local tSlots = this.getSlots();
        local nIndex = 0;

        return function()
            nIndex = nIndex + 1;
            local tSlot = tSlots[nIndex];

            if (tSlot) then
                return nIndex, tSlot.x, tSlot.y;
            end

        end;

    end,

    getBounds = function(this, cdat)
        local tSlots = cdat.pri.slots;

        if (#tSlots == 0) then
            return nil;
        end

        local nMinX, nMaxX = tSlots[1].x, tSlots[1].x;
        local nMinY, nMaxY = tSlots[1].y, tSlots[1].y;

        for _, tSlot in ipairs(tSlots) do
            nMinX, nMaxX = math.min(nMinX, tSlot.x), math.max(nMaxX, tSlot.x);
            nMinY, nMaxY = math.min(nMinY, tSlot.y), math.max(nMaxY, tSlot.y);
        end

        return {minX = nMinX, maxX = nMaxX, minY = nMinY, maxY = nMaxY,
                width = nMaxX - nMinX + 1, height = nMaxY - nMinY + 1};
    end,

},
nil,   --extending class
false, --if the class is final
nil    --interface(s)
);
