# LXC keywords and contextual names

This is the consolidated approved vocabulary. DESIGN.md defines behavior;
README.md shows use. Lua keywords retain their normal roles inside method bodies.

| Word | Meaning |
| --- | --- |
| namespace | Groups class declarations under a qualified name. |
| class | Declares a class at namespace scope or nested inside another class. |
| public | Access permitted wherever enclosing visibility allows. |
| private | Declaring class and its lexical nested scopes. |
| protected | Declaring/derived scopes, with protected receiver restrictions. |
| final | No class derivation, no method/property override, or a binding locked on first non-null initialization. |
| const | Declaration-initialized binding that cannot be rebound; table contents remain mutable. |
| this | Current instance; no implicit static receiver. |
| base | Immediate-parent lookup, or the first-statement parent constructor call. |
| abstract | Non-instantiable class or bodyless instance method contract. |
| override | Explicit compatible replacement of an inherited instance method/property. |
| static | Class-owned state/method or the single static constructor. |
| get | Contextual automatic/custom getter, with optional quoted method prefix. |
| set | Contextual automatic/custom setter, with optional quoted method prefix. |
| field | Contextual hidden property backing value within accessor code. |
| value | Contextual setter input. |
| permits | Qualified direct-child allowlist. |
| excludes | Qualified direct-child denylist; cannot combine with permits. |
| using | Namespace import for name lookup. |
| requires | Qualified explicit initialization dependencies. |

The list has 20 words, including contextual accessor names. get/set/field/value
remain ordinary identifiers outside their special contexts. `other` is an ordinary
parameter name. `null` is the runtime's predeclared placeholder value, not a
statement or declaration modifier; it cannot name a declaration. `class` is also the scoped helper binding in
Lua bodies. Compiler identifiers beginning `__lxc` and direct `_ENV` access are
reserved against environment/view escape.

```csharp
using Game.Settings;
namespace Game {
    abstract class Actor permits(Game.Player) {
        protected Actor() {}
        public abstract describe();
    }
    class Player : Actor requires(Game.Settings.Config) {
        public Player() { base(); }
        public override describe() { return "player"; }
        public Health { get("read"); private set { field=value; } }=100;
    }
}
```

The example assumes Game.Settings.Config is loaded or included in the batch.
Class-name methods declare constructors; `static ClassName()` declares the
parameterless static constructor. Abstract method declarations end in a semicolon.

There is no interface, virtual, new/hiding, readonly or import keyword. Interfaces
are excluded; final supplies the agreed initialization lock. `lock(table)` is a
separate future function, eventually table.lock, and is not a modifier. The earlier
const-lock/final-lock modifier proposals were superseded. Update this reference
when new vocabulary is explicitly agreed.

`operator` declares an operation, for example `public operator +(left,right)`.
Named spellings include tostring, pairs, call, index, newindex, close, gc, clone,
serialize and deserialize. Canonical metamethod names are also accepted.
Native equality accepts `public operator ==(other)` or
`public operator ==(left,right)`, and canonical `public __eq(other)`.
The usual operator visibility, inheritance, override and final contracts apply.
Without a declared equality operation, comparison falls back to identity.
Lua controls dispatch eligibility; table-versus-number equality never invokes it.

Serialization operator names do not select a wire format. Standalone LXC codec
calls use restricted data; normal LuaEx host saves use the existing trusted
serializer, including supported application Lua functions. See DESIGN.md.
