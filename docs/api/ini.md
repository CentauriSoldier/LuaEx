## 🇮​​​​​🇳​​​​​🇮​​​​​

A basic ini data handler originally written by Carreras Nicolas (https://github.com/Sledmine/lua-ini) which has been modified and adapted to LuaEx.

The ini module takes advantage of the class system allowing for ini objects to be created and operated on using OOP methods.

### Class Methods
- **ini(*string or nil*, *boolean or nil*, *boolean or nil*)** Creates a new ini object. Argument 1 is the filename where the ini may (optionally) be stored. Argument 2 is whether the ini should be autoloaded from the specified file during instantiation. Argument 3 is whether the ini should be autosaved when any changes are made to the object (*ini*).
- **__tostring** Returns a serialized table of the ini object's data.
- **deleteall** Clears all data from the ini object (*nil*).
- **deletesection(*string*)**


### Static Functions
The client may use these functions to operate on data free of using the class system. These are provided for convenience when not using the class system but are not needed when using the class system.

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

[https://mit-license.org/](https://mit-license.org/)

</details>

### [◀ Back](https://centaurisoldier.github.io/LuaEx/)