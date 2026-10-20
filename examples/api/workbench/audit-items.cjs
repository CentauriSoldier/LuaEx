// Read-only runtime reproductions for the item-system review. No core patches.
const fs=require('node:fs'),path=require('node:path');const {generate,root}=require('./catalog.cjs'),{LuaSession}=require('./runtime.js'),wasmoon=require('../wasmoon/package/dist/index.js');
(async()=>{const m=generate();let e;const make=()=>new LuaSession(wasmoon,new Uint8Array(fs.readFileSync(path.join(root,'examples/api/wasmoon/package/dist/glue.wasm'))),console.log);const files=Object.fromEntries(m.files.map(f=>[f,new Uint8Array(fs.readFileSync(path.join(root,f)))]));
 e=make();await e.boot(files);await e.lua.doString('print("Init inventory globals:",type(ItemSystem),type(ItemStashSystem));ReviewActualItem=class("ReviewActualItem",{}, {}, {}, {}, {ReviewActualItem=function(this,cdat,super)super("Sword","A sword") end},CoGItem);local ok,err=pcall(ReviewActualItem);print("Normal construction:",ok,err)');e.close();
 // Bootstrap adapters IN MEMORY to expose downstream failures. Actual
 // repository files remain unchanged, and baseline construction is checked above.
 const itemFile='LuaEx/inc/cog/Objects/ItemSystem/CoGItem.lua',objectFile='LuaEx/inc/cog/Objects/CoGObject.lua';
 files[itemFile]=new TextEncoder().encode(fs.readFileSync(path.join(root,itemFile),'utf8').replace('function(this, cdat, sName','function(this, cdat, super, sName'));
 files[objectFile]=new TextEncoder().encode(fs.readFileSync(path.join(root,objectFile),'utf8').replace('function(this, cdat, sName','function(this, cdat, super, sName').replace('local pri = cdat.pri;\n        local pro = cdat.pro;','super();\n        local pri = cdat.pri;\n        local pro = cdat.pro;').replace('_eRarity[1]','Rarity.LEVEL[1]').replace('affixDisplayOrder   = {},','Eventrix = null,\n    affixDisplayOrder = {},').replace('Rarity__auto__          = false','Rarity__auto__          = null'));
 e=make();try{await e.boot(files);console.log('Remaining probes: constructor/member bootstrap adapters, in memory');
 await e.lua.doString(String.raw`
local function probe(name,fn)
 local ok,result=pcall(fn);print(name..": "..(ok and "RESULT " or "ERROR ")..tostring(result))
end
ItemSystem=require("LuaEx.inc.cog.Objects.ItemSystem.ItemSystem")
ItemStashSystem=require("LuaEx.inc.cog.Objects.ItemSystem.ItemStashSystem")
ReviewActualItem=class("ReviewActualItem",{}, {}, {}, {}, {ReviewActualItem=function(this,cdat,super)super("Sword","A sword") end},CoGItem)
-- Bootstrap adapters isolate container failures from the broken superclass
-- chain. This is a test fixture, not a supported item workaround.
ReviewFixtureItem=class("ReviewFixtureItem",{}, {}, {}, {}, {ReviewFixtureItem=function(this,cdat,super)super("Fixture","Fixture description") end},CoGItem)
local item=ReviewFixtureItem();local other=ReviewFixtureItem()
probe("Clone item",function()return clone(item) end)
probe("Inventory capacity 1",function()local inv=ItemSystem(1);inv.addItem(item);return tostring(inv.addItem(other))..", count="..inv.getItemCount() end)
probe("Inventory initial items",function()return ItemSystem(2,{item}).getItemCount() end)
probe("Inventory initializer typo isolated",function()return ItemSystem(nil,2,{item}).getItemCount() end)
local inv=ItemSystem();inv.addItem(item)
probe("Inventory containsItemAt",function()return inv.containsItemAt(item,1) end)
probe("Inventory clear",function()inv.clear();return inv.getItemCount() end)
probe("Inventory owner",function()return inv.getOwner() end)
probe("Stash capacity 1 per tab",function()local stash=ItemStashSystem(Point(0,0),2,1);local tab=stash.getTab(1);tab.addItem(item);return tostring(tab.addItem(other))..", count="..tab.getItemCount() end)
local slot=ItemSlot();slot.set(item)
probe("Slot get",function()return slot.get()==item end)
probe("Slot disabled set",function()local s=ItemSlot();s.setEnabled(false);local _,accepted=s.set(item);return accepted end)
probe("CoGItem false flags",function()local c=class("ReviewFalseFlags",{}, {}, {}, {}, {ReviewFalseFlags=function(this,cdat,super)super("Fixture","Description",nil,nil,false,-1,false,false,false,false,false,false,false,false,false,false,0,0)end},CoGItem);local x=c();return tostring(x.isRemovable())..", "..tostring(x.isSellable())..", "..tostring(x.isTradable()) end)
local sys=ItemSlotSystem(nil,Point(0,0));sys.addItemSlot(slot);sys.addItemSlot(ItemSlot())
probe("Slot initializer",function()local inputs={ItemSlot()};local original=inputs[1];local s=ItemSlotSystem(inputs,Point(0,0));return s.getItemSlotCount()..", caller mutated="..tostring(inputs[1]~=original) end)
probe("Slot getItemCount",function()return sys.getItemCount() end)
probe("Slot getItemAt",function()return sys.getItemAt(1) end)
probe("Slot containsItemAt",function()return sys.containsItemAt(item,1) end)
probe("Swap occupied with empty",function()local _,swapped=sys.swapItems(1,2);return tostring(swapped)..", source unchanged="..tostring(slot.get()==item) end)
sys.getItemSlotAt(2).set(other)
probe("Swap occupied with occupied",function()return sys.swapItems(1,2) end)
probe("Duplicate item references",function()local i=ItemSystem();i.addItem(item);i.addItem(item);return i.getItemCount() end)
probe("Duplicate slot references",function()local i=ItemSlotSystem(nil,Point(0,0));i.addItemSlot(slot);i.addItemSlot(slot);return i.getItemSlotCount() end)
probe("Iterator bypasses item validation",function()local i=ItemSystem();local _,backing=i.iterator();backing[1]="not an item";return i.getItemAt(1) end)
probe("CoGObject fireEvent",function()return item.fireEvent(enum("ReviewEvents",{"TEST"},nil,true).TEST) end)
`);
 }finally{e.close();}})().catch(err=>{console.error(err);process.exitCode=1;});
