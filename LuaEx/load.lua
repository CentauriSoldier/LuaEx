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
local _nCoGClasses       = 6;
local _tClassRequirements = {
    [_nClassSystem]      = {},
    [_nBasicClasses]     = {_nClassSystem},
    [_nComponentClasses] = {_nClassSystem, _nBasicClasses},
    [_nGeometryClasses]  = {_nClassSystem, _nBasicClasses, _nComponentClasses},
    [_nUtilClasses]      = {_nClassSystem, _nBasicClasses, _nComponentClasses},
    [_nCoGClasses]       = {_nClassSystem, _nBasicClasses, _nComponentClasses, _nGeometryClasses},
};
-- Default user choices. nil arguments retain these values.
-- Levels: 0 core only; 1 class system; 2 basic; 3 components;
--         4 utilities; 5 geometry; 6 Code of Gaming.
local nCoGConfigParentLevels = 0;
local nClassLoadLevel = 6;

--[[!
@fqxn LuaEx
@desc
<div class="container py-4">
  <div class="text-center">
    <img src="https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png" alt="LuaEx Logo" class="img-fluid mb-4" style="max-height: 150px;">
    <p class="lead">A powerful, lightweight extension of Lua 5.3+</p>
  </div>

  <div class="my-5">
    <h3 class="mb-3">Key Features</h3>
    <ul class="list-group">
      <li class="list-group-item">✅ Drop-in global environment initializer</li>
      <li class="list-group-item">✅ Class system with full OOP: inheritance, encapsulation, polymorphism</li>
      <li class="list-group-item">✅ Dox documentation generator</li>
      <li class="list-group-item">✅ CoG game framework</li>
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
      <li>Optional interface declarations</li>
      <li>Auto-accessor properties via <code>__AUTO</code> directive</li>
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
      <li>Designed for Lua 5.3</li>
      <li>Backwards-compatible with Lua 5.1 (where possible)</li>
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
@param number|nil nConfigParentLevels Parent levels above LuaEx/inc/cog for the user config.lua overlay; 0 uses bundled defaults only. Validated when CoG is enabled.
@param number|nil nLoadLevel Whole number from 0 (core only) to 6 (all groups); defaults to 6. Levels 1 through 5 enable class system, basic, components, utilities and geometry respectively.
@param string|nil sConfigFilename User configuration name without an extension; non-string values default to config. Empty or blank names, extensions and directory components are rejected. Used when config-parent levels are positive.
@ret table The global luaex environment.
@throws Invalid options or module/configuration load errors. Failed initialization may leave loaded modules and globals; package.path is restored.
@ex local init = require("LuaEx.load"); init();
@ex local init = require("LuaEx.load"); init(3, 6);
!]]
local function init(...)
    if (_G.LUAEX_INIT) then
        return luaex;
    end

    assert(select("#", ...) <= 3, "LuaEx init accepts at most three options.");
    local nConfigParentLevels, nLoadLevel, sConfigFilename = ...;
    if (nConfigParentLevels == nil) then
        nConfigParentLevels = nCoGConfigParentLevels;
    end
    if (nLoadLevel == nil) then
        nLoadLevel = nClassLoadLevel;
    end
    -- Keep the legacy filename unless the caller supplies a project-specific name.
    if (type(sConfigFilename) ~= "string") then
        sConfigFilename = "config";
    end
    assert(type(sConfigFilename) == "string" and #sConfigFilename > 0 and
           sConfigFilename:find("%S") and
           not sConfigFilename:find("[./\\:%z]"),
           "CoG config filename must be a nonblank name without an extension or directory components.");

    assert(type(nLoadLevel) == "number" and nLoadLevel >= 0 and
           nLoadLevel <= 6 and nLoadLevel % 1 == 0,
           "LuaEx class-load level must be a whole number from 0 to 6.");
    local _tClassLoadValues = {};
    for nGroup = 1, _nCoGClasses do
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
    if (_tClassLoadValues[_nCoGClasses]) then
        assert(type(nConfigParentLevels) == "number" and
               nConfigParentLevels >= 0 and nConfigParentLevels < math.huge and
               nConfigParentLevels % 1 == 0,
               "CoG config parent levels must be zero or a positive whole number.");
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
                _VERSION = "LuaEx 0.90",
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

        if (_tClassLoadValues[_nClassSystem]) then
            interface = require("LuaEx.lib.interface");
            class = require("LuaEx.lib.class");

            cloner.registerFactory(class);
        end

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
        -- CLASS GROUPS: dependencies are enabled before entering these blocks.

        if (_tClassLoadValues[_nClassSystem]) then

            -- Interfaces must exist before classes implementing them.
            iCloneable 		= require("LuaEx.inc.interfaces.iCloneable");
            iSerializable 	= require("LuaEx.inc.interfaces.iSerializable");
            iShape 	        = require("LuaEx.inc.interfaces.iShape");

            -- Basic primitives and collections.

            if (_tClassLoadValues[_nBasicClasses]) then
                --primitive
                local pPrimitives   = "LuaEx.inc.primitives";
                point               = require(pPrimitives..".point");
                line                = require(pPrimitives..".line");
                circle              = require(pPrimitives..".circle");
                circlearc           = require(pPrimitives..".circlearc");
                ellipse             = require(pPrimitives..".ellipse");
                polygon             = require(pPrimitives..".polygon");

                --actual classes
                local pClasses = "LuaEx.inc.classes";

                --dependency class
                Queue               = require(pClasses..".Queue");
                XML                 = require(pClasses..".XML");
                Stack               = require(pClasses..".Stack");
                Tree                = require(pClasses..".Tree");
                Set                 = require(pClasses..".Set");
                SortedDictionary    = require(pClasses..".SortedDictionary");

                --[[
                     ██████╗ ██████╗ ███╗   ███╗██████╗  ██████╗ ███╗   ██╗███████╗███╗   ██╗████████╗███████╗
                    ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔═══██╗████╗  ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
                    ██║     ██║   ██║██╔████╔██║██████╔╝██║   ██║██╔██╗ ██║█████╗  ██╔██╗ ██║   ██║   ███████╗
                    ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║   ██║██║╚██╗██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║
                    ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ╚██████╔╝██║ ╚████║███████╗██║ ╚████║   ██║   ███████║
                     ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
                ]]
                -- COMPONENTS

                if (_tClassLoadValues[_nComponentClasses]) then
                    --component classes
                    Potentiometer   = require(pClasses..".component.Potentiometer");
                    Protean         = require(pClasses..".component.Protean");

                    --[[
                         ██████╗ ███████╗ ██████╗ ███╗   ███╗███████╗████████╗██████╗ ██╗   ██╗
                        ██╔════╝ ██╔════╝██╔═══██╗████╗ ████║██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝
                        ██║  ███╗█████╗  ██║   ██║██╔████╔██║█████╗     ██║   ██████╔╝ ╚████╔╝
                        ██║   ██║██╔══╝  ██║   ██║██║╚██╔╝██║██╔══╝     ██║   ██╔══██╗  ╚██╔╝
                        ╚██████╔╝███████╗╚██████╔╝██║ ╚═╝ ██║███████╗   ██║   ██║  ██║   ██║
                         ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝
                    ]]
                    -- GEOMETRY

                    if (_tClassLoadValues[_nGeometryClasses]) then
                        --geometry classes
                        --Point   = require(pClasses..".geometry.Point");
                        --Line    = require(pClasses..".geometry.Line");
                        --shapes
                        --Shape   = require(pClasses..".geometry.shapes.Shape");
                        --Circle  = require(pClasses..".geometry.shapes.Circle");
                        --Polygon = require(pClasses..".geometry.shapes.Polygon");
                        --solids
                        --Solid   = require(pClasses..".geometry.solids.Solid");
                        --TODO REMOVE SECTION  
                        --[[
                             ██████╗ ██████╗  ██████╗
                            ██╔════╝██╔═══██╗██╔════╝
                            ██║     ██║   ██║██║  ███╗
                            ██║     ██║   ██║██║   ██║
                            ╚██████╗╚██████╔╝╚██████╔╝
                             ╚═════╝ ╚═════╝  ╚═════╝
                        ]]
                        -- CODE OF GAMING

                        if (_tClassLoadValues[_nCoGClasses]) then
                            local pCoG      = "LuaEx.inc.cog";

                            local function fLoadCoGConfig()
                                -- Always execute the bundled assembler. It owns default sections,
                                -- loads the optional user overlay and locks the combined result.
                                local pConfigFile = pSourceDirectory.."/inc/cog/config.lua";
                                local configLoader, sError = loadfile(pConfigFile);
                                assert(configLoader, "Unable to load CoG config at '"..pConfigFile.."': "..tostring(sError));
                                local tConfigOptions = {userFilename = sConfigFilename..".lua"};

                                if (nConfigParentLevels > 0) then
                                    -- Resolve the user's file independently of the working directory.
                                    tConfigOptions.userDirectory = pSourceDirectory.."/inc/cog"..
                                                                   string.rep("/..", nConfigParentLevels);
                                end

                                local tConfig = configLoader(pCoG..".config", tConfigOptions);
                                type.assert.custom(tConfig, "table", "CoG config must return a table.");

                                -- A later require must observe the same assembled config as luaex.cog.
                                package.loaded[pCoG..".config"] = tConfig;
                                return tConfig;
                            end

                            --load the enums
                            require(pCoG..".Enums");

                            -- The base class has no config dependencies. Load it first so
                            -- user config.lua can mark replacement tables with CoG.purge.
                            CoG             = require(pCoG..".CoG");

                            --create the CoG table
                            local tCoG = {
                                config  = fLoadCoGConfig(),
                            };

                            --import CoG's table into the luaex global table
                            rawset(tLuaEx, "cog", table.readonly(tCoG));

                            scaler          = require(pCoG..".scaler");
                            Shuffler        = require(pCoG..".Shuffler");
                            Rarity          = require(pCoG..".Rarity");
                            RNG             = require(pCoG..".RNG");
                            BaseMod         = require(pCoG..".ModSystem.BaseMod");
                            Factorium       = require(pCoG..".ModSystem.Factorium");
                            Tiled           = require(pCoG..".Tiled");

                            --interfaces
                            IEquippable     = require(pCoG..".Interfaces.IEquippable");
                            IConsumable     = require(pCoG..".Interfaces.IConsumable");

                            TagSystem       = require(pCoG..".TagSystem");
                            Targetor        = require(pCoG..".Targetor");

                            -- Register lightweight instance types with their exact names.
                            type.TagSystem = true;
                            type.Targetor = true;

                            --affix system
                            Affix               = require(pCoG..".Affix");

                            Pool            = require(pCoG..".Pool");
                            StatusTracker   = require(pCoG..".StatusTracker");
                            AStar           = require(pCoG..".AStar");

                            --objects
                            local pCoGObjects   = pCoG..".Objects";
                            CoGRegistry            = require(pCoG..".CoGRegistry");
                            ObjectRegistry      = require(pCoGObjects..".ObjectRegistry");
                            BaseObject          = require(pCoGObjects..".BaseObject");
                            BaseCard            = require(pCoG..".CardSystem.BaseCard");
                            BaseDeck            = require(pCoG..".CardSystem.BaseDeck");

                            --item system
                            local pItemSystem   = pCoGObjects..".ItemSystem";
                            SlotPattern         = require(pItemSystem..".SlotPattern");
                            BaseItem            = require(pItemSystem..".BaseItem");
                            ItemSlot            = require(pItemSystem..".ItemSlot");
                            ItemSlotSystem      = require(pItemSystem..".ItemSlotSystem");
                            ItemSystem          = require(pItemSystem..".ItemSystem");
                            ItemStashSystem     = require(pItemSystem..".ItemStashSystem");

                            XPSystem        = require(pCoG..".XPSystem");

                            -- Creature composition requires inventory, Rover and XP components first.
                            BaseCreature    = require(pCoGObjects..".CreatureSystem.BaseCreature");
                        end

                    end

                    --[[
                        ██╗   ██╗████████╗██╗██╗     ██╗████████╗██╗███████╗███████╗
                        ██║   ██║╚══██╔══╝██║██║     ██║╚══██╔══╝██║██╔════╝██╔════╝
                        ██║   ██║   ██║   ██║██║     ██║   ██║   ██║█████╗  ███████╗
                        ██║   ██║   ██║   ██║██║     ██║   ██║   ██║██╔══╝  ╚════██║
                        ╚██████╔╝   ██║   ██║███████╗██║   ██║   ██║███████╗███████║
                         ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝   ╚═╝╚══════╝╚══════╝
                    ]]
                    -- DOCUMENTATION AND UTILITIES

                    if (_tClassLoadValues[_nUtilClasses]) then
                        local pDox              = pClasses..".util.Dox";
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
                        DoxBuilderHTML      = require(pDoxBuilders..".HTML.DoxBuilderHTML");
                        DoxBuilderPulsarLua = require(pDoxBuilders..".Pulsar.Lua.DoxBuilderPulsarLua");

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
                        Ini     = require(pClasses..".util.Ini");
                        BaseLog = require(pClasses..".util.BaseLog");
                    end

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
