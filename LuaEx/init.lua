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
local _tClassLoadValues = {
    [_nClassSystem]         = true,  --should LuaEx load the class system?
    [_nBasicClasses]        = true,  --load basic classes (set, queue, stack, dox, etc.)?
    [_nComponentClasses]    = true,  --component class (potentiometer, protean, etc.)?
    [_nGeometryClasses]     = true,  --geometry classes (shape, circle, polygon, etc.)?
    [_nUtilClasses]         = true,  --other things like Dox, Ini, etc.
    [_nCoGClasses]          = true,  --(Code of Gaming) game system classes
};

local _bUseBootDirectives = true;

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
--[[
local assert        = assert;
local debug         = debug;
local error         = error;
local ipairs        = ipairs;
local rawset        = rawset;
local require       = require;
local setmetatable  = setmetatable;
local table         = table;
local string        = string;
local type          = type;
]]
--TODO I think I need to do this with table.unpack

--enforce the class loading system to prevent errors
--for x = #_tClassLoadValues, 1, -1 do
for x = 1, #_tClassLoadValues do

    if _tClassLoadValues[x] then

        for _, nRequirementIndex in ipairs(_tClassRequirements[x]) do
            _tClassLoadValues[nRequirementIndex] = true;
        --for x2 = 1, x - 1 do
        --    _tClassLoadValues[x2] = true;
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
--[[!
    @fqxn LuaEx.Keywords
    @des A list of all keywords (or types) used in Lua and LuaEx.
    <br>
    <h1>Lua</h1>
    <ul>
        <li>and</li>
        <li>break</li>
        <li>do</li>
        <li>else</li>
        <li>elseif</li>
        <li>end</li>
        <li>false</li>
        <li>for</li>
        <li>function</li>
        <li>if</li>
        <li>in</li>
        <li>local</li>
        <li>nil</li>
        <li>not</li>
        <li>or</li>
        <li>repeat</li>
        <li>return</li>
        <li>then</li>
        <li>true</li>
        <li>until</li>
        <li>while</li>
    </ul>
    <h1>LuaEx</h1>
    <ul>
        <li>array</li>
        <li>arrayfactory</li>
        <li>class</li>
        <li>classfactory</li>
        <li>constant</li>
        <li>enum</li>
        <li>enumfactory</li>
        <li>event</li>
        <li>eventrix</li>
        <li>interface</li>
        <li>null</li>
        <li>struct</li>
        <li>structfactory</li>
        <li>structfactorybuilder</li>
    </ul>
!]]
--list all keywords
local tKeyWords = {	"and", 		"break", 	"do", 		"else", 	"elseif", 	"end",
                    "false", 	"for", 		"function", "if", 		"in", 		"local",
                    "nil", 		"not", 		"or", 		"repeat", 	"return", 	"then",
                    "true", 	"until", 	"while",
                    --LuaEx keywords/types
                    "constant", 	"enum", "enumfactory",
                    "event", "eventrix",
                    "struct",	"null",	"class",	"interface",
                    "array", "arrayfactory", "classfactory", "structfactory", "structfactorybuilder"
};

--create the 'protected' table used by LuaEx
local tLuaEx = {--TODO fix inconsistency in naming and underscores
        __isbooting = type(_bUseBootDirectives) == "boolean" and _bUseBootDirectives or false,
        --__config, --set below
        --these metatables are protected from modification and general access
        __metaguard  = {"class", "classfactory", "enum", "enumfactory",
                        "eventrix", "eventrixfactory", "struct", "structfactory"},
        __keywords__	= setmetatable({}, {
            __index 	= tKeyWords,
            __newindex 	= function(t, k)
                error("Attempt to perform illegal operation: adding keyword to __keywords__ table.");
            end,
            __pairs		= function (t)
                return next, tKeyWords, nil;
            end,
            __metatable = false,
        }),
        __keywords__count__ = #tKeyWords,
        _VERSION = "LuaEx 0.90",
        --_SOURCE_PATH = getsourcepath(),
};

--_G.luaex = setmetatable({},
_ENV.luaex = setmetatable({},
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
assert((type(debug) == "table" and type(debug.getinfo) == "function"), "LuaEx requires the debug library during initialization. Please enable the debug library before initializing LuaEx.");

--store the original package path;
local sOriginalPackagePath = package.path;
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
envrepo			        = 	require("LuaEx.lib.envrepo");
eventrix    	        = 	require("LuaEx.lib.eventrix");
schema                  =  	require("LuaEx.extlib.schema");
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

--import serialization
serializer  = require("LuaEx.lib.serializer");

--import cloner
cloner      = require("LuaEx.lib.cloner");
clone       = cloner.clone;

--🆁🅴🅶🅸🆂🆃🅴🆁 🅻🆄🅰🅴🆇 🅵🅰🅲🆃🅾🆁🅸🅴🆂 🆆🅸🆃🅷 🆃🅷🅴 🅲🅻🅾🅽🅴🆁
cloner.registerFactory(array);
cloner.registerFactory(enum);
cloner.registerFactory(eventrix);
cloner.registerFactory(struct);
cloner.registerFactory(structfactory);

--aliases
serialize   = serializer.serialize;
deserialize = serializer.deserialize;

--import the class system
if (_tClassLoadValues[_nClassSystem]) then
    interface	= require("LuaEx.lib.interface");
    class 		= require("LuaEx.lib.class");
    --🆁🅴🅶🅸🆂🆃🅴🆁 🆃🅷🅴 🅲🅻🅰🆂🆂 🅵🅰🅲🆃🅾🆁🆈 🆆🅸🆃🅷 🆃🅷🅴 🅲🅻🅾🅽🅴🆁
    cloner.registerFactory(class);

    --🅸🅼🅿🅾🆁🆃 🅸🅽🆃🅴🆁🅵🅰🅲🅴🆂
    iCloneable 		= require("LuaEx.inc.interfaces.iCloneable");
    iSerializable 	= require("LuaEx.inc.interfaces.iSerializable");
    iShape 	        = require("LuaEx.inc.interfaces.iShape");

    --🅸🅼🅿🅾🆁🆃 🅲🅻🅰🆂🆂🅴🆂

    if (_tClassLoadValues[_nBasicClasses]) then
        --primitive
        local pPrimitives   = "LuaEx.inc.primitives";
        line                = require(pPrimitives..".line");
        circle              = require(pPrimitives..".circle");
        polygon             = require(pPrimitives..".polygon");

        --actual classes
        local pClasses = "LuaEx.inc.classes";

        --dependency class
        Queue               = require(pClasses..".Queue");
        Stack               = require(pClasses..".Stack");
        Set                 = require(pClasses..".Set");
        SortedDictionary    = require(pClasses..".SortedDictionary");

        if (_tClassLoadValues[_nComponentClasses]) then
            --component classes
            Potentiometer   = require(pClasses..".component.Potentiometer");
            Protean         = require(pClasses..".component.Protean");

            if (_tClassLoadValues[_nGeometryClasses]) then
                --geometry classes
                Point   = require(pClasses..".geometry.Point");
                Line    = require(pClasses..".geometry.Line");
                --shapes
                Shape   = require(pClasses..".geometry.shapes.Shape");
                Circle  = require(pClasses..".geometry.shapes.Circle");
                Polygon = require(pClasses..".geometry.shapes.Polygon");
                --solids
                Solid   = require(pClasses..".geometry.solids.Solid");

                if (_tClassLoadValues[_nCoGClasses]) then
                    local pCoG      = "LuaEx.inc.cog";

                    --load the enums
                    require(pCoG..".Enums");

                    --create the CoG table
                    local tCoG = {
                        config  = require(pCoG..".config"),
                        --Scaler  = require(pCoG..".Scaler"),
                    };

                    setmetatable(tCoG, {__newindex = function() end});

                    --import CoG's table into the luaex global table
                    rawset(tLuaEx, "cog", tCoG);

                    Scaler          = require(pCoG..".Scaler");
                    Rarity          = require(pCoG..".Rarity");
                    RNG             = require(pCoG..".RNG");
                    BaseMod         = require(pCoG..".ModSystem.BaseMod");
                    Factorium       = require(pCoG..".ModSystem.Factorium");
                    CoG             = require(pCoG..".CoG");

                    --interfaces
                    IEquippable     = require(pCoG..".Interfaces.IEquippable");
                    IConsumable     = require(pCoG..".Interfaces.IConsumable");

                    TagSystem       = require(pCoG..".TagSystem");

                    --affix system
                    --local pAffixSystem  = pCoG..".AffixSystem";
                    Affix               = require(pCoG..".Affix");
                    --Affixory            = require(pAffixSystem..".Affixory");

                    Pool            = require(pCoG..".Pool");
                    StatusSystem    = require(pCoG..".StatusSystem");
                    AStar           = require(pCoG..".AStar");

                    --objects
                    local pCoGObjects   = pCoG..".Objects";
                    BaseObject          = require(pCoGObjects..".BaseObject");


                    --item system
                    local pItemSystem   = pCoGObjects..".ItemSystem";
                    BaseItem            = require(pItemSystem..".BaseItem");
                    ItemSlot            = require(pItemSystem..".ItemSlot");
                    ItemSlotSystem      = require(pItemSystem..".ItemSlotSystem");

                    XPSystem        = require(pCoG..".XPSystem");
                end

            end

            if (_tClassLoadValues[_nUtilClasses]) then
                pDox                    = pClasses..".util.Dox";
                local pDoxBuilders      = pDox..".Builders";
                local pDoxComponents    = pDox..".Components";
                local pDoxParsers       = pDox..".Parsers";

                --dox and dox component classes
                DoxMime         = require(pDoxComponents..".DoxMime");
                DoxSyntax       = require(pDoxComponents..".DoxSyntax");
                DoxBlockTag     = require(pDoxComponents..".DoxBlockTag");
                DoxBlock        = require(pDoxComponents..".DoxBlock");
                DoxBuilder      = require(pDoxComponents..".DoxBuilder");

                --require Dox Builders
                DoxBuilderHTML  = require(pDoxBuilders..".HTML.DoxBuilderHTML");

                --require Dox and Dox parsers (subclasses)
                Dox                     = require(pDox..".Dox");
                DoxAssemblyNASM         = require(pDoxParsers..".DoxAssemblyNASM");
                DoxAutoPlayMediaStudio  = require(pDoxParsers..".DoxAutoPlayMediaStudio");
                DoxC                    = require(pDoxParsers..".DoxC");
                DoxCSharp               = require(pDoxParsers..".DoxCSharp");
                DoxCPlusPlus            = require(pDoxParsers..".DoxCPlusPlus");
                DoxCSS                  = require(pDoxParsers..".DoxCSS");
                DoxDart                 = require(pDoxParsers..".DoxDart");
                DoxElm                  = require(pDoxParsers..".DoxElm");
                DoxFSharp               = require(pDoxParsers..".DoxFSharp");
                DoxFortran              = require(pDoxParsers..".DoxFortran");
                DoxGo                   = require(pDoxParsers..".DoxGo");
                DoxGroovy               = require(pDoxParsers..".DoxGroovy");
                DoxHaskell              = require(pDoxParsers..".DoxHaskell");
                DoxHTML                 = require(pDoxParsers..".DoxHTML");
                DoxJava                 = require(pDoxParsers..".DoxJava");
                DoxJavaScript           = require(pDoxParsers..".DoxJavaScript");
                DoxJulia                = require(pDoxParsers..".DoxJulia");
                DoxKotlin               = require(pDoxParsers..".DoxKotlin");
                DoxLua                  = require(pDoxParsers..".DoxLua");
                DoxMatlab               = require(pDoxParsers..".DoxMatlab");
                DoxObjectiveC           = require(pDoxParsers..".DoxObjectiveC");
                DoxPerl                 = require(pDoxParsers..".DoxPerl");
                DoxPHP                  = require(pDoxParsers..".DoxPHP");
                DoxPython               = require(pDoxParsers..".DoxPython");
                DoxRuby                 = require(pDoxParsers..".DoxRuby");
                DoxRust                 = require(pDoxParsers..".DoxRust");
                DoxScala                = require(pDoxParsers..".DoxScala");
                DoxSwift                = require(pDoxParsers..".DoxSwift");
                DoxTypeScript           = require(pDoxParsers..".DoxTypeScript");
                DoxXML                  = require(pDoxParsers..".DoxXML");



                --ini
                Ini     = require(pClasses..".util.Ini"); --TODO need to finish OrderedSet first
                BaseLog = require(pClasses..".util.BaseLog");
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


if (_bUseBootDirectives and 1 == 5) then--TODO FINISH move to ext file

    local function isdirectory(path)
        local p = io.popen('cd "' .. path .. '" 2>nul && echo ok')
        local result = p:read("*a")
        p:close()
        return result:match("ok") ~= nil
    end

    local function removeFilename(pDir)
        local sRet = pDir;

        local nPos = pDir:match(".*\\()");

        if (nPos) then
            sRet = pDir:sub(1, nPos - 2);
            sRet = sRet:gsub("\\%?", ' ');
        end

        return sRet;
    end


    local tDirs             = string.totable(package.path, ';');
    local tPathsToSearch    = {};
    local nPathsToSearch    = 0;

    if not (type(tDirs) == "table") then
        --TODO THROW ERROR
    end

    --find and store the legitmate directory paths
    for _, pDirRaw in pairs(tDirs) do
        local pDir = io.normalizepath(removeFilename(pDirRaw)):trim();

        if (isdirectory(pDir) and
            pDir ~= "\\" and pDir ~= "\\." and
            (tPathsToSearch[pDir] == nil)) then
            tPathsToSearch[pDir] = true;
            nPathsToSearch = nPathsToSearch + 1;
        end

    end

    local tClasses = {};
    local tClassesIndexer = {};
    local tClassesByName = {};

    local function getIndex(sName)

    end

    if (nPathsToSearch > 0) then

        local function addClassFile(pFile)

            if (tClassesIndexer[pFile] == nil) then
                local tParts = io.splitpath(pFile);

                if (tParts) then
                    local sName = tParts.filename;
                    local nIndex = #tClasses + 1;

                    tClassesByName[sName] = {
                        index = nIndex,
                        path = pFile,
                    };

                    tClassesIndexer[pFile] = {
                        index = nIndex,
                        name = sName,
                    };

                    tClasses[nIndex] = {
                        name = sName,
                        path = pFile,
                    };
                end

            end

        end

        for pDir, _ in pairs(tPathsToSearch) do
            listfiles(pDir, true, addClassFile, 'class');
        end

    end

    local nSafety   = math.factorial(#tClasses);
    local fLoader   = nil;
    local bSuccess  = true;
    local sMessage  = "";

    --attempt to load the classes
    for nID, tClassInfo in ipairs(tClasses) do
        local sClass    = tClassInfo.name;
        local pFile     = tClassInfo.path;

        fLoader, sMessage = loadfile(tClassInfo.path);

        if not (fLoader) then
            error("Error loading class, '"..sClass.."'\n"..sMessage);
        end

        bSuccess, sMessage = pcall(fLoader);

        if not (bSuccess) then
            local nGlobalErrorStart = sMessage:find("attempt to call a nil value (global '");

            if nGlobalErrorStart then
                local nIndex = tClassesIndexer[pFile].index;
                --print(nIndex, sMessage);

            else
                error("Error loading class, '"..sClass.."'\n"..sMessage);
            end

        end

    end

end


--useful if using LuaEx as a dependency in multiple modules to prevent the need for loading multilple times
constant("LUAEX_INIT", true); --TODO should this be a required check at the beginning of this module?\

--restore the original package path;
package.path = sOriginalPackagePath;
