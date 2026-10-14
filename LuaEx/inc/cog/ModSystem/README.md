# CoG blueprint repository

Factorium stores definitions. It does not create objects or return class
references. The host decides mod order and which capabilities to expose.

## Class contract

Participating CoG classes declare public static `Blueprint` (defaults),
`validateBlueprint(bp)` (returns `true` or `false, reason`), and
`fromBlueprint(bp, context)` (constructs the class's object).

Call `Factorium.registerClass(cClass)` once the class is built, for example
from its static constructor. Registration caches the class contract and
ancestor member references. LuaEx static members are not inherited, so each
participating class declares all three. Nonparticipating ancestors can omit
them. Every available ancestor validator runs, in ancestry order.

Tables merge recursively, including numeric keys. Missing fields inherit;
`false`, zero, and empty strings override. Extra fields remain unless a
validator forbids them. Keys can be strings, numbers, or plain tables. Table
keys match by identity, not by contents. Cycles through either keys or values
are rejected. Shared acyclic tables are allowed. Class objects, instances,
metatables and userdata are not definition data. Function values retain their
closures and are not executed by compilation.

## Host workflow

```lua
Factorium.setLog(programLog) -- Optional object with .log, or logging function.
Factorium.setEnvironment(modEnvironment) -- Optional; starts as {}.
Factorium.loadMod("mods/CoolDragons.lua")
Factorium.loadMod("mods/CoolerDragons.lua")
Factorium.runMods()
Factorium.finalizeImports()

local bp, modID = Factorium.getBlueprint(Dragon, "fire_dragon")
local dragon = Dragon.fromBlueprint(bp, spawnContext)
```

`loadMod` compiles a text file using the current environment. `runMods`
executes the queued files in supplied order and imports their returned tables.
Replacing the environment affects subsequent loads, not existing functions.
There is no fallback to host globals or execution-limit mechanism.

Without a supplied log, Factorium lazily creates a `BaseLog` at `Factorium.log`
in the working directory. `getWarnings()` also returns retained warnings.
Logging failures cannot stop imports.

## Returned mod table

```lua
return {
    id = "27bdc9c3-7452-4c36-b9bf-ab318216926a",
    name = "Cool Dragons",
    authors = { "Bob" },
    description = "Adds dragons.",
    released = "2026-10-13",
    updated = "2026-10-13",
    version = 1,
    contact = "", -- Optional.
    website = "", -- Optional.
    required = {}, -- Optional dependency UUID list.
    conflicts = {}, -- Optional incompatible UUID list.
    blueprints = {
        { id = "fire_dragon", class = "Dragon", health = 500 },
    },
}
```

`importMod(table)` also accepts a BaseMod subclass instance through
`getInfo()`. Invalid metadata rejects that mod; invalid definitions reject
only those definitions. Defaults merge and validators run during import.

BaseMod and Factorium share `BaseMod.validateModInfo(table)` for metadata
validation. Author/dependency/conflict lists must be dense numeric lists.
Malformed relationship UUIDs reject the mod; they are not silently discarded.
Optional relationship lists default to empty, and UUID case is normalized.

BaseMod initialization commits metadata only after full validation. Invalid
input logs a warning and retains declared metadata defaults without a
constructor exception. BaseMod stores no activation or validation status.
`getInfo()` returns metadata; Factorium validates it and owns acceptance,
rejection reasons and active state through `getModStatus`/`setModActive`.
Returned author and relationship lists are copies; raw blueprint entries are
retained for Factorium's individual validation boundary.

`Factorium.setLog` also supplies BaseMod's logger. BaseMod can be configured
independently using `BaseMod.setLog`; its default is a lazy `BaseLog` writing
`BaseMod.log`. Both classes retain warnings if the external logger fails.

Factorium controls mod activation, eligibility and blueprint visibility.
BaseMod contains only metadata and definitions and has no lifecycle hooks.

## Finalization and lifecycle

Finalization removes missing/inactive dependency chains, then processes
conflicts in load order. A declaration on either side counts as a conflict.
Later mods lose. If a winner loses a required mod, its conflict claims are
removed and eligibility is reconsidered. Circular requirements are permitted
when their full group remains eligible.

Blueprint IDs are global. The last valid definition from an accepted mod wins,
even if its target class changes. Earlier compiled definitions remain private
so they can be restored. `setModActive(id, boolean)`, `removeMod(id)`, and
`replaceMod(table)` require another `finalizeImports()` before queries.
Replacement preserves the mod's position and requested active state. Invalid
replacement definitions retain that mod's old definition for the same ID;
definitions omitted from a successful reload are removed.

`getBlueprint(cClass, id)` returns a definition copy and source mod ID.
`getBlueprints(cClass)` returns an ID-keyed map of `{ blueprint, modID }`.
Both operate only on the exact registered class. The caller handles ancestry
queries and RNG selection. Missing IDs return nil; empty class catalogs return
an empty table. Queries never expose the repository's class references.

The old `registerFactory`, `addBlueprint`, and `Factorium.fromBlueprint` API
has been replaced by class registration, mod import, and class-scoped queries.

## Verification

From the repository root, run the bundled Node executable with
`examples/api/workbench/verify-factorium.cjs`. It runs
`tests/factorium_regression.lua` and `tests/basemod_regression.lua` in the bundled
Lua 5.4 runtime, including
default logging, BaseMod integration, lifecycle changes and load environments.
