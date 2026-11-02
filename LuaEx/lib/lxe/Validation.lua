--[[!
@fqxn LuaEx.LXE.Validation
@desc Validates declarations and calculates the complete dependency order before
    any value expression runs. Nested declarations belong to their root's load unit.
!]]
-- Keep runtime string operations independent of application replacements.
local _find = string.find;


local Validation = {};
local Selection = require("LuaEx.lib.directives.Selection");
local _tReserved = {Value = true, Ordinal = true, Name = true, Parent = true};

--[[!
@fqxn LuaEx.LXE.Validation.fail
@desc Raises an error attributed to the declaring source.
@param table tRecord Source-bearing declaration.
@param string sMessage Failure explanation.
!]]
function Validation.fail(tRecord, sMessage)
    error(tRecord.File..":"..tRecord.Line..": "..sMessage, 0);
end

--[[!
@fqxn LuaEx.LXE.Validation.prepare
@desc Resolves dependencies, nested names, extensions and compiled Lua syntax.
    Returns pending definitions and dependency-first roots without executing code.
@param table tRecords Parsed declarations.
@param table tRegistry Existing private registry.
@ret table Pending definitions, ordered roots, and extension declarations.
!]]
function Validation.prepare(tRecords, tRegistry)
    local tBatch, tRoots, tExtensions = {}, {}, {};
    local function fFail(tRecord, sMessage) Validation.fail(tRecord, sMessage); end
    local function fIndex(tDefinition, tRoot)
        if (tBatch[tDefinition.FullName] or tRegistry.Definitions[tDefinition.FullName]) then
            fFail(tDefinition, "Duplicate enum: "..tDefinition.FullName);
        end
        tBatch[tDefinition.FullName], tDefinition.Root = tDefinition, tRoot;
        tDefinition.ByName, tDefinition.Extensions = {}, {};
        if (#tDefinition.Members == 0) then fFail(tDefinition, "Enums must contain members."); end
        -- Embedded enum candidates are selected as whole member subtrees.
        local tEmbedded = {};
        for _, tMember in ipairs(tDefinition.Members) do
            if (tMember.Members) then tEmbedded[#tEmbedded + 1] = tMember; end
        end
        local tLive = {};
        for _, tMember in ipairs(Selection.choose(tEmbedded, function(tMember) return tDefinition.FullName.."."..tMember.Name; end, "enum")) do
            tLive[tMember] = true;
        end
        local tMembers = {};
        for _, tMember in ipairs(tDefinition.Members) do
            if (not tMember.Members or tLive[tMember]) then tMembers[#tMembers + 1] = tMember; end
        end
        tDefinition.Members = tMembers;
        for n, tMember in ipairs(tMembers) do
            if (_tReserved[tMember.Name] or tDefinition.ByName[tMember.Name]) then fFail(tMember, "Reserved or duplicate member: "..tMember.Name); end
            tDefinition.ByName[tMember.Name], tMember.Ordinal = tMember, n;
            tMember.FullName, tMember.Parent, tMember.Root = tDefinition.FullName.."."..tMember.Name, tDefinition, tRoot;
            if (tMember.Expression) then
                local fChunk, sError = load("return ("..tMember.Expression.."\n)", "@"..tMember.File, "t", {});
                if (not fChunk) then fFail(tMember, sError); end
            end
            if (tMember.Members) then
                tMember.Namespace, tMember.Imports = tRoot.Namespace, tRoot.Imports;
                fIndex(tMember, tRoot);
            end
        end
    end
    local tRootRecords = {};
    for _, tRecord in ipairs(tRecords) do
        if (tRecord.Kind == "extension") then tExtensions[#tExtensions + 1] = tRecord;
        else tRootRecords[#tRootRecords + 1] = tRecord; end
    end
    for _, tRecord in ipairs(Selection.choose(tRootRecords, function(tRecord) return tRecord.FullName; end, "enum")) do
        if (not tRecord.Within and tRecord.Flags.Visibility and tRecord.Flags.Visibility ~= "public") then
            fFail(tRecord, "Namespace enums must be public.");
        end
        for sFlag in pairs(tRecord.Flags) do
            if (sFlag ~= "Visibility" and sFlag ~= "public" and sFlag ~= "private" and sFlag ~= "protected") then fFail(tRecord, "Invalid enum modifier: "..sFlag); end
        end
        fIndex(tRecord, tRecord); tRoots[#tRoots + 1] = tRecord;
    end
    local function fResolve(sName, tOwner)
        local tFound = tBatch[sName];
        if (tFound) then return tFound; end
        tFound = tBatch[tOwner.Namespace.."."..sName];
        for _, sImport in ipairs(tOwner.Imports) do
            local tOther = tBatch[sImport.."."..sName];
            if (tOther and tFound and tFound ~= tOther) then fFail(tOwner, "Ambiguous enum: "..sName); end
            tFound = tFound or tOther;
        end
        return tFound;
    end
    -- Resolve first so imported/relative spellings share one extension identity.
    for _, tExtension in ipairs(tExtensions) do
        local tTarget = fResolve(tExtension.Target, tExtension);
        if (not tTarget) then fFail(tExtension, "Extension target must be declared in this batch: "..tExtension.Target); end
        tExtension.Definition = tTarget;
        tExtension.FullName = tTarget.FullName.."."..tExtension.Name;
    end
    tExtensions = Selection.choose(tExtensions, function(tExtension) return tExtension.FullName; end, "extension");
    for _, tExtension in ipairs(tExtensions) do
        local tTarget = tExtension.Definition;
        if (_tReserved[tExtension.Name] or tTarget.ByName[tExtension.Name] or tTarget.Extensions[tExtension.Name]) then
            fFail(tExtension, "Extension name collision: "..tExtension.Name);
        end
        tTarget.Extensions[tExtension.Name], tExtension.Definition = tExtension, tTarget;
        local fChunk, sError = load("return function("..table.concat(tExtension.Parameters, ",")..")\n"..tExtension.Body.."\nend", "@"..tExtension.File, "t", {});
        if (not fChunk) then fFail(tExtension, sError); end
    end
    -- An embedded member also exposes its parent's extensions. Its own child
    -- names must not silently hide those callable members.
    for _, tDefinition in pairs(tBatch) do
        if (tDefinition.Parent) then
            for sName in pairs(tDefinition.Parent.Extensions) do
                if (tDefinition.ByName[sName]) then fFail(tDefinition, "Embedded member/extension collision: "..sName); end
            end
        end
    end
    table.sort(tRoots, function(a, b) return a.FullName < b.FullName; end);
    local tOrder, tActive, tDone = {}, {}, {};
    local function fVisit(tRoot)
        if (tDone[tRoot]) then return; end
        if (tActive[tRoot]) then fFail(tRoot, "Enum dependency cycle: "..tRoot.FullName); end
        tActive[tRoot] = true;
        local tSeen = {};
        for _, sName in ipairs(tRoot.Requires or {}) do
            if (not _find(sName, "%.") or tSeen[sName] or sName == tRoot.FullName) then fFail(tRoot, "Invalid requires entry: "..sName); end
            tSeen[sName] = true;
            local tRequired = tBatch[sName] or tRegistry.Definitions[sName];
            if (not tRequired) then fFail(tRoot, "Missing required enum: "..sName); end
            if (tRequired.Root == tRoot) then fFail(tRoot, "Enum cannot require itself or its children."); end
            if (tBatch[sName]) then fVisit(tRequired.Root); end
        end
        tActive[tRoot], tDone[tRoot] = nil, true;
        tOrder[#tOrder + 1] = tRoot;
    end
    for _, tRoot in ipairs(tRoots) do fVisit(tRoot); end
    return tBatch, tOrder, tExtensions;
end

return Validation;

