-- The runner supplies these names through the configuration before LuaEx loads.
local E = StatusTracker.EFFECT;
local oStatuses = StatusTracker();
assert(type(oStatuses) == "StatusTracker" and not class.isinstance(oStatuses));
assert(#oStatuses == 0 and not oStatuses.isActive(E.TIMED));
assert(oStatuses.getDuration("TIMED") == 0 and oStatuses.doesExpire("TIMED"));

-- Explicit activation is separate from setting duration.
assert(rawequal(oStatuses.setDuration("TIMED", 5), oStatuses));
assert(not oStatuses.isActive("TIMED"));
assert(oStatuses.activate(E.TIMED));
assert(#oStatuses == 1 and oStatuses.cycle(2) == 0);
assert(oStatuses.getDuration("TIMED") == 3);
assert(oStatuses.cycle(100) == 1 and not oStatuses.isActive("TIMED"));
assert(oStatuses.getDuration("TIMED") == 0);

-- Non-expiring statuses remain active at zero, including after time advances.
assert(oStatuses.activate("FOREVER", 0, false));
assert(oStatuses.cycle() == 0 and oStatuses.isActive("FOREVER"));
oStatuses.setDuration("FOREVER", 2).adjustDuration("FOREVER", -10);
assert(oStatuses.getDuration("FOREVER") == 0 and oStatuses.isActive("FOREVER"));
oStatuses.setDoesExpire("FOREVER", true);
assert(not oStatuses.isActive("FOREVER"));
oStatuses.setDoesExpire("FOREVER", false);
assert(not oStatuses.isActive("FOREVER"));
assert(oStatuses.activate("FOREVER"));
assert(oStatuses.deactivate("FOREVER"));
assert(not oStatuses.deactivate("FOREVER"));

-- Invalid arguments fail before changing state.
assert(oStatuses.activate("TIMED", 3, true));
assert(not pcall(oStatuses.activate, "TIMED", 8, "bad"));
assert(oStatuses.getDuration("TIMED") == 3);
assert(not pcall(oStatuses.setDuration, "TIMED", -1));
assert(not pcall(oStatuses.cycle, -1));
assert(not pcall(oStatuses.cycle, math.huge));
assert(not pcall(oStatuses.getDuration, "UNKNOWN"));
assert(not pcall(function() oStatuses.cycle = function() end; end));
assert(not pcall(function() StatusTracker.EFFECT = {}; end));

-- Snapshot iteration and independent instances cannot alter private records.
local fIterator = oStatuses.eachStatus();
oStatuses.setDuration("TIMED", 9);
local sName, tState = fIterator();
assert(sName == "TIMED" and tState.duration == 3);
tState.duration = 100;
assert(oStatuses.getDuration("TIMED") == 9);
assert(StatusTracker().getDuration("TIMED") == 0);

-- Clone and serialization preserve flags, including explicit false.
assert(oStatuses.activate("FOREVER", 0, false));
local oCopy = clone(oStatuses);
assert(oCopy.isActive("FOREVER") and not oCopy.doesExpire("FOREVER"));
oCopy.clear();
assert(#oCopy == 0 and #oStatuses == 2);
local oRestored = deserialize(serialize(oStatuses));
assert(type(oRestored) == "StatusTracker");
assert(oRestored.getDuration("TIMED") == 9 and oRestored.isActive("TIMED"));
assert(oRestored.isActive("FOREVER") and not oRestored.doesExpire("FOREVER"));
assert(rawequal(clone(StatusTracker), StatusTracker));
assert(rawequal(deserialize(serialize(StatusTracker)), StatusTracker));
assert(not pcall(StatusTracker.deserialize, {
    statuses = { TIMED = { duration = 0, active = true, doesExpire = true } },
}));
assert(not pcall(StatusTracker.deserialize, {
    statuses = { UNKNOWN = { duration = 1, active = true, doesExpire = true } },
}));

assert(oStatuses.clear() == 2 and #oStatuses == 0);
print("PASS StatusTracker: configured identities, timers/expiration, private state, snapshots, invalid input, clone and serialization");
