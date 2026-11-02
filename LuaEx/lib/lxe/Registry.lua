--[[!
@fqxn LuaEx.LXE.Registry
@desc Creates a private canonical registry per loader. Returned records stay internal;
    public lookup requires an enum object rather than an unrestricted name registry.
!]]
local Registry = {};

--[[!
@fqxn LuaEx.LXE.Registry.create
@desc Allocates a registry isolated from other loader instances.
@ret table Internal state containing canonical definitions and runtime weak keys.
!]]
function Registry.create()
    return {Definitions = {}, States = setmetatable({}, {__mode = "k"}), Loading = false};
end

return Registry;

