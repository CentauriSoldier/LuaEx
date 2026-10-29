# LXC verification coverage — 2026-10-28

This checklist maps DESIGN.md and HANDOFF.md requirements to executable evidence.
It is not a proof of every possible input, interaction or non-debug intrusion.
The current run uses Windows PowerShell and Lua 5.4 from
`C:\Users\CS\Sync\Projects\GitHub\wxLuma\Win\Bin\lua54.dll`.

## Actual results

| Suite | Checks |
| --- | ---: |
| contracts | 88 |
| persistence | 36 |
| loading | 20 |
| context | 28 |
| acceptance | 36 |
| language | 37 |
| operators | 56 |
| equality | 36 |
| stress | 25 |
| adversarial | 96 |
| examples | 3 |
| runtime isolation | 8 |
| 8 additional runtime registries | 1 assertion group |
| **Standalone total** | **470** |
| Real LuaEx discovery | 3 |
| Existing LuaEx core bridge | 9 |
| Normal loader + framework/host callbacks | 86 |
| Guided walkthrough | 51 |
| Existing collection regression | 3,795 |
| Existing VFS regression | 253 |
| Existing I/O listing regression | 69 |
| Protean / Potentiometer tutorials | 12 / 37 |

Fresh-state loader levels 0–5 and option validation passed. Compatible eventrix,
metahook, primitives, stringhook and XML suites passed through normal initialization.
The configured prettylua/serializer test files are missing; the old class-scope
suite uses retired class-factory syntax. Those are not passing coverage.

Counts are explicit assertions/groups reported by the runner. Stress loops contain
additional assertions; 2,000 iterations are not presented as 2,000 separate checks.

## Requirement checklist

| Documented aspect | Executable evidence |
| --- | --- |
| Encapsulation; public/private/protected members; cross-instance declaring rights | contracts, acceptance, context, stress, adversarial |
| Protected base/sibling/descendant receiver restrictions | acceptance, stress, adversarial |
| Lexical private-name reuse; public access optimization | contracts, acceptance, stress |
| Nested visibility; inner-to-outer direction; no sibling/outer-to-inner privilege | contracts, persistence, stress |
| Held/escaped private factories and helper use-site visibility | contracts, persistence, stress |
| Single inheritance; cycles; final bases; permits/excludes; access domains | contracts, loading, language, acceptance, adversarial |
| Abstract classes/methods; compatible explicit overrides; final/signature rejection | contracts, language, equality, adversarial |
| Dynamic dispatch; immediate base selection; protected override access | language, equality, stress, adversarial |
| Typed fields; false; null establishment/reset; nil rejection; original class constraint | contracts, language, persistence, equality, adversarial |
| Const/final binding locks; mutable table contents; static/instance initialization | contracts, language, loading, stress, adversarial |
| Constructors: access/default/base-first/order/failure; no replacement returns | contracts, acceptance, loading, adversarial, stress |
| Static fields/constructor/dependencies; inherited shared storage; failed staging | loading, language, contracts, persistence |
| Automatic/custom properties; aliases/prefixes; accessor access; shared override slot | contracts, language, acceptance, stress, adversarial |
| Imports, dependencies, relative names, ambiguity, local shadowing | loading, acceptance, language |
| Lua body scopes, closures, initializer functions, loops, labels, literals | acceptance, context; LuaScope corpus is finite |
| Reserved _ENV/__lxc names; implicit writes; dynamically loaded foreign functions | contracts, context, adversarial |
| External callbacks/tail calls/errors/yields; legitimate closure rights | context, acceptance, stress, operators, equality, adversarial |
| All declared Lua 5.4 callable operator families | operators plus equality; metadata __mode/__name/__metatable remain runtime-owned |
| Binary operand order/one-two operand forms; right/foreign fallback; inherited operators | operators, equality, runtime isolation |
| Native ==/~=; same-instance short circuit; identity fallback; type eligibility | equality, runtime isolation |
| pairs/custom iterators; escaped authored iterators; foreign hook/iterator boundaries | operators, adversarial |
| Raw reads/writes; shadowing; ordinary writes to raw keys; helper/API/class decoys | context, operators, equality, stress |
| Hidden typed slots remain intact under raw shadows; clone/save ignore shadows | equality, stress |
| Protected native metatable; table.insert/table.move/next; no resumable facade | context, stress, adversarial |
| Every public class-helper family; unresolved/nonstring inputs | contracts, language, adversarial |
| loadSources/loadFiles/discover; transactional publication/recheck/reentrancy/recovery | loading, acceptance, integration, stress, adversarial |
| Constructor-free clone/restore; class identity; functions retained by clone/rejected by codec | persistence, equality, stress, integration |
| Object/table cycles, aliases, keys, deep graphs; internal identity avoids user equality | persistence, equality, stress, integration |
| __clone and custom cyclic registration; external registration denial; rollback/recovery | operators, integration, stress |
| __serialize/__deserialize projection, source preservation, type rejection | operators; legacy snapshot validation exercised by stress |
| Snapshot schema/type/locks/classes/forged hidden factory paths; static persistence | persistence, language, adversarial |
| Invalid declarations, public arguments, malformed literal/schema data | contracts, loading, acceptance, equality, adversarial |
| Text/nesting/node limits; codec recovery after rejection | adversarial |
| close/gc; private reads; resurrection; exactly once; failed/incomplete state | operators, equality, stress |
| Multiple runtime dispatch; private scope separation; foreign codec/clone rejection | runtime isolation |
| Later runtime bootstrap with host-global decoys; foreign thread metadata unchanged | runtime isolation |
| LuaEx clone/tagged serializer/type bridge and primitive fallback | integration, framework; normal load levels and compatible core suites |

`framework.lua` covers all 14 bundled class identities, recursive application
discovery/dependency loading, custom comparator saves followed by insertion,
registry callbacks/defaults, Tree cycles, EventSystem flags, Grid views, Ini
inheritance/final, BaseLog handles/accessors, VFS final, and host callback captures.
Callback checks include shared cells, aliases, class back-references, cyclic roots,
custom environments, current global binding, nonfinite values, rejection/recovery,
and private compiled-closure/class-factory denial. Existing VFS tests include custom
adapter callback saves. Standalone codec function rejection remains covered.

## Stress dimensions

- 2,000 derived constructions with independent defaults, private-name reuse,
  inherited equality and original property backing slots.
- 100 repeated access, binding, callback and nested-visibility attempts per group.
- 40 suspended coroutines resumed in reverse order, with denial checks between.
- 40 incremental dependent class batches and 40 rejected duplicate batches.
- 8 additional isolated runtime registries, with mixed-runtime arithmetic,
  equality, denied private cross-access, independent clone and codec operations.
- Existing 301-class ancestry fixture and 2,000-edge persistence fixture.
- 300 mutually linked objects with aliases and object keys, through clone and codec.
- 1,000-level plain-table clone with a root back edge.
- 30 failed constructors and 30 failed restores, checking unusable leaked objects.
- 100 originals plus 100 clones plus 100 restores finalized once each; repeated
  collections, failed-object suppression and separate resurrection regressions.
- Rejection above 16 MiB text, at 256 nested literals, and at 100,001 graph nodes.

## Findings fixed during this repair

- Thread facades prevented native equality. Empty table decoys now use the private
  dispatch map and existing finalizer sidecar; no production native dependency.
- Subsequent runtime bootstrap could enumerate newly table-backed host identities.
  It now recognizes them before generic host-table copying.
- Dynamic protected overrides wrongly revoked the base declaration's access.
  Access now follows the original method/property/accessor contract.
- Graph-reference restoration returned assert's diagnostic as a second success
  value. Restored roots now return exactly one value.

## Limits and concrete consequences

Native rawset can shadow public lookup and subsequent writes to that raw key bypass
__newindex. This includes methods, properties, statics, helpers and API names.
Checked hidden slots remain separate in the exercised cases. Removing the entry
restores checked lookup. This is documented behavior of the chosen table decoys,
not hidden-state access and not a blanket raw-operation exception.

No claim covers unrestricted debug authority or aliases granting equivalent debug
capabilities. Only this Windows Lua 5.4 host was executed. Tests do not establish
other operating systems, every Lua 5.4 distribution, an unlimited graph/ancestry
depth, every possible source program, maximum-size successful inputs, arbitrary
foreign resources, all operator/snapshot-hook inheritance combinations, or every
possible intrusion. Snapshot projection is shallow, and explicitly authorized
exports can disclose private state. Snapshots are not authenticated.

Normal loader integration and the listed bundled class behavior are now tested.
Mixed typed-container coverage includes arrays of LXC instances, repeated aliases,
array/Queue back-cycles, callbacks capturing both, resaving and independent state.
A point inside a Queue also passes. Checks reject compiled callbacks and hidden
factories inside arrays, external/forged hidden-factory restoration, and failed
snapshot hooks; escaped failed shells are unusable and later restores recover.
Older LXC tags 1/2, ordinary version-one graphs, ignored extra arguments and eager
object-cycle rejection are covered. Other eager object cycles still require
their own allocation protocol and remain unsupported.
Host saves use trusted executable Lua through the existing core serializer's
authorized additive staged protocol;
standalone LXC saves remain data-only. No claim covers every foreign hook/callback
composition. Existing explicit unfinished methods in legacy classes remain
unfinished (for example Queue.deserialize and Grid sorting/duplication stubs).
Future table.lock, interfaces, abstract properties and Lua 5.3 remain outside completion.
The benchmark is a host/workload measurement, not a statistical speed guarantee.

## Historical equality repair files (before integration follow-up)

Production (6 files):

- `LuaEx/lxc/init.lua`
- `LuaEx/lxc/modules/Facades.lua`
- `LuaEx/lxc/modules/Operators.lua`
- `LuaEx/lxc/modules/Validation.lua`
- `LuaEx/lxc/modules/Model.lua`
- `LuaEx/lxc/modules/Persistence.lua`

Verification (9 files; equality, stress and adversarial suites are new):

- `lxc-prototype/tests/context.lua`
- `lxc-prototype/tests/operators.lua`
- `lxc-prototype/tests/equality.lua`
- `lxc-prototype/tests/stress.lua`
- `lxc-prototype/tests/adversarial.lua`
- `lxc-prototype/test.lua`
- `lxc-prototype/integration.lua`
- `lxc-prototype/benchmark.lua`
- `lxc-prototype/Run.ps1`

Documentation (7 files; this coverage checklist is new):

- `lxc-prototype/README.md`
- `lxc-prototype/DESIGN.md`
- `lxc-prototype/KEYWORDS.md`
- `lxc-prototype/RULES.md`
- `lxc-prototype/ARCHITECTURE.md`
- `lxc-prototype/HANDOFF.md`
- `lxc-prototype/COVERAGE.md`

The equality phase did not edit the old class implementation, loader or framework
drafts. The current integration follow-up also edits the authorized loader and
required `.lxc` classes, adds HostGraph.lua/HostStaged.lua/framework.lua, and updates
runtime bridges/documentation plus the explicitly authorized serializer.lua.
Other core hooks/libraries and old `.lua` classes are unchanged.

## Integration follow-up delivery set

Thirty files differ from the integration baseline (27 existing, 3 new):

- `LuaEx/load.lua`, `LuaEx/lib/serializer.lua`.
- Runtime modules: Facades, GraphAccess, Host, Loader, Persistence, Runtime,
  SnapshotSchema; new HostGraph and HostStaged.
- Bundled `.lxc` files: ClassRegistry, EventSystem, Grid, Set, SortedDictionary,
  component/Protean, util/BaseLog, util/Ini and util/VFS.
- Prototype files: ARCHITECTURE.md, COVERAGE.md, DESIGN.md, HANDOFF.md, KEYWORDS.md,
  README.md, RULES.md, integration.lua, Run.ps1; new framework.lua.

The delivery manifest records exact paths and SHA256 baseline/delivered hashes.
Files unchanged from the baseline are not transferred. Existing originals are
checked against their baseline hashes before any copy, and backed up separately.
