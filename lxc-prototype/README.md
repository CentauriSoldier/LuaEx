# LXC prototype

A standalone Lua 5.4 class language/runtime with C#-guided access, inheritance and
polymorphism. Production code lives in `LuaEx/lxc`; this directory supplies its
forwarding loader, examples, tests, tools and documentation. Normal
`require('LuaEx.load')()` now installs LXC and discovers bundled/application
`.lxc` classes; old `class(...)` declarations are not compatible with its API.

Read DESIGN.md for behavior, KEYWORDS.md for vocabulary, ARCHITECTURE.md for the
file map/internal flow, and RULES.md before changing the project.

## Run

From the LuaEx repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\lxc-prototype\Run.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\lxc-prototype\Run.ps1 -Integration
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\lxc-prototype\Run.ps1 -Framework
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\lxc-prototype\Run.ps1 -Benchmark
```

The runner supports built-in Windows PowerShell and PowerShell 7 (`pwsh`).
It creates a fresh Lua state using an existing Lua 5.4 DLL. It does not
initialize wxLua or open windows. Supply -LuaDll to choose another compatible
DLL. With a working Lua 5.4 executable, run `lua test.lua` from this directory.
The current Windows runner also searches the CS machine's GitHub/wxLuma DLL path.
Lua 5.3 is unsupported: lexical-context protection uses Lua 5.4 frame-retention
syntax. -Integration initializes the existing LuaEx core for filesystem discovery.

## Load classes

For a guided introduction, run `Run.ps1 -Walkthrough` with the same PowerShell
invocation shown above. Read `walkthrough.lua` alongside its labeled OK/DENIED
output. It demonstrates constructor chaining (constructors do not override),
inheritance, visibility, method/property overrides, typed and const/final fields,
statics, equality, operators, iteration, cloning, save/load graphs and raw shadows.
It checks the displayed outcomes and writes no saved files.

```lua
local LXC = assert(loadfile('lxc-prototype/lxc.lua'))();
local environment = setmetatable({}, {__index = _G});

LXC.loadSources({['player.lxc'] = [[
namespace Game {
    class Player {
        private name = "Unknown";

        public Player(sName) {
            this.name = sName;
        }

        public getName() {
            return this.name;
        }
    }
}
]]}, environment);

local player = environment.Game.Player('Ada');
assert(player.getName() == 'Ada');
```

The example exposes normal host globals for convenience. For restricted scripts,
supply the intended bindings and withhold debug facilities. The runtime itself
boots with trusted standard libraries and captures its private dependencies.

Declarations use braces; method bodies and initializer expressions use Lua.
Methods omit Lua's outer function/end. Inner Lua blocks keep their normal syntax.
Methods are bound dot calls. Fields initialize with `= expression;`; an omitted
initializer leaves null. Namespace classes default to public; nested classes and
members default to private. Explicit constructors default to private. An omitted
constructor is generated with class visibility and an implied parameterless parent call.

## Implemented behavior

- Private/protected/public classes and members, nested types, same-class access to
  other instances, protected receiver restrictions and scope-aware helpers.
- Single inheritance, required compatible override, final classes/methods,
  abstract classes/methods, direct-child permits/excludes lists and ancestor calls.
- One constructor, base-first construction, field source order, one static
  constructor, dependency ordering and shared inherited static state.
- Runtime field types with descendant assignments, null placeholders, const
  bindings and final bindings locked on first non-null initialization.
- Automatic/custom properties, direct/named accessors, accessor visibility,
  configurable prefixes and shared original storage across property overrides.
- Using imports, requires dependencies, Lua lexical scoping, compile-time import
  ambiguity errors and declaration-aware source diagnostics.
- Versioned graph persistence, constructor-free restoration, cloning, separate
  static saves, transactional load publication and failed-reference invalidation.

Const/final protect table bindings; table contents remain mutable. Properties do
not add construction privileges or implicit locks. `base.method(...)` starts at
the declaring class's immediate parent. Explicit `base(...)` must be the first
constructor statement; omission implies a parameterless parent call.

## Public API

| API | Contract |
| --- | --- |
| loadSources(sources, environment) | Plain filename-to-source map; validate, initialize and publish a batch. Returns dependency-first qualified class names. |
| loadFiles(paths, environment) | Read explicit source paths and load a batch. |
| discover(packagePath) | Find .lxc sources through the optional LuaEx io.listfiles adapter; returns sorted paths. |
| class | Read-only scoped metadata/reference helpers listed below. |
| null | Placeholder distinct from nil; first non-null assignment establishes type. |
| serialize(value), deserialize(text) | Save/restore a supported graph without running constructors. |
| clone(value) | Independent mutable graph with concrete class identities preserved. |
| saveStatic(class), loadStatic(class, text) | Save/restore caller-accessible mutable static fields. |

| Class helper | Result |
| --- | --- |
| getname(value) | Qualified type name, including the exact type of a held instance; never a factory. |
| is(value), isinstance(value) | Whether a value is a class/instance identity. |
| exists(value) | Whether its resolved live class is accessible in the caller's scope. |
| getbyname(name) | Visible registered class reference, otherwise nil; nonstring input returns nil. |
| isinstanceof(object, classOrName) | Exact visible-class match. |
| isa(object, classOrName) | Visible base-or-descendant match. |
| ischild(child, parent) | Strict ancestry between visible classes; excludes self. |
| getparentname(value), getbasename(value) | Visible immediate-parent/root-ancestor name, otherwise nil. |
| getchildnames(value) | Fresh sorted names of visible direct children. |

Class bodies receive scoped class helpers and null. Persistence is deliberate host
authority and is not automatically injected. Instance snapshots contain private
state; supply codec access only to its intended recipients. Restoring a private-
class instance exposes permitted public behavior without yielding its class factory.
Saved class references still require using-scope visibility. Snapshots validate
storage contracts and locks; they are not authenticated proof of original values.

The standalone `LXC.serialize` codec rejects functions, resources, metatable-bearing/foreign typed tables and
nonfinite numbers fail explicitly. Snapshot input is limited to 16 MiB, fewer
than 256 literal nesting levels and 100,000 graph nodes. Constructors/initializers
are not rerun during restoration. Failed batches publish no new classes; external
side effects deliberately performed by initialization callbacks cannot be rolled back.

Normal LuaEx `serialize`/`deserialize` and `serializer.serialize`/`deserialize`
automatically use the existing trusted Lua-code serializer for LXC graphs
(`--LXC:3` tag). Application Lua callbacks retain bytecode, captured values, shared
upvalue cells and current `_ENV == _G` binding. Restored captures reconnect to
restored LXC identities. Private compiler/runtime closures remain rejected.
These host saves execute trusted Lua; they are not the standalone data-only format.
C functions, threads and userdata remain unsupported. Its additive staged API
allocates LXC shells before typed containers restore; arrays/LXC cycles and aliases
are covered. Cycles requiring other object factories to allocate shells still
reject. Older `--LXC:1`/`--LXC:2` saves remain readable. See COVERAGE.md for limits.

## Validation and measured performance

The native Lua 5.4 suite includes declaration contracts, persistence, loading,
access contexts, language behavior, operators, equality, stress/adversarial cases,
examples and independent-runtime isolation. Integration runs real LuaEx discovery
and the existing core's clone/codec/type bridge. See COVERAGE.md for requirement
mapping, current counts, stress dimensions and explicit limits. Debug intrusion
is excluded; the suite supplies evidence rather than exhaustive assurance.

A measured table-decoy run on the CS host produced approximately (CPU time):

| Operation | CPU microseconds per operation |
| --- | ---: |
| Cached method with typed state | 9.06 |
| Method lookup plus invocation | 9.72 |
| Public property read | 2.42 |
| Public property write | 3.42 |
| Construction | 22.00 |
| Clone | 13.00 |
| Serialization | 52.00 |
| Identity equality | 0.02 |
| Declared equality | 5.70 |

Results depend on host/workload. The benchmark uses 50,000 operations for hot paths
and 2,000 for construction/clone/serialization. Public access avoids caller inspection
only when lexical private-name lookup cannot affect the result; restricted paths
retain checks. Method argument/return types are not automatically checked at call time.

## Scope and host interaction

References are empty Lua table decoys backed by hidden state. A protected shared
metatable dispatches operations across independent LXC registries; foreign threads
are untouched. Native rawset can insert entries and shadow public lookup. Existing
raw keys also receive ordinary writes directly. Those entries do not read or
replace hidden slots, and clone/save use registered backing state. Removing a raw
entry restores checked lookup. API/helper/class decoys have the same raw-shadow
consequence. See DESIGN.md and tests/context.lua, equality.lua and stress.lua.
This is not a blanket raw-operation exemption. Runtime state and compiler views
remain private; unrestricted debug authority is outside enforcement.

Interfaces, automatic method argument/return checking,
abstract property contracts and Lua 5.3 compatibility are outside this build.
The separate future recursive table-lock utility is not implemented here. Existing
LuaEx framework integration is implemented and behavior-tested as recorded in COVERAGE.md.

Operator declarations support arithmetic, bitwise operations, ordering, indexing,
calls, tostring, pairs, close and gc. The clone, serialize and deserialize hooks
are tested; see DESIGN.md for their projection contract. Native == supports both
binary forms, inherited/overridden/final contracts and identity fallback. Lua
controls dispatch eligibility: identical tables skip __eq, and table-versus-number
equality does not call it. ~= negates equality. No native runtime dependency was
added. The C# host in Run.ps1 remains test infrastructure only.
