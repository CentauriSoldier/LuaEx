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
		_VERSION = "LuaEx 0.81",
};

_G.luaex = setmetatable({},
{
	__index 		= tLuaEx,
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
                    require("LuaEx.hook.metahook");
					require("LuaEx.lib.stdlib");
constant 		= 	require("LuaEx.lib.constant");
clausum			=	require("LuaEx.lib.clausum");--TODO what is the purpose of this? Does it have any practical use?
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
--base64 		= require("LuaEx.ext_lib.base64");

--import other modules
serialize 	= require("LuaEx.util.serialize");
deserialize = require("LuaEx.util.deserialize");

--import interfaces
--icloneable 		= require("LuaEx.class.interfaces.iclonable");
--iserializable 	= require("LuaEx.class.interfaces.iserializable");

--import classes
queue 	    = require("LuaEx.class.classes.queue");
stack 	    = require("LuaEx.class.classes.stack");
set 		= require("LuaEx.class.classes.set");


--🅰🅻🅸🅰🆂🅴🆂
table.serialize 	= serialize.table;
string.serialize 	= serialize.string;

--useful if using LuaEx as a dependency in multiple modules to prevent the need for loading multilple times
constant("LUAEX_INIT", true); --TODO should this be a required check at the beginning of this module?
