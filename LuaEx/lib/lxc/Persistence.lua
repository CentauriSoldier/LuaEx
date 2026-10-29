--[[!
@fqxn LuaEx.LXC.Persistence
@desc <h3>Persistence — responsibility and connections</h3><p>Projects class identities and private instance
    storage into graphs and restores them without constructors. Each field keeps its declaring owner, type and
    const/final binding locks. Literal handles standalone text, SnapshotSchema checks shape, GraphAccess checks
    access and SnapshotHooks prepares/validates state. Host adapters extend graphs with foreign values and
    functions.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.Persistence.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Model Private injected dependency; its role is described in the module map.
@param table Context Private injected dependency; its role is described in the module map.
@param table Runtime Private injected dependency; its role is described in the module map.
@param table Literal Private injected dependency; its role is described in the module map.
@param table Schema Private injected dependency; its role is described in the module map.
@param table GraphAccess Private injected dependency; its role is described in the module map.
@param table Hooks Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Model, Context, Runtime, Literal, Schema, GraphAccess, Hooks)
    local __lxc_guard <close> = nil;
    local Codec = {};
    local tClasses, tObjects, fWrite, fAllocate, oNull = Runtime.services();

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.fields
    @desc Collects actual storage declarations across ancestors for instance/static state; skips
        methods/overrides because overriding properties share original slots.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param boolean bStatic True for class storage/qualification, false for instance state.
    @ret table tMembers Storage-owning declarations, selected class first.
    @vis internal
    !]]
    local function fFields(tClass, bStatic)
        local __lxc_guard <close> = nil;
        local tResult = {};
        while (tClass) do
            for _, tMember in ipairs(tClass.Members) do
                if (tMember.Kind ~= 'method' and not tMember.Overrides and not not tMember.Flags.static == bStatic) then
                    tResult[#tResult + 1] = tMember;
                end
            end
            tClass = tClass.Parent;
        end
        return tResult;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.fieldKey
    @desc Builds qualified-owner:member keys to distinguish same-name private storage at different inheritance
        levels.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @ret string sKey Stable storage key.
    @vis internal
    !]]
    local function fFieldKey(tMember)
        local __lxc_guard <close> = nil;
        return tMember.Owner.FullName..':'..tMember.Name;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.project
    @desc Projects LXC class/instance state for host adapters; foreign values yield nil. Instance preparation
        runs hooks, retains types/locks and rejects failed/incomplete state.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret table|nil tNode Projection with live field values, or nil.
    @vis internal
    !]]
    function Codec.project(vValue)
        local __lxc_guard <close> = nil;
        local tClass, tState = tClasses[vValue], tObjects[vValue];
        if (tClass) then
            assert(not tClass.Discarded, 'Cannot save a discarded class.');
            return {Kind = 'class', Class = tClass.FullName};
        end
        if (not tState) then return; end
        assert(not tState.Failed and not tState.Class.Discarded and not tState.Constructing,
            'Cannot save incomplete or failed construction.');
        local tNode = {Kind = 'instance', Class = tState.Class.FullName, Fields = {}};
        local tPrepared = Hooks.prepare(tState);
        for _, tMember in ipairs(fFields(tState.Class, false)) do
            local tSlot = assert(tState.Values[tMember], 'Cannot save incomplete construction.');
            local vValue = tPrepared[tMember];
            if (vValue == nil) then vValue = tSlot.Value; end
            tNode.Fields[fFieldKey(tMember)] = {Value = vValue,
                Type = type(tSlot.Type) == 'table' and tSlot.Type.FullName or tSlot.Type,
                ClassType = type(tSlot.Type) == 'table', Locked = tSlot.Locked or false};
        end
        return tNode;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.checkGraph
    @desc Checks host-enabled schema then caller visibility without allocating or executing constructors.
    @param table tGraph Decoded Root/Nodes descriptor graph, not live instance state.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @ret nil No return value; raises on invalid shape/access.
    @vis internal
    !]]
    function Codec.checkGraph(tGraph, tCaller)
        local __lxc_guard <close> = nil;
        Schema.validate(tGraph, true);
        GraphAccess.validate(tGraph, tCaller);
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.stage
    @desc Retrieves a class or allocates a concrete instance shell from a header. Constructors do not run; later
        restore fills/validates storage.
    @param table tNode One graph/publication-tree node as described by this operation.
    @ret table vValue Class/instance reference.
    @vis internal
    !]]
    function Codec.stage(tNode)
        local __lxc_guard <close> = nil;
        local tClass = assert(Model.Classes[tNode.Class], 'Missing saved class.');
        if (tNode.Kind == 'class') then return tClass.Object; end
        assert(tNode.Kind == 'instance' and not tClass.Flags.abstract, 'Invalid instance class.');
        return fAllocate(tClass).Object;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.snapshot
    @desc Interns identities and fills graph records iteratively, preserving cycles, shared keys, null and
        instance storage. Host callbacks add foreign values/captures. Checks access and caps nodes at 100000.
    @param any vRoot Application graph root to export.
    @param table|nil tHost Optional host graph adapter; nil selects standalone graph handling.
    @ret table tGraph Version-one Root/Nodes graph.
    @vis internal
    !]]
    function Codec.snapshot(vRoot, tHost)
        local __lxc_guard <close> = nil;
        local tGraph, tSeen, tDefinitions, tPending = {Version = 1, Nodes = {}}, {}, {}, {};
        local fEncode;
        --[[!
        @fqxn LuaEx.LXC.Persistence.encode
        @desc Builds scalar/null/reference descriptors. Assigns complex IDs before visiting edges, preserving
            cycles; standalone numbers must be finite.
        @param any vValue Value to inspect, assign, copy or serialize.
        @ret table tDescriptor Encoded value.
        @vis internal
        !]]
        fEncode = function(vValue)
            local __lxc_guard <close> = nil;
            if (rawequal(vValue, oNull)) then return {Null = true}; end
            local sType = type(vValue);
            if (sType == 'number' and not tHost) then assert(vValue == vValue and math.abs(vValue) < math.huge, 'Nonfinite numbers are not supported by this codec.'); end
            if (sType == 'nil' or sType == 'boolean' or sType == 'number' or sType == 'string') then return {Value = vValue}; end
            if (tSeen[vValue]) then return {Ref = tSeen[vValue]}; end
            local nID, tNode = #tGraph.Nodes + 1, {};
            assert(nID <= 100000, 'Snapshot node limit exceeded.');
            tSeen[vValue], tGraph.Nodes[nID] = nID, tNode;
            tPending[nID] = vValue;
            if (tHost) then tHost.remember(vValue, nID); end
            return {Ref = nID};
        end;
        Context.internal(fEncode);

        -- Intern first, then fill shells through a worklist. Deep application
        -- graphs and cycles do not consume one Lua stack frame per graph edge.
        tGraph.Root = fEncode(vRoot);
        local nID = 1;
        while (nID <= #tGraph.Nodes) do
            local vValue, tNode = tPending[nID], tGraph.Nodes[nID];
            local sType = type(vValue);
            if (tClasses[vValue]) then
                local tClass = tClasses[vValue];
                assert(not tClass.Discarded, 'Cannot save a discarded class.');
                tDefinitions[tClass.FullName] = tClass;
                tNode.Kind, tNode.Class = 'class', tClass.FullName;
            elseif (tObjects[vValue]) then
                local tState = tObjects[vValue];
                tDefinitions[tState.Class.FullName] = tState.Class;
                assert(not tState.Failed and not tState.Class.Discarded, 'Cannot save failed construction or class load.');
                assert(not tState.Constructing, 'Cannot save incomplete construction.');
                tNode.Kind, tNode.Class, tNode.Fields = 'instance', tState.Class.FullName, {};
                local tPrepared = Hooks.prepare(tState);
                for _, tMember in ipairs(fFields(tState.Class, false)) do
                    local tSlot = assert(tState.Values[tMember], 'Cannot save incomplete construction.');
                    local vValue = tPrepared[tMember];
                    if (vValue == nil) then vValue = tSlot.Value; end
                    tNode.Fields[fFieldKey(tMember)] = {Value = fEncode(vValue),
                        Type = type(tSlot.Type) == 'table' and tSlot.Type.FullName or tSlot.Type,
                        ClassType = type(tSlot.Type) == 'table', Locked = tSlot.Locked or false};
                end
            elseif (sType == 'table' and getmetatable(vValue) == nil) then
                tNode.Kind, tNode.Entries = 'table', {};
                for k, v in pairs(vValue) do tNode.Entries[#tNode.Entries + 1] = {fEncode(k), fEncode(v)}; end
            elseif (tHost) then
                tNode.Kind, tNode.Value = 'host', vValue;
                tNode.Captures = tHost.inspect(vValue, fEncode);
            else error('Unsupported saved value: '..sType); end
            nID = nID + 1;
        end
        GraphAccess.validate(tGraph, Context.caller(), tDefinitions);
        return tGraph;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.restore
    @desc Validates schema/access, allocates identities before filling edges, restores exact fields/types/locks
        and reconnects host captures. Parent-first validation precedes Ready. Constructors never run.
    @param table tGraph Decoded Root/Nodes descriptor graph, not live instance state.
    @param table|nil tHost Optional host graph adapter; nil selects standalone graph handling.
    @ret any vRoot Restored root.
    @vis internal
    !]]
    function Codec.restore(tGraph, tHost)
        local __lxc_guard <close> = nil;
        Schema.validate(tGraph, tHost ~= nil);
        local tCaller = Context.caller();
        if (tHost and tHost.caller) then tCaller = tHost.caller(); end
        GraphAccess.validate(tGraph, tCaller);
        local tValues, tStates = {}, {};
        for nID, tNode in ipairs(tGraph.Nodes) do
            if (tNode.Kind == 'table') then tValues[nID] = tHost and tHost.table and tHost.table(nID) or {};
            elseif (tNode.Kind == 'host') then tValues[nID] = tNode.Value;
            else
                local tClass = assert(Model.Classes[tNode.Class], 'Missing saved class: '..tostring(tNode.Class));
                if (tNode.Kind == 'class') then
                    tValues[nID] = tClass.Object;
                else
                    assert(tNode.Kind == 'instance' and not tClass.Flags.abstract, 'Invalid instance class.');
                    local tState = tHost and tHost.allocate and tHost.allocate(nID, tClass) or fAllocate(tClass);
                    tValues[nID], tStates[nID] = tState.Object, tState;
                end
            end
        end
        --[[!
        @fqxn LuaEx.LXC.Persistence.decode
        @desc Resolves scalar/null/reference descriptors against allocated identities, returning exactly one
            value even when an assertion supplies a diagnostic.
        @param table tValue One encoded descriptor/metadata record to validate or translate.
        @ret any vValue Decoded value.
        @vis internal
        !]]
        local function fDecode(tValue)
            local __lxc_guard <close> = nil;
            assert(type(tValue) == 'table', 'Invalid graph value.');
            if (tValue.Null) then return oNull; end
            if (tValue.Ref) then
                -- assert returns its diagnostic argument too on success. Decode
                -- exactly one graph value, including in a final expression list.
                local vValue = assert(tValues[tValue.Ref], 'Invalid graph reference.');
                return vValue;
            end
            return tValue.Value;
        end
        for nID, tNode in ipairs(tGraph.Nodes) do
            if (tNode.Kind == 'table') then
                local tKeys = {};
                for _, tEntry in ipairs(tNode.Entries) do
                    local k, v = fDecode(tEntry[1]), fDecode(tEntry[2]);
                    assert(k ~= nil and v ~= nil, 'Invalid saved table entry.');
                    assert(not tKeys[k], 'Duplicate restored table key.'); tKeys[k] = true;
                    tValues[nID][k] = v;
                end
            elseif (tNode.Kind == 'instance') then
                local tState, tKnown = tStates[nID], {};
                for _, tMember in ipairs(fFields(tState.Class, false)) do
                    local sKey = fFieldKey(tMember);
                    local tSaved = assert(tNode.Fields[sKey], 'Missing saved field: '..sKey);
                    tKnown[sKey] = true;
                    local vType = tSaved.ClassType and assert(Model.Classes[tSaved.Type], 'Missing saved field class.') or tSaved.Type;
                    assert(not tSaved.ClassType or vType, 'Missing saved class constraint.');
                    assert(vType == nil or type(vType) == 'table' or vType == 'number' or vType == 'string' or
                        vType == 'boolean' or vType == 'table' or vType == 'class' or
                        (tHost and vType == 'function'), 'Unsupported field type.');
                    if (tMember.DeclaredType) then assert(vType == tMember.DeclaredType, 'Snapshot changes declared field type: '..sKey); end
                    local tSlot = {Member = tMember, Type = vType};
                    fWrite(tSlot, fDecode(tSaved.Value), true);
                    assert(tSlot.Type == vType, 'Snapshot value changes its saved type contract.');
                    if (tMember.Flags.const and tMember.ConstValue ~= nil) then assert(tSlot.Value == tMember.ConstValue, 'Snapshot changes const value.'); end
                    assert(not tMember.Flags.final or tSlot.Type, 'Uninitialized saved final.');
                    assert(not tMember.Flags.const or tSlot.Type, 'Uninitialized saved const.');
                    tSlot.Locked = tMember.Flags.final or tMember.Flags.const or false;
                    assert(tSaved.Locked == tSlot.Locked, 'Snapshot binding lock mismatch.');
                    tState.Values[tMember] = tSlot;
                end
                for sKey in pairs(tNode.Fields) do assert(tKnown[sKey], 'Unknown saved field: '..sKey); end
            end
        end
        if (tHost) then tHost.reconnect(tValues); end
        for _, tState in pairs(tStates) do Hooks.validate(tState, true); end
        for _, tState in pairs(tStates) do tState.Ready = true; end
        return fDecode(tGraph.Root);
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.serialize
    @desc Snapshots standalone finite scalars/null/plain tables/classes/instances. Foreign functions/metatable
        values need host serialization. Rejects encoded text above 16 MiB.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret string sSource Restricted snapshot literal.
    @vis internal
    !]]
    function Codec.serialize(vValue)

           local __lxc_guard <close> = nil;
        local sSource = Literal.encode(Codec.snapshot(vValue));
        assert(#sSource <= 16 * 1024 * 1024, 'Snapshot text limit exceeded.');
        return sSource;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.deserialize
    @desc Reads a restricted literal then restores against current registered definitions; does not evaluate
        arbitrary input chunks.
    @param string sSource Source text; the operation description specifies whether this is LXC, Lua or snapshot
        data.
    @ret any vRoot Restored standalone root.
    @vis internal
    !]]
    function Codec.deserialize(sSource)

           local __lxc_guard <close> = nil;
        return Codec.restore(Literal.decode(sSource));
    end
    
    --[[!
    @fqxn LuaEx.LXC.Persistence.clone
    @desc Internal standalone snapshot round trip. Public LXC.clone instead uses GraphClone with live custom
        copying/foreign delegation.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret any vCopy In-memory round-trip copy.
    @vis internal
    !]]
    function Codec.clone(vValue)
        local __lxc_guard <close> = nil;
        return Codec.restore(Codec.snapshot(vValue));
    end

    -- Static snapshots intentionally include only fields accessible at the use site.
    
    --[[!
    @fqxn LuaEx.LXC.Persistence.saveStatic
    @desc Saves caller-accessible mutable static storage across ancestry, omitting const/final. Saved class
        identities alone do not include static state.
    @param table oClass LXC class object selecting static state.
    @ret string sSource Qualified-field snapshot.
    @vis internal
    !]]
    function Codec.saveStatic(oClass)
        local __lxc_guard <close> = nil;
        local tClass = assert(tClasses[oClass], 'Expected class.');
        assert(Model.visible(tClass, Context.caller()), 'Inaccessible class.');
        local tValues = {};
        for _, tMember in ipairs(fFields(tClass, true)) do
            if (not tMember.Flags.const and not tMember.Flags.final and
                Model.allowed(tMember.Visibility, tMember.Owner, Context.caller())) then
                tValues[fFieldKey(tMember)] = tMember.Owner.Static[tMember].Value;
            end
        end
        return Codec.serialize(tValues);
    end

    
    --[[!
    @fqxn LuaEx.LXC.Persistence.loadStatic
    @desc Checks every supplied qualified-field update using trial slots before committing any. Rejects
        access/type/lock/unknown-field failures; omitted fields keep current values.
    @param table oClass LXC class object selecting static state.
    @param string sSource Source text; the operation description specifies whether this is LXC, Lua or snapshot
        data.
    @ret nil No return value; commits checked assignments.
    @vis internal
    !]]
    function Codec.loadStatic(oClass, sSource)
        local __lxc_guard <close> = nil;
        local tClass = assert(tClasses[oClass], 'Expected class.');
        assert(Model.visible(tClass, Context.caller()), 'Inaccessible class.');
        local tValues, tPlan = Codec.deserialize(sSource), {};
        assert(type(tValues) == 'table' and getmetatable(tValues) == nil, 'Static snapshot must contain a plain field map.');
        for _, tMember in ipairs(fFields(tClass, true)) do
            local sKey = fFieldKey(tMember);
            if (tValues[sKey] ~= nil) then
                assert(Model.allowed(tMember.Visibility, tMember.Owner, Context.caller()), 'Inaccessible static field.');
                local tSlot = tMember.Owner.Static[tMember];
                local tTrial = {Member = tMember, Type = tSlot.Type, Locked = tSlot.Locked};
                fWrite(tTrial, tValues[sKey], false);
                tPlan[#tPlan + 1] = {Slot = tSlot, Value = tValues[sKey]}; tValues[sKey] = nil;
            end
        end
        assert(next(tValues) == nil, 'Unknown static snapshot field.');
        for _, tChange in ipairs(tPlan) do fWrite(tChange.Slot, tChange.Value, false); end
    end

    for _, fFunction in pairs(Codec) do Context.internal(fFunction); end
    return Codec;
end;
