--[[!
@fqxn LXC.Loader
@desc Private module composition and transactional class publication. Receives
    a relative module loader; never modifies LuaEx or global package.path.
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
    @fqxn LXC.bindHost
    @desc Binds initialized LuaEx core services without discovering class files.
    !]]
    function API.bindHost(tEnvironment)
        local __lxc_guard <close> = nil;
        return Host.install(Runtime.API, tEnvironment);
    end

    --[[!
    @fqxn LXC.publishFrameworkAliases
    @desc Publishes short aliases for successfully loaded framework classes.
    !]]
    function API.publishFrameworkAliases(tNames, tEnvironment)
        local __lxc_guard <close> = nil;
        return Host.publishAliases(tNames, tEnvironment);
    end

    --[[!
    @fqxn LXC.loadSources
    @param table tSources Filename-to-source map; files execute only during staging.
    @param table tEnvironment Publication destination and final name fallback.
    @ret table Dependency-first qualified names of newly loaded classes.
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
    @fqxn LXC.loadFiles
    @desc Reads an explicit path list; loadSources owns validation/publication.
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
    @fqxn LXC.discover
    @desc Optional LuaEx io.listfiles adapter. Explicit loading is standalone.
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
        __newindex = function()
            local __lxc_guard <close> = nil;
            error('LXC API is read-only.');
        end});
    Runtime.API = oAPI;
    return oAPI;
end;
