# Current core regression tests

Run from the repository root with native Lua on PATH:

```text
lua tests/run.lua
```

The runner starts a fresh interpreter for every configured suite and loader level.
Any failed test, missing core test or failed process returns a nonzero exit status.
It preserves native C functions such as `print`, which are important to the
serializer's rejection tests. Use `--lua PATH` for another interpreter,
`--list` to inspect coverage, or `--suite collections` to select one case.

The configured checks cover loader levels 0–5 and invalid options, collections,
class-reference access, Eventrix, filesystem listing behavior, metatable hooks,
geometry primitives, strings, XML, formatting, serialization and VFS.

`bootstrap.lua` supplies setup for tests originally written for the browser VM.
It maps repository source reads, supplies the `/xml-test.tmx` fixture in memory,
and rejects unmocked native filesystem writes. VFS uses its separate in-memory
backend. This does not validate actual host filesystem permissions or commands.

`prettylua_corpus.lua` lists the source corpus used for formatting checks.
`LuaEx/notes.lua` is excluded because it contains non-executable scratch notes;
it is not a runtime module. Update the corpus list when adding source files.

## Verified compatibility

- Native Lua 5.4.2 on Windows.
- Bundled Lua 5.4 / Wasmoon 1.16.0 for the browser checks exercised separately.
- Lua 5.3 and Linux/macOS native execution have not completed this suite.
- Lua 5.1 and LuaJIT compatibility are not claimed: the current source uses Lua
  5.3 syntax and APIs. A passing Windows run does not establish other-host support.

## Serialization contract

The current graph serializer preserves supported primitive values, repeated table
references, plain-table cycles, Lua closure upvalues and registered typed objects.
Class factory references retain identity through registered restoration bindings;
public metadata lookup restrictions do not revoke supported saved references.
Factories and named Eventrix environments must be available in the loading runtime.
Independent loads create independent mutable object/closure state.

Serialized data is executable Lua and must be trusted. Lua bytecode requires a
compatible runtime. Native C functions, threads, userdata and cycles passing
through typed-object serialization hooks are rejected explicitly. There is no
promise of arbitrary cross-version bytecode compatibility or silent data omission.

## Coverage and remaining release blockers

CoG, inventory, cards, mods, vehicles, status tracking, Tiled and Dox implementations
are absent from this checkout. Their historical tests and documentation remain;
the core runner reports these exclusions rather than counting them as passing.

A Tree with children currently forms a typed-object cycle through its parent
links and cannot round-trip. That needs a separate persistence design. Legacy
instance `serialize`/`deserialize` methods on some collections also contain
unfinished stubs; use the verified global `serialize(object)` and
`deserialize(saved)` path. These unresolved issues prevent treating a passing
core run as a declaration that LuaEx is ready for 1.0.
