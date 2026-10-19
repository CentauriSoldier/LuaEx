-- The runner supplies these names through the configuration before LuaEx loads.
local E = StatusTracker.ALL_THINGS.PEOPLE;
local oStatuses = StatusTracker(StatusTracker.ALL_THINGS.PEOPLE);
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
assert(not pcall(function() StatusTracker.ALL_THINGS.PEOPLE = {}; end));

-- Snapshot iteration and independent instances cannot alter private records.
local fIterator = oStatuses.eachStatus();
oStatuses.setDuration("TIMED", 9);
local sName, tState = fIterator();
assert(sName == "TIMED" and tState.duration == 3);
tState.duration = 100;
assert(oStatuses.getDuration("TIMED") == 9);
assert(StatusTracker(StatusTracker.ALL_THINGS.PEOPLE).getDuration("TIMED") == 0);

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
    scope = "ALL_THINGS.PEOPLE", statuses = { TIMED = { duration = 0, active = true, doesExpire = true } },
}));
assert(not pcall(StatusTracker.deserialize, {
    scope = "ALL_THINGS.PEOPLE", statuses = { UNKNOWN = { duration = 1, active = true, doesExpire = true } },
}));

assert(oStatuses.clear() == 2 and #oStatuses == 0);
print("PASS StatusTracker: configured identities, timers/expiration, private state, snapshots, invalid input, clone and serialization");

local all = StatusTracker.ALL_THINGS
local people = StatusTracker(all.PEOPLE)
local entire = StatusTracker(all)
local weapons = StatusTracker(all.WEAPONS)
local one = StatusTracker(all.WEAPONS.ONE_HANDED)
local nChecks = 0
local function fails(f, ...)
    assert(not pcall(f, ...)); nChecks=nChecks+1
end
fails(StatusTracker)
fails(StatusTracker, {})
fails(StatusTracker, all.PEOPLE.CONFUSED)
fails(StatusTracker, enum("BOB", {"CONFUSED"}, nil, true))
fails(StatusTracker, all, all.PEOPLE)
assert(entire.activate(all.PEOPLE.CONFUSED, 10))
assert(entire.activate(all.WEAPONS.ONE_HANDED.DULL, 7))
assert(entire.getDuration("WEAPONS.ONE_HANDED.DULL") == 7)
assert(entire.getDuration("ALL_THINGS.WEAPONS.ONE_HANDED.DULL") == 7)
assert(entire.getDuration(all.WEAPONS.TWO_HANDED.DULL) == 0)
assert(weapons.activate(all.WEAPONS.ONE_HANDED.DULL, 9))
assert(weapons.getDuration("ONE_HANDED.DULL") == 9)
assert(one.activate(all.WEAPONS.ONE_HANDED.DULL, 2))
assert(one.getDuration("DULL") == 2)
fails(one.getDuration, all.WEAPONS.TWO_HANDED.DULL)
fails(weapons.getDuration, "DULL")
fails(entire.getDuration, "DULL")
fails(people.getDuration, all.PEOPLE)
fails(people.getDuration, "ALL_THINGS.WEAPONS.ONE_HANDED.DULL")
for _, f in ipairs({people.activate,people.deactivate,people.isActive,people.getDuration,
                   people.setDuration,people.adjustDuration,people.doesExpire,people.setDoesExpire}) do
    fails(f, all.WEAPONS.ONE_HANDED.DULL, 2)
end
assert(#people == 0 and people.getDuration(all.PEOPLE.CONFUSED) == 0)
local saved = deserialize(serialize(one))
assert(saved.getDuration(all.WEAPONS.ONE_HANDED.DULL) == 2)
fails(saved.getDuration, all.WEAPONS.TWO_HANDED.DULL)
local copied = clone(one)
copied.adjustDuration("DULL", -1)
assert(copied.getDuration("DULL") == 1 and one.getDuration("DULL") == 2)
fails(copied.getDuration, all.PEOPLE.CONFUSED)
fails(StatusTracker.deserialize, {scope="BOB",statuses={}})
fails(StatusTracker.deserialize, {scope="ALL_THINGS.PEOPLE",statuses={DULL={duration=1,active=true,doesExpire=true}}})
fails(StatusTracker.deserialize, {scope="ALL_THINGS.PEOPLE.CONFUSED",statuses={}})
local count=0
for path, state in entire.eachStatus() do
    assert(path ~= "DULL" and state.duration >= 0); count=count+1
end
assert(count == 6)
assert(entire.cycle(7) == 1 and entire.isActive(all.PEOPLE.CONFUSED))
fails(function() luaex.cog.config.StatusTracker.ALL_THINGS.PEOPLE[1]="BAD" end)
fails(function() StatusTracker.ALL_THINGS={} end)
print("PASS hierarchy: "..nChecks.." rejection checks; ancestor/descendant scopes, duplicate leaf names, every effect method, clone, serialization, cycles, iteration, immutable config")