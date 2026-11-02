--[[!
@fqxn LuaEx.LXE.Persistence
@desc Registers LXE canonical references using LuaEx's existing serializer protocol.
    Restore never executes declaration files or manufactures enum copies.
!]]
-- Keep runtime string operations independent of application replacements.
local _match = string.match;


local Persistence = {};

--[[!
@fqxn LuaEx.LXE.Persistence.install
@desc Registers one canonical restoration type with the supplied host serializer.
@param table tRegistry Private canonical enum registry.
@param table Serializer Existing LuaEx serializer.
!]]
function Persistence.install(tRegistry, Serializer)
    Serializer.registerType("lxevalue", {
        deserialize = function(tState)
            assert(type(tState) == "table" and type(tState.Path) == "string", "Invalid saved LXE reference.");
            local tDefinition = tRegistry.Definitions[tState.Path];
            if (not tDefinition) then
                -- Leaf members have canonical paths but are not enum collections.
                local sParent, sName = _match(tState.Path, "^(.*)%.([^.]+)$");
                local tParent = sParent and tRegistry.Definitions[sParent];
                tDefinition = tParent and tParent.ByName[sName];
            end
            assert(tDefinition and tDefinition.Object and not tDefinition.Root.Failed,
                "LXE declaration must already be loaded: "..tState.Path);
            tRegistry.Check(tDefinition.Root);
            return tDefinition.Object;
        end,
    });
end

--[[!
@fqxn LuaEx.LXE.Persistence.inspectGraph
@desc Resolves saved canonical references without allocating or restoring objects.
    Returns node-to-visibility-definition mappings for LXC's existing graph-access
    validator. No active registry or private enum object is returned publicly.
@param table tRegistry Private canonical registry.
@param table tGraph Host serializer descriptor graph.
@ret table Enum node IDs and visibility definitions.
!]]
function Persistence.inspectGraph(tRegistry, tGraph)
    local tEnumNodes, tDefinitions = {}, {};
    for nID, tNode in ipairs(tGraph.nodes) do
        if (tNode.kind == "object" and tNode.type == "lxevalue") then
            local tState = tNode.state and tGraph.nodes[tNode.state.node];
            assert(tState and tState.kind == "table" and #tState.entries == 1, "Invalid saved LXE reference state.");
            local tEntry = tState.entries[1];
            local sPath = tEntry.value.value;
            assert(tEntry.key.value == "Path" and type(sPath) == "string", "Invalid saved LXE reference path.");
            local tDefinition = tRegistry.Definitions[sPath];
            if (not tDefinition) then
                local sParent, sName = _match(sPath, "^(.*)%.([^.]+)$");
                local tParent = sParent and tRegistry.Definitions[sParent];
                tDefinition = tParent and tParent.ByName[sName];
            end
            assert(tDefinition and not tDefinition.Root.Failed, "LXE declaration must already be loaded: "..sPath);
            local tRoot = tDefinition.Root;
            tEnumNodes[nID] = tRoot.FullName;
            tDefinitions[tRoot.FullName] = {FullName = tRoot.FullName,
                Outer = tRoot.ClassOwner, Visibility = tRoot.Flags.Visibility or "public"};
        end
    end
    return tEnumNodes, tDefinitions;
end

return Persistence;

