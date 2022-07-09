## 🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​

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

### [◀ Back](https://centaurisoldier.github.io/LuaEx/)
