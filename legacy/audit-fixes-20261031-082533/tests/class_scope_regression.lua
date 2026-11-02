--[[!
    @fqxn Tests.ClassScope
    @desc Verifies explicit class-reference lookup and metadata-only reflection.
    Run from the repository root: lua tests/class_scope_regression.lua.
    No native files are written and no debug introspection is used by the checks.
!]]
if (not LUAEX_INIT) then
    require("LuaEx.load")(2);
end

local _nChecks = 0;

--[[!
    @fqxn Tests.ClassScope.check
    @desc Asserts a named expectation and counts successful checks.
    @param string sLabel The behavior being verified.
    @param boolean bPassed Whether that behavior occurred.
!]]
local function check(sLabel, bPassed)
    assert(bPassed, sLabel);
    _nChecks = _nChecks + 1;
end

--[[!
    @fqxn Tests.ClassScope.makeClass
    @desc Creates a minimal class with an optional parent for hierarchy checks.
    @param string sName The unique class name.
    @param class|nil cParent The parent reference already available to this test.
    @ret class cClass The new class reference.
!]]
local function makeClass(sName, cParent)
    local tPublic = {};

    if (cParent) then
        -- Constructors explicitly call the supplied parent through LuaEx's wrapper.
        tPublic[sName] = function(this, cdat, super)
            super();
        end;
    else
        tPublic[sName] = function(this, cdat)
        end;
    end

    return class(sName, {}, {}, {}, {}, tPublic, cParent);
end

local Character = makeClass("ScopeCharacter");
local Player = makeClass("ScopePlayer", Character);
local Knight = makeClass("ScopeKnight", Player);
local Archer = makeClass("ScopeArcher", Character);
local Potion = makeClass("ScopePotion");
local oKnight = Knight();
local tEnvironment = {ScopeCharacter = Character, ScopePlayer = Player};

-- Both an existing name and an existing object are insufficient without a binding.
check("No implicit environment", class.getbyname("ScopeCharacter") == nil);
check("Direct binding returns the supplied object", rawequal(class.getbyname("ScopeCharacter", tEnvironment), Character));
check("Unbound registered class stays hidden", class.getbyname("ScopeKnight", tEnvironment) == nil);
check("Empty environment grants nothing", class.getbyname("ScopeCharacter", {}) == nil);
check("Alias binding still supplies an explicit reference", class.getbyname("hero", {hero = Player}) == Player);
check("Class object is not a lookup name", class.getbyname(Character, tEnvironment) == nil);
check("Unknown name returns nil", class.getbyname("ScopeMissing", tEnvironment) == nil);
check("Nil name returns nil", class.getbyname(nil, tEnvironment) == nil);

for _, vInvalid in ipairs({false, true, 0, "ScopeCharacter", function() end, coroutine.create(function() end)}) do
    check("Non-table environment uses private dummy", class.getbyname("ScopeCharacter", vInvalid) == nil);
    check("Dummy remains empty between calls", class.getbyname("ScopeCharacter") == nil);
end

for _, vInvalid in ipairs({false, 0, "ScopeCharacter", {}, oKnight, function() end}) do
    check("Binding must contain a registered class", class.getbyname("ScopeCharacter", {ScopeCharacter = vInvalid}) == nil);
end

local nIndexCalls = 0;
local tInheritedEnvironment = setmetatable({}, {
    __index = function()
        nIndexCalls = nIndexCalls + 1;
        return Character;
    end,
});
check("Environment metatable cannot supply a class", class.getbyname("ScopeCharacter", tInheritedEnvironment) == nil);
check("Environment lookup never calls __index", nIndexCalls == 0);
check("Table-valued fallback cannot supply a class", class.getbyname("ScopeCharacter", setmetatable({}, {__index = tEnvironment})) == nil);
check("Inherited globals are not direct bindings", class.getbyname("ScopeCharacter", _G) == nil);

-- Metadata reveals names and relationships, never class references.
for _, vClass in ipairs({Character, "ScopeCharacter"}) do
    check("Root has no parent", class.getparentname(vClass) == nil);
    check("Root has no base", class.getbasename(vClass) == nil);
    local tChildren = class.getchildnames(vClass);
    check("Only direct children are returned", #tChildren == 2);
    check("Child names are sorted strings", tChildren[1] == "ScopeArcher" and tChildren[2] == "ScopePlayer");
    tChildren[1] = "tampered";
    check("Returned lists cannot mutate the registry", class.getchildnames(vClass)[1] == "ScopeArcher");
end

for _, vClass in ipairs({Knight, "ScopeKnight"}) do
    check("Immediate parent is a name", class.getparentname(vClass) == "ScopePlayer");
    check("Root base is a name", class.getbasename(vClass) == "ScopeCharacter");
    check("Leaf has no child names", class.getchildnames(vClass) == nil);
end

check("Name query accepts a class", class.getname(Knight) == "ScopeKnight");
check("Name query accepts an instance", class.getname(oKnight) == "ScopeKnight");
check("Name query accepts a registered name", class.getname("ScopeKnight") == "ScopeKnight");
check("Unrelated name remains metadata", class.getname(Potion) == "ScopePotion");
check("Spoofed type metadata is insufficient", class.getname(setmetatable({}, {__type = "ScopeKnight"})) == nil);

for _, vInvalid in ipairs({false, 0, "ScopeMissing", {}, function() end}) do
    check("Invalid class name query", class.getname(vInvalid) == nil);
    check("Invalid parent query", class.getparentname(vInvalid) == nil);
    check("Invalid base query", class.getbasename(vInvalid) == nil);
    check("Invalid children query", class.getchildnames(vInvalid) == nil);
end
check("Nil instance is not registered", class.getname(nil) == nil);
check("Name-based parent checks remain valid", class.isparent("ScopeCharacter", "ScopeKnight"));
check("Name-based base checks remain valid", class.isbaseof("ScopeCharacter", "ScopeKnight"));
check("Name-based unrelated checks remain false", not class.isparent("ScopePotion", "ScopeKnight"));
check("Exact instance check uses existing reference", class.isinstanceof(oKnight, Knight));
check("Exact instance check rejects a different class", not class.isinstanceof(oKnight, Player));
check("Public of is removed", class.of == nil);
check("Public object parent getter is removed", class.getparent == nil);
check("Public object base getter is removed", class.getbase == nil);
check("Public object children getter is removed", class.getchildren == nil);
check("Internal lookup is not exported", class.getInstanceClass == nil);
check("Internal registry is not exported", class.repo == nil);

-- A class leaving its declaration block remains queryable only as metadata.
local oHidden;
local sHiddenInstanceSave;
local sHiddenClassSave;
do
    local Hidden = makeClass("ScopeHidden");
    oHidden = Hidden();
    check("Explicit local binding permits retrieval", class.getbyname("ScopeHidden", {ScopeHidden = Hidden}) == Hidden);

    -- Existing serializer registration supplies restoration references privately.
    serializer.registerFactory(Hidden, {name = "ScopeHiddenReference", types = {"ScopeHidden"}});
    sHiddenInstanceSave = serialize(oHidden);
    sHiddenClassSave = serialize(Hidden);
end
check("Instance does not grant its class reference", class.getname(oHidden) == "ScopeHidden" and class.getbyname("ScopeHidden") == nil);
check("Out-of-block name does not recover a class", class.getbyname("ScopeHidden", {}) == nil);
check("Registered private instance restores after its block ends", class.getname(deserialize(sHiddenInstanceSave)) == "ScopeHidden");
check("Registered private class reference restores after its block ends", class.getname(deserialize(sHiddenClassSave)) == "ScopeHidden");
check("Private restoration does not enable public lookup", class.getbyname("ScopeHidden") == nil);
check("Cloning an existing class reference retains identity", rawequal(clone(Character), Character));

-- ClassRegistry eligibility must work using names without obtaining new references.
local oRegistry = ClassRegistry({Character});
check("Registry accepts descendants", oRegistry.allows(oKnight));
check("Registry rejects unrelated instances", not oRegistry.allows(Potion()));
check("Registry rejects spoofed instance metadata", not oRegistry.allows(setmetatable({}, {__type = "ScopeKnight"})));
local oPotion = Potion();
local oInstanceRegistry = ClassRegistry({oPotion});
check("Registry retains exact instance matching", oInstanceRegistry.allows(oPotion));
check("Registry rejects a different instance of the same class", not oInstanceRegistry.allows(Potion()));

-- Serialization retains explicit saved references independently of public lookup.
rawset(_G, "ScopeSerializedClass", Character);
serializer.registerFactory(Character, {name = "ScopeSerializedClass"});
local sClassSave = serialize(Character);
check("Currently bound serialized class can restore", rawequal(deserialize(sClassSave), Character));
rawset(_G, "ScopeSerializedClass", nil);
check("Removed binding does not break saved class restoration", rawequal(deserialize(sClassSave), Character));
check("Saved reference does not enable public name lookup", class.getbyname("ScopeSerializedClass") == nil);
rawset(_G, "ScopeSerializedClass", Potion);
check("Replaced binding does not change saved class identity", rawequal(deserialize(sClassSave), Character));
rawset(_G, "ScopeSerializedClass", Character);
check("Restored matching binding permits class restoration", rawequal(deserialize(sClassSave), Character));
rawset(_G, "ScopeSerializedClass", nil);

print("PASS class scope: ".._nChecks.." checks; explicit environments, raw lookup, metadata-only relationships, instance names and removed object getters.");
