--[[*
@authors Centauri Soldier, Bas Groothedde
@copyright Public Domain
@description
	<h2>LuaEx</h2>
	<h3>A collection of code that extends Lua's functionality.</h3>
@email
@features
	<h3>Extends the Lua Libraires</h3>
	<p>Adds several useful function into the main lua libraries such as string, math, etc..</p>
	<h3>No Dependencies</h3>
@license <p>The Unlicense<br>
<br>Copyright Public Domain<br>
<br>
This is free and unencumbered software released into the public domain.
<br><br>
Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
<br><br>
In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.
<br><br>
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
<br><br>
For more information, please refer to <http://unlicense.org/>
</p>
@plannedfeatures
<ul>
	<li>Lua 5.4 features while remaining backward compatible with Lua 5.1</li>
</ul>
@moduleid LuaEx|LuaEx
@todo
@usage
	<h2>Coming Soon</h2>
@version 0.1
@versionhistory
<ul>
	<li>
		<b>0.1</b>
		<br>
		<p>Compiled various modules into LuaEx.</p>
	</li>
</ul>
@website https://github.com/CentauriSoldier/LuaEx
*]]

--warn the user if debug is missing
assert(type(debug) == "table", "LuaEx requires the debug library during initialization. Please enable the debug library before initializing LuaEx.");

--determine the call location
local sPath = debug.getinfo(1, "S").source;
--remove the calling filename
sPath = sPath:gsub("@", ""):gsub("init.lua", "");
--remove the "/" at the end
sPath = sPath:sub(1, sPath:len() - 1);
--format the path to be suitable for the 'require()' function
sPath = sPath:gsub("\\", "."):gsub("/", ".");

local function import(sFile)
	return require(sPath..'.'..sFile);
end

--core modules
const 				= import("const");
class, interface 	= import("class");
base64				= import("base64");

--lua extension modules
import("math");
import("string");
import("table");

--other modules
serialize 			= import("serialize");
deserialize 		= import("deserialize");

--useful if using LuaEx as a dependency in multiple modules to prevent the need for loading multilple times
LUAEX_INIT = true;
