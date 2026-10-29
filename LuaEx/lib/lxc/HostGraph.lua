--[[!
@fqxn LuaEx.LXC.HostGraph
@desc <h3>HostGraph — responsibility and connections</h3><p>Implements the older identity-envelope bridge
    between LuaEx serialization and LXC snapshots. Markers stand in for class identities while the host handles
    foreign values and application closures. Persistence restores LXC storage, then this service reconnects
    captured values. Host uses this for version-two imports; current exports use HostStaged.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.HostGraph.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Context Private injected dependency; its role is described in the module map.
@param table Runtime Private injected dependency; its role is described in the module map.
@param table Codec Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Context, Runtime, Codec)
    local HostGraph = {};
    local tClasses, tObjects = Runtime.services();
    local tSessions = setmetatable({}, {__mode = 'k'});

    
    --[[!
    @fqxn LuaEx.LXC.HostGraph.HostReference
    @desc Returns a temporary class/instance marker during an active older host export. The identity must
        already be interned in that export graph.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret table oMarker Shared marker for this identity.
    @vis internal
    !]]
    Runtime.HostReference = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        local tSession = assert(tSessions[coroutine.running()], 'No active LXC host export.');
        local nID = assert(tSession.Seen[vValue], 'Reference is outside the prepared class graph.');
        return assert(tSession.Markers[nID], 'Not a registered class identity.');
    end);

    
    --[[!
    @fqxn LuaEx.LXC.HostGraph.serialize
    @desc Snapshots with host callbacks, then serializes Graph/References/Markers together. A coroutine session
        supplies facade markers and the previous session is restored on success or failure.
    @param any vRoot Application graph root to export.
    @param table Serializer Original host serializer before the LXC facade wrapper.
    @ret string sSource Older envelope without its version prefix.
    @vis internal
    !]]
    function HostGraph.serialize(vRoot, Serializer)
        local __lxc_guard <close> = nil;
        local tSession = {Seen = {}, References = {}, Markers = {}};
        local tHost = {};

        --[[!
        @fqxn LuaEx.LXC.HostGraph.serialize.remember
        @desc Records live value/node identity and creates markers for class/instance nodes before following
            edges.
        @param any vValue Value to inspect, assign, copy or serialize.
        @param number nID Interned graph node identity.
        @ret nil No return value; updates the export session.
        @vis internal
        !]]
        function tHost.remember(vValue, nID)
            tSession.Seen[vValue], tSession.References[nID] = nID, vValue;
            if (tClasses[vValue] or tObjects[vValue]) then tSession.Markers[nID] = {}; end
        end

        --[[!
        @fqxn LuaEx.LXC.HostGraph.serialize.inspect
        @desc Encodes non-global captures of foreign functions. Current-global _ENV is skipped; LXC-owned
            closures are rejected. Non-functions contribute an empty capture list.
        @param any vValue Value to inspect, assign, copy or serialize.
        @param function fEncode Graph encoder used to intern captures.
        @ret table tCaptures Encoded captures.
        @vis internal
        !]]
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
    @fqxn LuaEx.LXC.HostGraph.deserialize
    @desc Verifies envelope identities, markers and capture descriptors, then restores via Persistence.
        Reconnect replaces temporary identities in function upvalues.
    @param string sSource Source text; the operation description specifies whether this is LXC, Lua or snapshot
        data.
    @param table Serializer Original host serializer before the LXC facade wrapper.
    @ret any vRoot Restored root graph.
    @vis internal
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

        --[[!
        @fqxn LuaEx.LXC.HostGraph.deserialize.reconnect
        @desc Replaces envelope references in function captures with restored values using setupvalue,
            preserving already joined upvalue cells. Interned identities also handle recursive closures.
        @param table tValues Allocated graph identities or storage records used by this operation.
        @ret nil No return value; reconnects captures.
        @vis internal
        !]]
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
