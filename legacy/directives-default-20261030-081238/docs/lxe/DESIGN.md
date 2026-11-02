# LXE design

Status: initial implementation built; validation and integration results are recorded below.

## Purpose and scope

LXE declares immutable enums in .lxe files and loads them before LXC classes. It owns enum parsing, validation, canonical identities, runtime behavior, extension methods, and persistence. C# is a guide, not a requirement to reproduce its entire language.

The initial implementation adds LXE alongside the existing enum factory. Migrating existing LuaEx and CoG enum declarations is a separate task. There is no requirement to reproduce old snapshot formats or add compatibility aliases to LXE.

## Members, values, and ordinals

Each member is a canonical object, not its raw payload. Value exposes an explicit payload, or the member's one-based declaration ordinal when no payload is supplied. Ordinal always exposes the declaration position within the immediate parent, independently of Value. Explicit numeric values do not change subsequent declaration ordinals.

Member names are unique within their immediate parent. Duplicate values are rejected within that same parent, including explicit/default collisions. Different enums may reuse values. Value and Ordinal are reserved names; members and extensions cannot shadow built-in operations or metadata.

Any Lua value except nil is permitted as an explicit payload, including false, tables, functions, and existing enum references. Scalar duplicates compare by ordinary value; reference payloads compare by identity, without invoking user-defined equality. Distinct tables are distinct payloads; reusing the same table for two siblings is a duplicate. Omission requests the ordinal default; an explicit expression yielding nil is an error. Value expressions execute exactly once during loading, in declaration order within their enum, after required enums are ready. The evaluation environment resolves the declaring namespace, using names, required enums, and existing LuaEx/application globals. Required enum identities are available through the prepared registry before public publication. Unknown names produce source-aware errors. using resolves names without loading or executing modules; enum dependencies needed during evaluation must be declared through requires. Payload objects remain references and are not recursively frozen. The approved metadata names are Value, Ordinal, Name, and Parent.

## Embedded enums

A nested declaration is simultaneously a member of its immediate parent and an enum containing its own members. It may have its own explicit Value independently of its children. Embedding is membership and type identity, not class inheritance.

Illustrative declaration body, to appear inside a namespace:

```lua
enum vehicle {
    car = 10 {
        honda = "Honda";
        toyota = "Toyota";
    }

    motorcycle;
}
```

Here car.Value is 10 and car.Ordinal is 1; honda.Value is "Honda" and honda.Ordinal is 1; motorcycle.Value and motorcycle.Ordinal are both 2.

For a root named vehicle: type(vehicle) is enum; type(vehicle.car) identifies vehicle; type(vehicle.car.honda) identifies vehicle.car. Type names include the declaring namespace to prevent collisions. For a root App.vehicle, type(App.vehicle) is enum, type(App.vehicle.car) is App.vehicle, and type(App.vehicle.car.honda) is App.vehicle.car.

Children are declared directly within their parent, built together, and published only after validation. An existing enum cannot be attached or reparented as another enum's child. Existing enum objects may be ordinary payload values. Such references preserve identity and do not create embedding or change ownership.

## Extension methods

Extensions must be declared in the same source file as their target enum: .lxe for standalone declarations, or .lxc for inline declarations. They may occur before or after their target at file, namespace, or class declaration scope. Collect declarations first, then resolve explicit target paths; physical adjacency and source order do not establish extension ownership. No wrapper class is required. Separate extension files are not permitted. This applies to declaration locations, not declarations buried in executable method bodies or expressions.

Agreed declaration shape:

```lua
extension vehicle.isRoadVehicle(this) {
    return this == vehicle.car
        or this == vehicle.motorcycle;
}

extension vehicle.car.isJapanese(this) {
    return this == vehicle.car.honda;
}
```

Calling shape:

```lua
vehicle.car:isRoadVehicle();
vehicle.car.honda:isJapanese();
```

The enum name or qualified path must prefix the custom method name. The receiver is a member of that exact enum. Methods do not propagate to parent or child enums. The method may explicitly navigate accessible enum relationships and perform comparisons or operations; it receives no implicit access privileges. Duplicate extension names and collisions with members or built-ins are errors. Extensions are registered during loading and fixed after publication.

Namespace qualification inside extension declarations, ordinary parameters, and extension execution environments must be specified consistently with the approved name-resolution contract. Any remaining externally visible ambiguity must be raised before implementation. Methods declared inside enum bodies are not part of this initial design.

## Namespaces and loading

Use namespace, using, and requires consistently with LXC. In particular, requires is a declaration clause with parenthesized fully qualified dependencies, not an invented file import statement. using participates in name resolution and must not execute modules.

Discover and parse source files; resolve declarations and dependencies; validate structural contracts and establish the complete dependency order for the batch before evaluating any payload expression or building runtime enum objects. Only after that preflight succeeds, evaluate values and build enums in dependency order, validate evaluated values, and publish the validated batch. Missing dependencies or cycles must fail before any payload expression executes. Missing dependencies and cycles produce source-aware errors. Embedded enums are built with their parent rather than scheduled independently. Independent declarations use deterministic ordering.

Load LXE before LXC. Runtime incremental loading uses the same validation and dependency rules, preserving existing canonical identities. Exact incremental dependency discovery behavior must be documented before coding; do not imply an unresolved name automatically locates an arbitrary file.

Parsing and structural validation do not execute payload expressions or extension bodies. Payload expressions execute during the loading stage and their resulting values must be validated before publication. Extension bodies execute only when invoked. A failed batch must not leave partially published enums or extensions. Arbitrary side effects caused by payload expressions cannot be promised to roll back; this limitation is part of the approved expression-evaluation contract.

## Class-owned enums and inline declarations

The ownership keyword is within. It replaces the earlier proposed for clause. Ownership must be explicit in both standalone .lxe files and inline .lxc declarations.

```lua
namespace App {
    public enum Kind within App.Car {
        Sedan;
        Coupe;
    }
}
```

This exposes App.Car.Kind.Sedan after the owning class has been built. No duplicate enum declaration is required inside that class. Alternatively, the declaration may appear inside the owning class body in its .lxc file, with the same required within App.Car clause. Extension declarations in that .lxc file are recognized and passed to LXE; they do not become class methods and may appear at any supported declaration scope before or after the enum. An inline ownership target must match its enclosing class. Declaring the same enum in both locations is a duplicate error.

Class ownership is independent of enum embedding. A class-owned root enum has Parent equal to LuaEx null; its members have that enum as Parent. The owning class governs accessibility through LXC's public, protected, and private rules. Ownership does not imply class inheritance for the enum.

A .lxc file may contain several classes. The parser tracks each enclosing declaration and associates each inline enum with its explicitly named owner; ownership is not assigned at file level. App.Car.Kind and App.Boat.Kind are distinct canonical names.

Coordinate discovery and parsing so each selected source file is parsed once, collecting both enum and class declarations. Establish enum dependency order before evaluating payloads or constructing enums. Build enums before classes, then attach class-owned enums as read-only class members when their owners are built. LXE owns enum validation and construction; LXC owns class attachment and access enforcement. Avoid a separate LXE pass that rereads every .lxc file.

Enum initialization cannot depend on a constructed class or its initialized static state because classes are built afterward. The within clause establishes ownership, not an initialization dependency on the owning class. Missing owners, invalid ownership targets, duplicate declarations, and class-member collisions must produce source-aware errors without partial publication. The coordinated loader preflights both declaration sets and delays publication until enum and class initialization succeed.

The approved implementation scope now includes necessary LXC parsing and loading integration for class-owned and inline enums. Inspect affected modules before selecting exact edits; explain any additional framework changes needed beyond that integration. This supersedes the earlier plan to defer inline declarations and avoid all LXC edits. It does not authorize unrelated LXC changes or directive implementation.

## Runtime and operators

Use portable Lua with protected public views and privately held state, following the reviewed framework patterns. Debug-library attacks are outside the agreed protection boundary. Do not introduce native dependencies or thread proxies that sacrifice Lua table metamethod behavior.

Approved operators:

| Operation | Contract |
| --- | --- |
| == and ~= | Canonical member identity. |
| <, <=, >, >= | Compare Value between siblings; reject unrelated members or values that cannot be ordered. |
| +, -, *, /, //, %, ^, unary - | Numeric payload arithmetic; results are numbers. Numeric scalar operands are allowed. |
| &, vertical-bar, ~, <<, >>, unary ~ | Integer payload bitwise operations; results are integers. Integer scalar operands are allowed. |
| .. | Concatenate string/number payloads; return a string. |
| #enum | Immediate member count, including for embedded enums. |
| tostring(member) | Qualified declaration path. |

Operators do not manufacture new enum members. No custom operator-declaration syntax has been approved for LXE. Lua does not invoke a table member's equality metamethod against a numeric or string scalar, so payload equality must not be promised for member == scalar.

Approved read-only metadata: Value, Ordinal, Name, and Parent. Name is the declaration name; Parent identifies the immediate owning enum for members. A root enum has Parent equal to LuaEx null.

Approved shared helpers:

- lxe.getByName(oEnum, sName): immediate member by name, or nil.
- lxe.getByValue(oEnum, vValue): immediate member by payload, or nil; use the same scalar-value/reference-identity rules as duplicate detection.
- lxe.isMember(oMember, oEnum): exact immediate-parent membership.
- lxe.isEnum(vValue): whether the value is an enum collection, including an embedded enum.

Dot/string lookup and one-based numeric ordinal lookup access members. Calling an enum or using pairs(enum) yields ordinal/member pairs in declaration order over immediate members. Preserve immutable enum/member identity when cloning.

## Persistence and framework integration

LXE owns its persistence contract. Use the existing generic serializer registration and metatable hooks; LXC must not parse enum declarations or duplicate their codec. Loading must recover the canonical root, nested enum, or member identity and its parent relationships, rather than create lookalike objects.

Restore references against already loaded declarations. If a required declaration is unavailable, fail clearly: do not implicitly execute files or manufacture replacement enum identities. This applies across processes as well as within one session. Avoid serializing extension runtime closures as enum state; extensions belong to their declarations. Any persisted payload must be supported by the existing serializer. Unsupported payloads cause an explicit save error rather than being silently discarded. Allowing a payload at runtime does not promise that every Lua value is serializable.

Initial executable scope is new LuaEx/lib/lxe.lua and focused modules in LuaEx/lib/lxe/, tests in tests/lxe/, and the LuaEx/load.lua integration. Necessary LXC parser and loading integration is also approved for class-owned and inline enums, as described above. The user additionally approved HostStaged.lua for caller-aware enum persistence. Serializer, cloner, type-hook, existing enum, CoG, and Dox edits are not currently approved as part of that scope. If evidence requires them, explain the need and obtain approval first.

## Module responsibilities

- Tokens.lua: lexical tokens and source positions.
- Parser.lua: declarations and extension bodies; no execution.
- Validation.lua: semantic contracts, collision checks, and dependency diagnostics.
- Registry.lua: qualified names and canonical identities.
- Runtime.lua: immutable members, embedding, lookup, iteration, and operators.
- Extensions.lua: extension compilation, binding, and receiver rules.
- Persistence.lua: serializer integration and canonical restoration.
- Loader.lua: discovery, batch preparation, dependency order, and publication.
- LuaEx/lib/lxe.lua: small public entry point composing those services.

Keep responsibilities focused. Do not build speculative abstractions merely to fill this layout.

## Deferred work

Shared directives are separate from LXE implementation. Initially only type is planned, with compile-time work and the previously agreed single completion validation boundaries; no directive checks on each read, write, method call, argument, or return. See ../directives.md. Param/return editor metadata and future default-parameter displays remain deferred.

Existing enum migrations, Pulsar tooling, and general class naming cleanup are separate work. Do not change general LuaEx conventions during this task.

## Review gate

The operator/helper contract, expression environment, missing-definition persistence behavior, namespace-qualified type names, and LuaEx null root Parent are approved. Document the complete grammar and raise any remaining externally visible ambiguities before implementing the affected behavior. Record approved answers here rather than silently choosing externally visible behavior. Executable implementation was subsequently authorized by the user. Remaining implementation limits are documented below.







## Implemented API and loading rules

The initial implementation provides lxe.loadSources, lxe.loadFiles, lxe.discover, getByName, getByValue, isMember, and isEnum. LuaEx initializes the lxe global automatically. Put application roots on package.path before LuaEx initialization for automatic discovery.

Standalone incremental enum batches use lxe.loadSources or lxe.loadFiles. Class-owned or inline enums use lxc.loadSources or lxc.loadFiles, which coordinate both systems. A source-map entry ending in .lxe is parsed as an LXE file; other entries in a mixed LXC batch are parsed as LXC. Root enum and class declarations require a namespace.

Enums initialize first; classes initialize afterward. Every class-owned enum must already exist when its owning class initializes. The owning class declaration is supplied in the coordinated batch so ownership can be validated before initialization. Adding enum declarations to an already published class is explicitly prohibited, not a deferred feature. A missing owner fails before payload evaluation. Core-only initialization cannot attach class-owned enum files: enable the class system for those applications.

Complete dependency preflight precedes object allocation and payload evaluation. In coordinated batches, class bodies are compiled before payload evaluation as well. Enum constants are available before ordinary class static initializers, independently of their declaration position.

Member declarations use a required semicolon unless followed by an embedded member block; the semicolon after such a block is optional. An explicit value expression extends to its outer semicolon or an embedded member block. Parenthesize Lua table-argument function calls when necessary to distinguish their argument braces from an embedded enum block. Parenthesized expressions support arbitrary non-nil results. Extension parameters start with explicit this, may add ordinary parameters, and may end in a vararg. Payload expressions and extension functions use normal Lua bodies; no default-parameter feature was added.

LXC parsing delegates enum and extension records from its existing token stream. It does not rescan every .lxc file through an LXE file pass. The standalone Tokens module uses the reviewed lexer behavior independently of LXC's private services.

Class-owned enums become static const storage declarations so LXC's existing lexical visibility and assignment checks apply. Generated enum storage precedes ordinary static fields. Enums are not classes and never enter the class inheritance registry.

Caller-bound persistence uses the approved HostStaged integration and the existing GraphAccess validator. Canonical enum references are checked under their storage owner's authority; a private enum in private instance state can round-trip, while an escaping alias is rejected. Removing the staged prefix does not grant access. No serializer or GraphAccess source changes were required. Canonical reference saves do not snapshot or replay mutable payload contents; loaded enum declarations define those values.

Internal composition seams loadDeclarations and connectClasses are for LXC integration. The latter seals its connector identity on first binding and returns its transaction/inspection hooks only to that connector. Neither seam is a public qualified-name lookup for existing private enums.

LXC integration edits: Parser.lua, Names.lua, Loader.lua, Compiler.lua, Environment.lua, Model.lua, and the separately approved HostStaged.lua. LuaEx/load.lua installs LXE and discovers standalone sources. The existing enum factory, serializer, cloner, CoG, and Dox sources remain unchanged.

## Validation record

tests/lxe/regression.lua passes 112 behavioral checks, using in-memory source fixtures. It covers nesting, values and ordinals, arbitrary payload references, duplicate detection, operators, extension placement/receivers, dependency preflight, incremental standalone loading, discovery, class ownership/visibility, static order, failed-batch invalidation, retry, canonical persistence, and private-state versus escaping-alias checks.

An actual filesystem startup check also passed using temporary .lxe/.lxc fixtures. Those fixtures were removed afterward. LuaEx loader levels 0 through 5 and option validation passed, as did the available collections, eventrix, I/O listing, metahook, primitive, stringhook, XML, and VFS suites. CoG RNG, Rarity defaults, Registry, CoGBase defaults, object/affix, ability, Pool, vehicle defaults, and structure checks passed.

The broader configured runner is not fully green: prettylua_regression.lua and cog_serializer_contract.lua are missing; class_scope_regression.lua invokes the legacy callable class factory; CoG's scaler check cannot find the scaler module. These unrelated files were not changed. Validation used the existing Windows Lua 5.4 DLL through the existing test host; other Lua hosts have not been verified.

## Static enum saving and loading

The user approved bringing LXC static persistence up to date. Host-bound lxc.saveStatic/loadStatic now use the existing staged serializer bridge, preserving canonical enum/member identity, shared references, and original caller access checks. This is the same graph protocol used for ordinary instance saving, not a separate enum snapshot format. Private static enum state can round-trip from its declaring class; an unrelated caller cannot restore inaccessible references.

Static saves still include only caller-accessible mutable fields and omit const/final bindings, including enum declarations themselves. Restore validates every proposed field assignment using trial slots before committing any static field changes. Unknown fields, inaccessible fields, wrong enum types, or binding violations fail without a partial static-field commit. Application side effects from serializer callbacks are not rolled back.

The private LXE connector supplies canonical enum types to LXC's existing field-assignment check. Member types identify their immediate parent enum; public metatable strings alone cannot impersonate an enum. Instance graph restoration accepts those type contracts only when the decoded value has the matching canonical type. This adds no directive system or new directive checks.

An initially null field may receive an existing enum value later under LXC's normal first-assignment typing rules. This is ordinary value assignment and does not attach a new enum declaration to the class. Existing rules concerning subsequent null assignments remain unchanged.

Without host binding, standalone LXC retains its restricted static snapshot codec. Previously produced restricted scalar snapshots remain accepted. Host static snapshots use the existing staged marker, and retain the 16 MiB static snapshot limit.

Additional edited integration files for this approved follow-up: LXC Host.lua, Persistence.lua, Runtime.lua and Loader.lua, plus LXE Loader.lua, regression tests and these design documents. No enum attachment mechanism was added.

Validation: 112 LXE checks pass, including new public/private static enum round trips, canonical aliases, type and unknown-field atomic failures, null-initialized fields, and late-attachment rejection. Separate fresh-state checks passed for enums loaded before a class-only batch and for standalone LXC static snapshots. Loader levels 0 through 5, options, collections, eventrix, primitives, VFS, CoG objects/affixes, Pool and vehicle defaults also pass after the change.



## CoG adoption (2026-10-29)

Shared CoG.TIER now comes from cog/enums/TIER.lxe. Pool's three selector enums,
AffixSystem.TYPE, Rarity.LEVEL and CoGVehicle.COMPONENT are inline declarations.
Rarity uses generic I through VI; Rarity.NAME configuration supplies display
labels and getName returns them. Settings no longer declare enum members.

The Pulsar source package now recognizes .lxe, enum, extension, within and enum
metadata, and validates mixed declarations without executing payloads. It uses
current LuaEx/lib module paths. Hover/signature/directive tooling remains deferred.
See ../lxc/ for the current class-system design/keyword/rule documents and
../HANDOFF.md for the migration continuation.
