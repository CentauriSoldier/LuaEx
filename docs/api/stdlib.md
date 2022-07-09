## 🇸​​​​​🇹​​​​​🇩​​​​​🇱​​​​​🇮​​​​​🇧​​​​​

Items that are globally accessible but do not fit nicely into any particular module or are global functions not listed elsewhere. These include new, **LuaEx** functions as well as hooks of existing Lua functions.

#### Functions
- **type** Works like the original Lua function except that it honors **LuaEx's** custom type system (for tables modified by ***table.settype*** or by manually setting a string value in a table's metatable key, ***__type***.).

- **subtype** Gets the subtype of an object/table. If it has not been given a subtype (either by using ***table.setsubtype*** or by manually setting the ***__subtype*** metatable key), then the string *"nil"* is returned.

- **fulltype** concatenates the results from ***__type*** and ***__subtype***.

- **xtype** Honor all **LuaEx's** pre-made (and internally-generated) custom types but ignores user implementation of the metatable value, ***__type***. So, for all user-defined types, it will return the string value, ***"table"***.

- **rawtype** The original Lua ***type*** function. It does not honor **LuaEx's** custom type system whatsoever; meaning, for all custom types, it will return the string value, ***"table"***.

- **sealmetatable** Permanently locks a metatable from being accessed, altered or changed by settting the ***__metatable*** key to *false*. This process cannot be undone. If the table does not have a metatable, one is created and sealed.

- **protect** This places a global into a protected table where it's place cannot be modified. That is, it cannot be deleted or changed. The exception is a table which can be modified unless locked (but it still cannot be deleted).

- **isnull** Returns true if the input is null or NULL, otherwise, returns false. TOTO MOVE THIS TO NULL SECTION

### [◀ Back](https://centaurisoldier.github.io/LuaEx/)
