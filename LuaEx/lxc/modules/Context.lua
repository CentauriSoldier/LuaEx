--[[!
@fqxn LXC.Context
@desc Factory for private lexical access-context registries. The actual Lua
    caller's compiled environment establishes rights, not an ambient privileged
    stack. External callbacks therefore cannot borrow the invoker's rights.
!]]
return function()
    local __lxc_guard <close> = nil;
    local Context = {};
    local tScopes = setmetatable({}, {__mode = 'k'});
    local tCache = setmetatable({}, {__mode = 'k'});
    local tInternal = setmetatable({}, {__mode = 'k'});
    local fInfo, fUpvalue = debug.getinfo, debug.getupvalue;

    --[[!
    @fqxn LXC.Context.register
    @desc Associates an inaccessible compiler environment with its declaring class.
    !]]
    function Context.register(tScope, tClass)
        local __lxc_guard <close> = nil;
        tScopes[tScope] = tClass;
    end

    --[[!
    @fqxn LXC.Context.internal
    @desc Marks trusted runtime functions that do not establish application rights.
    !]]
    function Context.internal(fFunction)
        local __lxc_guard <close> = nil;
        tInternal[fFunction] = true;
        return fFunction;
    end

    --[[!
    @fqxn LXC.Context.owns
    @desc Prevents host closure serialization from inspecting private runtime
        functions or compiled class environments as ordinary application code.
    !]]
    function Context.owns(fFunction)
        if (tInternal[fFunction]) then return true; end
        local nIndex = 1;
        while (true) do
            local sName, vValue = fUpvalue(fFunction, nIndex);
            if (not sName) then return false; end
            if (sName == '_ENV' and tScopes[vValue]) then return true; end
            nIndex = nIndex + 1;
        end
    end

    --[[!
    @fqxn LXC.Context.caller
    @desc Finds the first non-runtime Lua caller and caches its lexical owner.
        Stops at external code; never searches past it for a privileged ancestor.
        Works after yields/errors without global scope push/pop bookkeeping.
    @ret table|nil Internal declaring class, or nil for external application code.
    !]]
    function Context.caller()
        local __lxc_guard <close> = nil;
        local nLevel = 2;
        while (true) do
            local tInfo = fInfo(nLevel, 'fSt');
            if (not tInfo) then return; end
            local fFunction = tInfo.func;
            -- A tail call erased its caller. Compiled class functions retain
            -- their frames; an erased caller cannot supply class privileges.
            if (tInfo.istailcall and tInternal[fFunction]) then return; end
            if (tInfo.what ~= 'C' and not tInternal[fFunction]) then
                local vCached = tCache[fFunction];
                if (vCached ~= nil) then return vCached or nil; end
                local nIndex, tOwner = 1;
                while (true) do
                    local sName, vValue = fUpvalue(fFunction, nIndex);
                    if (not sName) then break; end
                    if (sName == '_ENV') then tOwner = tScopes[vValue]; break; end
                    nIndex = nIndex + 1;
                end
                tCache[fFunction] = tOwner or false;
                return tOwner;
            end
            nLevel = nLevel + 1;
        end
    end
    tInternal[Context.caller] = true;
    return Context;
end;
