# LuaEx performance handoff

Updated: November 2, 2026.

## Current objective and limits

The user wants a substantially faster pure Lua class system while preserving current functionality and public APIs. AStar exposed the cost, but the user specifically wants native Lua measurements, not just browser timings. The aspirational target is at least 80 million operations/second; that must be attached to a specific workload, not advertised as the speed of every class operation.

The latest authorized, completed pass was limited to typed field writes. The user has limited remaining credits and explicitly requested bounded work. Do not launch a broad rewrite or repeat extensive profiling without a concrete reason.

**Current result:** approximately 71 million prebound simple getter calls/second, approximately 6–6.6 million repeated `object.read()` calls/second, and approximately 1.27 million prebound typed assignments/second. The 80-million target has not been reached. General methods, setters, properties, construction, cloning and serialization do not inherit the getter benchmark rate.

## User instructions

- Obtain explicit permission before editing; edit only the authorized files. This handoff was explicitly requested in `dev`.
- Preserve all current functionality, access rules and public APIs. Ask before an unavoidable behavior change.
- Understand affected framework connections before changing them; disclose uncertainty rather than claiming complete framework understanding.
- Follow README naming/spacing. File-scope local functions have no `f` prefix; nested local functions use `f`. Do not introduce user-facing function names beginning with `_`.
- Use meaningful Dox comments and local comments. Spell the documentation system **Dox**.
- Do not spend the remaining budget on an open-ended optimization campaign.

## Relevant implementation

Framework source lives under `LuaEx/` within this repository. Initialization is `require("LuaEx.init")`, with no separate load function or load levels. Native class/enum declarations are discovered from the package path. Lua 5.4+ is required.

The main files changed during the performance work are:

| File | Current role/change |
| --- | --- |
| `LuaEx/lib/lxc/Model.lua` | Published namespace-prefix index and revision; successful member selection cached by concrete lookup class, lexical caller and member name after validation. |
| `LuaEx/lib/lxc/Environment.lua` | Shared immutable-batch namespace indexes; per-declaring-class resolution hit/miss cache invalidated by publication revision. Host values and public enum bindings remain live. |
| `LuaEx/lib/lxc/Loader.lua` | Publishes through `Model.publish`; failed batches invalidate definitions through `Runtime.discard`. |
| `LuaEx/lib/lxc/Compiler.lua` | Direct known-field reads; reuse of stable `this` views; compiled public instance bound bodies; specialized simple getters and private value-updater closures. |
| `LuaEx/lib/lxc/Runtime.lua` | Checked public-method cache, bound-body selection, getter synchronization, class-failure propagation and the latest scalar write fast path. |
| `dev/tests/environment_lookup_regression.lua` | Currently 173 behavioral checks for lookup, compiler fast paths, getters, failures and scalar writes. |
| `dev/tests/lookup_stress.lua` | Native Lua workloads, correctness assertions and CPU-time measurements. |
| `dev/tests/lookup_stress.cjs` | Fresh-process driver and in-memory comparison controls. No checkout rewriting for controls. |
| `dev/tests/suites.lua` | Registers the `lookup-cache` regression. |

### Lookup caches

`Model.publish` advances `Model.Revision` and indexes namespace prefixes. Each class scope caches `Model.resolve` hits and misses only until that revision changes. Publication can introduce a nearer class or make imported names ambiguous, so both hits and misses must be invalidated.

Namespace views still check class usability/access when yielding a class. Enum-only publication and mutable host bindings must remain visible without requiring a class-registry revision. Failed definitions must never become usable through a cached reference.

Successful `Model.member` selections are cached only after validation finishes. Caller identity is essential: private fields with the same name in base and derived classes are distinct. Arbitrary missing member names are not retained in this member cache.

### Compiled execution paths

Known accessible instance-field reads such as `this.value` can become private compiler-selected reads. Assignment targets, properties and dynamic accesses keep their checked paths. The compiler conservatively avoids hoisting a `this` view when bare uses could reassign/capture a changing receiver. Rebinding to another/foreign receiver retains fallback behavior.

Public instance methods can receive a compiled `BoundFactory`, eliminating the generic invocation trampoline. `this` is still a fresh local per invocation; callbacks retain the declaring `_ENV`; variadic and multiple-return behavior is preserved. Restricted/static methods, properties, accessors and operators retain their existing paths.

Instance facade reads cache only unambiguous public methods. Names affected by private declarations still use lexical lookup. Values and property results are not cached. Invocation and facade lifetime checks remain active.

### Prebound getters and lifetime rules

The compiler recognizes simple single-return getters rooted in a known field. Once that field's storage exists, `SlotGetterFactory` binds its current value as an upvalue and returns a private updater. Runtime stores updaters in `tSlot.GetterUpdates`.

All normal slot writes go through `fWrite`. Only after validation and committing `tSlot.Value` does it publish the new value to getter updaters. These updaters are runtime-owned and execute no application code. A rejected write must not change any prebound getter's result. Mutable table contents remain shared references.

If a method is bound before its field has been allocated, runtime uses the ordinary live-lookup bound body instead. Do not capture a missing slot permanently.

`Runtime.allocate` tracks instance states with weak keys on the declaring definition. `Runtime.discard` marks the failed definition and all its allocated instance states as failed. Loader calls this for every definition in a failed batch. This permits specialized getters to check the instance's `Failed` flag instead of separately reading class discard status every time.

**Important invariants for future work:**

- Class invalidation must flow through `Runtime.discard`; assigning only `Class.Discarded` could leave the specialized getter's instance flag unchanged.
- Field mutation must continue to flow through `fWrite`, or explicitly synchronize getter updaters. Raw changes to slot values would make captured values stale.
- Clone/restore currently create fresh instances and storage records. Any future in-place storage replacement needs a plan for cached bound methods/getters.
- The specialized getter's global `error` reference retains its declaring `_ENV`, allowing `Context.owns` to recognize compiled closures. Do not accidentally make these closures exportable as ordinary application code containing private runtime upvalues.
- Preserve constructor failure, batch failure, private access, inherited private selection, final/type locks, property accessor effects and serialization boundaries. Do not remove checks simply to hit a benchmark number.

### Latest typed-write optimization

`Runtime.write` now:

1. Checks nil, binding locks, const initialization and deferred-final constructor rules.
2. Uses the runtime's captured **native Lua type** for repeated assignments to established number/string/boolean slots.
3. Keeps the full identity/type classifier for other values and mismatches, including class ancestry and canonical enum/foreign identities.
4. Formats qualified diagnostics only on failure instead of constructing error strings on every successful write.
5. Commits storage and synchronizes getters through the common existing publish path.

Do not replace native type checking with the application's hooked `type`. The regression includes a table spoofing `__type = "number"`, which must be rejected by a numeric field.

## Measurements

Native Windows Lua 5.4.2, using CPU time from `os.clock`. Stress samples have one untimed warmup, three measured samples, and repeat work for at least 50 ms per sample before normalizing to one batch. Reported values are medians. They are local measurements, not cross-platform guarantees.

### Latest write pass

| Workload | Before | After |
| --- | ---: | ---: |
| 200,000 prebound typed assignments | 204 ms | 158 ms |
| Typed assignment throughput | 980,000/sec | 1.27 million/sec |
| Read/increment/write method calls | about 680,000/sec | about 820,000/sec |
| Prebound getter throughput | about 71–73 million/sec | about 71 million/sec |

The typed assignment rate improved approximately 29%; the mixed read/increment/write workload improved approximately 21%. The prebound dispatch-only control measured roughly 35–38 million/sec; its variation is not a claimed optimization result.

### Context from earlier passes

- Before getter storage specialization, prebound getters measured about 26 million/sec; capturing storage/value and preserving failure propagation raised that to about 71 million/sec.
- The matching plain Lua prebound closure control measured about 104–106 million/sec. It supplies no class access/type/persistence machinery.
- Repeated external `object.read()` calls remain around 6–6.6 million/sec. Do not conflate these with prebound calls:

  ```lua
  local read = object.read;
  read();
  ```

- With 1,000 extra classes, an earlier namespace optimization reduced 20,000 host-global reads from approximately 1.75 seconds to 14–15 ms. Registry growth no longer causes that scan on every read.
- Original native AStar timings were approximately 7.28 seconds to build the 20×14 map and 4.88 seconds for target `(19,12)` with two rovers.
- Latest recorded AStar timings were approximately 1.53 seconds for map creation and 0.87 seconds for that route. **Those measurements predate the final getter and typed-write passes; AStar was not retimed after them.** It is still not an instantaneous route calculation, and the class system is not universally 80 million operations/sec.

## Reproduce

Run from the LuaEx repository root with native Lua and Node available:

```text
lua dev/tests/run.lua --suite lookup-cache
node dev/tests/lookup_stress.cjs
node dev/tests/lookup_stress.cjs --no-direct
node dev/tests/lookup_stress.cjs --baseline
node dev/tests/lookup_stress.cjs --astar
```

The driver uses `LUA` from the environment when supplied, otherwise `lua` from PATH. The local executable used was `C:/Users/james.jones/Sync/PA/PATH/Lua 5.4/lua.exe`. In this Codex environment native Lua needs an elevated tool invocation; sandboxed DLL-loading errors were misleading. This is an execution-environment issue, not evidence that Lua is absent from PATH.

Comparison modes are specific:

- `--baseline` restores the old namespace/member resolver in memory. Other current execution changes remain enabled; it is not a complete historical checkout.
- `--no-direct` disables the compiler prototype and public facade method cache in memory. Current lifecycle/write machinery remains present.
- Neither mode restores the previous typed-write validator. The write-pass before numbers above were recorded before editing that validator.
- Controls use strict source-boundary replacements and may need updating when those implementation boundaries change.
- AStar stress deliberately calls `demo.plan()` to force a real solve. Repeatedly calling `demo.target()` with an unchanged goal can benchmark its intentional no-op instead.

## Validation and existing test-path limitation

Latest validation: all **17 native suites** passed, but **five require a read-only path adapter** because they still refer to pre-move locations. A bare `lua dev/tests/run.lua` therefore still reports path failures in those five; do not claim the unmodified aggregate command is green.

The 12 suites passing directly are initialization, I/O discovery, collections, class scope, lookup cache, Eventrix, I/O listing, metahook, primitives, XML, serializer and enums.

The five path-adapted suites are stringhook, string runtime, prettyLua, VFS and directives. They were executed with `docs/?.lua;dev/?.lua;` added to the package path and read-only `io.open`/`loadfile` resolution of missing legacy `.../LuaEx/...` paths back into this repository's `LuaEx/` source directory. Test files were not changed just to fix those unrelated paths. VFS's helper now resides under `docs/examples/support/`.

The focused regression currently reports **173 checks**, including:

- Late classes, ambiguity, enum-only loads and live host values.
- Base/derived private selection, escaped private methods and failed batches.
- Receiver rebinding/shadowing, virtual calls, properties, variadic/multiple returns.
- Constructor failure and class-discard invalidation of captured getters.
- Binding before storage exists; synchronization of multiple getter handles.
- Clone/restore independence and rejection of exporting compiled getter closures.
- Numeric integer/float writes, strings, booleans/false, spoofed types, enums, nil/null and rejected-write stability.

All **29 browser-runtime tutorials** also passed through Wasmoon: 16 LuaEx, 12 CoG, 1 Dox. This validates Lua execution and visual-model startup/actions covered by the scripts; live browser UI inspection was blocked by the tool's local-file URL policy. Do not claim live visual QA.

## Example repositories and rebuilds

The previously mixed examples were separated into their owning repositories, including supporting visual models/assets:

- LuaEx: `docs/Examples.html` — 16 tutorials.
- CoG sibling checkout: `docs/Examples.html` — 12 tutorials.
- Dox sibling checkout: `docs/Examples.html` — 1 tutorial.

The obsolete CSV tutorial, its embedded legacy class and its fixtures were removed with explicit permission. LuaEx's geometry tutorials were updated for the current lowercase primitives. CoG examples use native declarations/current qualified APIs. Dox's native export comparison normalizes platform text line endings.

From **each** repository root:

```text
node docs/examples/api/workbench/verify.cjs
node docs/examples/api/workbench/bundle.cjs
```

All three bundles were rebuilt after the latest write optimization. Builders embed current source dependencies; merely changing LuaEx source does not update an already generated sibling bundle. The browser uses a documented native-I/O-shaped adapter over Wasmoon's isolated filesystem; native filesystem semantics still need native tests. No framework native binary was changed in this work.

## Sensible next step

Stop and get the user's next scope before further edits. The latest bounded typed-write pass is complete.

If more performance work is authorized, use the separate dispatch, prebound getter, typed write and field-loop controls to choose one bottleneck. External facade lookup, general methods, properties and writes still have substantial overhead. The 80-million aspiration has not been met; do not imply a getter result establishes a rate for the whole framework. Keep correctness coverage and report tradeoffs rather than removing lifecycle/access/type checks to inflate a number.
