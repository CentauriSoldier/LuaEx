--[[!
@fqxn Experiments.LXC.DiscoveryIntegration
@desc Initializes only LuaEx core in this fresh process, then exercises real .lxc
    discovery and loading through existing filesystem hooks. No framework edits.
!]]
local pSource = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local pRoot = pSource:match("^(.*)/[^/]+$") or ".";
package.path = pRoot.."/../../?.lua;"..pRoot.."/../../?/init.lua;"..package.path;
require("LuaEx.load")(0);

local LXC = assert(loadfile(pRoot.."/lxc.lua"))();
local tFiles = LXC.discover(pRoot.."/examples/?.lua;"..pRoot.."/examples/?/init.lua");
assert(#tFiles == 2, "Expected exactly two discovered .lxc examples.");
local tEnvironment = setmetatable({}, {__index = _G});
local tOrder = LXC.loadFiles(tFiles, tEnvironment);
assert(tOrder[1] == "Demo.Characters.Creature", "Discovered parent must load first.");
assert(tEnvironment.Demo.Characters.Player("James").describe() == "James: 100", "Discovered classes must execute.");
print("LXC discovery integration: 3 checks passed using real LuaEx io.listfiles.");
