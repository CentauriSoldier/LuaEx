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
	<b>0.8</b>
		<br>
		<p>Change: rewrote the class system from scratch.</p>
		<p>Change: moved various modules to different directories.</p>
		<p>Change: renames __LUAEX__ global table luaex.</p>
		<p>Feature: added class interfaces.</p>
		<p>Feature: class system now uses full encapsulation (static protected, static public, private, protected and public fields & methods).</p>
		<p>Feature: luaex table now contains a _VERSION variable.</p>
	</li>
	<li>
		<b>0.7</b>
		<br>
		<p>Change: the rawtype function will now return LuaEx's type names for classes, constants, enums, structs, struct factories (and struct_factory_constructor) and null (and NULL) as oppossed to returning, "table".</p>
		<p>Feature: added null type.</p>
		<p>Feature: added the factory module.</p>
		<p>Feature: added the luatype function (an alias for Lua's original, type, function.)</p>
		<p>Feature: added the fulltype function.</p>
	</li>
	<li>
		<b>0.6</b>
		<br>
		<p>Bugfix: set and stack classes were not modifying values properly.</p>
		<p>Feature: added infusedhelp module.</p>
	</li>
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

--for backward compatibility
loadstring = loadstring;

if (type(loadstring) ~= "function" and type(load) == "function") then
	loadstring = load;
end

--[[
Defaulted is true, this protects
enum and const values from being
overwritten (except by using
rawget/rawset. of course). Set
this to false to prevent alteration
of the global environment.
]]

--							🆂🅴🆃🆄🅿 🅻🆄🅰🅴🆇 🅿🅰🆃🅷 & 🅼🅴🆃🅰🆃🅰🅱🅻🅴

--list all keywords
local tKeyWords = {	"and", 		"break", 	"do", 		"else", 	"elseif", 	"end",
					"false", 	"for", 		"function", "if", 		"in", 		"local",
					"nil", 		"not", 		"or", 		"repeat", 	"return", 	"then",
					"true", 	"until", 	"while",
					--LuaEx keywords
					"constant", 	"enum", 	"struct",	"null",	"class",	"interface",
};

--create the 'protected' table used by LuaEx
local tLuaEx = {
		__KEYWORDS__	= setmetatable({}, {
			__index 	= tKeyWords,
			__newindex 	= function(t, k)
				error("Attempt to perform illegal operation: adding keyword to __KEYWORDS__ table.");
			end,
			__pairs		= function (t)
				return next, tKeyWords, nil;
			end,
			__metatable = false,
		}),
		__KEYWORDS_COUNT__ = #tKeyWords,
		_VERSION = "LuaEx 0.8",
};

_G.luaex = setmetatable({},
{
	__index 		= tLuaEx,--TODO should I use a shadow table?
	__newindex 		= function(t, k, v)

		if tLuaEx[k] then
			error("Attempt to overwrite luaex value in key '"..tostring(k).."' ("..type(k)..") with value "..tostring(v).." ("..type(v)..") .");
		end

		rawset(tLuaEx, k, v);
	end,
	__metatable 	= false,
});

--warn the user if debug is missing
assert(type(debug) == "table", "LuaEx requires the debug library during initialization. Please enable the debug library before initializing LuaEx.");


--determine the call location
local sPath = debug.getinfo(1, "S").source;
--remove the calling filename
sPath = sPath:gsub("@", ""):gsub("[Ii][Nn][Ii][Tt].[Ll][Uu][Aa]", "");
--remove the "/" at the end
sPath = sPath:sub(1, sPath:len() - 1);
--update the package.path (use the main directory to prevent namespace issues)
package.path = package.path..";"..sPath.."\\..\\?.lua";


--🅸🅼🅿🅾🆁🆃 🅿🆁🅴🆁🅴🆀🆄🅸🆂🅸🆃🅴 🅼🅾🅳🆄🅻🅴🆂
type 			=  	require("LuaEx.hook.typehook");
					require("LuaEx.lib.stdlib");
constant 		= 	require("LuaEx.lib.constant");
clausum			=	require("LuaEx.lib.clausum");
local null		= 	require("LuaEx.lib.null");
					rawset(tLuaEx, "null", null); 	-- make sure null can't be overwritten
					rawset(tLuaEx, "NULL", null);	-- create an uppercase alias for null
enum			= 	require("LuaEx.lib.enum");
struct			= 	require("LuaEx.lib.struct");
source			=	require("LuaEx.util.source");
infusedhelp		= 	require("LuaEx.lib.infusedhelp");
--run the 'directives'
--directive	=	require("LuaEx.lib.directive"); TODO finish directives for enums (and classes?)

--🅼🅾🅳🅸🅵🆈 🆃🅷🅴 🅶🅻🅾🅱🅰🅻 🅼🅴🆃🅰🆃🅰🅱🅻🅴
--setup the global environment to properly manage enums, constants and their ilk
local tGMeta = getmetatable(_G) or {};
tGMeta.__newindex = function(t, k, v)

	--make sure functions such as constant, enum, etc., constant values and enums values aren't being overwritten
	if _G.luaex[k] then
		error("Attempt to overwrite protected item '"..tostring(k).."' ("..type(_G.luaex[k])..") with '"..tostring(v).."' ("..type(v)..").");
	end

	rawset(t, k, v);
end
--__metatable = false, TODO should this be set to false again?
tGMeta.__index = _G.luaex,
setmetatable(_G, tGMeta);

--🅸🅼🅿🅾🆁🆃 🅾🆃🅷🅴🆁 🅼🅾🅳🆄🅻🅴🆂
--import lua hook modules (except 'typehook' which is loaded first [above])
math 		= require("LuaEx.hook.mathhook");
string		= require("LuaEx.hook.stringhook");
table		= require("LuaEx.hook.tablehook");

--import the class system
interface	= require("LuaEx.class.interface");
class 		= require("LuaEx.class.class");

--import external libraries
base64 		= require("LuaEx.ext_lib.base64");

--import other modules
serialize 	= require("LuaEx.util.serialize");
deserialize = require("LuaEx.util.deserialize");

--import interfaces
icloneable 		= require("LuaEx.class.interfaces.iclonable");
iserializable 	= require("LuaEx.class.interfaces.iserializable");
-- = require("LuaEx.class.interfaces.");

--import classes
queue 		= require("LuaEx.class.classes.queue");
stack 		= require("LuaEx.class.classes.stack");
set 		= require("LuaEx.class.classes.set");
--ini 		= require("LuaEx.class.classes.ini"); --TODO convert to new class system

--🅰🅻🅸🅰🆂🅴🆂
table.serialize 	= serialize.table;
string.serialize 	= serialize.string;

--useful if using LuaEx as a dependency in multiple modules to prevent the need for loading multilple times
constant("LUAEX_INIT", true);
