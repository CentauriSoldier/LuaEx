## 🇸​​​​​🇹​​​​​🇷​​​​​🇺​​​​​🇨​​​​​🇹​​​​​

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

### [◀ Back](https://centaurisoldier.github.io/LuaEx/)
