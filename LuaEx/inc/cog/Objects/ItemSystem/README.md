# Inventory persistence

Use the framework's existing automatic class serialization:

```lua
local sSave = serialize(oInventory);
local oLoadedInventory = deserialize(sSave);
oLoadedInventory.setOwner(oCreature);
```

Owners are external associations and are deliberately omitted. Loading leaves
getOwner() equal to null until the caller calls setOwner. Child containers inherit
the reconnected root owner's association. setOwner accepts a class instance or
null and returns the container; invalid inputs leave its owner unchanged.

Container contents, capacities, enabled/locked flags, stash tabs, slot layout and
item fields use the generated class snapshots. Runtime indexes, parent links,
item locations and item-to-item attachments are rebuilt inside the inventory
system without rerunning item constructors or gameplay permission callbacks.
Saving a child container saves its subtree rather than its containing parent.

ItemPersistence adapts inventory registries through the general serializer's
existing registerFactory API. It preserves prerequisites and registry sharing,
and reconnects references to saved items and containers to their loaded identities.
The class system, serializer and registry implementations are unchanged.

Define concrete item classes before loading a save; global class bindings support
loading in a fresh runtime. Locally bound concrete classes are registered when
saved in the current runtime. As with other framework objects, external references
and closures that form object cycles remain subject to the serializer's existing
restrictions. Keep registry instance entries inside the saved inventory graph.
External owners are reconnected separately rather than saved through a registry.

Run `tests/item_persistence_regression.lua` from the repository root. It initializes
LuaEx when needed and covers round trips, owner reconnection, callbacks,
attachment membership, specific container references, shared identity and
independent loads.
