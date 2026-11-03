-- Run only in the extracted historical checkout, in a separate Lua process.
local fixture = assert(arg[1], "Current native benchmark path required");
require("LuaEx.load")(1);
local Counter = class("LegacyBenchmarkCounter", {}, {},
{value = 0}, {}, {
    Label = "counter",
    Enabled = false,
    LegacyBenchmarkCounter = function(this, cdat, initial) cdat.pri.value = initial; end,
    read = function(this, cdat) return cdat.pri.value; end,
    assign = function(this, cdat, value) cdat.pri.value = value; end,
    increment = function(this, cdat)
        cdat.pri.value = cdat.pri.value + 1;
        return cdat.pri.value;
    end,
    sum = function(this, cdat, count)
        local total = 0;
        for index = 1, count do total = total + cdat.pri.value; end
        return total;
    end,
}, nil, false);
local a, b = Counter(7), Counter(8);
assert(a.read() == 7 and b.read() == 8);
local ok = pcall(function() a.assign("wrong"); end);
assert(not ok and a.read() == 7, "Legacy primitive typing must reject invalid writes");
local file = assert(io.open(fixture, "rb"));
local text = file:read("*a");file:close();
-- Share the exact measurement routine and workload bodies with current backends.
local measure = assert(text:match('(local function measure.-)print%("BACKENDS'));
local workloads = assert(text:match('(for _, backend in ipairs%(backends%) do.*)'));
local environment = setmetatable({backends = {{Name = "legacy", Class = Counter}}}, {__index = _G});
assert(load(measure..workloads, "legacy shared workloads", "t", environment))();
print("PASS legacy independent storage and invalid typed-write checks");
