assert(getmetatable ~= rawgetmetatable and setmetatable ~= rawsetmetatable);

-- Sealing works with absent/existing metatables and preserves existing behavior.
local tPlain = {};
assert(sealmetatable(tPlain) and getmetatable(tPlain) == false);
assert(sealmetatable(tPlain));
assert(not pcall(setmetatable, tPlain, {}));
assert(not pcall(rawsetmetatable, tPlain, {}));
local tExisting = setmetatable({}, { __index = { value = 7 } });
assert(sealmetatable(tExisting) and tExisting.value == 7);
assert(not sealmetatable(12));

-- Guarded objects expose copied identity data and prohibit public replacement/removal.
local tMeta = { __type = "class", __subtype = "test", __name = "Example", __metaguard = true, secret = 9 };
local tGuarded = rawsetmetatable({}, tMeta);
local tView = getmetatable(tGuarded);
assert(tView ~= tMeta and tView.secret == nil and tView.__type == "class");
tView.__type = "changed";
assert(getmetatable(tGuarded).__type == "class");
assert(not pcall(setmetatable, tGuarded, {}));
assert(not pcall(setmetatable, tGuarded, nil));
assert(rawgetmetatable(tGuarded) == tMeta);
assert(rawsetmetatable(tGuarded, {}) == tGuarded);

-- Guard membership requires BOTH an exact boolean and a registered type name.
for _, tCandidate in ipairs({
    { __type = "class", __metaguard = "true" },
    { __type = "unregistered", __metaguard = true },
    { __type = false, __metaguard = true },
}) do
    local tObject = rawsetmetatable({}, tCandidate);
    assert(getmetatable(tObject) == tCandidate);
    assert(setmetatable(tObject, nil) == tObject);
end

-- Native sentinels retain their identity and cannot be mutated by sealing.
for _, vSentinel in ipairs({ "locked", false, { label = "protected" } }) do
    local tObject = rawsetmetatable({}, { __metatable = vSentinel });
    assert(getmetatable(tObject) == vSentinel);
    assert(not pcall(setmetatable, tObject, {}));
    assert(sealmetatable(tObject) == (vSentinel == false));

    if (rawtype(vSentinel) == "table") then
        assert(vSentinel.__metatable == nil);
    end
end

assert(not pcall(setmetatable, 1, {}));
assert(not pcall(setmetatable, {}, false));
assert(getmetatable({}) == nil);
print("PASS metahook: installed wrappers, sealing, guards, identity views, native sentinels and argument semantics");
