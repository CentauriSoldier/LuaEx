# LXC handoff — 2026-10-28

## Current integration follow-up (supersedes historical status below)

The latest user instruction allows application functions through the existing
LuaEx serializer. Earlier data-only/rebind choices were superseded. A delayed
queued answer did not revoke that instruction; source-chat chronology confirmed it.
Do not revert working custom comparators or VFS callbacks.

Normal `require('LuaEx.load')()` now installs LXC, filters framework classes by
load level, recursively discovers application `.lxc` roots from package.path,
and loads one internally dependency-ordered batch. Short framework aliases and
documented framework require paths identify the loaded LXC classes. Level 0
remains core-only; levels 0–5 and loader option checks passed in fresh states.

Host/HostStaged delegate application Lua functions to the existing serializer,
including bytecode, shared cells, custom environments and `_ENV == _G`.
The owner explicitly approved editing `LuaEx/lib/serializer.lua` after the mixed
array/LXC gap was demonstrated. Its additive serializeStaged/deserializeStaged
protocol allocates class identities before ordinary factories restore their state,
then fills and validates typed slots. Ordinary serialize/deserialize signatures
and version-one graphs remain; staged graphs use version two. Host saves use
`--LXC:3`; `--LXC:1`/`--LXC:2` remain readable through Codec/HostGraph respectively.
Standalone `LXC.serialize` remains data-only. Captured LXC references share
the existing serializer's graph identities;
compiled/runtime closures and inaccessible captured class factories are rejected
in maintained direct/ordinary-table callback cases.

Latest passing evidence in the worktree: standalone 470, discovery 3, bridge 9,
framework 86, walkthrough 51, collections 3,795, VFS 253, I/O 69, Protean tutorial
12 and Potentiometer tutorial 37. Compatible eventrix, metahook, primitives,
stringhook and XML suites passed. Benchmark completed; no universal speed claim.
Configured prettylua and serializer test files are absent. Legacy class-scope tests
still use retired `class(...)` syntax and do not pass against LXC.

The mixed-container gap is fixed: arrays of LXC instances, repeated aliases,
array/Queue cycles, callbacks capturing both and resaving pass. Failure tests
invalidate escaped LXC shells, preserve private field/class authority, reject
forged hidden-factory roots, and confirm recovery. Eager object cycles that do not
cross a staged LXC boundary still reject. Threads/userdata/C functions remain
unsupported. This is not a claim that every foreign object hook is compatible.

Authorized changes: required `LuaEx/lxc/**`, `lxc-prototype/**`, `LuaEx/load.lua`
and required `.lxc` fixes under `LuaEx/classes/**`, plus focused staged support
in `LuaEx/lib/serializer.lua`. Old `.lua` classes remain
outside edit scope. Do not regenerate PortClasses over manual repairs.
Class fixes include Set equality/clone/projection, SortedDictionary comparator
storage/projection, ClassRegistry callbacks/matching, EventSystem registration/
activation, Grid clone/rebuilt row views, Protean callback storage/snapshot limits,
BaseLog accessors/handle close, and restored Ini/VFS final restrictions.
Pre-existing explicit unfinished class methods were not implemented.

The integration delivery set contains exactly 30 scoped files (27 existing and
3 new). Baseline hashes, backups and delivery Manifest.json are in the prior
delivery folder's `Integration` directory. The manifest records completion and
SHA256 hashes; unchanged files are not transferred. Destination hashes are
checked against Baseline.json before copying to preserve original changes.

## Historical equality repair and walkthrough record

## Read this first

The authorized repair is implemented: **pure Lua empty table decoys backed by
hidden storage**, with native `==`/`__eq`, both binary forms, identity fallback,
inheritance/override/final contracts and mixed-runtime dispatch. Do not
introduce C, userdata allocators, DLLs, compiler dependencies, patched Lua, or a
native build requirement. The owner explicitly requires simple, portable Lua.

Current evidence: **470 standalone checks, 3 real discovery checks and 9 existing
LuaEx core bridge checks passed**. COVERAGE.md maps the documented requirements
to suites, stress dimensions, fixes and remaining limits. README.md records the
benchmark. Raw decoy entries can shadow public lookup; tests distinguish this
from hidden-state access. No exhaustive assurance or full framework migration
is claimed. The owner expanded verification to all documented systems, iterators,
invalid inputs and non-debug intrusion attempts; those suites are maintained.

Additional fixes found by verification: preserve host-global decoys during later
runtime bootstrap; authorize protected overrides by their original declaration;
return one restored graph root rather than assert's extra diagnostic value.
Finalization retains the existing private sidecar and frame-retention guards.
Shared dispatch now uses the debug registry without modifying foreign threads.

Assessment: the scoped repaired runtime has been tested thoroughly within the
available Windows Lua 5.4 environment and is ready for use within its documented
contracts and limits. This is confidence based on the recorded tests, not a
guarantee against every possible bug. Full framework migration is not release ready.
The exact 22 changed files are listed in COVERAGE.md; preserve other saved work
when transferring them from the worktree to the original checkout.

Delivery is complete in `C:\Users\CS\Sync\Projects\GitHub\LuaEx`: exactly those
22 files were copied after conflict checks and SHA256 verification. The original
checkout then passed the same 470 standalone, 3 discovery and 9 core bridge checks.
Pre-delivery versions of the 18 existing affected files and the transfer manifest
are backed up at
`C:\Users\CS\AppData\Local\Temp\LxcRepairDelivery-f96498ea6a2e41dd9debd3441d23ce9a`.
The other 4 delivered files are new. No reset, cleanup or broader synchronization
was performed; unrelated saved changes were preserved.

## Guided walkthrough follow-up

The owner subsequently requested a runnable learning example. `walkthrough.lua`
prints explanations and labeled OK/DENIED outcomes for constructor chaining,
inheritance, visibility, cross-instance/nested/protected access, overrides,
properties, typing, const/final, statics, imports, equality/operators, iteration,
abstract/final classes, clone/save/load graphs and raw shadows. Constructors chain;
they do not override. The walkthrough passed **51 checked outcomes** on the same
Lua 5.4 host. It keeps saves in memory and does not write project/data files.

Run from any working directory:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\CS\Sync\Projects\GitHub\LuaEx\lxc-prototype\Run.ps1" -Walkthrough -LuaDll "C:\Users\CS\Sync\Projects\GitHub\wxLuma\Win\Bin\lua54.dll"
```

This follow-up adds `lxc-prototype/walkthrough.lua` and updates only Run.ps1,
README.md and this handoff. The production repair and its 22-file record above
remain unchanged. The walkthrough is additional to the 470-check regression suite.

The previous agent chose threads to reject raw writes. That choice was not an
agreed architectural requirement and blocked custom equality. The subsequent
native-allocator detour was rejected. No native allocator or native dependency
was added to the repository. A portable compiler download was attempted and
interrupted; do not resume it. No downloaded compiler was used to build LXC.

The owner has very few credits left after this work. Be economical: read the
relevant implementation, make the focused repair, test it, report evidence.
Give concise progress updates as concrete steps finish. Do not turn this into
another architecture redesign or a sequence of already-settled questions.

The older notes below record the pre-repair state and reasoning where explicitly
marked historical. The current status above and COVERAGE.md supersede old counts
and pending-work statements. The owner resumed implementation in this session.

## User instructions and edit authority

Historical instruction summary (the current chat's 13 standing rules govern):

1. Do not edit files without explicit permission. Edit only permitted files.
2. Prioritize correctness over speed; one wrong character can break the code.
3. Before LuaEx changes, understand the framework. Do not falsely claim complete
   understanding. Disclose relevant gaps and resolve necessary ambiguity.
4. Follow README naming/style. A local function gets an `f` prefix only when it
   is inside another function. Module/file-level functions do not get that prefix.
5. Include DOx documentation and meaningful local comments explaining behavior.
6. Preserve the existing spacing; let lines breathe. Prefer focused functions
   and clear files over compressed, multipurpose implementations.
7. Do not pretend to know or silently ignore uncertainty.
8. No ninth rule was supplied; do not invent one.

Earlier prototype-only restrictions were explicitly expanded during this chat:

| Location | Authorized work |
| --- | --- |
| `lxc-prototype/**` | Prototype implementation, tests, examples, tools and documentation. |
| `LuaEx/lxc/**` | Required production LXC runtime files only; no tests/examples. |
| `LuaEx/classes/**` | Broader migration deferred; no edits in this repair. |
| `LuaEx/load.lua` | Integrate LXC after required runtime files are in place; remove individual migrated class requires in favor of discovery. |

Do not edit other core hooks/libraries, unrelated projects, or unrelated user
work without new permission. This resumed repair permits required production
runtime files and prototype tests/docs/tools. Loader integration remains separate.

The checkout has extensive existing modified, deleted and untracked files.
Do not reset, restore, clean, broadly delete, or infer ownership from Git status.
Many task files are untracked. Preserve them. Cleanup means specifically
identified obsolete project artifacts, not arbitrary untracked files.

`DESIGN.md`, `RULES.md`, `KEYWORDS.md`, `README.md` and `ARCHITECTURE.md` are in
`lxc-prototype`. Some still contain stale prototype-only scope, operator
exclusions, thread representation statements, paths and counts. The later
explicit user instructions above supersede those stale passages. Automatically
update the affected documentation when implementing agreed changes. Do not
treat old documentation as authority to undo newer user decisions.

## Agreed product and language requirements

- New class system, with C# as a behavioral guide, not a compatibility standard.
  Lua 5.4 is the target. Method bodies are Lua; declarations use LXC syntax.
- Encapsulation, inheritance and polymorphism must be implemented correctly.
  The owner explicitly stated debug is the sole intrusion exception and later
  rejected the agent's additional architectural complications around decoys.
- Keep real private/protected/public storage and internal registries hidden.
  A write to a public decoy is not access to hidden storage. Do not conflate
  public shadowing with reading or modifying private/protected backing state.
- Native Lua `rawset` can insert a raw entry into a table decoy and shadow lookup.
  Decoys alone cannot intercept that operation. Be truthful about that fact,
  preserve hidden storage, and test the concrete consequences. Do not claim the
  user granted a blanket raw-operation exception; they did not. Do not use this
  issue to restart the rejected thread/native design or invent more guards.
- Scope belongs to the declaring class, including cross-instance access between
  objects of the same class. Use C#-guided protected receiver restrictions.
- Nested private/protected/public classes, restricted class-reference use,
  appropriate inheritance restrictions, final and abstract classes/methods.
- Explicit compatible overrides; no accidental member hiding/shadowing in
  declarations. `base` selects immediate-parent behavior, including overrides.
- One instance constructor per class. An explicit parent constructor call must
  be the first statement; an omitted call implies parameterless parent chaining.
  Constructor chaining/accessibility follows the agreed C#-guided rules.
- One parameterless static constructor, able to mutate its own static state
  through the class qualifier. Static members are accessed through class names.
- `const` locks a declaration-initialized binding. `final` locks the binding on
  its first non-null initialization; for methods it prevents overriding, and for
  classes it prevents derivation. Neither recursively freezes a table's contents.
- Recursive `lock(table)` is a separate future function, eventually a table hook;
  not a class modifier and not part of this build.
- Automatic and custom typed properties; property syntax does not alter access
  rules. User-chosen access modifiers and configurable get/set prefixes.
- Scope-restricted class helpers. `this`, `base`, property `field`/`value`, and
  ordinary parameters such as `other` have their documented roles.
- `using` namespace lookup and `requires` initialization dependencies.
  The parser/example declarations currently use `class Child : Parent`.
  Do not promise an `extends` spelling without checking actual parser support.
- Interfaces were explicitly excluded. No speculative signature checking on
  every method invocation; compile-time override validation and field type
  enforcement are the intended approach. Abstract properties remain excluded.
- Classes/objects must support cloning and save/load, including graph identity
  and cycles. Generic clone/restore avoids constructors. Access checks still
  apply to hidden class references and capabilities.
- All Lua 5.4 callable metamethods must be supported as class operators, including
  `__eq`. Clone/serialize/deserialize are additional framework hooks, not native
  Lua metamethods. `__metatable`, `__mode`, `__name` are runtime-owned metadata;
  `__ipairs` is not a Lua 5.4 metamethod. Do not count metadata as unimplemented
  callable operators or describe the extra persistence hooks as native Lua.

Refer to the detailed design/tests for the remaining established contracts;
this summary does not authorize silently revising them.

## Current files and runtime composition

Production entry: `LuaEx/lxc/init.lua`.
Prototype entry: `lxc-prototype/lxc.lua`, now a small forwarding loader to it.
There is no separate maintained prototype module implementation.

All production modules live in `LuaEx/lxc/modules/`:

| Module(s) | Responsibility |
| --- | --- |
| `Tokens`, `Names`, `Parser`, `LuaScope`, `Compiler` | Lexing, declarations, lexical analysis, source transformation. |
| `Model`, `Validation`, `Operators` | Class/member records, contracts, inheritance and operator spellings/signatures. |
| `Environment`, `Context` | Method environments, declaring scopes and trusted/external frame boundaries. |
| `Facades` | Opaque references, private dispatch handlers, Lua metamethod dispatch and finalization. |
| `Runtime` | Instances, member access, typed storage, construction and operator invocation. |
| `Helpers` | Scope-restricted class helpers. |
| `SnapshotHooks`, `GraphClone` | Snapshot customization and independent graph cloning. |
| `Persistence`, `Literal`, `SnapshotSchema`, `GraphAccess` | Graph snapshot/restore, data-only encoding, schema and access validation. |
| `Loader`, `Diagnostics` | Composition, transactional source/file loading, discovery and diagnostics. |
| `Host` | In-progress LuaEx clone/serialization/type/global-alias integration bridge. |

`init.lua` loads factories relative to its own path into a private snapshot of
trusted library dependencies. It does not publish internal modules in
`package.loaded`. Host LuaEx null is reused when available; standalone LXC has
its own opaque null. Distinguish runtime identities using `rawequal` where needed.

The `Loader` builds the modules and root API. It exposes class/null helpers,
loadSources/loadFiles/discover, graph codec operations, `clone`, `bindHost`, and
`publishFrameworkAliases`. `API.clone` uses `GraphClone`, not serialization.
`Runtime.services()` privately supplies class/object registries, storage writes,
allocation, null and invocation to injected modules. Do not expose it publicly.

Loading is transactional: parse, validate, prepare, static initialization,
publication recheck, then commit. Failed batches invalidate partial references.
Incremental loading exists; do not rebuild all classes on each new file batch.
Dependency ordering is internal. User withdrew the separate LuaEx-first order
requirement. Discovery derives roots from package.path patterns, recursively
finds `.lxc` files through LuaEx `io.listfiles`, deduplicates/sorts, and loads a
batch. It is explicit discovery, not a magical native Lua require extension.

## Historical pre-repair access machinery (now replaced as described above)

- `Facades` currently allocates and resumes an empty coroutine for every opaque
  reference, leaving a dead thread. A weak-key map holds private operations.
  A protected shared thread metatable returns `LXC opaque reference` publicly.
- Different LXC runtime instances currently share facade dispatch through the
  private `__lxc_facades` marker on the actual thread metatable. Preserve the
  tested multi-runtime behavior when replacing allocation. Do not casually
  remove sharing and break mixed-runtime operations or expose handler registries.
- `Context.caller` recognizes registered compiled environments and trusted
  internal frames. External callbacks stop privilege propagation. Nested
  compiled closures retain their declaring rights.
- `local __lxc_guard <close> = nil;` deliberately prevents trusted frame tail
  elimination. `istailcall` handling rejects erased external caller contexts.
  Do not strip these guards as unnecessary overhead during this task.
- `Facades.invokeExternal` deliberately is NOT registered as an internal frame.
  Foreign metamethod callbacks must not borrow a calling class's privileges.
- The compiler rewrites qualified expression roots to private lexical views.
  Bare returned values/arguments do not automatically acquire caller rights.
  `_ENV` and `__lxc` names are reserved against source-level escapes.
- Lexical declaring storage wins over an ancestor/descendant private name reuse.
  Protected receiver rules and nested-type qualification checks are intentional.
- Unknown-name `__index`/`__newindex` hooks run only after declared members,
  aliases and nested-type names are resolved/checked. They cannot bypass denied
  declared members, property setter access, typing or binding locks.
- Codec authority is explicitly host-granted. Do not inject unrestricted private
  snapshots or registries into ordinary method environments.

## Historical pre-repair operator gap and repair checklist

The current operator suite has 55 checks. These passed:

`__add`, `__sub`, `__mul`, `__div`, `__idiv`, `__mod`, `__pow`, `__unm`,
`__band`, `__bor`, `__bxor`, `__bnot`, `__shl`, `__shr`, `__concat`, `__len`,
`__lt`, `__le`, `__index`, `__newindex`, `__call`, `__tostring`, `__pairs`,
`__close`, `__gc`, plus framework `__clone`, `__serialize`, `__deserialize`.

**Missing: custom `__eq` through native `==`.** Thread identity `==` works;
Lua 5.4 ignores a thread's `__eq`. This does not mean Lua lacks `__eq`.
Tables support it. Do not repeat the previous misleading generalization.

Concrete repair points:

1. `Facades.create`: replace the coroutine allocation with an empty table decoy
   using a protected dispatch metatable. Backing handlers remain private.
2. `Operators.lua`: add `__eq` to the binary contracts (one other operand or two
   original operands). `==` already resolves to `__eq` in the spelling map.
3. `Validation.lua`: remove the explicit rejection of `__eq`; retain ordinary
   public, instance-method, arity, override and final validation.
4. `Facades.lua`: add binary equality dispatch and the table `__eq` metamethod.
   Preserve left-before-right operator lookup and external callback boundaries.
   If neither operand declares equality, use identity, not an unsupported-op
   error. Lua itself returns true for an identical table without calling __eq.
   `~=` is Lua's negation of equality; it needs no separate hook.
5. Audit runtime/API/helper comparisons. Once facades are tables, `==` can call
   user code. Internal identity comparisons must use `rawequal` where identity
   is intended. Do not invoke user equality for registries, scopes, null or types.
6. Review all native type branches in Runtime/Helpers/Host/clone/codec/schema.
   Registered facade identities must be recognized before generic-table paths.
   Do not recurse into decoys as ordinary data or serialize them as empty tables.
7. Review finalization. Current threads use a private finalizable handler
   sidecar, not native thread __gc. It restores the weak dispatch map during
   finalization; Runtime restores object state for private reads/resurrection.
   A naive table replacement currently retains this sidecar. If implementing
   direct table __gc, attach its finalizable metatable at creation and ensure
   no duplicate finalization. Failed/incomplete instances must still skip hooks.
8. Update representation-specific tests (e.g. `tests/context.lua` calls
   `coroutine.resume(a)` directly and expects false). For table decoys that call
   raises an argument error. Test non-resumability through pcall instead.
   Existing rawset-rejection assertions will also require truthful treatment;
   do not silently erase meaningful hidden-storage access tests to make green.

Examples of existing syntax:

```lua
public operator +(left,right) { return Number.number(left)+Number.number(right); }
public operator +(other) { return this.value+other; }
public operator -() { return -this.value; }
public operator [](key) { return this.values[key]; }
public operator []=(key,value) { this.values[key]=value; }
public operator ()(...) { return this.value,...; }
public override operator +(left,right) { return base.__add(left,right)+100; }
```

Binary two-parameter forms receive the original operands in original order,
including primitive-left operations. One-parameter forms receive the other
operand with `this` bound to the selected instance. Unary forms take no explicit
operand. Canonical names such as `public __add(other)` also work.
Ordering implements reversed __lt fallback for <= when __le is absent.
Arithmetic has no invented default operation on arbitrary instances; it needs
a declared/inherited operator or valid Lua right-operand fallback.

Equality tests to add: same-instance identity, separate equal/unequal values,
default identity for classes without __eq, ~=, one/two-operand forms, inherited
and overridden equality, final/signature rejection, private same-class reads,
external-callback scope isolation, foreign operands and multi-runtime behavior.
Follow Lua 5.4's native dispatch eligibility; do not claim table-vs-number ==
invokes __eq. Add raw-decoy writes proving hidden state is not changed/exposed,
and explicitly record any public shadowing behavior without calling it hidden
storage access. Preserve graph cycle/alias and lifecycle tests after the swap.

## Clone and serialization hooks just completed

`GraphClone` already finds and invokes `__clone`. A custom clone must return a
distinct instance of the same concrete class. Generic graph copies preserve
cycles/aliases and function identities. Custom cyclic hooks can register copies
through the scoped helper; external callbacks cannot register privileged copies.

`SnapshotHooks.prepare` now selects the inherited most-derived `__serialize`
operator and invokes it at its declaring level, after that level's legacy
`prepareSnapshot` hook. It passes `{pri={}, pro={}, pub={}}` containing that
level's declared non-static fields. The operator edits projected values in place;
its return value is currently ignored. Prepared replacements retain field types.
The projection is shallow: mutating a referenced input table can mutate source
data. Replace projected values; do not claim deep isolation.

`SnapshotHooks.validate(state, true)` invokes selected `__deserialize` after
legacy `validateSnapshot` at its declaring level, parent-first, after the graph
is filled. Changes obey existing types and binding locks. Persistence passes
true; generic clone does not, so serialization operators do not run on clone.

Tests cover custom clone, source-slot preservation during serialization,
deserialize projection changes, and invalid serialization field type rejection.
These are focused tests, not proof of every inheritance/cycle interaction.
The generated Ini draft's return-table serialization style must be reconciled
with this projection contract before claiming that class is migrated.

## Benchmarks: measured, not assumptions

The owner asked whether giving up __eq was worth thread speed. Answer from the
actual local A/B benchmark: **no demonstrated useful thread speed advantage**.

The test loaded the actual LXC runtime into fresh Lua states using the existing
Lua 5.4 DLL. In the table variant only, a temporary in-memory loadfile wrapper
replaced these two source lines in Facades.create:

```lua
local oReference = coroutine.create(function() end);
coroutine.resume(oReference);
```

with `local oReference = setmetatable({}, _tMeta);`.
Everything else, including hidden maps/dispatch and existing sidecars, stayed
the same. No repository file was changed. This is an allocation/representation
comparison, not a completed or security-validated table implementation. The
temporary benchmark code was executed as a PowerShell here-string and was not
saved; `benchmark.lua` does not reproduce this A/B automatically.

Five alternating-order rounds, warmup, GC before timed operations. Per round:
100,000 field/property/addition operations, 50,000 method operations, 2,000,000
identity comparisons, 5,000 constructions. Retained heap measured with 1,000
live instances and two full collections. Class had a private counter, public
field, automatic property, increment method and addition operator. Basic
operation correctness and private read denial were checked before timing.

Medians in microseconds/op, except memory:

| Operation | Threads | Table decoys |
| --- | ---: | ---: |
| Field read | 0.63 | 0.63 |
| Field write | 0.91 | 0.94 |
| Property read | 0.86 | 0.86 |
| Property write | 1.14 | 1.16 |
| Cached method | 2.70 | 2.74 |
| Method lookup + call | 3.30 | 3.32 |
| Addition | 1.10 | 1.12 |
| Identity equality | 0.0125 | 0.0130 |
| Construction | 6.40 | 6.00 |
| Retained bytes per instance, including backing state | 2929.464 | 1993.464 |

Tables constructed about 6% faster and used about 32% less retained Lua heap
in this class. Other small differences were effectively tied for this decision;
no statistical significance or universal speed claim was established. The test
does not compare overloaded table equality to identity-only thread equality.
It provides no justification for sacrificing required custom equality.

## Test commands and historical pre-repair results

Use Windows PowerShell, **not `pwsh`** (the user does not have it).
Run from the authoritative repository:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\lxc-prototype\Run.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\lxc-prototype\Run.ps1 -Integration
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\lxc-prototype\Run.ps1 -Benchmark
```

Runner can take `-LuaDll` explicitly. Working DLL:

`C:\Users\CS\Sync\Projects\GitHub\wxLuma\Win\Bin\lua54.dll`

The installed `C:\Users\james.jones\Sync\PA\PATH\Lua 5.4\lua.exe` previously
failed DLL relocation. Prefer the existing runner; do not spend credits repairing
the unrelated Lua installation. Run.ps1 uses a C# P/Invoke host to open fresh Lua
states, load standard libraries and execute test.lua. It is testing infrastructure,
not a native production LXC dependency. PS5-compatible UTF-8 copying is already
implemented; do not reintroduce Marshal.PtrToStringUTF8.

Last actual standard result, before this handoff:

| Suite | Checks |
| --- | ---: |
| contracts | 88 |
| persistence | 36 |
| loading | 20 |
| context | 26 |
| acceptance | 36 |
| language | 37 |
| operators | 55 |
| examples | 3 |
| runtime isolation | 4 |
| **Total** | **305** |

Real LuaEx `io.listfiles` discovery integration also passed **3 checks** after
the snapshot hook changes. This is not full LuaEx loader/class integration.
No code changed during the subsequent A/B measurements or handoff writing.
The repair rerun is recorded at the top and in COVERAGE.md; this table is historical.
The host sometimes prints an InitializeDefaultDrives/FileSystem provider warning;
the recorded runs still completed successfully. Do not fix unrelated host setup.

## Larger migration: incomplete, separate from the equality repair

The previous agent's claim that only equality remained applied only to known
operator gaps. **The overall LuaEx migration is not complete.**

`LuaEx/load.lua` still contains individual legacy class requires and has not been
wired to the new runtime/Host bridge. Its backed-up legacy class implementation
is currently present at `LuaEx/lib/class.lua` and was inspected as the structural
decoy reference. It was not modified. Do not claim the normal loader now works
end to end with LXC.

Fourteen `.lxc` drafts exist alongside old `.lua` class files under LuaEx/classes:

- Queue, Stack, Set, Tree, SortedDictionary, ClassRegistry, XML, Grid, EventSystem.
- component/Potentiometer and component/Protean.
- util/Ini, util/BaseLog and util/VFS.

They previously compiled/initialized in a smoke run, but behavior was NOT fully
validated. Known follow-up areas: callback/function fields, BaseLog legacy
directives, EventSystem legacy API assumptions, Ini snapshot return format and
other generated semantic mismatches. Set equality was temporarily moved to
`equals()` with explicit owner agreement to revisit; now custom == is required.
Do not claim a draft class is migrated based only on parser/static-init success.

`lxc-prototype/tools/PortClasses.lua` generated these drafts. Re-running it can
overwrite manual fixes. Inspect before using. It moves file-level helpers into
private statics, rewrites cdat receivers and renames colliding private fields;
those transformations are not a substitute for per-class behavior validation.

`Host.lua` and Loader bindHost/publishFrameworkAliases exist but are in-progress:

- Bridges baseline LuaEx cloner/serializer and dispatches LXC graphs to the new
  clone/codec services. Tagged serialized payloads use `--LXC:1\n`.
- Wraps callable LuaEx type and can publish LuaEx.Classes aliases to host globals.
- Rejects serialization of private runtime/compiled closures through the legacy
  serializer; ordinary callback serialization is not automatically supported.
- cloneIndependent currently delegates to the same clone engine; validate the
  intended independent traversal semantics before claiming full compatibility.
- Host integration needs the actual initialized core and careful load ordering;
  it is not currently exercised by the standard standalone suite end to end.

Future integration should load required runtime after baseline services, bind
the host, discover framework/application LXC sources with internal dependency
ordering, publish intended framework aliases, and remove replaced individual
requires. Inspect actual loader modes first. Do not edit baseline cloner,
serializer, hooks or other unauthorized core files to force integration.

## Historical repair sequence (completed; future migration remains separate)

1. Confirm the owner has resumed implementation. Read README conventions,
   Facades/Operators/Validation/Runtime/Context and the affected tests. Inspect
   the old decoy wiring in `legacy/lib/class.lua` around instance.build and
   instance metatable construction. Do not claim entire-framework mastery.
2. Make the smallest table-decoy/equality repair. Preserve existing contracts,
   caller boundaries, graph identity and lifecycle behavior. Keep tests/examples
   out of production LuaEx/lxc. Do not expand into the larger migration unless
   that is the resumed task.
3. Add focused positive/negative equality and hidden-storage tests, update
   obsolete representation assertions, run the standard suite and integration.
   Investigate failures; do not weaken unrelated access contracts for green tests.
4. Update agreed design/rules/keyword/architecture/README representation and
   operator statements. Keep scope and recorded results accurate.
5. Report exactly what changed, what actually passed, any concrete remaining
   limitation, and whether full LuaEx integration is still outstanding. Never
   call everything done merely because operator tests pass.

Do not spend another session proving that threads lack __eq, downloading native
tools, rebuilding the entire framework, or defending the prior architecture.
The owner wants a readable, organized, portable class system using familiar
decoys and working operators, completed within the agreed scope.
