## 🇪​​​​​🇳​​​​​🇺​​​​​🇲​​​​​

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
- **serialize**

#### Enum Properties
- **__count** The total number of items in the enum (*number*)
- **__name** The name of the enum (*string*)

#### Enum Methods
- **__hasa**	Determines whether or not this enum has a given item (*boolean*)
- **serialize** Serializes the enum for saving in text format, preserving it for reloading later

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
- **next** Returns the next item based on ordinal value or nil if outside the enum's range (unless wrapping around using *true* as an argument)
- **previous** Returns the previous item based on ordinal value or nil if outside the enum's range (unless wrapping around using *true* as an argument)
- **isa** Determines whether or not the item exists in a given enum
- **isSibling** Determines whether or not the first item and the second item are in the same enum
- **serialize** Serializes the enum item for saving in text format, preserving it for reloading later

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

### [◀ Back](https://centaurisoldier.github.io/LuaEx/)
