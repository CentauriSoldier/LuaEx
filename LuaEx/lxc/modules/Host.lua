--[[!
@fqxn LXC.Host
@desc Connects initialized LuaEx core to LXC without changing library files.
    Existing primitive services remain available. New class objects use LXC's
    graph copy/codec services. Bridges retain caller frames across delegation.
!]]
return function(Model, Context, Runtime, Facades, Copy, Codec, Helpers, HostGraph, HostStaged)
    local Host = {};
    local tClasses, tObjects = Runtime.services();
    local tInstalled = setmetatable({}, {__mode = 'k'});
    local sPrefix = '--LXC:1\n';
    local sHostPrefix = '--LXC:2\n';
    local sStagedPrefix = '--LXC:3\n';

    --[[!
    @fqxn LXC.Host.contains
    @desc Detects LXC identities without invoking application iterators. Private
        runtime/compiler closures cannot enter the legacy closure serializer.
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
    @fqxn LXC.Host.install
    @desc Installs scope-preserving clone/tagged-codec bridges after LuaEx core
        is ready. Repeated installation into the same environment is harmless.
    !]]
    function Host.install(oAPI, tEnvironment)
        local __lxc_guard <close> = nil;
        if (tInstalled[tEnvironment]) then return; end
        assert(tEnvironment.class == nil or rawequal(tEnvironment.class, Helpers), 'A different class system is already installed.');
        local Cloner, Serializer = tEnvironment.cloner, tEnvironment.serializer;
        assert(Cloner and Serializer, 'Initialize LuaEx core clone/serialization services before binding LXC.');
        Copy.Fallback = Cloner.clone;

        local fClone = Context.internal(function(vValue, bIgnoreMetatable)
            local __lxc_guard <close> = nil;
            if (Copy.active() or fContains(vValue, {}, false)) then return Copy.clone(vValue, bIgnoreMetatable); end
            return Cloner.clone(vValue, bIgnoreMetatable);
        end);
        local fCloneIndependent = Context.internal(function(vValue, bIgnoreMetatable)
            local __lxc_guard <close> = nil;
            if (Copy.active() or fContains(vValue, {}, false)) then return Copy.clone(vValue, bIgnoreMetatable); end
            return Cloner.cloneIndependent(vValue, bIgnoreMetatable);
        end);

        local fSerialize = Context.internal(function(vValue, ...)
            local __lxc_guard <close> = nil;
            return HostStaged.serialize(vValue, Serializer);
        end);
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
        local fRegisterCopy = Context.internal(function(oSource, oCopy)
            local __lxc_guard <close> = nil;
            if (Copy.active()) then return Copy.registerCopy(oSource, oCopy); end
            return Cloner.registerCopy(oSource, oCopy);
        end);
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
            __index = function(sName) return tCloneMethods[sName] or Cloner[sName]; end,
            __newindex = function() error('Cloner is read-only.'); end,
        });
        tEnvironment.serializer = Facades.create({
            __index = function(sName) return tSerializeMethods[sName] or Serializer[sName]; end,
            __newindex = function() error('Serializer is read-only.'); end,
        });
        tEnvironment.class, tEnvironment.lxc = Helpers, oAPI;
        tEnvironment.clone, tEnvironment.serialize, tEnvironment.deserialize = fClone, fSerialize, fDeserialize;

        -- Preserve the callable type table and its existing assertion helpers.
        local tType = tEnvironment.type;
        local tMeta = type(tType) == 'table' and debug.getmetatable(tType);
        if (tMeta and tMeta.__call) then
            local fBaseType = tMeta.__call;
            tMeta.__call = function(tSelf, vValue)
                if (tClasses[vValue]) then return 'class'; end
                if (tObjects[vValue]) then return tObjects[vValue].Class.Name; end
                return fBaseType(tSelf, vValue);
            end;
        end
        tInstalled[tEnvironment] = true;
    end

    --[[!
    @fqxn LXC.Host.publishAliases
    @desc Preserves short framework names for ordinary Lua scripts while class
        declarations and metadata retain their qualified namespace identities.
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
