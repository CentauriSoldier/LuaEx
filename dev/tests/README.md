# LuaEx regression tests

Run from the LuaEx repository root with native Lua 5.4+ on PATH:

```text
lua tests/run.lua
lua tests/run.lua --list
lua tests/run.lua --suite collections
```

Every suite runs in a fresh interpreter. Failures, missing configured files and
failed processes return a nonzero exit status. Use `--lua PATH` to choose another
interpreter. Native I/O binaries must match its Lua ABI; bundled `lua54` binaries
are for Lua 5.4. Windows Lua 5.4.2 has been verified; other host/runtime combinations
need their own validation.

The suite covers direct `require("LuaEx.init")` initialization, discovery,
collections, class access, Eventrix, native I/O, metatable hooks, geometry
primitives, strings, XML, formatting, serialization, VFS, directives and enums.
Load levels and the separate initialization function no longer exist.

`bootstrap.lua` initializes LuaEx, maps repository source reads, supplies the
`/xml-test.tmx` fixture in memory and rejects unmocked filesystem writes.
VFS uses its own in-memory backend. The native I/O and discovery suites create
and clean up temporary filesystem fixtures; shell/process helpers are disabled
inside their filesystem-operation checks.

The formatter's maintained Lua source list is inside `prettylua_regression.lua`.
It checks syntax, executable tokens and idempotence without executing formatted
sources. Retired class/interface modules are not part of that corpus.

The enum checks and their notes are under `lxe/`. All other current checks live
in this directory. Old browser runners and tests for modules outside LuaEx have
been removed. CoG and Dox belong to their respective projects and are not covered
by this runner. Editor tooling has its own tests under `tools/pulsar/luaex-tools`.

## Serialization boundaries

The serializer checks cover shared references, plain-table cycles, Lua closures
and registered typed objects. Saved data is executable Lua and must be trusted;
bytecode requires a compatible runtime. Native C functions and threads cannot
be serialized. Tree parent/child cycles and unfinished legacy instance
persistence methods remain outside a claim of full release readiness.
