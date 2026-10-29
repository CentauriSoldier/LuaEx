--[[!
@fqxn LuaEx.LXC.Loader
@desc <h3>Loader — responsibility and connections</h3><p>Composes private services and implements the public
    load API. It parses and validates the entire batch, compiles every definition, runs ordered static
    initialization, then publishes names and registry entries. Destination collisions are checked before and
    after application initializers. Model owns definitions; Runtime owns live objects; Host provides optional
    integration.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.Loader.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param function module Private injected dependency; loads a named module from the sibling lxc directory.
@param table|nil oHostNull Private injected dependency; reuses the initialized host null singleton when
    provided.
@ret table Service returned by this module.
@vis internal
!]]
return function(module, oHostNull)
    local __lxc_guard <close> = nil;
    -- Capture native file operations before application code can change file metatables.
    local fReadFile, fCloseFile = io.stdin.read, io.stdin.close;
    local Tokens, Facades = module('Tokens'), module('Facades');
    local Diagnostics = module('Diagnostics');
    local Context, Model = module('Context')(), module('Model')(module('Validation'), Diagnostics, module('Names'), module('Operators'));
    Facades.register(Context);
    local Compiler = module('Compiler')(Tokens, Model, module('LuaScope')(Tokens));
    local Parser = module('Parser')(Tokens, module('Names'), module('Operators'));
    local Environment = module('Environment')(Model, Context, Facades);
    local Runtime = module('Runtime')(Model, Context, Facades, Compiler, Environment, Diagnostics, oHostNull, module('Operators'));
    local Hooks = module('SnapshotHooks')(Runtime);
    local Copy = module('GraphClone')(Model, Context, Runtime, Hooks);
    local Codec = module('Persistence')(Model, Context, Runtime, module('Literal')(Tokens), module('SnapshotSchema'), module('GraphAccess')(Model), Hooks);
    local Helpers = module('Helpers')(Model, Context, Runtime, Facades);
    local HostGraph = module('HostGraph')(Context, Runtime, Codec);
    local HostStaged = module('HostStaged')(Context, Runtime, Codec);
    local Host = module('Host')(Model, Context, Runtime, Facades, Copy, Codec, Helpers, HostGraph, HostStaged);
    local API = {};
    Runtime.Helpers = Helpers;

    
    --[[!
    @fqxn LuaEx.LXC.bindHost
    @desc Installs LXC into initialized LuaEx core without discovering/loading sources. Exposes class/lxc and
        graph-aware cloning/serialization; rejects a different installed class system.
    @param table tEnvironment Destination environment for namespace or host bindings.
    @ret nil No return value; updates host bindings.
    @pulsarlua function lxc.bindHost
    !]]
    function API.bindHost(tEnvironment)
        local __lxc_guard <close> = nil;
        return Host.install(Runtime.API, tEnvironment);
    end

    
    --[[!
    @fqxn LuaEx.LXC.publishFrameworkAliases
    @desc Adds short aliases for registered top-level LuaEx.Classes types after loading. Application namespaces
        are not flattened.
    @param table tNames Ordered qualified-name or restriction entries used by the surrounding operation.
    @param table tEnvironment Destination environment for namespace or host bindings.
    @ret nil No return value; publishes framework aliases.
    @pulsarlua function lxc.publishFrameworkAliases
    !]]
    function API.publishFrameworkAliases(tNames, tEnvironment)
        local __lxc_guard <close> = nil;
        return Host.publishAliases(tNames, tEnvironment);
    end

    
    --[[!
    @fqxn LuaEx.LXC.loadSources
    @desc Loads a plain filename-to-text map into a destination. Sorts filenames, validates the whole batch,
        compiles all classes and runs dependency-ordered static initialization before registry/namespace
        publication. Duplicate classes, reentrant loads and collisions fail. Failed initialization discards the
        batch but cannot undo application side effects.
    @param table tSources Plain filename-to-source-text map, or supplied host identity map for adapter
        callbacks.
    @param table tEnvironment Destination environment for namespace or host bindings.
    @ret table tNames Qualified names in initialization order, including nested classes.
    @pulsarlua function lxc.loadSources
    !]]
    function API.loadSources(tSources, tEnvironment)
        local __lxc_guard <close> = nil;
        assert(not Runtime.Loading, 'Re-entrant class loading is forbidden.');
        assert(type(tSources) == 'table' and type(tEnvironment) == 'table', 'Supply sources and environment tables.');
        assert(getmetatable(tSources) == nil, 'Sources must be a plain filename-to-text map.');
        local tBatch, tFiles = {}, {};
        for pFile, sSource in pairs(tSources) do
            assert(type(pFile) == 'string' and type(sSource) == 'string', 'Source filenames and text must be strings.');
            tFiles[#tFiles + 1] = pFile;
        end
        table.sort(tFiles);
        for _, pFile in ipairs(tFiles) do
            for _, tClass in ipairs(Parser.parse(tSources[pFile], pFile)) do
                assert(not tBatch[tClass.FullName] and not Model.Classes[tClass.FullName], 'Duplicate class: '..tClass.FullName);
                tBatch[tClass.FullName] = tClass;
                tClass.Batch = tBatch;
            end
        end
        local tOrder, tTree = Model.validate(tBatch), {Children = {}};
        for _, tClass in ipairs(tOrder) do
            if (tBatch[tClass.FullName] and not tClass.Outer) then
                local tNode = tTree;
                for sPart in string.gmatch(tClass.Namespace, '[^.]+') do
                    assert(not tNode.Class, 'Namespace/class collision.');
                    tNode.Children[sPart] = tNode.Children[sPart] or {Children = {}};
                    tNode = tNode.Children[sPart];
                end
                assert(not tNode.Children[tClass.Name] and not tNode.Class, 'Namespace/class collision.');
                tNode.Children[tClass.Name] = {Class = tClass, Children = {}};
            end
        end
        --[[!
        @fqxn LuaEx.LXC.loadSources.check
        @desc Checks raw destination bindings: namespace containers must be plain tables and class leaves
            absent. Runs before initialization and again after application callbacks may change the destination.
        @param table tNode One graph/publication-tree node as described by this operation.
        @param table tTarget Plain destination namespace table to check or populate.
        @ret nil No return value; raises on collisions.
        @vis internal
        !]]
        local function fCheck(tNode, tTarget)
            local __lxc_guard <close> = nil;
            for sName, tChild in pairs(tNode.Children) do
                local vExisting = rawget(tTarget, sName);
                if (tChild.Class) then assert(vExisting == nil, 'Class binding already exists: '..sName);
                else
                    assert(vExisting == nil or (type(vExisting) == 'table' and getmetatable(vExisting) == nil), 'Namespace must be plain table: '..sName);
                    fCheck(tChild, vExisting or {});
                end
            end
        end
        fCheck(tTree, tEnvironment);
        Runtime.Loading = true;
        local bInitialized, vError = pcall(function()
            local __lxc_guard <close> = nil;
            Runtime.prepare(tOrder, tBatch, tEnvironment);
            for _, tClass in ipairs(tOrder) do
                Diagnostics.run(tClass.StaticConstructor or tClass, Runtime.initialize, tClass);
            end
            -- Initializers may call application functions that alter the destination.
            -- Revalidate before any publication or registry commit.
            fCheck(tTree, tEnvironment);
        end);
        Runtime.Loading = false;
        if (not bInitialized) then
            for _, tClass in pairs(tBatch) do tClass.Discarded = true; end
            error(vError, 0);
        end
        --[[!
        @fqxn LuaEx.LXC.loadSources.publish
        @desc Uses rawset to publish the preflighted tree, reusing plain namespace tables. Nested types are
            reached through class facades rather than namespace leaves.
        @param table tNode One graph/publication-tree node as described by this operation.
        @param table tTarget Plain destination namespace table to check or populate.
        @ret nil No return value; updates namespace bindings.
        @vis internal
        !]]
        local function fPublish(tNode, tTarget)
            local __lxc_guard <close> = nil;
            for sName, tChild in pairs(tNode.Children) do
                if (tChild.Class) then rawset(tTarget, sName, tChild.Class.Object);
                else
                    local tNext = rawget(tTarget, sName) or {};
                    rawset(tTarget, sName, tNext); fPublish(tChild, tNext);
                end
            end
        end
        local tNames = {};
        for _, tClass in ipairs(tOrder) do
            if (tBatch[tClass.FullName]) then
                tClass.Published = true;
                Model.Classes[tClass.FullName] = tClass; tNames[#tNames + 1] = tClass.FullName;
            end
        end
        fPublish(tTree, tEnvironment);
        return tNames;
    end

    
    --[[!
    @fqxn LuaEx.LXC.loadFiles
    @desc Reads a plain ordered path list in binary mode, closes files and calls loadSources. Read/parse errors
        abort; repeated identical filenames collapse into one source-map entry.
    @param table tPaths Plain ordered list of source filenames.
    @param table tEnvironment Destination environment for namespace or host bindings.
    @ret table tNames Names returned by loadSources.
    @pulsarlua function lxc.loadFiles
    !]]
    function API.loadFiles(tPaths, tEnvironment)
        local __lxc_guard <close> = nil;
        assert(type(tPaths) == 'table' and getmetatable(tPaths) == nil, 'Supply a plain source-path list.');
        local tSources = {};
        for _, pFile in ipairs(tPaths) do
            assert(type(pFile) == 'string', 'Source paths must be strings.');
            local hFile = assert(io.open(pFile, 'rb'));
            local bOK, sSource = pcall(fReadFile, hFile, '*a'); fCloseFile(hFile);
            assert(bOK, sSource); tSources[pFile] = sSource;
        end
        return API.loadSources(tSources, tEnvironment);
    end

    
    --[[!
    @fqxn LuaEx.LXC.discover
    @desc Extracts roots from ? package-path templates, recursively lists .lxc files, deduplicates normalized
        paths and sorts. Requires io.listfiles; io.isdir skips confirmed missing roots when available. Does not
        load classes.
    @param string|nil sPackagePath Semicolon-separated templates; nil uses package.path.
    @ret table tPaths Sorted unique source paths.
    @pulsarlua function lxc.discover
    !]]
    function API.discover(sPackagePath)
        local __lxc_guard <close> = nil;
        assert(type(io.listfiles) == 'function', 'Discovery requires io.listfiles.');
        local tRoots, tSeen, tFiles = {}, {}, {};
        for sTemplate in string.gmatch(sPackagePath or package.path, '[^;]+') do
            local sPrefix = string.match(sTemplate, '^(.-)%?');
            if (sPrefix) then
                local pRoot = string.match(sPrefix, '^(.*)[/\\]') or '.';
                if (pRoot == '') then pRoot = string.sub(sPrefix, 1, 1); end
                if (not tRoots[pRoot]) then
                    tRoots[pRoot] = true;
                    -- package.path normally contains optional, absent directories.
                    -- Skip confirmed missing roots as require does; errors from
                    -- listing an existing root still propagate to the caller.
                    if (not io.isdir or io.isdir(pRoot)) then
                        local tFound, sReason = io.listfiles(pRoot, true, nil, 'lxc'); assert(tFound, sReason);
                        for _, pFile in ipairs(tFound) do
                            local pKey = string.gsub(string.gsub(pFile, '\\', '/'), '/%./', '/');
                            if (string.sub(package.config, 1, 1) == '\\') then pKey = string.lower(pKey); end
                            if (not tSeen[pKey]) then tSeen[pKey] = true; tFiles[#tFiles + 1] = pFile; end
                        end
                    end
                end
            end
        end
        table.sort(tFiles); return tFiles;
    end

    API.class, API.null = Helpers, Runtime.Null;
    for _, sName in ipairs({'serialize', 'deserialize', 'clone', 'saveStatic', 'loadStatic'}) do API[sName] = Codec[sName]; end
    API.clone = Copy.clone;
    for _, fFunction in pairs(API) do if (type(fFunction) == 'function') then Context.internal(fFunction); end end
    local oAPI = Facades.create({__index = function(sName)
        local __lxc_guard <close> = nil;
        return API[sName];
    end,
        --[[!
        @fqxn LuaEx.LXC.Loader.__newindex
        @desc Rejects mutation of the public LXC API facade.
        @ret nil Never returns successfully; raises a read-only/view error.
        @vis internal
        !]]
        __newindex = function()
            local __lxc_guard <close> = nil;
            error('LXC API is read-only.');
        end});
    Runtime.API = oAPI;
    return oAPI;
end;
