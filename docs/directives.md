# Directives and editor annotations

Status: shared parsing, `@type` completion validation and `@default` declaration
selection are implemented. Pulsar source tooling uses the same compilation rules;
live editor rendering remains unverified.

## Runtime budget: once-only validation

Directive parsing, name resolution, metadata construction and provable diagnostics
happen during class-loading compilation.

The only additional runtime validation permitted is one completion pass per newly
created instance, after its most-derived constructor finishes. Static storage gets
one pass per declaring class after its static constructor finishes, including
declaration initialization when no static body exists.

Clone and load operations that bypass constructors validate each resulting
instance once before returning the completed result. Coordinate custom clones
that invoke constructors so the final copied state is checked once, rather than
blindly stacking constructor and clone validation passes.

Do not add directive checks to assignments, field reads, property getters/setters,
method calls, arguments or return values. Do not parse directives or resolve type
names in those paths. Existing LXC runtime type, visibility, const and final checks
remain unchanged.

Consequently, type validates creation-time stored state; it is not an additional
continuously enforced runtime contract. Later writes follow existing LXC rules.
Computed-property types are compile-time/editor metadata only.

## Scope and placement

General LuaEx naming and coding conventions remain unchanged. Class-specific
conventions will have their own README subsection once settled.

Use shared infrastructure outside the lxc directory:

```text
LuaEx/lib/directives.lua
LuaEx/lib/directives/Parser.lua
LuaEx/lib/directives/Registry.lua
LuaEx/lib/directives/Diagnostics.lua
LuaEx/lib/directives/Selection.lua
```

The entry module assembles the public API. Parser records syntax, targets and
source locations. Registry registers definitions and validates supported uses.
Diagnostics produces consistent, located errors.

LXC and LXE integrations own their applicable definitions and semantics.
They opt into shared definitions explicitly. The shared parser must not contain
class or enum business logic.

Supported directives are type and default. Do not build speculative
handlers, plugin discovery, generic validation predicates or method-call contracts.

## Syntax and targets

```lua
---@type Pool
protected Fuel = null;

---@type Pool?
protected ReserveFuel = null;
```

A structured directive attaches to the following declaration in its declaration
scope. Whitespace and ordinary comments do not introduce a different target;
another declaration or a scope boundary does. Initially, type applies only to
LXC fields and properties, including static declarations.

Use structured line comments (`---@type` and `---@default`), not DOx block tags.
Unknown/invalid annotations and malformed declaration grammar are rejected while
parsing, including in a default candidate. Semantic validation and compilation
apply to selected declarations only. An annotation cannot cross a closing scope.

Keep directives distinct from ordinary comments and existing DOx blocks. Existing
DOx @param and @ret documentation must not acquire runtime semantics.

Initial type expressions name a supported non-nil Lua type or a resolvable LXC
class, optionally followed by ?. Do not implement unions, generic containers or
element-by-element table contracts now.

Unknown structured directives, unsupported targets, invalid arguments, duplicates,
and unresolved or ambiguous names produce clear compilation diagnostics.
Parameter/return annotations remain deferred, not active enforced directives.

Resolve names through the declaring namespace and using imports, respecting
visibility. Compilation and editor resolution must agree without executing
application code or depending on aliases published later by a loader.

## Stored-state validation

The compiled completion pass checks only annotated stored fields and applicable
property backing values:

- A declared class type accepts that class and compatible descendants.
- Non-nullable stored values must be compatible and non-null at completion.
- Nullable T? accepts a compatible value or LXC null at that boundary. Lua nil
  remains an invalid stored field value.
- false and zero remain valid values of their respective types.
- Visibility controls write authority, not separate instance deadlines. A child
  may initialize an accessible protected field before construction completes.
  It cannot directly assign a base class's private field; legitimate base-class
  initializer methods retain their own scope.
- Static deadlines belong to the declaring class, not a descendant's static body.
- Existing const/final access and binding restrictions take precedence. The
  directive grants no writes or deferred final initialization by descendants.
- Type validation does not impose numerical ranges or other application policies.

The declaration describes the expected completion value. Do not replace or widen
the existing inferred runtime field type merely to implement this check.
Likewise, T? does not override existing post-construction null-assignment rules.
It is not a promise of additional nullable-write behavior without a separately
approved change to LXC's existing type system.

Without type, preserve all current inference and initialization behavior.
Different constructor paths may establish different initial types for different
instances. Do not impose a required-value rule on unannotated fields.

## Properties

A stored property uses declaration initialization, automatic accessors, or the
contextual field backing-storage facility. Its annotated backing value
participates in the same single completion pass as an annotated field.

A computed property has custom accessor implementations without backing-storage
use or initialization. Its type annotation is compile-time/editor metadata:

```lua
---@type number
public Remaining {
    get {
        return this.Capacity - this.Used;
    }
}
```

Never invoke getters for construction, clone/load validation or editor analysis.
Do not persist/cache computed results or require an unused backing slot to be
initialized. Do not add getter-result, setter-input or setter-result checks.

For custom accessors on stored properties, validate the stored backing value only
at the permitted completion boundary. Existing ordinary storage checks remain.

Property overrides inherit the declared type/nullability metadata; conflicting
redeclarations are compilation errors. Consider effective concrete implementations
of abstract properties when determining whether meaningful backing storage exists.

Current LXC excludes abstract properties. An override cannot introduce a storage
type annotation where the original property had none. Equivalent class references
resolve to the same contract even when their annotation spellings differ.

Current LXC allocates property slots even when a custom getter ignores them.
Compilation tracks contextual backing-field use and automatic accessors rather
than deciding from slot existence. Stored original declarations retain their
contract through overrides. Unannotated slots and snapshot traversal are preserved.

## Cloning, persistence and LXE

Use private stored values and precompiled validation metadata at completion.
Preserve graph identity, inherited state and binding locks. Use existing failure
cleanup if a completion check fails; no usable partially validated result should
be returned.

Definitions supply the validation metadata. Saved payloads must not substitute
their own contracts or executable directive handlers.

LXE is an independent enum system loaded before classes. It owns enum
serialization/deserialization through generic serializer extensions and restores
canonical member identities. Its existing enum slot checks are unchanged. This
directive implementation does not add enum names to `@type` expressions.

## Default declarations

```lua
---@default
public class Creature {
    -- Used only when no ordinary declaration has this FQN.
}
```

`@default` takes no arguments and applies to classes, enums (including embedded
enum collections) and extensions. A single candidate loads normally. Two candidates
are allowed only when exactly one is marked default; the ordinary candidate wins.
Two defaults, two ordinary declarations, or more than two candidates are errors.
There is no priority chain, source-order preference or retry after initialization
failure. Already published identities cannot be replaced.

Selection occurs over a complete batch before dependency resolution, compilation
or application initialization. Discarding a class removes all its lexical members,
nested classes, inline enums and extensions. Discarding an enum removes its member
tree. External declarations are independent candidates: `within` refers to the
selected class by name; an external extension refers to the selected target enum.
Namespace-level extensions in a discarded enum's file are not inside that enum's
scope and remain candidates. Ordinary cross-kind/name collisions remain errors.

Extension identities are the resolved target enum FQN plus the method name.
Extensions may use the existing dotted declaration syntax from separate files in
the same batch. They acquire no additional private access and cannot attach to
already published enums.

## Parameter/return metadata and editor limits

Parameter and return annotations are documentation/editor metadata only. They
will never introduce runtime argument/return checks. They may describe multiple
acceptable types, optional values, varargs and multiple returns.

Editor support includes hover information, autocomplete details and signature
help when opening a method call, including the active parameter. Default parameter
values and their display remain future work.

Use shared definitions and static inference for clear initializers. Show unknown
when analysis cannot establish a type. Do not execute modules, constructors,
getters or arbitrary initializer expressions to obtain editor information.
Hover, completion and signature source tooling is implemented and tested without
executing application code. Live Pulsar rendering remains unverified.

## Implementation review

Before executable edits, trace parsing, validation, compilation, storage,
construction, properties and clone/load completion. Disclose unresolved findings.

Verify the single-pass budget, delayed child initialization, static deadlines,
primitive/subclass values, null/nil distinction, access/final restrictions,
stored/computed properties, overrides, custom clones, shared restored graphs,
failure cleanup, diagnostics and unchanged unannotated behavior.

Specifically prove that directive checks are absent from assignment, read,
accessor and method-call paths. Editor checks must prove analysis does not
execute application code. Record implementation evidence separately from design.

## Verification — 2026-10-30

The directive regression suite covers construction/static deadlines, inheritance,
stored/computed properties, nullability, canonical class contracts, clone/restore
graphs and failure cleanup, annotation diagnostics and declaration selection.
Instrumented boundaries verify one pass per construction/copy/restore and no
additional passes for field reads/writes, accessors or method calls. Custom copies
created through constructors are checked once after copying finishes.
Run `tests/directives_regression.lua` with Lua 5.4; its 114 behavioral checks pass.

The LXE suite passes 112 checks; the Pulsar source backend/editor suite passes 93
checks, including non-execution sentinels and external/default extensions. Loader
levels 0–5/options, collections, eventrix, I/O listing, metahook, primitives,
stringhook, XML and VFS pass. CoG Pool, Rarity defaults, object/affix, registry,
vehicle defaults and structure regressions pass. These are selected regressions,
not a claim that every repository suite or the live Pulsar UI was verified.
