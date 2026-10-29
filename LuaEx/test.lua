--[[!
@fqxn LuaEx.Test
@desc Playground driver for Creature.lxc, Human.lxc and Soldier.lxc. Initializes
    LuaEx and leaves Creature, Human and Soldier available for your own code below.
    Methods use bound dot calls. Run in a fresh Lua 5.4 session after class edits.
!]]
local _pSource       = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local _pDirectory    = _pSource:match("^(.*)/[^/]+$") or ".";
local _sPackagePath  = package.path;

package.path = _pDirectory.."/../?.lua;".._pDirectory.."/../?/init.lua;"..package.path;
require("LuaEx.load")();
package.path = _sPackagePath;

-- Normal initialization discovers these files. If LuaEx was already initialized,
-- load only definitions that are still missing, together in dependency order.
local _tPaths = {};
for _, sName in ipairs({"Creature", "Human", "Soldier"}) do
    if (not class.exists("Playground."..sName)) then
        _tPaths[#_tPaths + 1] = _pDirectory.."/"..sName..".lxc";
    end
end
if (#_tPaths > 0) then lxc.loadFiles(_tPaths, _G); end

local _tClasses = Playground;
for _, sName in ipairs({"Creature", "Human", "Soldier"}) do
    assert(rawget(_G, sName) == nil or rawequal(rawget(_G, sName), _tClasses[sName]),
        sName.." already belongs to another binding.");
end
Creature = _tClasses.Creature;
Human    = _tClasses.Human;
Soldier  = _tClasses.Soldier;
Bob = Soldier("Bob");
Ed = Soldier("Ed");

-- Add your playground code here.
print(Bob.getAge())
print(Bob.HitPoints)

Ed.attack(Bob);
print(Bob.HitPoints)
Ed.setAttackPower(40)
Ed.attack(Bob);
print(Bob.HitPoints)
