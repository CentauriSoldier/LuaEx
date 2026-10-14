if (not LUAEX_INIT) then
    require("LuaEx.init");
end

local tWarnings = {};
assert(Factorium.setLog(function(sMessage)
    tWarnings[#tWarnings + 1] = sMessage;
end));

local ModClass = class("BaseModRegressionMod", {}, {}, {}, {}, {
    BaseModRegressionMod = function(this, cdat, super, tInfo)
        super(tInfo);
    end,
}, BaseMod);

-- Validity is queried from metadata; the mod object stores no status flags.
local function isValid(oMod)
    return BaseMod.validateModInfo(oMod.getInfo()) ~= nil;
end

local function metadata()
    return {
        id = "ABCDEF00-1234-4000-8000-000000000001",
        name = "Metadata test",
        authors = { "Bob", "Ed" },
        description = "Tests complete mod metadata initialization.",
        released = "2024-02-29",
        updated = "2026-10-13",
        version = 1.5,
        required = { "ABCDEF00-1234-4000-8000-000000000002" },
        conflicts = { "ABCDEF00-1234-4000-8000-000000000003" },
        blueprints = {},
    };
end

-- Initialization normalizes identity and keeps list data independent.
assert(not class.haspublicmember(ModClass, "activate"));
assert(not class.haspublicmember(ModClass, "deactivate"));
assert(not class.haspublicmember(ModClass, "isActive"));

local tSource = metadata();
local oMod = ModClass(tSource);
assert(isValid(oMod));
local tInfo = oMod.getInfo();
assert(tInfo.id == tSource.id:lower());
assert(tInfo.required[1] == tSource.required[1]:lower());
assert(tInfo.conflicts[1] == tSource.conflicts[1]:lower());
assert(tInfo.contact == "" and tInfo.website == "");
assert(tInfo.version == 1.5);
tSource.authors[1] = "Changed source";
tInfo.authors[2] = "Changed result";
tInfo.required[1] = "Changed result";
assert(oMod.getInfo().authors[1] == "Bob");
assert(oMod.getInfo().authors[2] == "Ed");
assert(oMod.getInfo().required[1] == "abcdef00-1234-4000-8000-000000000002");

-- Optional relationship lists default to empty; duplicate UUIDs collapse.
local tOptional = metadata();
tOptional.required = nil;
tOptional.conflicts = nil;
tOptional.blueprints = nil;
local tNormalized = assert(BaseMod.validateModInfo(tOptional));
assert(#tNormalized.required == 0 and #tNormalized.conflicts == 0);
assert(next(tNormalized.blueprints) == nil);
local tDuplicate = metadata();
tDuplicate.required[2] = tDuplicate.required[1]:lower();
assert(#assert(BaseMod.validateModInfo(tDuplicate)).required == 1);

-- Every malformed metadata shape returns an invalid instance, not an exception.
local tInvalidCases = {
    function(t) t.id = "not-a-uuid"; end,
    function(t) t.name = "  "; end,
    function(t) t.description = false; end,
    function(t) t.authors = {}; end,
    function(t) t.authors = { [2] = "Bob" }; end,
    function(t) t.authors = { name = "Bob" }; end,
    function(t) t.authors = { "Bob", false }; end,
    function(t) t.required = { "not-a-uuid" }; end,
    function(t) t.conflicts = { "not-a-uuid" }; end,
    function(t) t.required = false; end,
    function(t) t.conflicts = { [2] = t.id }; end,
    function(t) t.released = "2023-02-29"; end,
    function(t) t.updated = "2026-13-01"; end,
    function(t) t.version = 0; end,
    function(t) t.version = 1000; end,
    function(t) t.version = math.huge; end,
    function(t) t.version = 0 / 0; end,
    function(t) t.blueprints = false; end,
};

for _, fBreak in ipairs(tInvalidCases) do
    local tInvalid = metadata();
    fBreak(tInvalid);
    local bOK, oInvalid = pcall(ModClass, tInvalid);
    assert(bOK and not isValid(oInvalid));
    local tChecked, sReason = BaseMod.validateModInfo(oInvalid.getInfo());
    assert(tChecked == nil and rawtype(sReason) == "string");
    assert(not Factorium.importMod(oInvalid));
    assert(not Factorium.importMod(tInvalid));
end

for _, vInput in ipairs({ false, 12, "invalid" }) do
    local bOK, oInvalid = pcall(ModClass, vInput);
    assert(bOK and not isValid(oInvalid));
end

local bOK, oEmpty = pcall(ModClass, nil);
assert(bOK and not isValid(oEmpty));

-- A later valid mod still imports after malformed metadata objects.
local tClean = metadata();
tClean.required = {};
tClean.conflicts = {};
assert(Factorium.importMod(ModClass(tClean)));
Factorium.finalizeImports();
assert(Factorium.getModStatus(tClean.id).accepted);
assert(#tWarnings > 0);

-- Default logging and a broken host logger cannot interrupt initialization.
assert(BaseMod.setLog(nil));
assert(not isValid(ModClass({})));
local hLog = assert(io.open("BaseMod.log", "r"));
assert(hLog:read("*a"):find("rejected", 1, true));
hLog:close();
assert(BaseMod.setLog(function() error("logger failed") end));
assert(not isValid(ModClass({})));
assert(isValid(ModClass(tClean)));
assert(#BaseMod.getWarnings() > 0);

print("PASS BaseMod: atomic metadata, normalization, copied lists, invalid-input containment, shared import rules, logging and Factorium-owned state");
