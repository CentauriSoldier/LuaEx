---------🇩‌🇴‌ 🇳‌🇴‌🇹‌ 🇲‌🇴‌🇩‌🇮‌🇫‌🇾‌ 🇹‌🇭‌🇮‌🇸‌ 🇧‌🇱‌🇴‌🇨‌🇰---------
local _nClassSystem         = 1;
local _nBasicClasses        = 2;
local _nComponentClasses    = 3;
local _nGeometryClasses     = 5;
local _nUtilClasses         = 4;
local _nCoGClasses          = 6;

local _tClassRequirements   = {
    [_nClassSystem]       = {},
    [_nBasicClasses]      = {_nClassSystem},
    [_nComponentClasses]  = {_nClassSystem, _nBasicClasses},
    [_nGeometryClasses]   = {_nClassSystem, _nBasicClasses, _nComponentClasses},
    [_nUtilClasses]       = {_nClassSystem, _nBasicClasses, _nComponentClasses},
    [_nCoGClasses]        = {_nClassSystem, _nBasicClasses, _nComponentClasses, _nGeometryClasses},
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
    [_nCoGClasses]          = true,  --(Code of Gaming) game system classes
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
--blueprint               =   require("LuaEx.lib.blueprint");
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
    iSerializable 	= require("LuaEx.inc.interfaces.iSerializable");
    iShape 	        = require("LuaEx.inc.interfaces.iShape");

    --🅸🅼🅿🅾🆁🆃 🅲🅻🅰🆂🆂🅴🆂

    if (tClassLoadValues[_nBasicClasses]) then
        local pClasses = "LuaEx.inc.classes";

        --dependency class
        Queue               = require(pClasses..".Queue");
        Stack               = require(pClasses..".Stack");
        Set                 = require(pClasses..".Set");
        SortedDictionary    = require(pClasses..".SortedDictionary");

        if (tClassLoadValues[_nComponentClasses]) then
            --component classes
            Potentiometer   = require(pClasses..".component.Potentiometer");
            Protean         = require(pClasses..".component.Protean");

            if (tClassLoadValues[_nGeometryClasses]) then
                --geometry classes
                Point   = require(pClasses..".geometry.Point");
                Line    = require(pClasses..".geometry.Line");
                --shapes
                Shape   = require(pClasses..".geometry.shapes.Shape");
                Circle  = require(pClasses..".geometry.shapes.Circle");
                Polygon = require(pClasses..".geometry.shapes.Polygon");

                if (tClassLoadValues[_nCoGClasses]) then
                    Pool = require(pClasses..".cog.Pool");
                end

            end

            if (tClassLoadValues[_nUtilClasses]) then
                pDox                    = pClasses..".util.Dox";
                local pDoxBuilders  = pDox..".Builders";
                local pDoxComponents    = pDox..".Components";
                local pDoxParsers       = pDox..".Parsers";

                --dox and dox component classes
                DoxMime         = require(pDoxComponents..".DoxMime"); --TODO rename to Parser
                DoxSyntax       = require(pDoxComponents..".DoxSyntax");
                DoxBlockTag     = require(pDoxComponents..".DoxBlockTag");
                DoxBlock        = require(pDoxComponents..".DoxBlock");
                DoxBuilder      = require(pDoxComponents..".DoxBuilder");

                --require Dox Builders
                DoxBuilderHTML  = require(pDoxBuilders..".HTML.DoxBuilderHTML");

                --require Dox and Dox parsers (subclasses)
                Dox                     = require(pDox..".Dox");
                DoxAssemblyNASM         = require(pDoxParsers..".DoxAssemblyNASM")
                DoxAutoPlayMediaStudio  = require(pDoxParsers..".DoxAutoPlayMediaStudio");
                DoxC                    = require(pDoxParsers..".DoxC")
                DoxCSharp               = require(pDoxParsers..".DoxCSharp")
                DoxCPlusPlus            = require(pDoxParsers..".DoxCPlusPlus")
                DoxCSS                  = require(pDoxParsers..".DoxCSS")
                DoxDart                 = require(pDoxParsers..".DoxDart")
                DoxElm                  = require(pDoxParsers..".DoxElm")
                DoxFSharp               = require(pDoxParsers..".DoxFSharp")
                DoxFortran              = require(pDoxParsers..".DoxFortran")
                DoxGo                   = require(pDoxParsers..".DoxGo")
                DoxGroovy               = require(pDoxParsers..".DoxGroovy")
                DoxHaskell              = require(pDoxParsers..".DoxHaskell")
                DoxHTML                 = require(pDoxParsers..".DoxHTML")
                DoxJava                 = require(pDoxParsers..".DoxJava")
                DoxJavaScript           = require(pDoxParsers..".DoxJavaScript")
                DoxJulia                = require(pDoxParsers..".DoxJulia")
                DoxKotlin               = require(pDoxParsers..".DoxKotlin")
                DoxLua                  = require(pDoxParsers..".DoxLua");
                DoxMatlab               = require(pDoxParsers..".DoxMatlab")
                DoxObjectiveC           = require(pDoxParsers..".DoxObjectiveC")
                DoxPerl                 = require(pDoxParsers..".DoxPerl")
                DoxPHP                  = require(pDoxParsers..".DoxPHP")
                DoxPython               = require(pDoxParsers..".DoxPython")
                DoxRuby                 = require(pDoxParsers..".DoxRuby")
                DoxRust                 = require(pDoxParsers..".DoxRust")
                DoxScala                = require(pDoxParsers..".DoxScala")
                DoxSwift                = require(pDoxParsers..".DoxSwift")
                DoxTypeScript           = require(pDoxParsers..".DoxTypeScript")
                DoxXML                  = require(pDoxParsers..".DoxXML")



                --ini
                Ini    = require(pClasses..".util.Ini"); --TODO need to finish OrderedSet first
            end

        end

    end

end


--TODO delete after test
Inventory       = require("LuaEx.test.Inventory.Inventory");
InventoryItem   = require("LuaEx.test.Inventory.InventoryItem");
InventorySlot   = require("LuaEx.test.Inventory.InventorySlot");


--TODO FINISH MOVE TO CoG after CoG is rebuilt.



--🅰🅻🅸🅰🆂🅴🆂
unpack = unpack or table.unpack;--TODO move this to table hook
--table.serialize 	= serialize.table;
--string.serialize 	= serialize.string;
--[[
![LuaEx](https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png)

]]
--useful if using LuaEx as a dependency in multiple modules to prevent the need for loading multilple times
constant("LUAEX_INIT", true); --TODO should this be a required check at the beginning of this module?
