--[[!
@fqxn LXC.HostGraph
@desc Adapts staged LXC state graphs to the existing LuaEx serializer. LuaEx
    owns bytecode, captured variables, shared cells and foreign-type restoration.
    Private identity markers reconnect captured class/table references only after
    all LXC shells exist; compiler environments are never exported.
!]]
return function(Context, Runtime, Codec)
    local HostGraph = {};
    local tClasses, tObjects = Runtime.services();
    local tSessions = setmetatable({}, {__mode = 'k'});

    --[[!
    @fqxn LXC.HostGraph.reference
    @desc Supplies an identity-only placeholder to LuaEx's existing object hook.
        It is usable only during this runtime's explicit host export transaction.
    !]]
    Runtime.HostReference = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        local tSession = assert(tSessions[coroutine.running()], 'No active LXC host export.');
        local nID = assert(tSession.Seen[vValue], 'Reference is outside the prepared class graph.');
        return assert(tSession.Markers[nID], 'Not a registered class identity.');
    end);

    --[[!
    @fqxn LXC.HostGraph.serialize
    @desc Projects typed class slots, then delegates function/foreign values to
        the unchanged LuaEx serializer. References retain aliases across both graphs.
    !]]
    function HostGraph.serialize(vRoot, Serializer)
        local __lxc_guard <close> = nil;
        local tSession = {Seen = {}, References = {}, Markers = {}};
        local tHost = {};

        function tHost.remember(vValue, nID)
            tSession.Seen[vValue], tSession.References[nID] = nID, vValue;
            if (tClasses[vValue] or tObjects[vValue]) then tSession.Markers[nID] = {}; end
        end

        function tHost.inspect(vValue, fEncode)
            local tCaptures = {};
            if (type(vValue) == 'function') then
                assert(not Context.owns(vValue), 'LXC runtime/compiled closures cannot be serialized as application code.');
                local nIndex = 1;
                while (true) do
                    local sName, vCaptured = debug.getupvalue(vValue, nIndex);
                    if (not sName) then break; end
                    -- Match LuaEx: _ENV == _G is a current-runtime binding, not
                    -- a snapshot of every global and its private service closures.
                    if (sName ~= '_ENV' or not rawequal(vCaptured, _G)) then
                        tCaptures[#tCaptures + 1] = fEncode(vCaptured);
                    end
                    nIndex = nIndex + 1;
                end
            end
            return tCaptures;
        end

        local tGraph = Codec.snapshot(vRoot, tHost);
        local oThread = coroutine.running();
        local tPrevious = tSessions[oThread];
        tSessions[oThread] = tSession;
        local bOK, sResult = pcall(Serializer.serialize, {
            Graph = tGraph, References = tSession.References, Markers = tSession.Markers,
        });
        tSessions[oThread] = tPrevious;
        if (not bOK) then error(sResult, 0); end
        return sResult;
    end
    Context.internal(HostGraph.serialize);

    --[[!
    @fqxn LXC.HostGraph.deserialize
    @desc Lets LuaEx rebuild functions/shared captures, then reconnects their
        identity references to constructor-free LXC shells before class validation.
    !]]
    function HostGraph.deserialize(sSource, Serializer)
        local __lxc_guard <close> = nil;
        local tEnvelope = Serializer.deserialize(sSource);
        assert(type(tEnvelope) == 'table' and type(tEnvelope.Graph) == 'table' and
            type(tEnvelope.References) == 'table' and type(tEnvelope.Markers) == 'table', 'Invalid LXC host graph.');
        local tSeen = {};
        for nID, tNode in ipairs(tEnvelope.Graph.Nodes or {}) do
            local vReference = tEnvelope.References[nID];
            assert(vReference ~= nil and not tSeen[vReference], 'Conflicting host graph identities.');
            tSeen[vReference] = true;
            if (tNode.Kind == 'class' or tNode.Kind == 'instance') then
                assert(rawequal(vReference, tEnvelope.Markers[nID]), 'Class reference marker mismatch.');
            elseif (tNode.Kind == 'host') then
                assert(rawequal(vReference, tNode.Value), 'Host value identity mismatch.');
                if (type(tNode.Value) == 'function') then
                    assert(not Context.owns(tNode.Value), 'Cannot restore private runtime/compiled closures.');
                    local nIndex, nCapture = 1, 0;
                    while (true) do
                        local sName, vCaptured = debug.getupvalue(tNode.Value, nIndex);
                        if (not sName) then break; end
                        if (sName ~= '_ENV' or not rawequal(vCaptured, _G)) then
                            nCapture = nCapture + 1;
                            local tSaved = assert(tNode.Captures[nCapture], 'Missing captured-value descriptor.');
                            local vExpected = tSaved.Ref and tEnvelope.References[tSaved.Ref] or
                                (tSaved.Null and Runtime.Null or tSaved.Value);
                            assert(rawequal(vCaptured, vExpected) or
                                (type(vCaptured) == 'number' and type(vExpected) == 'number' and
                                 vCaptured ~= vCaptured and vExpected ~= vExpected), 'Captured-value descriptor mismatch.');
                        end
                        nIndex = nIndex + 1;
                    end
                    assert(nCapture == #tNode.Captures, 'Unexpected captured-value descriptors.');
                end
            end
        end
        local tHost = {};

        function tHost.reconnect(tValues)
            local tReplacements = {};
            for nID, vReference in pairs(tEnvelope.References) do
                assert(type(nID) == 'number' and tValues[nID] ~= nil, 'Invalid host reference identity.');
                tReplacements[vReference] = tValues[nID];
            end

            -- setupvalue preserves cells already joined by LuaEx restoreGraph.
            -- Every captured table/function was interned during projection, so
            -- one pass over function nodes also handles mutually recursive closures.
            for _, tNode in ipairs(tEnvelope.Graph.Nodes) do
                if (tNode.Kind == 'host' and type(tNode.Value) == 'function') then
                    local nIndex = 1;
                    while (true) do
                        local sName, vCaptured = debug.getupvalue(tNode.Value, nIndex);
                        if (not sName) then break; end
                        local vReplacement = tReplacements[vCaptured];
                        if (vReplacement ~= nil and not rawequal(vReplacement, vCaptured)) then
                            debug.setupvalue(tNode.Value, nIndex, vReplacement);
                        end
                        nIndex = nIndex + 1;
                    end
                end
            end
        end

        return Codec.restore(tEnvelope.Graph, tHost);
    end
    Context.internal(HostGraph.deserialize);
    return HostGraph;
end;
