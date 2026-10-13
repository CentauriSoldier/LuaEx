# AStar laboratory (Budo / Lua 5.4)

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\examples\visual\AStar\run.ps1
```

Requires the portable runtime at `Budo/budo.exe`. The launcher works from any directory.
You can also double-click `run.cmd` in this folder.
Labels use a built-in pixel font because this Budo Windows build has no working
Skia font manager. No font installation or downloaded assets are needed.

Select Ground, Wall, Marsh, Rock, Start or Goal, then click/drag the grid. Right drag erases terrain. Start and Goal can only be placed on ordinary ground. Edits restart both rovers and replan the route.

PLAY animates committed group movement; STEP moves one cell; TURN regenerates movement points. Playback pauses when a new turn is needed. Space toggles playback, N steps and T advances the turn. SLOW/FAST adjusts playback between 1 and 10 steps per second.

Green route cells are reachable now; gold cells show the number of future turns needed. Two dots mark the soldier and scout. This animates route traversal, not internal AStar search expansion: the current Path API computes synchronously.

The soldier abhors rock and pays 15 points for marsh; the scout pays 5 for marsh and discards leftover points on a new turn. Both move together, start with 25 points, have capacity 40, and regenerate 20. The sidebar displays each budget, remaining path costs, and turn preview.

RESET restores a fixed scenario; RANDOM uses LuaEx RNG to generate terrain (some maps intentionally have no route). SAVE/LOAD round-trips terrain and endpoints through LuaEx serialization into `saved/map.luaex`; loading resets movement. Only load snapshots produced by this example.

Modules exercised: AStar, LayerConfig, Path, Rover, Pool, Protean terrain affinity/aversion and impactors, RNG, enum, Potentiometer, TagSystem, clone, serialize and deserialize. The model asserts that planning never spends points and that group steps commit both rovers before callbacks.

Model checks followed by a short automated window/rendering check:

```powershell
.\Budo\budo.exe run .\examples\visual\AStar\check --width 1120 --height 800
```
