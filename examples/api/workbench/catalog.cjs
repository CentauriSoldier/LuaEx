const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../../..');
const descriptions = {
  'cog/Tiled.lua':'Load square and both hex orientations from TMX, import terrain and rover settings, and follow native AStar routes.',
  'fundamentals/array.lua':'Fixed arrays, type checks, iteration, and copying.',
  'fundamentals/enum.lua':'Named values, iteration, and enum serialization.',
  'fundamentals/struct.lua':'Structured records and their protected members.',
  'fundamentals/event.lua':'Eventrix hook ordering, activation and event pauses.',
  'components/Pool.lua':'Capacity, reservation, modifiers, regeneration, and events.',
  'components/Potentiometer.lua':'Clamped positions, adjustment, and serialization.',
  'components/Protean.lua':'Values and additive/multiplicative modifiers.',
  'pathfinding/AStar.lua':'Terrain-aware group routes and turn-by-turn movement.',
  'utilities/TagSystem.lua':'Normalized tags, activation, copying and serialization.',
  'utilities/CSV.lua':'CSV import/export against the bundled resource files.',
  'utilities/Ini.lua':'INI parsing, output, and expected error cases.',
  'utilities/DoxExample.lua':'Generate documentation from a known LuaEx source file.',
  'utilities/qr.lua':'QR encoding, text output, and an image in the virtual filesystem.',
};
function walk(directory, accept) {
  const result = [];
  for (const entry of fs.readdirSync(directory, {withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name))) {
    const file = path.join(directory,entry.name);
    if (entry.isDirectory()) { if (!['api','saved','check'].includes(entry.name)) result.push(...walk(file,accept)); }
    else if (accept(file)) result.push(path.relative(root,file).split(path.sep).join('/'));
  }
  return result;
}
function generate() {
  const library = walk(path.join(root,'LuaEx'), file => file.endsWith('.lua'));
  const allExamples = walk(path.join(root,'examples'), file => /\.(lua|csv|ini|png|tmx|tsx)$/.test(file));
  const groups = {cog:'CoG',fundamentals:'Fundamentals',collections:'Collections',components:'Components',geometry:'Geometry',utilities:'Utilities',pathfinding:'Pathfinding',classes:'Classes & factories',legacy:'Legacy experiments'};
  const entries = [];
  for (const file of allExamples) {
    const relative = file.slice('examples/'.length), category = relative.split('/')[0];
    if (!file.endsWith('.lua') || category === 'visual' || category==='code' || !groups[category]) continue;
    const name = path.basename(file,'.lua');
    entries.push({id:relative,title: category === 'legacy' ? `${name} (legacy)` : name,
      group:groups[category],path:file,kind:category === 'legacy' ? 'legacy' : 'console',
      description: descriptions[relative] || `${name} example from the ${groups[category].toLowerCase()} collection.`,
      ...(relative.startsWith('legacy/creatures/') ? {note:'Historical class experiments may require other globals and older APIs.'} : {})});
  }
  for(const entry of entries) {
    if(entry.id==='utilities/textcatalog.lua'){entry.title='Text catalog';entry.visualPath='examples/visual/TextCatalog/browser.lua';entry.visualType='textcatalog';entry.description='Explore central game text, persistent variables, active nodes, scoped searches, safe wording edits, snapshots and public serialization.';}
    if(entry.id==='cog/Vehicles.lua'){entry.title='Vehicles';entry.visualPath='examples/visual/Vehicles/browser.lua';entry.visualType='vehicles';entry.description='Explore an illustrated garage: fuel, trips, component identity, constructor settings, concrete cloning and validation.';}
    if(['components/Pool.lua','components/ItemSlotSystem.lua','pathfinding/AStar.lua','pathfinding/HexMap.lua','utilities/TagSystem.lua','classes/BlueprintFactory.lua','classes/Creature.lua','classes/Human.lua','classes/Soldier.lua'].includes(entry.id))entry.group='CoG';
    entry.codePath='examples/code/'+entry.id;
    if(entry.id==='cog/Tiled.lua'){entry.visualPath='examples/visual/Tiled/browser.lua';entry.visualType='tiled';entry.description='Explore square and both hex maps, scout/goblin terrain costs, cave permissions, path movement and TMX editing.';}
    if(entry.id==='cog/Cards.lua'){entry.title='Cards & decks';entry.visualPath='examples/visual/Cards/browser.lua';entry.visualType='cards';entry.description='Draw, shuffle, flip and edit real BaseCard instances across a deck, hand and discard pile.';}
    if(entry.id==='components/ItemSlotSystem.lua'){entry.title='Item system';entry.visualPath='examples/visual/ItemSystem/browser.lua';entry.visualType='items';entry.description='A tabbed stash, character inventory, ground and shop: edit, move, save and load items, with owner reconnection and permission checks.';}
    if(entry.id==='pathfinding/AStar.lua'){entry.visualPath='examples/visual/AStar/browser.lua';entry.visualType='astar';}
    if(entry.id==='components/Pool.lua'){entry.visualPath='examples/visual/Pool/browser.lua';entry.visualType='pool';}
    if(entry.id==='components/Potentiometer.lua'){entry.visualPath='examples/visual/Potentiometer/browser.lua';entry.visualType='pot';}
    if(entry.id==='components/Protean.lua'){entry.visualPath='examples/visual/Protean/browser.lua';entry.visualType='protean';}
    if(entry.id==='collections/Stack.lua'){entry.visualPath='examples/visual/Stack/browser.lua';entry.visualType='stack';}
    if(entry.id==='fundamentals/enum.lua'){entry.visualPath='examples/visual/Enum/browser.lua';entry.visualType='enum';entry.description='Explore enum identity, typed payloads, iteration, navigation, protection and serialization.';}
    const source=entry.visualPath?fs.readFileSync(path.join(root,entry.visualPath),'utf8'):'';entry.inputs=[];
    for(const match of source.matchAll(/D\.input\("([^"]+)"\s*,\s*("(?:[^"\\]|\\.)*"|-?\d+(?:\.\d+)?|true|false)\)/g)) {
      const value=JSON.parse(match[2]);const field={name:match[1],label:match[1].replaceAll('_',' '),type:typeof value,default:value};
      if(field.type==='number') {
        field.min=-1000;field.max=1000;field.step='any';
        if(['width','height'].includes(field.name)){field.min=3;field.max=12;field.step=1;}
        if(field.name==='slots'){field.min=0;field.max=8;field.step=1;}
        if(['maximum','health'].includes(field.name)){field.min=1;field.max=500;}
        if(['current','damage','weight','quantity','rate'].includes(field.name))field.min=0;
        if(field.name==='reservation'){field.min=0;field.max=0.9;}
        if(field.name==='position'){field.min=0;field.max=10;}
        if(field.name==='playback_speed'){field.min=1;field.max=10;field.step=1;}
        if(field.name==='multiplier'){field.min=0;field.max=2;}
        if(field.name==='version'){field.min=0;field.step=1;}
      } else if(field.type==='string') {
        field.maxLength=field.name==='text'?120:100;
        if(['name','label','title','tags','items','left','right'].includes(field.name))field.required=true;
        if(field.name==='label')field.pattern='[^,\\\\\\r\\n]+';
        if(field.name==='name')field.pattern='[^\\r\\n]+';
        if(field.name==='level')field.options=['L','M','Q','H'];
      }
      entry.inputs.push(field);
    }
  }
  const tests = walk(path.join(root,'tests'), file => file.endsWith('.lua'));
  const manifest = {version:1, runtime:'Lua 5.4 / Wasmoon 1.16.0',library,files:[...new Set([...library,...allExamples,...tests,'docs/intro.lua'])], entries};
  fs.writeFileSync(path.join(root,'examples/manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  return manifest;
}
if (require.main === module) { const result = generate(); console.log(`Catalog: ${result.entries.length} examples, ${result.files.length} virtual files`); }
module.exports = {generate, root};
