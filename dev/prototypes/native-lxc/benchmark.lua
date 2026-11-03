-- Same real .lxc fixture and current compiler for both execution backends.
local source = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local here = assert(source:match("^(.*)/[^/]+$"));
local root = source:match("^(.*)dev/prototypes/native%-lxc/benchmark%.lua$");
if (root == "") then root = "./"; end
package.path = assert(root).."?.lua;"..package.path;
require("LuaEx.init");
local Bridge = assert(loadfile(here.."/bridge.lua"))();
local fixture = here.."/Counter.lxc";
local host = setmetatable({}, {__index = _G});
local LuaCounter = class.getbyname("NativePrototype.Counter");
if (not LuaCounter) then
    lxc.loadFiles({fixture}, host);
    LuaCounter = host.NativePrototype.Counter;
end
local NativeCounter = Bridge.loadFile(fixture, host);
local GenericCounter = Bridge.loadFile(fixture, host, {directSetters = false});

local function measure(label, count, work)
    work();
    local times = {};
    for sample = 1, 3 do
        collectgarbage("collect");
        local started, elapsed, repeats = os.clock(), 0, 0;
        repeat
            work();repeats = repeats + 1;elapsed = os.clock() - started;
        until (elapsed >= 0.05);
        times[sample] = elapsed / repeats;
    end
    table.sort(times);
    local seconds = times[2];
    print(string.format("RESULT\t%s\t%d\t%.6f\t%.0f", label, count, seconds, count / seconds));
end

print("BACKENDS production Lua, generic native and direct-setter native; same Counter.lxc input");
print("CLOCK os.clock CPU time, warmup + median of three samples, >=50ms/sample");
local backends = {{Name = "lua", Class = LuaCounter}, {Name = "native-generic", Class = GenericCounter}, {Name = "native", Class = NativeCounter}};
if (arg and arg[1] == "--native-first") then backends[1], backends[3] = backends[3], backends[1]; end
for _, backend in ipairs(backends) do
    local Counter = backend.Class;
    local object = Counter(1);
    local count = 200000;
    local read, assign, increment = object.read, object.assign, object.increment;
    measure(backend.Name.."/method-read", count, function()
        local expected, total = read(), 0;
        for index = 1, count do total = total + object.read(); end
        assert(total == count * expected);
    end);
    measure(backend.Name.."/prebound-read", count, function()
        local expected, total = read(), 0;
        for index = 1, count do total = total + read(); end
        assert(total == count * expected);
    end);
    measure(backend.Name.."/typed-write", count, function()
        for index = 1, count do assign(index); end
        assert(read() == count);
    end);
    measure(backend.Name.."/increment", count, function()
        local before = read();
        for index = 1, count do increment(); end
        assert(read() == before + count);
    end);
    measure(backend.Name.."/field-read-loop", count, function()
        assert(object.sum(count) == read() * count);
    end);
    measure(backend.Name.."/public-field-read", count, function()
        local total = 0;
        for index = 1, count do total = total + #object.Label; end
        assert(total == 7 * count);
    end);
    measure(backend.Name.."/public-field-write", count, function()
        for index = 1, count do object.Enabled = index % 2 == 0; end
        assert(object.Enabled == true);
    end);
    measure(backend.Name.."/construct", 2000, function()
        local total = 0;
        for index = 1, 2000 do total = total + Counter(index).read(); end
        assert(total == 2000 * 2001 / 2);
    end);
end
print("PASS native/Lua workload results verified. Rates apply only to each named workload.");
