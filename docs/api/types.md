#WIP--rewriting for clarity and continuity



##Type Overhaul

Lua types have been heavily overhauled to be more versatile, robust and to allow for custom types. Additionally, several of the base types have been given metatables in order to extend their functionality. These changed are explained in detail below.
<br>
<br>
<center><h4>The Lua <b><i>type</i></b> function has been recast as a table as follows:</h4></center>
<br>
<h1><center>Metamethods and Properties</center></h1>
<br>
<h2>__call</h2>
<h5>The function executed when you call the <i>type</i> table.</h5>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Item	| any	| The value of which to get the type. |

#### Return

| Type(s) | Description |
|-------|--------|
| string | The type of the value queried using **LuEx's** type system. |

#### Example
```lua
--create a basic table
local tDogs = {"Lab", "Husky"};

--get and print the type
print(type(tDogs)); --table

--now, let's add a metatable and set a custom type
--(we could also use table.settype to do this)
setmetatable(tDogs, {__type="Dog List"});

--get and print the new type
print(type(tDogs)); --Dog List
```

<h2 class="func">__type</h2>
<h5>This sets the type of the <i>type</i> table to "function" purely to maintain tradition.</h5>

#### Example

```lua
--get and print the type of 'type'
print(type(type)); --function
```
<br>
<h1><center>Functions</center></h1>
<br>
<h2>full</h2>
<h5>Concatenates the <i>__type</i> and <i>__subtype</i> metatable properties (and adds a space in between if a subtype exists).<br>If it is not a custom type, simply returns the type.</h5>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Item	| any	| The value of which to get the full type. |

#### Return

| Type(s) | Description |
|-------|--------|
| string | The type and subtype of the value queried using **LuEx's** type system. |

#### Example

```lua
--create a table
local tMice = {"Brown", "Black", "White", "Grey"};
--add a type and subtype
table.settype(tMice, "Mouse");
table.setsubtype(tMice, "Colors");
--get and print the full type
print(type.full(tMice));
```

<h2>getall</h2>
<h5>Gets a list of all types.</h5>

#### Return

| Type(s) | Description |
|-------|--------|
| table | The numerically-indexed table whose values are the types (strings). |

<h2>getlua</h2>
<h5>Gets a list of Lua types.</h5>

#### Return

| Type(s) | Description |
|-------|--------|
| table | The numerically-indexed table whose values are the types (strings). |

<h2>getluaex</h2>
<h5>Gets a list of <b><i>LuaEx</i></b> types.</h5>

#### Return

| Type(s) | Description |
|-------|--------|
| table | The numerically-indexed table whose values are the types (strings). |

<h2>getuser</h2>
<h5>Gets a list of user types.</h5>

#### Return

| Type(s) | Description |
|-------|--------|
| table | The numerically-indexed table whose values are the types (strings). |

<h2>raw</h2>
<h5>This is the original Lua <b><i>type</i></b> function.</h5>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Item	| any	| The value of which to get the type. |

#### Return

| Type(s) | Description |
|-------|--------|
| string | The type of the value queried ignoring **LuEx's** type system. |

#### Example
```lua
--create a basic table
local tDogs = {"Lab", "Husky"};

--get and print the type
print(type(tDogs)); --table

--now, let's add a metatable and set a custom type
--(we could also use table.settype to do this)
setmetatable(tDogs, {__type="Dog List"});

--get and print the new type
print(type(tDogs)); --Dog List
```


## sub
<h5>Gets the subtype of an value.</h5>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Item	| any	| The value of which to get the subtype |

#### Return

| Type(s) | Description |
|-------|--------|
| string | The subtype of the value queried using **LuEx's** type system.

#### Example

```lua
--create a table
local tMice = {"Brown", "Black", "White", "Grey"};
--add a type and subtype
table.settype(tMice, "Mouse");
table.setsubtype(tMice, "Colors");
--get and print the sub type
print(type.sub(tMice));
```

<h2><center>x</center></h2>
<center><h5>.</h5></center>

#### Aliases






















## 🇹​​​​​🇾​​​​​🇵​​​​​🇪​​​​​ 🇲​​​​​🇪​​​​​🇹​​​​​🇦​​​​​🇲​​​​​🇪​​​​​🇹​​​​​🇭​​​​​🇴​​​​​🇩​​​​​🇸​​​​​

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

### boolean
- __add (+) Boolean arithmetic OR.
- __concat (..) Attempts to concatenate the boolean value - to the other value by converting the boolean to a string.
- __len (#) Returns 1 and 0 for true and false respectively.
- __mul (*) Boolean arithmetic AND.
- __neg (-) Negates the value so true becomes false and false becomes true.
- __tostring Returns "true" and "false" for true and false respectively.

### number
- __tostring Coerces the number to string.
- __len Converts the number to boolean for values 0 and 1 but nil for all other values.

### string
- __mod Allows for string interpolation.
