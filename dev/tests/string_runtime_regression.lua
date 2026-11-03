--[[!
@fqxn Tests.StringRuntime
@desc Verifies class/enum runtime operations use captured string functions without
    changing application string behavior. All replacements are restored on failure.
!]]
if (not LUAEX_INIT) then require("LuaEx.init"); end
local _nChecks = 0;
local _string = string;
local _traceback = debug.traceback;
local _tMethods = {"match", "gmatch", "gsub", "sub", "find", "lower", "upper", "byte", "len", "rep", "format"};
local _tOriginal = {};
for _, sName in ipairs(_tMethods) do _tOriginal[sName] = _string[sName]; end
local _tMetatable = getmetatable("");
local _vOriginalIndex = _tMetatable.__index;
local _nReplacementCalls = 0;
local function check(bCondition, sMessage)
    assert(bCondition, sMessage);
    _nChecks = _nChecks + 1;
end
local function replacement()
    _nReplacementCalls = _nReplacementCalls + 1;
    error("Application string replacement invoked.", 2);
end

local pSource = _tOriginal.sub(debug.getinfo(1, "S").source, 2);
local pRoot = assert(_tOriginal.match(_tOriginal.gsub(pSource, "\\", "/"), "^(.*)/tests/[^/]+$"));
local fScanFiles = io.scanfiles;
local bCreated, Fresh = pcall(function() return assert(loadfile(pRoot.."/LuaEx/lib/lxc.lua"))(); end);
assert(bCreated, Fresh);

lxc.loadSources({["StringRuntimeSaved.lxc"] = [[namespace StringRuntimeSaved {
    class Item { public value = 23; }
    public enum Color { RED = 1; }
}]]}, _G);
local _sSavedClass = serialize(StringRuntimeSaved.Item());
local _sSavedEnum = serialize(StringRuntimeSaved.Color.RED);

-- Keep an ordinary application callback outside the captured runtime environment.
local Host = setmetatable({}, {__index = _G});
for nCase, sMode in ipairs({"metatable", "functions", "both"}) do
    local sNamespace = "StringIsolation"..nCase;
    local sClassSource = "namespace "..sNamespace..[[ {
        ---@default
        class Item { public read() { return -1; } }
        class Item {
            ---@type number
            private value = 17;
            public read() { return this.value; }
            public applicationString() { return ("text"):sub(1, 1); }
        }
    }]];
    local sEnumSource = "namespace "..sNamespace.." { public enum Color { RED = 1; BLUE = 2; } }\n"..
        "extension "..sNamespace..".Color.label(this) { return this.Name; }";
    local nBefore = _nReplacementCalls;
    if (sMode == "functions" or sMode == "both") then
        for _, sName in ipairs(_tMethods) do _string[sName] = replacement; end
    end
    if (sMode == "metatable" or sMode == "both") then _tMetatable.__index = replacement; end

    io.scanfiles = function()
        return {"virtual/runtime.lxc", "virtual/runtime.lxe"}, nil, {Roots = {}, Directories = 1};
    end;
    local bOK, sReason = xpcall(function()
        -- This standalone registry must not attach to the host's enum service.
        local LXE = package.loaded["LuaEx.lib.lxe"];
        package.loaded["LuaEx.lib.lxe"] = nil;
        local bLoaded, sLoadError = pcall(Fresh.loadSources, {["isolated.lxc"] = sClassSource}, Host);
        package.loaded["LuaEx.lib.lxe"] = LXE;
        assert(bLoaded, sLoadError);
        lxc.loadSources({["isolated.lxe"] = sEnumSource}, Host);
        local Item = Host[sNamespace].Item;
        local object = Item();
        check(object.read() == 17, "Selected class and typed field load");
        local copy = Fresh.clone(object);
        check(copy.read() == 17 and not rawequal(copy, object), "Cloning retains state");
        local restored = Fresh.deserialize(Fresh.serialize(object));
        check(restored.read() == 17, "Standalone snapshot round trip");
        local Color = Host[sNamespace].Color;
        check(Color.RED:label() == "RED" and Color.BLUE.Value == 2, "Enum loading and extension dispatch");
        local files = Fresh.discover("virtual/?.lua");
        check(#files == 1 and files[1] == "virtual/runtime.lxc", "Class discovery uses captured operations");
        local bDiscovered, tEnums = pcall(lxe.discover, "virtual/?.lua");
        check(bDiscovered and #tEnums == 1 and tEnums[1] == "virtual/runtime.lxe", "Enum discovery uses captured operations");
        check(deserialize(_sSavedClass).value == 23, "Host class snapshot remains readable");
        check(rawequal(deserialize(_sSavedEnum), StringRuntimeSaved.Color.RED), "Canonical enum restoration remains readable");
        local bAccepted = pcall(lxc.loadSources, {["bad.lxc"] = "namespace Broken { class Item { public value = ; } }"}, Host);
        check(not bAccepted, "Invalid source remains rejected");
        check(_nReplacementCalls == nBefore, "Runtime never called application replacements");
        check(not pcall(object.applicationString), "Application code still sees its own string changes");
    end, _traceback);

    io.scanfiles = fScanFiles;
    _tMetatable.__index = _vOriginalIndex;
    for _, sName in ipairs(_tMethods) do _string[sName] = _tOriginal[sName]; end
    check(bOK, sMode..": "..tostring(sReason));
end
check(("normal"):sub(1, 1) == "n", "Application string operations restored");
print("PASS captured string runtime: ".._nChecks.." checks.");
