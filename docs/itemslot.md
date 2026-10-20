# ItemSlot

ItemSlot now participates in the shared item-system containment rules. See [Item system](item-system.md) for constructor arguments, stacking, registry eligibility, location tracking, replacement, transfers, actions and grid semantics.

`ItemSlot(vAllowedItems, nCapacity, oOwner, sName)` defaults to CoGItem eligibility and capacity one. vAllowedItems accepts an ObjectRegistry retained by reference or an entries array. getAllowed_Items/getCapacity/getOwner/getName expose the configuration; getSystem identifies the actual parent system. setCapacity validates the final contents and rejects shrinking below their count.

get/getItem returns the first instance by default or an optional one-based index. eachItem yields a snapshot iterator; getItemCount and #slot count actual instances. set/setItem appends, or replaces the first instance at full capacity when explicitly requested. remove accepts no argument, an index, or an exact instance. Removal and replacement return the affected item.

Direct slot calls enforce the complete parent hierarchy, so stash/system rules cannot be bypassed by selecting a lower-level entry point. Parent and leaf locks/disabled state both apply. Coordinate patterns remain data; optional ItemSlotSystem grid placement interprets them.
