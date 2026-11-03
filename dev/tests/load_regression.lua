--[[!
    @fqxn Tests.Initialization
    @desc Checks direct full-framework initialization in a fresh interpreter,
        repeated require caching, direct execution and package-path restoration.
!]]
local function run()
    local sOriginalPath = package.path;
    assert(luaex == nil and LUAEX_INIT == nil, "Run initialization checks in a fresh interpreter.");

    -- A missing debug library must fail before framework globals are installed.
    local tDebug = debug;
    debug = nil;
    local bInitialized = pcall(require, "LuaEx.init");
    debug = tDebug;
    assert(not bInitialized and luaex == nil and LUAEX_INIT == nil);
    assert(package.path == sOriginalPath and not package.loaded["LuaEx.init"]);

    -- The module initializes all groups and returns no framework object.
    assert(require("LuaEx.init") == true);
    local tEnvironment = luaex;
    assert(LUAEX_INIT and not tEnvironment.__isbooting);
    assert(class and Stack and Protean and VFS and point and polygon);
    assert(package.path == sOriginalPath);

    -- Both require caching and the explicit initialization guard preserve state.
    assert(require("LuaEx.init") == true and luaex == tEnvironment);
    local pInitializer = assert(package.searchpath("LuaEx.init", package.path));
    assert(dofile(pInitializer) == nil and luaex == tEnvironment);
    assert(require("LuaEx.classes.Stack") == Stack);
    assert(package.path == sOriginalPath);
    print("PASS initialization: full framework, failure recovery, globals, caching, guard and path restoration.");
end

return run;
