--[[!
@fqxn Tests.Directives
@desc Verifies LXC type contracts and pre-initialization default
    selection using in-memory sources. No declaration fixtures are written.
!]]
local _pRoot = assert(debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/tests/"));
package.path = _pRoot.."/?.lua;"..package.path;
require("LuaEx.init");
local LXC = require("LuaEx.lib.lxc");
LXC.bindHost(_G);
local _nChecks = 0;
local _nBatch = 0;

--[[!
@fqxn Tests.Directives.check
@desc Counts a successful observable contract assertion.
!]]
local function check(bCondition, sMessage)
    _nChecks = _nChecks + 1;
    assert(bCondition, sMessage);
end

--[[!
@fqxn Tests.Directives.reject
@desc Requires failure with the specified diagnostic fragment.
!]]
local function reject(fAction, sFragment)
    local bOK, vError = pcall(fAction);
    check(not bOK and tostring(vError):find(sFragment, 1, true),
        "Expected "..sFragment.."; got "..tostring(vError));
end

--[[!
@fqxn Tests.Directives.loadBody
@desc Loads a fresh namespace without relying on global short aliases.
!]]
local function loadBody(sBody, tHost)
    _nBatch = _nBatch + 1;
    tHost = tHost or setmetatable({}, {__index = _G});
    local sNamespace = "DirectiveTest".._nBatch;
    LXC.loadSources({[sNamespace..".lxc"] = "namespace "..sNamespace.." { "..sBody.." }"}, tHost);
    return tHost[sNamespace], tHost;
end

local tClasses = loadBody([=[
class Base {
    ---@type number
    protected Pending = null;
    public Base() {}
    public read() { return this.Pending; }
}
class Child : Base { public Child() { this.Pending = 0; } }
class Unset { ---@type number
    public Pending = null;
}
class Wrong { ---@type number
    public Value;
    public Wrong() { this.Value = "wrong"; }
}
class Values {
    ---@type boolean
    public Flag = false;
    ---@type number
    public Zero = 0;
    ---@type string
    public Empty = "";
    ---@type table
    public Data = {};
    ---@type function
    public Callback = function() return true; end;
    ---@type number?
    public Optional;
    public Unannotated;
}
class Animal {}
class Dog : Animal {}
class Cat : Animal {}
class Holder {
    ---@type Animal
    public Pet;
    public Holder(oPet) { this.Pet = oPet; }
}
class Computed {
    ---@type number
    public Result { get { error("getter must not run"); } }
}
class Stored {
    ---@type number
    public Value { get; set; }
    public Stored() { this.Value = 4; }
}
class Backed {
    ---@type number
    public Value { get { return field; } set { field = value; } }
    public Backed() { this.Value = 5; }
}
class BackedMissing { ---@type number
    public Value { get { return field; } }
}
class ShadowedField { ---@type number
    public Value { get { local field = 8; return field; } }
}
class PropertyBase { ---@type number
    public Value { get; set; } = 6;
}
class PropertyChild : PropertyBase {
    public override Value { get { return field + 1; } set { field = value; } }
}
class StaticGood { ---@type number
    public static Value;
    static StaticGood() { StaticGood.Value = 9; }
}
]=]);
check(tClasses.Child().read() == 0, "last constructor initializes inherited protected storage");
reject(function() tClasses.Base(); end, "@type number");
reject(function() tClasses.Unset(); end, "@type number");
reject(function() tClasses.Wrong(); end, "@type number");
local oValues = tClasses.Values();
check(oValues.Flag == false and oValues.Zero == 0 and oValues.Empty == "", "false, zero and empty string are values");
check(oValues.Callback() == true and type(oValues.Data) == "table", "table and function annotations");
check(rawequal(oValues.Optional, null) and rawequal(oValues.Unannotated, null), "nullable and unannotated null survive");
oValues.Optional = 10;
reject(function() oValues.Optional = null; end, "Typed field cannot return to null");
local oDog, oCat = tClasses.Dog(), tClasses.Cat();
local oHolder = tClasses.Holder(oDog);
check(rawequal(oHolder.Pet, oDog), "declared base type accepts a descendant");
reject(function() oHolder.Pet = oCat; end, "Field type mismatch");
reject(function() tClasses.Holder({}); end, "@type Animal");
check(tClasses.Computed() ~= nil and tClasses.ShadowedField() ~= nil, "computed getters and shadowed field never execute");
check(tClasses.Stored().Value == 4 and tClasses.Backed().Value == 5, "automatic and custom stored properties");
reject(function() tClasses.BackedMissing(); end, "@type number");
check(tClasses.PropertyChild().Value == 7, "override shares annotated original storage");
check(tClasses.StaticGood.Value == 9, "static constructor completion");
check(LXC.clone(oValues).Zero == 0 and deserialize(serialize(tClasses.Stored())).Value == 4, "clone and host restore retain annotated values");
reject(function() serialize(oValues); end, "compiled closures");
check(LXC.clone(tClasses.Computed()) ~= nil, "copy never invokes computed getter");
check(deserialize(serialize(tClasses.Computed())) ~= nil, "restore never invokes computed getter");

for _, tCase in ipairs({
    {"---@type Missing\npublic Value;", "Unresolved"};
    {"---@type number|string\npublic Value;", "Invalid @type"};
    {"---@type nil\npublic Value;", "Invalid @type"};
    {"---@type number\n---@type string\npublic Value;", "Duplicate @type"};
    {"---@unknown\npublic Value;", "Unknown directive"};
    {"---@type number\npublic method() {}", "does not support method"};
    {"---@default\npublic Value;", "does not support field"};
    {"---@type number\n", "no supported following declaration"};
}) do
    reject(function() loadBody("class Invalid { "..tCase[1].." }"); end, tCase[2]);
end
reject(function() loadBody("class Invalid { ---@type number\npublic static Value; }"); end, "@type number");
reject(function() local tTypes = loadBody("class Parent { ---@type number\nprotected final Value; public Parent() {} } class Child : Parent { public Child() { this.Value = 1; } }"); tTypes.Child(); end, "Uninitialized final");
reject(function() local tTypes = loadBody("class Parent { ---@type number\nprivate Value; public Parent() {} } class Child : Parent { public Child() { this.Value = 1; } }"); tTypes.Child(); end, "private member");
reject(function() loadBody("class Parent { ---@type number\npublic Value { get; set; } = 1; } class Child : Parent { ---@type string\npublic override Value { get; set; } }"); end, "Conflicting overridden");
local tDocumentation = loadBody([=[class C {
    --[[! @type Missing !]]
    public Value;
    ---@type number
    -- ordinary comment
    public Number = 1;
    public Text = "---@type Missing";
}]=]);
check(rawequal(tDocumentation.C().Value, null), "DOx type text is not a directive");
check(tDocumentation.C().Number == 1, "ordinary comments preserve attachment");

local tImportHost = setmetatable({}, {__index = _G});
LXC.loadSources({["imports.lxc"] = [=[
namespace DirectiveImports { class Animal {} }
using DirectiveImports;
namespace DirectiveImportUser { class Holder { ---@type Animal
public Pet; public Holder(oPet) { this.Pet = oPet; } } }
]=]}, tImportHost);
check(tImportHost.DirectiveImportUser.Holder(tImportHost.DirectiveImports.Animal()) ~= nil, "using resolves annotation without aliases");
reject(function() LXC.loadSources({["ambiguous.lxc"] = [=[
namespace DirectiveAmbiguousA { class A {} }
namespace DirectiveAmbiguousB { class A {} }
using DirectiveAmbiguousA; using DirectiveAmbiguousB;
namespace DirectiveAmbiguousUser { class C { ---@type A
public Value; } }
]=]}, tImportHost); end, "Ambiguous class");

local tDefaultHost = setmetatable({events = {}}, {__index = _G});
local tDefaults = {
    ["default.lxc"] = [=[namespace DirectiveDefaults {
        ---@default
        class C {
            public class Lost {}
            public enum LostEnum within DirectiveDefaults.C { One = error("discarded payload"); }
            extension DirectiveDefaults.C.LostEnum.lost(this) { return true; }
            static C() { error("discarded static constructor"); }
        }
        ---@default
        enum E { A = error("discarded enum payload"); }
        ---@default
        extension E.label(this) { return "default"; }
    }]=];
    ["ordinary.lxc"] = [=[namespace DirectiveDefaults {
        class C { public Value = 2; }
        enum E { B; }
        extension E.label(this) { return "ordinary"; }
    }]=];
};
LXC.loadSources(tDefaults, tDefaultHost);
check(tDefaultHost.DirectiveDefaults.C().Value == 2, "ordinary class replaces default");
check(tDefaultHost.DirectiveDefaults.E.B:label() == "ordinary", "ordinary enum and extension replace defaults");
check(LXC.class.getbyname("DirectiveDefaults.C.Lost") == nil, "discarded nested class is not registered");
reject(function() return tDefaultHost.DirectiveDefaults.C.LostEnum; end, "Unknown member");
local tSingle = loadBody("---@default\nclass C { public Value = 3; }");
check(tSingle.C().Value == 3, "unopposed default class loads");
local tNested = loadBody("class Outer { ---@default\npublic class Inner { public Value = 1; } public class Inner { public Value = 2; } }");
check(tNested.Outer.Inner().Value == 2, "nested class candidates are selected before collision checks");
for _, tTags in ipairs({{"", ""}, {"---@default\n", "---@default\n"}, {"---@default\n", "", ""}}) do
    local tSources = {};
    for n, sTag in ipairs(tTags) do tSources[n..".lxc"] = "namespace DirectiveDuplicate { "..sTag.."class C {} }"; end
    reject(function() LXC.loadSources(tSources, {}); end, "Duplicate class");
end
reject(function() loadBody("---@default value\nclass C {}"); end, "takes no arguments");
reject(function() LXC.loadSources({["late.lxc"] = "namespace DirectiveDefaults { ---@default\nclass C {} }"}, tDefaultHost); end, "Duplicate class");

local tClone = loadBody([=[class C {
    ---@type number
    public Value;
    public C(bInitialize) { if bInitialize then this.Value = 4; end }
    public operator __clone() { local copy = C(false); copy.Value = this.Value; return copy; }
}]=]);
check(LXC.clone(tClone.C(true)).Value == 4, "custom copy validates final copied state instead of incomplete constructor state");
local tBadClone, tBadHost = loadBody([=[class C {
    ---@type number
    public Value;
    public C(bInitialize) { if bInitialize then this.Value = 4; end }
    public operator __clone() { local copy = C(false); sink.copy = copy; return copy; }
}]=], setmetatable({sink = {}}, {__index = _G}));
reject(function() LXC.clone(tBadClone.C(true)); end, "@type number");
reject(function() return tBadHost.sink.copy.Value; end, "failed");

local tRestore = loadBody([=[class C {
    ---@type number
    public Value = 3;
    public validateSnapshot(tProjection) { tProjection.pub.Value = 4; }
}]=]);
check(deserialize(serialize(tRestore.C())).Value == 4, "restore validates after snapshot hooks");
local tRestoreMissing = loadBody([=[class C {
    ---@type number?
    public Value;
}]=]);
check(rawequal(deserialize(serialize(tRestoreMissing.C())).Value, null), "nullable restore preserves null");

-- Completion contracts do not add checks to subsequent ordinary assignment.
local oLater = tRestoreMissing.C();
oLater.Value = "ordinary first-assignment type";
check(oLater.Value == "ordinary first-assignment type", "annotation does not change ordinary later assignment rules");
reject(function() LXC.clone(oLater); end, "@type number");
reject(function() deserialize(serialize(oLater)); end, "@type number");
reject(function() loadBody("class C { ---@type number\npublic Value = 'wrong'; }"); end, "Initializer conflicts");
local tMutual = loadBody("class A { ---@type B?\npublic Other; } class B { ---@type A?\npublic Other; }");
check(tMutual.A() ~= nil and tMutual.B() ~= nil, "mutual annotation references do not create initialization cycles");

local tEnumHost = setmetatable({}, {__index = _G});
lxe.loadSources({
    ["defaults.lxe"] = [=[namespace DirectiveEnumDefaults {
        ---@default
        enum E requires(Absent.Dependency) { Lost = error("must not evaluate"); }
        enum Sole { A; }
        ---@default
        extension Sole.only(this) { return 7; }
        enum Embedded {
            ---@default
            Child { Lost = error("must not evaluate"); }
            Child { Kept; }
        }
    }]=];
    ["ordinary.lxe"] = "namespace DirectiveEnumDefaults { enum E { Kept; } }";
    ["external.lxe"] = "extension DirectiveEnumDefaults.Embedded.Child.method(this) { return this.Name; }";
}, tEnumHost);
check(tEnumHost.DirectiveEnumDefaults.E.Kept.Name == "Kept", "discarded enum dependencies and payloads are ignored");
check(tEnumHost.DirectiveEnumDefaults.Sole.A:only() == 7, "unopposed default extension loads");
check(tEnumHost.DirectiveEnumDefaults.Embedded.Child.Kept:method() == "Kept", "external extension targets selected embedded enum");
lxe.loadSources({["sole.lxe"] = "namespace DirectiveEnumSole { ---@default\nenum E { A; } }"}, tEnumHost);
check(tEnumHost.DirectiveEnumSole.E.A.Name == "A", "unopposed default enum loads");
for _, sKind in ipairs({"enum", "extension"}) do
    for _, tTags in ipairs({{"", ""}, {"---@default\n", "---@default\n"}, {"---@default\n", "", ""}}) do
        local tSources = {};
        if (sKind == "extension") then tSources["enum.lxe"] = "namespace DirectiveEnumDuplicates { enum E { A; } }"; end
        for n, sTag in ipairs(tTags) do
            local sDeclaration = sKind == "enum" and "enum E { A; }" or "extension E.method(this) { return true; }";
            tSources[n..".lxe"] = "namespace DirectiveEnumDuplicates { "..sTag..sDeclaration.." }";
        end
        reject(function() lxe.loadSources(tSources, tEnumHost); end, "Duplicate "..sKind);
        check(tEnumHost.DirectiveEnumDuplicates == nil, "duplicate rejection publishes nothing");
    end
end
local tReversed = {};
tReversed["a.lxc"], tReversed["z.lxc"] = tDefaults["ordinary.lxc"], tDefaults["default.lxc"];
-- A fresh environment alone does not replace already published identities.
reject(function() LXC.loadSources(tReversed, {}); end, "Duplicate class");
local tReordered = {};
for pFile, sSource in pairs(tReversed) do tReordered[pFile] = sSource:gsub("DirectiveDefaults", "DirectiveReordered"); end
local tOrderHost = setmetatable({}, {__index = _G});
LXC.loadSources(tReordered, tOrderHost);
check(tOrderHost.DirectiveReordered.C().Value == 2 and tOrderHost.DirectiveReordered.E.B:label() == "ordinary", "selection is independent of file order");
local tDiscarded = loadBody("---@default\nclass C { public Duplicate; public Duplicate; } class C { public Kept = true; }");
check(tDiscarded.C().Kept, "semantic member errors in discarded class are ignored");
reject(function() loadBody("class C { public Duplicate; public Duplicate; }"); end, "Duplicate member");
reject(function() loadBody("class C { public class N {} public N; }"); end, "Duplicate member");
reject(function() loadBody("class C { public C() {} public C() {} }"); end, "Duplicate constructor");

local tNoPublication = setmetatable({events = {}}, {__index = _G});
reject(function() LXC.loadSources({["preflight.lxc"] = [=[namespace DirectivePreflight {
    enum E { A = table.insert(events, "payload"); }
    class C { ---@type Missing
        public Value;
        static C() { table.insert(events, "static"); }
    }
}]=]}, tNoPublication); end, "@type");
check(#tNoPublication.events == 0 and tNoPublication.DirectivePreflight == nil, "bad annotation fails before payloads or static code");

local tIgnored = loadBody([==[class C {
    --[=[
    ---@type Missing
    ]=]
    public Value;
    public Long = [=[---@type Missing]=];
}]==]);
check(rawequal(tIgnored.C().Value, null), "long comments and strings cannot introduce directives");
reject(function() loadBody("class C { public Value; ---@type number\n}"); end, "no supported following declaration");
reject(function() loadBody("class C { ---@default\n---@default\npublic class N {} }"); end, "Duplicate @default");
reject(function() loadBody("---@default\nenum E { A; } class E {}"); end, "namespace collision");

local tCycle = loadBody("class Node { ---@type Node?\npublic Next; public Node() {} }");
local oNode = tCycle.Node();
oNode.Next = oNode;
local tGraph = {First = oNode, Second = oNode};
local tGraphCopy = LXC.clone(tGraph);
check(rawequal(tGraphCopy.First, tGraphCopy.Second) and rawequal(tGraphCopy.First.Next, tGraphCopy.First), "annotated clone preserves cycles and aliases");
local tGraphLoad = deserialize(serialize(tGraph));
check(rawequal(tGraphLoad.First, tGraphLoad.Second) and rawequal(tGraphLoad.First.Next, tGraphLoad.First), "annotated restore validates completed cyclic graph");
local tPrivate = loadBody("class Outer { private class Hidden {} ---@type Hidden?\nprivate Value; public Outer() {} }");
check(tPrivate.Outer() ~= nil, "declaring scope may annotate its private nested class");
reject(function() loadBody("class Outer { private class Hidden {} } class Other { ---@type Outer.Hidden?\npublic Value; }"); end, "inaccessible @type");
reject(function() loadBody("class Parent { ---@type number\nprotected static Value; } class Child : Parent { static Child() { Child.Value = 1; } }"); end, "@type number");
reject(function() loadBody("class C { ---@type number\npublic Value { get { return function() return field; end; } } }").C(); end, "@type number");
reject(function() loadBody("class Parent { ---@type number\npublic Value { get; set; } } class Child : Parent { public override Value { get { return 1; } set {} } }").Child(); end, "@type number");
local tFailureHost = setmetatable({}, {__index = _G});
reject(function() LXC.loadSources({["default.lxc"] = "namespace DirectiveNoRetry { ---@default\nclass C {} }",
    ["ordinary.lxc"] = "namespace DirectiveNoRetry { class C { static C() { error('selected initialization fails'); } } }"}, tFailureHost); end, "selected initialization fails");
check(tFailureHost.DirectiveNoRetry == nil, "failed ordinary declaration does not retry its default or publish");
reject(function() LXC.loadSources({["default.lxc"] = "namespace DirectiveSoleFailure { ---@default\nclass C { static C() { error('sole default fails'); } } }"}, tFailureHost); end, "sole default fails");
check(tFailureHost.DirectiveSoleFailure == nil, "sole default uses normal transactional failure");
reject(function() lxe.loadSources({["late.lxe"] = "extension DirectiveEnumSole.E.late(this) { return true; }"}, tEnumHost); end, "declared in this batch");
reject(function() lxe.loadSources({["late.lxe"] = "namespace DirectiveEnumSole { ---@default\nenum E { B; } }"}, tEnumHost); end, "Duplicate enum");

-- A failed custom copy must not leave construction validation deferred afterward.
reject(function() tBadClone.C(false); end, "@type number");
check(LXC.clone(tClone.C(true)).Value == 4, "copy failure cleans up its completion session");

local tNativeKinds = loadBody([=[class C {
    ---@type table
    public Tagged = setmetatable({}, {__type = "CustomDisplay"});
    ---@type thread
    public Thread = coroutine.create(function() end);
}]=]);
check(type(tNativeKinds.C().Tagged) == "CustomDisplay", "primitive contract uses runtime storage type rather than display metadata");
reject(function() loadBody("class C { ---@type number\npublic Value = setmetatable({}, {__type = 'number'}); }").C(); end, "@type number");
reject(function() loadBody("---@type number\nenum E { A; }"); end, "does not support enum");
local tTamper, tTamperHost = loadBody([=[class C {
    ---@type number
    public Value;
    public C() {
        sink.saved = _G.ipairs;
        _G.ipairs = function() return function() end; end;
    }
}]=], setmetatable({sink = {}}, {__index = _G}));
local bTampered, vTampered = pcall(tTamper.C);
_G.ipairs = tTamperHost.sink.saved;
check(not bTampered and tostring(vTampered):find("@type number", 1, true), "constructor cannot disable completion by replacing global ipairs");

-- Instrument a fresh private service to count boundaries, not field operations.
local fDirectiveFactory = package.loaded["LuaEx.lib.lxc.Directives"];
local tPasses, tStaticPasses = {}, {};
package.loaded["LuaEx.lib.lxc.Directives"] = function(...)
    local Service = fDirectiveFactory(...);
    local fCheck = Service.check;
    Service.check = function(tState, bStatic, ...)
        local tCounts, vKey = bStatic and tStaticPasses or tPasses, bStatic and tState.Class.FullName or tState.Object;
        tCounts[vKey] = (tCounts[vKey] or 0) + 1;
        return fCheck(tState, bStatic, ...);
    end;
    return Service;
end;
local bFresh, Fresh = pcall(assert(loadfile(_pRoot.."/LuaEx/lib/lxc.lua")));
package.loaded["LuaEx.lib.lxc.Directives"] = fDirectiveFactory;
assert(bFresh, Fresh);
local tFreshHost = setmetatable({}, {__index = _G});
local LXE = package.loaded["LuaEx.lib.lxe"];
package.loaded["LuaEx.lib.lxe"] = nil;
local bLoaded, vLoadError = pcall(Fresh.loadSources, {["budget.lxc"] = [=[namespace DirectiveBudget {
    class Base { ---@type number
        protected Pending;
        public Base() {}
    }
    class C : Base {
        ---@type number
        public Value { get; set; } = 1;
        public C() { this.Pending = 2; }
        public read() { return this.Value; }
    }
    class D {
        ---@type number
        public Value;
        public D(bSet) { if bSet then this.Value = 3; end }
        public operator __clone() { local copy = D(false); copy.Value = this.Value; return copy; }
    }
}]=]}, tFreshHost);
package.loaded["LuaEx.lib.lxe"] = LXE;
assert(bLoaded, vLoadError);
local oCounted = tFreshHost.DirectiveBudget.C();
check(tPasses[oCounted] == 1, "one completion pass after most-derived constructor");
oCounted.Value = 5;
check(oCounted.Value == 5 and oCounted.getValue() == 5 and oCounted.read() == 5 and tPasses[oCounted] == 1,
    "reads, writes, accessors and methods add no directive passes");
local oCountedCopy = Fresh.clone(oCounted);
check(tPasses[oCountedCopy] == 1, "automatic copy receives one completion pass");
local oCustomCopy = Fresh.clone(tFreshHost.DirectiveBudget.D(true));
check(tPasses[oCustomCopy] == 1, "constructor-created custom copy receives one final pass");
local oCountedLoad = Fresh.deserialize(Fresh.serialize(oCounted));
check(tPasses[oCountedLoad] == 1, "constructor-free restore receives one completion pass");
check(tStaticPasses["DirectiveBudget.Base"] == 1 and tStaticPasses["DirectiveBudget.C"] == 1,
    "one static completion pass per declaring class");

local tAccessHost = setmetatable({}, {__index = _G});
LXC.loadSources({["access-owner.lxc"] = [=[namespace DirectiveExtensionAccess {
    class Owner {
        private static Secret = 7;
        private enum Hidden within DirectiveExtensionAccess.Owner { A; }
        public enum E within DirectiveExtensionAccess.Owner requires(DirectiveExtensionAccess.Owner.Hidden) { A; }
        extension DirectiveExtensionAccess.Owner.E.named(this) { return DirectiveExtensionAccess.Owner.Hidden.A.Name; }
        extension DirectiveExtensionAccess.Owner.E.secret(this) { return DirectiveExtensionAccess.Owner.Secret; }
    }
}]=], ["access-outside.lxe"] = [=[
extension DirectiveExtensionAccess.Owner.E.outside(this) { return DirectiveExtensionAccess.Owner.Secret; }
extension DirectiveExtensionAccess.Owner.E.hidden(this) { return DirectiveExtensionAccess.Owner.Hidden.A; }
]=]}, tAccessHost);
local oAccessMember = tAccessHost.DirectiveExtensionAccess.Owner.E.A;
check(oAccessMember:named() == "A", "lexical class scope retains declared private enum dependencies");
reject(function() oAccessMember:secret(); end, "private member");
reject(function() oAccessMember:outside(); end, "private member");
reject(function() oAccessMember:hidden(); end, "Inaccessible class-owned enum");
print("PASS directives: ".._nChecks.." behavioral checks.");
