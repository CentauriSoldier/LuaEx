![LuaEx](https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png)


## 🆆🅷🅰🆃 🅸🆂 🅻🆄🅰🅴🆇❓ 🔬
Simply put, **LuaEx** is a collection of scripts that extend Lua's functionality.

## 🅳🅴🆅🅴🅻🅾🅿🅼🅴🅽🆃 🅶🅾🅰🅻🆂 ⌨

#### Why Write LuaEx?
**LuaEx** attempts to implement code solutions for common and frequent problems. I found myself rewriting code over and again or copying old blocks of code from other projects into new projects and finally decided it would be better to compile that code into one single, easy-to-use module.

#### Big Things Come in Small Package
Keeping this module small is essential to making it useful. You shouldn't have to spend a year learning how to use something designed to be easy to use; **LuaEx** is developed with that in mind.

##### Simplicity
Retaining simplicity of the code is also a primary goal of this module. The code should be intuitive and I strive toward that end.

#### Conventional Consistency
This project is made to be consistent both with Lua's naming & coding conventions as well as internally.

#### Principle of Least Astonishment
In developing **LuaEx**, I strive to take full advantage of the flexibility of the Lua language while still adhering to the [Principle of Least Astonishment](https://en.wikipedia.org/wiki/Principle_of_least_astonishment).

The only *limited* exceptions made are for new features (*whose developments are generally permitted exclusively by Lua*) not otherwise found in other OOP languages.

## 🆁🅴🆂🅾🆄🆁🅲🅴🆂 ⚒
- Logo: https://cooltext.com/
- Special ASCII Fonts: https://fsymbols.com/generators/carty/
- Unicode Characters: https://unicode-table.com/en/sets/symbols-for-instagram/

## 🆅🅴🆁🆂🅸🅾🅽 ⚗

#### Alpha v0.81
<details>
<summary>View Changelog</summary>

### 🇨​​​​​🇭​​​​​🇦​​​​​🇳​​​​​🇬​​​​​🇪​​​​​🇱​​​​​🇴​​​🇬​​​​​
**v0.81**
- Bugfix: renamed the **\_\_LUAEX\_\_** table reference in the **enum** module that got missed.
- Change: removed class system from **v0.8** as it had a fatal, uncorrectable flaw.
- Change: rewrote the class system again from scratch, avoiding fatal flaw in previous system.
- Change: removed static protected members from the class system as using them is, almost always, an anti-pattern.
- Change: class members are now strongly typed.
- Change: ***temporarily*** disabled compulsory classes until they're refactored for new class system.
- Change: ***temporarily*** removed class interfaces until it's rewritten to operate with the new class system.
- Change: removed most of the non-basic classes to another repository in an ongoing effort to keep **LuaEx** simple and small.
- Change: cleaned up and reorganized a lot of the files in the **LuaEx** module.

**v0.80**
- Change: rewrote the class system from scratch.
- Change: moved various modules to different directories.
- Change: renamed **\_\_LUAEX\_\_** global table **luaex**.
- Feature: added class interfaces.
- Feature: class system now uses full encapsulation (static protected, static public, private, protected and public fields & methods).
- Feature: **luaex** table now contains a **\_VERSION** variable.

**v0.70**
- Change: enum items now use functions (.) instead of methods (:) and automatically input themselves as arguments.
- Change: enum items' ***next*** and ***previous*** functions can now wrap around to the start and end respectively.
- Change: moved all type items to **types.lua**.
- Change: renamed functions in various modules to conform with Lua's lowercase naming convention.
- Change:
- Change: improved the **string.totable** function.
- Change: the ***xtype*** function will now ignore user-defined types but return **LuaEx**'s type names for **classes**, **constants**, **enums**, structs, **struct factories** (and **struct_factory_constructor**) and **null** (and **NULL**) as opposed to returning, *"table"*. *Use the **rawtype** function to ignore all **LuaEx** type mechanics*.
- Change: renamed the ***string.delimitedtotable*** function to ***string.totable***.
- Bugfix: corrected several minor bugs in enum library.
- Bugfix: corrected assertions in stack class.
- Bugfix: ***set.addset*** was not adding items.
- Feature: added several type functions and metamethods to various default types (e.g., boolean, string, number, etc.).
- Feature: added serialization to enums.
- Feature: added the **ini** module.
- Feature: added ***string.isnumeric*** function.
- Feature: added a ***\_\_mod*** metamethod for string which allows for easy interpolation.
- Feature: added null type.
- Feature: added the **struct** factory module.
- Feature: added the ***xtype*** function.
- Feature: added the ***fulltype*** function.

**v0.60**
- Feature: removed ***string.left*** as it was an unnecessary and inefficient wrapper of ***string.sub***.
- Feature: removed ***string.right*** as it was an unnecessary and inefficient wrapper of ***string.sub***.
- Feature: added ***string.trim*** function.
- Feature: added ***string.trimleft*** function.
- Feature: added ***string.trimright*** function.
- Bugfix: corrected package.path code in init.lua and removed ***import*** function.
- Refactor: moved modules into appropriate subdirectories and updated init.lua to find them.
- Refactor: appended ***string***, ***math*** & ***table*** module files with "hook" without which they would not load properly.
- Update: updated README with more information.

**v0.50**
- Bugfix: ***table.lock*** was altering the metatable of enums when it should not have been.
- Bugfix: ***table.lock*** was not preserving metatable items (where possible).
- Change: classes are no longer automatically added to the global scope when created; rather, they are returned	for the calling script to handle.
- Change: **LuaEx** classes and modules are no longer auto-protected and may now be hooked or overwritten. This change does not affect the way constants and enums work in terms of their immutability.
- Change: **enums** values may now be of any non-nil type(previously only **string** and **number** were allowed).
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
- Bugfix: metavalue causing custom type check to fail to return the proper value.
- Bugfix: typo that caused global enums to not be put into the global environment.
- Feature: enums can now also be non-global.
- Feature: the enum created by a call to the enum function is now returned.

**v0.30**
- Hardened the protected table to prevent accidental tampering.
- Added a meta table to ***\_G*** in the **init** module.
- Changed the name of the const module and function to constant for Lua 5.1 - 5.4 compatibility.
- Altered the way constants and enums work by using the new, ***\_G*** metatable to prevent deletion or overwriting.
- Updated several modules.

**v0.20**
- Added the enum object.
- Updated a few modules.

**v0.10**
- Compiled various modules into **LuaEx**.
</details>

## 🅻🅸🅲🅴🅽🆂🅴 ©

All code is placed in the public domain under [The Unlicense](https://opensource.org/licenses/unlicense "The Unlicense") *(except where otherwise noted)*.

<details>
<summary>Full Text</summary>
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

## 🅶🅴🆃🆃🅸🅽🅶 🆂🆃🅰🆁🆃🅴🅳 🚀
In order to push all the code in **LuaEx** into the global environment, place the **LuaEx** folder into your package path and run the following code:
```lua
require("LuaEx.init");
```
From here on out, all modules of **LuaEx** will be available in the global environment.

## 🅳🅾🅲🆄🅼🅴🅽🆃🅰🆃🅸🅾🅽 🗎

All documentation for **LuaEx** is on ***GitHub Pages*** found here:
### [https://centaurisoldier.github.io/LuaEx](https://centaurisoldier.github.io/LuaEx)

## 🅼🅾🅳🆄🅻🅴🆂 ⚙
Below is the complete list of modules in **LuaEx**.

- #### [base64](https://centaurisoldier.github.io/LuaEx/api/base64.html)
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

## 🅲🅻🅰🆂🆂🅴🆂 & 🅸🅽🆃🅴🆁🅵🅰🅲🅴🆂 ♾️
LuaEx does ship with a few, basic classes and interfaces. (*More classes are available at [this repository](https://github.com/CentauriSoldier/LuaEx_Class_Modules))*.
### Classes
- ##### queue
- ##### set
- ##### stack
### Interfaces
- ##### iclonable
- ##### iserializable

## 🅲🆁🅴🅳🅸🆃🆂 ⚛
- Huge thanks to [Bas Groothedde](https://github.com/imagine-programming) at Imagine Programming for creating the original **class** module.
- Thanks to Alex Kloss (alexthkloss@web.de) for creating the **base64** module.
- Thanks to [Carreras Nicolas](https://github.com/Sledmine/lua-ini) for creating the original **ini** module.
