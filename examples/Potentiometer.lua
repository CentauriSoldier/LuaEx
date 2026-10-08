--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
if not (LUAEX_INIT) then
    local function getsourcepath()
        local sPath = debug.getinfo(1, "S").source:gsub("^@", "");
        local sDirectory = sPath:match("^(.*)[/\\]") or ".";
        return sDirectory;
    end

    local sSourcePath = getsourcepath();
    package.path = package.path..";"..sSourcePath.."/../../?.lua;";
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================

--[[NOTE:
    A Potentiometer represents a bounded position and a movement rate.
    NONE clamps at the endpoints, REVOLVE wraps an inclusive range and ALT
    bounces between the endpoints. In alternating mode, increase follows the
    current direction and decrease moves against it. adjust always adds an
    absolute signed amount, independently of the current direction.
]]

local function printPosition(sLabel, oPot)
    local nSpan = oPot.getMax() - oPot.getMin();
    local nIndex = math.floor((oPot.getPos() - oPot.getMin()) / nSpan * 20 + 0.5);
    local sDirection = "clamped";

    if (oPot.isAscending()) then
        sDirection = "ascending";
    elseif (oPot.isDescending()) then
        sDirection = "descending";
    end

    local sBar = string.rep("-", nIndex).."|"..string.rep("-", 20 - nIndex);
    print(string.format("%-30s [%s] position=%s, %s", sLabel..":", sBar, tostring(oPot.getPos()), sDirection));
end

--==============================================================================
--============================== Clamped Movement ==============================
--==============================================================================
local oPot = Potentiometer(0, 10, 5, 2); --minimum, maximum, position, rate, continuity
assert(oPot.getMin() == 0 and oPot.getMax() == 10 and oPot.getRate() == 2);
assert(oPot.getContinuity() == POT_CONTINUITY_NONE);
printPosition("Created", oPot);

oPot.increase(); --5 + 2 = 7
printPosition("Increase once", oPot);
oPot.increase(3); --requested 13; clamps to 10
assert(oPot.isAtEnd() and not oPot.isAtStart());
printPosition("Clamped at maximum", oPot);
oPot.decrease(6); --requested -2; clamps to 0
assert(oPot.isAtStart() and not oPot.isAtEnd());
printPosition("Clamped at minimum", oPot);
oPot.adjust(3); --absolute adjustment to 3
oPot.adjust(); --no amount supplied: use rate, reaching 5
oPot.increase(0); --explicit zero multiplier changes nothing
assert(oPot.getPos() == 5);

--==============================================================================
--============================== Inclusive Revolution ==========================
--==============================================================================
local oWrap = Potentiometer(10, 20, 20, 1, POT_CONTINUITY_REVOLVE);
assert(oWrap.isRevolving() and oWrap.isAscending());
printPosition("Revolving at maximum", oWrap);
oWrap.increase(); --20 -> 10; eleven integer positions in the inclusive range
assert(oWrap.getPos() == 10);
printPosition("Wrapped forward", oWrap);
oWrap.decrease(); --10 -> 20
assert(oWrap.getPos() == 20);
printPosition("Wrapped backward", oWrap);
oWrap.setPos(9); --also wraps correctly with a nonzero minimum
assert(oWrap.getPos() == 20);
oWrap.setPos(1000000000); --large movements do not require recursive wrapping
printPosition("Large wrapped position", oWrap);

local oDocumentedWrap = Potentiometer(0, 100, 120, 1, POT_CONTINUITY_REVOLVE);
assert(oDocumentedWrap.getPos() == 19); --inclusive period is 101, not 100
--Fractional values in the final one-unit seam clamp to maximum.
oWrap.setPos(20.5);
assert(oWrap.getPos() == 20);

--==============================================================================
--=============================== Alternating Movement =========================
--==============================================================================
local oBounce = Potentiometer(0, 10, 0, 1, POT_CONTINUITY_ALT);
assert(oBounce.isAlternating() and oBounce.isAscending());
printPosition("Alternating start", oBounce);
oBounce.increase(10); --exact endpoint retains direction until it is crossed
assert(oBounce.isAtEnd() and oBounce.isAscending());
printPosition("Reached maximum", oBounce);
oBounce.increase(); --overshoot reflects to 9 and reverses direction
assert(oBounce.getPos() == 9 and oBounce.isDescending());
printPosition("Reflected", oBounce);
oBounce.increase(3); --logical increase now descends: 9 -> 6
printPosition("Follow descending direction", oBounce);
oBounce.decrease(2); --logical decrease goes against it: 6 -> 8
assert(oBounce.getPos() == 8);
printPosition("Against descending direction", oBounce);
oBounce.adjust(1); --absolute adjustment ignores direction: 8 -> 9
assert(oBounce.getPos() == 9 and oBounce.isDescending());

local oMultiple = Potentiometer(0, 10, 0, 1, POT_CONTINUITY_ALT);
oMultiple.increase(25); --0 -> 10 -> 0 -> 5: two boundary crossings
assert(oMultiple.getPos() == 5 and oMultiple.isAscending());
printPosition("Multiple bounces", oMultiple);

local oFractional = Potentiometer(-2, 2, 1.5, 0.5, POT_CONTINUITY_ALT);
oFractional.increase(2); --requested 2.5; reflects to 1.5
assert(oFractional.getPos() == 1.5 and oFractional.isDescending());
printPosition("Fractional reflected position", oFractional);

--==============================================================================
--=============================== Settings and Bounds ==========================
--==============================================================================
oPot.setPos(9);
oPot.setMax(5); --position clamps to 5
assert(oPot.getPos() == 5 and oPot.isAtEnd());
oPot.setRate(-100); --rate is a magnitude, capped to the span
assert(oPot.getRate() == 5);
oPot.setMin(4); --smaller span also reduces the rate
assert(oPot.getRate() == 1);
printPosition("Changed bounds", oPot);

oPot.setMin(100); --minimum cannot reach maximum; becomes maximum - 1
assert(oPot.getMin() == 4);
oPot.setMax(-100); --maximum cannot reach minimum; becomes minimum + 1
assert(oPot.getMax() == 5);
oPot.setContinuity(POT_CONTINUITY_REVOLVE);
assert(oPot.isRevolving());
oPot.setContinuity(POT_CONTINUITY_NONE);
assert(not oPot.isAscending() and not oPot.isDescending());

local oRepaired = Potentiometer(10, 5, 7, -100);
assert(oRepaired.getMin() == 10 and oRepaired.getMax() == 11);
assert(oRepaired.getPos() == 10 and oRepaired.getRate() == 1);
--Omitted/nonnumeric constructor arguments use defaults; nonfinite numbers are rejected.
local oDefault = Potentiometer();
assert(oDefault.getMin() == 0 and oDefault.getMax() == 99 and oDefault.getPos() == 0);
local bAccepted = pcall(function() oDefault.setPos(math.huge); end);
assert(not bAccepted and oDefault.getPos() == 0);

--==============================================================================
--============================ Clone and Serialization =========================
--==============================================================================
local oOriginal = Potentiometer(0, 10, 11, 1, POT_CONTINUITY_ALT); --9, descending
local oCopy = clone(oOriginal);
oCopy.increase();
assert(oCopy.getPos() == 8 and oOriginal.getPos() == 9);
assert(oCopy.isDescending());
printPosition("Independent clone", oCopy);

local sSaved = serialize(oOriginal);
local oRestored = deserialize(sSaved); --current global API, preserving direction
assert(oRestored.getPos() == 9 and oRestored.isDescending());
oRestored.increase();
assert(oRestored.getPos() == 8);
printPosition("Restored object", oRestored);

--The instance snapshot API is available when another object owns the state.
local sSnapshot = oOriginal.serialize();
local tSnapshot = oOriginal.serialize(true); --unpacked table instead of a string
local oTarget = Potentiometer();
oTarget.deserialize(sSnapshot); --restore into an existing object
assert(oTarget.getPos() == 9 and oTarget.isDescending());
local oFromTable = Potentiometer.deserialize(tSnapshot); --static factory
assert(oFromTable.getPos() == 9 and oFromTable.isDescending());

--Malformed snapshots are rejected without partially replacing existing state.
tSnapshot.rate = -1;
bAccepted = pcall(function() oTarget.deserialize(tSnapshot); end);
assert(not bAccepted and oTarget.getPos() == 9 and oTarget.getRate() == 1);
print("Potentiometer example complete.");
