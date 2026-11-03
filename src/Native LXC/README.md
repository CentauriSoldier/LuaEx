# Native LXC acceleration

This optional Lua 5.4 module accelerates the existing production class runtime.
It does not replace the parser, compiler, class registry, enum runtime or graph
services. Public objects remain empty Lua table facades, with their existing
shared protected metatable and raw-key shadowing behavior. All stored values,
type contracts and locks remain in the original private Lua slot records.

## Execution paths

- Simple public instance methods whose entire body assigns their sole parameter
  to a mutable instance field can bind a C setter. The normal compiler still
  compiles the complete body first and resolves lexical access. Properties,
  static fields, const/final fields, variadic methods, expressions and additional
  statements retain their existing compiled bodies. Binding before allocation
  retains the ordinary method path.
- C writes accelerate only assignments matching an established number, string
  or boolean contract on an unlocked mutable slot. All other cases use the
  original Lua writer, including null/first assignments, class and enum identity,
  ancestry, table values, nil and rejected assignments. Getter updaters run after
  committing a successful write, matching the original writer's order.
- C index/newindex metamethods use the existing private facade-handler map.
  Only successful unambiguous public instance-field/method selections are cached.
  Field caches contain declaration identities, not values or slot records.
  Storage is looked up on the current instance, including clones/restored graphs.
  Private-name-sensitive access, properties, aliases, statics and unknown names
  retain the original Lua handlers. Failed state remains checked on cached paths.
- The existing fast Lua getters remain in place. Operators, external callback
  boundaries, static initialization, loading/publication, directives, persistence,
  cloning and enum/extension processing retain their original implementations.

No public API or source syntax is added. C closures are registered as internal
runtime functions so host persistence cannot export their private captures.
Native entry points are captured before application code can replace module keys.
Yieldable C continuations preserve coroutine suspension/resumption through Lua
property getters/setters and dynamic index/newindex operators.
The unrestricted debug library remains outside the existing protection boundary.

## Build

Use a Lua 5.4 SDK matching the host architecture and numeric configuration; on
Windows its import library must name the host Lua DLL. Do not link a separate
Lua runtime into the module.

```powershell
cmake -S 'src/Native LXC' -B <build-directory> -A x64 `
  -DLUA_INCLUDE_DIR=<lua-include-directory> -DLUA_LIBRARY=<lua-import-library>
cmake --build <build-directory> --config Release
```

The installed Windows x64 file is
`LuaEx/bin/lxc_native-lua54-windows-x64.dll`, exporting `luaopen_lxc_hybrid`.
Compilation uses C11 and /W4 /WX (or -Wall -Wextra -Werror).
The current binary was built with MSVC against the local Lua 5.4.2 host.

`LuaEx/lib/lxc/Native.lua` loads it relative to that module's saved path.
Missing/incompatible libraries retain Lua execution. `LXC_HYBRID_MODULE` supplies
an explicit alternative library path. Other platforms currently require a local
build and this explicit path; no other-platform binary has been verified.
Lua's loader checks the runtime version and numeric sizes.

Set `LXC_NATIVE_BACKEND=lua` before starting a fresh Lua process to disable native
acceleration for comparison. Changing it after module initialization has no effect.
These environment settings are development/deployment controls, not LXC syntax.

## Verification and measurement

Run `dev/tests/native_lxc_regression.lua` in fresh Lua-only and native-enabled
processes. The suite is also registered as `native-lxc` in `dev/tests/suites.lua`.
Run the full LuaEx suites in both modes; existing moved-path test failures must
be reported separately from native compatibility. CoG/Dox tests that still call
the removed `LuaEx.load` entry point are not current integration verification.

`dev/prototypes/native-lxc/compare-benchmarks.ps1` extracts the historical
82cb843 revision to a temporary directory and runs old Lua, current Lua, the
limited original C prototype and this compatible hybrid in separate processes.
It alternates order, asserts results, writes raw logs and computes medians.
The hybrid and Lua control use the same Counter.lxc and exact workload bodies.
Construction includes an immediate getter lookup. Timings exclude parsing/loading.

The original userdata prototype lacks major functionality and is not a valid
drop-in replacement. Its faster results cannot be attributed to this compatible
integration. A trial C implementation of compiler-selected field reads did not
improve its measured workload and was removed. The hybrid leaves those reads and
general method bodies in Lua; there is no claim of a universal speedup or proof
that every application behavior is covered by automated tests.

## Local compatibility evidence — November 2, 2026

The installed Windows x64 DLL passed all 18 configured LuaEx suites in fresh
native-enabled processes and again with the Lua-only control. Five pre-existing
moved-path suites used a read-only path adapter; their source files were not
changed. The new native suite passed 1,066 checks per mode under the framework
bootstrap, including constructor/batch failures, inheritance/private selection,
typing/locks, raw facade shadowing, getter synchronization, properties, callbacks,
coroutine yielding, clone/persistence graphs, allocation and entry-point capture.

Current unchanged CoG Astro, Zone and Rarity-default tests passed in both modes
(98, 81 and 596 checks respectively). A separate Dox integration smoke passed in
both modes: automatic discovery, Lua parsing, all three builders, in-memory
exports, cloning and persistence with equal output. CoG/Dox source files were not
edited. This smoke does not replace their complete historical regression suites
or establish browser-rendered output correctness.

Automatic DLL discovery, explicitly disabled acceleration, a missing DLL and a
wrong-entry-point DLL were also checked; the latter three retain Lua execution.
Validation logs:
`C:/Users/CS/AppData/Local/Temp/LuaExHybridVerified-lw0wmoo7/`.
Approved originals were preserved before editing in
`C:/Users/CS/AppData/Local/Temp/LuaExHybridBackup-20261102-204322/`.

## Final local timing comparison

Three fresh-process medians, operations per second, with the installed build's
source and binary. These compare the complete Lua runtime with the compatible
hybrid, not the limited userdata prototype.

| Workload | Lua only | Hybrid | Hybrid / Lua |
| --- | ---: | ---: | ---: |
| Repeated lookup + getter | 3,636,364 | 5,263,158 | 1.45x |
| Prebound getter | 45,283,019 | 44,000,000 | 0.97x |
| Prebound typed setter | 719,424 | 2,985,075 | 4.15x |
| Read/increment/write | 488,998 | 569,801 | 1.17x |
| Field reads inside method | 4,878,049 | 5,263,158 | 1.08x |
| Public field read | 763,359 | 3,508,772 | 4.60x |
| Public field write | 664,452 | 1,886,792 | 2.84x |
| Construction + getter | 49,383 | 43,956 | 0.89x |

The prebound getter and method-internal read implementations are unchanged;
their small timing differences are not native optimization claims. Construction
was about 11% slower in this final comparison, although preceding three-process
runs measured the hybrid slightly faster. Native dispatch adds cold-path work;
this build is not uniformly faster. No construction speedup is claimed.
Historical Lua still wins the public-field-read, increment and method-internal
read workloads in this final comparison. AStar was not measured in this task.

Raw logs, samples and medians:
`C:/Users/CS/AppData/Local/Temp/LuaExLegacyComparison-0479b45f75bd4b0fabee65df6c92d93d/`.
