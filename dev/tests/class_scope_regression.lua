--[[!
@fqxn Tests.ClassScope
@desc Tests native qualified lookup, inheritance metadata and private nested-class access.
    Run through tests/run.lua; all declaration fixtures remain in memory.
!]]
if (not LUAEX_INIT) then require("LuaEx.init"); end
local _nChecks = 0;
local function check(sLabel, bPassed)
    assert(bPassed, sLabel);
    _nChecks = _nChecks + 1;
end

lxc.loadSources({["ClassScope.lxc"] = [=[namespace Scope {
    class Character {
        private value = 7;
        public Character() {}
        public read() { return this.value; }
    }
    class Player : Scope.Character { public Player() { base(); } }
    class Knight : Scope.Player { public Knight() { base(); } }
    class Archer : Scope.Character { public Archer() { base(); } }
    class Potion {}
    class Owner {
        private class Hidden { public Hidden() {} public read() { return 9; } }
        public static instance() { return Owner.Hidden(); }
        public static factory() { return class.getbyname("Scope.Owner.Hidden"); }
    }
}]=]}, _G);

local Character, Player, Knight = Scope.Character, Scope.Player, Scope.Knight;
local oKnight = Knight();
check("Qualified public lookup", rawequal(class.getbyname("Scope.Character"), Character));
check("Short name is not an alias", class.getbyname("Character") == nil);
check("Unknown name", class.getbyname("Scope.Missing") == nil);
for _, vInvalid in ipairs({false, true, 0, {}, Character, oKnight, function() end}) do
    check("Lookup requires a string", class.getbyname(vInvalid) == nil);
end
check("Nil lookup", class.getbyname(nil) == nil);

for _, value in ipairs({Character, "Scope.Character"}) do
    check("Root has no parent", class.getparentname(value) == nil);
    check("Root is its own base", class.getbasename(value) == "Scope.Character");
    local names = class.getchildnames(value);
    check("Direct children only", #names == 2 and names[1] == "Scope.Archer" and names[2] == "Scope.Player");
    names[1] = "changed";
    check("Metadata list is independent", class.getchildnames(value)[1] == "Scope.Archer");
end
check("Immediate parent name", class.getparentname(Knight) == "Scope.Player");
check("Root ancestor name", class.getbasename(Knight) == "Scope.Character");
check("Leaf child list is empty", #class.getchildnames(Knight) == 0);
check("Instance name", class.getname(oKnight) == "Scope.Knight");
check("Class name", class.getname(Knight) == "Scope.Knight");
check("Registered name", class.getname("Scope.Knight") == "Scope.Knight");
check("Exact instance identity", class.isinstanceof(oKnight, Knight) and not class.isinstanceof(oKnight, Player));
check("Polymorphic membership", class.isa(oKnight, Character) and class.isa(oKnight, Player));
check("Strict descendant relation", class.ischild(Knight, Character) and not class.ischild(Character, Character));
check("Inherited behavior", oKnight.read() == 7);
check("No private field access", not pcall(function() return oKnight.value; end));

local fake = setmetatable({}, {__type = "Scope.Knight"});
check("Spoofed metadata grants no identity", not class.isinstance(fake) and class.getname(fake) == nil);
for _, name in ipairs({"of", "getparent", "getbase", "getchildren", "getInstanceClass", "repo"}) do
    check("No legacy/internal helper "..name, class[name] == nil);
end
check("Helpers remain read-only", not pcall(function() class.newHelper = true; end));

local hidden = Scope.Owner.instance();
local factory = Scope.Owner.factory();
check("Hidden object exposes only its metadata name", class.getname(hidden) == "Scope.Owner.Hidden");
check("Authored public method works", hidden.read() == 9);
check("External qualified lookup cannot expose a private class", class.getbyname("Scope.Owner.Hidden") == nil);
check("Private factory use is denied", not pcall(factory));
check("Saving private factory is denied", not pcall(serialize, factory));
check("Private lookup remains denied after failed use", class.getbyname("Scope.Owner.Hidden") == nil);

local registry = ClassRegistry({Character});
check("Registry accepts descendants", registry.allows(oKnight));
check("Registry rejects unrelated instances", not registry.allows(Scope.Potion()));
check("Registry rejects spoofed instances", not registry.allows(fake));
check("Class clone retains identity", rawequal(clone(Character), Character));
check("Public class save retains identity", rawequal(deserialize(serialize(Character)), Character));
local restored = deserialize(serialize(oKnight));
check("Instance restore keeps concrete class and behavior", class.isinstanceof(restored, Knight) and restored.read() == 7);

print("PASS class scope: ".._nChecks.." native checks.");
