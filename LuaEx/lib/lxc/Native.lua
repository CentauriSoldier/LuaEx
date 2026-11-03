--[[!
@fqxn LuaEx.LXC.Native
@desc Loads optional Lua 5.4 acceleration without replacing class identity, storage or
    language services. Missing/incompatible modules leave the existing Lua runtime active.
    LXC_NATIVE_BACKEND=lua supplies a fresh-process comparison control.
@vis internal
!]]
local Native = {Available = false};
if (os.getenv('LXC_NATIVE_BACKEND') == 'lua') then return Native; end
local pModule = os.getenv('LXC_HYBRID_MODULE');
if (not pModule and package.config:sub(1, 1) == '\\') then
    local pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
    local pRoot = pSource:match('^(.*)/lib/lxc/Native%.lua$');
    if (pRoot) then pModule = pRoot..'/bin/lxc_native-lua54-windows-x64.dll'; end
end
if (not pModule or not package.loadlib) then return Native; end
local fOpen, sReason = package.loadlib(pModule, 'luaopen_lxc_hybrid');
if (not fOpen) then Native.Reason = sReason; return Native; end
local bOK, tModule = pcall(fOpen);
if (not bOK or type(tModule) ~= 'table' or tModule.Version ~= 1 or
    tModule.Available ~= true or type(tModule.setter) ~= 'function' or
    type(tModule.dispatchers) ~= 'function') then
    Native.Reason = bOK and 'Unsupported native LXC interface.' or tModule;
    return Native;
end
return tModule;
