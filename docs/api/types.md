<h1><center>🇹​​​​​🇾​​​​​🇵​​​​​🇪​​​​​ 🇴​​​​​🇻​​​​​🇪​​​​​🇷​​​​​🇭​​​​​🇦​​​​​🇺​​​​​🇱​​​​​</center></h1>
<blockquote>
<p class="funcdesc">Lua types have been heavily overhauled to be more versatile, robust and to allow for custom types. Additionally, several of the base types have been given metatables in order to extend their functionality. The Lua <b><i>type</i></b> function has been recast as a table. These changed are explained in detail below.</p>
</blockquote>
<br>
<center><h1>🇨​​​​​🇺​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇲​​​​​ 🇹​​​​​🇾​​​​​🇵​​​​​🇪​​​​​🇸​​​​​</h1></center>
<p class="funcdesc">Custom types may be create by adding the <b><i>__type</i></b> key to a table's metatable and setting the value to a string. This may also be done by using the <b><i>table.settype()</i></b> function. Once set, get the type using the <b><i>type</i></b> function.</p>
<p class="funcdesc">Additionally, subtypes may be created by add a <b><i>__subtype</i></b> key to a table's metatable and setting the value to a string. This may also be done by using the <b><i>table.setsubtype()</i></b> function. Once set, get the subtype using the <b><i>type.sub</i></b> or <b><i>subtype</i></b> function.
</p>
<br>

***

<!--
█▀▄▀█ █▀▀ ▀█▀ ▄▀█ █▀▄▀█ █▀▀ ▀█▀ █░█ █▀█ █▀▄ █▀   ▄▀█ █▄░█ █▀▄   █▀█ █▀█ █▀█ █▀█ █▀▀ █▀█ ▀█▀ █ █▀▀ █▀
█░▀░█ ██▄ ░█░ █▀█ █░▀░█ ██▄ ░█░ █▀█ █▄█ █▄▀ ▄█   █▀█ █░▀█ █▄▀   █▀▀ █▀▄ █▄█ █▀▀ ██▄ █▀▄ ░█░ █ ██▄ ▄█
-->
<h1><center>🇲​​​​​🇪​​​​​🇹​​​​​🇦​​​​​🇲​​​​​🇪​​​​​🇹​​​​​🇭​​​​​🇴​​​​​🇩​​​​​🇸​​​​​</center></h1>
<h1><center>​​🇦​​​​​🇳​​​​​🇩​​​​​</center></h1>
<h1><center>🇵​​​​​🇷​​​​​🇴​​​​​🇵​​​​​🇪​​​​​🇷​​​​​🇹​​​​​🇮​​​​​🇪​​​​​🇸​​​​​</center></h1>

<!--- __call --->
<h2 class="func">__call</h2>
<p class="funcdesc">The function executed when you call the <i>type</i> table.</p>

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
<!--- __type --->
<h2 class="func">__type</h2>
<p class="funcdesc">This sets the type of the <i>type</i> table to "function" purely to maintain tradition.</p>

#### Example

```lua
--get and print the type of 'type'
print(type(type)); --function
```
<br>
<!--
█▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀
█▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█
-->
<h1><center>🇫​​​​​🇺​​​​​🇳​​​​​🇨​​​​​🇹​​​​​🇮​​​​​🇴​​​​​🇳​​​​​🇸​​​​​</center></h1>
<br>
<h2 class="func">full</h2>
<p class="funcdesc">Concatenates the <i>__type</i> and <i>__subtype</i> metatable properties (and adds a space in between if a subtype exists).<br>If it is not a custom type, simply returns the type.</p>

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
<!--- getall --->
<h2 class="func">getall</h2>
<p class="funcdesc">Gets a list of all types.</p>

#### Return

| Type(s) | Description |
|-------|--------|
| table | The numerically-indexed table whose values are the types (strings). |

<!--- getlua --->
<h2 class="func">getlua</h2>
<p class="funcdesc">Gets a list of Lua types.</p>

#### Return

| Type(s) | Description |
|-------|--------|
| table | The numerically-indexed table whose values are the types (strings). |

<!--- getluaex --->
<h2 class="func">getluaex</h2>
<p class="funcdesc">Gets a list of <b><i>LuaEx</i></b> types.</p>

#### Return

| Type(s) | Description |
|-------|--------|
| table | The numerically-indexed table whose values are the types (strings). |

<!--- getuser --->
<h2 class="func">getuser</h2>
<p class="funcdesc">Gets a list of user types.</p>

#### Return

| Type(s) | Description |
|-------|--------|
| table | The numerically-indexed table whose values are the types (strings). |

<!--- raw --->
<h2 class="func">raw</h2>
<p class="funcdesc">This is the original Lua <b><i>type</i></b> function.</p>

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

--get and print the raw (basic Lua) type, ignoring LuaEx's custom type system
print(type.raw(tDogs)); --table
```

<!--- sub --->
<h2 class="func">sub</h2>
<p class="funcdesc">Gets the subtype of an value.</p>

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

<!--- x --->
<h2 class="func">x</h2>
<p class="funcdesc">.</p>

<!--
▄▀█ █░░ █ ▄▀█ █▀ █▀▀ █▀
█▀█ █▄▄ █ █▀█ ▄█ ██▄ ▄█
-->
<h1><center>🇦​​​​​🇱​​​​​🇮​​​​​🇦​​​​​🇸​​​​​🇪​​​​​🇸​​​​​</center></h1>
<center><p class = "funcdesc">For convenience, several of the <b><i>type</i></b> functions have been given aliases.</p></center>

| Alias | Original |
|-------|--------|
| rawtype | type.raw |

<!--
| <h2 class = "func">xtype</h2> 	|  	<h2 class = "func">type.x</h2> 		|
| <h2 class = "func">fulltype</h2>	| 	<h2 class = "func">type.full</h2>	|
| <h2 class = "func">subtype</h2>	|	<h2 class = "func">type.sub</h2>	|

█ █▀   █▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀
█ ▄█   █▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█
-->
<h1><center>🇮​​​​​🇸​​​​​ 🇫​​​​​🇺​​​​​🇳​​​​​🇨​​​​​🇹​​​​​🇮​​​​​🇴​​​​​🇳​​​​​🇸​​​​​</center></h1>
<center><p class = "funcdesc"></p></center>
<!--
█▀▄ █▀▀ █▀▀ ▄▀█ █░█ █░░ ▀█▀   ▀█▀ █▄█ █▀█ █▀▀ █▀   █▀▄▀█ █▀▀ ▀█▀ ▄▀█
█▄▀ ██▄ █▀░ █▀█ █▄█ █▄▄ ░█░   ░█░ ░█░ █▀▀ ██▄ ▄█   █░▀░█ ██▄ ░█░ █▀█
-->

<h1><center>🇩​​​​​🇪​​​​​🇫​​​​​🇦​​​​​🇺​​​​​🇱​​​​​🇹​​​​​<br>🇹​​​​​🇾​​​​​🇵​​​​​🇪​​​​​🇸​​​​​<br>🇲​​​​​🇪​​​​​🇹​​​​​🇦​​​​​🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​🇸​​​​​</center></h1>
<center><p class = "funcdesc"></p></center>














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
