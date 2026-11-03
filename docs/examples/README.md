# LuaEx examples

Open [Examples.html](../Examples.html) directly in a browser. Its 16 tutorials and local Lua 5.4 / Wasmoon runtime are bundled for offline use. No upload or filesystem permission is needed. Browser writes stay in memory.

Arrays, enums, structs, Eventrix, collections, Potentiometer, Protean, point/line primitives, INI, QR codes, text catalogs, and VFS.

The Visual tab uses the real framework objects. The Code tab is independently editable and starts a fresh environment on Run. Supporting Lua and LXC fixtures live under this folder; the code files use support/bootstrap.lua to locate dependencies before declaration discovery.

## Native Lua

Keep the LuaEx and this checkouts as sibling directories. With Lua 5.4+ and its matching LuaEx native I/O library available, run a tutorial from this repository root, for example:

```text
lua docs/examples/code/collections/Queue.lua
```

Native tutorial writes use docs/examples/resources. Unlike browser writes, these are real files. The examples supply math.atan2 = math.atan before initialization because the current line primitive captures the older name. Framework sources are unchanged.

## Rebuild and verify

From this repository root, with Node available:

```text
node docs/examples/api/workbench/verify.cjs
node docs/examples/api/workbench/bundle.cjs
```

The builder reads the current sibling LuaEx sources and embeds them locally. The generated payload does not depend on sibling paths when the page is opened. catalog.json owns this repo’s tutorial list; manifest.json and bundle.js are generated. verification.json records actual source, independent-code, and visual startup results.

The optional Open Examples.cmd starts a loopback-only server and opens the page. Node is needed only for development or this optional launcher. [Runtime licenses](api/README.md) are retained beside Wasmoon.
