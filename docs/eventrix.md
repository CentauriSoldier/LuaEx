# Eventrix serialization

Eventrix uses the framework's existing serializer:

```lua
local sSaved = serialize(kEventrix);
local kLoaded = deserialize(sSaved);
```

Saving preserves event IDs, event activation, hook activation and registration
order. Events remain registered even after their last hook has been removed.
Restoration rebuilds independent event tables, hook tables and ordinal indexes
without firing callbacks. Duplicate references to one eventrix within a saved
graph restore as one object; separate loads restore independent objects.

Include a private event enum in the same saved graph if the application needs
its event IDs after loading. Use those restored IDs when querying or firing the
restored dispatcher; IDs from an independently restored enum have their own identity.

Hook functions use the general serializer's Lua closure protocol. Include an
external callback reference in the same saved graph when the application needs
to remove or toggle that exact callback after loading:

```lua
local sSaved = serialize({dispatcher = kEventrix, hook = onDamage, event = eDamage});
local tLoaded = deserialize(sSaved);
tLoaded.dispatcher.setHookActive(tLoaded.event, tLoaded.hook, false);
```

Shared callbacks and captured Lua state retain their sharing within a load.
Their restored identities are separate from the original functions and from
functions in independent loads. A hook's lexical environment and other upvalues
follow the general function serializer's existing rules; dispatch environment
bindings described below do not rewrite a callback's lexical environment.

Dispatcher environments are external runtime bindings. Saving records their
registered `envrepo` names rather than copying environment tables. Register
those names before loading in another runtime. Missing names reject restoration
instead of silently selecting a different environment. When one environment
has several names, saving picks the alphabetically first non-default name; the
mutable default alias is used only when no other name is available. The module's
original global environment has its own marker and reconnects to the restoring
runtime's global environment. This preserves the existing constructor fallback
behavior even after `envrepo.setDefault` changes its alias.

`eventrix.deserialize(tState)` accepts a state table produced by the serialization
hook. Its versioned shape is:

```lua
{
    version = 1,
    environment = false, -- Global binding, or a registered environment name.
    events = {
        {
            id = eEvent,
            active = true,
            hooks = {
                {callback = onEvent, active = false, environment = "GameEvents"},
            },
        },
    },
}
```

State containers must be ordinary tables. Event and hook lists must be dense.
Unknown fields, invalid IDs, duplicate event IDs, duplicate hooks within one
event, invalid activation flags and unavailable environments are rejected.
State containers are copied; direct restoration retains the supplied callback
and enum references, just as those references were supplied by graph decoding.

Serialized data remains trusted Lua data. Lua bytecode needs a compatible Lua
runtime. Native C callbacks, unsupported upvalues and cycles passing through an
eventrix serialization hook are rejected by the general serializer. In particular,
a hook that captures its owning dispatcher or an owning object can form such a
cycle. These restrictions are not bypassed or replaced by silent callback loss.

Run these checks from the repository root:

```text
lua tests/eventrix_regression.lua
examples/api/node/node.exe examples/api/workbench/verify-eventrix.cjs
examples/api/node/node.exe examples/api/workbench/verify-cog-api.cjs tests/item_persistence_regression.lua
examples/api/node/node.exe tests/item_example_persistence.cjs
```
