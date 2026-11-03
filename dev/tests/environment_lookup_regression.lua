--[[!
@fqxn Tests.EnvironmentLookup
@desc Verifies repeated class/member lookups without freezing host values or
    bypassing access checks. All declarations stay in memory. Run from the
    LuaEx root: lua dev/tests/environment_lookup_regression.lua.
!]]
local pSource = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
if (not LUAEX_INIT) then
    local pRoot = assert(pSource:match("^(.*)dev/tests/environment_lookup_regression%.lua$"));
    package.path = pRoot.."?.lua;"..package.path;
    require("LuaEx.init");
end

local nChecks = 0;
local tHost = setmetatable({HostValue = 1, Future = "host fallback"}, {__index = _G});

--[[!
@fqxn Tests.EnvironmentLookup.check
@desc Counts an observable contract assertion and reports its label on failure.
!]]
local function check(bCondition, sMessage)
    assert(bCondition, sMessage);
    nChecks = nChecks + 1;
end

--[[!
@fqxn Tests.EnvironmentLookup.reject
@desc Requires an operation to fail with the expected diagnostic fragment.
!]]
local function reject(fAction, sFragment)
    local bOK, sReason = pcall(fAction);
    check(not bOK and tostring(sReason):find(sFragment, 1, true), sFragment..": "..tostring(sReason));
end

lxc.loadSources({["LookupReaders.lxc"] = [[
    using LookupImportA; using LookupImportB; using LookupEnums;
    namespace LookupImportA { class Preferred {} }
    namespace LookupCache {
        class Reader {
            public static hostValue() { return HostValue; }
            public static future() { return Future; }
            public static preferred() { return Preferred; }
            public static namespaceValue() { return LookupCache.extra; }
            public static lateNamespace() { return LookupLater.Branch.Leaf; }
            public static enumValue() { return State; }
        }
        class Base {
            private value = 11;
            public readBase() { return this.value; }
        }
        class Child : Base {
            private value = 22;
            public Child() { base(); }
            public readChild() { return this.value; }
        }
        class Owner {
            private class Secret { public Secret() {} public read() { return 9; } }
            public static secret() { return Secret; }
            public static readSecret() { return Secret().read(); }
        }
    }
]]}, tHost);

local Reader = tHost.LookupCache.Reader;
local oChild = tHost.LookupCache.Child();

-- Warm both successful resolutions and misses before changing the host/registry.
for nIndex = 1, 12 do
    check(Reader.hostValue() == 1 and Reader.future() == "host fallback", "warm host lookups");
    check(rawequal(Reader.preferred(), tHost.LookupImportA.Preferred), "warm imported class");
    check(oChild.readBase() == 11 and oChild.readChild() == 22, "lexical private member selection");
end
reject(function() return oChild.value; end, "Cannot access private member");

tHost.HostValue = false;
check(Reader.hostValue() == false, "false host value stays live");
tHost.HostValue = function() return 17; end;
check(Reader.hostValue()() == 17, "replaced host function stays live");
tHost.HostValue = nil;
check(Reader.hostValue() == nil, "removed host value stays live");
tHost.LookupCache.extra = 4;
check(Reader.namespaceValue() == 4, "namespace host fallback");
tHost.LookupCache.extra = false;
check(Reader.namespaceValue() == false, "namespace host replacement");
tHost.LookupCache.extra = nil;
reject(Reader.namespaceValue, "Unknown namespace member");

-- A later class can replace an old host fallback or outrank an imported match.
lxc.loadSources({["LookupLater.lxc"] = [[
    namespace LookupImportA { class Future {} }
    namespace LookupCache { class Preferred {} }
    namespace LookupLater.Branch { class Leaf {} }
]]}, tHost);
check(rawequal(Reader.future(), tHost.LookupImportA.Future), "class miss invalidated after publication");
check(rawequal(Reader.preferred(), tHost.LookupCache.Preferred), "class hit invalidated for nearer declaration");
check(rawequal(Reader.lateNamespace(), tHost.LookupLater.Branch.Leaf), "new deep namespace visible");

lxc.loadSources({["LookupAmbiguity.lxc"] = [[
    namespace LookupImportB { class Future {} }
]]}, tHost);
reject(Reader.future, "Ambiguous class");

-- Enum-only loads do not advance the class registry revision. Enum bindings
-- must therefore remain live independently of the class-resolution cache.
check(Reader.enumValue() == nil, "warm missing enum");
lxc.loadSources({["LookupState.lxe"] = [[
    namespace LookupEnums { public enum State { Ready; Busy; } }
]]}, tHost);
check(rawequal(Reader.enumValue(), tHost.LookupEnums.State), "enum-only publication remains visible");

for nIndex = 1, 12 do
    check(tHost.LookupCache.Owner.readSecret() == 9, "private class works in declaring scope");
    local cSecret = tHost.LookupCache.Owner.secret();
    reject(function() return cSecret(); end, "Cannot access class");
end

-- A namespace view captured during a failing static constructor must not turn
-- its warmed class lookup into a usable reference after the batch is discarded.
local oEscaped;
tHost.capture = function(oNamespace) oEscaped = oNamespace; end;
reject(function()
    lxc.loadSources({["LookupFailure.lxc"] = [[
        namespace LookupFailed {
            class Broken {
                static Broken() {
                    local cWarm = LookupFailed.Broken;
                    capture(LookupFailed);
                    error("expected lookup failure");
                }
            }
        }
    ]]}, tHost);
end, "expected lookup failure");
check(oEscaped ~= nil, "failed batch captured its warmed namespace");
reject(function() return oEscaped.Broken; end, "failed load");
check(oChild.readBase() == 11 and oChild.readChild() == 22, "failed batch preserves existing member selection");

-- Fast receiver reads must retain dispatch, accessor effects and ordinary Lua
-- parameter/shadowing rules, including inside callbacks captured by a method.
lxc.loadSources({["LookupFastReceivers.lxc"] = [[
    namespace LookupFast {
        class Base {
            private value = 1;
            private records = {};
            public final Locked = 1;
            public Value { get; set; } = 1;
            public read() { return 5; }
            public dispatch() { return this.read(); }
            public rebind(oOther) { this = oOther; return this.read(); }
            public rebindField(oOther) { this = oOther; return this.value; }
            public shadow(oOther) { local this = oOther; return this.read(); }
            public property(nValue) { this.Value = nValue; return this.Value; }
            public update(nValue) { this.value = nValue; }
            public callback() { return function() return this.value; end; }
            private hidden() { return this.value; }
            public restricted() { return this.hidden; }
            public privateCall() { return this.hidden(); }
            public arguments(...) { return ...; }
            public multiple(nValue) {
                local nOther;
                this.value, nOther = nValue, nValue + 1;
                return this.value, nOther;
            }
            public nestedWrite(nValue) { this.records[1] = nValue; return this.records[1]; }
            public changeLocked() { this.Locked = 2; }
        }
        class Child : Base { public override read() { return 9; } }
    }
]]}, tHost);
local oBase = tHost.LookupFast.Base();
local oDerived = tHost.LookupFast.Child();
local fCallback = oBase.callback();
for nIndex = 1, 12 do
    check(oDerived.dispatch() == 9, "cached method keeps virtual dispatch");
    check(oBase.rebind(oDerived) == 9 and oBase.shadow(oDerived) == 9, "receiver rebinding and shadowing");
    check(oBase.property(nIndex) == nIndex, "properties retain accessors and current values");
    oBase.update(nIndex);
    check(fCallback() == nIndex, "callback reads current private storage");
end
reject(oBase.restricted(), "Cannot access private member");
local oLoaded = deserialize(serialize(oBase));
check(oLoaded.property(30) == 30, "restored receiver uses current property storage");
local oCloned = clone(oBase);
oCloned.update(41);
check(oCloned.callback()() == 41 and fCallback() == 12, "cloned receiver owns independent cached storage");
check(oBase.rebindField({value = 72}) == 72, "direct read preserves foreign receiver fallback");
local nFirst, nSecond = oBase.multiple(50);
check(nFirst == 50 and nSecond == 51, "multiple assignment retains checked field writes");
check(oBase.nestedWrite(63) == 63, "direct table-field read preserves nested writes");
reject(function() oBase.update("wrong type"); end, "Field type mismatch");
reject(oBase.changeLocked, "Cannot reassign const/final field");
check(fCallback() == 50 and oBase.Locked == 1, "rejected writes preserve direct-read storage");
check(oBase.privateCall() == 50, "direct public body retains private caller identity");
local nArgument, vArgument, sArgument = oBase.arguments(7, nil, "last");
check(nArgument == 7 and vArgument == nil and sArgument == "last", "bound body preserves multiple/variadic results");

-- Prebound getters may be captured before allocation, before constructor
-- failure, or from a batch that later fails. Their lifetime checks must survive.
local fEarly, fFailed, fDiscarded;
tHost.bindEarly = function(oObject)
    fEarly = oObject.read;
    reject(fEarly, "Field read before initialization");
    return 0;
end;
tHost.captureFailedGetter = function(fGetter) fFailed = fGetter; end;
tHost.captureDiscardedGetter = function(fGetter) fDiscarded = fGetter; end;
lxc.loadSources({["GetterLifetime.lxc"] = [[
    namespace LookupGetterLife {
        class Early {
            private before = bindEarly(this);
            private value = 7;
            public read() { return this.value; }
            public readAgain() { return this.value; }
            public write(nValue) { this.value = nValue; }
        }
        class Fails {
            private value = 9;
            public Fails() { captureFailedGetter(this.read); error("expected constructor failure"); }
            public read() { return this.value; }
        }
    }
]]}, tHost);
local oEarly = tHost.LookupGetterLife.Early();
local fAllocated = oEarly.readAgain;
check(fEarly() == 7 and fAllocated() == 7, "early and allocated getter binding");
oEarly.write(15);
check(fEarly() == 15 and fAllocated() == 15, "all prebound getters follow validated writes");
reject(function() oEarly.write("wrong"); end, "Field type mismatch");
check(fEarly() == 15 and fAllocated() == 15, "rejected write does not publish a getter value");
reject(function() serialize(fAllocated); end, "compiled closures");
reject(function() tHost.LookupGetterLife.Fails(); end, "expected constructor failure");
reject(fFailed, "failed load or construction");
reject(function()
    lxc.loadSources({["GetterDiscard.lxc"] = [[
        namespace LookupGetterDiscard {
            class Item {
                private value = 11;
                public read() { return this.value; }
            }
            class Break requires(LookupGetterDiscard.Item) {
                static Break() {
                    local oItem = Item();
                    captureDiscardedGetter(oItem.read);
                    error("expected getter batch failure");
                }
            }
        }
    ]]}, tHost);
end, "expected getter batch failure");
reject(fDiscarded, "failed load or construction");

-- Repeated scalar writes keep their original type contract, including false
-- and numeric integer/float interchange. Rejected writes must not publish values.
lxc.loadSources({["ScalarWrites.lxc"] = [[
    namespace LookupScalarWrites {
        class Record {
            private numberValue = 1;
            private textValue = "initial";
            private flagValue = false;
            public number(nValue) { this.numberValue = nValue; }
            public text(sValue) { this.textValue = sValue; }
            public flag(bValue) { this.flagValue = bValue; }
            public getNumber() { return this.numberValue; }
            public getText() { return this.textValue; }
            public getFlag() { return this.flagValue; }
        }
    }
]]}, tHost);
local oRecord = tHost.LookupScalarWrites.Record();
local fNumber, fText, fFlag = oRecord.getNumber, oRecord.getText, oRecord.getFlag;
for nIndex = 1, 20 do
    oRecord.number(nIndex / 2);
    oRecord.text("value "..nIndex);
    oRecord.flag(nIndex % 2 == 0);
    check(fNumber() == nIndex / 2 and fText() == "value "..nIndex and fFlag() == (nIndex % 2 == 0),
        "scalar writes and prebound getter synchronization");
end
reject(function() oRecord.number("10"); end, "Field type mismatch");
reject(function() oRecord.number(nil); end, "Declared fields cannot be nil");
reject(function() oRecord.number(setmetatable({}, {__type = "number"})); end, "Field type mismatch");
reject(function() oRecord.number(tHost.LookupEnums.State.Ready); end, "Field type mismatch");
reject(function() oRecord.text(null); end, "Typed field cannot return to null");
reject(function() oRecord.flag(1); end, "Field type mismatch");
check(fNumber() == 10 and fText() == "value 20" and fFlag() == true, "rejected scalar writes preserve published values");

print("PASS lookup caches: "..nChecks.." checks; late classes/enums, live hosts, private scopes and failed batches.");
