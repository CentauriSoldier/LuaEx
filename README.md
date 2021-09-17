![LuaEx](https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png)

## 🆆🅷🅰🆃 🅸🆂 🅻🆄🅰🅴🆇❓ 🔬

Put simply, LuaEx is a collection of scripts that extend Lua's functionality. Below is a list of included modules and their descriptions.  

## 🆅🅴🆁🆂🅸🅾🅽 ⚗

#### Alpha v0.4

##### Changelog

	v0.5
	Feature: added table.lock.
	Feature: added table.purge.
	Feature: added table.unlock.

	v0.4
	Bugfix: metavalue causing custom type check to fail to return the proper value.
	Bugfix: typo that caused global enums to not be put into the global environment.
	Feature: enums can now also be non-global.
	Feature: the enum created by a call to the enum function is now returned.

	v0.3
	Hardened the protected table to prevent accidental tampering.
	Added a meta table to _G in the init module.
	Changed the name of the const module and function to constant for lua 5.1 - 5.4 compatibility.
	Altered the way constants and enums work by using the new, _G metatable to prevent deletion or overwriting.
	Updated several modules.

	v0.2
	Added the enum object.
	Updated a few modules.

	v0.1
	Compiled various modules into LuaEx.

## 🅻🅸🅲🅴🅽🆂🅴 ©

All code is placed in the public domain under [The Unlicense](https://opensource.org/licenses/unlicense "The Unlicense") *(except where otherwise noted)*.

## 🅲🅷🅰🅽🅶🅴🆂 🆃🅾 🅻🆄🅰 🛠

#### The Global Environment

_G has been given a metatable that monitors the protected values (such as enums and constants).

#### Custom Types

Adding a **__type** field to any metatable and assigning a string value to it creates a custom object type. In order to achive this, the lua function, **type**, has been hooked. If you'd like to get the type of something, ignoring LuaEx's custom type feature, simply use the **rawtype** function.



## 🆆🅰🆁🆁🅰🅽🆃🆈 🗞
None. Use at your own risk. 💣

## 🅶🅴🆃🆃🅸🅽🅶 🆂🆃🅰🆁🆃🅴🅳 🚀
In order to push all the code in LuaEx into the global environment, place the LuaEx folder into your package path and run the following code:
```lua
require("LuaEx.init");
```
From here on out, all modules of LuaEx will be available in the global environment.


## 🅼🅾🅳🆄🅻🅴🆂 ⚙

## 🇧​​​​​🇦​​​​​🇸​​​​​🇪​​​​​64

#### Description
Created by Alex Kloss, this modules encodes/decodes strings into/from [base64](https://en.wikipedia.org/wiki/Base64) strings.

#### Functions
- **base64.enc(string)**
- **base64.dec(string)**

**base64 Module License**
- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
- licensed under the terms of the [LGPL2](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


## 🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸​​​​​
Description in Progress

## 🇨​​​​​🇴​​​​​🇳​​​​​🇸​​​​​🇹​​​​​🇦​​​​​🇳​​​​​🇹​​​​​

#### Description
Allows the creation of constants in lua. Once set, these global values cannot be changed or deleted.

#### Usage Example
```lua
--constant(string, *)
constant("I_LOVE_LUA", "No you don't!");
constant("MAX_CHAIRS_ALLOWED", 42);
constant("THE_ANSWER_TO_THE_UNIVERSE_AND_EVERYTHING", MAX_CHAIRS_ALLOWED);

print(I_LOVE_LUA);
print(MAX_CHAIRS_ALLOWED);
print(THE_ANSWER_TO_THE_UNIVERSE_AND_EVERYTHING);

--try to break it by uncommenting one of the items below
--I_LOVE_LUA = "Yuhu!";
--I_LOVE_LUA = nil;

```

## 🇩​​​​​🇪​​​​​🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​

#### Description
Used to reverse the process done by the 🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪 module.

#### Functions
- **deserialize.boolean(string)**
- **deserialize.number(string)**
- **deserialize.string(string)**
- **deserialize.table(string)**

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
All Lua Keywords plus LuaEx keywords (***constant***, ***enum***)

#### Reserved Enum Item Names
- **__count**
- **__hasA**
- **__name**

#### Enum Properties
- **__count** The total number of items in the enum (*number*)
- **__name** The name of the enum (*string*)

#### Enum Methods
- **__hasA**	Determines whether or not this enum has a given item (*boolean*)

#### Enum Metamethods
- **__call** Returns an iterator which returns the ordinal value and item object on each iteration (*iterator*)
- **__len** Same as the property, __count (*number*)
- **__tostring** Returns a pretty, formatted string of the enum name (*string*)

#### Item Properties
- **enum** The enum which owns this item (*enum*)
- **id** The ordinal value of the item (*number*)
- **name** The given name of the item (*string*)
- **value** The given (or default) value of the item (string or number)
- **valueType** The type of the value property (string)

#### Item Methods
- **next** Returns the next item based on ordinal value (or nil if outside the enum's range)
- **previous** Returns the previous item based on ordinal value (or nil if outside the enum's range)
- **isA** Determines whether or not the item exists in a given enum
- **isSibling** Determines whether or not the first item and the second item are in the same enum

#### Item Metamethods
- **__tostring** Returns a pretty, formatted string of the item name

#### Usage Example

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
print("Fact-check: A (Creature) "..CREATURE.FROG.name.." and (Creature) "..CREATURE.DRAGON.name.." are siblings (in the same enum)- "..tostring(CREATURE.FROG:isSibling(CREATURE.DRAGON)));
print("Get a "..CREATURE.FROG.name.." by name ("..CREATURE.FROG.name..") and by ordinal ("..CREATURE[3].id..")");
print("Get the first ("..AUTO[1].name..") and last ("..AUTO[AUTO.__count].name..") items in "..AUTO.__name..".");

--you can also create non-global enums
local tMyTable = {
	MY_COOL_ENUM 		= enum("MU_ENUM", 		{"STUFF", "THINGS", "ITEMS"}, nil, 		true),
	MY_OTHER_COOL_ENUM 	= enum("MU__OTHER_ENUM", 	{"STUFF", "THINGS", "ITEMS"}, {1, 7, 99}, 	true),
};
```

## 🇲​​​​​🇦​​​​​🇹​​​​​🇭​​​​​
Description in Progress

## 🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​

#### Description
As the title suggests, this module converts various types to a storable string. If you use the 🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸 module, you can create custom serialization for each of your classes. You can use the 🇩​​​​​🇪​​​​​🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪 module to reverse the process performed by this module.

#### Functions
- **serialize.boolean(boolean)**
- **serialize.number(number)**
- **serialize.string(string)**
- **serialize.table(table)**

## 🇸​​​​​🇹​​​​​🇷​​​​​🇮​​​​​🇳​​​​​🇬​​​​​
Description in Progress

## 🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​

#### Description
Adds several table functions to the lua library.

#### Functions
- **table.clone(table, boolean or nil)** Performs a deep copy of a table and returns that copy. This will also copy the metatable unless the second argument is set to true.
- **table.lock(table)** Prevents a table from being modified. Can be unlocked later.
- **table.purge(table, boolean or nil)** Sets every item in a table to nil recursively. This will also purge and delete the metatable unless the second argument is set to true.
- **table.unlock(table)** Reverses the process done by the table.lock function including putting back all metatables back that existed before.

#### Usage Example

```lua
local tAnimals = {
	WhatACloneSays = "I'm not a clone, I swear!",
	Dogs = 34,
	Cats = 10,
	Frogs = 0,
	BestDogs = {3, 3, 5, 7},
	IsBestDogActive = true,
};

--clone a table
tClone = table.clone(tAnimals);

--print some stuff from the clone
print(tClone.WhatACloneSays);
print("There are "..tClone.Dogs.." dogs in the cloned table.");

--lock a table
table.lock(tAnimals);

--we can still read from a locked table
print("There are "..tAnimals.Dogs.." dogs in the locked table.");

--we can alter the cloned table showing that the locked and cloned table are different
tClone.Cats = 2000;
print("There are now "..tClone.Cats.." cloned cats...I warned you not to clone cats!");

--uncomment any of these lines to see what happens when you try to write to a locked table
--tAnimals.Cats = 3;
--tAnimals.Mice = "Please, no mice, say the cats.";
--tAnimals.BestDogs[1] = 57;

--unlock the table and try again
--table.unlock(tAnimals)
--tAnimals.Cats = 3;
--tAnimals.Mice = "Please, no mice, say the cats.";
--tAnimals.BestDogs[1] = 57;

print("We've now got "..tAnimals.Cats.." uncloned cats.");
print(tAnimals.Mice);
print("Oh good. We've also got "..tAnimals.BestDogs[1].." best dogs.");
```
