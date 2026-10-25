--[[!
@fqxn LuaEx.Classes.Potentiometer
@author Centauri Soldier
@copyright Public Domain
@description
    <h2>Potentiometer</h2>
    <p>A logical potentiometer object. The client can set minimum and maximum values for the object, as well as rate of increase/decrease.
    Note: 'increase' and 'decrease' are logical terms referring to motion along a line based on the current direction. E.g., If a pot is
    alternating and descending, 'increase' would cause the positional value to be absolutely reduced, while 'decrease' would have the opposite
    effect.
    By default, values are clamped at min and max; however, if the object is set to be revolving (or alternating), any values which exceed the minimum or maximum
    boundaries, are carried over. For example, imagine a pot is set to have a min value of 0 and a max of 100. Then, imagine its position is set to 120.
    If revolving, it would have a final positional value of 19; if alternating it would have a final positional value of 80 and, if neither, its final positional
    value would be 100.</p>
@license <p>The Unlicense<br>
<br>
@version 1.5
@versionhistory
<ul>
    <li>
        <b>1.5</b>
        <br>
        <p>Change: updated to be compatible with new LuaEx class system.</p>
    </li>
    <li>
        <b>1.4</b>
        <br>
        <p>Bugfix: clamping values was not working correctly cause unpredictable results.</p>
    </li>
    <li>
        <b>1.3</b>
        <br>
        <p>Added serialization and deserialization methods.</p>
    </li>
    <li>
        <b>1.2</b>
        <br>
        <p>Fixed a bug in the revolution mechanism.</p>
        <p>Added the ability which allows the potentiometer to be continuous in a revolving or alternating manner.</p>
    </li>
    <li>
        <b>1.1</b>
        <br>
        <p>Added the option for the potentiometer to be continuous in a revolving manner.</p>
    </li>
    <li>
        <b>1.0</b>
        <br>
        <p>Created the module.</p>
    </li>
</ul>
@website https://github.com/CentauriSoldier
!]]

--[[!
@fqxn LuaEx.Classes.Potentiometer.Continuity
@desc NONE clamps to the endpoints. REVOLVE uses the inclusive period maximum - minimum + 1; fractional values in the final one-unit seam clamp to maximum. ALT reflects overshoot, preserving every boundary crossing and its direction change. Bounds and arithmetic must remain finite and representable.
@ex
local oWrap   = Potentiometer(0, 100, 120, 1, POT_CONTINUITY_REVOLVE);
local oBounce = Potentiometer(0, 100, 120, 1, POT_CONTINUITY_ALT);
assert(oWrap.getPos() == 19 and oBounce.getPos() == 80);
!]]

--Default constructor values retain the original fallback behavior.
local _nMinDefault  = 0;
local _nMaxDefault  = 99;
local _nRateDefault = 1;

constant("POT_CONTINUITY_NONE", 0);
constant("POT_CONTINUITY_REVOLVE", 1);
constant("POT_CONTINUITY_ALT", 2);

local function continuityIsValid(nValue)
    return rawtype(nValue) == "number" and
        (nValue == POT_CONTINUITY_NONE or nValue == POT_CONTINUITY_REVOLVE or nValue == POT_CONTINUITY_ALT);
end

local function validateNumber(nValue)
    type.assert.number(nValue);
    assert(nValue == nValue and nValue ~= math.huge and nValue ~= -math.huge, "Potentiometer values must be finite.");
end

local function updateStatus(pri)
    pri.isAtStart = pri.pos == pri.min;
    pri.isAtEnd   = pri.pos == pri.max;
end

local function normalizePosition(pri, nPosition)
    validateNumber(nPosition);
    local nSpan          = pri.max - pri.min;
    local nPositionFinal = nPosition;

    if (pri.continuity == POT_CONTINUITY_REVOLVE) then
        if (nPosition < pri.min or nPosition > pri.max) then
            --Inclusive revolution: 0..100 has a period of 101, so 120 becomes 19.
            local nPeriod = nSpan + 1;
            nPositionFinal = pri.min + ((nPosition % nPeriod - pri.min % nPeriod) % nPeriod);
            --Fractional values in the inclusive one-unit seam stay at the upper endpoint.
            nPositionFinal = math.min(pri.max, nPositionFinal);
        end
    elseif (pri.continuity == POT_CONTINUITY_ALT) then
        if (nPosition < pri.min or nPosition > pri.max) then
            local nPeriod = 2 * nSpan;
            local nPhase  = (nPosition % nPeriod - pri.min % nPeriod) % nPeriod;
            local nCrossings;

            if (nPosition > pri.max) then
                nCrossings = math.ceil((nPosition - pri.max) / nSpan);
            else
                nCrossings = math.ceil((pri.min - nPosition) / nSpan);
            end

            nPositionFinal = pri.min + (nPhase <= nSpan and nPhase or nPeriod - nPhase);

            if (nCrossings % 2 == 1) then
                pri.alternator = -pri.alternator;
            end
        end
    else
        nPositionFinal = math.max(pri.min, math.min(pri.max, nPosition));
    end

    pri.pos = nPositionFinal;
    updateStatus(pri);
end

local function validateBounds(nMin, nMax)
    validateNumber(nMin);
    validateNumber(nMax);
    local nSpan = nMax - nMin;
    assert(nSpan > 0 and nSpan < math.huge and nSpan * 2 < math.huge and nSpan + 1 > nSpan,
        "Potentiometer bounds must have a finite, positive representable span.");
end

return class("Potentiometer",
{--METAMETHODS
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.__clone
    @desc Creates an independent copy preserving bounds, rate, position, continuity and direction.
    @ret Potentiometer oCopy The copy.
    @ex
    local oPot  = Potentiometer(0, 10, 11, 1, POT_CONTINUITY_ALT);
    local oCopy = clone(oPot);
    assert(oCopy.isDescending() and oCopy.getPos() == 9);
    !]]
    __clone = function(this, cdat)
        local pri          = cdat.pri;
        local oCopy        = Potentiometer(pri.min, pri.max, pri.pos, pri.rate, pri.continuity);
        local tCopyPrivate = cdat.ins[oCopy].pri;
        tCopyPrivate.alternator = pri.alternator;
        updateStatus(tCopyPrivate);
        return oCopy;
    end,
},
{--STATIC PUBLIC
    },
{--PRIVATE
    -- Restoration skips the constructor, so validate saved bounds/direction and
    -- rebuild derived status through the autogenerated class snapshot hook.
    validateSnapshot = function(tState)
        local pri = tState.pri;
        type.assert.table(pri);

        for _, sField in ipairs({"min", "max", "pos", "rate", "alternator"}) do
            validateNumber(pri[sField]);
        end

        assert(pri.min < pri.max and math.isfinite(pri.max - pri.min), "Invalid Potentiometer snapshot bounds.");
        assert(pri.pos >= pri.min and pri.pos <= pri.max, "Invalid Potentiometer snapshot position.");
        assert(pri.rate >= 0 and pri.rate <= pri.max - pri.min, "Invalid Potentiometer snapshot rate.");
        assert(continuityIsValid(pri.continuity), "Invalid Potentiometer snapshot continuity.");
        assert(pri.alternator == 1 or pri.alternator == -1, "Invalid Potentiometer snapshot direction.");
        assert(rawtype(pri.isAtStart) == "boolean" and rawtype(pri.isAtEnd) == "boolean",
               "Invalid Potentiometer snapshot status.");
        updateStatus(pri);
    end,
    alternator = 1,
    continuity = POT_CONTINUITY_NONE,
    isAtStart  = false,
    isAtEnd    = false,
    min        = 0,
    max        = 99,
    pos        = 0,
    rate       = 1,
},
{--PROTECTED
},
{--PUBLIC
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.Potentiometer
    @pulsarlua function Potentiometer
    @desc Creates a bounded position. Nonnumeric or omitted arguments retain the original defaults. Invalid numeric bounds raise MAX to MIN + 1; rate is a nonnegative magnitude capped to the span. Nonfinite values are rejected.
    @param number|nil nMin Minimum; defaults to 0.
    @param number|nil nMax Maximum; defaults to 99.
    @param number|nil nPos Starting position; defaults to 0 and is normalized to the selected mode.
    @param number|nil nRate Rate magnitude; defaults to 1.
    @param number|nil nContinuity NONE, REVOLVE or ALT; defaults to NONE.
    @ret Potentiometer oPot The new object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    assert(oPot.getPos() == 5 and oPot.getRate() == 2);
    !]]
    Potentiometer = function(this, cdat, nMin, nMax, nPos, nRate, nContinuity)
        nMin = rawtype(nMin) == "number" and nMin or _nMinDefault;
        nMax = rawtype(nMax) == "number" and nMax or _nMaxDefault;
        nPos = rawtype(nPos) == "number" and nPos or _nMinDefault;
        nRate = rawtype(nRate) == "number" and nRate or _nRateDefault;
        validateNumber(nMin);
        validateNumber(nMax);
        validateNumber(nPos);
        validateNumber(nRate);

        if (nMax <= nMin) then
            nMax = nMin + 1;
        end

        validateBounds(nMin, nMax);
        local pri      = cdat.pri;
        pri.min        = nMin;
        pri.max        = nMax;
        pri.rate       = math.min(math.abs(nRate), nMax - nMin);
        pri.continuity = continuityIsValid(nContinuity) and nContinuity or POT_CONTINUITY_NONE;
        normalizePosition(pri, nPos);
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.adjust
    @pulsarlua function Potentiometer.adjust
    @desc Adds an absolute signed amount to position, independently of the alternating direction, then normalizes bounds.
    @param number|nil nValue Amount; defaults to the rate.
    @ret Potentiometer oPot This object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.adjust(-2);
    assert(oPot.getPos() == 3);
    !]]
    adjust = function(this, cdat, nValue)
        local pri     = cdat.pri;
        local nAmount = rawtype(nValue) == "number" and nValue or pri.rate;
        validateNumber(nAmount);
        normalizePosition(pri, pri.pos + nAmount);
        return this;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.decrease
    @pulsarlua function Potentiometer.decrease
    @desc Moves backward by rate times the multiplier relative to the current logical direction.
    @param number|nil nTimes Rate multiplier; defaults to 1.
    @ret Potentiometer oPot This object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.decrease(2);
    assert(oPot.getPos() == 1);
    !]]
    decrease = function(this, cdat, nTimes)
        local pri    = cdat.pri;
        local nCount = rawtype(nTimes) == "number" and nTimes or 1;
        validateNumber(nCount);
        normalizePosition(pri, pri.pos - pri.rate * nCount * pri.alternator);
        return this;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.getMax
    @pulsarlua function Potentiometer.getMax
    @desc Gets the current max.
    @ret number nValue The max.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    assert(oPot.getMax() == 10);
    !]]
    getMax = function(this, cdat)
        return cdat.pri.max;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.getMin
    @pulsarlua function Potentiometer.getMin
    @desc Gets the current min.
    @ret number nValue The min.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    assert(oPot.getMin() == 0);
    !]]
    getMin = function(this, cdat)
        return cdat.pri.min;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.getPos
    @pulsarlua function Potentiometer.getPos
    @desc Gets the current pos.
    @ret number nValue The pos.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    assert(oPot.getPos() == 5);
    !]]
    getPos = function(this, cdat)
        return cdat.pri.pos;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.getRate
    @pulsarlua function Potentiometer.getRate
    @desc Gets the current rate.
    @ret number nValue The rate.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    assert(oPot.getRate() == 2);
    !]]
    getRate = function(this, cdat)
        return cdat.pri.rate;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.getContinuity
    @pulsarlua function Potentiometer.getContinuity
    @desc Gets the current continuity.
    @ret number nValue The continuity.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    assert(oPot.getContinuity() == POT_CONTINUITY_NONE);
    !]]
    getContinuity = function(this, cdat)
        return cdat.pri.continuity;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.increase
    @pulsarlua function Potentiometer.increase
    @desc Moves forward by rate times the multiplier in the current logical direction. Alternating mode reflects overshoot and reverses direction once per boundary crossed.
    @param number|nil nTimes Rate multiplier; defaults to 1.
    @ret Potentiometer oPot This object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.increase(2);
    assert(oPot.getPos() == 9);
    !]]
    increase = function(this, cdat, nTimes)
        local pri    = cdat.pri;
        local nCount = rawtype(nTimes) == "number" and nTimes or 1;
        validateNumber(nCount);
        normalizePosition(pri, pri.pos + pri.rate * nCount * pri.alternator);
        return this;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.isAlternating
    @pulsarlua function Potentiometer.isAlternating
    @desc Checks whether alternating reflection is enabled.
    @ret boolean bResult The result.
    @ex
    local oPot = Potentiometer(0, 10, 5, 1, POT_CONTINUITY_ALT);
    assert(oPot.isAlternating());
    !]]
    isAlternating = function(this, cdat)
        return cdat.pri.continuity == POT_CONTINUITY_ALT;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.isAscending
    @pulsarlua function Potentiometer.isAscending
    @desc Checks whether a continuous mode currently advances toward maximum. Returns false in clamped mode.
    @ret boolean bResult The result.
    @ex
    local oPot = Potentiometer(0, 10, 5, 1, POT_CONTINUITY_ALT);
    assert(oPot.isAscending());
    !]]
    isAscending = function(this, cdat)
        local pri = cdat.pri;
        return pri.continuity ~= POT_CONTINUITY_NONE and pri.alternator == 1;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.isAtStart
    @pulsarlua function Potentiometer.isAtStart
    @desc Checks whether position equals minimum. This refers to the absolute endpoint, independently of direction.
    @ret boolean bResult The result.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.setPos(0);
    assert(oPot.isAtStart());
    !]]
    isAtStart = function(this, cdat)
        return cdat.pri.isAtStart;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.isAtEnd
    @pulsarlua function Potentiometer.isAtEnd
    @desc Checks whether position equals maximum. This refers to the absolute endpoint, independently of direction.
    @ret boolean bResult The result.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.setPos(10);
    assert(oPot.isAtEnd());
    !]]
    isAtEnd = function(this, cdat)
        return cdat.pri.isAtEnd;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.isDescending
    @pulsarlua function Potentiometer.isDescending
    @desc Checks whether alternating mode currently advances toward minimum.
    @ret boolean bResult The result.
    @ex
    local oPot = Potentiometer(0, 10, 11, 1, POT_CONTINUITY_ALT);
    assert(oPot.isDescending());
    !]]
    isDescending = function(this, cdat)
        local pri = cdat.pri;
        return pri.continuity == POT_CONTINUITY_ALT and pri.alternator == -1;
    end,
    --[[!
    @fqxn LuaEx.Classes.Potentiometer.isRevolving
    @pulsarlua function Potentiometer.isRevolving
    @desc Checks whether inclusive revolution is enabled.
    @ret boolean bResult The result.
    @ex
    local oPot = Potentiometer(0, 10, 5, 1, POT_CONTINUITY_REVOLVE);
    assert(oPot.isRevolving());
    !]]
    isRevolving = function(this, cdat)
        return cdat.pri.continuity == POT_CONTINUITY_REVOLVE;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.setMax
    @pulsarlua function Potentiometer.setMax
    @desc Sets maximum and normalizes position and rate. Values at or below minimum become minimum + 1. Nonnumeric input leaves state unchanged.
    @param number nValue The requested maximum.
    @ret Potentiometer oPot This object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.setMax(4);
    assert(oPot.getPos() == 4 and oPot.isAtEnd());
    !]]
    setMax = function(this, cdat, nValue)
        if (rawtype(nValue) == "number") then
            validateNumber(nValue);
            local pri  = cdat.pri;
            local nMax = nValue > pri.min and nValue or pri.min + 1;
            validateBounds(pri.min, nMax);
            pri.max  = nMax;
            pri.rate = math.min(pri.rate, pri.max - pri.min);
            normalizePosition(pri, pri.pos);
        end

        return this;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.setMin
    @pulsarlua function Potentiometer.setMin
    @desc Sets minimum and normalizes position and rate. Values at or above maximum become maximum - 1. Nonnumeric input leaves state unchanged.
    @param number nValue The requested minimum.
    @ret Potentiometer oPot This object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.setMin(6);
    assert(oPot.getPos() == 6 and oPot.isAtStart());
    !]]
    setMin = function(this, cdat, nValue)
        if (rawtype(nValue) == "number") then
            validateNumber(nValue);
            local pri  = cdat.pri;
            local nMin = nValue < pri.max and nValue or pri.max - 1;
            validateBounds(nMin, pri.max);
            pri.min  = nMin;
            pri.rate = math.min(pri.rate, pri.max - pri.min);
            normalizePosition(pri, pri.pos);
        end

        return this;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.setPos
    @pulsarlua function Potentiometer.setPos
    @desc Sets absolute position and applies the selected boundary behavior. Exact alternating endpoints retain direction until a boundary is crossed. Nonnumeric input leaves state unchanged.
    @param number nValue The requested position.
    @ret Potentiometer oPot This object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.setPos(12);
    assert(oPot.getPos() == 10);
    !]]
    setPos = function(this, cdat, nValue)
        if (rawtype(nValue) == "number") then
            normalizePosition(cdat.pri, nValue);
        end

        return this;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.setRate
    @pulsarlua function Potentiometer.setRate
    @desc Sets a nonnegative rate magnitude, capped to maximum minus minimum. Nonnumeric input leaves state unchanged.
    @param number nValue The requested rate.
    @ret Potentiometer oPot This object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.setRate(-3);
    assert(oPot.getRate() == 3);
    !]]
    setRate = function(this, cdat, nValue)
        if (rawtype(nValue) == "number") then
            validateNumber(nValue);
            local pri = cdat.pri;
            pri.rate  = math.min(math.abs(nValue), pri.max - pri.min);
        end

        return this;
    end,

    --[[!
    @fqxn LuaEx.Classes.Potentiometer.setContinuity
    @pulsarlua function Potentiometer.setContinuity
    @desc Sets a supported boundary mode. Unsupported values are ignored. Leaving alternating mode resets direction to ascending; no debugging output is emitted.
    @param number nContinuity A POT_CONTINUITY constant.
    @ret Potentiometer oPot This object.
    @ex
    local oPot = Potentiometer(0, 10, 5, 2);
    oPot.setContinuity(POT_CONTINUITY_REVOLVE);
    assert(oPot.isRevolving());
    !]]
    setContinuity = function(this, cdat, nContinuity)
        local pri = cdat.pri;

        if (continuityIsValid(nContinuity)) then
            pri.continuity = nContinuity;

            if (nContinuity ~= POT_CONTINUITY_ALT) then
                pri.alternator = 1;
            end
        end

        return this;
    end,
},
nil,
false,
nil
);
