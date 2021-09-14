# LuaEx
 A collection of scripts that extend Lua's functionality.

 All code is placed in the public domain except where otherwise noted.


----------


## Modules

### enum

#### Features
- **Immutability**
- **Robust Type Checking**
- **Helper Methods/Metamethods**
- **Optional User-defined String/Number Item Values**
- **Iterator For Each Enum**
- **Strict Ordinal Positioning**


#### Reserved Enum Names
All Lua Keywords plus LuaEx keywords (***const***, ***enum***) 

#### Reserved Enum Item Names
- **__count**
- **__first**
- **__getByOrdinal**
- **__hasA**
- **__last**
- **__name**

#### Enum Properties
- **__count** The total number of items in the enum (*number*)
- **__name** The name of the enum (*string*)

#### Enum Methods
- **__first** Returns the first ordinal item (*enum item*)
- **__hasA**	Determines whether or not this enum has a a given item (*boolean*)
- **__getByOrdinal** Returns the item with the given ordinal value (*enum item*)
- **__last** Returns the last ordinal item (*enum item*)

#### Enum Metamethods
- **__call** Returns an iterator which returns the ordinal value and item object for each enum item (*iterator*)
- **__len** Same as the property, __count (*number*)
- **__tostring** Returns a pretty, formatted string of the enum name (*string*)

#### Item Properties
- **enum** The enum which owns this item (*enum*)
- **id** The ordinal value of the item (*number*)
- **name** The given name of the item (*string*)
- **value** The given (or default) value of the item (string or number)
- **valueType** The type of the value property (string or number)

#### Item Methods
- **next** Returns the next item based on ordinal value (or nil if outside the enum's range)
- **previous** Returns the previous item based on ordinal value (or nil if outside the enum's range)
- **isA** Determines whether or not the item exists in a given enum 
 
#### Item Metamethods
- **__tostring** Returns a pretty, formatted string of the item name

#### Usage Examples

```lua

--create a few of enums
enum("CREATURE",{"HUMAN", "MONSTER", "FROG", "DRAGON"});
enum("AUTO", 	{"CAR", "TRUCK", "BIKE"});
enum("ANIMAL", 	{"DOG", "FROG", "MONKEY", "GIANT_SNAKE"});
--create oen with custom values
enum("TOOL", 	{"HAMMER", "DRILL", "TAPE"}, {"Framing", "Mega Drill", 50});

local maDrill = TOOL.DRILL;

print("Printing All Items in the "..ANIMAL.__name.." enum:\r\n");
for nID, oItem in ANIMAL() do
	print(tostring(oItem).." ("..oItem.name..") is an "..tostring(oItem.enum)..".");
end
print("\r\n");
print("Fact-check: A "..AUTO.CAR.name.." is an "..tostring(ANIMAL).." - "..tostring(AUTO.CAR:isA(ANIMAL)));
print("Fact-check: A "..tostring(TOOL).." has a "..tostring(maDrill).." - "..tostring(TOOL.__hasA(maDrill)));
print("Fact-check: A "..AUTO.TRUCK.name.." is an "..tostring(AUTO).." - "..tostring(AUTO.TRUCK:isA(AUTO)));
print("Fact-check: An "..tostring(AUTO.TRUCK.enum).." is an "..tostring(AUTO).." - "..tostring(AUTO.TRUCK.enum == AUTO));
print("Fact-check: A "..ANIMAL.FROG.name.." and "..ANIMAL.MONKEY.name.." are in the same enum - "..tostring(ANIMAL.FROG.enum == ANIMAL.MONKEY.enum));
print("Fact-check: A "..AUTO.BIKE.name.." and "..TOOL.HAMMER.name.." are in the same enum - "..tostring(AUTO.BIKE.enum == TOOL.HAMMER.enum));
print("Fact-check: A (Creature) "..CREATURE.FROG.name.." and (Animal) "..ANIMAL.FROG.name.." are in the same enum - "..tostring(CREATURE.FROG.enum == ANIMAL.FROG.enum));
print("Fact-check: A (Creature) "..CREATURE.FROG.name.." and (Animal) "..ANIMAL.FROG.name.." are the same - "..tostring(type(CREATURE.FROG) == type(ANIMAL.FROG)));

```


----------

### base64 Module License
 -- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
 -- licensed under the terms of the LGPL2