--[[!
@fqxn LXC.Persistence
@desc Versioned graph snapshots and independent cloning. Decoder reads only a
    restricted literal grammar for standalone calls. The private host adapter
    delegates supported functions/foreign values to LuaEx's existing serializer.
    Class definitions must already be registered.
!]]
return function(Model, Context, Runtime, Literal, Schema, GraphAccess, Hooks)
    local __lxc_guard <close> = nil;
    local Codec = {};
    local tClasses, tObjects, fWrite, fAllocate, oNull = Runtime.services();

    --[[!
    @fqxn LXC.Persistence.fields
    @desc Collects original instance or static storage declarations across an inheritance chain.
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
    @fqxn LXC.Persistence.fieldKey
    @desc Builds a qualified storage identity so reused private names remain distinct in snapshots.
    !]]
    local function fFieldKey(tMember)
        local __lxc_guard <close> = nil;
        return tMember.Owner.FullName..':'..tMember.Name;
    end

    --[[!
    @fqxn LXC.Persistence.project
    @desc Supplies one class-owned state projection to the host's staged graph.
        Values retain source identities; the existing serializer owns graph encoding.
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
    @fqxn LXC.Persistence.checkGraph
    @desc Preflights host graph structure and class-reference authority before allocation.
    !]]
    function Codec.checkGraph(tGraph, tCaller)
        local __lxc_guard <close> = nil;
        Schema.validate(tGraph, true);
        GraphAccess.validate(tGraph, tCaller);
    end

    --[[!
    @fqxn LXC.Persistence.stage
    @desc Allocates an unpublished class identity without constructors or initializers.
    !]]
    function Codec.stage(tNode)
        local __lxc_guard <close> = nil;
        local tClass = assert(Model.Classes[tNode.Class], 'Missing saved class.');
        if (tNode.Kind == 'class') then return tClass.Object; end
        assert(tNode.Kind == 'instance' and not tClass.Flags.abstract, 'Invalid instance class.');
        return fAllocate(tClass).Object;
    end

    --[[!
    @fqxn LXC.Persistence.snapshot
    @desc Encodes values by graph identity, including cycles through class state.
    !]]
    function Codec.snapshot(vRoot, tHost)
        local __lxc_guard <close> = nil;
        local tGraph, tSeen, tDefinitions, tPending = {Version = 1, Nodes = {}}, {}, {}, {};
        local fEncode;
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
    @fqxn LXC.Persistence.restore
    @desc Allocates graph shells, then validates typed storage without constructors.
        Unpublished shells are never returned when any validation step fails.
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
    @fqxn LXC.Persistence.serialize
    @param any vValue Supported application value or instance graph.
    @ret string Versioned state data; private field contents remain sensitive.
    !]]
    function Codec.serialize(vValue)

           local __lxc_guard <close> = nil;
        local sSource = Literal.encode(Codec.snapshot(vValue));
        assert(#sSource <= 16 * 1024 * 1024, 'Snapshot text limit exceeded.');
        return sSource;
    end

    --[[!
    @fqxn LXC.Persistence.deserialize
    @param string sSource Restricted literal snapshot text.
    @ret any Validated restored graph, without constructor execution.
    !]]
    function Codec.deserialize(sSource)

           local __lxc_guard <close> = nil;
        return Codec.restore(Literal.decode(sSource));
    end
    --[[!
    @fqxn LXC.Persistence.clone
    @desc Copies a supported graph through validated shells, preserving concrete classes and internal aliases.
    !]]
    function Codec.clone(vValue)
        local __lxc_guard <close> = nil;
        return Codec.restore(Codec.snapshot(vValue));
    end

    -- Static snapshots intentionally include only fields accessible at the use site.
    --[[!
    @fqxn LXC.Persistence.saveStatic
    @desc Exports only caller-accessible mutable static fields; readonly fields remain declaration-owned.
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
    @fqxn LXC.Persistence.loadStatic
    @desc Validates all supplied static updates against access/types/locks before committing any write.
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
