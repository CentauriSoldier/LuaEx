--[[!
@fqxn LXC.Prototype
@desc Development/test entry forwarding to the production runtime in LuaEx/lxc.
    Tests and examples stay in this directory; runtime implementation lives once.
!]]
local _pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
local _pRoot = _pSource:match('^(.*)/[^/]+$') or '.';
return assert(loadfile(_pRoot..'/../LuaEx/lxc/init.lua'))();
