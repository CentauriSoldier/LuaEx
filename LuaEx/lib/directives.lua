--[[!
@fqxn LuaEx.Directives.Guide
@desc <h3>Structured annotations and ordinary documentation</h3>
    <p>The shared Parser records directive syntax, declaration targets and source locations;
    Registry validates supported uses; Diagnostics reports located errors; Selection chooses
    declaration candidates. LXC and LXE own their language-specific semantics. Supported
    directives are &#64;type for LXC fields/properties and &#64;default for classes, enums and
    extensions. DOx parameter/return tags remain documentation, not runtime contracts.</p>
    <p>A structured line annotation attaches to the next declaration in the same scope.
    Whitespace and ordinary comments do not change its target, but another declaration or a
    closing scope does. Unknown, duplicate, malformed or unsupported-target directives are
    rejected even on a default candidate. Semantic validation applies to selected declarations.</p>
@ex ---&#64;type number
public Capacity = 10;
---&#64;type number?
protected Pending = null;
!]]

--[[!
@fqxn LuaEx.Directives.Completion
@desc <h3>Type annotations validate completed stored state</h3>
    <p>A type names boolean, number, string, table, function, thread, userdata or a visible
    resolvable LXC class, optionally followed by ?. Class names resolve through the declaring
    namespace and using imports. Unions, generic containers, enum types and per-element table
    contracts are not supported. Primitive values such as false and zero remain valid.</p>
    <p>The extra directive check runs once after the most-derived constructor completes,
    once after the declaring class's static initialization, and once for the final copied or
    restored instance state. A class contract accepts descendants. A nullable contract permits
    null at that boundary; nil is still forbidden storage. Child constructors may initialize
    accessible inherited protected storage before completion. Static deadlines belong to the
    declaring class. Access and const/final rules remain in force.</p>
    <p>Ordinary reads, assignments, accessors and method calls do not parse directives, resolve
    names or run additional directive checks. Existing inferred slot typing and binding locks
    remain active. An annotation does not widen those types or promise that a typed field can
    later be reset to null. Unannotated fields preserve their existing initialization behavior.</p>
    <p>Graph copies/restores validate private stored values against definition-owned metadata
    before returning usable results. Saved data cannot supply replacement contracts. Custom
    cloning through constructors defers completion until the final copied state is ready.</p>
!]]

--[[!
@fqxn LuaEx.Directives.Properties
@desc <h3>Stored and computed properties</h3>
    <p>Declaration initialization, automatic accessors or contextual field use identify stored
    backing values. Validate that storage at completion without calling getters. A property
    implemented by custom accessors with no backing use or initializer is computed: its type
    is compile-time/editor metadata only, even though LXC internally allocates a slot.</p>
    <p>Property overrides inherit the original contract and storage identity. Conflicting type
    or nullability redeclarations fail; equivalent class spellings resolve to one identity.
    An override cannot introduce a type annotation when the original property had none.
    Abstract properties are not supported. No getter-result, setter-input or method-call
    argument/return checking is introduced by documentation metadata.</p>
!]]

--[[!
@fqxn LuaEx.Directives.Defaults
@desc <h3>One fallback declaration, selected before initialization</h3>
    <p>The structured &#64;default annotation takes no arguments. A single declaration loads
    normally. Exactly two candidates with the same identity are accepted only when one is
    default and the other ordinary; the ordinary declaration wins. Two defaults, two ordinary
    candidates or more than two candidates fail. There is no source-order priority chain,
    retry after initialization failure or replacement of published identities.</p>
    <p>Selection happens across the complete batch before dependency resolution, compilation
    and application initialization. Discarding a class removes its lexical members, nested
    classes, inline enums and extensions. Discarding an enum removes its embedded member tree.
    External declarations are separate candidates: within resolves the selected owner, and an
    external extension resolves the selected enum. Extension identity combines target FQN and
    method name. Extensions still cannot attach to an already published target.</p>
@ex ---&#64;default
public class Creature {
    public Creature() { }
}
!]]

--[[!
@fqxn LuaEx.Directives.Editor
@desc <h3>Static editor metadata and current limits</h3>
    <p>The luaex-tools package provides diagnostics, hover, completion and active-parameter
    signature help from source and shared compiler rules. DOx parameter/return information
    supplies documentation metadata. Analysis must not execute modules, constructors, getters
    or arbitrary initializers. Unknown expressions remain unknown rather than guessed types.</p>
    <p>Default parameter values are not implemented. Argument and return annotations do not
    enable runtime validation. The maintained directive regression checks completion boundaries,
    nullability, inheritance, stored/computed properties, copy/restore and default selection.
    Run lua tests/run.lua --suite directives; editor tooling has its own package test runner.
    Mocked/source tests do not establish rendered behavior in a live Pulsar session.</p>
!]]
--[[!
@fqxn LuaEx.Directives
@desc Composes shared source annotation, target validation and declaration selection
    services. LXC and LXE explicitly supply their own declaration semantics.
!]]
return {
    Parser = require("LuaEx.lib.directives.Parser");
    Registry = require("LuaEx.lib.directives.Registry");
    Diagnostics = require("LuaEx.lib.directives.Diagnostics");
    Selection = require("LuaEx.lib.directives.Selection");
};
