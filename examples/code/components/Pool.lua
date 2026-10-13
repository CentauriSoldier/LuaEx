-- Independent code tutorial. Edit the values below, then Run code.
-- Locate the repository from this example (native Lua and browser virtual files).
local sExampleSource = debug.getinfo(1, "S").source:gsub("^@", "")
local sSourcePath = sExampleSource:match("^(.*)[/\\]") or "."
local sRepositoryPath = sSourcePath
for _ = 1, 8 do
    local file = io.open(sRepositoryPath .. "/LuaEx/init.lua", "r")
    if file then file:close(); break end
    sRepositoryPath = sRepositoryPath .. "/.."
end
package.path = sRepositoryPath .. "/?.lua;" .. package.path
if not LUAEX_INIT then require("LuaEx.init") end
local D=require("examples.support.tutorial").new("Pool", "Detailed scenarios, boundary behavior, numeric settings, callbacks and persistence.")
local nativeAssert=assert
local function assert(condition,message) D.check(message or "Scenario invariant",condition);return nativeAssert(condition,message) end

--[[NOTE:
    CURRENT is the spendable amount, MAX is total capacity and AVAILABLE is
    MAX minus RESERVED. Modifiers affect capacity, regeneration or reservation,
    rather than CURRENT. Percentages use fractions: 0.20 means 20%.

    All examples below run in order. Separate Pools keep each demonstration
    independent. Operators change the left Pool in place.
]]

local function printPool(sLabel, oPool)
    print(sLabel..": current="..oPool.get()
        ..", max="..oPool.get(Pool.ASPECT.MAX)
        ..", reserved="..oPool.get(Pool.ASPECT.RESERVED)
        ..", available="..oPool.get(Pool.ASPECT.AVAILABLE));
end

--==============================================================================
D.section("Values and Reservations", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oPool = Pool(200, 80); --maximum, current; defaults are 1 and 1
printPool("Created", oPool);

oPool.set(0.36, Pool.ASPECT.RESERVED_PERCENT); --reserve 36% of total capacity
print("Reserved: "..oPool.get(Pool.ASPECT.RESERVED)); --72
print("Available: "..oPool.get(Pool.ASPECT.AVAILABLE)); --128

oPool.set(0.10, Pool.ASPECT.MAX, Pool.MODIFIER.MULTIPLICATIVE_BONUS);
print("Max: "..oPool.get(Pool.ASPECT.MAX)); --220
print("Reserved: "..oPool.get(Pool.ASPECT.RESERVED)); --79.2
print("Available: "..oPool.get(Pool.ASPECT.AVAILABLE)); --140.8

oPool.set(10, Pool.ASPECT.RESERVED_FLAT); --flat and percentage reservations combine
printPool("Both reservation types", oPool);
oPool.set(0, Pool.ASPECT.RESERVED_FLAT);
oPool.set(0, Pool.ASPECT.RESERVED_PERCENT); --release reservations; no automatic refill

oPool.set(90); --CURRENT is the default aspect
oPool.adjust(-15); --spend 15 current points
assert(oPool.get() == 75);

local oResult, bAccepted, nOverage = oPool.set(1000);
print("Clamped current: "..oPool.get()); --220
assert(oResult == oPool and bAccepted and nOverage == 0);
--CURRENT is clamped; its overage return is always zero.
--Rejected capacity/reservation changes retain the previous settings.
local oLimited = Pool(100, 50);
oLimited.set(20, Pool.ASPECT.RESERVED_FLAT);
oResult, bAccepted, nOverage = oLimited.set(110, Pool.ASPECT.RESERVED_FLAT);
assert(not bAccepted and nOverage > 0);
assert(oLimited.get(Pool.ASPECT.RESERVED) == 20);
print("Rejected reservation: "..nOverage.." over the permitted limit");

--==============================================================================
D.section("Modifiers", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oModified = Pool(100, 40);
oModified.set(20, Pool.ASPECT.MAX, Pool.MODIFIER.BASE_BONUS);
oModified.set(10, Pool.ASPECT.MAX, Pool.MODIFIER.BASE_PENALTY);
oModified.set(0.5, Pool.ASPECT.MAX, Pool.MODIFIER.MULTIPLICATIVE_BONUS);
oModified.set(0.1, Pool.ASPECT.MAX, Pool.MODIFIER.MULTIPLICATIVE_PENALTY);
oModified.set(10, Pool.ASPECT.MAX, Pool.MODIFIER.ADDITIVE_BONUS);
oModified.set(4, Pool.ASPECT.MAX, Pool.MODIFIER.ADDITIVE_PENALTY);
--Final = (100 + 20 - 10) * (1 + 0.5 - 0.1) + 10 - 4 = 160.
assert(math.abs(oModified.get(Pool.ASPECT.MAX) - 160) < 0.000001);
oModified.set(150, Pool.ASPECT.MAX, Pool.MODIFIER.MAX); --upper cap on the final value
assert(oModified.get(Pool.ASPECT.MAX) == 150);
oModified.adjust(5, Pool.ASPECT.MAX, Pool.MODIFIER.BASE_BONUS);
print("Base bonus: "..oModified.get(Pool.ASPECT.MAX, Pool.MODIFIER.BASE_BONUS)); --25
--FINAL is calculated and cannot be set directly; BASE is the default for set/adjust.

--==============================================================================
D.section("Regeneration/Cycles", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oMana = Pool(100, 20);
oMana.set(5, Pool.ASPECT.CYCLE_FLAT);
oMana.set(0.10, Pool.ASPECT.CYCLE_PERCENT); --10% of total MAX, even with reservations
assert(oMana.get(Pool.ASPECT.CYCLE) == 15);
oMana.cycle(); --one regeneration amount
assert(oMana.get() == 35);
oMana.cycle(2); --apply twice the regeneration in one call
assert(oMana.get() == 65);
oMana.cycle(0); --no change
assert(oMana.get() == 65);
oMana.set(20, Pool.ASPECT.RESERVED_FLAT);
oMana.cycle(10); --caps at AVAILABLE, not total MAX
assert(oMana.get() == 80);
printPool("Regenerated mana", oMana);

local oFuel = Pool(100, 40);
oFuel.set(-5, Pool.ASPECT.CYCLE_FLAT); --negative cycle values consume current points
oFuel.cycle(2);
assert(oFuel.get() == 30);
printPool("Consumed fuel", oFuel);

--==============================================================================
D.section("Full, High and Low", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oStatus = Pool(100, 20);
oStatus.setLowMarker(0.25);
oStatus.setHighMarker(0.80);
assert(oStatus.getLowMarker() == 0.25 and oStatus.getHighMarker() == 0.80);
assert(oStatus.isLow() and not oStatus.isEmpty());
oStatus.set(20, Pool.ASPECT.RESERVED_FLAT);
oStatus.setFull(); --fills AVAILABLE: 80
assert(oStatus.isFull() and oStatus.isHigh());
oStatus.setHighMarker(0.90);
assert(oStatus.isFull() and not oStatus.isHigh());
--Full concerns available capacity; low/high thresholds use total maximum.
oStatus.set(80, Pool.ASPECT.RESERVED_FLAT);
assert(oStatus.get() == 20 and oStatus.isFull() and oStatus.isLow());
oStatus.setEmpty();
assert(oStatus.isEmpty() and not oStatus.isLow());
printPool("Empty reserved Pool", oStatus);

--==============================================================================
D.section("Events", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oHealth = Pool(100, 50);
local tEvents = {
    {Pool.EVENT.ON_INCREASE, "increase"},
    {Pool.EVENT.ON_DECREASE, "decrease"},
    {Pool.EVENT.ON_EMPTY, "empty"},
    {Pool.EVENT.ON_LOW, "low"},
    {Pool.EVENT.ON_HIGH, "high"},
    {Pool.EVENT.ON_FULL, "full"},
    {Pool.EVENT.ON_RESERVE, "reserve"},
    {Pool.EVENT.ON_UNRESERVE, "unreserve"},
};

for _, tEvent in ipairs(tEvents) do
    local sEventName = tEvent[2];
    oHealth.setEventCallback(tEvent[1], function(oChangedPool)
        print("Health event: "..sEventName..", current="..oChangedPool.get());
    end);
end

oHealth.setEventCallback(Pool.EVENT.ON_CYCLE, function(oChangedPool, nOld, nNew, nCycle, nMultiplier, nRequestedDelta)
    print("Health cycle: "..nOld.." -> "..nNew..", actual change="..(nNew - nOld)
        ..", requested change="..nRequestedDelta);
end);

oHealth.set(20); --decrease and low
oHealth.setEmpty(); --decrease and empty
oHealth.setFull(); --increase, high and full
oHealth.set(10, Pool.ASPECT.RESERVED_FLAT); --reserve; current falls to 90
oHealth.set(0, Pool.ASPECT.RESERVED_FLAT); --unreserve; current remains 90
oHealth.set(5, Pool.ASPECT.CYCLE_FLAT);
oHealth.cycle(); --current becomes 95; ON_CYCLE fires only on effective change

oHealth.setEventActive(Pool.EVENT.ON_DECREASE, false); --keep the callback, disable firing
oHealth.adjust(-10);
oHealth.setEventActive(Pool.EVENT.ON_DECREASE, true);
oHealth.adjust(-10);
oHealth.setEventCallback(Pool.EVENT.ON_DECREASE, nil); --clear and disable

local nIncreaseCalls = 0;
oHealth.setEventCallback(Pool.EVENT.ON_INCREASE, function()
    nIncreaseCalls = nIncreaseCalls + 1;
end, true); --third argument prevents automatic activation
oHealth.adjust(1);
assert(nIncreaseCalls == 0);
oHealth.setEventActive(Pool.EVENT.ON_INCREASE, true);
oHealth.adjust(1);
assert(nIncreaseCalls == 1);

--==============================================================================
D.section("Deferred Notifications", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oFirst  = Pool(100, 40);
local oSecond = Pool(100, 40);
oFirst.setEventCallback(Pool.EVENT.ON_DECREASE, function()
    --Both balances are updated before this callback runs.
    assert(oFirst.get() == 30 and oSecond.get() == 30);
    print("Deferred callback sees both committed balances");
end);
Pool.withDeferredEvents(function()
    oFirst.adjust(-10);
    oSecond.adjust(-10);
end);
--The action must not yield. This defers notifications; it does not roll back errors.

--==============================================================================
D.section("Operators", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oArithmetic = Pool(100, 20);
oArithmetic = oArithmetic + 10; --30
oArithmetic = oArithmetic - 5; --25
oArithmetic = oArithmetic * 2; --50
oArithmetic = oArithmetic / 3; --16: division is floored
assert(oArithmetic.get() == 16);
oArithmetic = oArithmetic + Pool(100, 4); --uses the other Pool's CURRENT: 20
assert(oArithmetic.get() == 20);
oArithmetic = oArithmetic % Pool(200, 1); --sets MAX base from the other's calculated MAX
assert(oArithmetic.get(Pool.ASPECT.MAX) == 200);
oArithmetic = oArithmetic % 120; --sets MAX base; this is not a remainder operation
oArithmetic = -oArithmetic; --empties the same Pool
assert(oArithmetic.isEmpty());
local nFilled = #oArithmetic; --fills AVAILABLE and returns the numeric CURRENT
assert(nFilled == 120 and oArithmetic.isFull());
printPool("Arithmetic Pool", oArithmetic);
--A Pool must be the left operand. Operators do not create an independent copy.

--==============================================================================
D.section("Clone and Serialization", "Follow the labelled values and verified checks for this scenario.")
--==============================================================================
local oOriginal = Pool(100, 40);
oOriginal.set(20, Pool.ASPECT.RESERVED_FLAT);
oOriginal.set(10, Pool.ASPECT.CYCLE_FLAT);
oOriginal.setHighMarker(0.8);
local nCloneCalls = 0;
oOriginal.setEventCallback(Pool.EVENT.ON_INCREASE, function()
    nCloneCalls = nCloneCalls + 1;
end);

local oCopy = clone(oOriginal); --independent values; retains callbacks and activation
oCopy.adjust(10);
assert(oCopy.get() == 50 and oOriginal.get() == 40 and nCloneCalls == 1);

local sSaved    = serialize(oOriginal);
local oRestored = deserialize(sSaved); --automatically invokes Pool.deserialize
--Serialization retains numeric settings and thresholds, but omits live callbacks.
oRestored.cycle();
assert(oRestored.get() == 50 and oOriginal.get() == 40 and nCloneCalls == 1);
assert(oRestored.getHighMarker() == 0.8);
assert(oRestored.get(Pool.ASPECT.RESERVED) == 20);
printPool("Restored Pool", oRestored);
print("Pool example complete.");


D.section("Your own Pool", "Try integer or fractional capacity and starting values.")
local customMax=(100 --[[ Edit maximum here ]]);local customCurrent=(25 --[[ Edit current here ]])
local custom=Pool(customMax,customCurrent)
D.equal("Custom maximum",custom.get(Pool.ASPECT.MAX),customMax)
D.equal("Custom current clamps",custom.get(),math.min(customMax,customCurrent))
D.show("Custom current type",type(custom.get()))

D.finish()
