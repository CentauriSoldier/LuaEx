## 🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​

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

### [◀ Back](https://centaurisoldier.github.io/LuaEx/)
