# Item system

All five item/container classes and SlotPattern are loaded by LuaEx.init. ItemRules is their private shared implementation; callers use the class APIs.

## Responsibilities

- CoGItem represents one actual item, exposes mutable permission registries and Pools, and tracks its actual container and optional attachment host. It does not define stack capacity, prices, upgrade effects, or destruction.
- ItemSlot holds separate CoGItem instances, with a positive integer capacity (default one) and ObjectRegistry eligibility. A stack is a collection of actual instances; consuming one removes that one.
- ItemSlotSystem owns ItemSlots and enforces rules across them. It can optionally interpret SlotPattern coordinates as footprints on a rectangular grid.
- ItemSystem is an inventory of individual items, with a count limit (default unlimited). Capacity zero is valid. It can be a stash tab.
- ItemStashSystem owns ItemSystem tabs, checks all their contents as one context, and always retains at least one tab.
- SlotPattern only describes occupied relative integer coordinates. It does not store items or decide placement.

A slot or tab belongs to one parent system. Sharing the same item instance between locations, sharing a slot between systems, creating containment cycles, and removing nonempty child containers are rejected. Owner is application metadata; parent/system and Location are containment references.

## Construction and eligibility

```lua
local slot = ItemSlot(ObjectRegistry({MyItemClass}), 5, owner, "Supplies");
local equipment = ItemSlotSystem({slot}, owner);
local inventory = ItemSystem(20, nil, owner);
local stash = ItemStashSystem(owner, 3, 20);
```

All inputs are validated. Initial item arrays are accepted atomically: an invalid array or item leaves no partial membership or location updates. Arrays must be dense; input arrays are copied and supplied item/slot instances retained by reference.

ItemSlot defaults to allowing CoGItem and descendants. An explicit empty registry permits nothing. Inventory and stash insertion require Storable_In to permit at least one actual context in the destination hierarchy (a particular tab, the stash, or an applicable class). Storable_In defaults empty, so concrete item constructors must configure their storage permissions. ItemSlotSystem is neutral: ordinary insertion checks slot eligibility, while equipItem also checks the actor's Equipable_By permission.

CoGRegistry callbacks receive useful context: slot eligibility `(item, slot)`; storage `(container, item)`; Exclusive_In `(container, ruleOwner)`; Exclusive_With `(otherItem, ruleOwner, container)`; CoGItem.can* helpers `(matchedObject, item, ...)`. Callbacks must be side-effect-free. Container, location and attachment mutations during callbacks are rejected. Exceptions become failed operations with a reason and unchanged membership.

## Exclusivity across a whole stash

Configure the kite's constructor inputs with:

```lua
local exclusiveIn = CoGRegistry({myStash});
local exclusiveWith = CoGRegistry({Kite});
```

At every context in the containing hierarchy, each pair is checked in both directions: the rule owner must match that context through Exclusive_In and the other item through Exclusive_With. One rule is enough to reject the pair; insertion order does not matter. Defaults include ItemSlotSystem, ItemSystem and ItemStashSystem as contexts, but Exclusive_With starts empty, so there is no default conflict.

An Exclusive_In constructor argument may be a CoGRegistry or a specific supported system instance (wrapped in a CoGRegistry). Direct calls to a stash tab or a system-owned slot still validate the entire root context. Moving an existing kite between tabs validates the final arrangement, excluding its old position. Specific instance entries use raw identity.

## Mutations and return values

ItemSystem.addItem keeps its original `bSuccess, this, sReason` order. Most other mutations return `this, bSuccess`, with a reason or removed data afterward. ItemSlot.set/remove, container clear and transfer methods return `this, bSuccess, oRemovedOrItems, sReason`. For failed operations, removed data is nil. Stash.removeTab retains the removed-tab-first convention: `oTabOrNil, bSuccess, sReason`.

`set(item)` appends to a slot. At full capacity, `set(item, true)` replaces its first item and returns that displaced instance. Capacity changes cannot silently discard items. Reads remain available when disabled or locked; containment changes honor both the immediate container and all parent states.

Use `source.transferItemTo(destinationLeaf, item, replace)` for atomic movement between an ItemSlot or ItemSystem. System facades can select a destination slot/tab. If validation fails, contents and locations remain unchanged. Replacement never bypasses eligibility, storage, exclusivity or locking. swapWith and ItemSlotSystem.swapItems exchange complete slot collections after validating the resulting contexts. clear clears a whole subtree atomically and returns the actual removed instances; one locked descendant prevents partial clearing.

Locations point to the actual leaf ItemSlot or ItemSystem. A stash can discover an item's tab through containsItem. Empty slot reads return nil; removed item Location becomes null. Snapshot iterators yield index and item/slot/tab without exposing mutable internal arrays. Item counts count instances, not occupied slots or footprint cells.

## Gameplay permissions

Administrative containment APIs do not infer an actor. Passing an actor to remove/removeItem checks Removable_By. Named action methods enforce their relevant registries:

- consumeItem(item, actor) checks Consumable_By and removes exactly that instance; the caller applies consumption effects and decides its subsequent lifetime.
- ItemSlotSystem.equipItem(item, actor, slotIndex) checks Equipable_By and moves from the current container if necessary.
- ItemSlotSystem.unequipItem(item, actor, destinationLeaf) checks Unequippable_By and transfers to storage.
- tradeItemTo(destinationLeaf, item, trader, recipient) checks both Tradable_By and Tradable_To. The stash facade can select a destination stash tab. Money, prices and barter effects remain caller policy.
- CoGItem.attachTo(host) checks Attachable_To, requires the item to be outside storage and detached, and prevents self-attachment/cycles. detach(actor) checks Detachable_By and clears the host relation. eachAttachment yields attached item instances. One item has one host; a host can have several attached items. Attachments move with their host relationship and are not counted as separate stash contents.

CoGItem.canDamageBy/canRepairBy/canUpgradeBy/canDowngradeBy and other can* helpers expose registry decisions. Callers adjust the relevant Pools or apply effects. Durability reaching zero does not destroy anything. No destruction field or method has been introduced. Inimitable is still caller-enforced metadata and does not forbid copying.

## Optional grids

```lua
local grid = ItemSlotSystem(nineSlots);
assert(select(2, grid.configureGrid(3, 3)));
assert(select(2, grid.placeItem(item, 0, 0)));
local occupant = grid.getOccupantAt(1, 1);
```

Grid coordinates are zero based. Slots map row-major, and dimensions must match the slot count. Shape coordinates are translated relative to the anchor slot. Empty patterns use one anchor cell. Bounds, overlap, every footprint slot's eligibility, and locks/disabled state on every affected cell are checked. Grid mode permits one footprint per cell; ordinary count-based stacks remain available outside grid mode. getItemCount counts a shaped item once, while getOccupantAt identifies the item covering any footprint cell.

Supplied registries, Pools and SlotPatterns remain mutable by design. After deliberate external rule/pattern edits, validate() checks consistency. Grid queries recalculate current coordinates and reject inconsistent layouts instead of returning silently stale occupancy. Change a live shape through a valid intermediate configuration or remove it first; these objects do not provide mutation observers.

## Copying and persistence

Concrete CoGItem subclasses define __clone because only the caller knows subclass state, affix effects and gameplay identity. Container clone hooks explicitly reject implicit copying rather than accidentally sharing live membership. Automatic class snapshots are explicitly rejected for containers; reconstruct through public constructors and insertion methods so ownership, permission and exclusivity checks run. The application decides how item identities, specific registry entries and attachment graphs persist.

## Verification

Run the local runtime (no installation):

```text
examples/api/node/node.exe examples/api/workbench/verify-cogitem.cjs
examples/api/node/node.exe examples/api/workbench/verify-code.cjs
```

Coverage includes defaults and validation, exact identities, stacking, both exclusivity directions across stash tabs, direct-tab/slot enforcement, atomic movement/replacement/clearing, actor actions, attachments, locks, callback errors/reentrancy, bounds, overlaps and mutable coordinate patterns. The browser ItemSlotSystem code example demonstrates the full containment flow.
