## 🇩​​​​​🇪​​​​​🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​

Used to reverse the process done by the [🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪](serialize.md) module.

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
### [◀ Back](https://centaurisoldier.github.io/LuaEx/)
