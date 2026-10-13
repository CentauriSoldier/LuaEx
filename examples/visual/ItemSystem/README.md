# Item-system laboratory

Open the repo-root Examples.html, then choose **CoG → Item system**. The Visual tab runs examples/visual/ItemSystem/browser.lua; the independent Code tab runs examples/code/components/ItemSlotSystem.lua. Everything uses the bundled Lua 5.4 runtime, local JavaScript and CSS. No upload, folder selection, installation or server is required.

The 20 starter instances occupy a 4×4 character inventory, a three-tab stash, a ground inventory and a shop. Character and merchant owners are generic CoG actor objects, not creatures. Their names and traits are example data. The lab also distinguishes each item's legal owner from its actual container's owner.

Try these experiments:

1. Select Festival kite in the shop. Choose stash tab 2, then Move (lab). Wind kite in tab 1 causes a whole-stash exclusivity rejection. The rejected item remains in the shop. Buy it into an empty character cell instead; wallets and legal ownership update only after a successful trade.
2. Select Elven sentinel helm. Compare the active Human adventurer and Elf merchant, or edit required race, level and strength. The real Equipable_By callback checks those traits and legal ownership.
3. Select the longsword. Damage it to zero, then repair it. Zero durability does not delete it. Upgrade/downgrade is an example effect gated by the real item permissions.
4. Turn off Grid footprints. Move a second potion into the first potion's slot. Consume one instance; the other stays. Turn grid mode on again to see overlapping stacked footprints rejected until you separate them.
5. Select Ruby focus gem. Take out, choose a weapon host, then Attach gem. The relationship is real, and the gem has no independent inventory location. Detach returns it to the unplaced collection.
6. Change a stored item's footprint to overlap its neighbor, or change Storable_In to Nowhere. Apply rejects the edit and preserves the previous item. The editor keeps the draft so you can correct it.
7. Lock a container or a footprint cell. Movement and clearing honor the actual hierarchy. Shrinking capacity below the contents never discards items.
8. Add stash tabs, remove empty ones, create new items, copy them, and delete them. Copying preserves properties through this concrete item's __clone; the lab normally honors Inimitable, with an explicit override for testing caller policy.

Click items to inspect them; on narrow screens the inspector is brought into view. Drag/drop and Move (lab) are administrative containment operations. They intentionally do not charge money or rewrite legal ownership. Buy/Sell use the real trade methods, actor permissions and the application's wallet policy. Delete is an editor operation, not a destruction feature. Clearing a container moves its instances into the unplaced collection rather than deleting them.

Properties include names/descriptions, kinds, rarity, legal owner, durability Pool current/maximum, value/weight/size Pools, actor prerequisites, action registries, storage scopes, exclusivity group/context, relative coordinates and Inimitable metadata. Failed property edits preserve the item and existing membership. At most 80 live instances and eight stash tabs are allowed in this browser lab.

Switching to Code preserves the running visual state. Reset laboratory restores all 20 starter items and wallets. Changes are in memory; a page reload or Run visual starts a fresh lab.

Verification: examples/api/node/node.exe examples/api/workbench/verify-items.cjs. It checks seeded counts, ownership, permissions, rejected wallet changes, whole-stash exclusivity, edit rollback, grid/stack behavior, single-instance consumption, attachments, copying/deletion, creation, slot swaps, capacity, locks, tab management and reset.
