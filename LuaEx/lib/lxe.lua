--[[!
@fqxn LuaEx.LXE.Guide
@desc <h3>Enum declarations, identities and values</h3>
    <p>Place .lxe declaration files under a package.path root before requiring LuaEx.init.
    LuaEx discovers them together with .lxc classes. A root enum is an immutable collection;
    its members are canonical objects rather than their raw payloads. Calling an enum or
    iterating pairs(enum) yields ordinal/member pairs in declaration order. String lookup
    selects an immediate member by name; numeric lookup selects its one-based ordinal.</p>
    <p>Value is the explicit payload or, when omitted, the member's ordinal. Ordinal is always
    its position within its immediate parent. Name is its declaration name; Parent is its
    immediate enum collection, or LuaEx null for a root collection. These metadata names
    are reserved and cannot be shadowed by members or extension methods.</p>
    <p>Payloads may be any non-nil Lua value, including false, tables, functions or another
    enum reference. Sibling payloads must be distinct: scalars compare by value, reference
    payloads by identity without invoking application equality. Different parents may reuse
    payloads. Mutable payload objects are retained by reference and are not recursively frozen.</p>
@ex namespace Example.Enums {
    public enum Vehicle {
        Car = 10 {
            Honda = "Honda";
            Toyota = "Toyota";
        }
        Motorcycle;
    }
}
-- Vehicle.Car is both a member of Vehicle and a collection of Honda/Toyota.
-- Car.Value is 10, Car.Ordinal is 1; Motorcycle.Value and Ordinal are both 2.
!]]

--[[!
@fqxn LuaEx.LXE.Grammar
@desc <h3>Declaration syntax and name resolution</h3>
    <p>Root declarations require a namespace. using imports names for resolution without
    executing modules. requires(Fully.Qualified.Enum) declares initialization dependencies;
    imports alone do not initialize a dependency. Unknown names and cycles fail preflight.</p>
    <p>A member requires a semicolon unless followed by an embedded member block; a semicolon
    after that block is optional. A value expression ends at its outer semicolon or embedded
    block. Parenthesize table-argument function calls when needed to disambiguate their braces.
    Explicit expressions execute once, in declaration order within the enum, after required
    enums are ready. An expression that returns nil is rejected rather than using an ordinal.</p>
    <p>Embedded enums are membership, not inheritance. Their qualified immediate-parent names
    define member types. Existing enums cannot be attached or reparented as children; using
    one as a payload creates a reference, not embedding. Visibility keywords apply to
    class-owned roots under LXC rules; other class modifiers are not automatically valid.</p>
!]]

--[[!
@fqxn LuaEx.LXE.Extensions.Guide
@desc <h3>Extensions belong to one exact enum</h3>
    <p>Declare extension EnumName.method(this, ...) at file, namespace or class declaration
    scope, before or after the target. A separate source file is permitted within the same
    complete loading batch. The first explicit parameter must be this. Invoke the method
    with a colon on a member of that exact enum. Additional parameters and a final vararg
    follow ordinary Lua rules; extension bodies run only when called.</p>
    <p>Methods do not propagate to parent or embedded child enums, gain no additional private
    access, and cannot collide with member names or metadata. Extensions cannot attach to
    already published enums. No methods are declared inside the enum member body.</p>
@ex namespace Example.Extensions {
    enum Vehicle { Car; Motorcycle; }
    extension Vehicle.isCar(this) {
        return this == Vehicle.Car;
    }
}
-- Example.Extensions.Vehicle.Car:isCar() returns true after loading.
!]]

--[[!
@fqxn LuaEx.LXE.Operators
@desc <h3>Operators use payloads without creating new members</h3>
    <ul><li>Equality compares canonical identity. Lua table equality against a scalar does
    not invoke enum equality; use Value when comparing a member with its raw payload.</li>
    <li>Ordering compares sibling payloads and rejects unrelated or unorderable operands.</li>
    <li>Arithmetic uses numeric payloads and accepts numeric scalar operands; results are numbers.</li>
    <li>Bitwise operations require integer payloads/scalars and return integers.</li>
    <li>Concatenation accepts string/number payloads and returns a string.</li>
    <li>Length counts immediate members; tostring returns the qualified declaration path.</li></ul>
    <p>Shared helpers are lxe.getByName(enum, name), lxe.getByValue(enum, value),
    lxe.isMember(member, enum) and lxe.isEnum(value). Membership is immediate-parent identity,
    not recursive ancestry. Embedded collections also satisfy isEnum.</p>
!]]

--[[!
@fqxn LuaEx.LXE.Loading
@desc <h3>Loading and class ownership</h3>
    <p>Use lxe.loadSources or lxe.loadFiles for standalone enum batches. Use lxc.loadSources
    or lxc.loadFiles for mixed class/enum batches and class-owned enums. In a mixed source map,
    .lxe keys select enum parsing; other keys select class parsing. Explicit load calls never
    locate missing dependency files implicitly. discover returns paths without loading them.</p>
    <p>The loader parses, selects default candidates, resolves names/dependencies and preflights
    collisions before evaluating payloads. Coordinated class bodies compile before enum payloads
    execute. Enums initialize before ordinary class static fields and constructors. Publication
    waits for the complete batch; failed identities are discarded. Application side effects
    from payloads or static constructors cannot be rolled back.</p>
    <p>Class ownership requires within Fully.Qualified.Class, even for a declaration inside its
    owner. Inline ownership must match the enclosing class. The owner must be declared in the
    same coordinated batch. A class-owned enum becomes static const storage with ordinary LXC
    access rules; its root Parent is still null. Ownership is independent of embedding.</p>
    <p>Never attach a new enum declaration to an initialized class. Assigning an already existing
    member to an eligible field later is ordinary value assignment, not late attachment.</p>
@ex namespace Example.Ownership {
    class Car {
        public enum Kind within Example.Ownership.Car { Sedan; Coupe; }
        public Car() { }
    }
}
!]]

--[[!
@fqxn LuaEx.LXE.Persistence.Guide
@desc <h3>Canonical references, not copies of enum definitions</h3>
    <p>Clone/save/load retains the canonical root, embedded collection or member identity.
    Declarations must already be loaded before restoration. Missing definitions fail instead
    of importing files or inventing lookalike values. Reference saves do not replay mutable
    payload contents or serialize extension implementation closures; loaded declarations
    remain authoritative. Runtime payload support does not imply arbitrary payload serialization.</p>
    <p>LXC uses a private connector to obtain canonical immediate-parent enum type constraints.
    Public metatable strings cannot impersonate those types. Caller-bound host persistence
    preserves private enum references under their storage owner's rights while rejecting
    escaping hidden references. Static saves include accessible mutable fields, excluding
    const/final enum declarations, and validate all assignments before committing any.</p>
    <p>Standalone LXC retains its restricted codec. Host-bound saves use the existing staged
    graph serializer rather than a separate enum-specific format. Trusted serialized input
    and compatible Lua bytecode remain requirements of that host format.</p>
!]]

--[[!
@fqxn LuaEx.LXE.Maintenance
@desc <h3>Implementation boundaries and verification</h3>
    <p>Parser records syntax without executing application code; Validation checks names,
    collisions and dependency order; Registry owns canonical identities; Runtime provides
    members/operators; Extensions compiles receiver-bound methods; Persistence reconnects
    identities; Loader coordinates the transaction. LXC delegates inline enum records from
    its token stream rather than rereading every class file.</p>
    <p>Keep class ownership/access in LXC and enum semantics in LXE. Preserve canonical identity,
    explicit dependencies, preflight-before-evaluation and all-before-commit static restore.
    Use portable Lua facades; debug-library intrusion is outside the protection boundary.
    Structured &#64;default selection is shared with LXC; &#64;type does not apply to enums.</p>
    <p>Run lua tests/run.lua --suite enums for current behavioral checks and
    --suite io-discovery for actual filesystem startup. Historical prototype totals,
    old loader levels and other-platform verification are not current evidence.</p>
!]]
--[[!
@fqxn LuaEx.LXE
@desc LXE loads immutable enum declarations from .lxe files and inline LXC
    declarations. LuaEx core supplies null, type hooks, and the generic serializer.
    Values remain canonical across clone/save/load. See the LXE Guide, Grammar, Loading and Persistence entries.
@ret table Enum loading and lookup helpers.
!]]
assert(luaex and null ~= nil, "Initialize LuaEx core before requiring LXE.");
return require("LuaEx.lib.lxe.Loader").create(null, require("LuaEx.lib.serializer"));

