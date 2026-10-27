-- Eventrix and its serialization protocol are core facilities, independent of CoG.
if not LUAEX_INIT then require("LuaEx.load")(0); end

local _eEvents = enum("EventrixRegressionEvents", {"ACTIVE", "PAUSED", "EMPTY", "NESTED"}, nil, true);

-- Invalid removal reports the supplied input type and leaves existing events intact.
local _kRemovalBus = eventrix();
_kRemovalBus.addHook(_eEvents.ACTIVE, function() end);
for _, vInvalid in ipairs({42, "ACTIVE", false, {}}) do
    local bRemoved, sReason = pcall(_kRemovalBus.removeEvent, vInvalid);
    assert(not bRemoved and sReason:find("Type given: "..subtype(vInvalid)..".", 1, true), sReason);
    assert(_kRemovalBus.eventExists(_eEvents.ACTIVE));
end

-- Dispatch must neither create nor overwrite an unrelated global game flag.
local _vPreviousFired = rawget(_G, "bFired");
local _kFlagBus = eventrix();
local _nFlagCalls = 0;
_kFlagBus.addHook(_eEvents.ACTIVE, function()
    _nFlagCalls = _nFlagCalls + 1;
end);
for _, vFlag in ipairs({false, true, "unchanged", 17}) do
    rawset(_G, "bFired", vFlag);
    _kFlagBus.fire(_eEvents.ACTIVE);
    assert(rawequal(rawget(_G, "bFired"), vFlag), "Dispatch must preserve unrelated globals.");
end
rawset(_G, "bFired", nil);
_kFlagBus.fire(_eEvents.ACTIVE);
assert(rawget(_G, "bFired") == nil and _nFlagCalls == 5, "Dispatch must not create bFired.");
rawset(_G, "bFired", _vPreviousFired);

local _tTrace  = {};
local _nCalls  = 0;

local function first(nValue)
    _nCalls = _nCalls + 1;
    _tTrace[#_tTrace + 1] = "first";
    return nValue * 2;
end

local function second()
    _tTrace[#_tTrace + 1] = "second";
    return false;
end

local function noResult()
    _tTrace[#_tTrace + 1] = "nil";
end

local function failure()
    error("expected hook failure");
end

local function snapshot(kEventrix)
    return rawgetmetatable(kEventrix).__serialize();
end

local function rejects(tState)
    assert(not pcall(eventrix.deserialize, tState), "Malformed eventrix state must be rejected.");
end

-- Environment contents are external runtime state, including values the serializer cannot copy.
envrepo.EventrixRegressionEnvironment = {native = print, thread = coroutine.create(function() end)};
envrepo.EventrixRegressionHookEnvironment = {native = print};
local _kBus = eventrix("EventrixRegressionEnvironment");
assert(_kBus.addHook(_eEvents.ACTIVE, first) == _kBus);
_kBus.addHook(_eEvents.ACTIVE, second);
_kBus.addHook(_eEvents.ACTIVE, noResult);
_kBus.addHook(_eEvents.ACTIVE, failure);
_kBus.setHookActive(_eEvents.ACTIVE, second, false);
_kBus.addHook(_eEvents.PAUSED, first);
_kBus.addHook(_eEvents.PAUSED, second, "EventrixRegressionHookEnvironment");
_kBus.setEventActive(_eEvents.PAUSED, false);
_kBus.addHook(_eEvents.EMPTY, second);
_kBus.removeHook(_eEvents.EMPTY, second);
_kBus.setEventActive(_eEvents.EMPTY, false);

local _sSaved = serialize({bus = _kBus, again = _kBus, events = _eEvents, trace = _tTrace, first = first, second = second});
assert(_nCalls == 0 and #_tTrace == 0, "Saving must not execute hooks.");
local _tLoaded = deserialize(_sSaved);
local _tOther  = deserialize(_sSaved);
local _kLoaded = _tLoaded.bus;
local _eLoaded = _tLoaded.events;
assert(rawequal(_kLoaded, _tLoaded.again) and not rawequal(_kLoaded, _kBus));
assert(not rawequal(_kLoaded, _tOther.bus));
assert(_kLoaded.getHookCount(_eLoaded.ACTIVE) == 4);
assert(_kLoaded.getHookOrdinal(_eLoaded.ACTIVE, _tLoaded.first) == 1);
assert(not _kLoaded.isHookActive(_eLoaded.ACTIVE, _tLoaded.second));
assert(not _kLoaded.isEventActive(_eLoaded.PAUSED));
assert(_kLoaded.eventExists(_eLoaded.EMPTY) and _kLoaded.getHookCount(_eLoaded.EMPTY) == 0);
assert(not _kLoaded.isEventActive(_eLoaded.EMPTY));

-- Results keep their ordinal slots, including disabled-hook holes, false and the nil sentinel.
local _tResults = _kLoaded.fire(_eLoaded.ACTIVE, 7);
assert(_tResults[1] == 14 and _tResults[2] == nil and _tResults[3] == EVENTRIX_NIL,
       tostring(_tResults[1]).." / "..tostring(_tResults[2]).." / "..tostring(_tResults[3]));
assert(type(_tResults[4]) == "string" and _tResults[4]:find("expected hook failure", 1, true));
assert(table.concat(_tLoaded.trace, ",") == "first,nil");
assert(#_tTrace == 0 and #_tOther.trace == 0 and _nCalls == 0);
_kLoaded.setHookActive(_eLoaded.ACTIVE, _tLoaded.second, true);
assert(_kLoaded.fire(_eLoaded.ACTIVE, 3)[2] == false);
assert(not _kBus.isHookActive(_eEvents.ACTIVE, second));
assert(next(_kLoaded.fire(_eLoaded.PAUSED, 5)) == nil);
_kLoaded.setEventActive(_eLoaded.PAUSED, true);
assert(_kLoaded.fire(_eLoaded.PAUSED, 5)[1] == 10);

-- Rebuilt callback indexes support ordinary duplicate insertion, removal and ordinal updates.
_kLoaded.addHook(_eLoaded.ACTIVE, _tLoaded.first);
assert(_kLoaded.getHookCount(_eLoaded.ACTIVE) == 4);
_kLoaded.removeHook(_eLoaded.ACTIVE, _tLoaded.first);
assert(_kLoaded.getHookOrdinal(_eLoaded.ACTIVE, _tLoaded.second) == 1);
assert(_kLoaded.getHookCount(_eLoaded.ACTIVE) == 3);
_kLoaded.removeEvent(_eLoaded.PAUSED);
assert(not _kLoaded.eventExists(_eLoaded.PAUSED) and _kBus.eventExists(_eEvents.PAUSED));
local _kResaved = deserialize(serialize(_kLoaded));
assert(type(_kResaved) == "eventrix");
assert(rawequal(deserialize(serialize(eventrix)), eventrix));

-- Direct state restoration copies containers and never changes caller-owned snapshot tables.
local _tState = snapshot(_kBus);
assert(_tState.environment == "EventrixRegressionEnvironment");
local _kDirect = eventrix.deserialize(_tState);
for _, tEvent in ipairs(_tState.events) do
    if (tEvent.id == _eEvents.ACTIVE) then
        tEvent.active = false;
    end
end
assert(_kDirect.isEventActive(_eEvents.ACTIVE));
_kDirect.addHook(_eEvents.EMPTY, second);
local _tDirectState = snapshot(_kDirect);
for _, tEvent in ipairs(_tDirectState.events) do
    for _, tHook in ipairs(tEvent.hooks) do
        local sExpected = tEvent.id == _eEvents.PAUSED and tHook.callback == second and
                          "EventrixRegressionHookEnvironment" or "EventrixRegressionEnvironment";
        assert(tHook.environment == sExpected);
    end
end

-- Named bindings remain external even if the repository's mutable default alias changes.
envrepo.EventrixRegressionOther = {};
envrepo.setDefault("EventrixRegressionOther");
assert(snapshot(deserialize(_sSaved).bus).environment == "EventrixRegressionEnvironment");
assert(snapshot(deserialize(serialize(eventrix()))).environment == false);

-- Snapshotting during dispatch must not depend on builtins in a restricted hook environment.
local _kNested = eventrix("EventrixRegressionEnvironment");
_kNested.addHook(_eEvents.NESTED, function()
    return serialize(eventrix());
end, "EventrixRegressionHookEnvironment");
local _sNested = _kNested.fire(_eEvents.NESTED)[1];
assert(_sNested:match("^serializer"), _sNested);
assert(snapshot(deserialize(_sNested)).environment == "EventrixRegressionHookEnvironment");
assert(snapshot(eventrix()).environment == false, "Dispatch must restore its environment.");

-- Stable named aliases take precedence over the repository's mutable default alias.
local _tAliasEnvironment = {};
envrepo.EventrixRegressionZAlias = _tAliasEnvironment;
envrepo.EventrixRegressionAAlias = _tAliasEnvironment;
envrepo.setDefault("EventrixRegressionZAlias");
local _kAliased = eventrix("EventrixRegressionZAlias");
assert(snapshot(_kAliased).environment == "EventrixRegressionAAlias");
assert(snapshot(deserialize(serialize(_kAliased))).environment == "EventrixRegressionAAlias");
envrepo.setDefault("EventrixRegressionOther");
assert(snapshot(deserialize(serialize(_kAliased))).environment == "EventrixRegressionAAlias");

rejects(nil);
rejects(false);
rejects({version = 2, environment = false, events = {}});
rejects({version = 1, environment = true, events = {}});
rejects({version = 1, environment = "MissingEventrixEnvironment", events = {}});
rejects({version = 1, environment = "getDefault", events = {}});
rejects({version = 1, environment = false, events = {}, unknown = true});
rejects(setmetatable({version = 1, environment = false, events = {}}, {}));
rejects({version = 1, environment = false, events = {[2] = {}}});
rejects({version = 1, environment = false, events = {{id = "ACTIVE", active = true, hooks = {}}}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = 1, hooks = {}}}});
rejects({version = 1, environment = false, events = {
    {id = _eEvents.ACTIVE, active = true, hooks = {}},
    {id = _eEvents.ACTIVE, active = true, hooks = {}},
}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = true, hooks = {
    {callback = first, active = true, environment = false},
    {callback = first, active = false, environment = false},
}}}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = true, hooks = {
    {callback = false, active = true, environment = false},
}}}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = true, hooks = {
    {callback = first, active = "true", environment = false},
}}}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = true, hooks = {
    {callback = first, active = true, environment = "MissingEventrixEnvironment"},
}}}});
rejects({version = 1, environment = false, events = false});
rejects({version = 1, environment = false, events = setmetatable({}, {})});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = true, hooks = {}, unknown = true}}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, hooks = {}}}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = true, hooks = {
    [2] = {callback = first, active = true, environment = false},
}}}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = true, hooks = {
    {callback = first, active = true, environment = false, unknown = true},
}}}});
rejects({version = 1, environment = false, events = {{id = _eEvents.ACTIVE, active = true, hooks = {
    {callback = first, active = true},
}}}});

-- Generic serializer restrictions reject unsupported closures explicitly, without poisoning later saves.
local _kCycle = eventrix();
_kCycle.addHook(_eEvents.ACTIVE, function() return _kCycle; end);
assert(not pcall(serialize, _kCycle));
local _kNative = eventrix();
_kNative.addHook(_eEvents.ACTIVE, print);
assert(not pcall(serialize, _kNative));
assert(type(deserialize(serialize(eventrix()))) == "eventrix");

print("PASS eventrix: core loading, hook order/flags/results, empty events, callback graph identity, independent loads, external environments, validation and resaving");
