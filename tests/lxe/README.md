# LXE regression checks

Run from the LuaEx repository root with Lua 5.4:

    lua tests/lxe/regression.lua

The suite initializes LuaEx core, binds LXC, and uses source strings rather than
persistent .lxe/.lxc fixture files. This keeps application discovery from loading
the tests as declarations.

See ../../docs/lxe/DESIGN.md for the contract, integration details, and current
loading limits. Existing enum factory declarations have not been migrated.

For automatic startup, add application roots to package.path before invoking
require("LuaEx.load")(). For incremental standalone enums use lxe.loadSources or
lxe.loadFiles. For a coordinated class/enum batch use lxc.loadSources or
lxc.loadFiles; class-owned enum owners must be declared in that batch.

The suite also verifies static enum save/load through the host bridge, private
access, canonical type checks, and atomic rejection of invalid static updates.
Late enum attachment to an initialized class is intentionally rejected.
