--[[!
@fqxn LuaEx.LXC.GraphClone
@desc <h3>GraphClone — responsibility and connections</h3><p>Copies live graphs while preserving shared
    references and cycles. Runtime supplies allocation without constructors; SnapshotHooks validates automatic
    copies. Unlike a text round trip, live copies can retain function identities, invoke a clone operator and
    delegate foreign values to the host cloner. Nested calls share one coroutine-local session.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
@field function Fallback Original host cloner injected by Host.install for unsupported foreign values.
!]]

--[[!
@fqxn LuaEx.LXC.GraphClone.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Model Private injected dependency; its role is described in the module map.
@param table Context Private injected dependency; its role is described in the module map.
@param table Runtime Private injected dependency; its role is described in the module map.
@param table Hooks Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Model, Context, Runtime, Hooks)
    local Copy = {};
    local tClasses, tObjects, _, fAllocate, oNull, fInvoke = Runtime.services();
    local tSessions = setmetatable({}, {__mode = 'k'});
    local fCopy;

    
    --[[!
    @fqxn LuaEx.LXC.GraphClone.remember
    @desc Stores source-to-copy identity before recursion and records automatically allocated states for failure
        invalidation. Repeated references reuse this copy.
    @param table tSession Active graph copy/export identity and rollback bookkeeping.
    @param any vSource Original identity being copied.
    @param any vCopy Copy identity associated with a source.
    @param table|nil tOwnedState Automatic copy state to invalidate on rollback, if any.
    @ret nil No return value; updates session identity records.
    @vis internal
    !]]
    local function fRemember(tSession, vSource, vCopy, tOwnedState)
        if (not tSession.Seen[vSource]) then
            tSession.Records[#tSession.Records + 1] = {Source = vSource, State = tOwnedState};
        end
        tSession.Seen[vSource] = vCopy;
    end

    
    --[[!
    @fqxn LuaEx.LXC.GraphClone.rollback
    @desc Removes identities, active hooks and pending validators added after the call checkpoints; marks new
        automatic instances failed. Application side effects inside custom hooks cannot be undone.
    @param table tSession Active graph copy/export identity and rollback bookkeeping.
    @param number nRecords Identity-record checkpoint at copy-call entry.
    @param number nActive Active-hook checkpoint at copy-call entry.
    @param number nValidators Pending-validator checkpoint at copy-call entry.
    @ret nil No return value; rolls back session bookkeeping.
    @vis internal
    !]]
    local function fRollback(tSession, nRecords, nActive, nValidators)
        for n = #tSession.Records, nRecords + 1, -1 do
            local tRecord = tSession.Records[n];
            if (tRecord.State) then tRecord.State.Failed = true; end
            tSession.Seen[tRecord.Source], tSession.Records[n] = nil, nil;
        end
        for n = #tSession.ActiveOrder, nActive + 1, -1 do
            tSession.Active[tSession.ActiveOrder[n]], tSession.ActiveOrder[n] = nil, nil;
        end
        for n = #tSession.Validate, nValidators + 1, -1 do tSession.Validate[n] = nil; end
    end

    
    --[[!
    @fqxn LuaEx.LXC.GraphClone.registerCopy
    @desc Registers a distinct same-concrete-class copy from the source's active clone hook. Register before
        recursively cloning contents that lead back to the source. Only the hook's declaring class scope may
        register.
    @param table oSource Source LXC instance with an active custom clone hook.
    @param table oCopy Distinct same-concrete-class copy of the source.
    @ret nil No return value; stores source/copy identity.
    @vis internal
    !]]
    function Copy.registerCopy(oSource, oCopy)
        local __lxc_guard <close> = nil;
        local tSession = assert(tSessions[coroutine.running()], 'No active LXC copy.');
        local tHook = assert(tSession.Active[oSource], 'registerCopy requires an active source clone hook.');
        assert(Model.allowed('private', tHook.Owner, Context.caller()), 'Only the declaring clone hook can register its copy.');
        assert(tObjects[oCopy] and tObjects[oCopy].Class == tObjects[oSource].Class, 'Clone must preserve concrete class identity.');
        assert(not rawequal(oSource, oCopy), 'Instance clones require a distinct instance.');
        assert(not tSession.Seen[oSource] or rawequal(tSession.Seen[oSource], oCopy), 'Conflicting registered copy.');
        fRemember(tSession, oSource, oCopy);
    end
    Context.internal(Copy.registerCopy);

    
    --[[!
    @fqxn LuaEx.LXC.GraphClone.instance
    @desc Runs the selected clone operator or allocates storage without constructors. Custom copies must be
        distinct and preserve concrete class. Automatic copies retain slot types/locks and defer validation
        until the root graph is complete.
    @param table oSource Source LXC instance with an active custom clone hook.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tSession Active graph copy/export identity and rollback bookkeeping.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @ret table oCopy Copied instance reference.
    @vis internal
    !]]
    local function fInstance(oSource, tState, tSession, tCaller)
        assert(not tState.Failed and not tState.Class.Discarded and not tState.Constructing, 'Cannot clone incomplete or failed state.');
        assert(not tSession.Active[oSource], 'Cyclic custom clone: register the copy before copying its contents.');
        local tHook = Hooks.find(tState.Class, '__clone');
        if (tHook) then
            tSession.Active[oSource] = tHook;
            tSession.ActiveOrder[#tSession.ActiveOrder + 1] = oSource;
            local oCopy = fInvoke(tState, tHook);
            assert(tObjects[oCopy] and tObjects[oCopy].Class == tState.Class, 'Clone hook must preserve concrete class identity.');
            assert(not rawequal(oSource, oCopy), 'Instance clones require a distinct instance.');
            assert(not tSession.Seen[oSource] or rawequal(tSession.Seen[oSource], oCopy), 'Clone hook returned a different registered copy.');
            fRemember(tSession, oSource, oCopy);
            tSession.Active[oSource] = nil;
            return oCopy;
        end

        local tCopy = fAllocate(tState.Class);
        fRemember(tSession, oSource, tCopy.Object, tCopy);
        tSession.Validate[#tSession.Validate + 1] = tCopy;
        for tMember, tSlot in pairs(tState.Values) do
            tCopy.Values[tMember] = {Member = tMember, Type = tSlot.Type, Locked = tSlot.Locked,
                Value = fCopy(tSlot.Value, tSession, tMember.Owner), State = tCopy};
        end
        return tCopy.Object;
    end

    --[[!
    @fqxn LuaEx.LXC.GraphClone.copy
    @desc Preserves null/scalars/function identities, retains accessible class references, reuses known copies,
        copies instances/plain tables, then delegates foreign values to the host fallback. Keys and cycles
        participate in the same identity map.
    @param any vValue Value to inspect, assign, copy or serialize.
    @param table tSession Active graph copy/export identity and rollback bookkeeping.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @ret any vCopy Copied value or shared immutable/class identity.
    @vis internal
    !]]
    fCopy = function(vValue, tSession, tCaller)
        if (rawequal(vValue, oNull)) then return oNull; end
        local tClass = tClasses[vValue];
        if (tClass) then
            assert(not tClass.Discarded and Model.visible(tClass, tCaller), 'Cannot clone inaccessible class reference.');
            return vValue;
        end
        local sType = type(vValue);
        if (sType == 'nil' or sType == 'string' or sType == 'number' or sType == 'boolean' or sType == 'function') then return vValue; end
        if (tSession.Seen[vValue]) then return tSession.Seen[vValue]; end
        if (tObjects[vValue]) then return fInstance(vValue, tObjects[vValue], tSession, tCaller); end

        if (sType == 'table' and (getmetatable(vValue) == nil or tSession.IgnoreMetatable)) then
            local tCopy = {};
            fRemember(tSession, vValue, tCopy);
            for k, v in pairs(vValue) do tCopy[fCopy(k, tSession, tCaller)] = fCopy(v, tSession, tCaller); end
            return tCopy;
        end
        assert(Copy.Fallback, 'Unsupported foreign clone value: '..sType);
        local vCopy = Copy.Fallback(vValue, tSession.IgnoreMetatable);
        fRemember(tSession, vValue, vCopy);
        return vCopy;
    end;

    
    --[[!
    @fqxn LuaEx.LXC.GraphClone.clone
    @desc Copies a root in a coroutine-local session shared by nested calls. Root completion validates automatic
        copies and marks them ready; failures roll back work added by the failing call.
    @param any vValue Value to inspect, assign, copy or serialize.
    @param boolean|nil bIgnoreMetatable Optional copy flag; true treats eligible foreign tables as plain data.
    @ret any vCopy Copied root.
    @vis internal
    !]]
    function Copy.clone(vValue, bIgnoreMetatable)
        local __lxc_guard <close> = nil;
        assert(bIgnoreMetatable == nil or type(bIgnoreMetatable) == 'boolean', 'Ignore-metatable option must be boolean.');
        local oThread = coroutine.running();
        local tSession = tSessions[oThread];
        local bRoot = tSession == nil;
        if (bRoot) then
            tSession = {Seen = {}, Active = {}, Validate = {}, Records = {}, ActiveOrder = {}, IgnoreMetatable = bIgnoreMetatable == true};
            tSessions[oThread] = tSession;
        end
        local nRecords, nActive, nValidators = #tSession.Records, #tSession.ActiveOrder, #tSession.Validate;
        local bOK, vResult = pcall(fCopy, vValue, tSession, Context.caller());
        if (bRoot) then
            if (bOK) then
                bOK, vResult = pcall(function()
                    for _, tState in ipairs(tSession.Validate) do Hooks.validate(tState); end
                    for _, tState in ipairs(tSession.Validate) do tState.Ready = true; end
                    return vResult;
                end);
            end
            tSessions[oThread] = nil;
        end
        if (not bOK) then
            fRollback(tSession, nRecords, nActive, nValidators);
            error(vResult, 0);
        end
        return vResult;
    end
    Context.internal(Copy.clone);

    
    --[[!
    @fqxn LuaEx.LXC.GraphClone.active
    @desc Checks whether this coroutine already has an LXC copy session. Host uses it to retain nested graph
        identity.
    @ret boolean bActive Whether a session exists.
    @vis internal
    !]]
    function Copy.active() return tSessions[coroutine.running()] ~= nil; end
    return Copy;
end;
