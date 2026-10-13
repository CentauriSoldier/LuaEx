# BaseItem construction

BaseItem is constructed through a concrete subclass calling its protected superclass constructor. It represents one item; container code handles quantities and stacking. Permission registries describe eligibility, not action execution.

Arguments after the injected `this, cdat, super`, in order:

1. `sName, sDescription, eRarity, wEventrix` — BaseObject metadata/environment.
2. `oAttachableTo, oConsumableBy, oDamageableBy, oDetachableBy, oEquipableBy` — ObjectRegistries.
3. `vExclusiveIn` — a Registry or a specific ItemSlotSystem, ItemSystem or ItemStashSystem. Omission creates `Registry({ItemSlotSystem, ItemSystem, ItemStashSystem})`; a specific system creates `Registry({thatSystem})`.
4. `oExclusiveWith` — Registry identifying conflicting classes/instances.
5. `bInimitable` — optional boolean, default false; caller-enforced metadata.
6. `oRemovableBy, oRepairableBy` — ObjectRegistries.
7. `oStorableIn` — Registry.
8. `oTradableBy, oTradableTo, oUnequippableBy, oUpgradeableBy, oDowngradableBy` — ObjectRegistries.
9. `oDurability, oSize, oValue, oWeight` — Pools.
10. `oAttachedTo, oLocation, oSlotPattern` — optional single CoG attachment host, class-instance location and SlotPattern instance.

Object inputs are declared null, except the optional Location and attachment references, which uses private table storage to allow transitions between a container and null. Omitted object arguments create fresh defaults in the constructor. Supplied objects must be instances of the expected class or its descendants and are retained by reference. Deliberately supplying the same object to two items therefore shares it.

ObjectRegistries and ordinary Registries default empty, except Exclusive_In. Durability defaults to `Pool(1, 1)`; Size, Value and Weight default to `Pool(1, 0)`. Attached_To and Location default null; Slot_Pattern defaults to a fresh empty `SlotPattern()`.

Accessor directives expose getters such as `getDamageable_By()` and `getDurability()`, plus `isInimitable()`. There are no generated public replacement setters. Location has a final explicit coordinated `setLocation(oLocation, oExpectedLocation)` method for container operations. Returned registries, Pools and SlotPatterns remain mutable.

There are no stacking, selling or destruction fields/methods. Trading covers sale eligibility; the caller interprets Value as cost information. Zero durability has no automatic consequence. Container/attachment operations must keep item Location/Attached_To synchronized with their membership records. Slot_Pattern provides occupied slot count and relative layout queries. Blueprint identity retains an explicit TODO note.

The base clone hook explicitly requires a concrete subclass implementation rather than constructing protected BaseItem or silently losing subclass state. It does not enforce Inimitable. Copying affixes, attachment relationships, location and additional subclass state needs an explicit policy; this implementation does not guess those policies.

Tests: `tests/baseitem_regression.lua`, run with the local `examples/api/node/node.exe examples/api/workbench/verify-baseitem.cjs`.


See [Item system](item-system.md) for enforced containment, attachments, actor permission helpers and transactional operations.
