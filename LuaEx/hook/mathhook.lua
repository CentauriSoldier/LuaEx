local math      = math;
local rawtype   = rawtype;
local string    = string;
local type      = type;

local _nExactIntegerMax = 9007199254740991;
local _sDigits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

local function validateNumber(nValue)
    type.assert.number(nValue);
    assert(rawtype(nValue) == "number" and nValue == nValue, "Expected a native number other than NaN.");
end


local function validateFinite(nValue)
    validateNumber(nValue);
    assert(nValue > -math.huge and nValue < math.huge, "Expected a finite number.");
end


local function validateInteger(nValue)
    validateFinite(nValue);
    assert(nValue % 1 == 0 and math.abs(nValue) <= _nExactIntegerMax,
           "Expected an exact integer between -9007199254740991 and 9007199254740991.");
end


local function validateBase(nBase)
    validateInteger(nBase);
    assert(nBase >= 2 and nBase <= 36, "Base must be between 2 and 36.");
end


local function validateFlag(bFlag)
    assert(bFlag == nil or rawtype(bFlag) == "boolean", "Rounding flag must be a boolean or nil.");
end


local function validateChannel(nChannel)
    validateInteger(nChannel);
    assert(nChannel >= 0 and nChannel <= 255, "RGB channels must be between 0 and 255.");
end


-- Native floating-point values retain Lua's arithmetic and comparison rules.
--[[!
    @fqxn LuaEx.Lua Hooks.math.Constants.e
    @pulsarlua number math.e
    @desc Euler's number, calculated as exp(1).
!]]
math.e = math.exp(1);
--[[!
    @fqxn LuaEx.Lua Hooks.math.Constants.inf
    @pulsarlua number math.inf
    @desc Native positive infinity, an alias of math.huge. Negate it for negative infinity.
!]]
math.inf = math.huge;
--[[!
    @fqxn LuaEx.Lua Hooks.math.Constants.nan
    @pulsarlua number math.nan
    @desc A native floating-point NaN. NaN is unequal to itself; use math.isnan to detect it.
!]]
math.nan = math.huge / math.huge;

-- Geometry has its own implementation while retaining the math.geometry API.
math.geometry = require("LuaEx.hook.math.geometry");


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.clamp
    @pulsarlua function math.clamp
    @desc Clamps a native number to inclusive ordered bounds. Infinity is supported; NaN and reversed bounds are rejected.
    @param number nValue The value.
    @param number nMinValue Minimum bound.
    @param number nMaxValue Maximum bound.
    @ret number nRet The clamped value.
    @ex print(math.clamp(12, 0, 10)); -- 10
!]]
function math.clamp(nValue, nMinValue, nMaxValue)
    validateNumber(nValue);
    validateNumber(nMinValue);
    validateNumber(nMaxValue);
    assert(nMinValue <= nMaxValue, "Clamp minimum exceeds maximum.");

    return math.max(nMinValue, math.min(nValue, nMaxValue));
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.convertbase
    @pulsarlua function math.convertbase
    @desc Converts a signed integer string between bases 2 through 36, using uppercase output digits. Numeric input is accepted only for base 10. Values must lie in the exact integer range -9007199254740991 through 9007199254740991; invalid digits and overflow are rejected.
    @param string|number vInput The input integer.
    @param number nFromBase Input base.
    @param number nToBase Output base.
    @ret string sRet The converted integer.
    @ex print(math.convertbase("FF", 16, 2)); -- 11111111
!]]
function math.convertbase(vInput, nFromBase, nToBase)
    validateBase(nFromBase);
    validateBase(nToBase);
    local nValue;

    if (rawtype(vInput) == "number") then
        assert(nFromBase == 10, "Numeric base conversion input requires source base 10.");
        validateInteger(vInput);
        nValue = vInput;
    else
        type.assert.string(vInput);
        local sInput = vInput:match("^%s*(.-)%s*$");
        assert(sInput:match("^[+-]?[%w]+$"), "Invalid base conversion input.");
        local bNegative = sInput:sub(1, 1) == "-";
        sInput = sInput:gsub("^[+-]", ""):upper();
        nValue = 0;

        -- Parse explicitly so tonumber's integer wrapping cannot conceal an
        -- oversized source string before the range check.
        for x = 1, #sInput do
            local nPosition = _sDigits:find(sInput:sub(x, x), 1, true);
            local nDigit = nPosition and nPosition - 1;
            assert(nDigit and nDigit < nFromBase, "Input contains digits outside its source base.");
            assert(nValue <= math.floor((_nExactIntegerMax - nDigit) / nFromBase),
                   "Base conversion input exceeds the exact integer range.");
            nValue = nValue * nFromBase + nDigit;
        end

        if (bNegative) then
            nValue = -nValue;
        end
    end

    local bNegative = nValue < 0;
    nValue = math.abs(nValue);
    local sRet = "";

    repeat
        local nDigit = nValue % nToBase;
        sRet = _sDigits:sub(nDigit + 1, nDigit + 1)..sRet;
        nValue = (nValue - nDigit) / nToBase;
    until nValue == 0

    if (bNegative) then
        sRet = "-"..sRet;
    end

    return sRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.counting
    @pulsarlua function math.counting
    @desc Converts a finite number's magnitude to a counting number (at least one). Floors by default, or rounds upward when requested.
    @param number nValue The input.
    @param boolean|nil bRaise Round upward; defaults to false.
    @ret number nRet The counting number.
    @ex print(math.counting(-2.7)); -- 2
!]]
function math.counting(nValue, bRaise)
    validateFinite(nValue);
    validateFlag(bRaise);

    local fRound = bRaise and math.ceil or math.floor;
    return math.max(1, fRound(math.abs(nValue)));
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.drift
    @pulsarlua function math.drift
    @desc Adds a uniformly selected integer offset in the inclusive range [-nDrift, nDrift] to a finite value.
    @param number nValue The base value.
    @param number nDrift Nonnegative exact integer offset limit.
    @ret number nRet The shifted value.
    @ex print(math.drift(10, 0)); -- 10
!]]
function math.drift(nValue, nDrift)
    validateFinite(nValue);
    validateInteger(nDrift);
    assert(nDrift >= 0, "Drift must be nonnegative.");
    local nRet = nValue + math.random(-nDrift, nDrift);
    validateFinite(nRet);

    return nRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.driftf
    @pulsarlua function math.driftf
    @desc Applies a random proportional drift using randomf's four-decimal grid. A drift of 0.1 permits offsets up to ten percent of the value in either direction.
    @param number nValue The finite base value.
    @param number nDrift Nonnegative finite proportional limit.
    @ret number nRet The shifted value.
    @ex print(math.driftf(10, 0)); -- 10
!]]
function math.driftf(nValue, nDrift)
    validateFinite(nValue);
    validateFinite(nDrift);
    assert(nDrift >= 0, "Drift must be nonnegative.");

    local nRet = nValue + nValue * math.randomf(-nDrift, nDrift);
    validateFinite(nRet);

    return nRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.factorial
    @pulsarlua function math.factorial
    @desc Calculates the factorial of a nonnegative integer, including 0! = 1. Returns a floating-point number; larger results may be rounded. Values above 170 are rejected to prevent infinity.
    @param number nValue Integer from 0 through 170.
    @ret number nRet The factorial.
    @ex print(math.factorial(5)); -- 120
!]]
function math.factorial(nValue)
    validateInteger(nValue);
    assert(nValue >= 0 and nValue <= 170, "Factorial input must be between 0 and 170.");
    local nRet = 1.0;

    for x = 2, nValue do
        nRet = nRet * x;
    end

    return nRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.gcf
    @pulsarlua function math.gcf
    @desc Gets the nonnegative greatest common factor of two exact integers. Signs are ignored; gcf(0, n) is abs(n), and gcf(0, 0) is zero.
    @param number nLeft First integer.
    @param number nRight Second integer.
    @ret number nRet The greatest common factor.
    @ex print(math.gcf(12, 18)); -- 6
!]]
function math.gcf(nLeft, nRight)
    validateInteger(nLeft);
    validateInteger(nRight);
    local nA = math.abs(nLeft);
    local nB = math.abs(nRight);

    -- The iterative Euclidean algorithm also handles either zero input.
    while (nB ~= 0) do
        nA, nB = nB, nA % nB;
    end

    return nA;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.inttorgb
    @pulsarlua function math.inttorgb
    @desc Unpacks a 24-bit color matching rgbtoint: red is the low byte, green the middle byte, and blue the high byte.
    @param number nColor Integer from 0 through 16777215.
    @ret number nR The red channel.
    @ret number nG The green channel.
    @ret number nB The blue channel.
    @ex print(math.inttorgb(math.rgbtoint(10, 20, 30))); -- 10 20 30
!]]
function math.inttorgb(nColor)
    validateInteger(nColor);
    assert(nColor >= 0 and nColor <= 16777215, "Color must be a 24-bit nonnegative integer.");

    local nR = nColor % 256;
    local nG = math.floor(nColor / 256) % 256;
    local nB = math.floor(nColor / 65536);

    return nR, nG, nB;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.isabstract
    @pulsarlua function math.isabstract
    @desc Checks whether a value is a native nonfinite number: NaN, positive infinity, or negative infinity. Returns false for finite numbers and non-numbers. Retained for compatibility; prefer math.isnan or math.isinf when checking a specific condition.
    @param any vInput The value to check.
    @ret boolean bIsAbstract Whether the value is a native nonfinite number.
    @ex print(math.isabstract(math.inf)); -- true
!]]
function math.isabstract(vInput)
    return math.isnan(vInput) or math.isinf(vInput);
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.iseven
    @pulsarlua function math.iseven
    @desc Checks whether a value is a finite integer divisible by two. Returns false for fractions and non-numbers.
    @param any vInput The value to check.
    @ret boolean bIsEven Whether the value is even.
    @ex print(math.iseven(4)); -- true
!]]
function math.iseven(vInput)
    return math.isinteger(vInput) and vInput % 2 == 0;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.isfinite
    @pulsarlua function math.isfinite
    @desc Checks whether a value is a native finite number, excluding NaN and either infinity. Returns false for non-numbers, including objects presenting a custom number type.
    @param any vInput The value to check.
    @ret boolean bIsFinite Whether the value is finite.
    @ex print(math.isfinite(42)); -- true
!]]
function math.isfinite(vInput)
    return rawtype(vInput) == "number" and vInput == vInput and
           vInput ~= math.huge and vInput ~= -math.huge;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.isinf
    @pulsarlua function math.isinf
    @desc Checks whether a value is native positive or negative infinity. Returns false for non-numbers.
    @param any vInput The value to check.
    @ret boolean bIsInfinity Whether the value is infinite.
    @ex print(math.isinf(math.inf)); -- true
!]]
function math.isinf(vInput)
    return rawtype(vInput) == "number" and
           (vInput == math.huge or vInput == -math.huge);
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.isinteger
    @pulsarlua function math.isinteger
    @desc Checks whether a value is a native finite number with no fractional part. Returns false for non-numbers, NaN, and infinity.
    @param any vInput The value to check.
    @ret boolean bIsInteger Whether the value is an integer.
    @ex print(math.isinteger(2.5)); -- false
!]]
function math.isinteger(vInput)
    return math.isfinite(vInput) and vInput % 1 == 0;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.isnan
    @pulsarlua function math.isnan
    @desc Checks whether a value is native NaN. NaN is unequal to itself; equality with math.nan cannot identify it. Returns false for non-numbers.
    @param any vInput The value to check.
    @ret boolean bIsNaN Whether the value is NaN.
    @ex print(math.isnan(math.nan)); -- true
!]]
function math.isnan(vInput)
    return rawtype(vInput) == "number" and vInput ~= vInput;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.isodd
    @pulsarlua function math.isodd
    @desc Checks whether a value is a finite integer not divisible by two. Returns false for fractions and non-numbers.
    @param any vInput The value to check.
    @ret boolean bIsOdd Whether the value is odd.
    @ex print(math.isodd(-3)); -- true
!]]
function math.isodd(vInput)
    return math.isinteger(vInput) and vInput % 2 ~= 0;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.randomf
    @pulsarlua function math.randomf
    @desc Generates a uniform random float on a four-decimal grid within inclusive finite bounds. Reversed bounds are accepted. Rejects intervals containing no grid value and scaled bounds outside the exact integer range. Uses the shared math.random stream.
    @param number nMinRaw One interval endpoint.
    @param number nMaxRaw The other endpoint.
    @ret number nResult The result.
    @ex print(math.randomf(1, 1)); -- 1
!]]
function math.randomf(nMinRaw, nMaxRaw)
    validateFinite(nMinRaw);
    validateFinite(nMaxRaw);
    local nMin = math.ceil(math.min(nMinRaw, nMaxRaw) * 10000);
    local nMax = math.floor(math.max(nMinRaw, nMaxRaw) * 10000);
    validateInteger(nMin);
    validateInteger(nMax);
    assert(nMin <= nMax, "Random float interval contains no four-decimal grid value.");

    return math.random(nMin, nMax) / 10000;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.ratio
    @pulsarlua function math.ratio
    @desc Reduces an integer ratio by its greatest common factor, preserving each input sign. A single zero is supported; the ratio 0:0 is undefined and rejected.
    @param number nLeft Left integer.
    @param number nRight Right integer.
    @ret table tRatio The reduced left and right values.
    @ex local tRatio = math.ratio(12, 18); print(tRatio.left, tRatio.right); -- 2 3
!]]
function math.ratio(nLeft, nRight)
    local nGCF = math.gcf(nLeft, nRight);
    assert(nGCF ~= 0, "The ratio 0:0 is undefined.");

    return {left = nLeft / nGCF, right = nRight / nGCF};
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.rgbtohex
    @pulsarlua function math.rgbtohex
    @desc Converts RGB channels to an uppercase 0xRRGGBB string. Finite integer channels are clamped to the range 0 through 255.
    @param number nR Red channel.
    @param number nG Green channel.
    @param number nB Blue channel.
    @ret string sHex The hexadecimal color.
    @ex print(math.rgbtohex(255, 0, 16)); -- 0xFF0010
!]]
function math.rgbtohex(nR, nG, nB)
    validateInteger(nR);
    validateInteger(nG);
    validateInteger(nB);
    nR = math.clamp(nR, 0, 255);
    nG = math.clamp(nG, 0, 255);
    nB = math.clamp(nB, 0, 255);

    return string.format("0x%02X%02X%02X", nR, nG, nB);
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.rgbtoint
    @pulsarlua function math.rgbtoint
    @desc Packs RGB integer channels in the range 0 through 255 into a 24-bit value. Retains the existing byte order: R + G * 256 + B * 65536. This byte order differs from the displayed 0xRRGGBB string.
    @param number nR Red channel.
    @param number nG Green channel.
    @param number nB Blue channel.
    @ret number nColor The packed color.
    @ex print(math.rgbtoint(1, 2, 3)); -- 197121
!]]
function math.rgbtoint(nR, nG, nB)
    validateChannel(nR);
    validateChannel(nG);
    validateChannel(nB);

    return nR + nG * 256 + nB * 65536;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.sum
    @pulsarlua function math.sum
    @desc Adds all supplied finite numbers in argument order. No arguments returns zero; nil holes, non-numbers, and nonfinite results are rejected.
    @param number ... Values to add.
    @ret number nRet The sum.
    @ex print(math.sum(1, 2, 3)); -- 6
!]]
function math.sum(...)
    local nRet = 0.0;

    for x = 1, select("#", ...) do
        local nValue = select(x, ...);
        validateFinite(nValue);
        nRet = nRet + nValue;
        validateFinite(nRet);
    end

    return nRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.math.Functions.whole
    @pulsarlua function math.whole
    @desc Converts a finite number's magnitude to a whole number, including zero. Floors by default, or rounds upward when requested.
    @param number nValue The input.
    @param boolean|nil bRaise Round upward; defaults to false.
    @ret number nRet The whole number.
    @ex print(math.whole(-0.7)); -- 0
!]]
function math.whole(nValue, bRaise)
    validateFinite(nValue);
    validateFlag(bRaise);

    local fRound = bRaise and math.ceil or math.floor;
    return fRound(math.abs(nValue));
end


return math;
