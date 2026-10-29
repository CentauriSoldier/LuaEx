--[[!
@fqxn LuaEx.LXC.HostStaged
@desc <h3>HostStaged — responsibility and connections</h3><p>Adapts LXC identities and storage to the LuaEx
    staged serializer. The host owns graph identities and application closure captures; this service supplies
    class headers, fields, validation and allocation callbacks. Persistence fills already allocated instances;
    abort marks any staged instances unusable after a failed import.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.HostStaged.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Context Private injected dependency; its role is described in the module map.
@param table Runtime Private injected dependency; its role is described in the module map.
@param table Codec Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Context, Runtime, Codec)
    local HostStaged = {};
    local _, tObjects = Runtime.services();

    
    --[[!
    @fqxn LuaEx.LXC.HostStaged.adapter
    @desc Creates callbacks for one staged transaction, capturing the original caller and tracking allocated
        instances for failure invalidation.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @ret table tAdapter Transaction adapter.
    @vis internal
    !]]
    local function fAdapter(tCaller)
        local tAdapter, tAllocated = {Used = false}, {};

        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.descriptor
        @desc Translates host descriptors to Ref/Null/Value form for LXC validation. Class identities must use
            staged nodes; symbolic factory/global references do not confer class access.
        @param table tValue One encoded descriptor/metadata record to validate or translate.
        @ret table tValue LXC descriptor.
        @vis internal
        !]]
        local function fDescriptor(tValue)
            if (tValue.node) then return {Ref = tValue.node}; end
            if (tValue.reference == 'null') then return {Null = true}; end
            -- Symbolic factory references and current-global upvalues carry no
            -- LXC class authority; class identities are always staged nodes.
            return {Value = tValue.value};
        end

        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.record
        @desc Rejects non-plain metadata and unknown keys before host headers enter LXC validation.
        @param table tValue One encoded descriptor/metadata record to validate or translate.
        @param table tAllowed Set of allowed metadata field names.
        @ret nil No return value; raises for invalid metadata.
        @vis internal
        !]]
        local function fRecord(tValue, tAllowed)
            assert(type(tValue) == 'table' and getmetatable(tValue) == nil, 'Invalid staged metadata.');
            for sKey in pairs(tValue) do assert(tAllowed[sKey], 'Unknown staged metadata field.'); end
        end

        -- Convert the existing serializer's descriptors only for LXC schema and
        -- authority validation. This does not duplicate or serialize its values.
        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.graph
        @desc Translates host graph shape without duplicating values. Checks staged field indices are unique and
            cover exactly the supplied values; foreign dependencies become capture descriptors.
        @param table tSource Host graph records to translate or finish.
        @param table tValues Allocated graph identities or storage records used by this operation.
        @ret table tGraph LXC validation graph.
        @vis internal
        !]]
        local function fGraph(tSource, tValues)
            local tGraph = {Version = 1, Root = fDescriptor(tSource.root), Nodes = {}};
            for nID, tNode in ipairs(tSource.nodes) do
                local tResult;
                if (tNode.kind == 'staged') then
                    local tHeader = tNode.header;
                    fRecord(tHeader, {Kind = true, Class = true, Fields = true});
                    tResult = {Kind = tHeader.Kind, Class = tHeader.Class};
                    assert(tHeader.Kind == 'class' or tHeader.Kind == 'instance', 'Invalid staged identity kind.');
                    local tUsed, nCount = {}, 0;
                    if (tHeader.Kind == 'instance') then
                        assert(type(tHeader.Fields) == 'table' and getmetatable(tHeader.Fields) == nil,
                            'Invalid staged field map.');
                        tResult.Fields = {};
                        for sKey, tField in pairs(tHeader.Fields) do
                            fRecord(tField, {Index = true, Type = true, ClassType = true, Locked = true});
                            local nIndex = tField.Index;
                            assert(type(nIndex) == 'number' and nIndex % 1 == 0 and nIndex >= 1 and
                                tNode.values[nIndex] and not tUsed[nIndex], 'Invalid staged field index.');
                            tUsed[nIndex], nCount = true, nCount + 1;
                            tResult.Fields[sKey] = {Value = fDescriptor(tNode.values[nIndex]), Type = tField.Type,
                                ClassType = tField.ClassType, Locked = tField.Locked};
                        end
                    else assert(tHeader.Fields == nil, 'Class references cannot carry instance fields.'); end
                    assert(nCount == #tNode.values, 'Unexpected staged field values.');
                elseif (tNode.kind == 'table') then
                    tResult = {Kind = 'table', Entries = {}};
                    for _, tEntry in ipairs(tNode.entries) do
                        tResult.Entries[#tResult.Entries + 1] = {fDescriptor(tEntry.key), fDescriptor(tEntry.value)};
                    end
                else
                    tResult = {Kind = 'host', Value = tValues and tValues[nID] or {}, Captures = {}};
                    --[[!
                    @fqxn LuaEx.LXC.HostStaged.adapter.capture
                    @desc Appends one non-global dependency to the translated host node; globals remain
                        current-host bindings.
                    @param table tValue One encoded descriptor/metadata record to validate or translate.
                    @ret nil No return value; appends Captures.
                    @vis internal
                    !]]
                    local function fCapture(tValue)
                        if (not tValue.global) then tResult.Captures[#tResult.Captures + 1] = fDescriptor(tValue); end
                    end
                    if (tNode.kind == 'function') then
                        for _, tUpvalue in ipairs(tNode.upvalues) do fCapture(tUpvalue.value); end
                    else
                        if (tNode.state) then fCapture(tNode.state); end
                        for _, tValue in ipairs(tNode.dependencies or {}) do fCapture(tValue); end
                    end
                end
                tGraph.Nodes[nID] = tResult;
            end
            return tGraph;
        end

        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.project
        @desc Recognizes LXC values via Persistence.project, separates identity/field metadata from ordered live
            field values, and marks the adapter used. Foreign values remain the host's responsibility.
        @param any vValue Value to inspect, assign, copy or serialize.
        @ret table|nil tHeader Followed by table tValues; no results for foreign values.
        @vis internal
        !]]
        function tAdapter.project(vValue)
            local tProjection = Codec.project(vValue);
            if (not tProjection) then return; end
            tAdapter.Used = true;
            local tHeader, tValues = {Kind = tProjection.Kind, Class = tProjection.Class}, {};
            if (tProjection.Fields) then
                tHeader.Fields = {};
                for sKey, tField in pairs(tProjection.Fields) do
                    tValues[#tValues + 1] = tField.Value;
                    tHeader.Fields[sKey] = {Index = #tValues, Type = tField.Type,
                        ClassType = tField.ClassType, Locked = tField.Locked};
                end
            end
            return tHeader, tValues;
        end

        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.checkFunction
        @desc Rejects internal/runtime-compiled functions before host application-code serialization.
        @param function fValue Candidate application function for export checks.
        @ret nil No return value; raises for owned closures.
        @vis internal
        !]]
        function tAdapter.checkFunction(fValue)
            assert(not Context.owns(fValue), 'LXC runtime/compiled closures cannot be serialized as application code.');
        end

        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.checkGraph
        @desc Validates translated version-two staged graphs under the original caller. Version-one host graphs
            contain no class nodes; function checks still apply.
        @param table tGraph Decoded Root/Nodes descriptor graph, not live instance state.
        @param table tSources Plain filename-to-source-text map, or supplied host identity map for adapter
            callbacks.
        @ret nil No return value; checks graph schema/access.
        @vis internal
        !]]
        function tAdapter.checkGraph(tGraph, tSources)
            -- Version one has no class nodes, but function checks still apply
            -- while encoding ordinary/foreign callbacks in the same transaction.
            if (tGraph.version == 2) then Codec.checkGraph(fGraph(tGraph, tSources), tCaller); end
        end

        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.allocate
        @desc Allocates a shell or returns a registered class from a staged header. Tracks new instance states
            for abort; constructors never run.
        @param table tHeader Staged class/instance identity and field metadata.
        @ret table vValue Class/instance identity.
        @vis internal
        !]]
        function tAdapter.allocate(tHeader)
            local vValue = Codec.stage(tHeader);
            if (tObjects[vValue]) then tAllocated[#tAllocated + 1] = tObjects[vValue]; end
            return vValue;
        end

        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.finish
        @desc Restores field contents into host-provided shells, reconnects through the host and runs snapshot
            validation. Internal callbacks retain the original caller's authority.
        @param table tSource Host graph records to translate or finish.
        @param table tValues Allocated graph identities or storage records used by this operation.
        @ret nil No return value; completes staged storage.
        @vis internal
        !]]
        function tAdapter.finish(tSource, tValues)
            local tHost = {};
            --[[!
            @fqxn LuaEx.LXC.HostStaged.adapter.finish.table
            @desc Returns the host's existing table shell for this node so aliases across host/LXC data remain
                shared.
            @param number nID Interned graph node identity.
            @ret table tValue Existing shell.
            @vis internal
            !]]
            function tHost.table(nID) return tValues[nID]; end
            --[[!
            @fqxn LuaEx.LXC.HostStaged.adapter.finish.allocate
            @desc Finds private state for a preallocated staged instance; missing identities fail instead of
                allocating a second copy.
            @param number nID Interned graph node identity.
            @ret table tState Existing instance state.
            @vis internal
            !]]
            function tHost.allocate(nID) return assert(tObjects[tValues[nID]], 'Missing staged instance.'); end
            --[[!
            @fqxn LuaEx.LXC.HostStaged.adapter.finish.reconnect
            @desc No-op: staged host restoration already owns reference/capture reconnection.
            @ret nil No return value.
            @vis internal
            !]]
            function tHost.reconnect() end
            --[[!
            @fqxn LuaEx.LXC.HostStaged.adapter.finish.caller
            @desc Returns the original operation caller captured before internal callback frames were entered.
            @ret table|nil tCaller Original class or external nil.
            @vis internal
            !]]
            function tHost.caller() return tCaller; end
            Codec.restore(fGraph(tSource, tValues), tHost);
        end

        --[[!
        @fqxn LuaEx.LXC.HostStaged.adapter.abort
        @desc Marks every allocated state failed and not ready, preventing escaped references from acting as
            successful restored objects.
        @ret nil No return value; invalidates states.
        @vis internal
        !]]
        function tAdapter.abort()
            for _, tState in ipairs(tAllocated) do tState.Failed, tState.Ready = true, false; end
        end

        for _, fFunction in pairs(tAdapter) do
            if (type(fFunction) == 'function') then Context.internal(fFunction); end
        end
        Context.internal(fDescriptor); Context.internal(fRecord); Context.internal(fGraph);
        return tAdapter;
    end
    Context.internal(fAdapter);

    
    --[[!
    @fqxn LuaEx.LXC.HostStaged.serialize
    @desc Serializes with a fresh adapter, adding --LXC:3 and a newline only when LXC projection was used.
        Otherwise returns ordinary host text unchanged.
    @param any vValue Value to inspect, assign, copy or serialize.
    @param table Serializer Original host serializer before the LXC facade wrapper.
    @ret string sSource Host serialization text.
    @vis internal
    !]]
    function HostStaged.serialize(vValue, Serializer)
        local __lxc_guard <close> = nil;
        local tAdapter = fAdapter(Context.caller());
        local sSource = Serializer.serializeStaged(vValue, tAdapter);
        return tAdapter.Used and '--LXC:3\n'..sSource or sSource;
    end

    
    --[[!
    @fqxn LuaEx.LXC.HostStaged.deserialize
    @desc Restores through a caller-bound adapter; failure aborts allocated instances and rethrows the original
        error. Host removes the version prefix before invoking this operation.
    @param string sSource Source text; the operation description specifies whether this is LXC, Lua or snapshot
        data.
    @param table Serializer Original host serializer before the LXC facade wrapper.
    @ret any vValue Restored root.
    @vis internal
    !]]
    function HostStaged.deserialize(sSource, Serializer)
        local __lxc_guard <close> = nil;
        local tAdapter = fAdapter(Context.caller());
        local bOK, vValue = pcall(Serializer.deserializeStaged, sSource, tAdapter);
        if (not bOK) then tAdapter.abort(); error(vValue, 0); end
        return vValue;
    end
    Context.internal(HostStaged.serialize); Context.internal(HostStaged.deserialize);
    return HostStaged;
end;
