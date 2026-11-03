# Text catalog example

Open the root `Examples.html` and choose **Utilities → Text catalog**.
The **Visual** tab is an interactive dialogue desk; the **Code** tab runs an
independent tutorial with literal values you can edit. Their Lua sessions are
separate, so editing a conversation never changes the Code tutorial's objects.

## Explore the desk

1. Compare the two conversation cards. Each is a real `textcatalog` object with
   the same hierarchy and different variable bindings.
2. Choose `dialogue.merchant` in the tree to activate it. Run `gettext` with
   `greeting`, or `findtext` with `HELLO`. Both use the active scope.
3. Uncheck **Omit scope** and leave the explicit scope empty to search the root.
   Try `100%?` to see literal matching. Try `traveler` to see an ambiguous match;
   the library intentionally does not promise which matching entry comes first.
4. Set `friend` to another string. The selected rendered preview and conversation
   card update on every state refresh. Search for that value: it does not match
   unless the value appears in a stored template. Search happens before rendering.
5. Select `dialogue.merchant.contact`, then choose the no-chaining demonstration.
   It sets `friend` to `${player}`. The inserted placeholder remains literal.
   Select `dialogue.merchant.literal` to see `$${friend}` output `${friend}`.
6. Clear a variable or all variables. The complete missing placeholders remain
   visible. Switch conversations to verify that their variables are independent.
7. Edit the selected stored template. `settext` changes only that existing string;
   it cannot add/delete entries or replace a node. Empty string wording is valid.
8. Run `findnode` with `rum`, or `getnode` for the active node's nested snapshot.
   **Test snapshot isolation** adds an entry to a returned table and verifies it
   is absent from a fresh catalog snapshot. Last-call results are snapshots too:
   run the operation again when you want a result using the latest variables.
9. Save a checkpoint, change text/variables/scope, then restore. The example uses
   the global `serialize` and `deserialize` calls and displays the actual saved
   string. Restoration retains raw templates, variables and active-node selection.
10. Clone into the other conversation, edit it, then switch back to compare.
    Contract probes display expected rejections while retaining the live state.

All paths and queries are case-insensitive; declared names and wording keep their
spelling. Explicit scopes start at the root, while omitted scope uses the active
node. A search with no match returns nil and the valid scope's full path; an invalid
scope returns nil, nil. The root's path is the empty string.

The navigation tree is sorted only for display. It does not impose search order.
The inspector maintains its own mirror of known source templates and variable
edits because public node snapshots are rendered. It never accesses catalog
private state or replaces the actual Lua implementation of lookup/rendering.

## Files and verification

- `definition.lua`: initial wording for the visual example.
- `browser.lua`: state and action bridge to real public catalog methods.
- `../../utilities/textcatalog.lua`: standalone tutorial.
- `../../code/utilities/textcatalog.lua`: independent Code-tab tutorial copy.
- `../../api/workbench/textcatalog-view.js` and `textcatalog.css`: visual renderer.
- `../../api/workbench/verify-textcatalog.cjs`: real Lua action and tutorial checks.

Run from the repository root:

```powershell
.\examples\api\node\node.exe examples/api/workbench/verify-textcatalog.cjs
.\examples\api\node\node.exe examples/api/workbench/bundle.cjs
```

The verifier updates this example's verification entry. The bundle command embeds
the current library and example sources for offline use, including direct disk
launch. No extra assets, network service or package installation is needed.
