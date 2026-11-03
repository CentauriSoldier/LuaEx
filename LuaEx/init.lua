--[[
     ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
    ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
    ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
    ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
]]
-- FRAMEWORK INITIALIZATION

--[[!
@fqxn LuaEx
@desc
<div class="container py-4">
  <div class="text-center">
    <img src="https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png" alt="LuaEx Logo" class="img-fluid mb-4" style="max-height: 150px;">
    <p class="lead">A lightweight extension of Lua for Lua 5.4+</p>
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
      <li>LuaEx supports Lua 5.4 and later (5.4+); Lua 5.3 and earlier are not supported.</li>
      <li>Native I/O binaries must match the host Lua ABI; bundled lua54 binaries target Lua 5.4.</li>
      <li>Windows x64 native I/O is tested; other native platforms remain unverified.</li>
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
@requires Lua 5.4+ and the debug library.
@desc Initializes all LuaEx framework groups in the global environment when LuaEx.init is required. The file runs directly and returns no framework value. Successful require calls are cached; the initialization guard also prevents repeated initialization when the file is executed directly.
@throws Module/configuration load errors. Failed initialization may leave loaded modules and globals; package.path is restored.
@ex require("LuaEx.init");
!]]
-- Requiring this module is cached by Lua; also guard direct file execution.
if (_G.LUAEX_INIT) then
    return;
end

assert(type(debug) == "table" and type(debug.getinfo) == "function", "LuaEx requires the debug library during initialization. Please enable the debug library before initializing LuaEx.");

local sOriginalPackagePath = package.path;
local bSuccess, vResult = pcall(function()
    --list all keywords
    local tKeyWords = {	"and", 		"break", 	      "do", 		"else", 	"elseif", 	"end",
                        "false", 	"for", 		      "function", "if", 		"in", 		"local",
                        "nil", 		"not", 		      "or", 		"repeat", 	"return", 	"then",
                        "true", 	"until", 	      "while",
                        --LuaEx keywords/types
                        "constant", "enum",           "enumfactory",
                        "event",    "eventrix",
                        "struct",	"null",           "class",	"interface",
                        "array",    "arrayfactory",   "classfactory", "structfactory", "structfactorybuilder"
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
    schema                  =  	require("LuaEx.libext.schema");
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
    -- CLONING, CLASS FACTORY, AND SERIALIZATION

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
    -- LXE handles enum declarations (.lxe); LXC handles class declarations
    -- (.lxc). A class file can also contain enum declarations. Both kinds of
    -- file enter one loading batch so enums are ready before class static
    -- fields and static constructors use them.
    lxe = require("LuaEx.lib.lxe");

    -- Find declaration files in the application's original package.path and
    -- in LuaEx's own classes directory. Adding the framework directory here
    -- ensures bundled classes are found even if package.path omits it.
    -- SourceDiscovery returns one snapshot containing both .lxc and .lxe
    -- files, including the bundled files; no second directory scan is needed.
    local SourceDiscovery = require("LuaEx.lib.SourceDiscovery");
    local pFrameworkRoot  = pSourceDirectory.."/classes";
    local tDiscovery      = SourceDiscovery.scan(sOriginalPackagePath, {pFrameworkRoot});

    -- Connect the class runtime to LuaEx's global environment, cloning and
    -- serialization services. This installs class helpers without loading
    -- any class declarations yet.
    local LXC = require("LuaEx.lib.lxc");
    LXC.bindHost(_G);

    -- These geometry primitives are ordinary Lua modules, not .lxc classes.
    -- Load them before the declaration batch so class initializers can use
    -- point, line, circle, circlearc, ellipse and polygon.
    point     = require("LuaEx.primitives.point");
    line      = require("LuaEx.primitives.line");
    circle    = require("LuaEx.primitives.circle");
    circlearc = require("LuaEx.primitives.circlearc");
    ellipse   = require("LuaEx.primitives.ellipse");
    polygon   = require("LuaEx.primitives.polygon");

    -- Keep the actual file paths for reading and separate comparison keys
    -- for duplicate checks. Overlapping discovery roots must not cause a
    -- declaration file to be included twice.
    local tSourcePaths = {};
    local tSeenPaths   = {};
    local bWindows     = package.config:sub(1, 1) == "\\";

    --[[!
    @fqxn LuaEx.init.fGetPathKey
    @desc Creates a comparison key for an already discovered file path.
        Unifies directory separators and ignores letter case on Windows.
        This does not resolve paths or change the filename used for reading.
    @param string pFile Discovered source-file path.
    @ret string Path key used to detect duplicate source files.
    @vis internal
    !]]
    local function fGetPathKey(pFile)
        local pKey = pFile:gsub("\\", "/");

        if (bWindows) then
            pKey = pKey:lower();
        end

        return pKey;
    end

    -- Files already includes bundled classes, application classes and enums.
    -- Collect that complete list directly rather than splitting framework
    -- files into a second list and then merging them back into this one.
    for _, pFile in ipairs(tDiscovery.Files) do
        local pKey = fGetPathKey(pFile);

        if (not tSeenPaths[pKey]) then
            tSeenPaths[pKey] = true;
            tSourcePaths[#tSourcePaths + 1] = pFile;
        end
    end

    -- Sort filenames for repeatable input. LXC validates the whole batch and
    -- determines class initialization order from declaration dependencies;
    -- alphabetical filename order does not decide inheritance order.
    -- Passing .lxe files here also lets LXC coordinate enum initialization.
    table.sort(tSourcePaths);

    local tLoadedClassNames = LXC.loadFiles(tSourcePaths, _G);

    -- Classes are published under their declared namespaces. Also expose
    -- LuaEx's top-level framework classes by short names such as Stack.
    -- Application class namespaces are left intact.
    LXC.publishFrameworkAliases(tLoadedClassNames, _G);

    -- Preserve existing require("LuaEx.classes.<relative module>") calls.
    -- Each matching .lxc file has already been loaded above: cache its short
    -- global class reference under the corresponding Lua module name so
    -- require returns that class instead of executing an old .lua version.
    for _, pFile in ipairs(tSourcePaths) do
        local pNormalizedFile = pFile:gsub("\\", "/");
        local pRelativeClass  = pNormalizedFile:match("/LuaEx/classes/(.*)%.lxc$");

        if (pRelativeClass) then
            -- Example: Ini becomes the module name
            -- LuaEx.classes.Ini and the global name Ini.
            local sClassName  = pRelativeClass:match("([^/]+)$");
            local sModuleName = "LuaEx.classes."..pRelativeClass:gsub("/", ".");

            package.loaded[sModuleName] = rawget(_G, sClassName);
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

end);
package.path = sOriginalPackagePath;
if (not bSuccess) then
    error(vResult, 0);
end
