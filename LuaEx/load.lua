--[[
     ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
    ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
    ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
    ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
]]
-- ON-DEMAND LOADER AND OPTIONS

-- Class group identifiers retain the framework's existing dependency mapping.
local _nClassSystem      = 1;
local _nBasicClasses     = 2;
local _nComponentClasses = 3;
local _nUtilClasses      = 4;
local _nGeometryClasses  = 5;
local _tClassRequirements = {
    [_nClassSystem]      = {},
    [_nBasicClasses]     = {_nClassSystem},
    [_nComponentClasses] = {_nClassSystem, _nBasicClasses},
    [_nGeometryClasses]  = {_nClassSystem, _nBasicClasses, _nComponentClasses},
    [_nUtilClasses]      = {_nClassSystem, _nBasicClasses, _nComponentClasses},
};
-- Default user choices. nil arguments retain these values.
-- Levels: 0 core only; 1 class system; 2 basic; 3 components;
--         4 utilities; 5 geometry.
local nClassLoadLevel = 5;

--[[!
@fqxn LuaEx
@desc
<div class="container py-4">
  <div class="text-center">
    <img src="https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png" alt="LuaEx Logo" class="img-fluid mb-4" style="max-height: 150px;">
    <p class="lead">A lightweight extension of Lua with a Lua 5.4 class runtime</p>
  </div>

  <div class="my-5">
    <h3 class="mb-3">Key Features</h3>
    <ul class="list-group">
      <li class="list-group-item">✅ Drop-in global environment initializer</li>
      <li class="list-group-item">✅ Class system with full OOP: inheritance, encapsulation, polymorphism</li>
      <li class="list-group-item">✅ Event system</li>
      <li class="list-group-item">✅ Ships with basic classes (<em>E.g., Set, Stack, Queue, SortedDictionary, etc.</em>)</li>
      <li class="list-group-item">✅ Strict naming, coding and commenting conventions for clarity and consistency</li>
      <li class="list-group-item">✅ Enhanced type system with subtype support</li>
      <li class="list-group-item">✅ Boolean arithmetic and coercion features</li>
      <li class="list-group-item">✅ Safe <code>null</code> type (distinct from <code>nil</code>)</li>
      <li class="list-group-item">✅ Simple constant definition</li>
      <li class="list-group-item">✅ Typed objects like <strong>arrays</strong>, <strong>enums</strong>, and <strong>structs</strong></li>
      <li class="list-group-item">✅ Built-in serializer/deserializer system with metatable support</li>
    </ul>
  </div>

  <div class="my-5">
    <h3 class="mb-3">Class System</h3>
    <p>Supports:</p>
    <ul>
      <li>Static initializers and constructors</li>
      <li>Final classes and final methods</li>
      <li>Scoped LXC class declarations discovered from .lxc files</li>
      <li>Automatic and custom property accessors</li>
      <li>Support for encapsulation (private/protected/public)</li>
    </ul>
  </div>

  <div class="my-5">
    <h3 class="mb-3">Advanced Data Types</h3>
    <div class="row">
      <div class="col-md-4">
        <h5>Arrays</h5>
        <ul>
          <li>Fixed length</li>
          <li>Type-safe</li>
          <li>Bounds checked</li>
          <li>Optional initial values</li>
        </ul>
      </div>
      <div class="col-md-4">
        <h5>Enums</h5>
        <ul>
          <li>Strict ordinal values</li>
          <li>Optional value types</li>
          <li>Runtime creation support</li>
        </ul>
      </div>
      <div class="col-md-4">
        <h5>Structs</h5>
        <ul>
          <li>Fixed key/value pairs</li>
          <li>Immutable or mutable</li>
          <li>Strict typing per key</li>
        </ul>
      </div>
    </div>
  </div>

  <div class="my-5">
    <h3 class="mb-3">Serialization</h3>
    <p>Supports native Lua types and custom types that implement:</p>
    <ul>
      <li><code>__serialize</code> metamethod for object state extraction</li>
      <li><code>deserialize()</code> static function for reconstitution</li>
      <li>Class objects have built-in auto serialization/deserialization</li>
    </ul>
    <p class="text-white">Threads and userdata are not serializable.</p>
  </div>

  <div class="my-5">
    <h3 class="mb-3">Simplicity & Compatibility</h3>
    <ul>
      <li>LXC requires Lua 5.4</li>
      <li>The bundled Windows Lua 5.4 runtime is tested; other hosts remain unverified.</li>
      <li>Minimal learning curve with intuitive APIs</li>
      <li>Effortlessly extendable</li>
    </ul>
  </div>

  <div class="my-5">
    <h3 class="mb-3">License</h3>
    <p><strong>LuaEx</strong> is released under <a href="https://opensource.org/licenses/unlicense" target="_blank">The Unlicense</a>. Use it freely for any purpose, personal or commercial.</p>
  </div>

  <div class="my-5 text-center">
    <a href="https://centaurisoldier.github.io/LuaEx" class="btn btn-primary btn-lg" target="_blank">📚 View Full Documentation</a>
    <a href="https://github.com/CentauriSoldier/LuaEx" class="btn btn-outline-secondary btn-lg ml-3" target="_blank">🌐 Visit GitHub Repo</a>
  </div>
</div>

!]]

--[[!
@fqxn LuaEx.init
@pulsarlua function init
@desc Initializes LuaEx on demand. Requiring LuaEx.load only returns this function. Omitted or nil arguments use the defaults above. The class-load level enables every group up to that level. Further calls after successful initialization return the existing luaex environment without reconfiguring it.
@param number|nil nLoadLevel Whole number from 0 (core only) to 5 (all groups); defaults to 5. Levels 1 through 5 enable class system, basic, components, utilities and geometry respectively.
@ret table The global luaex environment.
@throws Invalid options or module/configuration load errors. Failed initialization may leave loaded modules and globals; package.path is restored.
@ex local init = require("LuaEx.load"); init();
@ex local init = require("LuaEx.load"); init(5);
!]]
local function init(...)
    if (_G.LUAEX_INIT) then
        return luaex;
    end

    assert(select("#", ...) <= 1, "LuaEx init accepts at most one option.");
    local nLoadLevel = ...;
    if (nLoadLevel == nil) then
        nLoadLevel = nClassLoadLevel;
    end
    assert(type(nLoadLevel) == "number" and nLoadLevel >= 0 and
           nLoadLevel <= 5 and nLoadLevel % 1 == 0,
           "LuaEx class-load level must be a whole number from 0 to 5.");
    local _tClassLoadValues = {};
    for nGroup = 1, _nGeometryClasses do
        _tClassLoadValues[nGroup] = nGroup <= nLoadLevel;
    end

    -- Enable the complete dependency closure before any framework globals change.
    local function fEnableRequirements(nGroup)
        for _, nRequirement in ipairs(_tClassRequirements[nGroup]) do
            if (not _tClassLoadValues[nRequirement]) then
                _tClassLoadValues[nRequirement] = true;
                fEnableRequirements(nRequirement);
            end
        end
    end
    for nGroup = 1, #_tClassLoadValues do
        if (_tClassLoadValues[nGroup]) then
            fEnableRequirements(nGroup);
        end
    end
    assert(type(debug) == "table" and type(debug.getinfo) == "function", "LuaEx requires the debug library during initialization. Please enable the debug library before initializing LuaEx.");

    local sOriginalPackagePath = package.path;
    local bSuccess, vResult = pcall(function()
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
        local tLuaEx = {
                __isbooting = true,
                --these metatables are protected from modification and general access
                __metaguard  = {"class", "classfactory", "enum", "enumfactory",
                                "eventrix", "eventrixfactory", "struct", "structfactory"},
                __keywords__	= setmetatable({}, {
                    __index 	= tKeyWords,
                    __newindex 	= function(t, k)
                        error("Attempt to perform illegal operation: adding keyword to __keywords__ table.");
                    end,
                    __pairs		= function (t)
                        return function(_, vKey) return next(tKeyWords, vKey); end, t, nil;
                    end,
                    __metatable = false,
                }),
                __keywords__count__ = #tKeyWords,
                _VERSION = "LuaEx 0.62",
        };

        _G.luaex = setmetatable({},
        {
            __index 		= tLuaEx,
            __newindex 		= function(t, k, v)

                if tLuaEx[k] ~= nil then
                    error("Attempt to overwrite luaex value in key '"..tostring(k).."' ("..type(k)..") with value "..tostring(v).." ("..type(v)..") .");
                end

                rawset(tLuaEx, k, v);
            end,
            __metatable 	= false,
        });


        --store the original package path;
        --determine the call location
        local sSource = debug.getinfo(1, "S").source;
        local pSourceDirectory = sSource:match("^@(.+)[/\\][^/\\]+$") or ".";

        -- Windows also accepts forward slashes; use a portable package template.
        package.path = package.path..";"..pSourceDirectory.."/../?.lua";

        cloner, clone = nil; -- Module factories capture these globals after the cloner is loaded.

        --[[
             ██████╗ ██████╗ ██████╗ ███████╗
            ██╔════╝██╔═══██╗██╔══██╗██╔════╝
            ██║     ██║   ██║██████╔╝█████╗
            ██║     ██║   ██║██╔══██╗██╔══╝
            ╚██████╗╚██████╔╝██║  ██║███████╗
             ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
        ]]
        -- CORE FACTORIES: type/metatable hooks precede factory creation.

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
        strata                  =   require("LuaEx.lib.strata");
        envrepo			        = 	require("LuaEx.lib.envrepo");
        eventrix    	        = 	require("LuaEx.lib.eventrix");
        schema                  =  	require("LuaEx.extlib.schema");
        local tStruct           = 	require("LuaEx.lib.struct");
        struct                  =   tStruct.struct;
        structfactory           =   tStruct.structfactory;
        source			        =	require("LuaEx.util.source");
        isotominutes            =   require("LuaEx.util.isotominutes");
        prettyLua               =   require("LuaEx.util.prettylua");
        textcatalog             =   require("LuaEx.lib.textcatalog");

        --[[
             ██████╗ ██╗      ██████╗ ██████╗  █████╗ ██╗     ███████╗
            ██╔════╝ ██║     ██╔═══██╗██╔══██╗██╔══██╗██║     ██╔════╝
            ██║  ███╗██║     ██║   ██║██████╔╝███████║██║     ███████╗
            ██║   ██║██║     ██║   ██║██╔══██╗██╔══██║██║     ╚════██║
            ╚██████╔╝███████╗╚██████╔╝██████╔╝██║  ██║███████╗███████║
             ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
        ]]
        -- GLOBAL ENVIRONMENT: protect constants and enums before loading constants.

        --setup the global environment to properly manage enums, constants and their ilk
        local tGMeta = getmetatable(_G) or {};
        tGMeta.__newindex = function(t, k, v)

            --make sure functions such as constant, enum, etc., constant values and enums values aren't being overwritten
            if _G.luaex[k] ~= nil then
                error("Attempt to overwrite protected item '"..tostring(k).."' ("..type(_G.luaex[k])..") with '"..tostring(v).."' ("..type(v)..").");
            end

            rawset(t, k, v);
        end
        tGMeta.__index = _G.luaex;
        setmetatable(_G, tGMeta);

        -- Constants depend on the factory/global-environment bootstrap above.
        require("LuaEx.constants");

        --[[
            ██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗███████╗
            ██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██╔════╝
            ███████║██║   ██║██║   ██║█████╔╝ ███████╗
            ██╔══██║██║   ██║██║   ██║██╔═██╗ ╚════██║
            ██║  ██║╚██████╔╝╚██████╔╝██║  ██╗███████║
            ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝
        ]]
        -- STANDARD LIBRARY HOOKS AND SUPPORT MODULES

        --import lua hook modules (except 'typehook' which is loaded first [above])
        io   		= require("LuaEx.hook.iohook");
        math 		= require("LuaEx.hook.mathhook");
        string		= require("LuaEx.hook.stringhook");
        table		= require("LuaEx.hook.tablehook");
        base64 		= require("LuaEx.lib.base64");
        qr          = require("LuaEx.lib.qr");

        --import cloner
        cloner      = require("LuaEx.lib.cloner");
        clone       = cloner.clone;

        --[[
            ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗███████╗███████╗
            ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██║██╔════╝██╔════╝
            █████╗  ███████║██║        ██║   ██║   ██║██████╔╝██║█████╗  ███████╗
            ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗██║██╔══╝  ╚════██║
            ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║██║███████╗███████║
            ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝
        ]]
        -- CLONING, OPTIONAL CLASS FACTORY, AND SERIALIZATION

        cloner.registerFactory(array);
        cloner.registerFactory(enum);
        cloner.registerFactory(eventrix);
        cloner.registerFactory(struct);
        cloner.registerFactory(structfactory);


        --import serialization
        serializer  = require("LuaEx.lib.serializer");

        --aliases
        serialize   = serializer.serialize;
        deserialize = serializer.deserialize;

        --[[
             ██████╗██╗      █████╗ ███████╗███████╗███████╗███████╗
            ██╔════╝██║     ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝
            ██║     ██║     ███████║███████╗███████╗█████╗  ███████╗
            ██║     ██║     ██╔══██║╚════██║╚════██║██╔══╝  ╚════██║
            ╚██████╗███████╗██║  ██║███████║███████║███████╗███████║
             ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝
        ]]
        -- LXC owns class loading; baseline primitives remain ordinary Lua modules.
        if (_tClassLoadValues[_nClassSystem]) then
            local LXC = require("LuaEx.lib.lxc");
            LXC.bindHost(_G);

            if (_tClassLoadValues[_nBasicClasses]) then
                point     = require("LuaEx.primitives.point");
                line      = require("LuaEx.primitives.line");
                circle    = require("LuaEx.primitives.circle");
                circlearc = require("LuaEx.primitives.circlearc");
                ellipse   = require("LuaEx.primitives.ellipse");
                polygon   = require("LuaEx.primitives.polygon");
            end

            local tFramework, tPaths, tSeen = {}, {}, {};
            local function fPathKey(pFile)
                local pKey = pFile:gsub("\\", "/");
                return package.config:sub(1, 1) == "\\" and pKey:lower() or pKey;
            end

            -- Identify bundled source groups before merging application discovery.
            -- Disabled framework groups must not enter through an overlapping root.
            for _, pFile in ipairs(LXC.discover(pSourceDirectory.."/classes/?.lua")) do
                local pKey = fPathKey(pFile);
                local nGroup = pKey:find("/component/", 1, true) and _nComponentClasses or
                    (pKey:find("/util/", 1, true) and _nUtilClasses or _nBasicClasses);
                tFramework[pKey] = {Path = pFile, Group = nGroup};
            end

            local function fInclude(pFile)
                local pKey = fPathKey(pFile);
                local tFrameworkFile = tFramework[pKey];
                if (not tSeen[pKey] and (not tFrameworkFile or _tClassLoadValues[tFrameworkFile.Group])) then
                    tSeen[pKey] = true;
                    tPaths[#tPaths + 1] = pFile;
                end
            end

            for _, tFile in pairs(tFramework) do fInclude(tFile.Path); end
            for _, pFile in ipairs(LXC.discover(sOriginalPackagePath)) do fInclude(pFile); end
            table.sort(tPaths);
            local tNames = LXC.loadFiles(tPaths, _G);
            LXC.publishFrameworkAliases(tNames, _G);

            -- Preserve documented require paths without executing legacy .lua
            -- class declarations against LXC's scoped helper API.
            for _, pFile in ipairs(tPaths) do
                local sRelative = pFile:gsub("\\", "/"):match("/LuaEx/classes/(.*)%.lxc$");
                if (sRelative) then
                    local sName = sRelative:match("([^/]+)$");
                    package.loaded["LuaEx.classes."..sRelative:gsub("/", ".")] = rawget(_G, sName);
                end
            end
        end

        --[[
            ███████╗██╗███╗   ██╗██╗███████╗██╗  ██╗
            ██╔════╝██║████╗  ██║██║██╔════╝██║  ██║
            █████╗  ██║██╔██╗ ██║██║███████╗███████║
            ██╔══╝  ██║██║╚██╗██║██║╚════██║██╔══██║
            ██║     ██║██║ ╚████║██║███████║██║  ██║
            ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝
        ]]
        -- FINALIZE: publish the success flag only after every requested module loads.

        unpack = unpack or table.unpack;

        constant("LUAEX_INIT", true);

        rawset(tLuaEx, "__isbooting", false);

        return luaex;

    end);
    package.path = sOriginalPackagePath;
    if (not bSuccess) then
        error(vResult, 0);
    end
    return vResult;
end

return init;
