--LOCALIZATION
local class = class;

-- Reject NaN, infinities and fractions while allowing negative relative offsets.
local function validateCoordinate(nValue)
    assert(rawtype(nValue) == "number" and nValue == nValue and
           nValue ~= math.huge and nValue ~= -math.huge and nValue % 1 == 0,
           "SlotPattern coordinates must be finite integers.");
end

-- Validate every coordinate record and return fresh tables instead of retaining caller-owned input.
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

        -- Track both coordinates so duplicate cells are rejected regardless of their list positions.
        local nX, nY = tSlot.x, tSlot.y;
        tSeen[nX] = tSeen[nX] or {};
        assert(not tSeen[nX][nY], "SlotPattern contains duplicate coordinates.");
        tSeen[nX][nY] = true;
        tSlots[nIndex] = {x = nX, y = nY};
        nCount = nCount + 1;
    end

    -- Valid integer keys can still leave holes; verify every position in the counted range.
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

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.__clone
        @desc Constructs an independent pattern; the constructor copies every coordinate record.
    !]]
    __clone = function(this, cdat)
        return SlotPattern(cdat.pri.slots);
    end,

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.__len
        @desc Returns occupied-coordinate count rather than the area of the bounding rectangle.
    !]]
    __len = function(this, cdat)
        return #cdat.pri.slots;
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
    slots = {},

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.validateSnapshot
        @desc Validates and independently copies all saved coordinates before accepting the pattern.
    !]]
    validateSnapshot = function(tState)
        assert(rawtype(tState.pri) == "table", "Invalid SlotPattern snapshot.");
        tState.pri.slots = copySlots(tState.pri.slots);
    end,

},
{--PROTECTED
},
{--PUBLIC

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.SlotPattern
        @desc Creates an empty layout, or validates and copies the supplied relative coordinates.
    !]]
    SlotPattern = function(this, cdat, tSlots)

        if (tSlots ~= nil) then
            this.setSlots(tSlots);
        end
    end,

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.setSlots
        @desc Validates the entire input before replacing the layout, leaving the previous pattern intact on
        failure.
    !]]
    setSlots = function(this, cdat, tSlots)

        -- Validate and copy everything before replacing the current layout.
        cdat.pri.slots = copySlots(tSlots);

        return this;
    end,

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.getSlots
        @desc Returns independent coordinate tables so callers cannot mutate the stored layout.
    !]]
    getSlots = function(this, cdat)
        return copySlots(cdat.pri.slots);
    end,

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.getSlotCount
        @desc Returns the number of occupied relative coordinates.
    !]]
    getSlotCount = function(this, cdat)
        return #cdat.pri.slots;
    end,

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.contains
        @desc Validates integer coordinates and reports whether that exact relative cell belongs to the pattern.
    !]]
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

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.eachSlot
        @desc Captures a copied layout and returns an iterator yielding index, x and y.
    !]]
    eachSlot = function(this, cdat)

        -- Capture a copy so later pattern edits do not alter an iteration already in progress.
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

    --[[!
        @fqxn CoG.ItemSystem.SlotPattern.Methods.getBounds
        @desc Returns inclusive minimum/maximum coordinates and rectangle dimensions; an empty pattern returns
        nil.
    !]]
    getBounds = function(this, cdat)
        local tSlots = cdat.pri.slots;

        if (#tSlots == 0) then
            return nil;
        end

        -- Seed bounds from an occupied cell so offset-only patterns are not enlarged toward zero.
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
