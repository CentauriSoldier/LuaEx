---------🇩‌🇴‌ 🇳‌🇴‌🇹‌ 🇲‌🇴‌🇩‌🇮‌🇫‌🇾‌ 🇹‌🇭‌🇮‌🇸‌ 🇧‌🇱‌🇴‌🇨‌🇰---------
local _nClassSystem         = 1;
local _nBasicClasses        = 2;
local _nComponentClasses    = 3;
local _nGeometryClasses     = 4;
---------🇩‌🇴‌ 🇳‌🇴‌🇹‌ 🇲‌🇴‌🇩‌🇮‌🇫‌🇾‌ 🇹‌🇭‌🇮‌🇸‌ 🇧‌🇱‌🇴‌🇨‌🇰---------






--🆂🆃🅰🆁🆃 🆄🆂🅴🆁 🆅🅰🆁🅸🅰🅱🅻🅴🆂-----------------------------------------------


--[[🅲🅻🅰🆂🆂 🅻🅾🅰🅳 🆅🅰🅻🆄🅴🆂
🅽🅾🆃🅴: setting a Class Load Value
        to true will cause all items
        listed above it to be loaded
        as well.                  ]]
local tClassLoadValues = {
    [_nClassSystem]         = true,  --should LuaEx load the class system?
    [_nBasicClasses]        = true,  --load basic classes (set, queue, stack, dox, etc.)?
    [_nComponentClasses]    = true,  --component class (potentiometer, protean, etc.)?
    [_nGeometryClasses]     = true,  --geometry classes (shape, circle, polygon, etc.)?
};

--🅴🅽🅳 🆄🆂🅴🆁 🆅🅰🆁🅸🅰🅱🅻🅴🆂---------------------------------------------------






--🅼🅾🅳🅸🅵🆈 🆅🅰🅻🆄🅴🆂 🅱🅴🅻🅾🆆 🅰🆃 🆈🅾🆄🆁 🅾🆆🅽 🆁🅸🆂🅺
--for backward compatibility
loadstring = loadstring;

if (type(loadstring) ~= "function" and type(load) == "function") then
    loadstring = load;
end
--TODO I think I need to do this with table.unpack


--enforce the class loading system to prevent errors
for x = #tClassLoadValues, 1, -1 do

    if tClassLoadValues[x] then

        for x2 = 1, x - 1 do
            tClassLoadValues[x2] = true;
        end
        break;

    end

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
                    "array",
};

--create the 'protected' table used by LuaEx
local tLuaEx = {
        __KEYWORDS__	= setmetatable({}, {--TODO uncap these...
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

--TODO execute this without using/modifying the packagepath if possible (loadfile)
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
array           =   require("LuaEx.lib.array");
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

--🅻🅾🅰🅳 🅻🆄🅰🅴🆇 🅲🅾🅽🆂🆃🅰🅽🆃🆂
require("LuaEx.constants");

--🅸🅼🅿🅾🆁🆃 🅾🆃🅷🅴🆁 🅼🅾🅳🆄🅻🅴🆂
--import lua hook modules (except 'typehook' which is loaded first [above])
math 		= require("LuaEx.hook.mathhook");
string		= require("LuaEx.hook.stringhook");
table		= require("LuaEx.hook.tablehook");

--import external libraries
base64 		= require("LuaEx.ext_lib.base64");

--import other modules
serialize 	= require("LuaEx.util.serialize");
deserialize = require("LuaEx.util.deserialize");

--prep for loading the class system (if instructed by the user)
interface, class, iCloneable, iSerializable, iShape = nil;
queue, stack, set = nil;
dox, doxLua, potentiometer, point, line, shape, circle = nil;

--import the class system
if (tClassLoadValues[_nClassSystem]) then
    interface	= require("LuaEx.class.interface");
    class 		= require("LuaEx.class.class");

    --🅸🅼🅿🅾🆁🆃 🅸🅽🆃🅴🆁🅵🅰🅲🅴🆂
    iCloneable 		= require("LuaEx.class.interfaces.iClonable");
    iSerializable 	= require("LuaEx.class.interfaces.iSerializable");
    iShape 	        = require("LuaEx.class.interfaces.iShape");

    --🅸🅼🅿🅾🆁🆃 🅲🅻🅰🆂🆂🅴🆂

    if (tClassLoadValues[_nBasicClasses]) then
        --dependency class
        queue           = require("LuaEx.class.classes.queue");
        stack 	        = require("LuaEx.class.classes.stack");
        set 		    = require("LuaEx.class.classes.set");

        --dox and included language classes
        dox             = require("LuaEx.class.classes.dox");
        doxLua          = require("LuaEx.class.classes.dox.doxLua");

        if (tClassLoadValues[_nComponentClasses]) then
            --component classes
            potentiometer   = require("LuaEx.class.classes.component.potentiometer");

            if (tClassLoadValues[_nGeometryClasses]) then
                --geometry classes
                point           = require("LuaEx.class.classes.geometry.point");
                line            = require("LuaEx.class.classes.geometry.line");
                --shapes
                shape           = require("LuaEx.class.classes.geometry.shapes.shape");
                circle          = require("LuaEx.class.classes.geometry.shapes.circle");
                polygon         = require("LuaEx.class.classes.geometry.shapes.polygon");


                --tClassLoadValues[_nGeometryClasses]
                --dependant classes

            end

        end

    end

end

--🅰🅻🅸🅰🆂🅴🆂
table.serialize 	= serialize.table;
string.serialize 	= serialize.string;

--useful if using LuaEx as a dependency in multiple modules to prevent the need for loading multilple times
constant("LUAEX_INIT", true); --TODO should this be a required check at the beginning of this module?
