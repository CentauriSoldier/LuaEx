# LuaEx examples

Open `Examples.html` in the repository root. The examples and Lua runtime load
automatically from the included JavaScript bundle. The page works offline,
including when opened directly from disk. There are no folder prompts, uploads,
downloads, installations, or external services.

Alternatively, double-click `Open Examples.cmd` in this folder. It uses
the portable Node executable in `api/node`, starts a loopback-only static server,
and opens the page. Nothing is installed. Close its console to stop the server.
Any ordinary static web host can also serve this repository.

## Organization

| Folder | Contents |
| --- | --- |
| `fundamentals` | Arrays, enums, structs, and Eventrix events |
| `collections` | Queue, Stack, Set, SortedDictionary |
| `components` | Pool, Potentiometer, Protean, ItemSlotSystem |
| `classes` | Creature → Human → Soldier inheritance and Factorium blueprint factories |
| `geometry` | Point and Line |
| `pathfinding` | Square and staggered hex AStar scenarios |
| `utilities` | CSV, INI, QR, Dox documentation and TagSystem |
| `visual/AStar` | Shared Lua AStar model, browser bridge, and temporary Budo frontend |
| `visual/Pool` | Health and Mana globes, Stamina meter and interactive LuaEx resource controls |
| `utilities/textcatalog.lua`, `visual/TextCatalog` | Interactive dialogue desk and independent text catalog tutorial |
| `cog/Vehicles.lua`, `visual/Vehicles` | Illustrated vehicle garage and independent constructor, component and cloning tutorial |
| `resources/vehicles` | Rover, cargo airship and survey skiff illustrations, with art prompts |
| `resources` | CSV/INI inputs and the QR image |
| `api` | Local Wasmoon, optional Node, and workbench code; see its license README |

Load headers locate the repository portably; CSV, QR, and documentation paths
follow the new layout. Older experiments were updated to the current public APIs
and moved into their topic folders. Every catalog example is checked in Wasmoon;
the site shows actual output and errors when run.

## Using the workbench

Select a module from its topic folder. Every module page has **Visual** and
**Code** tabs. AStar and Pool contain the existing interactive visuals and all
their controls. Other modules clearly indicate when no visual has been created.
Potentiometer also has a visual comparison of Clamp, Wrap and Bounce, with shared
bounds, position and rate controls, individual direction readouts, stepping,
signed adjustment, playback and movement history.
Protean’s Visual tab is a character sheet with base and modified attributes,
stackable curses/buffs, all six modifier categories, explicit calculation stages,
optional limits, manual recalculation and callback controls. Advanced sections
demonstrate signed adjustments, shared linked bases, independent copies,
serialization, read-only Final and callback locks. Reset controls distinguish
removing effects, clearing modifiers and restoring original stat/character state.
The enum module has a replacement code tutorial and a visual inspector
covering payload types, duplicate payload identity, navigation, validation,
cloning, canonical snapshots and custom numeric definitions. Its Code tab also
demonstrates private and nested enums.
The Code tab loads an independent tutorial from `code/`, with literal values you
can edit directly before **Run code**. There are no separate parameter controls
on Code tabs. Visual runs keep their own Lua session, so running Code and
switching back preserves the visual state. Code drafts persist while browsing
modules within the page; Restore source resets the editor to the included file.
Every console tutorial has at least six explained sections, labelled typed values,
verified checks and a final summary. Expected validation errors and current API
limitations are labelled separately. All 26 console examples are verified with
both default and changed parameters; the visual AStar bridge has movement and
terrain checks. Console output and errors appear
under Source & output. Runs use fresh environments; Stop terminates the worker,
including an infinite loop. Code edits are kept in the page;
the page never overwrites repository files. Lua file writes occur in a virtual
filesystem. Generated files are reported in the output and remain in memory.

In the AStar laboratory, select a terrain tool and drag the map. Right drag
erases. Place party requires grassland; goals can be previewed on any terrain.
Enable **Goal follows cursor** to replan while hovering, then click to pin it.
Disable **Auto-update path** to make changes and use **Update path** manually.
Hovering and painting preserve movement budgets and party positions.
Humans, elves, goblins and dwarves have visible affinities, aversions and refusals.
Add/remove creatures, clear a party, or manage up to six independent parties.
Every member must satisfy terrain and port rules. Paired caves are actual LuaEx
ports available only to goblin-only parties; their entrances remain walkable.
Random maps form connected biomes, mountain ridges and a traversable trade road.
Step commits one move; Next turn replenishes budgets; Play traverses the planned
route and pauses at a turn boundary. Green is reachable this turn; gold numbers
show future turns. Save map keeps a snapshot in the page; Restore map restores it.
No file picker or browser download is involved. The saved map lasts until reload.
Snapshots include terrain, endpoints, all party compositions and positions;
restoring restarts their movement budgets. Icons are original local vector artwork
in `api/workbench/fantasy-icons.js`, with no font, CDN or license dependency.

The browser uses LuaEx's real Lua 5.4 logic. It draws snapshots of the Lua model;
it does not reimplement AStar in JavaScript or require Budo.

The **Pool Visual tab** shows red Health and blue Mana globes and a green
Stamina meter. Colored fill is current resource; stripes mark reserved capacity.
Use the sliders or Spend/Restore/Empty/Full controls, edit each resource's settings
and Apply, or advance regeneration cycles manually or once per second. Negative
regen drains a resource. Rejected configurations preserve all previous settings.
The event log shows actual LuaEx Pool callbacks. Auto regen pauses when switching
tabs or modules, stopping the runtime or hiding the page. The independent Pool
code tutorial is available in the same module's Code tab.

After changing repository examples, regenerate the local browser bundle with
`api/node/node.exe api/workbench/bundle.cjs` from this folder. The optional
launcher also rebuilds it automatically. This is a developer maintenance step,
not part of using the page.
