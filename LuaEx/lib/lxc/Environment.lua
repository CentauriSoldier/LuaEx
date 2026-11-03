--[[!
@fqxn LuaEx.LXC.Environment
@desc <h3>Environment — responsibility and connections</h3><p>Builds one declaring class's name-lookup
    environment. Compiler bindings take precedence, then Model resolves accessible classes and namespace views,
    then ordinary names fall back to the supplied host. Context registers ownership; Runtime checks class
    usability. Namespace views and implicit global assignments are read-only.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]
-- Keep runtime string operations independent of application replacements.
local _gmatch, _find, _sub = string.gmatch, string.find, string.sub;



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
    local tNamespaceIndexes = setmetatable({}, {__mode = 'k'});

    --[[!
    @fqxn LuaEx.LXC.Environment.indexNamespaces
    @desc Indexes all dotted prefixes once for an immutable declaration batch.
        The weak-key cache does not retain otherwise unreachable batches.
    @param table tDeclarations Class or enum definitions keyed by qualified name.
    @ret table tPaths Set of namespace prefixes.
    @vis internal
    !]]
    local function indexNamespaces(tDeclarations)
        local tPaths = tNamespaceIndexes[tDeclarations];
        if (tPaths) then return tPaths; end

        tPaths = {};
        for sName in pairs(tDeclarations) do
            local nDot = _find(sName, '.', 1, true);
            if (not nDot) then tPaths[sName] = true; end
            while (nDot) do
                tPaths[_sub(sName, 1, nDot - 1)] = true;
                nDot = _find(sName, '.', nDot + 1, true);
            end
        end

        tNamespaceIndexes[tDeclarations] = tPaths;
        return tPaths;
    end

    
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
        local tBatchNamespaces = indexNamespaces(tBatch);
        local tEnumNamespaces = indexNamespaces(tEnums);
        local tResolvedClasses = {};
        local nRevision = Model.Revision;

        --[[!
        @fqxn LuaEx.LXC.Environment.resolveClass
        @desc Caches class-resolution hits and misses for this declaring scope.
            A published class invalidates both: later declarations can introduce
            a match, change lexical precedence or make imported names ambiguous.
            Host values and enum bindings are deliberately not stored here.
        @param string sName Class name to resolve.
        @ret table|nil tFound Internal definition, still checked by the caller.
        @vis internal
        !]]
        local function fResolveClass(sName)
            if (nRevision ~= Model.Revision) then
                tResolvedClasses = {};
                nRevision = Model.Revision;
            end

            local vFound = tResolvedClasses[sName];
            if (vFound == nil) then
                vFound = Model.resolve(sName, tClass, tBatch) or false;
                tResolvedClasses[sName] = vFound;
            end

            return vFound or nil;
        end

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
                for sPart in _gmatch(sFull, '[^.]+') do
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
            for sPart in _gmatch(sPath, '[^.]+') do
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

                    if (tBatchNamespaces[sFull] or Model.NamespacePaths[sFull]) then return fNamespace(sFull); end
                    local oEnum = fEnum(sFull);
                    if (oEnum) then return oEnum; end
                    if (tEnumNamespaces[sFull]) then return fNamespace(sFull); end
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

                local tFound = fResolveClass(sKey);
                if (tFound) then
                    fCheckClass(tFound, tClass);
                    return tFound.Object;
                end
                if (tBatchNamespaces[sKey] or Model.NamespacePaths[sKey]) then return fNamespace(sKey); end
                local oEnum = fEnum(sKey) or fEnum(tClass.Namespace..'.'..sKey);
                for _, sImport in ipairs(tClass.Imports) do
                    local oOther = fEnum(sImport..'.'..sKey);
                    assert(not oOther or not oEnum or rawequal(oEnum, oOther), 'Ambiguous enum: '..sKey);
                    oEnum = oEnum or oOther;
                end
                if (oEnum) then return oEnum; end
                if (tEnumNamespaces[sKey]) then return fNamespace(sKey); end
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


