---------🇩‌🇴‌ 🇳‌🇴‌🇹‌ 🇲‌🇴‌🇩‌🇮‌🇫‌🇾‌ 🇹‌🇭‌🇮‌🇸‌ 🇧‌🇱‌🇴‌🇨‌🇰---------
local _nClassSystem         = 1;
local _nBasicClasses        = 2;
local _nComponentClasses    = 3;
local _nGeometryClasses     = 5;
local _nUtilClasses         = 4;

local _tClassRequirements   = {
    [_nClassSystem]       = {},
    [_nBasicClasses]      = {_nClassSystem},
    [_nComponentClasses]  = {_nClassSystem, _nBasicClasses},
    [_nGeometryClasses]   = {_nClassSystem, _nBasicClasses, _nComponentClasses},
    [_nUtilClasses]       = {_nClassSystem, _nBasicClasses, _nComponentClasses},
};
---------🇩‌🇴‌ 🇳‌🇴‌🇹‌ 🇲‌🇴‌🇩‌🇮‌🇫‌🇾‌ 🇹‌🇭‌🇮‌🇸‌ 🇧‌🇱‌🇴‌🇨‌🇰---------






--🆂🆃🅰🆁🆃 🆄🆂🅴🆁 🆅🅰🆁🅸🅰🅱🅻🅴🆂-----------------------------------------------


--[[🅲🅻🅰🆂🆂 🅻🅾🅰🅳 🆅🅰🅻🆄🅴🆂
🅽🅾🆃🅴: setting a Class Load Value
        to true will cause its required
        _tClassRequirements to be loaded
        as well.]]
local tClassLoadValues = {
    [_nClassSystem]         = true,  --should LuaEx load the class system?
    [_nBasicClasses]        = true,  --load basic classes (set, queue, stack, dox, etc.)?
    [_nComponentClasses]    = true,  --component class (potentiometer, protean, etc.)?
    [_nGeometryClasses]     = true,  --geometry classes (shape, circle, polygon, etc.)?
    [_nUtilClasses]         = true,  --other things like Dox, Ini, etc.
};


--🅴🅽🅳 🆄🆂🅴🆁 🆅🅰🆁🅸🅰🅱🅻🅴🆂---------------------------------------------------

--[[!
@fqxn LuaEx
@desc Put info about LuaEx here...
!]]

--🅼🅾🅳🅸🅵🆈 🆅🅰🅻🆄🅴🆂 🅱🅴🅻🅾🆆 🅰🆃 🆈🅾🆄🆁 🅾🆆🅽 🆁🅸🆂🅺
--for backward compatibility
--loadstring = loadstring;
--load = load or loadstring;

--if (type(loadstring) ~= "function" and type(load) == "function") then
--    loadstring = load;
--end


--TODO I think I need to do this with table.unpack


--enforce the class loading system to prevent errors
--for x = #tClassLoadValues, 1, -1 do
for x = 1, #tClassLoadValues do

    if tClassLoadValues[x] then

        for _, nRequirementIndex in ipairs(_tClassRequirements[x]) do
            tClassLoadValues[nRequirementIndex] = true;
        --for x2 = 1, x - 1 do
        --    tClassLoadValues[x2] = true;
        --end
        --break;
        end

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
                    --LuaEx keywords/types
                    "constant", 	"enum", "enumfactory",	"struct",	"null",	"class",	"interface",
                    "array", "arrayfactory", "classfactory", "structfactory", "structfactorybuilder"
};

--create the 'protected' table used by LuaEx
local tLuaEx = {
        __metaguard  = {"class", "classfactory", "enum", "enumfactory", "struct", "structfactory"}, --these metatables are protected from modification and general access
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
        --_SOURCE_PATH = getsourcepath(),
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


cloner, clone = nil; --delcared here so all lower modules can use it
--QUESTION do i need serializer here too? I think not but double check

--🅸🅼🅿🅾🆁🆃 🅿🆁🅴🆁🅴🆀🆄🅸🆂🅸🆃🅴 🅼🅾🅳🆄🅻🅴🆂
type 			        =  	require("LuaEx.hook.typehook");
                            require("LuaEx.hook.metahook");
                            require("LuaEx.lib.stdlib");
constant 		        = 	require("LuaEx.lib.constant");
--clausum			    =	require("LuaEx.lib.clausum");--TODO what is the purpose of this? Does it have any practical use?
local null		        = 	require("LuaEx.lib.null");
                            rawset(tLuaEx, "null", null); 	-- make sure null can't be overwritten
                            rawset(tLuaEx, "NULL", null);	-- create an uppercase alias for null
array                   =   require("LuaEx.lib.array");
enum			        = 	require("LuaEx.lib.enum");
local tStruct           = 	require("LuaEx.lib.struct");
struct                  =   tStruct.struct;
structfactory           =   tStruct.structfactory;
--sorteddictionary        =   require("LuaEx.lib.sorteddictionary");
source			        =	require("LuaEx.util.source");
infusedhelp		        = 	require("LuaEx.lib.infusedhelp");
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
io   		= require("LuaEx.hook.iohook");
math 		= require("LuaEx.hook.mathhook");
string		= require("LuaEx.hook.stringhook");
table		= require("LuaEx.hook.tablehook");
base64 		= require("LuaEx.lib.base64");

--import external libraries


--import serialization
serializer  = require("LuaEx.util.serializer");

--import cloner
cloner      = require("LuaEx.util.cloner");
clone       = cloner.clone;

--🆁🅴🅶🅸🆂🆃🅴🆁 🅻🆄🅰🅴🆇 🅵🅰🅲🆃🅾🆁🅸🅴🆂 🆆🅸🆃🅷 🆃🅷🅴 🅲🅻🅾🅽🅴🆁
cloner.registerFactory(array);
cloner.registerFactory(enum);
cloner.registerFactory(struct);
cloner.registerFactory(structfactory);
--cloner.registerFactory();

--aliases
serialize   = serializer.serialize;
deserialize = serializer.deserialize;

--prep for loading the class system (if instructed by the user)

--class, interface, iCloneable, iSerializable, iShape = nil;
--Queue, Stack, Ssset = nil;
--dox, doxLua, potentiometer, point, line, shape, circle = nil;

--import the class system
if (tClassLoadValues[_nClassSystem]) then
    interface	= require("LuaEx.lib.interface");
    class 		= require("LuaEx.lib.class");
    --🆁🅴🅶🅸🆂🆃🅴🆁 🆃🅷🅴 🅲🅻🅰🆂🆂 🅵🅰🅲🆃🅾🆁🆈 🆆🅸🆃🅷 🆃🅷🅴 🅲🅻🅾🅽🅴🆁
    cloner.registerFactory(class);

    --🅸🅼🅿🅾🆁🆃 🅸🅽🆃🅴🆁🅵🅰🅲🅴🆂
    iCloneable 		= require("LuaEx.inc.interfaces.iCloneable");
    iSerializable 	= require("LuaEx.inc..interfaces.iSerializable");
    iShape 	        = require("LuaEx.inc..interfaces.iShape");

    --🅸🅼🅿🅾🆁🆃 🅲🅻🅰🆂🆂🅴🆂

    if (tClassLoadValues[_nBasicClasses]) then
        --dependency class
        Queue               = require("LuaEx.inc.classes.Queue");
        Stack               = require("LuaEx.inc.classes.Stack");
        Set                 = require("LuaEx.inc.classes.Set");
        SortedDictionary    = require("LuaEx.inc.classes.SortedDictionary");

        if (tClassLoadValues[_nComponentClasses]) then
            --component classes
            Potentiometer = require("LuaEx.inc.classes.component.Potentiometer");


            if (tClassLoadValues[_nGeometryClasses]) then
                --geometry classes
                Point   = require("LuaEx.inc.classes.geometry.Point");
                Line    = require("LuaEx.inc.classes.geometry.Line");
                --shapes
                Shape   = require("LuaEx.inc.classes.geometry.shapes.Shape");
                Circle  = require("LuaEx.inc.classes.geometry.shapes.Circle");
                Polygon = require("LuaEx.inc.classes.geometry.shapes.Polygon");
            end

            if (tClassLoadValues[_nUtilClasses]) then
                --dox and included support classes
                DoxMime     = require("LuaEx.inc.classes.util.Dox.DoxMime");
                DoxSyntax   = require("LuaEx.inc.classes.util.Dox.DoxSyntax");
                DoxBlockTag = require("LuaEx.inc.classes.util.Dox.DoxBlockTag");
                DoxBlock    = require("LuaEx.inc.classes.util.Dox.DoxBlock");
                Dox         = require("LuaEx.inc.classes.util.Dox.Dox");

                --require Dox Parsers
                DoxAssemblyNASM         = require("LuaEx.inc.classes.util.Dox.Parsers.DoxAssemblyNASM")
                DoxAutoPlayMediaStudio  = require("LuaEx.inc.classes.util.Dox.Parsers.DoxAutoPlayMediaStudio");
                DoxC                    = require("LuaEx.inc.classes.util.Dox.Parsers.DoxC")
                DoxCSharp               = require("LuaEx.inc.classes.util.Dox.Parsers.DoxCSharp")
                DoxCPlusPlus            = require("LuaEx.inc.classes.util.Dox.Parsers.DoxCPlusPlus")
                DoxCSS                  = require("LuaEx.inc.classes.util.Dox.Parsers.DoxCSS")
                DoxDart                 = require("LuaEx.inc.classes.util.Dox.Parsers.DoxDart")
                DoxElm                  = require("LuaEx.inc.classes.util.Dox.Parsers.DoxElm")
                DoxFSharp               = require("LuaEx.inc.classes.util.Dox.Parsers.DoxFSharp")
                DoxFortran              = require("LuaEx.inc.classes.util.Dox.Parsers.DoxFortran")
                DoxGo                   = require("LuaEx.inc.classes.util.Dox.Parsers.DoxGo")
                DoxGroovy               = require("LuaEx.inc.classes.util.Dox.Parsers.DoxGroovy")
                DoxHaskell              = require("LuaEx.inc.classes.util.Dox.Parsers.DoxHaskell")
                DoxHTML                 = require("LuaEx.inc.classes.util.Dox.Parsers.DoxHTML")
                DoxJava                 = require("LuaEx.inc.classes.util.Dox.Parsers.DoxJava")
                DoxJavaScript           = require("LuaEx.inc.classes.util.Dox.Parsers.DoxJavaScript")
                DoxJulia                = require("LuaEx.inc.classes.util.Dox.Parsers.DoxJulia")
                DoxKotlin               = require("LuaEx.inc.classes.util.Dox.Parsers.DoxKotlin")
                DoxLua                  = require("LuaEx.inc.classes.util.Dox.Parsers.DoxLua");
                DoxMatlab               = require("LuaEx.inc.classes.util.Dox.Parsers.DoxMatlab")
                DoxObjectiveC           = require("LuaEx.inc.classes.util.Dox.Parsers.DoxObjectiveC")
                DoxPerl                 = require("LuaEx.inc.classes.util.Dox.Parsers.DoxPerl")
                DoxPHP                  = require("LuaEx.inc.classes.util.Dox.Parsers.DoxPHP")
                DoxPython               = require("LuaEx.inc.classes.util.Dox.Parsers.DoxPython")
                DoxRuby                 = require("LuaEx.inc.classes.util.Dox.Parsers.DoxRuby")
                DoxRust                 = require("LuaEx.inc.classes.util.Dox.Parsers.DoxRust")
                DoxScala                = require("LuaEx.inc.classes.util.Dox.Parsers.DoxScala")
                DoxSwift                = require("LuaEx.inc.classes.util.Dox.Parsers.DoxSwift")
                DoxTypeScript           = require("LuaEx.inc.classes.util.Dox.Parsers.DoxTypeScript")
                DoxXML                  = require("LuaEx.inc.classes.util.Dox.Parsers.DoxXML")

                --ini
                Ini    = require("LuaEx.inc.classes.util.Ini"); --TODO need to finish OrderedSet first
            end

        end

    end

end


--🅰🅻🅸🅰🆂🅴🆂
unpack = unpack or table.unpack;--TODO move this to table hook
--table.serialize 	= serialize.table;
--string.serialize 	= serialize.string;
--[[
![LuaEx](https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png)

]]
--useful if using LuaEx as a dependency in multiple modules to prevent the need for loading multilple times
constant("LUAEX_INIT", true); --TODO should this be a required check at the beginning of this module?
