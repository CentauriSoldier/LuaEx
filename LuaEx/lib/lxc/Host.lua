--[[!
@fqxn LuaEx.LXC.Host
@desc <h3>Host — responsibility and connections</h3><p>Connects LXC to an initialized LuaEx core. Installs
    class/lxc, graph-aware clone/serialization functions and LXC recognition in the callable type table.
    GraphClone handles live copies, HostStaged handles current exports and HostGraph supports older imports.
    Binding rejects a different installed class system.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.Host.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Model Private injected dependency; its role is described in the module map.
@param table Context Private injected dependency; its role is described in the module map.
@param table Runtime Private injected dependency; its role is described in the module map.
@param table Facades Private injected dependency; its role is described in the module map.
@param table Copy Private injected dependency; its role is described in the module map.
@param table Codec Private injected dependency; its role is described in the module map.
@param table Helpers Private injected dependency; its role is described in the module map.
@param table HostGraph Private injected dependency; its role is described in the module map.
@param table HostStaged Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Model, Context, Runtime, Facades, Copy, Codec, Helpers, HostGraph, HostStaged)
    local Host = {};
    local tClasses, tObjects = Runtime.services();
    local tInstalled = setmetatable({}, {__mode = 'k'});
    local sPrefix = '--LXC:1\n';
    local sHostPrefix = '--LXC:2\n';
    local sStagedPrefix = '--LXC:3\n';

    
    --[[!
    @fqxn LuaEx.LXC.Host.contains
    @desc Searches plain table keys/values for LXC identities, optionally walking non-global function captures.
        Seen identities stop cycles; serialization inspection rejects runtime/compiled closures.
    @param any vValue Value to inspect, assign, copy or serialize.
    @param table tSeen Identity set used to terminate cycles during inspection.
    @param boolean|nil bCheckFunctions False skips closure inspection; otherwise inspect non-global captures.
    @ret boolean bFound Whether reachable values need LXC handling.
    @vis internal
    !]]
    local function fContains(vValue, tSeen, bCheckFunctions)
        if (tClasses[vValue] or tObjects[vValue]) then return true; end
        if (type(vValue) == 'function' and bCheckFunctions ~= false) then
            assert(not Context.owns(vValue), 'LXC runtime/compiled closures cannot be serialized as application code.');
            if (tSeen[vValue]) then return false; end
            tSeen[vValue] = true;
            local nIndex, bFound = 1, false;
            while (true) do
                local sName, vCaptured = debug.getupvalue(vValue, nIndex);
                if (not sName) then break; end
                if (sName ~= '_ENV' or not rawequal(vCaptured, _G)) then
                    bFound = fContains(vCaptured, tSeen, true) or bFound;
                end
                nIndex = nIndex + 1;
            end
            return bFound;
        end
        if (type(vValue) ~= 'table' or getmetatable(vValue) ~= nil or tSeen[vValue]) then return false; end
        tSeen[vValue] = true;
        local bFound = false;
        for k, v in next, vValue do
            local bKey, bValue = fContains(k, tSeen, bCheckFunctions), fContains(v, tSeen, bCheckFunctions);
            bFound = bFound or bKey or bValue;
        end
        return bFound;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Host.install
    @desc Installs class/lxc and graph-aware host functions. Requires cloner/serializer and no conflicting class
        system; repeated installation into the same environment is a no-op. Extends the callable type table
        while retaining assertion helpers.
    @param table oAPI Read-only public LXC API to publish on the host.
    @param table tEnvironment Destination environment for namespace or host bindings.
    @ret nil No return value; updates host bindings.
    @vis internal
    !]]
    function Host.install(oAPI, tEnvironment)
        local __lxc_guard <close> = nil;
        if (tInstalled[tEnvironment]) then return; end
        assert(tEnvironment.class == nil or rawequal(tEnvironment.class, Helpers), 'A different class system is already installed.');
        local Cloner, Serializer = tEnvironment.cloner, tEnvironment.serializer;
        assert(Cloner and Serializer, 'Initialize LuaEx core clone/serialization services before binding LXC.');
        Copy.Fallback = Cloner.clone;

        --[[!
        @fqxn LuaEx.LXC.Host.clone
        @desc Routes graphs containing LXC values or active nested copies to GraphClone; other values keep
            original host-cloner behavior.
        @param any vValue Value to inspect, assign, copy or serialize.
        @param boolean|nil bIgnoreMetatable Optional copy flag; true treats eligible foreign tables as plain
            data.
        @ret any vCopy Copied root.
        @vis internal
        !]]
        local fClone = Context.internal(function(vValue, bIgnoreMetatable)
            local __lxc_guard <close> = nil;
            if (Copy.active() or fContains(vValue, {}, false)) then return Copy.clone(vValue, bIgnoreMetatable); end
            return Cloner.clone(vValue, bIgnoreMetatable);
        end);
        --[[!
        @fqxn LuaEx.LXC.Host.cloneIndependent
        @desc Uses the LXC session for LXC graphs/active nested calls; otherwise delegates to the original
            cloneIndependent.
        @param any vValue Value to inspect, assign, copy or serialize.
        @param boolean|nil bIgnoreMetatable Optional copy flag; true treats eligible foreign tables as plain
            data.
        @ret any vCopy Copied root.
        @vis internal
        !]]
        local fCloneIndependent = Context.internal(function(vValue, bIgnoreMetatable)
            local __lxc_guard <close> = nil;
            if (Copy.active() or fContains(vValue, {}, false)) then return Copy.clone(vValue, bIgnoreMetatable); end
            return Cloner.cloneIndependent(vValue, bIgnoreMetatable);
        end);

        --[[!
        @fqxn LuaEx.LXC.Host.serialize
        @desc Uses HostStaged so LXC and foreign values share one host graph. A version-three prefix is added
            only when an LXC projection is used.
        @param any vValue Value to inspect, assign, copy or serialize.
        @param any ... Additional arguments forwarded in order.
        @ret string sSource Serialized text.
        @vis internal
        !]]
        local fSerialize = Context.internal(function(vValue, ...)
            local __lxc_guard <close> = nil;
            return HostStaged.serialize(vValue, Serializer);
        end);
        --[[!
        @fqxn LuaEx.LXC.Host.deserialize
        @desc Selects staged, older host-envelope, standalone LXC or ordinary host restore by prefix. Remaining
            host options pass only to the ordinary fallback.
        @param string sSource Source text; the operation description specifies whether this is LXC, Lua or
            snapshot data.
        @param any ... Additional arguments forwarded in order.
        @ret any vValue Restored root.
        @vis internal
        !]]
        local fDeserialize = Context.internal(function(sSource, ...)
            local __lxc_guard <close> = nil;
            if (type(sSource) == 'string' and string.sub(sSource, 1, #sStagedPrefix) == sStagedPrefix) then
                return HostStaged.deserialize(string.sub(sSource, #sStagedPrefix + 1), Serializer);
            end
            if (type(sSource) == 'string' and string.sub(sSource, 1, #sHostPrefix) == sHostPrefix) then
                return HostGraph.deserialize(string.sub(sSource, #sHostPrefix + 1), Serializer);
            end
            if (type(sSource) == 'string' and string.sub(sSource, 1, #sPrefix) == sPrefix) then
                return Codec.deserialize(string.sub(sSource, #sPrefix + 1));
            end
            return Serializer.deserialize(sSource, ...);
        end);
        --[[!
        @fqxn LuaEx.LXC.Host.registerCopy
        @desc Routes copy registration into the active LXC session, otherwise the original host cloner. Custom
            LXC clone hooks use this to preserve cycles.
        @param table oSource Source LXC instance with an active custom clone hook.
        @param table oCopy Distinct same-concrete-class copy of the source.
        @ret nil No return value; registers identity.
        @vis internal
        !]]
        local fRegisterCopy = Context.internal(function(oSource, oCopy)
            local __lxc_guard <close> = nil;
            if (Copy.active()) then return Copy.registerCopy(oSource, oCopy); end
            return Cloner.registerCopy(oSource, oCopy);
        end);
        --[[!
        @fqxn LuaEx.LXC.Host.registerFactory
        @desc Checks visible LXC classes and treats them as already managed; foreign factories are forwarded to
            the original cloner.
        @param table oFactory LXC or foreign factory being registered for host cloning.
        @param any ... Additional arguments forwarded in order.
        @ret any ... Foreign registration results, or none for an LXC class.
        @vis internal
        !]]
        local fRegisterFactory = Context.internal(function(oFactory, ...)
            local __lxc_guard <close> = nil;
            local tClass = tClasses[oFactory];
            if (tClass) then
                assert(Model.visible(tClass, Context.caller()), 'Inaccessible class factory.');
                return;
            end
            return Cloner.registerFactory(oFactory, ...);
        end);

        local tCloneMethods = {clone = fClone, cloneIndependent = fCloneIndependent,
            registerCopy = fRegisterCopy, registerFactory = fRegisterFactory};
        local tSerializeMethods = {serialize = fSerialize, deserialize = fDeserialize};
        tEnvironment.cloner = Facades.create({
            --[[!
            @fqxn LuaEx.LXC.Host.install.cloner.read
            @desc Returns an LXC cloner override when defined, otherwise delegates to the original host cloner
                member.
            @param string sName Name/path to resolve or inspect under the lookup rules described above.
            @ret any vMember Cloner operation/member.
            @vis internal
            !]]
            __index = function(sName) return tCloneMethods[sName] or Cloner[sName]; end,
            --[[!
            @fqxn LuaEx.LXC.Host.install.cloner.write
            @desc Rejects replacing members on the bound read-only cloner facade.
            @ret nil Never returns successfully; raises a read-only error.
            @vis internal
            !]]
            __newindex = function() error('Cloner is read-only.'); end,
        });
        tEnvironment.serializer = Facades.create({
            --[[!
            @fqxn LuaEx.LXC.Host.install.serializer.read
            @desc Returns an LXC serialization override when defined, otherwise delegates to the original host
                serializer.
            @param string sName Name/path to resolve or inspect under the lookup rules described above.
            @ret any vMember Serializer operation/member.
            @vis internal
            !]]
            __index = function(sName) return tSerializeMethods[sName] or Serializer[sName]; end,
            --[[!
            @fqxn LuaEx.LXC.Host.install.serializer.write
            @desc Rejects replacing members on the bound read-only serializer facade.
            @ret nil Never returns successfully; raises a read-only error.
            @vis internal
            !]]
            __newindex = function() error('Serializer is read-only.'); end,
        });
        tEnvironment.class, tEnvironment.lxc = Helpers, oAPI;
        tEnvironment.clone, tEnvironment.serialize, tEnvironment.deserialize = fClone, fSerialize, fDeserialize;

        -- Preserve the callable type table and its existing assertion helpers.
        local tType = tEnvironment.type;
        local tMeta = type(tType) == 'table' and debug.getmetatable(tType);
        if (tMeta and tMeta.__call) then
            local fBaseType = tMeta.__call;
            --[[!
            @fqxn LuaEx.LXC.Host.__call
            @desc Recognizes an LXC class as class and an instance by its concrete short class name; otherwise
                delegates to the original callable type implementation.
            @param table tSelf Existing callable host type table.
            @param any vValue Value to inspect, assign, copy or serialize.
            @ret any vResult Result of the owning view operation; see the enclosing view contract.
            @vis internal
            !]]
            tMeta.__call = function(tSelf, vValue)
                if (tClasses[vValue]) then return 'class'; end
                if (tObjects[vValue]) then return tObjects[vValue].Class.Name; end
                return fBaseType(tSelf, vValue);
            end;
        end
        tInstalled[tEnvironment] = true;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Host.publishAliases
    @desc Adds short aliases only for top-level LuaEx.Classes definitions. Application/nested types stay
        qualified; an existing different short binding fails.
    @param table tNames Ordered qualified-name or restriction entries used by the surrounding operation.
    @param table tEnvironment Destination environment for namespace or host bindings.
    @ret nil No return value; publishes checked aliases.
    @vis internal
    !]]
    function Host.publishAliases(tNames, tEnvironment)
        for _, sName in ipairs(tNames) do
            local tClass = Model.Classes[sName];
            if (not tClass.Outer and tClass.Namespace == 'LuaEx.Classes') then
                local vExisting = rawget(tEnvironment, tClass.Name);
                assert(vExisting == nil or rawequal(vExisting, tClass.Object), 'Framework class alias already exists: '..tClass.Name);
                rawset(tEnvironment, tClass.Name, tClass.Object);
            end
        end
    end

    return Host;
end;
