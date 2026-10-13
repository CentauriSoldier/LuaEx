local source=debug.getinfo(1,"S").source:gsub("^@","")
local directory=source:match("^(.*)[/\\]") or "."
package.path=directory.."/../../../?.lua;"..package.path
if not LUAEX_INIT then require("LuaEx.init") end
return require("examples.visual.AStar.fantasy")
