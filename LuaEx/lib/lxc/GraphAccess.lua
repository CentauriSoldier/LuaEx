--[[!
@fqxn LuaEx.LXC.GraphAccess
@desc <h3>GraphAccess — responsibility and connections</h3><p>Checks whether a saved graph would expose an
    inaccessible class reference. Persistence supplies graph descriptors; Model supplies access rules. Traversal
    considers the declaring owner of stored private values and recipients who can directly read fields or
    automatic getters. Custom getter behavior remains authored application behavior.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.GraphAccess.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Model Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Model)
    local GraphAccess = {};

    
    --[[!
    @fqxn LuaEx.LXC.GraphAccess.validate
    @desc Traverses reference/scope pairs. Checks storage under its declaration owner and directly readable
        fields/automatic getters under the recipient. Custom getter policy remains authored code. Visited
        node/scope pairs terminate cycles without losing distinct checks.
    @param table tGraph Decoded Root/Nodes descriptor graph, not live instance state.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @param table|nil tDefinitions Optional qualified-name definition map for the current snapshot batch.
    @ret nil No return value; raises for inaccessible class references.
    @vis internal
    !]]
    function GraphAccess.validate(tGraph, tCaller, tDefinitions)
        local tPending, tSeen = {{Value = tGraph.Root, Scope = tCaller}}, {};

        --[[!
        @fqxn LuaEx.LXC.GraphAccess.validate.find
        @desc Resolves a saved qualified class name from supplied snapshot definitions or the published
            registry; absent definitions fail.
        @param string sName Name/path to resolve or inspect under the lookup rules described above.
        @ret table tClass Resolved definition.
        @vis internal
        !]]
        local function fFind(sName)
            return assert((tDefinitions and tDefinitions[sName]) or Model.Classes[sName], 'Missing saved class: '..sName);
        end

        --[[!
        @fqxn LuaEx.LXC.GraphAccess.validate.push
        @desc Queues a descriptor together with the class scope allowed to receive it.
        @param table tValue One encoded descriptor/metadata record to validate or translate.
        @param table tScope Class environment supplied to compilation or registered for lexical ownership.
        @ret nil No return value; extends the worklist.
        @vis internal
        !]]
        local function fPush(tValue, tScope)
            tPending[#tPending + 1] = {Value = tValue, Scope = tScope};
        end

        -- Storage is validated under its actual declaration's authority. Also
        -- validate direct fields/automatic getters that the recipient can read.
        -- Custom getters execute their own authored access decisions at runtime.
        --[[!
        @fqxn LuaEx.LXC.GraphAccess.validate.instance
        @desc Visits actual instance storage across ancestors. Queues declaration-owned values and accessible
            recipient-facing values; overriding automatic getters reuse the original property slot.
        @param table tNode One graph/publication-tree node as described by this operation.
        @param table tScope Class environment supplied to compilation or registered for lexical ownership.
        @ret nil No return value; schedules access checks.
        @vis internal
        !]]
        local function fInstance(tNode, tScope)
            local tConcrete = fFind(tNode.Class);
            local tClass = tConcrete;
            while (tClass) do
                for _, tMember in ipairs(tClass.Members) do
                    if (tMember.Kind ~= 'method' and not tMember.Flags.static and not tMember.Overrides) then
                        local sKey = tClass.FullName..':'..tMember.Name;
                        local tSaved = assert(tNode.Fields[sKey], 'Missing saved field: '..sKey);
                        fPush(tSaved.Value, tMember.Owner);
                        if (Model.memberAllowed(tMember, tScope, tConcrete)) then
                            local tEffective = Model.member(tConcrete, tScope, tMember.Name);
                            local tGetter = tMember.Accessors and tMember.Accessors.get;
                            if (tEffective and tEffective.Kind == 'property' and tEffective.Slot == tMember) then
                                tGetter = tEffective.Accessors.get;
                            end
                            if (tMember.Kind == 'field' or (tGetter and not tGetter.Body and
                                Model.memberAllowed(tGetter, tScope, tConcrete))) then
                                fPush(tSaved.Value, tScope);
                            end
                        end
                    end
                end
                tClass = tClass.Parent;
            end
        end

        while (#tPending > 0) do
            local tPendingValue = table.remove(tPending);
            local nID, tScope = tPendingValue.Value.Ref, tPendingValue.Scope;
            local vScopeKey = tScope or false;
            if (nID and not (tSeen[nID] and tSeen[nID][vScopeKey])) then
                tSeen[nID] = tSeen[nID] or {};
                tSeen[nID][vScopeKey] = true;
                local tNode = tGraph.Nodes[nID];
                if (tNode.Kind == 'class') then
                    local tClass = fFind(tNode.Class);
                    assert(Model.visible(tClass, tScope) or Model.visible(tClass, tCaller),
                        'Cannot persist inaccessible class reference.');
                elseif (tNode.Kind == 'host') then
                    for _, tValue in ipairs(tNode.Captures) do fPush(tValue, tScope); end
                elseif (tNode.Kind == 'table') then
                    for _, tEntry in ipairs(tNode.Entries) do
                        fPush(tEntry[1], tScope);
                        fPush(tEntry[2], tScope);
                    end
                elseif (tNode.Kind == 'instance') then fInstance(tNode, tScope);
                end
            end
        end
    end

    return GraphAccess;
end;
