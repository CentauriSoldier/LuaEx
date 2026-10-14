# Tiled maps and CoG AStar

`Tiled` is a CoG class at `LuaEx/inc/cog/Tiled.lua`. One instance holds one editable
TMX map. The XML class stays generic; the internal `tiled` helpers interpret Tiled's
format, projection and AStar settings.

```lua
local oTiled = Tiled("maps/world.tmx");
local tTile = oTiled.getTile("Ground", 0, 0);
local nPixelX, nPixelY = oTiled.tileToPixel(0, 0, "Ground");
local nColumn, nRow = oTiled.pixelToTile(nPixelX, nPixelY, "Ground");

local tNavigation = oTiled.toAStar("world");
local oNode = tNavigation.map.getNode("Ground", 0, 0);
local oRover = oNode.createRover();
local oPath = AStar.Path(oNode, tNavigation.map.getNode("Ground", 3, 2), oRover);
```

Coordinates are native Tiled coordinates: column/row zero is the first cell, and
infinite maps can have negative coordinates. `tileToPixel` consistently returns the
**displayed cell center** for every orientation. These displayed pixels differ from
the unprojected object coordinates stored in isometric and oblique TMX files.
An optional layer selector accounts for inherited group/layer offsets. Projection
does not apply a camera's zoom or parallax scrolling.

Supported orientations are orthogonal, isometric, staggered isometric, hexagonal and
oblique. Hex and staggered maps retain their `staggeraxis` and `staggerindex`.
Finite tile layers, infinite chunks, nested groups, image layers and object layers
share the same query interface. Negative cells preserve their native parity.

## Loading and querying

`load(path, reader, decompressor)` reads a file. `parse(XML, path, reader, decompressor)`
reads source text. The optional path is the **containing map filename**, so a relative
TSX, template, image or file property has a known base directory.

The optional reader receives a resource path and returns XML source. Without it,
the class uses `io.open`. Both external TSX tilesets and XML object templates are
resolved and cached. Templates are expanded, instance attributes/properties override
template defaults, and tile object GIDs are remapped into the map's tilesets.

Tile data can be XML tiles, CSV or base64. Compressed base64 delegates to the program:

```lua
local oTiled = Tiled("maps/world.tmx", readXML, function(sBytes, sFormat, nExpected)
    -- The program supplies its own zlib/gzip/zstd library here.
    return decompress(sBytes, sFormat, nExpected);
end);
```

The callback must return exactly the expected number of decompressed bytes. LuaEx
does not bundle these compression libraries. Choose CSV or uncompressed base64 in
Tiled when no decompressor is supplied. Loaded tile data becomes CSV internally, so
later edits, cloning and deserialization do not need the original decompressor.

Queries return independent copies:

| Method | Result |
| --- | --- |
| `getMap()` | Map attributes and typed map properties |
| `getLayers()` | All layers in depth-first draw order, including groups |
| `getLayer(IDOrName)` | Layer, effective offsets/visibility/opacity/parallax and chunks |
| `getObjects(layer?)` | Ordered objects, optionally in one object layer |
| `getObject(ID)` | One object, including raw shape/text XML |
| `getProperties(layer?, objectID?)` | Map, layer or object properties |
| `getTilesets()` | Ascending GID ranges, sparse tile definitions, images and animation |
| `getTile(layer, x, y)` | Resolved tile/tileset and transformation flags |
| `resolveGID(rawGID)` | The same tile resolution without cell placement |
| `getDocument()` | Canonical XML root, retaining advanced and unknown TMX metadata |
| `getXML()` | Canonical TMX source |

A layer name must be an exact, unique match. Use IDs when names repeat. `getTile`
returns a record with `gid = 0` for a present empty cell, and `nil` for an absent
cell or an unallocated infinite chunk. All four GID flags are retained and stripped
before tileset lookup. Hexagonal rotation flags are available alongside flip flags;
the program interprets them according to the map orientation.

Property records have `type`, `propertyType`, `value`, `rawValue` and `raw`. A class
property's `value` contains named property records; a list contains ordered property
records. Numeric values and booleans retain their types, object properties retain
object IDs, and file properties resolve against their containing XML file. Custom
class/enum names remain descriptive Tiled metadata, rather than LuaEx classes.

XML only exports explicitly supplied class members. Defaults defined solely in a
Tiled project file are not loaded by this TMX reader. Supply the relevant members
explicitly when their values must be imported. Advanced data such as collision
shapes, Wang sets, tile alignment, tint colors, text and blend modes is retained in
raw XML; the class does not render or automatically simulate those features.

## Creating and editing

```lua
local oTiled = Tiled().create({
    orientation = "hexagonal",
    width = 20,
    height = 20,
    tilewidth = 64,
    tileheight = 48,
    staggeraxis = "y",
    staggerindex = "odd",
    hexsidelength = 16,
});

local nGround = oTiled.addLayer({attributes = {name = "Ground"}});
local nActors = oTiled.addLayer({kind = "objectgroup", attributes = {name = "Actors"}});

-- Embed a TSX definition before placing its GIDs.
local nFirstGID = oTiled.addTileset(readXML("tiles/terrain.tsx"), nil, "tiles/terrain.tsx");
oTiled.setTile(nGround, 4, 6, nFirstGID);
oTiled.setTileProperty(nFirstGID, "AStar", {aspects = {mud = 0.75}}, "class");
oTiled.setAttribute("visible", true, nGround);
oTiled.setProperty("weather", "rain");

local nScout = oTiled.addObject(nActors, {
    attributes = {name = "Scout"},
    properties = {AStar = {
        layer = "Ground",
        tileX = 4,
        tileY = 6,
        rover = true,
        affinities = {mud = 0.5},
        aversions = {sand = 1},
        movePoints = {max = 100, current = 100, cycleFlat = 10},
    }},
});

local tNavigation = oTiled.toAStar("created");
local oScout = tNavigation.rovers[nScout];
oTiled.save("maps/created.tmx");
```

Embedded TSX image/file references are relative to the map filename. For an unloaded
programmatically created map, that base is the current working directory. Definitions
read from another location can pass their containing TSX filename as the third
`addTileset` argument to rebase those references. Definitions
accepted by `addLayer`, `addObject` and table-form `addTileset` have `attributes`,
`properties` and `children`. Children use the XML element shape:

```lua
local tImage = {
    kind = "element",
    name = "image",
    attributes = {source = "assets/terrain.png", width = "64", height = "32"},
    children = {},
    content = {},
};

oTiled.addTileset({
    attributes = {name = "Terrain", tilewidth = 32, tileheight = 32, tilecount = 2, columns = 2},
    children = {tImage},
});
```

New finite layers contain empty cells. Painting an infinite map outside its existing
chunks creates a one-cell chunk. `removeObject` and `removeLayer` retain other IDs;
removing a group removes its descendants. `setProperty` and `setTileProperty` accept
nil to remove a property. Plain Lua values infer string, float, bool or class/list
types; explicitly select `int`, `file`, `object`, `color`, `class` or `list` as needed.
Property tables must be acyclic; lists must be contiguous.

`setTileProperty` edits the shared tile definition, affecting every occurrence of
that tile in this map. If the definition came from external TSX, the class embeds
and rebases it before editing; it does not write to the original TSX file.

For batch edits or any advanced TMX field, use `edit(function(root) ... end)`. The
callback gets a copied XML root. Element nodes belong in both `children` and
`content`, referencing the same node. The class reparses and validates the result
before committing it. Ordinary setters also validate the complete replacement;
batch large edits in one callback rather than repeatedly rebuilding large maps.

`save(outputPath, writer?)` writes TMX and rebases references to the output location.
Use consistently absolute or consistently relative filenames when rebasing. The
optional writer receives `(path, XML)` and should raise an error on failure. External
resource files are not rewritten. Clone and native serialization include cached
resource XML, so restoration does not read files. The resulting navigation map is
independent: subsequent Tiled edits require a fresh `toAStar` import.

## AStar properties authored in Tiled

Create a **class property named `AStar`** on a map, group, tile layer, tileset, tile
definition or object. The custom class's `propertytype` can have any name; the
property name `AStar` selects integration. There are no per-field `astar.` prefixes.
Define nested custom property classes for your program's named aspects/responses.

```xml
<properties>
    <property name="AStar" type="class" propertytype="Navigation">
        <properties>
            <property name="passable" type="bool" value="true"/>
            <property name="aspects" type="class" propertytype="TerrainAspects">
                <properties>
                    <property name="mud" type="float" value="0.75"/>
                    <property name="sand" type="float" value="0.25"/>
                </properties>
            </property>
        </properties>
    </property>
</properties>
```

Node defaults merge in order: **map → tileset → tile → ancestor groups → layer**.
Later explicit fields override earlier fields at the same location. Object settings
then overlay their target node. Missing aspects start at 0. Present cells default
to passable, including GID 0; absent chunk cells are blocked. Set map/layer/tile
properties explicitly to impose a different rule.

| AStar member | Meaning |
| --- | --- |
| `passable` | Boolean node passability |
| `aspects` | Named numeric intensities from 0 to 1 |
| `layer` | Object's target tile layer ID or unique exact name; optional with one selected layer |
| `tileX`, `tileY` | Optional paired native object anchor coordinates |
| `rover` | Create a native rover on the object's target node when true |
| `affinities`, `aversions` | Named numeric rover responses |
| `abhors` | Named boolean rover abhoration flags |
| `types`, `deniedTypes` | Lists of rover type strings |
| `allowedLayers` | Named boolean rover layer permissions |
| `retainsPointsOverCycle` | Native rover point-retention flag |
| `movePoints` | `max`, `current`, `cycleFlat`, `cyclePercent` |
| `ports` | List of target Tiled object IDs; each target needs an AStar property |
| `twoWay` | Ports are bidirectional by default; false makes outgoing-only ports |

Rover/port members apply to object properties. Objects without `tileX`/`tileY` use
their TMX position anchor, translated through their object layer and target tile
layer offsets. For tile objects, this is their TMX placement anchor, not an image's
visual center. Specify native coordinates when an exact spawn cell matters.

`toAStar(name, existingSystem?, options?)` creates a system automatically from every
referenced aspect name, or verifies an existing system includes them. Tile layers
must have nonblank names unique ignoring case. Options can select `layers` by
ID/name, limit `bounds = {x, y, width, height}`, and supply:

```lua
configureNode = function(oNode, tTile, tSettings, nX, nY, nTiledLayerID)
    -- Install your own application rules through the ordinary native APIs.
end
```

Infinite maps use a dense AStar rectangle around selected chunks, with holes blocked.
Use explicit bounds for a manageable navigation region on large sparse maps. Native
square topology covers orthogonal, isometric and oblique grids; hex topology has six
neighbors; `AStar.MAP_TYPE_STAGGERED` has the four slanted edge-sharing neighbors of
staggered isometric grids. Affinities, aversions, movement costs, group paths, cycles,
ports and callbacks continue through the existing native AStar objects.

The bridge result contains `system`, `map`, `bounds`, `layers` keyed by Tiled layer
ID, `objectNodes` keyed by object ID, and `rovers` keyed by spawned object ID.
Data validation happens before map creation. A `configureNode` callback executes
after native registration; if that callback fails, a supplied system retains the
partially configured map. Use a fresh system for application callbacks that can fail.

This module consumes TMX/TSX/template XML. JSON/Lua exports, Tiled project files,
rendering, image decoding and DTD processing are outside this module.

The format/projection details were checked against the official [TMX reference](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/),
[GID reference](https://doc.mapeditor.org/en/stable/reference/global-tile-ids/), and
[Tiled 1.12.2 source](https://github.com/mapeditor/tiled/tree/v1.12.2/src/libtiled).

Run `examples/api/node/node.exe examples/api/workbench/verify-tiled.cjs` to verify the
import/edit/snapshot/projection/AStar regressions in the bundled Lua 5.4 runtime.

Open `Examples.html`, select **CoG → Tiled → Visual**, and click **Run visual** for
the interactive square/flat-top/pointy-top maps. Choose a scout or goblin, adjust mud
responses, step the route, advance turns, paint terrain, or download edited TMX.
Paired caves demonstrate native goblin-only port permissions. The webpage draws
projected data from Lua; the Tiled and AStar objects perform editing and navigation.
Run `examples/api/node/node.exe examples/api/workbench/verify-tiled-visual.cjs` for
the visual model's import, cave, movement, editing and export regressions.
