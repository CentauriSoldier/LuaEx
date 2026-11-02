--[[!
@fqxn LuaEx.LXE.Loader
@desc Composes parsing, validation, runtime, extensions, and persistence. A batch
    preflights completely before payload evaluation and publishes only on success.
!]]
local SourceDiscovery = require("LuaEx.lib.SourceDiscovery");

-- Keep runtime string operations independent of application replacements.
local _gmatch, _gsub, _lower, _match, _rep, _sub = string.gmatch, string.gsub, string.lower, string.match, string.rep, string.sub;


local Parser = require("LuaEx.lib.lxe.Parser");
local Registry = require("LuaEx.lib.lxe.Registry");
local Validation = require("LuaEx.lib.lxe.Validation");
local Runtime = require("LuaEx.lib.lxe.Runtime");
local Extensions = require("LuaEx.lib.lxe.Extensions");
local Persistence = require("LuaEx.lib.lxe.Persistence");
local Loader = {};

--[[!
@fqxn LuaEx.LXE.Loader.create
@desc Creates one enum system bound to the host null and serializer.
@param any oNull LuaEx null singleton.
@param table Serializer Host serializer.
@ret table Public loading/helper API.
!]]
function Loader.create(oNull, Serializer)
    local tRegistry = Registry.create();
    local Service = Runtime.create(tRegistry, oNull);
    local API = Service.helpers();
    -- Caller authority is supplied only by the connected LXC service. A second
    -- service cannot replace it, and the private transaction hook is returned
    -- only to the exact connector identity that established the connection.
    local tClassAccess, tCaller, bActive, bTouched, bGraphChecked;
    function tRegistry.Check(tRoot)
        bTouched = true;
        if (tRoot.Within and not bActive) then
            assert(tClassAccess and tClassAccess.allowed(tRoot, bActive and tCaller or nil),
                "Inaccessible class-owned enum reference: "..tRoot.FullName);
        end
    end

    --[[!
    @fqxn LuaEx.LXE.connectClasses
    @desc Connects one LXC authority provider and returns its private transaction
        runner. Rebinding to another provider fails. The public enum API exposes
        neither caller identities nor a setter for active access privileges.
    @param table tAccess Stable private LXC connector identity.
    @ret function Private caller-bound serialization runner.
    !]]
    function API.connectClasses(tAccess)
        assert(type(tAccess) == "table" and type(tAccess.allowed) == "function", "Invalid LXC access connector.");
        assert(not tClassAccess or tClassAccess == tAccess, "LXE is already connected to another class service.");
        tClassAccess = tAccess;
        return function(tOriginalCaller, fOperation, ...)
            local tPrevious, bPreviousActive, bPreviousTouched, bPreviousChecked = tCaller, bActive, bTouched, bGraphChecked;
            tCaller, bActive, bTouched, bGraphChecked = tOriginalCaller, true, false, false;
            local tResults = table.pack(pcall(fOperation, ...));
            local bUsed = bTouched;
            local bChecked = bGraphChecked;
            tCaller, bActive, bTouched, bGraphChecked = tPrevious, bPreviousActive, bPreviousTouched, bPreviousChecked;
            if (not tResults[1]) then error(tResults[2], 0); end
            assert(not bUsed or bChecked, "Enum persistence requires a validated graph.");
            return tResults[2], bUsed;
        end, function(tGraph)
            local tNodes, tDefinitions = Persistence.inspectGraph(tRegistry, tGraph);
            bGraphChecked = true;
            return tNodes, tDefinitions;
        end, function(vValue)
            -- Only registry-owned values receive an enum type contract. Public
            -- metatable strings alone cannot impersonate an LXE declaration.
            local tState = tRegistry.States[vValue];
            if (not tState) then return; end
            assert(not tState.Root.Failed, 'Discarded LXE value.');
            return tState.Parent and tState.Parent.FullName or 'enum';
        end;
    end
    Persistence.install(tRegistry, Serializer);

    --[[!
    @fqxn LuaEx.LXE.loadDeclarations
    @desc Internal LXC integration seam. The callback receives validate, initialize,
        and publish phases. All declaration validation precedes payload evaluation;
        publication callbacks must only commit already checked namespace bindings.
    @param table tRecords Parsed declaration list.
    @param table tHost Destination and expression environment.
    @param function|nil fClasses Optional coordinated class batch.
    @ret table Ordered qualified root names.
    !]]
    function API.loadDeclarations(tRecords, tHost, fClasses)
        assert(not tRegistry.Loading, "Re-entrant enum loading is forbidden.");
        local tBatch, tOrder, tExtensions = Validation.prepare(tRecords, tRegistry);
        local tTree = {Children = {}};
        for _, tRoot in ipairs(tOrder) do
            if (not tRoot.Within) then
                local tNode = tTree;
                for sPart in _gmatch(tRoot.FullName, "[^.]+") do
                    assert(not tNode.Definition, "Enum/namespace collision: "..tRoot.FullName);
                    tNode.Children[sPart] = tNode.Children[sPart] or {Children = {}};
                    tNode = tNode.Children[sPart];
                end
                assert(not tNode.Definition and next(tNode.Children) == nil, "Enum/namespace collision: "..tRoot.FullName);
                tNode.Definition = tRoot;
            elseif (not fClasses) then
                Validation.fail(tRoot, "Class-owned enum requires coordinated LXC loading.");
            end
        end
        local function fCheck(tNode, tTarget)
            for sName, tChild in pairs(tNode.Children) do
                local vExisting = rawget(tTarget, sName);
                if (tChild.Definition) then assert(vExisting == nil, "Enum binding already exists: "..sName);
                else
                    assert(vExisting == nil or (type(vExisting) == "table" and getmetatable(vExisting) == nil), "Namespace must be a plain table: "..sName);
                    fCheck(tChild, vExisting or {});
                end
            end
        end
        local function fPublish(tNode, tTarget)
            for sName, tChild in pairs(tNode.Children) do
                if (tChild.Definition) then rawset(tTarget, sName, tChild.Definition.Object);
                else
                    local tNext = rawget(tTarget, sName) or {};
                    rawset(tTarget, sName, tNext); fPublish(tChild, tNext);
                end
            end
        end
        tRegistry.Loading = true;
        local bOK, vError = pcall(function()
            fCheck(tTree, tHost);
            if (fClasses) then fClasses("validate", tOrder, tBatch); end
            for _, tRoot in ipairs(tOrder) do Service.allocate(tRoot); end
            if (fClasses) then fClasses("prepare", tOrder, tBatch); end
            Extensions.compile(tExtensions, tBatch, tRegistry, tHost);
            for _, tRoot in ipairs(tOrder) do
                local tEnvironment = Extensions.environment(tRoot, tBatch, tRegistry, tHost);
                Service.initialize(tRoot, function(tMember)
                    local fExpression = assert(load(_rep("\n", tMember.Line - 1).."return ("..
                        tMember.Expression.."\n)", "@"..tMember.File, "t", tEnvironment));
                    local bEvaluated, vValue = pcall(fExpression);
                    if (not bEvaluated) then Validation.fail(tMember, tostring(vValue)); end
                    return vValue;
                end);
            end
            if (fClasses) then fClasses("initialize", tOrder, tBatch); end
            fCheck(tTree, tHost);
            -- No application callbacks occur after this point.
            fPublish(tTree, tHost);
            for sName, tDefinition in pairs(tBatch) do tRegistry.Definitions[sName] = tDefinition; end
            if (fClasses) then fClasses("publish", tOrder, tBatch); end
        end);
        tRegistry.Loading = false;
        if (not bOK) then
            for _, tRoot in ipairs(tOrder) do tRoot.Failed = true; end
            error(vError, 0);
        end
        local tNames = {};
        for _, tRoot in ipairs(tOrder) do tNames[#tNames + 1] = tRoot.FullName; end
        return tNames;
    end

    --[[!
    @fqxn LuaEx.LXE.loadSources
    @desc Parses a filename/text map, selects @default candidates and validates the
        whole dependency batch before loading. Extensions may target an enum in
        another source file in this batch. Does not implicitly locate requires.
    @param table tSources Plain filename-to-source map.
    @param table|nil tHost Destination; defaults to the global environment.
    @ret table Ordered qualified root names.
    !]]
    function API.loadSources(tSources, tHost)
        assert(type(tSources) == "table" and getmetatable(tSources) == nil, "Supply a plain source map.");
        tHost = tHost or _G;
        assert(type(tHost) == "table", "Supply an environment table.");
        local tFiles, tRecords = {}, {};
        for pFile, sSource in pairs(tSources) do
            assert(type(pFile) == "string" and type(sSource) == "string", "Source keys/text must be strings.");
            tFiles[#tFiles + 1] = pFile;
        end
        table.sort(tFiles);
        for _, pFile in ipairs(tFiles) do
            for _, tRecord in ipairs(Parser.parse(tSources[pFile], pFile)) do tRecords[#tRecords + 1] = tRecord; end
        end
        return API.loadDeclarations(tRecords, tHost);
    end

    --[[!
    @fqxn LuaEx.LXE.loadFiles
    @desc Reads each unique source path once and closes handles on read failures.
    @param table tPaths Source paths.
    @param table|nil tHost Destination environment.
    @ret table Ordered qualified root names.
    !]]
    function API.loadFiles(tPaths, tHost)
        local tSources = {};
        for _, pFile in ipairs(tPaths) do
            if (not tSources[pFile]) then
                local hFile = assert(io.open(pFile, "rb"));
                local bOK, sSource = pcall(hFile.read, hFile, "*a");
                hFile:close(); assert(bOK, sSource); tSources[pFile] = sSource;
            end
        end
        return API.loadSources(tSources, tHost);
    end

    --[[!
    @fqxn LuaEx.LXE.discover
    @desc Delegates to SourceDiscovery and returns its sorted .lxe snapshot. The shared
        authority owns root handling, approved types and native traversal.
    @param string|nil sPackagePath Package templates; defaults to package.path.
    @ret table Sorted unique paths.
    !]]
    function API.discover(sPackagePath)
        return SourceDiscovery.scan(sPackagePath).ByExtension.lxe;
    end
    return API;
end

return Loader;


