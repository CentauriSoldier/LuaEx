# Item system review

Reviewed the five files in `LuaEx/inc/cog/Objects/ItemSystem`, their initializer registration, and the CoGObject/Affix/Rarity dependencies. This is a review of the current working tree, including existing uncommitted work.

The system is incomplete and has blocking runtime defects. Normal CoGItem subclass construction fails before a usable item exists. Inventory capacity and initialization are broken; equipment lookup and swapping are broken; inherited affix/event behavior is inconsistent.

## Validation and limits of evidence

Reproductions run using the repository's local Node and Wasmoon/Lua 5.4 runtime. Run `examples/api/node/node.exe examples/api/workbench/audit-items.cjs` from the repository root.

The script first checks unmodified initialization and normal item construction. Because construction fails, downstream probes run in a separate engine with **in-memory bootstrap adapters**: constructor superclass parameters/calls, a declared private Eventrix field, a null initial rarity type, and the rarity fallback. These adapters isolate later failures; they are not production fixes, and no core source file was edited. Findings below distinguish reproduced failures, source defects, and design limitations. Fixing the initial blockers alone will not make the entire subsystem work.

## Blocking/high-priority defects

1. **CoGItem construction calls a missing global `super`.** `CoGItem.lua:37–42` omits the injected superclass parameter and calls `super(...)`. An ordinary child constructor calling its superclass fails with `attempt to call a nil value (global 'super')`. Reproduced without adapters.

2. **CoGObject has additional constructor blockers.** `CoGObject.lua:52–62` also omits the superclass parameter/call despite extending CoG. It assigns undeclared private `Eventrix`, while the declared field is protected lowercase `eventrix`. Its fallback `_eRarity` is undefined, and `Rarity` starts as boolean false despite being assigned an enum item under the class system's field-type checks. Source inspection; the undeclared Eventrix assignment also failed while isolating the constructor chain.

3. **Inventory/stash classes are not initialized.** `LuaEx/init.lua:489–492` registers CoGItem, ItemSlot and ItemSlotSystem, but not ItemSystem or ItemStashSystem. Both globals are nil after standard initialization. Stash construction also expects a global ItemSystem, so merely requiring the stash module is insufficient. Baseline reproduced.

4. **ItemSystem shifts its constructor arguments.** `ItemSystem.lua:97` declares `super` even though the class has no parent. `ItemSystem(1)` therefore ignores the intended capacity and stays unlimited; a second item is accepted. `ItemSystem(2, {item})` initializes zero items. A stash configured for one item per tab inherits the same problem. Reproduced with item-construction adapters.

5. **Inventory initialization has a second independent typo.** `ItemSystem.lua:112–116` declares `nMyMaxItems` but compares against undefined `tMyMaxItems`. Supplying arguments that reach this branch produces a number-versus-nil comparison error. Reproduced with adapters.

6. **Position-based membership checks are copied from the wrong abstraction.** `ItemSystem.lua:175–184` and `ItemSlotSystem.lua:118–128` validate undefined `oSlot`, so both methods throw immediately. Inventory then incorrectly calls `getItem()` on the stored item; slot-system code calls `getItem()` on a slot whose actual API is `get()`. Reproduced first failure; later missing-method defects confirmed in source.

7. **Slot lookup/count methods use nonexistent names.** `ItemSlotSystem.lua:201` calls `getItem()` instead of `get()`. At `:216`, count accesses `pro.ItemSlots` instead of declared `pro.itemSlots`. Both throw. Reproduced.

8. **Slot-system initialization cannot create its slot list.** `ItemSlotSystem.lua:63–76` calls `clone()` on ItemSlot, which has no cloner. It also never assigns the resulting slots to `pro.itemSlots`; instead it overwrites the caller's input table. Current construction with a nonempty slot list fails at cloning. The missing assignment and caller mutation remain latent defects after adding cloning support.

9. **Slot swapping errors or reports a false success.** `ItemSlotSystem.lua:278–305` uses nonexistent `getItem()`/`setItem()` methods. With occupied slots it throws. With different indices and an empty slot, `bRet` remains true despite no swap occurring. The same success-initialization flaw applies when locks prevent swapping. There is no rollback if the first reassignment succeeds but the second fails type compatibility. Both empty and occupied cases reproduced; atomicity/type compatibility risks are source findings.

10. **Explicit false item flags are lost.** `CoGItem.lua:50–54` uses `condition and value or true` for Removable, Sellable and Tradable. Supplying false therefore produces true. All three reproduced after constructor adapters. This matters for quest items, bound items and non-removable equipment.

11. **Item cloning is unusable.** `CoGItem.lua:7–10` constructs CoGItem directly even though its constructor is protected. `clone()` of a subclass throws. Even if direct construction were enabled, this implementation would discard the concrete subclass, item state and flags, including Inimitable. Reproduced error; state-loss risk confirmed in source.

12. **Inherited event/affix operations have multiple defects.** `CoGObject.lua`:
    - `:147` reads lowercase private `eventrix`, while initialization/application uses uppercase private `Eventrix` and the declaration is in protected storage. `fireEvent()` fails in the downstream probe.
    - `:91–93` calls nonexistent `Rarity.getPrefixCount/getSuffixCount` and accesses undeclared `pri.prefixes/suffixes`; Rarity exposes `getMaxPrefixCount/getMaxSuffixCount`.
    - `:95` takes `#` of an affix-keyed dictionary, which does not count its entries or separate prefix/suffix totals. Capacity enforcement would remain wrong after fixing method names.
    - `:154` reads `tAffixes` before its local declaration. Removal also uses inconsistent sorted-list names and never removes an affix from an ordered display list.
    - `:193–201` getters read undeclared `maxPrefixes/maxSuffixes`.
    - Affix documentation describes event IDs mapped to lists of hooks, while `applyAffix` only accepts a direct function value, silently skipping lists. The contract must be made consistent.

13. **Affix compatibility is effectively always true for classes.** `Affix.lua:197–215` initializes the return value to `class.is(cType)` and never sets it false if no compatible class matches. Its ancestry test is also reversed: the candidate should be a child of the allowed class. Consequently restrictions are not actually enforced. Source-confirmed; normal Affix construction has its own missing superclass parameter/call at `:130`, so a clean end-to-end affix test remains blocked.

## Other bugs and unfinished behavior

14. **Clear is a no-op; individual inventory removal does not exist.** `ItemSystem.lua:146` has an empty body. Calling it leaves the item count unchanged. There is no `removeItem`/`removeItemAt` implementation, so there is no supported way to free a normal inventory position or perform a transfer using the basic public API.

15. **Inventory ownership is absent.** `ItemSystem.lua:213` accesses `pro.owner`, which is neither declared nor assigned; the getter throws. Slot/stash ownership has TODO validation, and ItemSlot's Owner remains null instead of being associated when registered. A coherent owner/container contract is missing.

16. **Disabled slots still accept items.** `ItemSlot.lua:123–136` checks Locked and type compatibility but never Enabled. `setEnabled(false)` followed by a valid `set(item)` succeeds. Reproduced. Whether disabled slots should permit removal is a policy decision, but disabling currently does not prevent placement.

17. **References can be duplicated across slots and inventories.** No duplicate or single-container ownership checks exist. The same item can be added twice, and the same ItemSlot can be registered twice. Both reproduced. Counts then represent positions/references rather than distinct physical objects, and forced replacement has no ownership transfer or displaced-item handling.

18. **Item flags do not enforce gameplay rules.** Exclusive, Stackable, Removable, Equipable, Inimitable and related flags are primarily metadata. There is no quantity merging, exclusive-item admission rule, non-removable check in ItemSlot.remove, or enforced copy restriction. Plain storage may intentionally be low-level, but callers need an explicit higher-level policy layer rather than assuming these flags are enforced here.

19. **Backing arrays are exposed through iterator state.** Inventory `iterator()`/`__pairs` and slot `eachSlot()`/`__pairs` return internal storage as the iterator state. A caller can retrieve and mutate it, bypassing validation and capacity constraints. A probe inserted a string into an inventory this way, and `getItemAt()` returned it.

20. **Validation/return contracts need tightening.** Numeric item fields accept negative/nonfinite values; capacity/tab normalization can turn invalid nonpositive values into unlimited capacity rather than rejecting them. Index validation is inconsistent. ItemSlot.set accepts any truthy force-removal argument, not necessarily a boolean. Inventory.addItem returns `(success, self)`, while slot set/remove return `(self, success)` and some registration methods return nothing. These are limitations/inconsistencies rather than all being immediate failures.

21. **Affix iteration and callback environments are unsafe/incomplete.** `Affix.lua:187` omits `this, cdat` while accessing `cdat`. `:245–262` restores `_ENV` only after successful callbacks; an exception skips restoration. Environment selection changes the wrapper's environment rather than necessarily the supplied callback's environment, so the intended callback isolation needs a separate design/test. Source findings.

## What currently works in isolated tests

Once item construction is adapted in memory, a compatible ItemSlot can hold and retrieve an item. Explicit addItemSlot registration, slot-count retrieval, and ordinary inventory append/count work. These successes do not cover persistence, initialized slots, ownership or affix behavior. The existing browser ItemSlotSystem tutorial primarily demonstrates empty-slot registration, so its passing result does not establish that the full item system works.

## Repair order

1. Fix constructor chaining, member declarations and init registration.
2. Repair inventory capacity/initialization, removal and Clear.
3. Repair slot initialization, correct API names, membership/counts and atomic swapping.
4. Define ownership, duplicate-item, enabled-slot and item-flag policies.
5. Repair item cloning/persistence and affix/event contracts.
6. Add regression checks covering real item subclasses, capacity failures, transfers, typed/locked/disabled slots, failed swaps without partial mutation, flags, copies and affix removal.

Core implementation files were not modified by this review.
