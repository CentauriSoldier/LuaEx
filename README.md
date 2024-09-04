<div align="center">
  <img src="https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png" alt="LuaEx Logo">
</div>

---

## 🆆🅷🅰🆃 🅸🆂 🅻🆄🅰🅴🆇❓ 🔬</center>
Simply put, **LuaEx** is a lightweight overhaul of Lua that extends its functionality.

Below are some of the [🅵🅴🅰🆃🆄🆁🅴🆂](#features)
in **LuaEx** (*See documentation for full details*).


## 🅶🅴🆃🆃🅸🅽🅶 🆂🆃🅰🆁🆃🅴🅳 🚀
In order to push all the code in **LuaEx** into the global environment, place the **LuaEx** folder into your package path and run the following code:
```lua
require("LuaEx.init");
```
From here on out, all modules of **LuaEx** will be available in the global environment.


## 🆅🅴🆁🆂🅸🅾🅽 ⚗

#### Current Version: Beta v0.90
<details>
<summary>🆅🅸🅴🆆 🅲🅷🅰🅽🅶🅴🅻🅾🅶</summary>

### 🇨​​​​​🇭​​​​​🇦​​​​​🇳​​​​​🇬​​​​​🇪​​​​​🇱​​​​​🇴​​​🇬​​​​​
**v0.91** ***(IN PROGRESS)***
- Bugfix:  **Structfactory** not properly cloning itself.
- Bugfix:  **Structs** not properly cloning internal objects.
- Bugfix:  Instance returns in parent class were not properly returning child instance when subclassed.
- Bugfix:  Dox "Copy" button not working.
- Change:  Dox now places all output into a single HTML file instead of using a separate *.js* file.
- Change:  Dox CSS redesigned to be more functional and aesthetically pleasing.
- Feature: Dox now has an ***@inheritdoc*** tag that allows inheritance of docs from one **fqxn** to another.
- Feature: Dox Fully Qualified Dox Names (**fqxn**) may now contain spaces.
- Feature: Dox now allows custom intro page message.
- Feature: Subclassing is now able to be limited to certain subclass types by providing either a blacklist or whitelist.
- Feature Added several class-level checks:
    - **class.of**
    - **class.getname**
    - **class.getbase**
    - **class.is**
    - **class.isbase**
    - **class.ischild**
    - **class.ischildorself**
    - **class.isdirectchild**
    - **class.isdirectparent**
    - **class.isinlineage**
    - **class.isinstance**
    - **class.isinstanceof**
    - **class.isparent**
    - **class.isparentorself**    
- Feature: Classes now fully respect polymorphism in assignment operation type checking.
- Feature: The class constructor may now be either private, protected or public.
- Feature: Classes now have an *optional* static constructor using the class name as the static method name.
- Feature: Dox comment blocks can now use anchor links (*#*) to other FQXNs.
- Feature: added Dox output back navigation.
- Feature: Dox now uses **prism.js** for displaying code blocks with syntax highlighting for all available **prism.js** languages.
- Feature: added a "Copy" (to clipboard) button to all user-created code blocks.
- Feature: added a **Code** ***BlockTag*** to Dox, permitting code examples with any user-specified **prism.js** language.
- Feature: **Example** ***BlockTag*** now automatically detects the **prism.js** language based on the Dox subclass being used.
- Feature: **prism.js** scripts are automatically added to Dox's finalized HTML output based on the languages used in the documentation.
- Feature: added Dox parsers (subclasses) for several new languages.

**v0.90**
- Bugfix:  error in ***type.assert.table*** where value type was showing as index type, resulting in false negatives.
- Bugfix:  error in **SortedDictionary** causing malformed returns.
- Bugfix:  fatal bug in cloner preventing the cloning of items.
- Change:  rewrote and completed the interface system for classes.
- Feature: added support for code html tags using **prism.js** in **Dox** module.
- Feature: added several new features to **Dox** and prepped it for major updates in future releases.
- Feature: added ***type.assert.function***.
- Feature: all items in tables are now properly cloned.
- Feature: class tables are now cloned so class instances may now start with clonable objects as default properties.

**v0.83**
- Bugfix:   various, minor bugs.
- Bugfix:   major bug in class auto directive causing malformed classes.
- Feature:  reorganized and added sections and examples to README.
- Feature:  integrated and rewrote Dox documentation module and added support for other languages.
- Refactor: restructured module layout and added more examples to the **examples** directory.

**v0.82**
- Bugfix:   various, minor bugs.
- Feature:  created new **Ini.lua** module.
- Feature:  created new **base64.lua** module.
- Feature:  created **cloner.lua** module. Updated various, existing items to make them clonable.
- Feature:  created new **serializer.lua** module that handles serialization and deserialization.
- Feature:  added serval examples in the **examples** directory for demonstrating usage.
- Change:   removed old **ini.lua** module.
- Change:   removed old **base64.lua** module.
- Change:   modified **cloner** to work with custom, user-created objects.
- Change:   removed old **serialize.lua** and **deserialize.lua** modules.
- Change:   modified the serializer to work with custom, user-created objects.
- Change:   modified the cloner to work with custom, user-created objects.
- Change:   modified **init.lua** to provide some user options for class loading.
- Change:   changed all class names to PascalCase to provide clear distinction between class variables and other variables.
- Refactor: moved several items in the directory structure

**v0.81**
- Bugfix: renamed the **\_\_LUAEX\_\_** table reference in the **enum** module that got missed.
- Change: removed class system from **v0.8** as it had a fatal, uncorrectable flaw.
- Change: rewrote the class system again from scratch, avoiding fatal flaw in previous system.
- Change: renamed ***type.x*** to ***type.ex*** and ***typex*** to ***typeex*** to more clearly indicate the check refers to **LuaEx** types.
- Change: set types for factories. (E.g., print(type(class)); --> classfactory)
- Change: removed static protected members from the class system as using them is, almost always, an anti-pattern.
- Change: class members are now strongly typed.
- Change: ***temporarily*** disabled compulsory classes until they're refactored for new class system.
- Change: ***temporarily*** removed class interfaces until it's rewritten to operate with the new class system.
- Change: cleaned up and reorganized a lot of the files in the **LuaEx** module.

**v0.80**
- Change:   rewrote the class system from scratch.
- Change:   renamed **\_\_LUAEX\_\_** global table **luaex**.
- Feature:  added class interfaces.
- Feature:  class system now uses full encapsulation (static protected, static public, private, protected and public fields & methods).
- Feature:  **luaex** table now contains a **\_VERSION** variable.
- Refactor: moved various modules to different directories.

**v0.70**
- Change:   enum items now use functions (.) instead of methods (:) and automatically input themselves as arguments.
- Change:   enum items' ***next*** and ***previous*** functions *may* now wrap around to the start and end respectively.
- Change:   renamed functions in various modules to conform with Lua's lowercase naming convention.
- Change:   improved the ***string.totable*** function.
- Change:   the ***xtype*** function will now ignore user-defined types but return **LuaEx**'s type names for **classes**, **constants**, **enums**, structs, **struct factories** (and **struct_factory_constructor**) and **null** (and **NULL**) as opposed to returning, *"table"*. *Use the **rawtype** function to ignore all **LuaEx** type mechanics*.
- Change:   renamed the ***string.delimitedtotable*** function to ***string.totable***.
- Bugfix:   corrected several minor bugs in enum library.
- Bugfix:   corrected assertions in stack class.
- Bugfix:   ***set.addset*** was not adding items.
- Feature:  added several type functions and metamethods to various default types (e.g., boolean, string, number, etc.).
- Feature:  added serialization to enums.
- Feature:  added the **ini** module.
- Feature:  added ***string.isnumeric*** function.
- Feature:  added a ***\_\_mod*** metamethod for string which allows for easy interpolation.
- Feature:  added null type.
- Feature:  added the **struct** factory module.
- Feature:  added the ***xtype*** function.
- Feature:  added the ***fulltype*** function.
- Refactor: moved all type items to **types.lua**.

**v0.60**
- Feature:  removed ***string.left*** as it was an unnecessary and inefficient wrapper of ***string.sub***.
- Feature:  removed ***string.right*** as it was an unnecessary and inefficient wrapper of ***string.sub***.
- Feature:  added ***string.trim*** function.
- Feature:  added ***string.trimleft*** function.
- Feature:  added ***string.trimright*** function.
- Bugfix:   corrected package.path code in init.lua and removed ***import*** function.
- Refactor: moved modules into appropriate subdirectories and updated init.lua to find them.
- Refactor: appended ***string***, ***math*** & ***table*** module files with "hook" without which they would not load properly.
- Update:   updated README with more information.

**v0.50**
- Bugfix: ***table.lock*** was altering the metatable of **enums** when it should not have been.
- Bugfix: ***table.lock*** was not preserving metatable items (where possible).
- Change: classes are no longer automatically added to the global scope when created; rather, they are returned for the calling script to handle.
- Change:  **LuaEx** classes and modules are no longer auto-protected and may now be hooked or overwritten. This change does not affect the way constants and enums work in terms of their immutability.
- Change:  **enums** values may now be of any non-nil type(previously only **string** and **number** were allowed).
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

**v0.40**
- Bugfix:  metavalue causing custom type check to fail to return the proper value.
- Bugfix:  typo that caused global enums to not be put into the global environment.
- Feature: enums can now also be non-global.
- Feature: the enum created by a call to the enum function is now returned.

**v0.30**
- Change:  Added a meta table to ***\_G*** in the **init** module.
- Change:  Changed the name of the **const** module and function to **constant** for Lua 5.1 - 5.4 compatibility.
- Change:  Altered the way constants and enums work by using the new, ***\_G*** metatable to prevent deletion or overwriting.
- Change:  Updated several modules.
- Feature: Hardened the protected table to prevent accidental tampering.

**v0.20**
- Change: Added the enum object.
- Change: Updated a few modules.

**v0.10**
- Compiled various modules into **LuaEx**.
</details>

## 🅻🅸🅲🅴🅽🆂🅴 ©

All code is placed in the public domain under [The Unlicense](https://opensource.org/licenses/unlicense "The Unlicense") *(except where otherwise noted)*.

<details>
<summary>🆅🅸🅴🆆 🅻🅸🅲🅴🅽🆂🅴</summary>
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
</details>

## 🆆🅰🆁🆁🅰🅽🆃🆈 🗞
None. Use at your own risk. 💣


## 🅳🅾🅲🆄🅼🅴🅽🆃🅰🆃🅸🅾🅽 🗎

All documentation for **LuaEx** is on ***GitHub Pages*** found here:
### [https://centaurisoldier.github.io/LuaEx](https://centaurisoldier.github.io/LuaEx)  


## 🅳🅴🆅🅴🅻🅾🅿🅼🅴🅽🆃 🅶🅾🅰🅻🆂 ⌨

#### Why Write LuaEx?
**LuaEx** attempts to implement code solutions for common and frequent problems. I found myself rewriting code over and again or copying old blocks of code from other projects into new projects and finally decided it would be better to compile that code into one single, easy-to-use module.

#### Big Things Come in Small Package
Keeping this module small is essential to making it useful. You shouldn't have to spend a year learning how to use something designed to be easy to use; **LuaEx** is developed with that in mind.

#### Simplicity
Retaining simplicity of the code is also a primary goal of this module. The code should be intuitive and I strive toward that end. The purpose being that both you and I should be able to read the code and understand it.

#### Conventional Consistency
This project is made to be consistent both with Lua's naming & coding conventions as well as internally.  
While my own convention uses (dromedary) [*camelCase*](https://en.wikipedia.org/wiki/Camel_case) and *PascalCase*, I defer to **Lua's** convention where appropriate.  
What that means is, everything that's hooked directly into **Lua** or creates new base types (*e.g.*, ***table.clone***, ***rawtype***, **enums**, **arrays**, **structs**), respects the *alllowercase* convention used by **Lua**; however, for any items which do not, the convention is *camelCase* (e.g., functions) and *PascalCase* (e.g., classes).
This helps maintain expectations of the user while accessing **Lua** items while still allowing me to adhere to my own convention for things outside of **Lua's** core.

#### Naming Conventions
**LuaEx** adheres to strict naming conventions for the sake of clarity, consistency, readability and [OCD](https://en.wikipedia.org/wiki/Obsessive%E2%80%93compulsive_disorder) compliance.

<details>
<summary>🆅🅸🅴🆆 🅲🅾🅽🆅🅴🅽🆃🅸🅾🅽🆂</summary>  

Variables are prefixed with the following lower-case symbols based on their type/application and appear to be PascalCase *after* the prefix. Combined with the prefix, this makes them camelCase.

*_* |   **file-scoped local variables** *e.g.,* ```local _nMaxUnits = 12;```  
*a* |   **array**  
*b*	|	**boolean**  
*c*	|	**class**  
*e*	|	**enum**  
*f*	| 	**function**  
*h*	|	**file\window\etc. handle** *(number)*  
*n*	|	**number**  
*p*	|	**file\dir path** *(string)*  
*r*	|	**struct**  
*o*	|	**class\other** *(object)*  
*s*	|	**string**  
*t*	|	**table**  
*u*	| 	**userdata**  
*v*	|	**variable/unknown type**  
*w*	|	**environment table** *(table)*  
*x*	|	**factory**  
*z*	|	**type** *(string)* (e.g., "string", "table", etc.)  

Types ignored by this convention are types **nil** and **null** since prefixing such a variable type would, generally, serve no real purpose.

###### Exceptions:
In **for loops**, sometimes '*x*' is used to indicate active index while 'k' and 'v' are used (when using pairs/ipairs) to reference the key and value of a table respectively. This shorthand is used often when the purpose and process of the loop is self-evident or easily determined at a glance.

Global variables that are directory paths begin with **_** and ***do not*** have a variable prefix.
E.g., _Scripts

In class methods, the first two arguments--the instance object and the class data table respectively) are written as '*this*' and '*cdat*' while the third argument in a child class constructor—the parent constructor method—is written as '*super*'.  
Additionally, In any method that accepts the input of another class instance, the variable is written as '*other*' (or as '*left*' and '*right*' in metamethods). This intentional and obvious deviation from convention makes these variables stand out clearly.  
Within methods, cdat.pri (and other class data tables) may be set as ```local pri = cdat.pri; ```.

Class name are *PascalCase*.  
E.g,  
```lua
MyNewClass = class(...);
```
</details>
<br>

#### Principle of Least Astonishment
In developing **LuaEx**, I strive to take full advantage of the flexibility of the Lua language while still adhering to the [Principle of Least Astonishment](https://en.wikipedia.org/wiki/Principle_of_least_astonishment).

The only *limited* exceptions made are for new features (*whose developments are generally permitted exclusively by Lua*) not otherwise found in other OOP languages.  
Simply put, things are intended to be intuitive.

#### User Feedback
While I develop **LuaEx** for my own projects, it's also designed to be used by others.  
For their benefit and my own, I take user feedback seriously and address and appreciate submitted issues and pull requests.

## 🅲🅾🅼🅿🅰🆃🅸🅱🅸🅻🅸🆃🆈 ❤
**LuaEx** is designed for **Lua 5.3**; however, I will make every possible effort to make it backward compatible with the latest version of **Lua 5.1**.  
To that end, if you're using **Lua 5.1** and come across a bug that appears specific to that version, please submit a issue and I'll address it.  
Please keep in mind, if there is ever an intractable conflict between **Lua 5.1** and **Lua 5.3**, **Lua 5.3** will ***always*** take precedence.


<br>
<br>

---

# <center><a id="features"></a>🅵🅴🅰🆃🆄🆁🅴🆂✨⭐📲</center>

---

<br>
<br>

## 🅽🅴🆆 🆃🆈🅿🅴 🆂🆈🆂🆃🅴🅼 💫
- Allows for type checking against old, new and user-created types. For example, if the user created a **Creature** class, instantiated an object and checked the type of that object, ***type*** would return **"Creature"**. In addition to new **LuaEx** types (such as **array**, **enum**, **class**, **struct**, etc.), users can create their own types by setting a string value in the table's metatable under the key, *__type*. Subtypes are also available using the *__subtype* key (use ***type.sub*** function to check that).
- boolean to number/string coercion, number to boolean coercion, boolean math, boolean negation, etc.
- The ***null*** (or ***NULL***) type now exists for the main purpose of retaining table keys while providing no real value. While setting a table key to nil will remove it, setting it to ***null*** will not.  
The ***null*** value can be compared to other types and itself.  
In addition, it allows for undeclared initial types in **classes**, **arrays** and **structs**.  
  - As shown above, The ***null*** value has an alias: ***NULL***.  
  - ***WARNING***: <u>*never*</u> localize the ***null*** (or ***NULL***) value! Strange things happen...you've been warned. **☠ ☣ ☢ 💥**


###### Boolean

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

```lua
-- Logical OR
print(true + false);  -- true (logical OR)
print(false + false);  -- false (logical OR)

-- Concatenation
print("This value is " .. true);  -- "This value is true"
print(false .. " value");  -- "false value"

-- Length
print(#true);  -- 1
print(#false);  -- 0

-- Logical AND
print(true * false);  -- false (logical AND)
print(true * true);  -- true (logical AND)

-- String Coercion
print(tostring(true));  -- "true"
print(tostring(false));  -- "false"

-- Negation
print(-true);  -- false (negation)
print(-false);  -- true (negation)

-- Logical XOR (custom operator)
print(true ~ false);  -- true (logical XOR)
print(true ~ true);  -- false (logical XOR)

-- Logical NAND
print(not (true and true));  -- false (logical NAND)
print(not (true and false));  -- true (logical NAND)

-- Logical NOR
print(not (true or false));  -- false (logical NOR)
print(not (false or false));  -- true (logical NOR)

-- Logical XNOR (equivalence)
print(true == true);  -- true (logical XNOR/equivalence)
print(false == true);  -- false (logical XNOR/equivalence)

-- Implication
print((not false) or true);  -- true (implication)
print((not true) or false);  -- false (implication)


--etc.
```  
</details>



###### Number

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>
</details>

###### Null
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

```lua
print(null < 1);    --> true
print(null < "");   --> true
print(null < nil);  --> false
local k = null;
print(k)            --> null
```
</details>

---

##### Constants ♾️
While **Lua 5.4** offers constants natively, previous versions don't.  
As **LueEx** is not built for **5.4**, constants are provided. They may be of any non-nil type (*though ***null*** [or ***NULL***] should **never** be set as a constant, as it already is*).  

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

```lua
constant("MAX_CREATURES", 45);
print(MAX_CREATURES);           --> 45
constant("ERROR_MARKER", "err:");
print(ERROR_MARKER);            --> "err:"
```
</details>

---

##### String Interpolation 💱
```lua
"I can embed variables like, ${var1}, in my strings and make ${adjective} madlibs." % {var1 = "Frog", adjective = "crazy"};
```

---

##### Class System 💠
- A fully-functional, (*pseudo*) [Object Oriented Programming](https://en.wikipedia.org/wiki/Object-oriented_programming) class system which features encapsulation, inheritance, and polymorphism as well as optional interfaces.
- The class system also takes advantage of metatables and allows user to create, inherit and override these for class objects.
- Optional **Properties**: auto getter/setter (*accessor/mutator*) directives which create getter/setter methods for a given non-method member.
- Optional static initializer method called once during class creation.
- Strongly typed values (although allowing initial ***null*** values).
- Optional final methods (preventing subclass overrides).
- Optional final classes.
- Optional limited classes meaning a class can limit which classes can subclass it.
- **More** features inbound...

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

```lua
Creature = class("Creature",
{--metamethods
},
{--public static members
    createCount = 0;
    _INIT = function(stapub)
        --DO static things here during class creation.
    end,
},
{--private members
    DeathCount = 0,
    Allies = {},
},
{--protected members --set up properties using the _AUTO directive
    HP_AUTO     = 10,
    HPMax_AUTO  = 100,
    Damage_AUTO = 5,
    AC_AUTO     = 0,
    Armour_AUTO = 0,
},
{--public members
    Creature = function(this, cdat, nHP, nHPMax)
        cdat.pro.HP     = nHP < 1 and 1 or nHP;
        cdat.pro.HP     = nHP > nHPMax and nHPMax or nHP;
        cdat.pro.HPMax  = nHPMax;
    end,
    isDead__FNL = function(this, cdat) --set this method as final
        return cdat.pro.HP <= 0;
    end,
    kill = function(this, cdat)
        cdat.pro.HP = 0;
    end,
    move = function(this, cdat)

    end
},
NO_PARENT, false, NO_INTERFACES);



local HP_MAX = 120; -- this is an example of a private static field

Human = class("Human",
{--metamethods
},
{--public static members
},
{--private members
    Name_AUTO = "",
},
{--protected members
},
{--public members
    Human = function(this, cdat, super, sName, nHP)
        --print("human", sName, nHP, HP_MAX)
        super(nHP, HP_MAX);
        cdat.pri.Name = sName;
    end,
},
Creature, false, NO_INTERFACES);

local Dan = Human("Dan", 45);
print("Name: "..Dan.getName());                         --> "Name: Dan"
print("HP: "..Dan.getHP());                             --> "HP: 45:"
print("Type: "..type(Dan));                             --> "Type: Human"
print("Is Dead? "..Dan.isDead());                       --> "Is Dead? false"
print("Kill Dan ):!"); Dan.kill();                      --> "Kill Dan ):!"
print("Is Dead? "..Dan.isDead());                       --> "Is Dead? true"
print("Set Name: Dead Dan"); Dan.setName("Dead Dan");   --> "Set Name: Dead Dan"
print("Name: "..Dan.getName());                         --> "Name: Dead Dan"
```
</details>

---

##### Enums 🔠
- Can be local or global and even embedded at runtime.
- Have the option for custom value types for items.
- Strict ordinal adherence.
- Built-in iterator.
- QoL methods and properties like ***next***, ***previous***, etc.

---

##### Structs 🕋
These objects are meant to behave as you might expect from other languages but with added features.  

They are made by first creating a struct factory. The factory created is of type **[sName]factory** (of subtype **structfactory**) where *sName* is the name input into the *struct factory builder* (as shown in the example below).  

Struct factories output type **sName** (of subtype **struct**).

Creation of a **structfactory** object involves inputting a string-indexed table whose value types are rigidly set by the type given in the input table (or null to remain variable). **Structs** can be set to immutable but are mutable by default.  

***Note**: item types are **not** mutable save for an item containing a **null** value (before being set to a value type). Once an item that contains a **null** value has been set to a real value type, the type cannot be changed.*

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

 ```lua
--create a mutable bullet struct table
local bImmutable = false; --set this to true to disallow value changes
local tBullet = {
    speed   = 5,
    damage  = 10,
    caliber = "9mm",
    owner   = null, --this type can be set later by each bullet created
};

--create the struct factory
xBullet = structfactory("bullet", tBullet, bImmutable);

--print the details of the struct factory
print("Bullet factory:\n", xBullet);

--print the factory's type and subtype
print("Factory's Type - Subtype :\n", type(xBullet), " - ",subtype(xBullet));

--let's make a bullet with the default values
local oBullet1 = xBullet();

--print the first bullet
print("\n\nBullet #1:\n", oBullet1);

--print the bullet's type and subtype
print("Bullet #1's Type - Subtype :\n", type(oBullet1), " - ",subtype(oBullet1));

--let's make another but with some custom initial values
local oBullet2 = xBullet({damage = 25, caliber = ".30-06"});

--print the second bullet
print("\n\nBullet #2:\n", oBullet2);

--clone oBullet1
local oBullet1Clone = clone(oBullet1);

--print the clone's details
print("\n\nBullet #1 Cloned:\n", oBullet1Clone);

--make some changes to oBullet1
oBullet1.speed = 35;
--print the bullet's caliber and speed
print("\n\nBullet #1 Caliber: ", oBullet1.caliber);
print("\n\nBullet #1's New Speed: ", oBullet1.speed);

--serialize oBullet1 and print it
local zBullet1 = serialize(oBullet1);
print("\n\nBullet #1 Serialized:\n", zBullet1);

--deserialize it (creating a new struct object) and show it's type and details
local oBullet1Deserialized = deserialize(zBullet1);
print("\n\nBullet #1 Deerialized:\n", "type: "..type(oBullet1Deserialized).."\n", oBullet1Deserialized);
```
</details>

---

##### Arrays 🔢
- The **array** object behaves like traditional arrays in as many ways as is possible in **Lua**.
- Are type-safe, meaning only one type may be put into an **array**.
- Have a fixed length.
- Are numerically indexed.
- Have the option to initialize with a numerically-indexed table of values or a number.
- Initializing with a number—e,g., aMyArray = **array**(*nLength*)—all values are set to **null** and the **array** type is set upon the first value assignment.
- Strict bounds checking upon assignment/retrieval.
- Returns **null** value for unassigned values in numerically-instantiated **array**.
- Obligatory methods such as ***sort***, ***clear***, ***copy***, etc.  
- Array cloning is done via the cloner (as shown in the example below).

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

```lua
--initialized with a size, but no type.
local aPet = array(5);

--show some info on the aPet array
print("aPets is an "..type(aPet).." made by the "..type(array)..'.');

--print the value at index 5 (null)
print("aPet[5] -> "..tostring(aPet[5]));

--initialized with a size and type.
local aNoPet = array({"Aligator", "T-Rex", "Rino", "Leech", "Dragon"});

--print the aNoPet array
print("aNoPet (Don't pet these things! Stop it, no pet!) -> ", aNoPet);

--add some items to the aPet array (and set the type with the first assignment)
aPet[1] = "Cat";
aPet[2] = "Frog";
aPet[3] = "Doggo";
aPet[4] = "Lizard";
--aPet[4] = 45; --this will throw an error for trying to set a different type
aPet[5] = "Bunny";

--print the aPet array
print("aPet (It's okay, you can pet these ones.) -> ", aPet);

--access some items by index
print("Don't pet the "..aNoPet[3]..'! But, you can pet the '..aPet[1]..'.');

--iterate over one of the arrays using the built-in iterator
for nIndex, sValue in aNoPet() do
    print("No pet the "..sValue..'!');
end

--show the legth of an array
print("There are "..aPet.length.." animals you can pet.");

--sort and print the arrays
aPet.sort();
aNoPet.sort()

print("\naPet Sorted: -> "..tostring(aPet));
print("aNoPet Sorted: -> "..tostring(aNoPet));

--reverse sort the aNoPet array and print the results
aNoPet.sort(function(a, b) return a > b end)
print("aNoPet Reverse Sorted: -> "..tostring(aNoPet));

print("\n")

--you can create arrays of any single type (including functions)
local aMethods = array(3);
aMethods[1] = function()
    print("You can make an array of functions/methods.");
end
aMethods[2] = function(...)
    local sOutput = "You can referene the aMethods "..type(aMethods)..".\n";
    sOutput = sOutput.."\nThen, you can do whatever else you want even setting the other items."

    if (type(aMethods[3]) == "null") then
        aMethods[3] = function()
            print("Calling aMethods[2] will print this very boring message.");
        end

    end

    print(sOutput);
end

aMethods[1]();
aMethods[2]();
aMethods[3]();

--TODO clone and copy examples
local aCloned = clone(aNoPet);
print(aCloned)
```
</details>

---

##### Notes on Factories 🚧
- All **arrays**, **enums**, **structs** and other such items are made by *factories*. The **array** *factory* is called by ***array()***, **enum** *factory* by ***enum()***, **class** *factory* by ***class()***, etc.
- While some objects are made by *factories*, some things make *factories* (*that, in turn, make objects*). One example of this is **structs**. These are made by *factories* that are made by a *struct factory builder* called with ***structfactory()*** that returns a *struct factory*.

---

## 🆂🅴🆁🅸🅰🅻🅸🆉🅴🆁 ❓➡️ 🔤

The serializer system is designed to work with most native **Lua** types as well as custom objects such as **classes**, **arrays**, etc., and user-created objects.  
The two **Lua** types <u>**not currently**</u> able to be serialized/deserialized are:
- **thread**
- **userdata**

To serialize something, simply call the ***serialize()*** function with the item input (as shown in the example below).  
To deserialize something that was serialized, call the ***deserialize()*** function with the item as input.

These two functions work effortlessly for  native **Lua** types but use with custom objects depends on a contract.  
Any object which is to be serialized must have a ***__serialize*** metamethod.
To deserialize it, a static ***deserialize*** method must exist.

The contract between the ***__serialize*** metamethod and the static ***deserialize*** method is as follows: whatever is returned from ***__serialize*** will be input by the serializer system into the ***deserialize*** method as the first argument exactly as output by ***__serialize***.  

It's the responsibility of the ***__serialize*** metamethod to ensure all custom objects it returns are serialized before returned (user should confirm those custom objects also have a ***__serialize*** metamethod).  

It's the responsibility of the static ***deserialize*** method to return the expected object.

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

```lua

Creature = class("Creature",
{--metamethods
    __serialize = function(this, cdat)
        --local pri = cdat.pri;
        local pro = cdat.pro;

        local tData = {
            ["pro"] = {
                damage  = pro.damage,
                armour  = pro.armour,
                HP      = pro.HP,
                HPMax   = pro.HPMax,
            },
        };

        return tData;
    end,
    __tostring = function(this, cdat)
        local sRet  = "";
        local pro   = cdat.pro;

        sRet = sRet.."Damage: "..pro.damage;
        sRet = sRet.."\nArmour: "..pro.armour;
        sRet = sRet.."\nHP: "..pro.HP;
        sRet = sRet.."\nMax HP: "..pro.HPMax;

        return sRet;
    end,
},
{--public static members
    deserialize = function(tData)
        local oRet = Creature(tData.pro.HP, tData.pro.HPMax);
        oRet.setArmour(tData.pro.armour);
        oRet.setDamage(tData.pro.damage);
        return oRet;
    end,
},
{--private members
    DeathCount = 0,
    Allies = {},
},
{--protected members
    armour_AUTO = 0,
    damage_AUTO = 5,
    HP_AUTO     = 10,
    HPMax_AUTO  = 100,
},
{--public members
    Creature = function(this, cdat, nHP, nHPMax)
        cdat.pro.HP     = nHP < 1 and 1 or nHP;
        cdat.pro.HP     = nHP > nHPMax and nHPMax or nHP;
        cdat.pro.HPMax  = nHPMax;
    end,
    isDead = function(this, cdat)
        return cdat.pro.HP <= 0;
    end,
    kill = function(this, cdat)
        cdat.pro.HP = 0;
    end,
    move = function(this, cdat)

    end,
    getArmour = function(this, cdat)
        return cdat.pro.armour;
    end,
    setArmour = function(this, cdat, nArmour)
        cdat.pro.armour = nArmour;
    end,
    getDamage = function(this, cdat)
        return cdat.pro.damage;
    end,
    setDamage = function(this, cdat, nDamage)
        cdat.pro.damage = nDamage;
    end,
},
NO_PARENT, false, NO_INTERFACES);

--create a creature
local oMonster           = Creature(80, 100);
--print stats
print("Before serialization:\n"..tostring(oMonster));
--serialize the creature
local sMonsterSerialized = serialize(oMonster);
--print the serialized string
print("\n\n"..sMonsterSerialized.."\n");
--deserialize the creature
oMonster        = deserialize(sMonsterSerialized)
--print stats
print("After serialization:\n"..tostring(oMonster));

```
</details>

---

## 🅲🅻🅾🅽🅴🆁 🐝➡️🐝
#### Info coming soon...

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

```lua

```
</details>

---

## 🅳🅾🆇 - 🅳🅾🅲🆄🅼🅴🅽🆃🅰🆃🅸🅾🅽 🆂🆈🆂🆃🅴🅼 📚
#### Info coming soon...

<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

```lua

```
</details>

---

## 🅼🅾🅳🆄🅻🅴🆂 ⚙
Below is the complete list of modules in **LuaEx**.

<details>
<summary>TODO 🛠</summary>

- #### [class](https://centaurisoldier.github.io/LuaEx/api/class.html)
- #### [constant](https://centaurisoldier.github.io/LuaEx/api/constant.html)
- #### [deserialize](https://centaurisoldier.github.io/LuaEx/api/deserialize.html)
- #### [enum](https://centaurisoldier.github.io/LuaEx/api/enum.html)
- #### [math](https://centaurisoldier.github.io/LuaEx/api/math.html)
- #### [serialize](https://centaurisoldier.github.io/LuaEx/api/serialize.html)
- #### [stdlib](https://centaurisoldier.github.io/LuaEx/api/stdlib.html)
- #### [string](https://centaurisoldier.github.io/LuaEx/api/string.html)
- #### [struct](https://centaurisoldier.github.io/LuaEx/api/struct.html)
- #### [table](https://centaurisoldier.github.io/LuaEx/api/table.html)

</details>

---

## 🅲🅻🅰🆂🆂🅴🆂 & 🅸🅽🆃🅴🆁🅵🅰🅲🅴🆂 📔
LuaEx ships with a classes and interfaces which can be found in the documentation section.

---

## 🆁🅴🆂🅾🆄🆁🅲🅴🆂 ⚒
- Logo: https://cooltext.com/
- Special ASCII Fonts: https://fsymbols.com/generators/carty/
- Unicode Characters: https://unicode-table.com/en/sets/symbols-for-instagram/

## 🅲🆁🅴🅳🅸🆃🆂 ⚛
- Huge thanks to [Bas Groothedde](https://github.com/imagine-programming) at Imagine Programming for creating the original **class** module.
