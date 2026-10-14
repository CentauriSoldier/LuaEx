--LOCALIZATION
local tLuaEX            = rawget(_G, "luaex");
local rawtype           = rawtype;
local rawget            = rawget;
local pairs             = pairs;
local pcall             = pcall;
local fGetMetatable     = rawget(_G, "rawgetmetatable") or getmetatable;
local fSetMetatable     = rawget(_G, "rawsetmetatable") or setmetatable;

-- Save native operations before installing wrappers. These aliases bypass LuaEx
-- guards, but still respect Lua's __metatable locks; they are not debug bypasses.
rawgetmetatable = fGetMetatable;
rawsetmetatable = fSetMetatable;

--[[!
    @fqxn LuaEx.Lua Hooks.metatable.Helpers.isGuarded
    @desc Checks an accessible metatable for explicit guard opt-in and a registered type name.
    @param any vMeta Native getter result, possibly a protected sentinel.
    @ret boolean bGuarded Whether LuaEx guard policy applies.
    @scope local
!]]
local function isGuarded(vMeta)

    -- Step 1: native protection may return false, a string or another sentinel.
    if (rawtype(vMeta) ~= "table" or rawget(vMeta, "__metaguard") ~= true) then
        return false;
    end

    -- Step 2: match string type names against the initialized guard registry.
    local sType = rawget(vMeta, "__type");

    if (rawtype(sType) == "string") then
        for _, sName in pairs(tLuaEX.__metaguard) do
            if (sType == sName) then
                return true;
            end
        end
    end

    return false;
end


--[[!
    @fqxn LuaEx.Lua Hooks.getmetatable
    @pulsarlua function getmetatable
    @desc Preserves native lookup semantics except for accessible LuaEx guarded metatables,
    which return a fresh identity-only view. Native __metatable sentinels remain unchanged.
    @param any vInput Value whose metatable is requested.
    @ret any vMeta Native result or guarded identity view; nil when no metatable exists.
!]]
function getmetatable(vInput)

    -- Step 1: obtain the native result without recursively calling this wrapper.
    local vMeta = fGetMetatable(vInput);

    if (isGuarded(vMeta)) then
        -- Step 2: expose only identity fields, never mutable implementation members.
        return {
            __type      = rawget(vMeta, "__type"),
            __subtype   = rawget(vMeta, "__subtype"),
            __name      = rawget(vMeta, "__name"),
        };
    end

    return vMeta;
end


--[[!
    @fqxn LuaEx.Lua Hooks.sealmetatable
    @pulsarlua function sealmetatable
    @desc Protects a table using __metatable=false, creating a metatable if needed.
    Returns true when sealed, including an existing false sentinel. Other protected
    metatables and non-table inputs return false without modifying their protection.
    @param table tInput Table to seal.
    @ret boolean bSealed Whether the table is sealed with a false sentinel.
!]]
function sealmetatable(tInput)

    -- Step 1: this utility seals table objects only.
    if (rawtype(tInput) ~= "table") then
        return false;
    end

    local vMeta = fGetMetatable(tInput);

    if (vMeta == false) then
        return true;
    end

    if (vMeta ~= nil and rawtype(vMeta) ~= "table") then
        return false;
    end

    -- Step 2: verify replacement is permitted BEFORE changing the returned table.
    -- A table-valued __metatable sentinel is not necessarily the real metatable.
    local tMeta = vMeta or {};
    local bAllowed = pcall(fSetMetatable, tInput, tMeta);

    if (not bAllowed) then
        return false;
    end

    -- Step 3: lock future native/public replacement while retaining existing behavior.
    tMeta.__metatable = false;
    return true;
end


--[[!
    @fqxn LuaEx.Lua Hooks.setmetatable
    @pulsarlua function setmetatable
    @desc Rejects replacement/removal of LuaEx guarded metatables. Otherwise delegates to
    native setmetatable, preserving its validation, __metatable locks and return value.
    @param table tInput Table whose metatable is being changed.
    @param table|nil tMeta New metatable, or nil to remove it.
    @ret table tInput The supplied table after successful replacement.
!]]
function setmetatable(tInput, tMeta)

    -- Step 1: enforce LuaEx policy only when native lookup exposes a guarded metatable.
    local vCurrent = fGetMetatable(tInput);

    if (isGuarded(vCurrent)) then
        error("Attempt to modify guarded object metatable: "..rawget(vCurrent, "__type")..".", 2);
    end

    -- Step 2: let Lua enforce argument types and existing native protection.
    return fSetMetatable(tInput, tMeta);
end
