--[[!
@fqxn Tests.NativeLXC
@desc Checks production storage/facade semantics with optional C acceleration.
    Execute in separate native-enabled and LXC_NATIVE_BACKEND=lua processes.
!]]
local LXC = require('LuaEx.lib.lxc');
local Native = require('LuaEx.lib.lxc.Native');
local tHost = setmetatable({Leaks = {}}, {__index = _G});
local nChecks = 0;
local function check(bValue, sMessage)
    assert(bValue, sMessage);nChecks = nChecks + 1;
end
local function reject(fAction, sMessage)
    local bOK, sReason = pcall(fAction);
    check(not bOK and tostring(sReason):find(sMessage, 1, true), tostring(sReason));
end
LXC.loadSources({['HybridContracts.lxc'] = [=[
namespace HybridContracts {
    class Base {
        private value = 3;
        public Visible = 4;
        public static Total = 0;
        public const Fixed = 7;
        public final Once = null;
        public Shared = {};
        public Count { get; set; } = 5;
        public Custom { get { return field; } set { field = value; HybridContracts.Base.Total = HybridContracts.Base.Total + 1; } } = 6;
        public Yielding { get { coroutine.yield('getter'); return field; } set { coroutine.yield('setter'); field = value; } } = 8;
        public Base() { this.Once = 9; }
        public read() { return this.value; }
        public assign(value) { this.value = value; }
        public setVisible(value) { this.Visible = value; }
        public readVisible() { return this.Visible; }
        public setShared(value) { this.Shared = value; }
        public setFixed(value) { this.Fixed = value; }
        public setOnce(value) { this.Once = value; }
        public complex(value) { this.value = value; return this.value, false; }
        public echo(...) { return ...; }
        public callback() { return function(value) this.value = value; return this.value; end; }
        public yieldMethod(value) { coroutine.yield('method'); this.Visible = value; return this.Visible; }
    }
    class Child : Base {
        private value = 11;
        public readChild() { return this.value; }
        public assignChild(value) { this.value = value; }
    }
    class Pending {
        public Value = null;
        public assign(value) { this.Value = value; }
        public read() { return this.Value; }
    }
    class Broken {
        private value = 0;
        public assign(value) { this.value = value; }
        public Broken() { Leaks.object = this; Leaks.setter = this.assign; error('constructor failure'); }
    }
    class Dynamic {
        public __index(key) { coroutine.yield('index'); return key; }
        public __newindex(key, value) { coroutine.yield('newindex'); Leaks.dynamic = value; }
    }
}
]=]}, tHost);
local Classes = tHost.HybridContracts;
local a, b = Classes.Child(), Classes.Child();
check((rawtype or type)(a) == 'table', 'Public instances remain Lua tables');
check(next(a) == nil and getmetatable(a) == 'LXC opaque reference', 'Facade remains opaque');
check(a.read() == 3 and a.readChild() == 11 and b.read() == 3, 'Distinct inherited private storage');
local fRead, fAssign = a.read, a.assign;
check(fAssign == a.assign and fRead == a.read, 'Stable bound identities');
if (LUAEX_INIT) then
    reject(function() serialize(fAssign); end, 'compiled closures');
end
check(select('#', fAssign(20, 'ignored')) == 0 and fRead() == 20, 'Setter arguments/returns');
check(b.read() == 3 and a.readChild() == 11, 'Write isolation');
for _, vBad in ipairs({'wrong', false, {__type = 'number'}}) do
    reject(function() fAssign(vBad); end, 'Field type mismatch');
    check(fRead() == 20, 'Rejected write leaves captured getter unchanged');
end
reject(function() fAssign(); end, 'cannot be nil');
check(fRead() == 20, 'Missing argument leaves state unchanged');
a.assignChild(30);check(a.readChild() == 30 and fRead() == 20, 'Child setter selects child private slot');
reject(function() return a.value; end, 'private');
reject(function() a.value = 1; end, 'private');
check(a.Visible == 4 and a.Visible == 4, 'Public field cached lookup');
local fVisible = a.readVisible;
a.Visible = 12;check(fVisible() == 12, 'Facade write synchronizes Lua getter');
a.setVisible(14);check(a.Visible == 14 and fVisible() == 14, 'Native setter synchronizes facade and getter');
reject(function() a.Visible = 'wrong'; end, 'Field type mismatch');
check(a.Visible == 14 and fVisible() == 14, 'Rejected cached field write is atomic');
rawset(a, 'Visible', 100);
check(a.Visible == 100 and fVisible() == 14, 'Raw facade shadow preserves hidden storage');
a.Visible = 101;check(fVisible() == 14, 'Existing raw key bypasses checked assignment');
rawset(a, 'Visible', nil);check(a.Visible == 14, 'Removing raw shadow restores checked lookup');
a.Count = 16;check(a.Count == 16, 'Automatic property');
a.Custom = 17;check(a.Custom == 17 and Classes.Base.Total == 1, 'Custom property effects');
local function resume(tThread, ...)
    local tValues = table.pack(coroutine.resume(tThread, ...));
    check(tValues[1], tostring(tValues[2]));
    return table.unpack(tValues, 2, tValues.n);
end
local tGetter = coroutine.create(function() return a.Yielding; end);
check(resume(tGetter) == 'getter' and resume(tGetter) == 8, 'Yielding property getter');
local tSetter = coroutine.create(function() a.Yielding = 19;return 'set'; end);
check(resume(tSetter) == 'setter' and resume(tSetter) == 'set', 'Yielding property setter');
local tMethod = coroutine.create(function() return a.yieldMethod(22); end);
check(resume(tMethod) == 'method' and resume(tMethod) == 22, 'Yielding method preserves receiver');
local oDynamic = Classes.Dynamic();
local tIndex = coroutine.create(function() return oDynamic.missing; end);
check(resume(tIndex) == 'index' and resume(tIndex) == 'missing', 'Yielding dynamic index');
local tNewIndex = coroutine.create(function() oDynamic.missing = 23;return 'written'; end);
check(resume(tNewIndex) == 'newindex' and resume(tNewIndex) == 'written' and tHost.Leaks.dynamic == 23,
    'Yielding dynamic assignment');
reject(function() a.setFixed(8); end, 'const/final');
reject(function() a.setOnce(10); end, 'const/final');
check(a.Fixed == 7 and a.Once == 9, 'Locks preserved');
local x, y = a.complex(40);check(x == 40 and y == false and fRead() == 40, 'Complex setter retains body/results');
local tEcho = table.pack(a.echo(1, nil, 3));check(tEcho.n == 3 and tEcho[3] == 3, 'Variadic/multiple returns');
local fCallback = a.callback();check(fCallback(41) == 41 and fRead() == 41, 'Lexical callbacks');
local tShared = {self = a};a.setShared(tShared);check(a.Shared == tShared, 'Table setter fallback');
local oPending = Classes.Pending();local fPending = oPending.read;
check(fPending() == LXC.null, 'Untyped null');
oPending.assign(false);check(fPending() == false and oPending.Value == false, 'First false assignment');
oPending.assign(true);check(fPending() == true, 'Established boolean native assignment');
reject(function() oPending.assign(LXC.null); end, 'return to null');
local oString = Classes.Pending();oString.assign('first');local fString = oString.read;
oString.assign(string.rep('x', 4096));collectgarbage('collect');
check(#fString() == 4096, 'Strings remain GC-rooted in production slots');
local oCopy = LXC.clone(a);local fCopy = oCopy.read;
check(oCopy ~= a and fCopy() == 41 and oCopy.Shared.self == oCopy, 'Clone graph preserves identity/cycles');
oCopy.assign(50);check(fCopy() == 50 and fRead() == 41, 'Clone setter/getter storage isolation');
local oRestored = LXC.deserialize(LXC.serialize(a));local fRestored = oRestored.read;
check(fRestored() == 41 and oRestored.Shared.self == oRestored, 'Persistence graph round trip');
oRestored.assign(60);oRestored.Visible = 61;
check(fRestored() == 60 and oRestored.Visible == 61 and fRead() == 41, 'Restored native writes');
reject(function() Classes.Broken(); end, 'constructor failure');
reject(function() tHost.Leaks.setter(1); end, 'failed load or construction');
reject(function() return tHost.Leaks.object.assign; end, 'failed load or construction');
reject(function() LXC.loadSources({['HybridFailedBatch.lxc'] = [=[
namespace HybridFailedBatch {
    class Leaked {
        public Value = 0;
        public assign(value) { this.Value = value; }
        static Leaked() {
            local object = HybridFailedBatch.Leaked();
            Leaks.batchObject = object; Leaks.batchSetter = object.assign;
            local cached = object.Value;
            error('static failure');
        }
    }
}
]=]}, tHost); end, 'static failure');
reject(function() tHost.Leaks.batchSetter(2); end, 'failed load or construction');
reject(function() return tHost.Leaks.batchObject.Value; end, 'failed load or construction');
-- Allocation/GC exercises bound closure lifetimes without retaining instances.
for n = 1, 1000 do
    local oValue = Classes.Pending();oValue.assign(n);local fValue = oValue.read;
    oValue.assign(n + 1);check(fValue() == n + 1, 'Allocation getter synchronization');
end
collectgarbage('collect');
local fNativeSetter, bAvailable = Native.setter, Native.Available;
Native.setter = function() error('Application replacement must not receive private runtime state.'); end;
Native.Available = not bAvailable;
local oFrozen = Classes.Pending();oFrozen.assign(123);
check(oFrozen.read() == 123, 'Runtime captures native entry points before application replacement');
Native.setter, Native.Available = fNativeSetter, bAvailable;
print('PASS hybrid contracts: '..nChecks..' checks; native='..tostring(Native.Available));
