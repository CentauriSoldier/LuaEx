# StatusTracker

StatusTracker follows the TagSystem/Targetor factory pattern: callable factory,
private storage inside `build`, method table, decoy object and metatable hooks.
It is not a LuaEx class and has no inheritance.

Configure status names in `LuaEx/inc/cog/config/StatusTracker.lua` before loading
LuaEx. All preserved example names are commented out by default. An empty
configuration creates an empty functional tracker; no placeholder status is added.
Configured names are case-sensitive and also available through
`StatusTracker.EFFECT` when the configuration is nonempty.

```lua
local statuses = StatusTracker()
statuses.activate("HASTENED", 5, true) -- Requires HASTENED in config.
statuses.cycle(1)
statuses.getDuration("HASTENED")       -- 4

statuses.activate("HASTENED", 0, false)
statuses.cycle(10)                    -- Still active at zero.
statuses.deactivate("HASTENED")
```

Duration is finite and nonnegative. The caller chooses units, including turns or
seconds. `doesExpire` determines whether reaching zero deactivates a status.
Active state is independent; non-expiring statuses remain active at zero.

`activate(status, duration, doesExpire)` replaces supplied settings and retains
omitted settings. It does not stack. Expiring statuses cannot activate at zero.
`setDuration` and `adjustDuration` do not activate inactive statuses. Adjustments
clamp at zero and reject numeric overflow before mutation. Turning expiration on
at zero deactivates immediately; turning it off does not automatically activate.

`cycle(step)` advances active timers only, defaults to one and returns the number
expired. Non-expiring timers also count down but remain active at zero. `clear`
deactivates everything and clears durations, retaining expiration settings.

`#tracker` counts active statuses. `eachStatus()` and `pairs(tracker)` return
configured names and copied state records, including inactive statuses, in config
order. Snapshots do not expose private storage. Dot calls are used throughout.

Global `clone`, `serialize` and `deserialize` use the same factory registration
pattern as TagSystem. Restore validates state, rejects unknown names and preserves
explicit false flags. Saved statuses must still exist in the current configuration.

Gameplay effects, immunity, resistance, callbacks and RNG policy are not implemented
in this initial tracker. These rules remain separate design decisions.

The old StatusSystem module paths forward to StatusTracker; the loaded global and
canonical config section are now named StatusTracker.

Run `examples/api/node/node.exe examples/api/workbench/verify-statustracker.cjs`
from the repository root to verify empty configuration and configured behavior.
