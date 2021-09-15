![LuaEx](https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png)

# 🆆🅷🅰🆃 🅸🆂 🅻🆄🅰🅴🆇❓

Put simply, LuaEx is a collection of scripts that extend Lua's functionality. Below is a list of included modules and their descriptions.  

# 🆅🅴🆁🆂🅸🅾🅽

Alpha 0.2

# 🅻🅸🅲🅴🅽🆂🅴

All code is placed in the public domain except where otherwise noted using [The Unlicense](https://opensource.org/licenses/unlicense "The Unlicense").

# 🆆🅰🆁🆁🅰🅽🆃🆈
None. Use at your own risk.

# 🅶🅴🆃🆃🅸🅽🅶 🆂🆃🅰🆁🆃🅴🅳
In order to push all the code in LuaEx into the global environment, place the LuaEx folder into your package path and run the following code:
```lua
require("LuaEx.init");
``` 
From here on out, all modules of LuaEx will be available in the global environment.


# 🅼🅾🅳🆄🅻🅴🆂

## 🇧​​​​​🇦​​​​​🇸​​​​​🇪​​​​​64
base64 Module License
 -- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
 -- licensed under the terms of the LGPL2


## <a href="#">🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸</a>​​​​​
Description in Progress 

## 🇨​​​​​🇴​​​​​🇳​​​​​🇸​​​​​🇹​​​​​
Description in Progress 

## 🇩​​​​​🇪​​​​​🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​
Description in Progress 

## 🇪​​​​​🇳​​​​​🇺​​​​​🇲​​​​​

#### Description
Brings enums to lua. While they do do not possess every feature you have come to expect in OOP, I have tried to make their behavior as close to actual enums as possible. 

#### Features
- **Immutability**
- **Robust Type Checking**
- **Helper Methods/Metamethods**
- **Optional User-defined String/Number Item Values**
- **Iterator For Each Enum**
- **Strict Ordinal Positioning**
- **Enum Items Accessible By Either Name Or Ordinal**


#### Reserved Enum Names
All Lua Keywords plus LuaEx keywords (***const***, ***enum***) 

#### Reserved Enum Item Names
- **__count**
- **__hasA**
- **__name**

#### Enum Properties
- **__count** The total number of items in the enum (*number*)
- **__name** The name of the enum (*string*)

#### Enum Methods
- **__hasA**	Determines whether or not this enum has a a given item (*boolean*)

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
- **isSibling** Determines whether or not the first item and the second item are in the same enum
 
#### Item Metamethods
- **__tostring** Returns a pretty, formatted string of the item name

#### Usage Examples

```lua

--init all LuaEx modules
require("LuaEx.init");

--create a few of enums
enum("CREATURE",{"HUMAN", "MONSTER", "FROG", "DRAGON"});
enum("AUTO", 	{"CAR", "TRUCK", "BIKE"});
enum("ANIMAL", 	{"DOG", "FROG", "MONKEY", "GIANT_SNAKE"});
--create one with custom values
enum("TOOL", 	{"HAMMER", "DRILL", "TAPE"}, {"Framing", "Mega Drill", 50});

local maDrill = TOOL.DRILL;

--print every item in an enum
print("Printing All Items in the "..ANIMAL.__name.." enum:\r\n");
for nID, oItem in ANIMAL() do
	print(tostring(oItem).." ("..oItem.name..") is an "..tostring(oItem.enum)..".");
end

--print some test cases
print("\r\n");
print("Fact-check: A "..AUTO.CAR.name.." is an "..tostring(ANIMAL).." - "..tostring(AUTO.CAR:isA(ANIMAL)));
print("Fact-check: A "..tostring(TOOL).." has a "..tostring(maDrill).." - "..tostring(TOOL.__hasA(maDrill)));
print("Fact-check: A "..AUTO.TRUCK.name.." is an "..tostring(AUTO).." - "..tostring(AUTO.TRUCK:isA(AUTO)));
print("Fact-check: An "..tostring(AUTO.TRUCK.enum).." is an "..tostring(AUTO).." - "..tostring(AUTO.TRUCK.enum == AUTO));
print("Fact-check: A "..ANIMAL.FROG.name.." and "..ANIMAL.MONKEY.name.." are in the same enum - "..tostring(ANIMAL.FROG.enum == ANIMAL.MONKEY.enum));
print("Fact-check: A "..AUTO.BIKE.name.." and "..TOOL.HAMMER.name.." are in the same enum - "..tostring(AUTO.BIKE.enum == TOOL.HAMMER.enum));
print("Fact-check: A (Creature) "..CREATURE.FROG.name.." and (Animal) "..ANIMAL.FROG.name.." are in the same enum - "..tostring(CREATURE.FROG.enum == ANIMAL.FROG.enum));
print("Fact-check: A (Creature) "..CREATURE.FROG.name.." and (Animal) "..ANIMAL.FROG.name.." are in the same enum - "..tostring(CREATURE.FROG.enum == ANIMAL.FROG.enum));
print("Fact-check: A (Creature) "..CREATURE.FROG.name.." and (Creature) "..CREATURE.DRAGON.name.." are siblings (in the same enum)- "..tostring(CREATURE.FROG:isSibling(CREATURE.DRAGON)));
print("Get a "..CREATURE.FROG.name.." by name ("..CREATURE.FROG.name..") and by ordinal ("..CREATURE[3].id..")");
print("Get the first ("..AUTO[1].name..") and last ("..AUTO[AUTO.__count].name..") items in "..AUTO.__name..".");

```

## 🇲​​​​​🇦​​​​​🇹​​​​​🇭​​​​​
Description in Progress

## 🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​

#### Description
As the title suggests, this module converts various types to string. If you use the [🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸](🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸) module, you can create custom serialization for each of your classes. Use can use the Deserialize module to reverse the process performed by this module.

#### Functions

## 🇸​​​​​🇹​​​​​🇷​​​​​🇮​​​​​🇳​​​​​🇬​​​​​
Description in Progress

## 🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​
Description in Progress