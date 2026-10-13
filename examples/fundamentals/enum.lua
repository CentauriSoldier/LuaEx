-- Edit these values, then Run code. This tutorial is independent of the Visual tab.
local commonValue, rareValue, legendaryValue = 10, 25, 50
local source = debug.getinfo(1, 'S').source:gsub('^@', '')
local root = source:match('^(.*)[/\\]') or '.'
for _=1,8 do
    local file=io.open(root..'/LuaEx/init.lua','r')
    if file then file:close();break end
    root=root..'/..'
end
package.path=root..'/?.lua;'..package.path
if not LUAEX_INIT then require('LuaEx.init') end
local D=require('examples.support.tutorial').new('Enums from the beginning','Named items, payloads, identity, navigation, protection and persistence.')

D.section('Create and read', 'An enum gives each item a name, ordinal position and payload.')
local Rarity=enum('CodeExampleRarity',{'COMMON','RARE','LEGENDARY'},{commonValue,rareValue,legendaryValue})
D.show('COMMON payload',Rarity.COMMON.value)
D.equal('Name and index resolve the same item',Rarity[1],Rarity.COMMON)
D.equal('Number of items',#Rarity,3)
for index,item in Rarity() do D.show('Ordinal '..index..': '..tostring(item),item.value) end

D.section('Default and mixed values', 'Omitted payloads use ordinals; explicit payloads can have different types.')
local State=enum('CodeExampleState',{'IDLE','BUSY'},nil,true)
D.equal('First default payload',State.IDLE.value,1)
local Mixed=enum('CodeExampleMixed',{'TEXT','FLAG','RECORD'},{'ready',false,{count=3}},true)
D.show('Text',Mixed.TEXT.value);D.show('Record',Mixed.RECORD.value)
D.equal('False is a real payload',Mixed.FLAG.value,false)
D.equal('Private enum is not a global',_G.CodeExampleMixed,nil)

D.section('Identity and membership', 'Equal payloads do not mean equal enum items.')
local Twins=enum('CodeExampleTwins',{'FIRST','SECOND'},{7,7},true)
D.equal('Equal payloads',Twins.FIRST.value,Twins.SECOND.value)
D.check('Distinct items',Twins.FIRST~=Twins.SECOND)
D.check('Siblings',Twins.FIRST.isSibling(Twins.SECOND))
D.check('Membership',Rarity.COMMON.isa(Rarity))
D.check('Enum contains its item',Rarity.__hasa(Rarity.COMMON))

D.section('Navigation and arithmetic', 'Wrapping is optional; arithmetic uses numeric payloads.')
D.equal('Next item',Rarity.COMMON.next(),Rarity.RARE)
D.equal('Previous at first boundary',Rarity.COMMON.previous(),nil)
D.equal('Wrapped previous',Rarity.COMMON.previous(true),Rarity.LEGENDARY)
D.equal('Last wraps to first',Rarity.LEGENDARY.next(true),Rarity.COMMON)
D.equal('Numeric sum',Rarity.COMMON+Rarity.RARE,commonValue+rareValue)

D.section('Protection and validation', 'Create a new definition instead of overwriting a protected enum.')
D.reject('Duplicate names',function()enum('CodeExampleDuplicate',{'A','A'},nil,true)end)
D.reject('Invalid identifier',function()enum('CodeExampleInvalid',{'bad name'},nil,true)end)
D.reject('Empty definition',function()enum('CodeExampleEmpty',{},nil,true)end)
D.reject('Overwrite enum item',function()Rarity.COMMON=false end)
D.reject('Overwrite payload field',function()Rarity.COMMON.value=99 end)

D.section('Cloning, snapshots and nesting', 'Public names restore canonical identity; nested enums organize symbolic paths.')
D.equal('Clone preserves identity',clone(Rarity.RARE),Rarity.RARE)
D.equal('Serialized public item restores identity',deserialize(serialize(Rarity.RARE)),Rarity.RARE)
local Child=enum('CodeExampleChild',{'IDLE','BUSY'},nil,true)
local Parent=enum('CodeExampleParent',{'STATES','OTHER'},{Child},true)
D.check('Nested membership',Parent.STATES.IDLE.isa(Parent.STATES))
D.show('Nested symbolic snapshot',Parent.STATES.IDLE.serialize())
D.note('Use unique public enum names within one Lua environment. Each code run starts fresh.')
D.finish()
