--[[*
@authors Centauri Soldier (All code except where noted), Bas Groothedde (class.lua), Alex Kloss (base64.lua)
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
@version 0.5
@versionhistory
<ul>
	<li>
		<b>0.5</b>
		<br>
		<p>Change: classes are no longer automatically added to the global scope when created; rather, they are returned for the calling scipt to handle.</p>
		<p>Change: LuaEx classes and modules are no longer auto-protected and may now be hooked or overwritten. This change does not affect the way constants and enums work in terms of their immutability.</p>
		<p>Bugfix: table.lock was not preserving metatable items (where possible)</p>
		<p>Feature: added protect function (in stdlib).</p>
		<p>Feature: added table.lock function.</p>
		<p>Feature: added table.purge function.</p>
		<p>Feature: added table.settype function.</p>
		<p>Feature: added table.unlock function.</p>
		<p>Feature: added queue class.</p>
		<p>Feature: added stack class.</p>
	</li>
	<li>
		<b>0.4</b>
		<br>
		<p>Bugfix: metavalue causing custom type check to fail to return the proper value.</p>
		<p>Bugfix: typo that caused enum to not be put into the global environment.</p>
		<p>Feature: enums can now also be non-global.</p>
		<p>Feature: the enum created by a call to the enum function are now returned.</p>
	</li>
	<li>
		<b>0.3</b>
		<br>
		<p>Hardened the protected table to prevent accidental tampering.</p>
		<p>Added a meta table to _G in the init module.</p>
		<p>Changed the name of the const module and function to constant for lua 5.1-5.4 compatibility.</p>
		<p>Altered the way constants and enums work by using the new, _G metatable to prevent deletion or overwriting.</p>
		<p>Updated several modules.</p>
	</li>
	<li>
		<b>0.2</b>
		<br>
		<p>Added the enum object.</p>
		<p>Updated a few modules.</p>
	</li>
	<li>
		<b>0.1</b>
		<br>
		<p>Compiled various modules into LuaEx.</p>
	</li>
</ul>
@website https://github.com/CentauriSoldier/LuaEx
*]]

--[[
Defaulted is true, this protects
enum and const values from being
overwritten (except by using
rawget/rawset. of course). Set
this to false to prevent alteration
of the global environment.
]]

--create the 'protected' table used by LuaEx
local tLuaEx = {};

_G.__LUAEX__ = setmetatable({}, {
	__index 	= tLuaEx,
	__newindex 	= function(t, k, v)

		if tLuaEx[k] then
			error("Attempt to overwrite __LUAEX__ value in key '"..tostring(k).."' ("..type(k)..") with value "..tostring(v).." ("..type(v)..") .");
		end

		rawset(tLuaEx, k, v);
	end,
	__metatable = false,
});

--update the package.path
package.path = package.path..";LuaEx\\?.lua";

--warn the user if debug is missing
assert(type(debug) == "table", "LuaEx requires the debug library during initialization. Please enable the debug library before initializing LuaEx."); --TODO find a way to remoev this!

--TODO do i need this part?
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

--import core modules
import("stdlib");
constant 	= import("constant");
enum		= import("enum");

--setup the global environment to properly manage enums, constants and their ilk
setmetatable(_G,
	{--TODO check for existing meta _G table.
		__newindex = function(t, k, v)

			--make sure functions such as constant, enum, etc., constant values and enums values aren't being overwritten
			if _G.__LUAEX__[k] then
				error("Attempt to overwrite protected item '"..tostring(k).."' ("..type(_G.__LUAEX__[k])..") with '"..tostring(v).."' ("..type(v)..").");
			end

			rawset(t, k, v);
		end,
		__metatable = false,
		__index = _G.__LUAEX__,
	}
);

class 		= import("class");
base64 		= import("base64");

--import lua extension modules
			  import("math");
			  import("string");
			  import("table");

--import other modules
serialize 	= import("serialize");
deserialize = import("deserialize");

--import classes
queue 		= import("queue");
stack 		= import("stack");
set 		= import("set");
