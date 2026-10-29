--[[!
@fqxn LuaEx.LXC
@desc <h3>LXC — classes written for Lua</h3><p>LXC adds a declaration language and a Lua 5.4 runtime to LuaEx.
    Write classes in .lxc source files using namespaces, access modifiers, constructors, methods and properties;
    write ordinary Lua inside method and accessor bodies. The loader validates declarations, compiles their
    bodies, initializes static state and publishes callable class objects.</p><p>A class describes a type;
    calling it constructs an instance. Each instance has private storage, while static members belong to the
    class. Access checks follow the class that authored the calling code. Inheritance preserves private storage,
    supports explicit method/property overrides and enforces final/abstract contracts.</p><nav aria-label="LXC
    guide"><ul><li><a href="#LuaEx.LXC.QuickStart">Start here</a></li><li><a href="#LuaEx.LXC.Keywords">Keywords
    — the language reference</a></li><li><a href="#LuaEx.LXC.Syntax">Declaration syntax</a></li><li><a
    href="#LuaEx.LXC.Properties">Properties and accessors</a></li><li><a
    href="#LuaEx.LXC.Inheritance">Inheritance and access</a></li><li><a
    href="#LuaEx.LXC.Operators.Reference">Operator reference</a></li><li><a href="#LuaEx.LXC.Typing">Values,
    types and binding locks</a></li><li><a href="#LuaEx.LXC.Persistence.Guide">Copying and saving</a></li><li><a
    href="#LuaEx.LXC.Loading">Loading and discovery</a></li><li><a href="#LuaEx.LXC.Modules">How the modules fit
    together</a></li></ul></nav><h4>Capabilities at a glance</h4><ul><li>Namespaces and using imports; nested
    public/protected/private classes.</li><li>Single inheritance, dependency ordering and direct-child
    restrictions.</li><li>Automatic/custom accessors with generated callable aliases.</li><li>Typed storage,
    null-before-typing, const/final binding locks.</li><li>Instance operators, bound methods and lexical access
    across closures.</li><li>Graph-aware copying and snapshots preserving shared
    references/cycles.</li></ul><p>The returned LXC object exposes loading, class helpers, null, clone,
    serialization and static snapshots. Internal module entries below explain implementation relationships; they
    are documentation paths, not fields on that public object. LuaEx initializes and binds LXC normally;
    standalone use can load source maps without initializing LuaEx.</p>
@requires Lua 5.4 and the debug library.
@pulsarlua table lxc
!]]
--[[!
@fqxn LuaEx.LXC.QuickStart
@desc <h3>A complete first class</h3><p>Run this Lua with the repository on package.path. The source map uses a
    diagnostic filename; no .lxc file is written. Namespace publication creates Example.Counter in the supplied
    environment. Methods are already bound: use dot calls and pass only declared arguments.</p>
@ex local LXC = require("LuaEx.lib.lxc");
local tEnvironment = {};
LXC.loadSources({["Counter.lxc"] = [=[
namespace Example {
    public class Counter {
        public Count { get; private set; } = 0;
        public Counter(nStart) { this.Count = nStart; }
        public Increment() { this.Count = this.Count + 1; }
    }
}
]=]}, tEnvironment);
local oCounter = tEnvironment.Example.Counter(4);
oCounter.Increment();
assert(oCounter.Count == 5);
assert(LXC.class.getname(oCounter) == "Example.Counter");
!]]
--[[!
@fqxn LuaEx.LXC.Syntax
@desc <h3>The shape of an LXC file</h3><p>A file contains using declarations and one or more namespace blocks;
    each block contains classes. Namespace-local using declarations must precede classes. Namespace names and
    parent references use dot-separated valid identifiers. Class bodies contain fields, methods, properties and
    nested classes. Field initializers and abstract method declarations end with semicolons; method bodies use
    braces around Lua statements.</p><p>Parameters are untyped names with an optional final ...; this/base are
    supplied by LXC. Lua bodies keep normal Lua locals, loops, functions and return semantics.
    Constructors/static constructors must return no values. Implicit global writes are rejected; mutate an
    explicitly supplied host object when shared external state is intended. _ENV and __lxc-prefixed tokens are
    compiler-reserved.</p>
@ex using Shared.Types;
namespace Example.Syntax {
    using Other.Types;
    public abstract class Shape {
        protected scale = 1;
        public abstract Area();
        protected Reset() { this.scale = 1; }
    }
}
!]]
--[[!
@fqxn LuaEx.LXC.Typing
@desc <h3>Values, types and binding locks</h3><p>Fields and property backing storage cannot contain nil. Missing
    initializers start at LXC.null. The first non-null value establishes a storage type; afterwards the slot
    cannot return to null or change type. An LXC instance initializer establishes a class constraint that
    accepts that class and its descendants. A class object has the class-reference type; ordinary tables have
    table type.</p><p>const requires declaration initialization and locks the binding. final storage may be
    initialized in its declaration or assigned its first non-null value from its declaring constructor/static
    constructor; it must be initialized when that phase ends. A locked table binding does not recursively freeze
    table contents. final methods/properties prohibit overriding; final classes prohibit inheritance. Property
    overrides retain the original storage/type/lock.</p>
@ex namespace Example.Values {
    public class Settings {
        public const Label = "Demo";
        public final Owner;
        public Pending;
        public Settings(sOwner) {
            this.Owner = sOwner;
            this.Pending = 1;
        }
    }
}
!]]
--[[!
@fqxn LuaEx.LXC.Properties
@desc <h3>One value, controlled ways to read and write it</h3><p>A property declares get and/or set accessors.
    Semicolon accessors automatically read/write its backing value. A custom body uses field for that value and
    a setter uses implicit value for its incoming argument. Accessors may narrow visibility relative to the
    property. A const property cannot have a setter.</p><p>Every accessor also creates a bound callable alias by
    directly concatenating its prefix and property name: getHealth/setHealth. A quoted prefix replaces get/set;
    there is no automatic capitalization or inserted separator. Alias collisions are rejected. A saved alias
    checks access again when called. Overriding a property must preserve accessor presence/visibility/prefixes
    and cannot reinitialize its backing value.</p>
@ex namespace Example.Properties {
    public class Meter {
        public Health {
            get("read") { return field; }
            private set { field = math.max(0, value); }
        } = 10;
        public Meter() { }
        public Damage(nAmount) { this.Health = this.Health - nAmount; }
    }
}
-- With this source loaded: oMeter.Health and oMeter.readHealth()
-- both read the same backing value. Damage may use its private setter.
!]]
--[[!
@fqxn LuaEx.LXC.Inheritance
@desc <h3>Inheritance follows both declaration and receiver</h3><p>Use a colon for one parent. Accessible
    inherited methods/properties require explicit override; ordinary hiding is forbidden. Overrides preserve
    visibility, method parameter count and vararg shape. Same-name inaccessible private declarations can remain
    separate storage. Public is callable externally; private admits the declaring class and lexical nested
    descendants; protected additionally admits derived classes.</p><p>Protected instance access has a receiver
    rule: a derived class can use its own receiver branch, not an unrelated sibling instance. Nested types must
    satisfy every enclosing visibility restriction. A derived type cannot expose a less accessible nested
    base.</p><p>Construction is parent-first. An explicit base(...) must be the constructor's unique first
    statement; arguments cannot access unconstructed this/base. Without it the parent receives no arguments.
    Each level then initializes its instance fields and runs its constructor. Static fields/static constructors
    run once in validated parent/requires order before publication.</p>
@ex namespace Example.Inheritance {
    public class Base {
        public Health { get; protected set; } = 10;
        public Base(nHealth) { this.Health = nHealth; }
        public Describe() { return "base"; }
    }
    public class Child : Base {
        public Child(nHealth) { base(nHealth); }
        public override Describe() { return base.Describe() .. " child"; }
        public override Health {
            get { return field; }
            protected set { field = math.max(0, value); }
        }
    }
}
!]]
--[[!
@fqxn LuaEx.LXC.Loading
@desc <h3>From source text to published classes</h3><ol><li><strong>Discover/read:</strong> discover extracts
    roots from package templates and lists .lxc files; loadFiles reads them, or loadSources accepts a plain
    filename-to-text map.</li><li><strong>Parse/validate:</strong> all class names must be unique;
    parent/requires dependencies are resolved and cycles rejected.</li><li><strong>Prepare/initialize:</strong>
    create every facade, compile bodies, then initialize static storage in dependency
    order.</li><li><strong>Publish:</strong> check destination bindings again, register definitions and insert
    namespace tables/class objects.</li></ol><p>Existing plain namespace tables can be reused; existing class
    leaves cannot be overwritten. Reentrant loading is forbidden. Initialization failure prevents publication
    and marks the batch discarded, but cannot undo side effects in application callbacks. The runtime keeps
    published definitions for subsequent batches.</p><p>LuaEx.load binds the host, discovers bundled/application
    classes and adds short aliases for top-level LuaEx.Classes types. Standalone source-map loading needs no
    io.listfiles; discover needs that filesystem service. Public APIs are read-only facade members.</p>
@ex -- Direct source-file loading, after choosing the source paths:
local LXC = require("LuaEx.lib.lxc");
local tEnvironment = setmetatable({}, {__index = _G});
-- local tNames = LXC.loadFiles({"MyProject/Counter.lxc"}, tEnvironment);
-- Discovery requires LuaEx's io.listfiles (or a compatible host service):
-- local tPaths = LXC.discover("MyProject/?.lua");
!]]
--[[!
@fqxn LuaEx.LXC.Persistence.Guide
@desc <h3>Copying and saving graphs</h3><p>LXC.clone copies live graphs with shared references/cycles. Scalars,
    null and ordinary functions retain identity; class references remain class references when visible.
    Automatic instance copies bypass constructors, preserve storage contracts and run validation once the graph
    is complete. A clone operator may create a custom distinct same-class instance; register it through bound
    cloner.registerCopy before recursively copying cyclic contents.</p><p>LXC.serialize/deserialize are
    standalone restricted snapshots: finite scalar values, null, plain tables, class identities and instances.
    Snapshot strings are limited to 16 MiB, graph nodes to 100000 and literal nesting below 256 levels. Restore
    requires matching registered class definitions, exact fields, compatible saved types and binding locks; it
    does not migrate schemas. Saving a class identity does not capture static state: use saveStatic/loadStatic
    for accessible mutable statics.</p><p>After bindHost, global serialize/deserialize use the LuaEx staged
    serializer for foreign host values and application closures as well. Runtime/class closures are rejected as
    application code. Current host output adds --LXC:3 when needed; older --LXC:1 and --LXC:2 imports remain
    routed by Host.</p><h4>Class-owned hooks</h4><p>prepareSnapshot(projection) edits outgoing pri/pro/pub
    replacements concrete-first without replacing original slots; referenced objects are shallow, so do not
    mutate source tables in preparation. validateSnapshot(projection) runs parent-first after
    restoration/automatic copy, and may update values only within normal type/lock rules. Selected
    serialize/deserialize operators integrate at their declaring level; deserialize operators run for restore,
    not generic live-copy validation.</p>
@ex local LXC = require("LuaEx.lib.lxc");
local tSource = {Score = 3};
tSource.Self = tSource;
local tCopy = LXC.clone(tSource);
assert(tCopy ~= tSource and tCopy.Self == tCopy);
local tRestored = LXC.deserialize(LXC.serialize(tSource));
assert(tRestored.Self == tRestored and tRestored.Score == 3);
!]]
--[[!
@fqxn LuaEx.LXC.Modules
@desc <h3>The module map</h3><p>The entry point loads private factories from its sibling lxc directory. Loader
    injects dependencies, so registries stay inside closures and application code receives only a read-only
    facade.</p><table class="table table-striped
    table-bordered"><thead><tr><th>Layer</th><th>Modules</th><th>Contribution</th></tr></thead><tbody><tr><th>Source</th><td><a
    href="#LuaEx.LXC.Tokens">Tokens</a>, <a href="#LuaEx.LXC.Names">Names</a>, <a
    href="#LuaEx.LXC.Operators">Operators</a>, <a href="#LuaEx.LXC.Parser">Parser</a>, <a
    href="#LuaEx.LXC.LuaScope">LuaScope</a>, <a href="#LuaEx.LXC.Compiler">Compiler</a></td><td>Recognize
    declarations and compile their Lua bodies.</td></tr><tr><th>Rules</th><td><a
    href="#LuaEx.LXC.Model">Model</a>, <a href="#LuaEx.LXC.Validation">Validation</a>, <a
    href="#LuaEx.LXC.Context">Context</a>, <a href="#LuaEx.LXC.Environment">Environment</a>, <a
    href="#LuaEx.LXC.Diagnostics">Diagnostics</a></td><td>Resolve names, validate contracts and retain lexical
    access context.</td></tr><tr><th>Objects</th><td><a href="#LuaEx.LXC.Runtime">Runtime</a>, <a
    href="#LuaEx.LXC.Facades">Facades</a>, <a href="#LuaEx.LXC.Helpers">Helpers</a></td><td>Own state and expose
    checked class/instance operations.</td></tr><tr><th>Graphs</th><td><a
    href="#LuaEx.LXC.GraphClone">GraphClone</a>, <a href="#LuaEx.LXC.Persistence">Persistence</a>, <a
    href="#LuaEx.LXC.Literal">Literal</a>, <a href="#LuaEx.LXC.SnapshotSchema">SnapshotSchema</a>, <a
    href="#LuaEx.LXC.GraphAccess">GraphAccess</a>, <a
    href="#LuaEx.LXC.SnapshotHooks">SnapshotHooks</a></td><td>Copy, project, validate and restore identity
    graphs.</td></tr><tr><th>Integration</th><td><a href="#LuaEx.LXC.Loader">Loader</a>, <a
    href="#LuaEx.LXC.Host">Host</a>, <a href="#LuaEx.LXC.HostGraph">HostGraph</a>, <a
    href="#LuaEx.LXC.HostStaged">HostStaged</a></td><td>Publish classes and connect host
    services.</td></tr></tbody></table>
!]]
--[[!
@fqxn LuaEx.LXC.class
@desc <h3>Class metadata helpers</h3><p>The read-only helper facade is available as LXC.class, as class inside
    compiled declarations, and as global class after bindHost. Names are fully qualified. Queries that expose
    classes/relationships honor caller visibility; raw is/isinstance predicates only recognize
    identities.</p><ul><li><a href="#LuaEx.LXC.class.getname">getname</a></li><li><a
    href="#LuaEx.LXC.class.is">is</a></li><li><a href="#LuaEx.LXC.class.isinstance">isinstance</a></li><li><a
    href="#LuaEx.LXC.class.exists">exists</a></li><li><a
    href="#LuaEx.LXC.class.getbyname">getbyname</a></li><li><a
    href="#LuaEx.LXC.class.isinstanceof">isinstanceof</a></li><li><a
    href="#LuaEx.LXC.class.isa">isa</a></li><li><a href="#LuaEx.LXC.class.ischild">ischild</a></li><li><a
    href="#LuaEx.LXC.class.getparentname">getparentname</a></li><li><a
    href="#LuaEx.LXC.class.getbasename">getbasename</a></li><li><a
    href="#LuaEx.LXC.class.getchildnames">getchildnames</a></li></ul>
@pulsarlua table class
!]]
--[[!
@fqxn LuaEx.LXC.null
@desc <h3>An untyped value waiting for initialization</h3><p>The read-only null singleton represents
    uninitialized storage. It is distinct from nil; nil is forbidden for declared fields. A slot may stay null
    until its first non-null value fixes a type, but cannot return to null afterwards. Initialized LuaEx
    supplies its existing singleton; standalone LXC creates its own opaque null reference.</p>
@pulsarlua table lxc.null
!]]
--[[!
@fqxn LuaEx.LXC.Keywords
@desc <h3>Keywords — read the language one declaration at a time</h3><p>These entries describe LXC reserved
    words and its contextual property bindings. Examples marked as fragments belong in an appropriate
    namespace/class/property; QuickStart shows a complete loadable example.</p><table class="table table-striped
    table-bordered"><thead><tr><th>Word</th><th>Purpose</th></tr></thead><tbody><tr><td><a
    href="#LuaEx.LXC.Keywords.namespace">namespace</a></td><td>Group classes under a qualified
    name.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.using">using</a></td><td>Import a namespace for
    unqualified class lookup.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.class">class</a></td><td>Declare a
    type with instance/static members.</td></tr><tr><td><a
    href="#LuaEx.LXC.Keywords.public">public</a></td><td>Allow external use of a
    declaration.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.private">private</a></td><td>Restrict access to
    the declaring lexical class family.</td></tr><tr><td><a
    href="#LuaEx.LXC.Keywords.protected">protected</a></td><td>Allow declaring, lexical and inheritance
    scopes.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.static">static</a></td><td>Put a member on the class
    instead of each instance.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.final">final</a></td><td>Lock a
    storage binding or prohibit an override/derivation.</td></tr><tr><td><a
    href="#LuaEx.LXC.Keywords.const">const</a></td><td>Initialize and lock a storage binding at
    declaration.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.abstract">abstract</a></td><td>Declare an
    incomplete class or method contract.</td></tr><tr><td><a
    href="#LuaEx.LXC.Keywords.override">override</a></td><td>Explicitly replace an accessible inherited
    method/property.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.permits">permits</a></td><td>Allow only
    listed direct subclasses.</td></tr><tr><td><a
    href="#LuaEx.LXC.Keywords.excludes">excludes</a></td><td>Reject listed direct
    subclasses.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.requires">requires</a></td><td>Order explicit
    class initialization prerequisites.</td></tr><tr><td><a
    href="#LuaEx.LXC.Keywords.operator">operator</a></td><td>Declare a supported public instance
    operation.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.get">get</a></td><td>Read a property automatically
    or through a Lua body.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.set">set</a></td><td>Write a property
    automatically or through a Lua body.</td></tr><tr><td><a
    href="#LuaEx.LXC.Keywords.field">field</a></td><td>Use the current property's private backing
    value.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.value">value</a></td><td>Use the incoming setter
    argument.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.null">null</a></td><td>Represent storage that has
    not established its type.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.this">this</a></td><td>Refer to the
    current instance.</td></tr><tr><td><a href="#LuaEx.LXC.Keywords.base">base</a></td><td>Select parent
    behavior or forward constructor arguments.</td></tr></tbody></table><p>Ordinary Lua keywords remain Lua
    syntax inside bodies: and, break, do, else, elseif, end, false, for, function, goto, if, in, local, nil,
    not, or, repeat, return, then, true, until, while. Lua declaration bodies are not a separate replacement for
    Lua. _ENV and the __lxc prefix are compiler-reserved; see Names.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.namespace
@desc <h3>namespace — Group classes under a qualified name.</h3><div class="card mb-3"><div
    class="card-body"><p>Top-level declaration container; may contain using declarations before classes.
    Multiple namespace blocks are allowed. Publication creates namespace tables in the supplied
    environment.</p><p><strong>Example context:</strong> Complete namespace declaration.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex namespace Example.Tools { public class Marker { } }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.using
@desc <h3>using — Import a namespace for unqualified class lookup.</h3><div class="card mb-3"><div
    class="card-body"><p>Write using Qualified.Namespace; at file scope or at the beginning of a namespace
    block. It does not import a single class or create an alias. Current/lexical namespace lookup wins before
    imports; conflicting imported class matches fail.</p><p><strong>Example context:</strong> Complete namespace
    declaration.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex using Example.Shared;
namespace Example.Tools { public class Marker { } }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.class
@desc <h3>class — Declare a type with instance/static members.</h3><div class="card mb-3"><div
    class="card-body"><p>Every class belongs to a namespace or an enclosing class. Namespace classes default
    public and must be public; nested classes default private. The class name identifies its constructor.
    Fields/methods/properties default private.</p><p><strong>Example context:</strong> Complete namespace
    declaration.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex namespace Example { public class Marker { public Marker() { } } }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.public
@desc <h3>public — Allow external use of a declaration.</h3><div class="card mb-3"><div
    class="card-body"><p>Applies to namespace/nested classes, members and instance constructors. An accessor
    cannot be more visible than its property; an override preserves the inherited
    visibility.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the enclosing
    class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public Count { get; private set; } = 0;
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.private
@desc <h3>private — Restrict access to the declaring lexical class family.</h3><div class="card mb-3"><div
    class="card-body"><p>The declaring class and lexical nested descendants may access private declarations;
    inheritance alone does not grant private access. Members and nested classes default
    private.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the enclosing
    class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex private count = 0;
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.protected
@desc <h3>protected — Allow declaring, lexical and inheritance scopes.</h3><div class="card mb-3"><div
    class="card-body"><p>Derived code also obeys the protected receiver restriction: it may use its own receiver
    branch, not an unrelated sibling instance. A protected accessor can narrow a public
    property.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the enclosing
    class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public Health { get; protected set; } = 10;
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.static
@desc <h3>static — Put a member on the class instead of each instance.</h3><div class="card mb-3"><div
    class="card-body"><p>Use ClassName.Member, not this.Member. Static bodies cannot use implicit this/base.
    static ClassName() is the parameterless static constructor; it cannot have explicit visibility. Static
    members cannot override/hide inherited accessible members.</p><p><strong>Example context:</strong>
    Declaration/body fragment; supply the enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public static Count = 0;
static Counter() { Counter.Count = Counter.Count + 1; }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.final
@desc <h3>final — Lock a storage binding or prohibit an override/derivation.</h3><div class="card mb-3"><div
    class="card-body"><p>A final class cannot be inherited; a final method/property cannot be overridden. Final
    storage locks at its first non-null assignment and must be initialized by the end of its declaring
    construction/static phase. Referenced table contents are not recursively frozen.</p><p><strong>Example
    context:</strong> Declaration/body fragment; supply the enclosing class/property and referenced
    declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public final Owner;
public Settings(sOwner) { this.Owner = sOwner; }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.const
@desc <h3>const — Initialize and lock a storage binding at declaration.</h3><div class="card mb-3"><div
    class="card-body"><p>Requires a non-null declaration initializer; cannot be combined with final or applied
    to methods/classes. A const property has no setter. Binding immutability does not freeze referenced table
    contents.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the enclosing
    class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public const Title = "Example";
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.abstract
@desc <h3>abstract — Declare an incomplete class or method contract.</h3><div class="card mb-3"><div
    class="card-body"><p>An abstract class cannot be instantiated. Only methods may declare abstract member
    contracts, with a semicolon instead of a body, in an abstract owning class. They cannot be
    private/static/final/const; concrete descendants must implement them with override.</p><p><strong>Example
    context:</strong> Declaration/body fragment; supply the enclosing class/property and referenced
    declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public abstract class Shape { public abstract Area(); }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.override
@desc <h3>override — Explicitly replace an accessible inherited method/property.</h3><div class="card mb-3"><div
    class="card-body"><p>Required when an accessible inherited member is redeclared. Keeps kind/visibility and
    method parameter-count/vararg shape. Properties retain original backing storage and accessor contracts;
    fields/static members cannot override.</p><p><strong>Example context:</strong> Declaration/body fragment;
    supply the enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public override Describe() { return base.Describe() .. " child"; }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.permits
@desc <h3>permits — Allow only listed direct subclasses.</h3><div class="card mb-3"><div
    class="card-body"><p>Class-header clause with a nonempty unique list of fully qualified child names. Checked
    for each immediate child, not as a transitive allowlist. Cannot combine with excludes; not a dependency
    declaration.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the enclosing
    class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public class Base permits(Example.Child) { }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.excludes
@desc <h3>excludes — Reject listed direct subclasses.</h3><div class="card mb-3"><div
    class="card-body"><p>Class-header clause with fully qualified child names. Entries must be unique/nonempty
    and cannot name the class itself. Cannot combine with permits.</p><p><strong>Example context:</strong>
    Declaration/body fragment; supply the enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public class Base excludes(Example.Blocked) { }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.requires
@desc <h3>requires — Order explicit class initialization prerequisites.</h3><div class="card mb-3"><div
    class="card-body"><p>Class-header clause with fully qualified accessible class names. Required definitions
    initialize before this class; cycles with inheritance/other requires fail. It does not add methods, inherit
    storage or import short names.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the
    enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public class Consumer requires(Example.Provider) { }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.operator
@desc <h3>operator — Declare a supported public instance operation.</h3><div class="card mb-3"><div
    class="card-body"><p>Follow with a supported symbol, named alias or canonical metamethod name and
    parameters. Hidden this is not counted. Operators follow ordinary override/final rules plus
    operation-specific arity. See the operator reference.</p><p><strong>Example context:</strong>
    Declaration/body fragment; supply the enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public operator +(other) { return this.Value + other.Value; }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.get
@desc <h3>get — Read a property automatically or through a Lua body.</h3><div class="card mb-3"><div
    class="card-body"><p>Contextual accessor word inside a property. get; returns backing storage; get { ... }
    provides custom code using field. Optional get("prefix") changes the generated callable alias. Accessor
    visibility may narrow the property.</p><p><strong>Example context:</strong> Declaration/body fragment;
    supply the enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public Score { get; private set; } = 0;
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.set
@desc <h3>set — Write a property automatically or through a Lua body.</h3><div class="card mb-3"><div
    class="card-body"><p>Contextual accessor word inside a property. set; assigns implicit value; custom code
    uses value and field. Optional set("prefix") changes the alias. A missing/inaccessible setter rejects
    writes; const forbids setters.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the
    enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public Score { get; set { field = math.max(0, value); } } = 0;
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.field
@desc <h3>field — Use the current property's private backing value.</h3><div class="card mb-3"><div
    class="card-body"><p>Contextual implicit binding inside custom accessors, not an ordinary declared member.
    Compiler rewrites it to checked storage reads/writes; it is unavailable as a general field shortcut in
    methods. Locally shadowed bindings follow Lua scope analysis.</p><p><strong>Example context:</strong>
    Declaration/body fragment; supply the enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex get { return field; }
set { field = math.max(0, value); }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.value
@desc <h3>value — Use the incoming setter argument.</h3><div class="card mb-3"><div
    class="card-body"><p>Implicit parameter in set bodies. Reading returns the value the caller assigned; assign
    it to field to store it, possibly after normalization. It is a contextual parameter, not a globally reserved
    declaration word.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the enclosing
    class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex set { field = math.max(0, value); }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.null
@desc <h3>null — Represent storage that has not established its type.</h3><div class="card mb-3"><div
    class="card-body"><p>Implicit LXC singleton in compiled bodies and public LXC.null outside. Unlike nil it
    may occupy an untyped field. First non-null assignment fixes type and prevents returning to null. Const
    cannot start null.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the enclosing
    class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public Pending;
public Ready() { return this.Pending ~= null; }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.this
@desc <h3>this — Refer to the current instance.</h3><div class="card mb-3"><div class="card-body"><p>Implicit in
    instance methods, constructors and accessors; omitted from declared parameters and dot-call arguments.
    Static code cannot use it. It is not available in explicit base-constructor argument expressions before
    construction.</p><p><strong>Example context:</strong> Declaration/body fragment; supply the enclosing
    class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public Increment() { this.Count = this.Count + 1; }
!]]
--[[!
@fqxn LuaEx.LXC.Keywords.base
@desc <h3>base — Select parent behavior or forward constructor arguments.</h3><div class="card mb-3"><div
    class="card-body"><p>base.Member starts lookup at the declaring class's parent, allowing an override to call
    inherited behavior. In an instance constructor only, base(...) must be the first unique statement; it is
    extracted before construction. A root cannot call base(...).</p><p><strong>Example context:</strong>
    Declaration/body fragment; supply the enclosing class/property and referenced declarations.</p></div></div>
@see <a href="#LuaEx.LXC.Syntax">Syntax</a>
@ex public Child(nValue) { base(nValue); }
public override Describe() { return base.Describe(); }
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference
@desc <h3>Instance operator reference</h3><p>All operators are public non-static instance methods. Declare with
    operator followed by the spelling below, or use the canonical metamethod name as a method. Arity counts only
    explicit parameters, not this. For a one-parameter binary form, this is the selected LXC receiver and the
    parameter is the other operand; with two parameters they are original left/right operands. This matters when
    the LXC receiver is on the right.</p><p>For -, zero parameters selects __unm; otherwise __sub. For ~, zero
    selects __bnot; otherwise __bxor. Binary dispatch tries left then right support. Missing &lt;= can use
    reversed &lt;; missing equality uses raw identity. No general automatic conversion is added.</p><table
    class="table table-striped table-bordered"><thead><tr><th>Canonical
    name</th><th>Spelling</th><th>Parameters</th><th>Purpose</th></tr></thead><tbody><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__add">__add</a></td><td>+</td><td>1 or
    2</td><td>Addition</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__sub">__sub</a></td><td>-</td><td>1 or
    2</td><td>Subtraction</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__mul">__mul</a></td><td>*</td><td>1 or
    2</td><td>Multiplication</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__div">__div</a></td><td>/</td><td>1 or
    2</td><td>Division</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__idiv">__idiv</a></td><td>//</td><td>1 or 2</td><td>Floor
    division</td></tr><tr><td><a href="#LuaEx.LXC.Operators.Reference.__mod">__mod</a></td><td>%</td><td>1 or
    2</td><td>Modulo</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__pow">__pow</a></td><td>^</td><td>1 or
    2</td><td>Exponentiation</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__concat">__concat</a></td><td>..</td><td>1 or
    2</td><td>Concatenation</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__eq">__eq</a></td><td>==</td><td>1 or
    2</td><td>Equality</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__lt">__lt</a></td><td>&lt;</td><td>1 or 2</td><td>Less
    than</td></tr><tr><td><a href="#LuaEx.LXC.Operators.Reference.__le">__le</a></td><td>&lt;=</td><td>1 or
    2</td><td>Less than or equal</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__band">__band</a></td><td>&amp;</td><td>1 or 2</td><td>Bitwise
    and</td></tr><tr><td><a href="#LuaEx.LXC.Operators.Reference.__bor">__bor</a></td><td>|</td><td>1 or
    2</td><td>Bitwise or</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__bxor">__bxor</a></td><td>~</td><td>1 or 2</td><td>Bitwise
    xor</td></tr><tr><td><a href="#LuaEx.LXC.Operators.Reference.__shl">__shl</a></td><td>&lt;&lt;</td><td>1 or
    2</td><td>Left shift</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__shr">__shr</a></td><td>&gt;&gt;</td><td>1 or 2</td><td>Right
    shift</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__unm">__unm</a></td><td>-</td><td>0</td><td>Unary
    negation</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__bnot">__bnot</a></td><td>~</td><td>0</td><td>Bitwise
    not</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__len">__len</a></td><td>#</td><td>0</td><td>Length</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__tostring">__tostring</a></td><td>tostring</td><td>0</td><td>Text
    representation</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__pairs">__pairs</a></td><td>pairs</td><td>0</td><td>Iteration</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__gc">__gc</a></td><td>gc</td><td>0</td><td>Garbage-collection
    finalization</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__clone">__clone</a></td><td>clone</td><td>0</td><td>Custom live
    copy</td></tr><tr><td><a href="#LuaEx.LXC.Operators.Reference.__call">__call</a></td><td>() / call</td><td>0
    or more; varargs allowed</td><td>Callable instance</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__index">__index</a></td><td>[] / index</td><td>1</td><td>Unknown
    member read</td></tr><tr><td><a href="#LuaEx.LXC.Operators.Reference.__newindex">__newindex</a></td><td>[]=
    / newindex</td><td>2</td><td>Unknown member assignment</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__close">__close</a></td><td>close</td><td>1</td><td>Lua 5.4 scope
    close</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__serialize">__serialize</a></td><td>serialize</td><td>0 or
    1</td><td>Outgoing projection preparation</td></tr><tr><td><a
    href="#LuaEx.LXC.Operators.Reference.__deserialize">__deserialize</a></td><td>deserialize</td><td>0 or
    1</td><td>Restored projection validation</td></tr></tbody></table>
@ex namespace Example.Operators {
    public class Number {
        public Value = 0;
        public Number(nValue) { this.Value = nValue; }
        public operator +(left, right) { return left.Value + right.Value; }
        public operator tostring() { return tostring(this.Value); }
    }
}
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__add
@desc <h3>Addition — __add</h3><p><strong>Spelling:</strong> +</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__sub
@desc <h3>Subtraction — __sub</h3><p><strong>Spelling:</strong> -</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__mul
@desc <h3>Multiplication — __mul</h3><p><strong>Spelling:</strong> *</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__div
@desc <h3>Division — __div</h3><p><strong>Spelling:</strong> /</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__idiv
@desc <h3>Floor division — __idiv</h3><p><strong>Spelling:</strong> //</p><p>Declaration contract: 1 or 2
    explicit parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__mod
@desc <h3>Modulo — __mod</h3><p><strong>Spelling:</strong> %</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__pow
@desc <h3>Exponentiation — __pow</h3><p><strong>Spelling:</strong> ^</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__concat
@desc <h3>Concatenation — __concat</h3><p><strong>Spelling:</strong> ..</p><p>Declaration contract: 1 or 2
    explicit parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__eq
@desc <h3>Equality — __eq</h3><p><strong>Spelling:</strong> ==</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__lt
@desc <h3>Less than — __lt</h3><p><strong>Spelling:</strong> &lt;</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__le
@desc <h3>Less than or equal — __le</h3><p><strong>Spelling:</strong> &lt;=</p><p>Declaration contract: 1 or 2
    explicit parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__band
@desc <h3>Bitwise and — __band</h3><p><strong>Spelling:</strong> &amp;</p><p>Declaration contract: 1 or 2
    explicit parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__bor
@desc <h3>Bitwise or — __bor</h3><p><strong>Spelling:</strong> |</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__bxor
@desc <h3>Bitwise xor — __bxor</h3><p><strong>Spelling:</strong> ~</p><p>Declaration contract: 1 or 2 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__shl
@desc <h3>Left shift — __shl</h3><p><strong>Spelling:</strong> &lt;&lt;</p><p>Declaration contract: 1 or 2
    explicit parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__shr
@desc <h3>Right shift — __shr</h3><p><strong>Spelling:</strong> &gt;&gt;</p><p>Declaration contract: 1 or 2
    explicit parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__unm
@desc <h3>Unary negation — __unm</h3><p><strong>Spelling:</strong> -</p><p>Declaration contract: 0 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__bnot
@desc <h3>Bitwise not — __bnot</h3><p><strong>Spelling:</strong> ~</p><p>Declaration contract: 0 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__len
@desc <h3>Length — __len</h3><p><strong>Spelling:</strong> #</p><p>Declaration contract: 0 explicit
    parameter(s), public instance method. Runtime supplies receiver-aware invocation through the facade
    dispatcher; ordinary Lua constrains how the result is used.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__tostring
@desc <h3>Text representation — __tostring</h3><p><strong>Spelling:</strong> tostring</p><p>Declaration
    contract: 0 explicit parameter(s), public instance method. Return a string accepted by Lua tostring.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__pairs
@desc <h3>Iteration — __pairs</h3><p><strong>Spelling:</strong> pairs</p><p>Declaration contract: 0 explicit
    parameter(s), public instance method. Return an iterator function, state and initial control value in the
    ordinary Lua pairs protocol.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__gc
@desc <h3>Garbage-collection finalization — __gc</h3><p><strong>Spelling:</strong> gc</p><p>Declaration
    contract: 0 explicit parameter(s), public instance method. Runs only for ready instances not marked
    failed/discarded; collection timing remains controlled by Lua.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__clone
@desc <h3>Custom live copy — __clone</h3><p><strong>Spelling:</strong> clone</p><p>Declaration contract: 0
    explicit parameter(s), public instance method. Return a distinct instance of the same concrete class.
    Register the copy before recursively cloning cyclic contents; see GraphClone.registerCopy.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__call
@desc <h3>Callable instance — __call</h3><p><strong>Spelling:</strong> () / call</p><p>Declaration contract: 0
    or more; varargs allowed explicit parameter(s), public instance method. Receives the explicit call arguments
    and may be variadic; class-object calls remain construction, while this operator makes an instance
    callable.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__index
@desc <h3>Unknown member read — __index</h3><p><strong>Spelling:</strong> [] / index</p><p>Declaration contract:
    1 explicit parameter(s), public instance method. Receives the unknown key only after declared
    members/aliases/nested names have been considered; it cannot bypass access restrictions on a declared
    member.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__newindex
@desc <h3>Unknown member assignment — __newindex</h3><p><strong>Spelling:</strong> []= /
    newindex</p><p>Declaration contract: 2 explicit parameter(s), public instance method. Receives unknown key
    and assigned value only for undeclared instance names.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__close
@desc <h3>Lua 5.4 scope close — __close</h3><p><strong>Spelling:</strong> close</p><p>Declaration contract: 1
    explicit parameter(s), public instance method. Receives Lua's close error argument. Lua 5.4 to-be-closed
    usage invokes this operation.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__serialize
@desc <h3>Outgoing projection preparation — __serialize</h3><p><strong>Spelling:</strong>
    serialize</p><p>Declaration contract: 0 or 1 explicit parameter(s), public instance method. An optional
    parameter receives the declaring level's pri/pro/pub projection. Edit it in place; return values are not a
    replacement snapshot. Serialize runs for preparation; deserialize runs for restore, not generic live-clone
    validation.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Operators.Reference.__deserialize
@desc <h3>Restored projection validation — __deserialize</h3><p><strong>Spelling:</strong>
    deserialize</p><p>Declaration contract: 0 or 1 explicit parameter(s), public instance method. An optional
    parameter receives the declaring level's pri/pro/pub projection. Edit it in place; return values are not a
    replacement snapshot. Serialize runs for preparation; deserialize runs for restore, not generic live-clone
    validation.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Records
@desc <h3>Internal data records</h3><p>Definitions describe source declarations; live state owns values;
    snapshot records describe an identity graph. These are private service contracts, not public fields on
    class/instance facades. Optional fields appear only after their preparation stage.</p>
!]]
--[[!
@fqxn LuaEx.LXC.Records.Token
@desc Internal Token record used by the services described in the module map.
@vis internal
@field string Text Exact original token spelling, or the end-of-file sentinel.
@field number Start Inclusive one-based byte offset.
@field number Stop Inclusive final byte offset.
@field number Line One-based line at token start.
@field string|nil Kind string or number for those tokens; nil for other tokens.
!]]
--[[!
@fqxn LuaEx.LXC.Records.Class
@desc Internal Class record used by the services described in the module map.
@vis internal
@field string Name Short declaration name.
@field string FullName Namespace/outer path plus short name.
@field string Namespace Containing namespace path.
@field table|nil Outer Lexically enclosing class, independent of inheritance.
@field table|nil Parent Resolved inherited base.
@field table Flags Declaration modifiers including optional Visibility.
@field table Members Non-constructor members in source initialization order.
@field table ByName Own declared members by short name.
@field table Nested Own nested class definitions.
@field table Imports Using namespace paths copied at declaration time.
@field table Aliases Generated accessor alias records with Property and Access.
@field table Operators Effective inherited/declared operator definitions.
@field table AbstractMembers Remaining abstract method-name obligations.
@field table PrivateNames Names that require lexical private-member selection.
@field table Batch Pending definition map for this load.
@field table Static Storage slots for this class's actual static declarations.
@field table Object Public callable class facade.
@field table State Static dispatch state.
@field boolean Published Registry/publication commit has occurred.
@field boolean Discarded Failed-load definitions may no longer be used.
@field string File Diagnostic filename.
@field number Line Declaration source line.
!]]
--[[!
@fqxn LuaEx.LXC.Records.Member
@desc Internal Member record used by the services described in the module map.
@vis internal
@field string Name Declared name or canonical operator key.
@field string Kind field, method, property or accessor.
@field table Owner Declaring class definition.
@field string Visibility Effective public/protected/private access.
@field table Flags static/final/const/abstract/override modifiers as applicable.
@field table Parameters Ordered explicit parameter names.
@field boolean Variadic Whether the final vararg is declared.
@field string Body Uncompiled Lua body when present.
@field string Initializer Declaration expression text when present.
@field function Function Compiled callable with hidden runtime arguments.
@field function Initialize Compiled storage initializer.
@field table Accessors get/set definitions for properties.
@field table Overrides Accessible inherited declaration being overridden.
@field table Slot Original property definition that owns backing storage.
@field string Prefix Generated accessor prefix; concatenated directly with property name.
@field any DeclaredType Inferred primitive/class/instance constraint when statically recognized.
!]]
--[[!
@fqxn LuaEx.LXC.Records.State
@desc Internal State record used by the services described in the module map.
@vis internal
@field table Class Concrete class definition.
@field table Object Public instance facade.
@field table Values Instance storage keyed by storage-owning member definitions.
@field table Methods Cached bound closures keyed by member definitions.
@field table StorageViews Cached property backing views.
@field table BaseViews Cached parent views keyed by declaring owner.
@field table LexicalViews Cached declaring-scope views.
@field table|nil Constructing Declaring level currently running construction.
@field boolean Ready Construction/restore/copy validation completed.
@field boolean Failed State must not be used after failed construction/restore/copy.
!]]
--[[!
@fqxn LuaEx.LXC.Records.Slot
@desc Internal Slot record used by the services described in the module map.
@vis internal
@field table Member Original declaration owning this storage.
@field any Value Current non-nil value, possibly initial null.
@field string|table|nil Type Established primitive/class marker or instance-class definition; nil while untyped.
@field boolean Locked const/final binding may no longer be reassigned.
@field table State Owning live instance/static dispatch state when supplied.
!]]
--[[!
@fqxn LuaEx.LXC.Records.Graph
@desc Internal Graph record used by the services described in the module map.
@vis internal
@field number Version Standalone descriptor format version, currently 1.
@field table Root Value descriptor identifying the graph root.
@field table Nodes Dense array of interned identity records, limited to 100000.
!]]
--[[!
@fqxn LuaEx.LXC.Records.Descriptor
@desc Internal Descriptor record used by the services described in the module map.
@vis internal
@field boolean Null True identifies the LXC null singleton.
@field number Ref One-based identity index in Nodes.
@field any Value Primitive literal; a blank descriptor represents nil. Only one descriptor form is allowed.
!]]
--[[!
@fqxn LuaEx.LXC.Records.Node
@desc Internal Node record used by the services described in the module map.
@vis internal
@field string Kind table, class, instance, or host in adapter-enabled graphs.
@field string Class Exact registered class name for class/instance nodes.
@field table Entries Table nodes store descriptor key/value pairs.
@field table Fields Instance storage keyed by qualified-owner:member, with Value/Type/ClassType/Locked metadata.
@field any Value Foreign host node identity when enabled.
@field table Captures Host dependency descriptors used for access checks.
!]]
--[[!
@fqxn LuaEx.LXC.serialize
@desc Builds a standalone restricted snapshot. This is the direct Persistence codec, even when host binding also
    provides a broader global serialize. See Persistence.Guide for supported values and limits.
@param any vValue Application graph root.
@ret string sSource Restricted snapshot literal.
@pulsarlua function lxc.serialize
@see <a href="#LuaEx.LXC.Persistence.Guide">Copying and saving</a>
!]]
--[[!
@fqxn LuaEx.LXC.deserialize
@desc Restores standalone literal data against registered definitions, without constructors. Checks
    shape/access/types/locks and runs snapshot validation.
@param string sSource Restricted text from LXC.serialize.
@ret any vValue Restored root.
@pulsarlua function lxc.deserialize
@see <a href="#LuaEx.LXC.Persistence.Guide">Copying and saving</a>
!]]
--[[!
@fqxn LuaEx.LXC.clone
@desc Copies a live graph using GraphClone, retaining aliases/cycles and supporting custom clone operators.
    Constructors do not run for automatic copies.
@param any vValue Root to copy.
@param boolean|nil bIgnoreMetatable Optional foreign-table copy behavior.
@ret any vCopy Copied root.
@pulsarlua function lxc.clone
@see <a href="#LuaEx.LXC.Persistence.Guide">Copying and saving</a>
!]]
--[[!
@fqxn LuaEx.LXC.saveStatic
@desc Snapshots caller-accessible mutable static storage; class identities alone do not include static state.
    Const/final fields are excluded.
@param table oClass LXC class object.
@ret string sSource Static-field map snapshot.
@pulsarlua function lxc.saveStatic
@see <a href="#LuaEx.LXC.Persistence.Guide">Copying and saving</a>
!]]
--[[!
@fqxn LuaEx.LXC.loadStatic
@desc Validates all supplied static updates before committing them. Missing fields stay unchanged;
    inaccessible/locked/unknown/type-invalid fields fail.
@param table oClass LXC class object.
@param string sSource Snapshot from saveStatic.
@ret nil No return value; updates validated fields.
@pulsarlua function lxc.loadStatic
@see <a href="#LuaEx.LXC.Persistence.Guide">Copying and saving</a>
!]]

local _pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
local _pRoot = _pSource:match('^(.*)/[^/]+$') or '.';

-- Freeze trusted runtime dependencies before application code can replace
-- globals such as assert/rawget or table/string operations. Application bodies
-- still receive the caller-supplied environment, not this private snapshot.
local _rawType = rawtype or type;
local _loadFile = loadfile;
local _tFacades = debug.getregistry()['LXC.Facades.TableDecoys'];
local _tRuntimeEnvironment = {};
for sName, vValue in pairs(_G) do
    if (_rawType(vValue) == 'table' and not rawequal(vValue, _G) and
        not (_tFacades and _tFacades.owns(vValue))) then
        local tCopy = {};
        for k, v in pairs(vValue) do tCopy[k] = v; end
        _tRuntimeEnvironment[sName] = tCopy;
    else
        _tRuntimeEnvironment[sName] = vValue;
    end
end
_tRuntimeEnvironment.type = _rawType;


--[[!
@fqxn LuaEx.LXC.module
@desc Loads a private module factory relative to this entry point using the captured runtime environment.
    Runtime table dependencies are shallow-copied before application code can replace global services;
    application method bodies still use the caller-supplied host environment.
@param string sName Module basename in the sibling lxc directory.
@ret any vModule Loaded module value or factory.
@vis internal
!]]
local function module(sName)
    return assert(_loadFile(_pRoot..'/lxc/'..sName..'.lua', 't', _tRuntimeEnvironment))();
end

-- Reuse LuaEx's existing null singleton when initialized by the framework.
-- Standalone use keeps LXC's own opaque placeholder.
local _oHostNull = rawget(_G, 'luaex') and _G.luaex.null or nil;
return module('Loader')(module, _oHostNull);
