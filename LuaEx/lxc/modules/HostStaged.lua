--[[!
@fqxn LXC.HostStaged
@desc Projects LXC slots into the existing serializer's staged graph protocol.
    Native tables, closures and foreign hooks retain the serializer's identities.
    Class-reference authority is checked before any restored shell is allocated.
!]]
return function(Context, Runtime, Codec)
    local HostStaged = {};
    local _, tObjects = Runtime.services();

    --[[!
    @fqxn LXC.HostStaged.adapter
    @desc Creates one transaction's private projection, allocation and validation callbacks.
    !]]
    local function fAdapter(tCaller)
        local tAdapter, tAllocated = {Used = false}, {};

        local function fDescriptor(tValue)
            if (tValue.node) then return {Ref = tValue.node}; end
            if (tValue.reference == 'null') then return {Null = true}; end
            -- Symbolic factory references and current-global upvalues carry no
            -- LXC class authority; class identities are always staged nodes.
            return {Value = tValue.value};
        end

        local function fRecord(tValue, tAllowed)
            assert(type(tValue) == 'table' and getmetatable(tValue) == nil, 'Invalid staged metadata.');
            for sKey in pairs(tValue) do assert(tAllowed[sKey], 'Unknown staged metadata field.'); end
        end

        -- Convert the existing serializer's descriptors only for LXC schema and
        -- authority validation. This does not duplicate or serialize its values.
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

        function tAdapter.checkFunction(fValue)
            assert(not Context.owns(fValue), 'LXC runtime/compiled closures cannot be serialized as application code.');
        end

        function tAdapter.checkGraph(tGraph, tSources)
            -- Version one has no class nodes, but function checks still apply
            -- while encoding ordinary/foreign callbacks in the same transaction.
            if (tGraph.version == 2) then Codec.checkGraph(fGraph(tGraph, tSources), tCaller); end
        end

        function tAdapter.allocate(tHeader)
            local vValue = Codec.stage(tHeader);
            if (tObjects[vValue]) then tAllocated[#tAllocated + 1] = tObjects[vValue]; end
            return vValue;
        end

        function tAdapter.finish(tSource, tValues)
            local tHost = {};
            function tHost.table(nID) return tValues[nID]; end
            function tHost.allocate(nID) return assert(tObjects[tValues[nID]], 'Missing staged instance.'); end
            function tHost.reconnect() end
            function tHost.caller() return tCaller; end
            Codec.restore(fGraph(tSource, tValues), tHost);
        end

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
    @fqxn LXC.HostStaged.serialize
    @desc Uses existing bytecode/object hooks and tags only graphs containing LXC state.
    !]]
    function HostStaged.serialize(vValue, Serializer)
        local __lxc_guard <close> = nil;
        local tAdapter = fAdapter(Context.caller());
        local sSource = Serializer.serializeStaged(vValue, tAdapter);
        return tAdapter.Used and '--LXC:3\n'..sSource or sSource;
    end

    --[[!
    @fqxn LXC.HostStaged.deserialize
    @desc Returns only fully validated graphs; every allocated LXC shell is invalidated on failure.
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
