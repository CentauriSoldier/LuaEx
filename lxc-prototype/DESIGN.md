# LXC class system design

## Authority and purpose

Production runtime: `LuaEx/lxc/init.lua` and `LuaEx/lxc/modules`.
The forwarding loader, tests, tools and documentation live in `lxc-prototype`.
The authorized scope also includes `LuaEx/load.lua` and required bundled `.lxc`
classes. Normal initialization installs LXC, discovers framework and application
roots recursively from package.path, and resolves dependencies within the batch.
Legacy `.lua` class implementations and core hooks remain unchanged. The owner
also authorized the focused staged graph extension in `LuaEx/lib/serializer.lua`.

LXC is a new class runtime with C#-guided declarations and Lua method bodies.
It does not translate into the existing LuaEx class implementation. C# guides
familiar behavior; it is not a compatibility standard. Lua 5.4 is the target.

This document consolidates the owner's agreed decisions, including the approved
completion package. Earlier repeated questions and superseded proposals have
been removed. Implementation was authorized by “let's build,” “keep going” and
“finish it.” Rules for future changes remain in RULES.md. Module contracts and
internal records are in ARCHITECTURE.md; executable contracts are in tests/.

## Three pillars and enforcement

Encapsulation, inheritance and polymorphism MUST apply correctly and WITHOUT
EXCEPTION. Performance, convenience and implementation difficulty cannot justify
weakening a pillar. Every non-debug intrusion is in scope: raw operations,
metatables, environments, reflection, callbacks, coroutines and escaped references.
Unrestricted debug access is the sole agreed exception. Restricted application
environments must withhold that facility. Report obstacles and evidence honestly;
a finite test suite is not a proof of every possible intrusion.

Access belongs to the executing function's declaring class. External callbacks
do not borrow the invoker's rights. Compiled closures retain their legitimate
lexical rights. Yields and errors must not leak context between calls/coroutines.
Tail-call elimination must not turn an external callback into privileged code.

Class references are checked where used. Holding, returning or aliasing an
inaccessible class does not authorize construction, statics or reference helpers.
A public method may return an instance of a private class. Its public members
remain usable; private state, its class factory and direct construction remain
restricted. Authorized methods may deliberately expose values or closures; the
runtime must not attach additional privileges to ordinary returned identities.

## Declarations and visibility

Sources contain namespace blocks and optional using declarations. Class bodies
contain fields, methods, properties, constructors and nested classes. Braces delimit
declarations; method bodies and initializer expressions use Lua syntax. Calls use
bound dot syntax: `object.method(arguments)`. Inner Lua functions retain `end`.

| Declaration | Default visibility |
| --- | --- |
| Namespace-level class | public |
| Nested class | private |
| Field, method, property | private |
| Explicit instance constructor | private |
| Generated constructor | its class's visibility |

Namespace classes must be public. Nested classes support public/private/protected;
effective access also includes every enclosing class's restrictions.
Public members are accessible through an existing instance. Private members belong
to their declaring class and its lexical nested classes. Protected members also
permit descendant declaring classes. Derived protected instance access requires a
receiver of that derived class or a descendant; it cannot target arbitrary base
or sibling instances. Owning-class methods retain cross-instance access.

Nesting and inheritance are distinct. Nested classes can access enclosing private
members through explicit objects; there is no implicit enclosing instance.
Enclosing classes gain no access to nested-private members. Sibling classes gain
no private access to one another merely through shared nesting.

A base-declared method can access base-owned private state on derived objects.
It cannot access private state introduced by the descendant. Separate private
scopes may reuse names without sharing storage or access rights.

## Fields, types and binding restrictions

An initialized field retains its established type. `null` is an uninitialized
placeholder; its first non-null assignment establishes its type. Reject nil
assignments and changing a typed field back to null. An instance-valued field
retains its original class constraint and accepts descendants without narrowing
that constraint after assignment. Lua expressions establish their actual value's
type; do not guess an expression's type from its first token.

`const` initializes in the declaration and forbids rebinding. Const cannot begin
null. No C# constant-expression requirement or implicit-static behavior is adopted.
`final` locks at the first non-null initialization. Declaration values count;
null does not. Otherwise initialization belongs to the declaring construction
context. Reject a second assignment even during construction. Instance finals
must be initialized when construction finishes; static finals by static completion.
An external callback cannot initialize a final merely because construction is active.

For tables, const/final protect the table reference, not its entries or subtables.
Recursive content protection is a separate user-invoked `lock(table)` function,
not a declaration modifier or automatic lifecycle step. It accepts tables only.
Its eventual home is `table.lock` in LuaEx's table hook. That utility is separate
from this class-system build; original-versus-copy, aliases/cycles and its return
contract remain future decisions. It does not authorize framework-hook edits.

At each inheritance level, initialize fields in source order before that level's
constructor. Finish parent construction before child fields and child body.
Each instance receives independently evaluated mutable initializer values.

## Constructors

One instance constructor per class; no overloads, inheritance or overriding.
Declare it with the class name and optional public/protected/private access.
If omitted, generate an empty parameterless constructor with class visibility.

An explicit `base(arguments)` must be the first constructor statement. Reject
late, duplicate, root-class or ordinary-method constructor calls at compilation.
Omission implies a parameterless immediate-parent call before the body. Parent
construction occurs exactly once and must be accessible. Parent arguments cannot
read an unconstructed instance. Arguments follow Lua rules, including nil for
missing values; there is no call-time arity checker. Constructors cannot return
values or replacement objects. Failed construction must not yield a usable
partially initialized instance, including one leaked through a callback.

## Inheritance and polymorphism

Single inheritance only; no fixed language-level ancestry-depth limit. Reject
cycles, inaccessible bases/parent constructors, final bases and derived declarations
whose effective access is wider than their base's nested accessibility domain.

Instance methods are overridable unless final. Require explicit `override` for
replacement or abstract implementation. The target must be accessible, non-final,
instance-owned and of the same member kind. Preserve visibility, declared named
parameter count and vararg status. Parameter names may differ. Validate these
contracts once at compilation; do not add automatic argument/return type checks
to ordinary method calls.

`base.method(...)` starts at the calling method's declaring class's immediate
parent and uses its inherited implementation if needed. It preserves the current
instance and normal access. It never dispatches back to the child's override.
A parent implementation may continue with its own base call. There is no
`base.base` or explicit ancestor selector to skip an intervening override.
Ordinary `this.method(...)` dispatches on the concrete instance.

`final class` forbids inheritance. `final` methods/properties forbid overrides.
Reject hiding of accessible inherited fields, statics, nested types or different
member kinds. Generated accessor names participate in collision checks. There
is no `new` hiding modifier or `virtual` requirement.

Use either `permits(Fully.QualifiedChild, ...)` or
`excludes(Fully.QualifiedChild, ...)` before the class body, never both.
These lists constrain direct children only; named children need not be loaded.
Reject empty, unqualified, duplicate or self entries. Final classes still forbid
all children regardless of lists.

Abstract classes cannot instantiate. Abstract methods have no body:
`public abstract run(arguments);`. They must be non-private, non-static and
non-final in an abstract class. Abstract descendants may defer implementation;
concrete descendants must resolve all contracts with compatible overrides.
Interfaces and abstract properties are excluded. Operators follow ordinary
method inheritance, override, final and abstract contracts.

## Operators and snapshot hooks

Lua 5.4 callable metamethods are in scope. Arithmetic has no implicit object
implementation: a declared or inherited operator must supply it. Empty Lua table
decoys support native equality through __eq. Binary operators accept one other
operand or two original operands, with left-before-right lookup. Missing equality
falls back to identity; identical tables skip __eq and ~= negates its result.
Lua 5.4 does not invoke table __eq against numbers, strings, booleans, nil or threads.
The __metatable, __mode and __name metadata remain runtime-owned.

Hidden storage and handlers are separate from every public decoy. Native rawset
can add entries that shadow public lookup, including fields, methods, properties,
class statics, helpers and API names; subsequent ordinary writes to existing raw
keys also bypass __newindex. These entries neither reveal nor replace hidden slots.
Removing an entry restores checked lookup. Compiler lexical views continue to use
hidden slots for rewritten qualified access. Clone and persistence copy registered
backing state, ignoring raw decoy entries. This is a concrete table consequence,
not a blanket exception to hidden-storage access requirements.

The clone operator returns a distinct instance of the same concrete class.
Serialization and deserialization select the most-derived inherited operator,
passing its declaring level's field projection as {pri={}, pro={}, pub={}}.
The operator replaces known projected field values in place; its return value
is unused. Serialization leaves original slots unchanged. Deserialization runs
after graph allocation and applies changes subject to type and binding locks.
These operators do not run during cloning. Legacy per-level snapshot hooks
remain supported and run before the corresponding operator at that level.

## Static state

Use static fields/methods through a class qualifier. Static methods have no
implicit this/base and cannot override or hide inherited statics. Accessible
inherited statics may be qualified through descendants but retain the declaring
class's single storage and method access rights.

Initialize static state once at successful class load: dependencies/parent first,
fields in source order, then one optional `static ClassName()` constructor.
It has no parameters, visibility modifier, injected static-data parameter or
manual call form. It can read/write its own private static values through its
class name, under ordinary typing and binding rules. There is no pre-build
initializer. Failed static initialization discards the load batch.

## Properties and accessor methods

Both direct property syntax and named accessor methods are required. Example:

```csharp
public Health {
    get("read") { return field; }
    private set { field = value; }
} = 100;
```

Automatic accessors use `get;` / `set;`. Custom accessors use Lua bodies.
`field` denotes the current property's hidden typed backing storage; setter input
is `value`. Use this for other instance members and the class name for statics.
Lua table keys/selectors named field are ordinary keys, not backing references.
Accessor words are contextual; ordinary Lua locals and parameters retain lookup.

Default named prefixes are get/set. Optional quoted per-accessor prefixes, such
as get("is"), generate prefix plus the property name without renaming the direct
property. Prefixes must be identifiers; generated names must be distinct and
must not collide with other visible declarations/accessors.

Properties do not change access rules. Accessors may narrow visibility, never
widen it. Direct and named access execute identical accessors and enforce the
same storage type and const/final binding restrictions, including custom writes.
No setter means no setter operation, including in a constructor. It does not
implicitly lock storage or returned table contents. Reading/writing the same
property through this re-enters its accessor; use field for backing state.

Non-final instance properties permit explicit override. Preserve property and
accessor visibility, accessor presence, original prefixes/generated names, and
the original storage contract. An override cannot reinitialize storage. Every
instance has one original-declaration-owned slot shared by base and overriding
accessors. This/base selects behavior, not a separate value. Static properties
cannot be hidden or overridden. Fields/methods cannot replace properties.
Access checks use the original overridden declaration's contract, including its
accessors, so dynamic selection does not revoke a base method's existing rights.

These rules follow POLA: explicit access/binding modifiers mean the same thing
through every supported access route; no hidden property privileges are added.

## Name resolution, imports and dependencies

Preserve normal Lua locals, parameters, nested scopes and closures. Require
this.member / other.member for instances and ClassName.member for statics.
Class lookup searches the nearest class and its accessible inherited nested types,
then enclosing classes outward, then current namespace,
then imported namespaces, then supplied environment bindings. Relative qualified
base names resolve through the same scope search. Fully qualified names
still obey access. Ambiguous unqualified class references fail at compilation;
a local/parameter of the same name is not a class reference. Strings, comments,
labels and table keys must not be mistaken for variable references.

`using Namespace;` imports names without granting access or initialization order.
File imports apply to following namespace blocks; namespace imports precede its
classes and remain local to that namespace block. Nested classes inherit imports.
`requires(Fully.QualifiedClass, ...)` explicitly orders initialization dependencies;
inheritance already implies a dependency. Reject missing/inaccessible requirements
and dependency cycles. Do not silently load arbitrary dependency files.

## Helpers and persistence

The read-only class helper API returns names/booleans or explicitly scope-checked
references. It never exposes registries, backing tables, environments or privileged
views. `getname` may describe a held private-class instance without exposing its
factory. `getbyname` returns a class reference only where visible.
`isinstanceof` is exact; `isa` includes descendants. `ischild` excludes self.
Parent/base names and fresh sorted direct-child-name lists remain metadata.
See README.md for the public function signatures.

Class definitions load from source; saves do not embed executable definitions.
Versioned snapshots preserve concrete identity, inherited state, graph aliases,
cycles and binding locks. Restore validated state without constructors. Classes
must already be loaded. Clones preserve concrete class identity while independently
copying mutable graph state. In the standalone data-only codec, unsupported functions, native resources, metatable-
bearing foreign tables, foreign typed containers and nonfinite values fail explicitly.

Normal LuaEx host saves delegate application functions and supported foreign values
to the existing trusted Lua-code serializer. Its additive serializeStaged and
deserializeStaged API accepts a private host adapter. HostStaged projects typed
slots, validates class-reference authority before allocation, and fills staged
LXC identities after ordinary tables, callbacks and foreign factories restore.
It preserves callback aliases, captured references and shared upvalue cells.
Global `_ENV == _G` retains the serializer's current-runtime binding. Compiler/runtime
closures are rejected; captured class references remain scope checked. Host saves use
`--LXC:3`; older `--LXC:1` data and `--LXC:2` envelope saves remain readable. This executable
format requires trusted input. Version-one ordinary graphs retain their format;
staged graphs use version two. Cycles through LXC state can cross existing typed
containers; eager object cycles that require their own staged allocation reject.
Every allocated LXC shell is invalidated when restoration or validation fails.

Persistence is an explicitly controlled host service. Instance snapshots contain
private/protected/public storage, so the root persistence capability is not
injected into class environments automatically. The host chooses its authorized
recipients; a deliberately authorized export discloses its saved values. Restoring
private-class instances does not grant hidden class-reference or general factory
access. Saving/restoring exposed class references still checks using-scope visibility.
References inside encapsulated storage may retain the declaring scope's authority;
forged data must not transplant a hidden factory into unrelated or exposed storage.

Validate graph schema, references, field identities, type/value agreement and
binding locks before returning a graph. Statically known literal/table and direct-constructor constraints are
checked against declarations. Dynamic initializer/const state is saved per slot;
restoration must not execute an initializer to rediscover it. Snapshots are not
cryptographically authenticated; they are not proof of original field contents.

Static persistence is separate and explicit. Save/restore mutable fields accessible
to the calling scope, retaining inherited storage identity. Do not restore readonly
fields or modify an instance's shared static state implicitly. Validate a complete
static restoration plan before applying writes.

## Loading, failure and acceptance

Support in-memory source maps, explicit file lists and optional filesystem discovery.
Already-loaded classes may satisfy dependencies. Parse/validate/compile the complete
batch before running its static initializers. Stage all new identities before
publication. Failed batches publish no classes, commit no registry entries and
invalidate leaked staged references. Reject reentrant loading; recheck publication
bindings after callbacks. External initialization side effects cannot be rolled back.

Diagnostics identify source file, line, class and member where available. Reject
unsupported or contradictory syntax explicitly. Keep modules focused and documented,
with tests for successful behavior and rejected operations. Measure dispatch,
properties, construction, cloning and persistence rather than asserting speed.

README.md records reproducible checks and measured results. Future findings that
change semantics require agreement and automatic documentation updates; test failures
are fixed without weakening these contracts.
