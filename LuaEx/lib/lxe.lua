--[[!
@fqxn LuaEx.LXE
@desc LXE loads immutable enum declarations from .lxe files and inline LXC
    declarations. LuaEx core supplies null, type hooks, and the generic serializer.
    Values remain canonical across clone/save/load. See docs/lxe/DESIGN.md.
@ret table Enum loading and lookup helpers.
!]]
assert(luaex and null ~= nil, "Initialize LuaEx core before requiring LXE.");
return require("LuaEx.lib.lxe.Loader").create(null, require("LuaEx.lib.serializer"));

