--[[!
@fqxn LuaEx.LXC.Environment
@desc <h3>Environment — responsibility and connections</h3><p>Builds one declaring class's name-lookup
    environment. Compiler bindings take precedence, then Model resolves accessible classes and namespace views,
    then ordinary names fall back to the supplied host. Context registers ownership; Runtime checks class
    usability. Namespace views and implicit global assignments are read-only.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.Environment.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Model Private injected dependency; its role is described in the module map.
@param table Context Private injected dependency; its role is described in the module map.
@param table Facades Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Model, Context, Facades)
    local Environment = {};

    
    --[[!
    @fqxn LuaEx.LXC.Environment.create
    @desc Builds and registers one class-owned _ENV. Reserved bindings win, then Model class resolution and
        namespace views, then host globals. Namespace reads check usability; namespace writes and implicit
        globals raise errors.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param table tBatch Pending class definitions keyed by qualified name.
    @param table|nil tHost Optional host graph adapter; nil selects standalone graph handling.
    @param table tBindings Compiler bindings taking precedence over class/host names.
    @param function fCheckClass Runtime callback checking class visibility/publication/discard status.
    @ret table tScope Registered lookup environment supplied to Lua load.
    @vis internal
    !]]
    function Environment.create(tClass, tBatch, tHost, tBindings, fCheckClass)
        local tNamespaceCache = {};
        local tEnums = tClass.EnumBatch or {};

        --[[!
        @fqxn LuaEx.LXC.Environment.enum
        @desc Resolves a prepared enum without publishing it early. Class-owned
            roots use the declaring class's existing visibility rules.
        @param string sFull Qualified enum name.
        @ret table|nil Canonical enum object.
        !]]
        local function fEnum(sFull)
            local tEnum = tEnums[sFull];
            if (not tEnum) then
                -- Resolve already-published public enums through namespace tables.
                -- Do not turn qualified class paths into an access bypass.
                local vValue = tHost;
                for sPart in sFull:gmatch('[^.]+') do
                    if (type(vValue) ~= 'table') then return; end
                    vValue = vValue[sPart];
                end
                local LXE = rawget(_G, 'lxe') or package.loaded['LuaEx.lib.lxe'];
                if (LXE and LXE.isEnum(vValue)) then return vValue; end
                return;
            end
            local tRoot = tEnum.Root;
            if (tRoot.Within) then
                local tOwner = tBatch[tRoot.Within] or Model.Classes[tRoot.Within];
                assert(tOwner and Model.allowed(tRoot.Flags.Visibility or 'public', tOwner, tClass),
                    'Inaccessible enum: '..sFull);
            end
            assert(tEnum.Object and not tRoot.Failed, 'Enum is not ready: '..sFull);
            return tEnum.Object;
        end

        -- Existing public host enums remain visible through namespace views even
        -- when a class in that namespace causes LXC to create a scoped view.
        local function fHostPath(sPath)
            local vValue = tHost;
            for sPart in sPath:gmatch('[^.]+') do
                if (vValue == nil) then return; end
                vValue = vValue[sPart];
            end
            return vValue;
        end

        -- Namespace views are cached only within this declaring class's scope.
        -- Each lookup still checks the current using scope before yielding a class.
        --[[!
        @fqxn LuaEx.LXC.Environment.namespace
        @desc Creates or reuses a read-only dotted-namespace view for this declaring class. Its read callback
            returns a checked class or deeper namespace view; unknown children raise an error rather than
            exposing registry tables.
        @param string sPath Dotted namespace path whose view is requested.
        @ret table oNamespace Cached opaque namespace view.
        @vis internal
        !]]
        local function fNamespace(sPath)
            if (tNamespaceCache[sPath]) then return tNamespaceCache[sPath]; end

            local oNamespace = Facades.create({
                --[[!
                @fqxn LuaEx.LXC.Environment.create.namespace.read
                @desc Resolves a checked child class or deeper namespace path in the cached namespace view.
                    Unknown names fail.
                @param string sKey Requested namespace or member name.
                @ret table oValue Class/namespace facade.
                @vis internal
                !]]
                __index = Context.internal(function(sKey)
                    local __lxc_guard <close> = nil;
                    assert(type(sKey) == 'string', 'Namespace names must be strings.');
                    local sFull = sPath..'.'..sKey;
                    local tFound = tBatch[sFull] or Model.Classes[sFull];
                    if (tFound) then
                        fCheckClass(tFound, Context.caller());
                        return tFound.Object;
                    end

                    for sName in pairs(tBatch) do
                        if (string.sub(sName, 1, #sFull + 1) == sFull..'.') then return fNamespace(sFull); end
                    end
                    for sName in pairs(Model.Classes) do
                        if (string.sub(sName, 1, #sFull + 1) == sFull..'.') then return fNamespace(sFull); end
                    end
                    local oEnum = fEnum(sFull);
                    if (oEnum) then return oEnum; end
                    for sName in pairs(tEnums) do
                        if (sName:sub(1, #sFull + 1) == sFull..'.') then return fNamespace(sFull); end
                    end
                    local vHostValue = fHostPath(sFull);
                    if (vHostValue ~= nil) then return vHostValue; end
                    error('Unknown namespace member: '..sFull);
                end),
                --[[!
                @fqxn LuaEx.LXC.Environment.create.namespace.write
                @desc Rejects writes through a namespace view.
                @ret nil Never returns successfully; namespace views are read-only.
                @vis internal
                !]]
                __newindex = function() error('Namespace is read-only.'); end,
            });

            tNamespaceCache[sPath] = oNamespace;
            return oNamespace;
        end
        Context.internal(fNamespace);

        local tScope = setmetatable({}, {
            --[[!
            @fqxn LuaEx.LXC.Environment.create.scope.read
            @desc Resolves compiler bindings, class names, namespace roots, then host values for this
                class-owned environment.
            @param table _ Unused Lua metamethod receiver supplied by Lua.
            @param string sKey Requested namespace or member name.
            @ret any vValue Resolved environment binding.
            @vis internal
            !]]
            __index = Context.internal(function(_, sKey)
                local __lxc_guard <close> = nil;
                if (tBindings[sKey] ~= nil) then return tBindings[sKey]; end

                local tFound = Model.resolve(sKey, tClass, tBatch);
                if (tFound) then
                    fCheckClass(tFound, tClass);
                    return tFound.Object;
                end
                for sName in pairs(tBatch) do
                    if (string.match(sName, '^([^.]+)') == sKey) then return fNamespace(sKey); end
                end
                for sName in pairs(Model.Classes) do
                    if (string.match(sName, '^([^.]+)') == sKey) then return fNamespace(sKey); end
                end
                local oEnum = fEnum(sKey) or fEnum(tClass.Namespace..'.'..sKey);
                for _, sImport in ipairs(tClass.Imports) do
                    local oOther = fEnum(sImport..'.'..sKey);
                    assert(not oOther or not oEnum or rawequal(oEnum, oOther), 'Ambiguous enum: '..sKey);
                    oEnum = oEnum or oOther;
                end
                if (oEnum) then return oEnum; end
                for sName in pairs(tEnums) do
                    if (sName:match('^([^.]+)') == sKey) then return fNamespace(sKey); end
                end
                return tHost[sKey];
            end),
            --[[!
            @fqxn LuaEx.LXC.Environment.create.scope.write
            @desc Rejects implicit global assignments from a compiled class body.
            @ret nil Never returns successfully; implicit global writes fail.
            @vis internal
            !]]
            __newindex = function() error('Class environments do not allow implicit global writes.'); end,
        });

        Context.register(tScope, tClass);
        return tScope;
    end

    return Environment;
end;


