--[[!
@fqxn LXC
@desc Standalone Lua 5.4 class-system entry point. Composes focused modules using
    paths relative to this file, without changing package.path or LuaEx files.
!]]
local _pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
local _pRoot = _pSource:match('^(.*)/[^/]+$') or '.';

-- Freeze trusted runtime dependencies before application code can replace
-- globals such as assert/rawget or table/string operations. Application bodies
-- still receive the caller-supplied environment, not this private snapshot.
local _rawType = rawtype or type;
local _loadFile = loadfile;
local _tFacades = debug.getregistry()['LXC.Facades.TableDecoys'];
local _tRuntimeEnvironment = {};
for sName, vValue in pairs(_G) do
    if (_rawType(vValue) == 'table' and not rawequal(vValue, _G) and
        not (_tFacades and _tFacades.owns(vValue))) then
        local tCopy = {};
        for k, v in pairs(vValue) do tCopy[k] = v; end
        _tRuntimeEnvironment[sName] = tCopy;
    else
        _tRuntimeEnvironment[sName] = vValue;
    end
end
_tRuntimeEnvironment.type = _rawType;

--[[!
@fqxn LXC.module
@desc Loads a private module factory; runtime registries stay in factory closures.
@param string sName Module basename in modules/.
@ret any The loaded module or factory.
!]]
local function module(sName)
    return assert(_loadFile(_pRoot..'/modules/'..sName..'.lua', 't', _tRuntimeEnvironment))();
end

-- Reuse LuaEx's existing null singleton when initialized by the framework.
-- Standalone use keeps LXC's own opaque placeholder.
local _oHostNull = rawget(_G, 'luaex') and _G.luaex.null or nil;
return module('Loader')(module, _oHostNull);
