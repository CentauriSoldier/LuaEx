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
| Value	| any	| The value of which to get the type. |

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
| Value	| any	| The value of which to get the full type. |

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
| Value	| any	| The value of which to get the type. |

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
| Value	| any	| The value of which to get the subtype. |

#### Return

| Type(s) | Description |
|-------|--------|
| string | The subtype of the value queried using **LuEx's** type system. |

#### Example

```lua
--create a table
local tMice = {"Brown", "Black", "White", "Grey"};

--add a type and subtype
table.settype(tMice, "Mouse");
table.setsubtype(tMice, "Colors");

--get and print the sub type
print(type.sub(tMice)); --Colors
```

<!--- x --->
<h2 class="func">x</h2>
<p class="funcdesc">The same as <b><i>type</i></b> except is ignores user types created by explicitly setting the <b><i>__type</i></b> metatable property; however, any custom types made by using <b><i>LuaEx's</i></b> mechanisms will return the custom type.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Value	| any	| The value of which to get the subtype. |

#### Return

| Type(s) | Description |
|-------|--------|
| string | The subtype of the value queried using **LuEx's** type system but ignoring user types. |

#### Example

```lua
--create a table
local tMice = setmetatable({"Brown", "Black", "White", "Grey"}, {__type="mousekind"});

--get and print type user type
print(type(tMice)); --mousekind

--get and print type user type (using x)
print(xtype(tMice)); --table

--now, try a LuaEx
enum("DOG", {"BIG", "SMALL", "MEDIUM"});
print(xtype(DOG)); --enum
print(xtype(DOG.MEDIUM)); --DOG
```

<!--
▄▀█ █░░ █ ▄▀█ █▀ █▀▀ █▀
█▀█ █▄▄ █ █▀█ ▄█ ██▄ ▄█
-->
<h1><center>🇦​​​​​🇱​​​​​🇮​​​​​🇦​​​​​🇸​​​​​🇪​​​​​🇸​​​​​</center></h1>
<center><p class = "funcdesc">For convenience, several of the <b><i>type</i></b> functions have been given aliases.</p></center>

| Alias | Original |
|-------|--------|
| rawtype | type.raw |
| xtype	| type.x |
| fulltype | type.full |
| subtype |	type.sub |


<!--
█ █▀   █▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀
█ ▄█   █▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█
-->
<h1><center>🇮​​​​​🇸​​​​​ 🇫​​​​​🇺​​​​​🇳​​​​​🇨​​​​​🇹​​​​​🇮​​​​​🇴​​​​​🇳​​​​​🇸​​​​​</center></h1>
<p class = "funcdesc">These are auto-generated functions that use all known types (lua, LuaEx and user types) to create each <u>is(type)</u> function.</p>
<p class = "funcdesc">For example, a list of Lua <u>is</u> functions is below for reference.</p>

| Function | Type Reference |
|-------|--------|
| isboolean | boolean |
| istable | table |
| isnumber | number |
| isstring | string |
| isfunction | function |
| isuserdata | userdata |
| isnil | nil |

<p class = "funcdesc">Every <u>is</u> function has the same number of arguments and produces the same output type.</p>

<!--- is --->
<h2 class="func">is(type)</h2>
<p class="funcdesc">Returns the type of the value using LuaEx's type system.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Value	| any	| The value to check if it's a specific type. |

#### Return

| Type(s) | Description |
|-------|--------|
| boolean | Returns true if the value is of the queried type and false otherwise. |

#### Example

```lua
--create a custom type
local tCats = table.settype({"Dumb", "Mean", "Playful", "Hungry"}, "CatsList");
--get and print the type of the new table
print(tostring(type.isCatsList(tCats)));

--now try with a variable non-compliant string
local tCats = table.settype({"Dumb", "Mean", "Playful", "Hungry"}, "&Variable Unfriendly");
--get and print the type of the new table
print(tostring(type["is&Variable Unfriendly"](tCats)));
```

<!--
█▀▄ █▀▀ █▀▀ ▄▀█ █░█ █░░ ▀█▀   ▀█▀ █▄█ █▀█ █▀▀ █▀   █▀▄▀█ █▀▀ ▀█▀ ▄▀█
█▄▀ ██▄ █▀░ █▀█ █▄█ █▄▄ ░█░   ░█░ ░█░ █▀▀ ██▄ ▄█   █░▀░█ ██▄ ░█░ █▀█
-->

<h1><center>🇩​​​​​🇪​​​​​🇫​​​​​🇦​​​​​🇺​​​​​🇱​​​​​🇹​​​​​<br>🇹​​​​​🇾​​​​​🇵​​​​​🇪​​​​​🇸​​​​​<br>🇲​​​​​🇪​​​​​🇹​​​​​🇦​​​​​🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​🇸​​​​​</center></h1>
<center><p class = "funcdesc"></p></center>

### boolean

<!--- __add --->
<h2 class="func">__add</h2>
<p class="funcdesc">Boolean arithmetic OR.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Left	| boolean	| The left boolean value. |
| Right	| boolean	| The right boolean value. |

#### Return

| Type(s) | Description |
|-------|--------|
| boolean | The result of the boolean arithmetic. |

#### Example

```lua
print(false + false); 	--false
print(false + true); 	--true
print(true + true); 	--true
```

<!--- __concat --->
<p class="func">__concat</p>
<p class="funcdesc">Attempts to concatenate the boolean value - to the other value by converting the boolean to a string.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Left	| any 	| The left value. |
| Right	| any	| The right value. |

##### Note: while one value may be of any type, at least ***one*** value must be of type boolean.

#### Return

| Type(s) | Description |
|-------|--------|
| string | The concatenated values. |

#### Example

```lua
local sString = "This value is ";

print(sString..true); --This value is true
print(sString..false); --This value is false

print(40 .. true); --40true
print(42 .. false); --42false

local tTable = {blarg="blarg"};
print(table.serialize(tTable).." "..true)--[[
{

	["blarg"] = "blarg",

} true
]]
```

<!--- __len --->
<p class="func">__len</p>
<p class="funcdesc">Returns 1 and 0 for true and false respectively.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Value	| boolean	| The value for which to get the numeric equivalent. |

#### Return

| Type(s) | Description |
|-------|--------|
| number | Returns 1 for true or 0 for false. |

#### Example

```lua
print(#false); --0
print(#true); --1
```

<!--- __mul --->
<p class="func">__mul</p>
<p class="funcdesc">Boolean arithmetic AND.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Left	| boolean	| The left boolean value. |
| Right	| boolean	| The right boolean value. |

#### Return

| Type(s) | Description |
|-------|--------|
| boolean | The result of the boolean arithmetic. |

#### Example

```lua
print(false * false); --false
print(false * true); --false
print(true * true); --true
```

<!--- __neg --->
<p class="func">__neg</p>
<p class="funcdesc">Negates the value so true becomes false and false becomes true.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Value	| boolean	| The boolean value to negate. |

#### Return

| Type(s) | Description |
|-------|--------|
| boolean | The opposite of the input. |

#### Example

```lua
print(-false); --true
print(-true); --false
```

<!--- __tostring --->
<p class="func">__tostring</p>
<p class="funcdesc">Returns "true" and "false" for true and false respectively.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Value	| boolean	| The boolean value to convert to a string. |

#### Return

| Type(s) | Description |
|-------|--------|
| string | Returns "true" for true and "false" for false. |

#### Example

```lua
print(false); --false
print(true); --true
```

### number
<!--- __tostring --->
<p class="func">__tostring</p>
<p class="funcdesc">Coerces the number to string.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Value	| any	| . |

#### Return

| Type(s) | Description |
|-------|--------|
| boolean | . |

#### Example

```lua

```

<!--- __len --->
<p class="func">__len</p>
<p class="funcdesc">Converts the number to boolean for values 0 and 1 but nil for all other values.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Value	| any	| . |

#### Return

| Type(s) | Description |
|-------|--------|
| boolean | . |

#### Example

```lua

```

### string
<!--- __mod --->
<p class="func">__mod</p>
<p class="funcdesc">Allows for string interpolation.</p>

#### Parameter(s)

| Name | Type(s) | Description |
|-------|--------|---------|
| Value	| string	| The string that is to be interpolated upon. |
| Value | table 	| The table that contains the values to be interpolated. |

#### Return

| Type(s) | Description |
|-------|--------|
| string | The interpolated string. |

#### Example

```lua
--create a string and interpolate variables into it
local sCats = "Cats are nice. My favorite type of cat is a ${bluecat}.\nBut even better are ${othercat}.\nI have ${catcount} cats." % {bluecat="blue and red cat", othercat="calicos", catcount=22};

--print the string
print(sCats);--[[
				Cats are nice. My favorite type of cat is a blue and red cat.
				But even better are calicos.
				I have 22 cats.
				]]

```

<!--
█▄░█ █░█ █░░ █░░
█░▀█ █▄█ █▄▄ █▄▄
-->
<h1><center>🇳​​​​​🇺​​​​​🇱​​​​​🇱​​​​​</center></h1>
<center><p class = "funcdesc">NULL (also null) is a custom type added to **LuaEx**. It is of type null and has obligatory comparison behavior for null values as it does in many programming languages. The main purpose of this value, as an alternative for ***nil***, is to allow the retention of table keys while still indicating a lack of value for a given key. Of course, you may use this null value however you wish. You can use the ***isnull*** function to determine whether a value is null. Both ***null*** and ***NULL*** are the same value and may be accessed by using either word.</p></center>

### Notes:
- Calling the ***rawtype*** function with ***null*** (or ***NULL***) as an argument will return the value, "table".
- Do ***not*** localize ***null*** (or ***NULL***)...strange things happen.
