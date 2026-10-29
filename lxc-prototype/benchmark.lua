--[[!
@fqxn LXC.Benchmark
@desc Reproducible Lua 5.4 CPU-time measurements; correctness belongs to tests.
    Results are host/runtime dependent and do not establish a universal speed claim.
!]]
local pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
local pRoot = pSource:match('^(.*)/[^/]+$') or '.';
local LXC = assert(loadfile(pRoot..'/lxc.lua'))();
local tEnvironment = setmetatable({}, {__index = _G});
LXC.loadSources({['benchmark.lxc'] = [[namespace Bench {
    class Counter {
        private count=0;
        public Count { get; set; }=0;
        public Counter() {}
        public increment() { this.count=this.count+1; return this.count; }
        public read() { return this.count; }
        public operator ==(other) { return this.count==other.count; }
    }
}]]}, tEnvironment);
local Counter = tEnvironment.Bench.Counter;
local oObject = Counter();
local fIncrement = oObject.increment;
local oEqual = Counter();
local nIterations = 50000;

--[[!
@fqxn LXC.Benchmark.measure
@desc Times a warmed operation loop and prints CPU seconds and microseconds/op.
!]]
local function measure(sName, nCount, fOperation)
    collectgarbage('collect');
    for _ = 1, 100 do fOperation(); end
    local nStart = os.clock();
    for _ = 1, nCount do fOperation(); end
    local nElapsed = os.clock() - nStart;
    print(string.format('%-28s %8.4f s  %8.3f us/op  (%d operations)',
        sName, nElapsed, nElapsed * 1000000 / nCount, nCount));
end

measure('cached method + typed state', nIterations, function() fIncrement(); end);
measure('method lookup + invocation', nIterations, function() oObject.increment(); end);
measure('property read', nIterations, function() return oObject.Count; end);
measure('property write', nIterations, function() oObject.Count=1; end);
measure('construction', 2000, function() Counter(); end);
measure('clone', 2000, function() LXC.clone(oObject); end);
measure('serialization', 2000, function() LXC.serialize(oObject); end);
measure('identity equality', nIterations, function() return oObject==oObject; end);
measure('declared equality', nIterations, function() return oObject==oEqual; end);
assert(oObject.read() >= nIterations * 2, 'Benchmark methods must execute.');
