--[[!
@fqxn LuaEx.LXC.Context
@desc <h3>Context — responsibility and connections</h3><p>Answers which class authored the currently executing
    code. Environment registers each compiled class environment; Context inspects function environments on the
    call stack and skips trusted service frames. Runtime, Helpers and persistence use this lexical identity to
    check access rather than trusting how a function was obtained.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.Context.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@ret table Service returned by this module.
@vis internal
!]]
return function()
    local __lxc_guard <close> = nil;
    local Context = {};
    local tScopes = setmetatable({}, {__mode = 'k'});
    local tCache = setmetatable({}, {__mode = 'k'});
    local tInternal = setmetatable({}, {__mode = 'k'});
    local fInfo, fUpvalue = debug.getinfo, debug.getupvalue;

    
    --[[!
    @fqxn LuaEx.LXC.Context.register
    @desc Associates a compiled environment with its declaring class. Environment.create registers it so
        caller() can recognize ownership through the function's _ENV upvalue.
    @param table tScope Class environment supplied to compilation or registered for lexical ownership.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @ret nil No return value; updates a weak-key map.
    @vis internal
    !]]
    function Context.register(tScope, tClass)
        local __lxc_guard <close> = nil;
        tScopes[tScope] = tClass;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Context.internal
    @desc Marks a trusted service frame for caller() to skip. Returns the same function for wrapping; this
        registration does not grant application code class privileges.
    @param function fFunction Function identity to register or recognize.
    @ret function fFunction Original function identity.
    @vis internal
    !]]
    function Context.internal(fFunction)
        local __lxc_guard <close> = nil;
        tInternal[fFunction] = true;
        return fFunction;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Context.owns
    @desc Recognizes an internal function or compiled function with a registered class _ENV. Host serialization
        uses this to reject exporting runtime/class closures as application code.
    @param function fFunction Function identity to register or recognize.
    @ret boolean bOwned Whether this context owns the function.
    @vis internal
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
    @fqxn LuaEx.LXC.Context.caller
    @desc Walks past C/trusted frames to the first application Lua function and returns its registered class,
        otherwise nil. An erased internal tail caller stops the search rather than borrowing a distant frame's
        privilege.
    @ret table|nil tClass Declaring definition, or nil for external/unrecoverable callers.
    @vis internal
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
