--[[!
@fqxn Tests.LXE
@desc Exercises runtime identity, payloads, nesting, extensions, operators,
    dependency preflight, incremental batches, class ownership and persistence.
    Sources stay in memory so package discovery cannot mistake fixtures for apps.
!]]
local sRoot = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/tests/lxe/");
assert(sRoot, "Run this saved regression file with loadfile.");
package.path = sRoot.."/?.lua;"..package.path;
require("LuaEx.init");
local LXE = require("LuaEx.lib.lxe");
local LXC = require("LuaEx.lib.lxc");
LXC.bindHost(_G);
local nChecks = 0;

--[[!
@fqxn Tests.LXE.check
@desc Counts a behavioral assertion and reports its context on failure.
@param boolean bCondition Expected true condition.
@param string sMessage Assertion context.
!]]
local function check(bCondition, sMessage)
    nChecks = nChecks + 1;
    assert(bCondition, sMessage);
end

--[[!
@fqxn Tests.LXE.reject
@desc Requires a call to fail with a diagnostic fragment.
@param function fAction Operation expected to fail.
@param string sFragment Required diagnostic substring.
!]]
local function reject(fAction, sFragment)
    local bOK, sError = pcall(fAction);
    check(not bOK and tostring(sError):find(sFragment, 1, true) ~= nil,
        "Expected failure containing "..sFragment.."; got "..tostring(sError));
end

local tHost = setmetatable({calls = {}, shared = {}, make = function() return {}; end}, {__index = _G});
LXE.loadSources({["core.lxe"] = [=[
extension Spec.vehicle.car.isHonda(this) {
    return this == Spec.vehicle.car.honda;
}
namespace Spec {
    enum vehicle {
        car = 10 {
            honda = "Honda";
            toyota = "Toyota";
        }
        motorcycle;
    }
    extension vehicle.isCar(this) { return this == vehicle.car; }
    enum Numbers {
        Eight = 8;
        Three = 3;
        Negative = -4;
    }
    enum Payloads {
        No = false;
        Text = "value";
        Data = shared;
        Factory = function(n) return n * 2; end;
        Fresh = make();
        Nothing = null;
    }
}
]=]}, tHost);
local eVehicle, eNumbers, ePayloads = tHost.Spec.vehicle, tHost.Spec.Numbers, tHost.Spec.Payloads;
check(type(eVehicle) == "enum", "root enum type");
check(type(eVehicle.car) == "Spec.vehicle", "nested enum member type");
check(type(eVehicle.car.honda) == "Spec.vehicle.car", "nested leaf type");
check(eVehicle.Parent == null, "root parent is null");
check(eVehicle.car.Parent == eVehicle and eVehicle.car.honda.Parent == eVehicle.car, "immediate parents");
check(eVehicle.car.Value == 10 and eVehicle.car.Ordinal == 1, "independent embedded value");
check(eVehicle.motorcycle.Value == 2 and eVehicle.motorcycle.Ordinal == 2, "default ordinal independent of preceding explicit value");
check(eVehicle.car.honda.Value == "Honda" and eVehicle.car.honda.Ordinal == 1, "child payload and ordinal");
check(eVehicle.car.Name == "car", "member name");
check(eVehicle[1] == eVehicle.car and eVehicle["car"] == eVehicle.car, "lookup forms");
check(#eVehicle == 2 and #eVehicle.car == 2, "immediate counts");
local nIndex = 0;
for n, oMember in eVehicle() do nIndex = nIndex + 1; check(n == nIndex and oMember == eVehicle[n], "call iteration order"); end
for n, oMember in pairs(eVehicle.car) do check(oMember == eVehicle.car[n], "pairs order"); end
check(LXE.isEnum(eVehicle) and LXE.isEnum(eVehicle.car) and not LXE.isEnum(eVehicle.car.honda), "collection recognition");
check(LXE.isMember(eVehicle.car.honda, eVehicle.car) and not LXE.isMember(eVehicle.car.honda, eVehicle), "exact membership");
check(LXE.getByName(eVehicle, "missing") == nil and LXE.getByName(eVehicle, "car") == eVehicle.car, "name helper");
check(LXE.getByValue(ePayloads, false) == ePayloads.No, "false payload lookup");
check(LXE.getByValue(ePayloads, tHost.shared) == ePayloads.Data, "reference identity lookup");
check(LXE.getByValue(ePayloads, {}) == nil, "distinct reference lookup");
check(ePayloads.No.Value == false and ePayloads.Factory.Value(4) == 8, "false and function payloads");
check(ePayloads.Nothing.Value == null, "null payload");
check(eVehicle.car:isCar() and eVehicle.car.honda:isHonda(), "extension binding");
reject(function() return eVehicle.car.honda:isCar() end, "Unknown enum member");
reject(function() return eVehicle.car.isCar(eVehicle.car.honda) end, "Invalid enum extension receiver");
reject(function() eVehicle.car.Value = 9; end, "read-only");
reject(function() eVehicle.car = {}; end, "read-only");
reject(function() getmetatable(eVehicle.car).__type = "bad"; end, "read-only");

local a, b = eNumbers.Eight, eNumbers.Three;
check(a + b == 11 and a - b == 5 and a * b == 24 and a / b == 8 / 3, "arithmetic");
check(a // b == 2 and a % b == 2 and a ^ b == 512 and -a == -8, "remaining arithmetic");
check(a + 2 == 10 and 2 + a == 10 and 20 - a == 12, "scalar arithmetic");
check(a & b == 0 and a | b == 11 and a ~ b == 11, "bitwise binary");
check(a << 1 == 16 and a >> 1 == 4 and ~a == ~8, "bitwise shifts and unary");
check(b < a and b <= a and a > b and a >= b, "sibling value ordering");
check(a == a and a ~= b and a ~= 8, "identity equality");
check(eVehicle.car.honda.."!" == "Honda!" and "v"..a == "v8", "concatenation");
check(tostring(eVehicle.car.honda) == "Spec.vehicle.car.honda", "qualified tostring");
reject(function() return ePayloads.No + 1; end, "numbers");
reject(function() return eNumbers.Three < eVehicle.car; end, "siblings");

local tGraph = {Root = eVehicle, Nested = eVehicle.car, Member = eVehicle.car.honda, Alias = eVehicle.car.honda};
local tCopy = clone(tGraph);
check(tCopy ~= tGraph and rawequal(tCopy.Member, tGraph.Member), "clone canonical identity");
local tRestored = deserialize(serialize(tGraph));
check(rawequal(tRestored.Root, eVehicle) and rawequal(tRestored.Nested, eVehicle.car), "restore enum identities");
check(rawequal(tRestored.Member, eVehicle.car.honda) and rawequal(tRestored.Alias, tRestored.Member), "restore member aliases");

tHost.tick = function(n) tHost.calls[#tHost.calls + 1] = n; return n; end;
LXE.loadSources({
    ["a.lxe"] = "namespace Ordered { enum Later requires(Ordered.First) { One = tick(3); } }",
    ["z.lxe"] = "namespace Ordered { enum First { One = tick(1); Two = tick(2); } }",
}, tHost);
check(table.concat(tHost.calls, ",") == "1,2,3", "dependency order precedes value evaluation");
LXE.loadSources({["incremental.lxe"] = "namespace Ordered { enum Next requires(Ordered.First) { Existing = Ordered.First.One; } }"}, tHost);
check(tHost.Ordered.Next.Existing.Value == tHost.Ordered.First.One, "existing enum as payload does not embed");
check(not LXE.isEnum(tHost.Ordered.Next.Existing) and tHost.Ordered.First.Parent == null, "no reparenting");

local nCalls = #tHost.calls;
reject(function() LXE.loadSources({["missing.lxe"] = "namespace Missing { enum E requires(Absent.E) { One = tick(9); } }"}, tHost); end, "Missing required");
reject(function() LXE.loadSources({["cycle.lxe"] = "namespace Cycle { enum A requires(Cycle.B) { One = tick(9); } enum B requires(Cycle.A) { One; } }"}, tHost); end, "cycle");
check(#tHost.calls == nCalls and tHost.Missing == nil and tHost.Cycle == nil, "dependency errors execute no payloads");
reject(function() LXE.loadSources({["nil.lxe"] = "namespace NilCase { enum E { One = nil; } }"}, tHost); end, "nil");
check(tHost.NilCase == nil, "nil failure does not publish");
for n, sMembers in ipairs({"A = 2; B;", "A = false; B = false;", "A = shared; B = shared;"}) do
    reject(function() LXE.loadSources({["duplicate.lxe"] = "namespace Duplicate"..n.." { enum E { "..sMembers.." } }"}, tHost); end, "Duplicate enum value");
end
LXE.loadSources({["distinct.lxe"] = "namespace Distinct { enum E { A = {}; B = {}; } }"}, tHost);
check(tHost.Distinct.E.A.Value ~= tHost.Distinct.E.B.Value, "different table values allowed");
reject(function() LXE.loadSources({["collision.lxe"] = "namespace BadNames { enum E { Value; } }"}, tHost); end, "Reserved");
reject(function() LXE.loadSources({["badextension.lxe"] = "namespace BadExtension { enum E { A; } extension E.A(this) { return true; } }"}, tHost); end, "collision");
LXE.loadSources({["one.lxe"] = "namespace ExternalExtension { enum E { A; } }",
    ["two.lxe"] = "extension ExternalExtension.E.test(this) { return true; }"}, tHost);
check(tHost.ExternalExtension.E.A:test(), "extension may use its target FQN from a separate file");
reject(function() LXE.loadSources({["unknown.lxe"] = "namespace Unknown { enum E { A = missingGlobal; } }"}, tHost); end, "Unknown name");
reject(function() LXE.loadSources({["requires.lxe"] = "namespace NoRequires { enum E { A = Ordered.First.One; } }"}, tHost); end, "Declare requires");
check(tHost.Unknown == nil and tHost.NoRequires == nil, "value failures do not publish");

LXC.loadSources({
    ["owned.lxe"] = "namespace Owned { public enum External within Owned.Car { Red; Blue; } enum Shared { Seven = 7; } }",
    ["classes.lxc"] = [=[
extension Owned.Car.Kind.isSedan(this) { return this == Owned.Car.Kind.Sedan; }
namespace Owned {
    public class Car {
        public enum Kind within Owned.Car { Sedan; Coupe; }
        private enum Secret within Owned.Car { One; }
        protected enum Family within Owned.Car { One; }
        public static Count = Shared.Seven.Value;
        public static DefaultKind = Car.Kind.Sedan;
        private choice = Car.Secret.One;
        public getChoice() { return this.choice; }
        extension Owned.Car.Kind.isCoupe(this) { return this == Owned.Car.Kind.Coupe; }
        public static secret() { return Car.Secret.One; }
        public static saveSecret() { return serialize(Car.Secret.One); }
        public static loadSecret(sSaved) { return deserialize(sSaved); }
    }
    public class Child : Car {
        public static family() { return Car.Family.One; }
    }
    public class Boat {
        public enum Kind within Owned.Boat { Sail; Motor; }
    }
}
]=],
}, tHost);
check(tHost.Owned.Car.Count == 7, "enum before class static initializer");
check(tHost.Owned.Car.Kind.Sedan:isSedan(), "inline extension before enum");
check(tHost.Owned.Car.External.Blue.Ordinal == 2, "separate class-owned enum");
check(tHost.Owned.Boat.Kind.Sail.Parent == tHost.Owned.Boat.Kind, "multiple class owners in one file");
check(tHost.Owned.Car.Kind.Parent == null, "class ownership is not enum parent");
check(tHost.Owned.Car.secret().Name == "One", "declaring class private access");
check(tHost.Owned.Child.family().Name == "One", "derived protected access");
reject(function() return tHost.Owned.Car.Secret; end, "Cannot access");
reject(function() return tHost.Owned.Car.Family; end, "Cannot access");
reject(function() tHost.Owned.Car.Kind = tHost.Owned.Car.External; end, "Cannot reassign");
local tOwnedCopy = deserialize(serialize({Member = tHost.Owned.Car.Kind.Sedan}));
check(tOwnedCopy.Member == tHost.Owned.Car.Kind.Sedan, "class-owned member persistence");
reject(function() LXC.loadSources({["wrong.lxc"] = "namespace WrongOwner { public class C { public enum E within WrongOwner.D { A; } } }"}, tHost); end, "match its enclosing");
reject(function() LXC.loadSources({["absent.lxe"] = "namespace MissingOwner { public enum E within MissingOwner.C { A; } }"}, tHost); end, "owner must be declared");
reject(function() LXC.loadSources({["staticfail.lxc"] = "namespace StaticFailure { public class C { public enum E within StaticFailure.C { A; } static C() { error('static failure'); } } }"}, tHost); end, "static failure");
check(tHost.StaticFailure == nil, "failed class static does not publish enum or owner");
check(tHost.Owned.Car.DefaultKind == tHost.Owned.Car.Kind.Sedan, "owned enum precedes ordinary static fields");
local sPrivate = tHost.Owned.Car.saveSecret();
check(tHost.Owned.Car.loadSecret(sPrivate) == tHost.Owned.Car.secret(), "declaring class private enum round trip");
reject(function() return deserialize(sPrivate); end, "Inaccessible class-owned enum");
reject(function() return serialize(tHost.Owned.Car.secret()); end, "Inaccessible class-owned enum");
reject(function() return deserialize(sPrivate:gsub("^%-%-LXC:3\n", "")); end, "Inaccessible class-owned enum");
reject(function() LXE.connectClasses({allowed = function() return true; end}); end, "another class service");
LXC.loadSources({["later.lxc"] = "using Spec; namespace LaterClass { public class C { public static Selected = vehicle.car; } }"}, tHost);
check(tHost.LaterClass.C.Selected == eVehicle.car, "using resolves previously published enums");
LXC.loadSources({["required.lxc"] = "namespace RequiredClass { enum E { A; } public class C requires(RequiredClass.E) { public static Selected = E.A; } }"}, tHost);
check(tHost.RequiredClass.C.Selected == tHost.RequiredClass.E.A, "class requires enum in coordinated batch");
check(tHost.Owned.Car.Kind.Coupe:isCoupe(), "extension at class declaration scope");
local nBeforeInvalidClass = #tHost.calls;
reject(function() LXC.loadSources({["badclass.lxc"] = "namespace BadClass { enum E { A = tick(8); } public class C { public broken() { local = 1; } } }"}, tHost); end, "badclass.lxc");
check(#tHost.calls == nBeforeInvalidClass and tHost.BadClass == nil, "invalid class syntax precedes enum payload execution");
reject(function() LXE.loadSources({["crosscollision.lxe"] = "namespace CrossCollision { enum E { Child { test; } } extension E.test(this) { return true; } }"}, tHost); end, "Embedded member/extension collision");
local oLeaked;
tHost.leak = function(oValue) oLeaked = oValue; return 1; end;
reject(function() LXE.loadSources({["discard.lxe"] = "namespace Discard { enum E { A = leak(E); B = nil; } }"}, tHost); end, "nil");
check(tHost.Discard == nil, "failed enum batch stays unpublished");
reject(function() return oLeaked.Name; end, "discarded");
LXE.loadSources({["retry.lxe"] = "namespace Discard { enum E { A; } }"}, tHost);
check(tHost.Discard.E.A.Value == 1, "failed declarations may be retried");
local oUnknown = setmetatable({}, {__serialtype = "lxevalue", __serialize = function() return {Path = "NotLoaded.E.A"}; end});
reject(function() return deserialize(serialize(oUnknown)); end, "already be loaded");
local fOriginalScan, nScans = io.scanfiles, 0;
io.scanfiles = function(tRoots, ...)
    nScans = nScans + 1;
    local tTypes = {...};
    check(#tRoots == 2 and tRoots[1] == "present" and tRoots[2] == "absent", "discovery deduplicates template roots");
    check(#tTypes == 2 and tTypes[1] == "lxc" and tTypes[2] == "lxe", "one scan requests every approved declaration type");
    return {"C:/Example/E.lxe", "C:/Example/E.lxe", "C:/Example/C.lxc", "C:/Example/ignored.lua"}, nil, {Roots = {}, Directories = 1};
end;
local bDiscovered, tFound = pcall(LXE.discover, "present/?.lua;present/?/init.lua;absent/?.lua");
io.scanfiles = fOriginalScan;
assert(bDiscovered, tFound);
check(nScans == 1 and #tFound == 1 and tFound[1] == "C:/Example/E.lxe", "discovery deduplicates files and returns only enums");
local oCar = tHost.Owned.Car();
local oCarCopy = deserialize(serialize(oCar));
check(oCarCopy ~= oCar and oCarCopy.getChoice() == oCar.getChoice(), "private enum state survives ordinary instance save/load");
reject(function() return serialize({Object = oCar, Escaped = oCar.getChoice()}); end, "Inaccessible class-owned enum");
LXC.loadSources({["laterrequires.lxc"] = "namespace LaterRequires { public class C requires(Spec.vehicle) { public static Selected = Spec.vehicle.car; } }"}, tHost);
check(tHost.LaterRequires.C.Selected == eVehicle.car, "later class requires a previously published enum");
LXC.loadSources({["static-enums.lxc"] = [=[
namespace StaticEnums {
    enum Mode { A; B; }
    enum Other { A; B; }
    public class C {
        public enum Kind within StaticEnums.C { A; B; }
        private enum Hidden within StaticEnums.C { A; B; }
        public static Selected = Mode.A;
        public static Alias = Mode.A;
        public static Pending;
        public static Count = 1;
        public const Fixed = 10;
        public static final Frozen = 20;
        private static Secret = C.Hidden.A;
        public static saveAll() { return lxc.saveStatic(C); }
        public static loadAll(sSaved) { lxc.loadStatic(C, sSaved); }
        public static changeSecret() { C.Secret = C.Hidden.B; }
        public static getSecret() { return C.Secret; }
    }
}
]=]}, tHost);
local cStatics, eModes = tHost.StaticEnums.C, tHost.StaticEnums.Mode;
cStatics.Pending = eModes.B;
check(cStatics.Pending == eModes.B, "existing enum assigned to initially null field");
local sStatics = LXC.saveStatic(cStatics);
local tStaticMap = deserialize(sStatics);
check(tStaticMap["StaticEnums.C:Selected"] == eModes.A and
    tStaticMap["StaticEnums.C:Alias"] == eModes.A, "static enum map uses canonical identities");
check(tStaticMap["StaticEnums.C:Secret"] == nil and
    tStaticMap["StaticEnums.C:Fixed"] == nil and tStaticMap["StaticEnums.C:Frozen"] == nil,
    "static save retains access and binding exclusions");
cStatics.Selected, cStatics.Alias, cStatics.Pending, cStatics.Count = eModes.B, eModes.B, eModes.A, 9;
LXC.loadStatic(cStatics, sStatics);
check(cStatics.Selected == eModes.A and cStatics.Alias == cStatics.Selected and
    cStatics.Pending == eModes.B and cStatics.Count == 1, "static enum round trip restores shared canonical members");
local sPrivateStatics = cStatics.saveAll();
local oPrivateBefore = cStatics.getSecret();
cStatics.changeSecret();
cStatics.loadAll(sPrivateStatics);
check(cStatics.getSecret() == oPrivateBefore, "private static enum state round trips from declaring class");
reject(function() LXC.loadStatic(cStatics, sPrivateStatics); end, "Inaccessible class-owned enum");
local tBadStatics = deserialize(sStatics);
tBadStatics["StaticEnums.C:Selected"] = tHost.StaticEnums.Other.A;
tBadStatics["StaticEnums.C:Count"] = 22;
reject(function() LXC.loadStatic(cStatics, serialize(tBadStatics)); end, "Field type mismatch");
check(cStatics.Count == 1 and cStatics.Selected == eModes.A, "failed type validation commits no static fields");
tBadStatics = deserialize(sStatics);
tBadStatics["StaticEnums.C:Unknown"] = true;
reject(function() LXC.loadStatic(cStatics, serialize(tBadStatics)); end, "Unknown static snapshot field");
check(cStatics.Count == 1, "unknown static field failure stays atomic");
local sLiteralStatics = LXC.serialize({["StaticEnums.C:Count"] = 4});
LXC.loadStatic(cStatics, sLiteralStatics);
check(cStatics.Count == 4, "standalone scalar snapshot remains accepted");
reject(function() LXE.loadSources({["late-owned.lxe"] =
    "namespace StaticEnums { enum Late within StaticEnums.C { A; } }"}, tHost); end, "coordinated LXC loading");
reject(function() LXC.loadSources({["late-owned.lxe"] =
    "namespace StaticEnums { enum Late within StaticEnums.C { A; } }"}, tHost); end, "owner must be declared");
check(not pcall(function() return cStatics.Late; end), "late class enum attachment is rejected");
print("PASS LXE: "..nChecks.." behavioral checks.");
return nChecks;







