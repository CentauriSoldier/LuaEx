# Standalone .lxc experiment

This is an isolated language/runtime prototype. It does not load LuaEx, replace
`class.lua`, change framework initialization, or migrate existing classes.
All prototype files live in this directory. The format and API are experimental.

## Run it

From this directory, using Lua 5.3 or 5.4:

```text
lua test.lua
```

On this Windows checkout, PowerShell can use the existing Lua 5.4 DLL directly:

```powershell
./Run.ps1
./Run.ps1 -Integration
```

The runner borrows only `wxLuma-main/Win/Bin/lua54.dll`; it does not initialize
wxLua, open windows, or run wxLuma tests. `-Integration` initializes LuaEx core in
a fresh Lua state to test real filesystem discovery. The equivalent CLI command
is `lua integration.lua`. Use `-LuaDll` to select another compatible
Windows Lua 5.4 DLL. Lua 5.4 is tested here; Lua 5.3 compatibility is unverified.

The test intentionally supplies Player before its parent Creature. Expected output
includes the corrected parent-first load order and a constructed player example.
Negative fixtures test access errors, invalid declarations, inheritance cycles,
missing parents, final-method overrides, and namespace collisions.

## The syntax

```csharp
namespace Game.Characters
{
    class Player
    {
        Name = "Unknown";
        private items = {};

        public Player(sName)
        {
            this.Name = sName;
        }

        public final getName()
        {
            return this.Name;
        }
    }
}
```

Declarations use braces and modifiers; method bodies and field initializers use
Lua. Use Lua comments (`--`), operators, loops, tables, strings, and `nil`.
Fields need an initializer and terminating semicolon. Methods omit `function`
and use braces instead of the outer function's `end`. Inner Lua blocks still
use their normal `end`. No type annotations are implemented.

Unmarked classes and members are public. `private` members are accessible only
from methods declared in their own class; `protected` members also allow methods
declared in descendants. Access uses `this.Member` for all three visibilities.
Member access is explicit: bare names are Lua variables, namespace class names,
or environment globals. Calls use dots, as in current LuaEx: `oPlayer.getName()`.
Do not pass `this` explicitly to declared methods.

Use `class Player : Creature` for one parent in the same namespace, or give a
fully qualified parent. Methods dispatch to overrides; final methods reject
overrides. Overrides preserve method/field kind and visibility. Constructors are
public, named after their class, and optional. A child constructor calls
`base(arguments)` explicitly; parent constructors are never called implicitly.
`base()` currently calls only a parent's explicit constructor, not parent methods.
Field initializers execute parent-first and alphabetically within each class,
separately for each instance. They cannot access `this`.

## Load application classes

```lua
local LXC = assert(loadfile("lxc.lua"))();
local tPublic = setmetatable({}, {__index = _G});

local tOrder = LXC.loadFiles({
    "examples/01_Player.lxc",
    "examples/02_Creature.lxc",
}, tPublic);

local oPlayer = tPublic.Demo.Characters.Player("James");
print(oPlayer.describe());
print(oPlayer.getItemCount());
```

Classes publish through namespace tables in the supplied environment. Bare class
references inside a method resolve in its namespace first, then the supplied
environment. Existing plain namespace tables are reused; occupied class bindings
and non-table namespace bindings fail. All sources, parents, Lua bodies and
publication destinations are checked before any namespace is published.
Field initializer expressions execute later during construction, so their runtime
errors can still occur after publication.

If LuaEx is already initialized, discovery uses its existing file listing API:

```lua
local tPaths = LXC.discover(package.path);
local tOrder = LXC.loadFiles(tPaths, tPublic);
```

Discovery scans directory prefixes before the `?` in package.path templates,
recursively, with `io.listfiles(root, true, nil, "lxc")`. Prefer a narrow path such
as `./MyClasses/?.lua` when experimenting. Listing failures are reported, rather
than silently skipping roots. The standalone tests use an adapter stub; the
integration test exercises real LuaEx filesystem discovery. Path deduplication
does not resolve symlinks or every relative/absolute alias.

## Deliberate limits

This prototype implements public namespaced classes, public/private/protected
members, single inheritance, constructors and final methods. It does not yet
implement nested/private/protected classes, static members, interfaces, imports,
properties/accessor directives, serialization, LuaEx type integration, or explicit
initializer dependency declarations. One namespace block is required per file;
multiple classes may appear inside it. Parents must be part of the same load batch.

Only inheritance determines loading order. References inside method bodies resolve
later. Arbitrary Lua code is not analyzed to infer dependencies. The tokenizer
understands Lua strings/comments and balanced braces; it is not a full Lua parser.
Lua's compiler validates method bodies. Source filenames and method line numbers
are preserved for method errors; field initializer line mapping remains incomplete.

This is trusted application code, not a security sandbox. Instance access views
demonstrate normal visibility checks, but raw/debug operations and deliberately
leaked internal views (for example, inside returned tables) need further design
before a production runtime could promise strict encapsulation. Direct `return
this` is converted to the public instance view.
