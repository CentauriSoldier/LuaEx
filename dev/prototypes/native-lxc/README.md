# Native LXC backend prototype

This is an isolated experiment, not a replacement for the production class runtime.
Class declarations and method bodies remain ordinary `.lxc` source. `bridge.lua`
uses the existing production tokenizer, parser, model validation, Lua-scope analysis
and compiler. The C module supplies storage, field access and bound-method lookup.
The same `Counter.lxc` is used for the production Lua and experimental C backends.

Writing the parser in C later would not require changing the class-file syntax.
It would address loading cost; this experiment measures execution cost after loading.
Lua method bodies still execute in Lua. A C backend does not automatically compile
those bodies into machine code.

## Supported experiment

- One public root class per load, optionally final, with a public constructor.
- Public/private fields with number/string/boolean literal defaults and inferred
  primitive type stability. Integer/float numeric values remain one field type.
- Public Lua methods, dot-call binding, variadic arguments, multiple returns,
  same-class access through another receiver and authored callbacks.
- Private compiler-selected field readers and lexical write views. External field
  access does not acquire a lexical capability. Capability tokens are not returned
  by the bridge or exposed on instances.
- Native cached bound methods, direct C slot getters, and direct C typed setters
  for whole single-parameter assignments. Bounds, primitive typing and failed
  state checks remain on every write; rejected writes leave stored values unchanged.
  Methods with extra statements, return values, expressions or variadic parameters
  keep the ordinary compiled Lua path.

Unsupported declarations fail explicitly: inheritance, enums/extensions, properties,
custom operators, restricted methods, static members, const/final field bindings,
abstract/override members, dependency policies, nested classes, non-scalar/default
expressions and directives. Cloning, persistence and production class-helper
integration are not implemented. This is not a complete semantic substitute.

Objects/classes are full userdata rather than production table decoys. Raw type,
raw writes, reflection and metatable behavior therefore differ. Nothing installs
this module into LuaEx or changes its production factories. With the repository
root on package.path, normal declaration discovery may load Counter.lxc as a Lua
fixture class; that never activates the C backend or loads its DLL.

## Files

- `runtime.c`: C11/Lua 5.4 backend and protected native capability operations.
- `bridge.lua`: current-parser/compiler adapter and explicit subset preflight.
- `Counter.lxc`: identical input fixture for both backends.
- `test.lua`: privacy, typing, failed constructors, callback lifetime, bounds,
  unsupported features, and 10,000 allocation/state/GC checks.
- `benchmark.lua`: identical verified workloads for Lua and C; supports
  `--native-first` to alternate measurement order.
- `CMakeLists.txt`: builds an isolated module against the host Lua SDK.

## Build and run

Requires a C11 compiler, CMake and a Lua 5.4 development SDK matching the host ABI,
architecture and Lua numeric configuration. Do not link a second Lua runtime into
an extension loaded by an existing Lua host. Supply its compatible import library.
For Windows/MSVC, from the repository root:

```powershell
cmake -S dev/prototypes/native-lxc -B <build-directory> -A x64 `
  -DLUA_INCLUDE_DIR=<lua-sdk-include-directory> -DLUA_LIBRARY=<lua-sdk-library>
cmake --build <build-directory> --config Release
$env:LXC_NATIVE_MODULE = '<build-directory>/Release/lxc_native.dll'
lua dev/prototypes/native-lxc/test.lua
lua dev/prototypes/native-lxc/benchmark.lua
lua dev/prototypes/native-lxc/benchmark.lua --native-first
```

The local run used native Windows x64 Lua 5.4.2 and MSVC 19.51, Release. Official
Lua 5.4.2 headers and an import library generated from the host lua54.dll exports
were kept in a temporary SDK directory. Windows SDK access required an elevated
build invocation in this environment. No production source/binary was replaced.
C compilation passed /W4 /WX; MSBuild warned only about its temporary build directory.
Linux, macOS, other Lua builds and deployment are untested.

Local binary: `C:/Users/CS/AppData/Local/Temp/LuaEx-native-prototype-build-msvc/Release/lxc_native.dll`.

## First prototype baseline — November 2, 2026

Both backends parse/compile the same fixture using the existing system. Rates below
are medians across three fresh-process runs. Each workload has one warmup and three
CPU-time samples of at least 50 ms; backend order was alternated for the middle run.
Every timed workload asserts its result. Counts are logical operations, not a claim
that every operation performs equal work. Construction includes an immediate read.

| Workload | Current Lua ops/s | Prototype C ops/s | C / Lua |
| --- | ---: | ---: | ---: |
| Repeated method lookup + getter | 3,174,603 | 8,108,108 | 2.55x |
| Prebound simple getter | 43,137,255 | 17,543,860 | 0.41x |
| Prebound typed assignment | 714,286 | 2,564,103 | 3.59x |
| Prebound read/increment/write | 505,051 | 1,886,792 | 3.74x |
| Field reads inside a Lua method loop | 4,878,049 | 13,114,754 | 2.69x |
| Public field lookup/read | 829,876 | 4,819,277 | 5.81x |
| Public field lookup/write | 803,213 | 6,896,552 | 8.59x |
| Construct + getter | 47,619 | 760,000 | 15.96x |

Raw logs/medians: `C:/Users/CS/AppData/Local/Temp/LxcNativeBenchmark-2wd7_lp3/`.
These local microbenchmarks show useful native-backend potential, not a promised
speedup for a complete implementation. The C subset lacks substantial features
supported by production Lua. The existing specialized prebound Lua getter wins
this comparison by roughly 2.46x. Moving every operation to C is not established
as the best design, and the 80-million-op target was not reached by the C backend.

The first baseline passed 48 functional checks plus 10,000 checked allocations
and GC. The current expanded suite passes 87 functional checks plus those 10,000
allocation/state checks. The prototype was not used for AStar; the requested comparison is backend versus
backend. A decision to expand it should separately define the full contracts for
inheritance, properties, directives, enums, persistence, reflection and object
representation, then rerun correctness and identical-workload measurements.

## Direct typed-setter experiment — November 2, 2026

The next pass recognizes exactly `this.field = parameter` as the complete body
of a non-variadic, single-parameter public method. The existing parser/compiler
still validates and compiles the source. The bridge resolves its accessible field
slot once and installs a C bound setter instead of calling the Lua body at runtime.
Comments and an optional semicolon are accepted through the existing token scanner.

The setter checks instance/class failure, slot bounds and established primitive
type, then uses the same native store function as ordinary writes. It avoids the
Lua method frame, per-call lexical-view allocation and field-name lookup. Return
behavior stays empty; extra actual arguments are ignored as in Lua. Source-stack
frames differ when a method is executed directly in C. This prototype does not
promise complete production diagnostic or semantic compatibility.

Use `Bridge.loadFile(filename, host, {directSetters = false})` (or the equivalent
fourth loadSource argument) to retain the generic native setter path. The benchmark
now runs all three backends: production Lua, generic native, direct-setter native.
The generic control uses the same C binary and fixture with this optimization
turned off. No production runtime or parser file was modified in this pass.

The comparison below is the median across three fresh processes, with the same
warmup/three-sample method as before and reversed outer-backend order in the middle
run. These results apply to the named microbenchmarks and the supported subset.

| Workload | Lua ops/s | Generic C ops/s | Direct-setter C ops/s |
| --- | ---: | ---: | ---: |
| Prebound typed setter | 613,497 | 1,960,784 | 12,000,000 |
| Repeated getter lookup/call | 2,857,143 | 6,153,846 | 5,555,556 |
| Prebound simple getter | 40,000,000 | 13,559,322 | 13,559,322 |
| Read/increment/write | 395,257 | 1,369,863 | 1,342,282 |
| Field read loop | 3,773,585 | 10,909,091 | 10,344,828 |
| Public field read | 623,053 | 3,508,772 | 3,508,772 |
| Public field write | 560,224 | 5,128,205 | 4,705,882 |
| Construct + getter | 32,787 | 481,481 | 545,455 |

The targeted setter improves **6.12x versus generic C** and **19.56x versus Lua**
in this run. No general improvement is established for the other paths; the
unchanged controls vary in both directions. Prebound Lua getters remain faster.
There is no claim of a 19.56x speedup for an entire class system or application.

Expanded checks cover enabled/disabled parity, comments, strings/false, rejected
nil/missing/spoofed/mismatched writes, setter identity and return behavior,
additional statements, expression/return/second-parameter/variadic fallbacks,
constructor-leaked setters, invalid slots and cached setters after class failure.
All 87 functional checks and the 10,000-allocation stress passed.

Before-edit backups, including the old DLL:
`C:/Users/CS/AppData/Local/Temp/LxcDirectSetterBackup-fv0n84ax/`.
Raw logs and three-run medians:
`C:/Users/CS/AppData/Local/Temp/LxcDirectSetterBenchmark-q12a3ji9/`.
