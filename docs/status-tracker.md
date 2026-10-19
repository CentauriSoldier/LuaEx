# StatusTracker

StatusTracker is a callable factory with private timer state. It tracks configured
status identifiers; it does not apply gameplay effects, stacking, resistance or RNG.
Methods use dot calls.

## Configuration and scopes

Define the hierarchy in the user's CoG config before LuaEx loads. The top key is
`StatusTracker`, matching the factory name. Named tables are categories; dense
numeric lists contain terminal effect names. Categories may contain subcategories
and effects together. All category and effect names use UPPERCASE_WITH_UNDERSCORES.

```lua
return {
    StatusTracker = {
        ALL_THINGS = {
            PEOPLE = {"CONFUSED"},
            VEHICLES = { SHIPS = {"DAMAGED"} },
            WEAPONS = { ONE_HANDED = {"DULL"} },
        },
    },
};
```

This section replaces the bundled StatusTracker settings without a purge marker.
Other CoG sections retain their existing merge rules. The bundled EFFECT example
table is commented out; no effects or categories are enabled by default. Empty
configuration loads successfully, but has no category from which to construct a
tracker. Declared categories must be nonempty. Cycles, sparse lists, duplicate
members, invalid names and scalar category values are rejected.

The configuration is locked at runtime and converted to nested private enums:

- `StatusTracker.ALL_THINGS`: category enum.
    - `PEOPLE`: category enum; `CONFUSED`: terminal effect member, default value 1.
    - `VEHICLES`: category enum; `SHIPS`: category enum; `DAMAGED`: terminal effect member, default value 1.
    - `WEAPONS`: category enum; `ONE_HANDED`: category enum; `DULL`: terminal effect member, default value 1.
- Category members are ordered alphabetically; effect list entries retain their
  numeric order and precede categories. A category's nested members use the enum
  library's default ordinal values unless their value is a nested category enum.

Construction requires exactly one actual category enum from this configuration:

```lua
local E = StatusTracker.ALL_THINGS;
local oAll     = StatusTracker(E);
local oPeople  = StatusTracker(E.PEOPLE);
local oWeapons = StatusTracker(E.WEAPONS.ONE_HANDED);

oAll.activate(E.WEAPONS.ONE_HANDED.DULL, 5, true);
oPeople.activate(E.PEOPLE.CONFUSED, 3, true);
```

A scope accepts effects at any descendant depth. Unrelated enums, plain tables,
missing arguments and terminal effects are invalid constructor inputs. Effects
from sibling categories are rejected by every effect getter, setter and adjuster.
An ALL_THINGS tracker accepts all configured descendants of ALL_THINGS.

Methods accept an actual descendant effect enum or an exact case-sensitive path.
Paths may be relative to the selected category or fully qualified from the config
root. For an ALL_THINGS tracker, use `WEAPONS.ONE_HANDED.DULL` or
`ALL_THINGS.WEAPONS.ONE_HANDED.DULL`. For a ONE_HANDED tracker, `DULL` is valid.
There is no search by an unqualified leaf name across subcategories. Identically
named effects in different categories remain distinct enum identities and records.

## Timer methods

Every status starts inactive, with duration zero and doesExpire true.

- `activate(effect, duration?, doesExpire?)`: validates before mutation, retains
  omitted settings and returns the resulting active flag. Supplied values replace
  current settings; they do not stack. An expiring zero-duration status stays inactive.
- `deactivate(effect)`: deactivates without changing duration or expiration policy;
  returns whether it was previously active.
- `isActive(effect)`, `getDuration(effect)`, `doesExpire(effect)`: read current state.
- `setDuration(effect, duration)`: finite nonnegative duration; never activates.
  Zero deactivates an expiring status. Returns this tracker.
- `adjustDuration(effect, delta)`: finite signed adjustment, clamped at zero;
  overflow is rejected before mutation. Returns this tracker.
- `setDoesExpire(effect, flag)`: requires a boolean. Enabling at zero deactivates;
  disabling does not activate. Returns this tracker.
- `cycle(step?)`: defaults to one; requires a finite nonnegative step. Advances
  active timers only, clamps at zero, and returns the number expired. Non-expiring
  statuses stay active at zero. The caller chooses the time unit.
- `eachStatus()`: snapshot iterator yielding relative effect path and a copied
  record containing duration, active and doesExpire. Includes inactive effects.
- `clear()`: deactivates and zeroes all durations, retaining expiration flags;
  returns the number previously active.
- `#tracker`: active count. `pairs(tracker)`: snapshot iteration over all scoped effects.

## Clone and persistence

`clone(tracker)` copies independent mutable state while retaining its configured
scope. `deserialize(serialize(tracker))` restores that scope against the current
configuration. Plain restoration through `StatusTracker.deserialize(state)` uses:

```lua
{
    scope = "ALL_THINGS.PEOPLE",
    statuses = {
        CONFUSED = { duration = 3, active = true, doesExpire = true },
    },
}
```

Unknown scopes, out-of-scope paths, extra fields, invalid durations and inconsistent
active expiring records are rejected. Omitted valid status records receive initial
state. The factory itself retains its registered serialization and clone identity.

This replaces the old no-argument constructor and fixed EFFECT namespace. Existing
callers must pass a configured category enum. Old saved state without a scope is
rejected; persistence does not guess a category or rename configured paths.

## Cost

Enum membership and accepted string paths are indexed once when the configured
factory loads. Effect methods use direct lookups, without walking the hierarchy on
each call. Ancestor scopes retain indexes for their descendants, so configuration
index memory increases with both effect count and nesting depth. Instance creation,
iteration, clearing, active counts and cycling scale with the number of effects in
the selected scope. Configuration processing and enum construction are one-time work.