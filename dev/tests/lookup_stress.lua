--[[!
@fqxn Tests.LookupStress
@desc Measures native Lua class/global/member access as the registry grows.
    Assertions validate every workload. Run lua dev/tests/lookup_stress.lua;
    add --astar for the separate CoG navigation workload. Timings use os.clock.
!]]
local pSource = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local pRoot = assert(pSource:match("^(.*)dev/tests/lookup_stress%.lua$"));
local bAStar = arg and arg[1] == "--astar";
package.path = pRoot.."?.lua;"..package.path;
if (bAStar) then
    package.path = pRoot.."../CoG/?.lua;"..pRoot.."../CoG/docs/?.lua;"..package.path;
end
require("LuaEx.init");

--[[!
@fqxn Tests.LookupStress.measure
@desc Reports the median of three CPU-time samples after one untimed warmup.
    Each sample repeats work for at least 50 ms, then normalizes to one batch,
    avoiding zero-duration results for plain Lua at the host clock's resolution.
    Workloads assert their result inside the measured function.
@param string sLabel Workload and registry size.
@param number nOperations Number of logical operations in each sample.
@param function fWork Workload closure.
!]]
local function measure(sLabel, nOperations, fWork)
    fWork();
    local tTimes = {};
    for nSample = 1, 3 do
        collectgarbage("collect");
        local nStart = os.clock();
        local nRepeats, nElapsed = 0, 0;
        repeat
            fWork();
            nRepeats = nRepeats + 1;
            nElapsed = os.clock() - nStart;
        until (nElapsed >= 0.05);
        tTimes[nSample] = nElapsed / nRepeats;
    end
    table.sort(tTimes);
    local nSeconds = tTimes[2];
    print(string.format("RESULT\t%s\t%d\t%.6f\t%.0f", sLabel, nOperations,
        nSeconds, nOperations / math.max(nSeconds, 0.000001)));
end

if (bAStar) then
    require("cog.load")();
    local Model = require("examples.visual.AStar.model");
    local nStart = os.clock();
    local demo = Model.new();
    print(string.format("RESULT\tastar/map-20x14-two-rovers\t1\t%.6f", os.clock() - nStart));

    -- Reuse the same live map and rover budgets. Planning must not spend points.
    local nBudget = demo.group[1].getMovePoints();
    for _, tGoal in ipairs({{19, 12}, {10, 8}, {19, 7}}) do
        demo.goal = {x = tGoal[1], y = tGoal[2]};
        measure("astar/target-"..tGoal[1].."-"..tGoal[2], 1, function()
            -- Force a fresh solve: target() intentionally ignores an unchanged
            -- goal, which would otherwise benchmark that no-op after warmup.
            demo.plan();
            assert(demo.group[1].getMovePoints() == nBudget, "Planning spent movement points.");
        end);
        local tCoordinates = {};
        for _, oNode in ipairs(demo.path.getNodes()) do
            tCoordinates[#tCoordinates + 1] = oNode.getX()..","..oNode.getY();
        end
        print("ROUTE\t"..tGoal[1]..","..tGoal[2].."\t"..tostring(demo.path.hasPath())..
            "\t"..demo.path.getCost(demo.group[1]).."\t"..table.concat(tCoordinates, ";"));
    end
    return;
end

local tHost = setmetatable({StressHostValue = 3}, {__index = _G});
lxc.loadSources({["LookupStress.lxc"] = [[
    namespace LookupStress {
        class Probe {
            private value = 0;
            public static globals(nCount) {
                local nTotal = 0;
                for nIndex = 1, nCount do nTotal = nTotal + StressHostValue; end
                return nTotal;
            }
            public static classes(nCount) {
                local cResult;
                for nIndex = 1, nCount do cResult = Probe; end
                return cResult;
            }
            public read() { return this.value; }
            public increment() { this.value = this.value + 1; return this.value; }
            public echo(nValue) { return nValue; }
            public assign(nValue) { this.value = nValue; }
            public sum(nCount) {
                local nTotal = 0;
                for nIndex = 1, nCount do nTotal = nTotal + this.value; end
                return nTotal;
            }
        }
    }
]]}, tHost);

local Probe = tHost.LookupStress.Probe;
local oProbe = Probe();
local nCalls = 20000;
local nDeclared = 0;

for _, nSize in ipairs({0, 100, 1000}) do
    if (nSize > nDeclared) then
        local tDeclarations = {"namespace LookupStress.Filler {"};
        for nIndex = nDeclared + 1, nSize do
            tDeclarations[#tDeclarations + 1] = "class C"..nIndex.." {}";
        end
        tDeclarations[#tDeclarations + 1] = "}";
        lxc.loadSources({["LookupStressFiller"..nSize..".lxc"] = table.concat(tDeclarations, "\n")}, tHost);
        nDeclared = nSize;
    end

    local sSuffix = "/"..nSize.."-extra-classes";
    measure("host-global"..sSuffix, nCalls, function()
        assert(Probe.globals(nCalls) == nCalls * 3);
    end);
    measure("class-name"..sSuffix, nCalls, function()
        assert(rawequal(Probe.classes(nCalls), Probe));
    end);
    measure("method-read"..sSuffix, nCalls, function()
        local nExpected = oProbe.read();
        local nTotal = 0;
        for nIndex = 1, nCalls do nTotal = nTotal + oProbe.read(); end
        assert(nTotal == nCalls * nExpected);
    end);
    measure("method-write"..sSuffix, nCalls, function()
        local nBefore = oProbe.read();
        for nIndex = 1, nCalls do oProbe.increment(); end
        assert(oProbe.read() == nBefore + nCalls);
    end);
    collectgarbage("collect");
    print(string.format("MEMORY\t%d-extra-classes\t%.1f", nSize, collectgarbage("count")));
end
print("PASS native Lua lookup stress: all workload results verified.");

-- Compare valid-operation behavior with ordinary Lua closures. The plain Lua
-- control intentionally provides no class access/type/persistence machinery.
local nPlainValue = oProbe.read();
local tPlain = {};
tPlain.read = function() return nPlainValue; end;
tPlain.increment = function() nPlainValue = nPlainValue + 1; return nPlainValue; end;
local nCompare = 200000;
measure("plain/method-read", nCompare, function()
    local nExpected, nTotal = tPlain.read(), 0;
    for nIndex = 1, nCompare do nTotal = nTotal + tPlain.read(); end
    assert(nTotal == nExpected * nCompare);
end);
measure("class/method-read", nCompare, function()
    local nExpected, nTotal = oProbe.read(), 0;
    for nIndex = 1, nCompare do nTotal = nTotal + oProbe.read(); end
    assert(nTotal == nExpected * nCompare);
end);
local fPlainRead = tPlain.read;
local fClassRead = oProbe.read;
measure("plain/prebound-read", nCompare, function()
    local nExpected, nTotal = fPlainRead(), 0;
    for nIndex = 1, nCompare do nTotal = nTotal + fPlainRead(); end
    assert(nTotal == nExpected * nCompare);
end);
measure("class/prebound-read", nCompare, function()
    local nExpected, nTotal = fClassRead(), 0;
    for nIndex = 1, nCompare do nTotal = nTotal + fClassRead(); end
    assert(nTotal == nExpected * nCompare);
end);
local fEcho = oProbe.echo;
local fAssign = oProbe.assign;
measure("class/prebound-dispatch", nCompare, function()
    local nTotal = 0;
    for nIndex = 1, nCompare do nTotal = nTotal + fEcho(1); end
    assert(nTotal == nCompare);
end);
measure("class/prebound-typed-write", nCompare, function()
    for nIndex = 1, nCompare do fAssign(nIndex); end
    assert(fClassRead() == nCompare);
end);
measure("plain/field-read-loop", nCompare, function()
    local nTotal = 0;
    for nIndex = 1, nCompare do nTotal = nTotal + nPlainValue; end
    assert(nTotal == nPlainValue * nCompare);
end);
measure("class/field-read-loop", nCompare, function()
    assert(oProbe.sum(nCompare) == oProbe.read() * nCompare);
end);
