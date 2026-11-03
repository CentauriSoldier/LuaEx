-- Run in a fresh process. LXC_NATIVE_BACKEND=lua selects the production Lua control.
local pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
local pHere = assert(pSource:match('^(.*)/[^/]+$'));
local pRoot = assert(pSource:match('^(.*)dev/prototypes/native%-lxc/hybrid%-benchmark%.lua$'));
package.path = pRoot..'?.lua;'..package.path;
require('LuaEx.init');
local Native = require('LuaEx.lib.lxc.Native');
local sBackend = Native.Available and 'hybrid' or 'lua';
if (os.getenv('LXC_NATIVE_BACKEND') ~= 'lua') then assert(Native.Available, Native.Reason); end
local Counter = assert(class.getbyname('NativePrototype.Counter'));
local tFile = assert(io.open(pHere..'/benchmark.lua', 'rb'));
local sText = tFile:read('*a');tFile:close();
local sMeasure = assert(sText:match('(local function measure.-)print%("BACKENDS'));
local sWorkloads = assert(sText:match('(for _, backend in ipairs%(backends%) do.*)'));
local tEnvironment = setmetatable({backends = {{Name = sBackend, Class = Counter}}}, {__index = _G});
assert(load(sMeasure..sWorkloads, 'shared hybrid workloads', 't', tEnvironment))();
