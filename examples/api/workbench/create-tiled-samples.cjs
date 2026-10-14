// Rebuild the small, editable TMX/TSX/PNG fixtures used by the Tiled tutorial.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const directory = path.resolve(__dirname, '../../resources/tiled');
fs.mkdirSync(directory, {recursive: true});

function crc32(bytes) {
    let crc = 0xffffffff;
    for (const byte of bytes) {
        crc ^= byte;
        for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
    }
    return (crc ^ 0xffffffff) >>> 0;
}

function chunk(name, data) {
    const type = Buffer.from(name);
    const size = Buffer.alloc(4);
    size.writeUInt32BE(data.length);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(Buffer.concat([type, data])));
    return Buffer.concat([size, type, data, crc]);
}

function image(name, axis) {
    const width = 192, height = 48;
    const pixels = Buffer.alloc((width * 4 + 1) * height);
    const colors = [[82, 146, 78], [146, 102, 61], [76, 82, 91]];
    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const dx = Math.abs(x % 64 + 0.5 - 32);
            const dy = Math.abs(y + 0.5 - 24);
            const inside = !axis || (axis === 'x' ? dx <= 8 + 24 * (1 - dy / 24) : dy <= 8 + 16 * (1 - dx / 32));
            const offset = y * (width * 4 + 1) + 1 + x * 4;
            const color = colors[Math.floor(x / 64)];
            const shade = ((x + y) % 13 < 2) ? 12 : 0;
            pixels[offset] = color[0] + shade;
            pixels[offset + 1] = color[1] + shade;
            pixels[offset + 2] = color[2] + shade;
            pixels[offset + 3] = inside ? 255 : 0;
        }
    }
    const header = Buffer.alloc(13);
    header.writeUInt32BE(width, 0);
    header.writeUInt32BE(height, 4);
    header[8] = 8;
    header[9] = 6;
    fs.writeFileSync(path.join(directory, name + '.png'), Buffer.concat([
        Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
        chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(pixels)), chunk('IEND', Buffer.alloc(0)),
    ]));
}

const cells = [];
for (let y = 0; y < 5; y++) {
    const row = [];
    for (let x = 0; x < 7; x++) row.push(x === 3 && y >= 1 && y <= 3 ? 3 : y === 2 && (x === 1 || x === 2) ? 2 : 1);
    cells.push(row.join(','));
}

for (const [name, axis] of [['square', null], ['hex-flat', 'x'], ['hex-pointy', 'y']]) {
    const startX = 32, startY = axis === 'y' ? 88 : 120;
    const endX = axis === 'x' ? 272 : 416, endY = startY;
    image(name, axis);
    fs.writeFileSync(path.join(directory, name + '.tsx'), `<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" name="Sample terrain" tilewidth="64" tileheight="48" tilecount="3" columns="3">
 <image source="${name}.png" width="192" height="48"/>
 <tile id="0" type="Grass"/>
 <tile id="1" type="Mud"><properties><property name="AStar" type="class"><properties>
  <property name="aspects" type="class"><properties><property name="mud" type="float" value="0.75"/></properties></property>
 </properties></property></properties></tile>
 <tile id="2" type="Wall"><properties><property name="AStar" type="class"><properties>
  <property name="passable" type="bool" value="false"/>
 </properties></property></properties></tile>
</tileset>
`);
    fs.writeFileSync(path.join(directory, name + '.tmx'), `<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="${axis ? 'hexagonal' : 'orthogonal'}" renderorder="right-down"
 width="7" height="5" tilewidth="64" tileheight="48" infinite="0" nextlayerid="3" nextobjectid="3"${axis ? ` staggeraxis="${axis}" staggerindex="odd" hexsidelength="16"` : ''}>
 <tileset firstgid="1" source="${name}.tsx"/>
 <layer id="1" name="Ground" width="7" height="5"><data encoding="csv">
${cells.join(',\n')}
 </data></layer>
 <objectgroup id="2" name="Actors">
  <object id="1" name="Scout" x="${startX}" y="${startY}"><point/><properties><property name="AStar" type="class"><properties>
   <property name="layer" value="Ground"/><property name="tileX" type="int" value="0"/><property name="tileY" type="int" value="2"/>
   <property name="rover" type="bool" value="true"/>
   <property name="affinities" type="class"><properties><property name="mud" type="float" value="0.5"/></properties></property>
   <property name="aversions" type="class"><properties><property name="mud" type="float" value="1"/></properties></property>
   <property name="movePoints" type="class"><properties><property name="max" type="float" value="200"/><property name="current" type="float" value="200"/></properties></property>
  </properties></property></properties></object>
  <object id="2" name="Destination" x="${endX}" y="${endY}"><point/><properties><property name="AStar" type="class"><properties>
   <property name="layer" value="Ground"/><property name="tileX" type="int" value="6"/><property name="tileY" type="int" value="2"/>
  </properties></property></properties></object>
 </objectgroup>
</map>
`);
}
console.log('Created square, flat-top hex and pointy-top hex sample maps.');
