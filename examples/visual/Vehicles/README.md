# Vehicle garage

Open the repository's `Examples.html`, choose **CoG → Vehicles**, and select
**Visual**. The **Code** tab runs an independent tutorial; edits and trips in
one tab do not alter the other tab's objects.

The three illustrated presets are Trailwarden (rover), Cloudrunner (airship)
and Stillwater (unmanned survey skiff). Select an illustration to inspect it.

## Things to explore

- Spend or add fuel, reserve tank capacity, and take a distance-based trip.
  Insufficient fuel rejects the trip before changing either fuel or distance.
- Install, remove, damage and repair real objects in every configured component
  slot. This framework configuration supplies `BODY`; the example does not
  invent additional slots. A component is a Pool whose value is its condition.
- Share the first other vehicle's component, damage it, then select that other
  vehicle to see shared object identity. Snapshot testing verifies that changing
  a returned binding table does not change the vehicle's actual bindings.
- Change name, description, rarity, value, efficiency, speed, all five flags,
  owner presence and event environment. Apply validates a replacement vehicle
  before publishing it. Fuel/component/owner references survive the replacement;
  tag membership and enabled status are copied. Inspection count starts fresh.
- Add/remove inherited tags and dispatch an inspection event. The concrete
  subclass installs one fresh hook per instance. A Pool supplies the minimal
  owner class instance for each preset; it represents crew identity, not fuel.
- Clone the selected concrete vehicle. Change its fuel and component condition,
  then compare with the original. Owners are shared; fuel, components and tags
  are copied. Trip and inspection counters start at zero. Up to twelve vehicle
  records are allowed before a reset is required.
- Try cloning the base class, invalid constructor values, an unknown component
  slot, a plain table component, and native serialization. Results appear in the
  status message and bounded operation journal.

Movement, units, trip counters, condition, images and concrete clone choices are
example policy. CoGVehicle supplies validated storage and inherited identity.
`Tradeable` covers selling. Flags do not automatically enforce game rules.

## Current framework limits shown honestly

Native serialization encounters inherited Eventrix state. The persistence probe
reports the actual error; it does not claim a successful round trip.

Eventrix accepts a registered environment name, but changes its own `_ENV`
instead of rebinding an independently defined callback's lexical environment.
The inspector and journal show configured and observed environments separately.
The callback still runs and increments that vehicle's inspection count.

CoGObject's unfinished affix implementation is documented rather than exposed
as a functioning control. Affixes and arbitrary user hooks are not cloned by
this example. The inspection hook is recreated by the concrete constructor.

## Sources and verification

- `browser.lua`: live Lua model and action dispatch.
- `Vehicle.lua`: documented concrete subclass and explicit copy policy.
- `../../cog/Vehicles.lua`: standalone tutorial.
- `../../code/cog/Vehicles.lua`: independent Code-tab copy of that tutorial.
- `../../api/workbench/vehicles-view.js` and `vehicles.css`: inspector UI.
- `../../resources/vehicles`: generated illustration assets and art prompts.

From the repository root:

```powershell
.\examples\api\node\node.exe examples/api/workbench/verify-vehicles.cjs
.\examples\api\node\node.exe examples/api/workbench/bundle.cjs
```

The verifier runs real Wasmoon Lua sessions, exercises state transitions and
expected failures, and runs the independent tutorial. It updates only this
example's entry in `examples/verification.json`. The bundle command refreshes
the offline catalog and embedded files.
