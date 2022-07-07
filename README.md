![LuaEx](https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png)


## 🆆🅷🅰🆃 🅸🆂 🅻🆄🅰🅴🆇❓ 🔬
Simply put, **LuaEx** is a collection of scripts that extend Lua's functionality. Below is a list of included modules and their descriptions.  

## 🅳🅴🆅🅴🅻🅾🅿🅼🅴🅽🆃 🅶🅾🅰🅻🆂

#### Common Use
**LuaEx** attempts to implement code solutions for common and frequent problems.

#### Small Package
Keeping this module small is essential to making it useful. You shouldn't have to spend a year learning how to use something designed to be easy to use; **LuaEx** is developed with that in mind.

##### Simplicity
Retaining simplicity of the code is also a primary goal of this module. The code should be intuitive and I strive toward that end.

#### Conventional Consistency



## 🆁🅴🆂🅾🆄🆁🅲🅴🆂
- Logo: https://cooltext.com/
- Special ASCII Fonts: https://fsymbols.com/generators/carty/

## 🆅🅴🆁🆂🅸🅾🅽 ⚗

#### Alpha v0.7
<details>
<summary>See Changes</summary>

### 🇨​​​​​🇭​​​​​🇦​​​​​🇳​​​​​🇬​​​​​🇪​​​​​🇱​​​​​🇴​​​🇬​​​​​

**v0.7**
- Change: renamed functions in various modules to conform with Lua's lowercase naming convention.
- Change: improved the **string.totable** function.
- Change: the **xtype** function will now ignore user-defined types but return **LuaEx**'s type names for **classes**, **constants**, **enums**, structs, **struct factories** (and **struct_factory_constructor**) and **null** (and **NULL**) as oppossed to returning, *"table"*. *Use the **rawtype** function to ignore all **LuaEx** type mechanics*.
- Change: renamed the **string.delimitedtotable** function to ***string.totable***.
- Bugfix: corrected assertions in stack class.
- Bugfix: **set.addset** was not adding items.
- Feature: addded the **ini** module.
- Feature: added **string.isnumeric** function.
- Feature: added a **__mod** metamethod for string which allows for easy interpolation.
- Feature: added null type.
- Feature: added the **struct** factory module.
- Feature: added the **xtype** function.
- Feature: added the **fulltype** function.

**v0.6**
- Feature: removed ***string.left*** as it was an unnecessary and inefficient wrapper of ***string.sub***.
- Feature: removed ***string.right*** as it was an unnecessary and inefficient wrapper of ***string.sub***.
- Feature: added ***string.trim*** function.
- Feature: added ***string.trimleft*** function.
- Feature: added ***string.trimright*** function.
- Bugfix: corrected package.path code in init.lua and removed ***import*** function.
- Refactor: moved modules into appropriate subdirectories and updated init.lua to find them.
- Refactor: appended ***string***, ***math*** & ***table*** module files with "hook" without which they would not load properly.
- Update: updated README with more information.

**v0.5**
- Bugfix: ***table.lock*** was altering the metatable of enums when it should not have been.
- Bugfix: ***table.lock*** was not preserving metatable items (where possible).
- Change: classes are no longer automatically added to the global scope when created; rather, they are returned	for the calling script to handle.
- Change: **LuaEx** classes and modules are no longer auto-protected and may now be hooked or overwritten. This change does not affect the way constants and enums work in terms of their immutability.
- Change: **enums** values may now be of any non-nil type(previously only **string** and **number** were allowed).
- Feature: **class** constructor methods now pass, not only the instance, but a protected, shared (fields and methods) table to parent classes.
- Feature: **enums** may now be nested.
- Feature: added ***protect*** function (in ***stdlib***).
- Feature: added ***sealmetatable*** function (in ***stdlib***).
- Feature: added ***subtype*** function (in ***stdlib***).
- Feature: added ***table.lock*** function.
- Feature: added ***table.purge*** function.
- Feature: added ***table.settype*** function.
- Feature: added ***table.setsubtype*** function.
- Feature: added ***table.unlock*** function.
- Feature: added ***queue*** class.
- Feature: added ***set*** class.
- Feature: added ***stack*** class.

**v0.4**
- Bugfix: metavalue causing custom type check to fail to return the proper value.
- Bugfix: typo that caused global enums to not be put into the global environment.
- Feature: enums can now also be non-global.
- Feature: the enum created by a call to the enum function is now returned.

**v0.3**
- Hardened the protected table to prevent accidental tampering.
- Added a meta table to ***_G*** in the init module.
- Changed the name of the const module and function to constant for Lua 5.1 - 5.4 compatibility.
- Altered the way constants and enums work by using the new, ***_G*** metatable to prevent deletion or overwriting.
- Updated several modules.

**v0.2**
- Added the enum object.
- Updated a few modules.

**v0.1**
- Compiled various modules into **LuaEx**.
</details>

## 🅻🅸🅲🅴🅽🆂🅴 ©

All code is placed in the public domain under [The Unlicense](https://opensource.org/licenses/unlicense "The Unlicense") *(except where otherwise noted)*.


## 🅲🅷🅰🅽🅶🅴🆂 🆃🅾 🅻🆄🅰 🛠

#### The Global Environment

***_G*** has been given a metatable that monitors the protected values (such as enums and constants).

**Note:** In order to mitigate any potential slow-down from this added metatable in ***_G***, simply localize every global variable before use in your scripts *(especially tables)*. On the average, this is good practice anyhow.

#### Custom Types

Adding a ***__type*** field to any metatable (or by using ***table.settype***) and assigning a string value to it creates a custom object type. In order to achieve this, the Lua function, ***type*** has been hooked.

If you'd like to get the type of something, ignoring ***user-implemented***, custom implementations of **LuaEx's** custom type feature, simply use the ***xtype*** function. This will not affect pre-built, **LuaEx** types such as ***null***, ***enums***, ***classes***, ***constants***, ***struct factories***, etc. and objects of these types will still return their name as defined by **LuaEx**.

If you want the *actual Lua type* of a thing ignoring ***ALL*** **LuaEx** custom type mechanics, use the ***rawtype*** function.

### Subtypes
They work the same as types except the metatable entry is ***__subtype*** and the function to detect the subtype is ***subtype***.

### Fulltype
The **fulltype** function concatenates the results from **__type** and **__subtype**.

### The NULL Type
NULL (also null) is a custom type added to **LuaEx**. It is of type null and has obligatory comparison behavior for null values in many programming languages. The main purpose of this value, as an alternative for ***nil***, is to allow the retention of table keys while still indicating a lack of value for a given key. Of course, you may use this null value however you wish. You can use the ***isnull*** function to determine whether a value is null. Both ***null*** and ***NULL*** are the same value and may be accessed by using either word.

Note: This works only with the ***type*** function. Calling the ***rawtype*** function with ***null*** (or ***NULL***) as an argument will return the value, "table".

Note: Do not localize ***null*** (or ***NULL***)...strange things happen.


## 🆆🅰🆁🆁🅰🅽🆃🆈 🗞
None. Use at your own risk. 💣


## 🅶🅴🆃🆃🅸🅽🅶 🆂🆃🅰🆁🆃🅴🅳 🚀
In order to push all the code in **LuaEx** into the global environment, place the **LuaEx** folder into your package path and run the following code:
```lua
require("LuaEx.init");
```
From here on out, all modules of **LuaEx** will be available in the global environment.


## 🅲🅻🅰🆂🆂🅴🆂 💥

#### Description
These are various classes that help bring more OOP features to Lua. These have been added by using the 🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸​​​​​ module.

#### Classes
- **queue** A basic queue class with obligatory methods.
- **set** 	A basic set class with obligatory methods as well as many mathematical operations.
- **stack** A basic stack class with obligatory methods.


## 🅼🅾🅳🆄🅻🅴🆂 ⚙
Below is a the complete list of modules in LuaEx.

<details>
<summary>🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​ 🇴​​​​​🇫​​​​​ 🇨​​​​​🇴​​​​​🇳​​​​​🇹​​​​​🇪​​​​​🇳​​​​​🇹​​​​​🇸​​​​​</summary>

- #### [🇸​​​​​🇹​​​​​🇩​​​​​🇱​​​​​🇮​​​​​🇧​​​​​](#stdlib)
- #### [🇧​​​​​🇦​​​​​🇸​​​​​🇪​​​​​64](#base64)
- #### [🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸​​​​​](#class)
- #### [🇨​​​​​🇴​​​​​🇳​​​​​🇸​​​​​🇹​​​​​🇦​​​​​🇳​​​​​🇹​​​​​](#constant)
- #### [🇩​​​​​🇪​​​​​🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​](#deserialize)
- #### [🇪​​​​​🇳​​​​​🇺​​​​​🇲​​​​​](#enum)
- #### [🇮​​​​​🇳​​​​​🇮​​​​​](#ini)
- #### [🇲​​​​​🇦​​​​​🇹​​​​​🇭​​​​​](#math)
- #### [🇸​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​](#serialize)
- #### [🇸​​​​​🇹​​​​​🇷​​​​​🇺​​​​​🇨​​​​​🇹​​​​​](#struct)
- #### [🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​](#table)

</details>

## 🇸​​​​​🇹​​​​​🇩​​​​​🇱​​​​​🇮​​​​​🇧​​​​​

#### Description
These are items that are globally accessible but do not fit nicely into any particular module or are global functions not listed elsewhere. These include new, **LuaEx** functions as well as hooks of existing Lua functions.

#### Functions
- **type** Works like the original Lua function except that it honors **LuaEx's** custom type system (for tables modified by ***table.settype*** or by manually setting a string value in a table's metatable key, ***__type***.).

- **subtype** Gets the subtype of an object/table. If it has not been given a subtype (either by using ***table.setsubtype*** or by manually setting the ***__subtype*** metatable key), then the string *"nil"* is returned.

- **fulltype** concatenates the results from ***__type*** and ***__subtype***.

- **xtype** Honor all **LuaEx's** pre-made (and internally-generated) custom types but ignores user implementation of the metatable value, ***__type***. So, for all user-defined types, it will return the string value, ***"table"***.

- **rawtype** The original Lua ***type*** function. It does not honor **LuaEx's** custom type system whatsoever; meaning, for all custom types, it will return the string value, ***"table"***.

- **sealmetatable** Permanently locks a metatable from being accessed, altered or changed by settting the ***__metatable*** key to *false*. This process cannot be undone. If the table does not have a metatable, one is created and sealed.

- **protect** This places a global into a protected table where it's place cannot be modified. That is, it cannot be deleted or changed. The exception is a table which can be modified unless locked (but it still cannot be deleted).

- **isnull** Returns true if the input is null or NULL, otherwise, returns false. TOTO MOVE THIS TO NULL SECTION

## 🇧​​​​​🇦​​​​​🇸​​​​​🇪​​​​​64

#### Description
Created by Alex Kloss, this modules encodes/decodes strings into/from [base64](https://en.wikipedia.org/wiki/Base64) strings.

#### Functions
- **base64.enc(string)** Converts a string to a base 64 string (*string*).
- **base64.dec(string)** Converts a base 64 string back into a normal string (*string*).

**base64 Module License**
- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
- licensed under the terms of the [LGPL2](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


## 🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸​​​​​

#### Description
This is used to create classes in **LuaEx**. It allows the client access to many features of Object Oriented Programming (although not all). It is important to remember that the first two (implicit) arguments to any class constructor (those not passed by the caller) are ***1)*** the instance and ***2)*** a protected, shared table (or nil if the class has no children). This table is used to store non-public fields and methods visible to only to the class, its parents and its children. Each child and parent of a given class instance can access and mutate this table and its elements. This table serves as the "protected" portion of classes' O.O.P.


#### Usage Example
```lua
--used to store protected instance information
local tProtectedRepo = {};

local animal = class "animal" {

	__construct = function(this, protected, sName, bIsBiped)
		--setup the protected table for this instance (or import the given one if it's not nil)
		tProtectedRepo[this] = rawtype(protected) == "table" and protected or {};

		--for readability
		local tProt = tProtectedRepo[this];

		--create the protected properties
		tProt.name 		= type(sName) 		== "string" and sName 		or "";
		tProt.isBiped 	= type(bIsBiped)	== "string" and bIsBiped 	or false;

	end,


};

local dog = class "dog" : extends(animal) {

	__construct = function(this, protected, sName)
		--setup the protected table for this instance (or import the given one if it's not nil)
		tProtectedRepo[this] = rawtype(protected) == "table" and protected or {};

		--for readability
		local tProt = tProtectedRepo[this];

		--call the parent constructor
		this:super(tProt, sName, false);
	end,

	bark = function(this)
		print(tProtectedRepo[this].name.." says, \"Woof!\".");
	end,
};

local spot = dog("Spot");
spot:bark();
```

## 🇨​​​​​🇴​​​​​🇳​​​​​🇸​​​​​🇹​​​​​🇦​​​​​🇳​​​​​🇹​​​​​

#### Description
Allows the creation of constants in Lua. Once set, these global values cannot be changed or deleted.

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
- **deserialize.boolean(*string*)**
- **deserialize.number(*string*)**
- **deserialize.string(*string*)**
- **deserialize.table(*string*)**

#### Usage Example
```lua
--create a table
local tBatteries = {
	Good 		= 45,
	Bad 		= 34678,
	InLandfill 	= 2345674222,
	CostPer		= {
		Low	= 200,
		Med = 300,
		High = 400,
	},
};

local sBatteries = serialize.table(tBatteries);

local tReturned = deserialize.table(sBatteries);

--print some stuff to compare
print("Returned: "..tReturned.CostPer.Med);
print("Batteries: "..tBatteries.CostPer.Med);
print("Returned: "..tReturned.Bad);
print("Batteries: "..tBatteries.Bad);
```

## 🇪​​​​​🇳​​​​​🇺​​​​​🇲​​​​​

#### Description
Brings enums to Lua. While they do not possess every feature you have come to expect in OOP, I have tried to make their behavior as close to actual enums as possible while still affording them the benefits of Lua flexibility.

#### Features
- **Immutability**
- **Robust Type Checking**
- **Helper Methods/Metamethods**
- **Optional User-defined String/Number Item Values**
- **Iterator For Each Enum**
- **Strict Ordinal Positioning**
- **Enum Items Accessible By Either Name Or Ordinal**


#### Reserved Enum Names
All Lua Keywords plus **LuaEx** keywords (***constant***, ***enum***, etc.)

#### Reserved Enum Item Names
- **__count**
- **__hasa**
- **__name**

#### Enum Properties
- **__count** The total number of items in the enum (*number*)
- **__name** The name of the enum (*string*)

#### Enum Methods
- **__hasa**	Determines whether or not this enum has a given item (*boolean*)

#### Enum Metamethods
- **__call** Returns an iterator which returns the ordinal value and item object on each iteration (*iterator*)
- **__len** Same as the property, __count (*number*)
- **__tostring** Returns a pretty, formatted string of the enum name (*string*)

#### Item Properties
- **enum** The enum which owns this item (*enum*)
- **id** The ordinal value of the item (*number*)
- **name** The given name of the item (*string*)
- **value** The given (or default) value of the item (any non-nil type)
- **valueType** The type of the value property (string)

#### Item Methods
- **next** Returns the next item based on ordinal value (or nil if outside the enum's range)
- **previous** Returns the previous item based on ordinal value (or nil if outside the enum's range)
- **isa** Determines whether or not the item exists in a given enum
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
print("Fact-check: A "..AUTO.CAR.name.." is an "..tostring(ANIMAL).." - "..tostring(AUTO.CAR:isa(ANIMAL)));
print("Fact-check: A "..tostring(TOOL).." has a "..tostring(maDrill).." - "..tostring(TOOL.__hasa(maDrill)));
print("Fact-check: A "..AUTO.TRUCK.name.." is an "..tostring(AUTO).." - "..tostring(AUTO.TRUCK:isa(AUTO)));
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

--(private) enums can be embedded within other enums
enum("ANIMAL", {"CAT", "DOG", "MOUSE", "COUNT"}, {
	enum("ANIMAL.CAT", {"COLOR", "SIZE"}, {5, 7}, true, {
		enum("ANIMAL.CAT.COLOR", {"WHITE", "GREY", "BLACK", "TEAL"}, nil, true),
		enum("ANIMAL.CAT.SIZE", {"BIG", "MEDIUM", "SMALL"}, {3, 7, 9}, true),
	}, true),
	enum("ANIMAL.DOG", {"OWNED", "IN_KENNEL"}, {2, 6}, true),
	enum("ANIMAL.MOUSE", {"IN_HOUSE", "NOISY"}, {false, true}, true),
	45,
});

--get the type of cat
print(tostring("This is a "..ANIMAL.CAT.name.."."));

--there are a couple ways to access the same info
print("This "..ANIMAL.DOG.name.." is a "..ANIMAL.DOG.OWNED.name);
print("This "..ANIMAL.DOG.name.." is a "..ANIMAL.DOG.value.OWNED.name);

--check on the mouse
print("Mouse is in the house: "..tostring(ANIMAL.MOUSE.IN_HOUSE.value));

--and, of course, the enums and values are protected (uncomment to see)
--ANIMAL.DOG = 44;
--ANIMAL.DOG.OWNED.value = "Hello";
```

## 🇮​​​​​🇳​​​​​🇮​​​​​

#### Description
A module by Carreras Nicolas (https://github.com/Sledmine/lua-ini) which is a basic ini data handler.

- **ini.decode(*string*)** Decodes ini data (*in string format*) and returns the data in table format (*table*).
- **ini.encode(*string*)** Encodes ini data (*in table format*) to a string (*string*).
- **ini.load(*string*)** Same as ***ini.decode*** except it takes a filepath string; loads the file and decodes the string data to a table (*table*).
- **ini.save(*string*)** Same as ***ini.decode*** except also saves the string data to the file specified by the filepath string (*nil*).

## 🇲​​​​​🇦​​​​​🇹​​​​​🇭​​​​​

#### Description
Adds several math function to the Lua library.
- **Function descriptions in-progress.**

## 🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​

#### Description
As the title suggests, this module converts various types to a storable string. If you use the 🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸 module, you can create custom serialization for each of your classes. You can use the 🇩​​​​​🇪​​​​​🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪 module to reverse the process performed by this module.

#### Functions
- **serialize.boolean(*boolean*)** Returns a string, either, "true" or "false" (*string*).
- **serialize.number(*number*)** Returns a string of the numbe r(*string*).
- **serialize.string(*string*)** Returns a string which has been formatted for storage (*string*).
- **serialize.table(*table*)** Returns a string representation of the given table. It will store all values and hierarchy except for ***userdata***, ***functions*** and ***nil*** (use ***null*** instead) (*string*).

#### Usage Example
```lua
--create a table
local tBatteries = {
	Good 		= 45,
	Bad 		= 34678,
	InLandfill 	= 2345674222,
	CostPer		= {
		Low	= 200,
		Med = 300,
		High = 400,
	},
};

print(serialize.table(tBatteries));
```

## 🇸​​​​​🇹​​​​​🇷​​​​​🇮​​​​​🇳​​​​​🇬​​​​​

#### Description
Adds several string function to the Lua library.

- **string.cap(*string*, *boolean* or *nil*)** Capatalizes the first letter of the input. If the second argument is true, it also lowers all letters after the first (*string*).
- **string.capall(*string*)** Capatalizes the first letter of each word of the input. The delimiter of a "word" in this context is a space character (*string*).
- **string.totable(*string*, *string*)** Takes a string input and returns a table. The table is split by the provided string delimiter (*table*). ***[Credit & Source](https://www.codegrepper.com/code-examples/lua/lua+split+string+into+table)***
- **string.getfuncname(*function*)** Takes a function as input and returns the name in string form (*string*).
- **string.iskeyword(*string*)** Determines whether the input string is a keyword (*string*).
- **string.isnumeric(*string*)** Determines whether the input is a numeric string (*string*).
- **string.isvariablecompliant(*string*, *boolean* or *nil*)** Determines whether a given string is a valid Lua variable name. If the second argument is false or nil, the function will check a list of Lua (and **LuaEx**) keywords for validation; if not, it will ignore keyword violations (*string*).
- **string.trim(*string*)** Trims the whitespace from the beginning and end of the input string (*string*). ***[Credit & Source](http://snippets.bentasker.co.uk/page-1706031030-Trim-whitespace-from-string-LUA.html)***
- **string.trimright(*string*)** Trims the whitespace from the end of the input string (*string*). ***[Credit & Source](http://snippets.bentasker.co.uk/page-1705231409-Trim-whitespace-from-end-of-string-LUA.html)***
- **string.trimleft(*string*)** Trims the whitespace from the beginning of the input string (*string*). ***[Credit & Source](http://snippets.bentasker.co.uk/page-1706031025-Trim-whitespace-from-beginning-of-string-LUA.html)***
- **string.uuid(*string* or *nil*, *string* or *nil*)** Generates a Universally Unique Identifier string (*string*). *Note: this function does not generate entropy. The client is responsible for having sufficient randomness.*
- **__mod(*string*, *table*)** The **%** metamethod applies to all strings and allows for easy interpolation using a provided table whose keys refer to sections of the string with declared variables ***{$myvar}*** and whose values are strings ***{myvar="string stuff here"}*** (*string*).

#### Usage Example
```lua
--interpolation
local sMyString = "This string has several variables embedded {$var1} it and can be {$mod} much easier than changing the {$et}." % {var1="within", mod="modified", et="entire string"};

print(sMyString);
```
## 🇸​​​​​🇹​​​​​🇷​​​​​🇺​​​​​🇨​​​​​🇹​​​​​

#### Description
**LuaEx's** implementation of **structs**.

A **struct** is a table whose keys must be strings but and have any value except nil. To indicate an empty value for a given key, use null instead of nil. This will retain the property while still indicating an empty value.

The value of each type, once set, is permanently fixed and may never be changed. For this reason, when creating a factory, it may be of use to set some values to null allowing each struct (during or after instantiation) to define the type of that given value.

**Creating a struct factory.**
```lua
local bullet = struct.factory("bullet"{
	id 			= null,
	direction 	= null,
	speed 		= null,
	x 			= 0,
	y 			= 0,
});
```

As shown above, the default values of a struct may be null. This allows each struct to set certain values without relying on the factory; however, once a factory-defined, null, value has been set, it's type is fixed.

**Creating a struct factory.**


#### Functions
- **struct.factory(*string*, *table*)** Creates a struct using the provided name and table of properties. The properties table must contain at least one valid key. Returns a factory that will produce structs that conform to the provided table (*struct factory*).

## 🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​

#### Description
Adds several table functions to the Lua library.

#### Functions
- **table.clone(*table*, *boolean* or *nil*)** Performs a deep copy of a table and returns that copy. This will also copy the metatable unless the second argument is set to true (*table*).
- **table.lock(*table*)** Makes a table read-only recursively. That is, it prevents any of a table's key or values from being mutated (or any added to the table) while still allowing them to be accessed. Can be unlocked later. Note: while the original metatable is mostly preserved, ***__index*** and ***__newindex*** are necessarily replaced while the table is locked (but are restored once the table is unlocked). The exception to this rule is enums: their ***__index*** metamethod remains when locked (*table*).
- **table.purge(*table*, *boolean* or *nil*)** Sets every item in a table to nil recursively. This will also purge and delete the metatable unless the second argument is set to true (*table*).
- **table.settype(*table*, *string*)** Sets the table to a custom type instead of type ***"table"***. Calls to ***type*** will now return the input string. To check the type, ignoring the custom type feature, use the ***rawtype*** function instead (*table*).
- **table.setsubtype(*table*, *string*)** Does the same thing as type allowing an object/table to have, both, a type and a subtype simultaneously. To get the subtype of an object/table, use the ***subtype*** function (*table*).
- **table.unlock(*table*)** Reverses the process done by the ***table.lock*** function including putting all metatables back which existed before (*table*).

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

--set the type
table.settype(tAnimals, "Kennel");
print("You just built a "..type(tAnimals));

--set the table's subtype
table.setsubtype(tAnimals, "Happy");
print("The "..type(tAnimals).." is of subtype "..subtype(tAnimals));

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

## 🅲🆁🅴🅳🅸🆃🆂
- Huge thanks to [Bas Groothedde](https://github.com/imagine-programming) at Imagine Programming for creating the original **class** module.
- Thanks to Alex Kloss (alexthkloss@web.de) for creating the **base64** module.
- Thanks to [Carreras Nicolas](https://github.com/Sledmine/lua-ini) for creating the **ini** module.
