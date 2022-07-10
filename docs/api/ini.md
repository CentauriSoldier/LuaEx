---
layout: default
---
## 🇮​​​​​🇳​​​​​🇮​​​​​

A basic ini data handler originally written by Carreras Nicolas (https://github.com/Sledmine/lua-ini) which has been modified and adapted to LuaEx.

The ini module takes advantage of the class system allowing for ini objects to be created and operated on using OOP methods.

### Class Methods
***

#### __tostring
Creates a serialized table of the ini object's data.

##### Return

| Type(s) | Description |
|-------|--------|
| string | A serialized table of the ini data. |

- **deleteall** Clears all data from the ini object (*nil*).
- **deletesection(*string*)**

***

### Static Functions
The client may use these functions to operate on data free of using the class system. These are provided for convenience when not using the class system but are not needed when using the class system.

<h1><center>ini</center></h1>
<center><h5>The class constructor which creates a new ini object.</h5></center>

##### Parameters

| Name | Type(s) | Description |
|-------|--------|---------|
| filepath | string or nil | The path to the ini file. If there is not need to load/save from file, this can be set to nil. |
| autoload | boolean or nil | Sets whether the ini should be autoloaded from the specified file during instantiation of the ini object. |
| autosave | boolean or nil | Sets whether the ini should be autosaved when any changes are made to the object. |

##### Return

| Type(s) | Description |
|-------|--------|
| ini object | The ini object upon which class methods can be called |

##### Example
``` lua
	local oMyINI = ini("./myfile.ini", true, true);
	print(type(oMyINI)); --prints "ini"
```

- **ini.decode(*string*)** Decodes ini data (*in string format*) and returns the data in table format (*table*).
- **ini.encode(*table*)** Encodes ini data (*in table format*) to a string (*string*).
- **ini.load(*string*)** Same as ***ini.decode*** except it takes a filepath string; loads the file and decodes the string data to a table (*table*).
- **ini.save(*string*, *table*)** Same as ***ini.decode*** except also saves the string data to the file specified by the filepath string (*nil*).

<details>
<summary>License</summary>
The MIT License (MIT)

Copyright © 2022 <copyright holders>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#### [https://mit-license.org/](https://mit-license.org/)

</details>


### [◀ Back] (https://centaurisoldier.github.io/LuaEx/)
