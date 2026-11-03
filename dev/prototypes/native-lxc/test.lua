-- Tests the isolated backend, never installs it into LuaEx.
local source = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local here = assert(source:match("^(.*)/[^/]+$"));
local Bridge = assert(loadfile(here.."/bridge.lua"))();
local checks = 0;
local function check(value, message) assert(value, message); checks = checks + 1; end
local function reject(action, fragment)
    local ok, err = pcall(action);
    check(not ok and (not fragment or tostring(err):find(fragment, 1, true)), tostring(err));
end
local Counter = Bridge.loadFile(here.."/Counter.lxc");
local a, b = Counter(7), Counter(8);
check(a.read() == 7 and b.read() == 8, "Constructor and independent scalar storage");
local get = a.read;
check(get == a.read, "Stable bound method identity");
a.assign(11);check(get() == 11, "Captured getter observes writes");
check(a.increment() == 12 and get() == 12, "General read/write method");
check(a.sum(5) == 60 and a.echo(false) == false, "Compiled loop and arguments");
local x, y, z = a.multiple(nil, false, 7);
check(x == nil and y == false and z == 7, "Variadic nil and multiple returns");
check(a.otherRead(b) == 8, "Same-class lexical private read on another instance");
reject(function() return a.value; end, "private");
reject(function() a.value = 99; end, "private");
reject(function() a.assign("bad"); end, "type");
check(get() == 12, "Rejected write leaves getter unchanged");
reject(function() a.assign(nil); end, "only numbers");
reject(function() a.assign(setmetatable({}, {__type = "number"})); end, "only numbers");
check(get() == 12, "Spoofed numeric metadata grants no write");
for _, number in ipairs({1.5, -42, math.maxinteger, 0/0, math.huge}) do
    a.assign(number);local value = get();
    check(number ~= number and value ~= value or value == number, "Number representation retained");
end
local callback = a.callback();a.assign(19);check(callback() == 19, "Authored closure retains lexical reads");
a.Label = "a\0b";a.Enabled = true;
check(a.Label == "a\0b" and a.Enabled == true and b.Label == "counter", "String roots, booleans and per-instance data");
reject(function() a.Label = false; end, "type");
reject(function() a.Enabled = 1; end, "type");
reject(function() a.read = function() end; end, "immutable");
reject(function() rawset(a, "value", 100); end);
reject(function() setmetatable(a, {}); end);
check(getmetatable(a) == "locked native prototype", "Metatable is opaque");
local Other = Bridge.loadSource([[namespace Other { class Counter {
    private value = 5;
    public Counter() {}
} }]], "Other.lxc");
reject(function() a.otherRead(Other()); end, "Foreign receiver");
local leaked, escaped;
local Failure = Bridge.loadSource([[namespace Failure { class Item {
    private value = 0;
    public Item() { capture(this, this.read); this.value = "invalid"; }
    public read() { return this.value; }
} }]], "Failure.lxc", setmetatable({capture = function(object, getter) leaked, escaped = object, getter; end}, {__index = _G}));
reject(function() Failure(); end, "type");
check(leaked ~= nil and escaped ~= nil, "Constructor leak fixture executed");
reject(escaped, "failed");
reject(function() return leaked.read; end, "failed");
reject(function() leaked.Enabled = true; end, "failed");

for _, text in ipairs({
    "namespace Rejected { class A {} class B : A {} }",
    "namespace Rejected { class A { public Value { get; set; } = 0; } }",
    "namespace Rejected { class A { private helper() {} } }",
    "namespace Rejected { class A { public static Value = 1; } }",
    "namespace Rejected { class A { public const Value = 1; } }",
    "namespace Rejected { class A { public Value = {}; } }",
    "namespace Rejected { class A { ---@type number\n public Value = 1; } }",
    "namespace Rejected { enum E { A; } class A {} }",
}) do reject(function() Bridge.loadSource(text, "Unsupported.lxc"); end, "Prototype"); end
reject(function() Bridge.loadSource("namespace Bad { class A { public = ; } }", "Malformed.lxc"); end);

local native = assert(package.loadlib(assert(os.getenv("LXC_NATIVE_MODULE")), "luaopen_lxc_native"))();
reject(function() native.scope(Counter, {}); end);
local description = {count = 1, fields = {Value = {slot = 500000, public = true}}, methods = {}, initializers = {function() return 1; end}};
local Unsafe, authority = native.define(description);native.seal(authority);
local unsafe = Unsafe();
reject(function() unsafe.Value = 9; end, "Invalid native field slot");
reject(function() return unsafe.Value; end, "Invalid native field slot");
native.invalidate(authority);
reject(function() Unsafe(); end, "unavailable");
reject(function() return unsafe.Value; end, "failed");

-- Run the same source with direct setters enabled and disabled. Bodies with
-- additional work must retain their ordinary compiled behavior.
local setterSource = [[namespace SetterChecks {
    class Item {
        private value = 0;
        private text = "";
        private enabled = false;
        public Item() {}
        public read() { return this.value; }
        public label() { return this.text; }
        public state() { return this.enabled; }
        public assign(value) { -- comments are not executable work
            this.value = value;
        }
        public setText(value) { this.text = value }
        public setFlag(value) { this.enabled = value; }
        public sideEffect(value) { this.value = value; notify(); }
        public expression(value) { this.value = value + 1; }
        public returns(value) { this.value = value; return true; }
        public second(unused, value) { this.value = value; }
        public variadic(value, ...) { this.value = value; return ...; }
    }
}]];
for _, direct in ipairs({true, false}) do
    local notifications = 0;
    local Class = Bridge.loadSource(setterSource, "SetterChecks.lxc",
        setmetatable({notify = function() notifications = notifications + 1; end}, {__index = _G}),
        {directSetters = direct});
    local object = Class();local assign = object.assign;
    check(assign == object.assign and select("#", assign(3, "extra")) == 0, "Stable setter and nil-return/extra-argument semantics");
    check(object.read() == 3, "Setter commits selected field");
    reject(function() assign(); end, "only numbers");
    reject(function() assign(nil); end, "only numbers");
    reject(function() assign("3"); end, "type");
    reject(function() assign(setmetatable({}, {__type = "number"})); end, "only numbers");
    check(object.read() == 3, "All rejected setters leave storage unchanged");
    object.setText("binary\0text");object.setFlag(false);
    collectgarbage("collect");
    check(object.label() == "binary\0text" and object.state() == false, "String roots and false are retained by direct writes");
    object.setFlag(true);check(object.state() == true, "Boolean true write");
    reject(function() object.setText(1); end, "type");
    reject(function() object.setFlag(0); end, "type");
    object.sideEffect(4);check(notifications == 1 and object.read() == 4, "Additional statements are not discarded");
    object.expression(5);check(object.read() == 6, "Expression assignment is not misclassified");
    check(object.returns(7) == true and object.read() == 7, "Explicit return is preserved");
    object.second(0, 8);check(object.read() == 8, "Second-parameter source remains compiled");
    local first, second = object.variadic(9, nil, false);
    check(first == nil and second == false and object.read() == 9, "Variadic return behavior remains compiled");
    reject(function() return object.value; end, "private");
end

local escapedSetter;
local SetterFailure = Bridge.loadSource([[namespace SetterFailure { class Item {
    private value = 0;
    public Item() { retain(this.assign); error("constructor failed"); }
    public assign(value) { this.value = value; }
} }]], "SetterFailure.lxc", setmetatable({retain = function(fn) escapedSetter = fn; end}, {__index = _G}));
reject(function() SetterFailure(); end, "constructor failed");
check(escapedSetter ~= nil, "Constructor retained the setter fixture");
reject(function() escapedSetter(1); end, "failed");

local OwnClass, token = native.define({count = 1, fields = {},
    methods = {assign = {setter = 1}, invalid = {setter = 500000}}, initializers = {function() return 0; end}});
native.seal(token);local owned = OwnClass();local boundSetter = owned.assign;
boundSetter(1);reject(function() owned.invalid(1); end, "Invalid native field slot");
native.invalidate(token);reject(function() boundSetter(2); end, "failed");

-- Stress allocation, GC and closure roots; do not count loop iterations as assertions.
for index = 1, 10000 do local value = Counter(index);assert(value.read() == index, "Allocation state");end
collectgarbage("collect");check(get() == 19 and b.read() == 8, "Live objects and getters survive collection");
print("PASS native prototype: "..checks.." functional checks plus 10,000 checked allocations; existing parser/model/compiler and C backend.");
