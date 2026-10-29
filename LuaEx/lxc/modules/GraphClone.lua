--[[!
@fqxn LXC.GraphClone
@desc Constructor-free object/table copying with one coroutine-local graph map.
    Explicit clone hooks own their copy policy and register shells before cycles.
    Callback functions retain identity, matching LuaEx's existing clone contract;
    cloning does not serialize code or inspect captured function environments.
!]]
return function(Model, Context, Runtime, Hooks)
    local Copy = {};
    local tClasses, tObjects, _, fAllocate, oNull, fInvoke = Runtime.services();
    local tSessions = setmetatable({}, {__mode = 'k'});
    local fCopy;

    --[[!
    @fqxn LXC.GraphClone.remember
    @desc Records graph shells so a caught nested failure can discard its own
        entries without invalidating an enclosing clone traversal.
    !]]
    local function fRemember(tSession, vSource, vCopy, tOwnedState)
        if (not tSession.Seen[vSource]) then
            tSession.Records[#tSession.Records + 1] = {Source = vSource, State = tOwnedState};
        end
        tSession.Seen[vSource] = vCopy;
    end

    --[[!
    @fqxn LXC.GraphClone.rollback
    @desc Invalidates engine-allocated incomplete instances and removes graph
        records created after the failed call's checkpoint.
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
    @fqxn LXC.GraphClone.registerCopy
    @desc Lets the executing declaring-class clone hook register its own shell.
        External callbacks cannot register a replacement into a privileged copy.
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
    @fqxn LXC.GraphClone.instance
    @desc Uses an explicit class hook, or allocates/copies typed slots directly.
        Generic copies run snapshot validators after the complete graph is built.
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
    @fqxn LXC.GraphClone.clone
    @desc Starts or joins a copy graph. Each entry determines its actual caller;
        a nested external callback never borrows the outer caller's scope.
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
    @fqxn LXC.GraphClone.active
    @desc Reports whether registerCopy belongs to this runtime's copy traversal.
    !]]
    function Copy.active() return tSessions[coroutine.running()] ~= nil; end
    return Copy;
end;
