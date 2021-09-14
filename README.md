# LuaEx
 A collection of scripts that extend Lua's functionality.

 All code is placed in the public domain except where otherwise noted.


----------


## Modules


**I'M CURRENTLY WORKING ON THIS PAGE (Updating every few hours at most until done)**

### enum

#### Features

#### Reserved Enum Names
All Lua Keywords plus LuaEx keywords (const, enum) 

#### Reserved Enum Item Names
- **__count**
- **__first**
- **__getByOrdinal**
- **__hasType**
- **__last**
- **__name**

#### Enum Properties
- **__count** The total number of items in the enum
- **__name** The name of the enum (as a string)

#### Enum Methods
- **__first** Returns the first ordinal item 
- **__hasType**	Determines whether or not a given enum item belongs to this enum 
- **__getByOrdinal** Returns the item with the given ordinal value
- **__last** Returns the last ordinal item 

#### Enum Metamethods
- **__call** Returns an iterator which returns the ordinal value and item object for each enum item
- **__len** Same as the property, __count
- **__tostring** Return a pretty, formatted string of the enum name

#### Item Properties
- **id** The ordinal value of the item
- **name** The given name of the item (as a string)
- **type** The enum which owns this item
- **value** The given (or default) value of the item
- **valueType** The type of the value property

### Item Methods
- **next** Returns the next item based on ordinal value (or nil if outside the enum's range)
- **previous** Returns the previous item based on ordinal value (or nil if outside the enum's range)
- **typeOf** Determines whether or not the item is owned by a given enum 
 
#### Item Metamethods
#### None

#### Usage Examples

```lua

--create a couple of enums
enum("ANIMAL", 	{"DOG", "FROG", "MONKEY", "GIANT_SNAKE"});
enum("AUTO", 	{"CAR", "TRUCK", "BIKE"});

print("Printing All Items in the "..ANIMAL.__name.." enum:\r\n");
for nID, oItem in ANIMAL() do
	print(oItem.name.." is a "..oItem.type);
end

print("Fact-check: A car is an animal - "..AUTO.CAR:typeOf(ANIMAL));

```


----------

### base64 Module License
 -- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
 -- licensed under the terms of the LGPL2