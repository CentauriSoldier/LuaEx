--[[!
    @fqxn Tests.Loader
    @desc Checks loader options or one dependency level in an uninitialized process.
    Invoked by tests/run.lua so each loader configuration gets independent globals.
!]]
local function run(vLevel)
    local fNativeType = type;
    local sPath = package.path;
    local init = require("LuaEx.load");
    assert(type(init) == "function" and luaex == nil and LUAEX_INIT == nil);
    assert(type == fNativeType and package.path == sPath);

    if (vLevel == "options") then
        for _, vInvalid in ipairs({-1, 6, 0.5, math.huge, false, "2", {}}) do
            assert(not pcall(init, vInvalid));
            assert(luaex == nil and LUAEX_INIT == nil and package.path == sPath);
        end
        assert(not pcall(init, 0 / 0));
        assert(not pcall(init, 0, 4));
        local tDebug = debug;
        debug = nil;
        assert(not pcall(init, 0));
        debug = tDebug;
        assert(luaex == nil);
        init(0);
    else
        local tEnvironment = init(vLevel);
        assert(tEnvironment == luaex and LUAEX_INIT and not luaex.__isbooting);
        assert((class ~= nil) == (vLevel >= 1));
        assert((Stack ~= nil) == (vLevel >= 2));
        assert((Protean ~= nil) == (vLevel >= 3));
        assert((VFS ~= nil) == (vLevel >= 4));
        assert(luaex._VERSION == "LuaEx 0.62");
        assert(CoG == nil and Dox == nil);
        assert(init(99) == tEnvironment);
    end

    assert(package.path == sPath);
    print("PASS loader "..tostring(vLevel)..": initialization, validation, dependencies and path restoration.");
end

return run;
