--[[!
@fqxn LXC.GraphAccess
@desc Validates class-reference authority through plain graph paths and instance
    storage. Closed fields use their declaring scope; publicly readable storage
    also uses the returning caller's scope. Forged snapshots cannot transplant a
    hidden factory into an unrelated holder or an exposed field.
!]]
return function(Model)
    local GraphAccess = {};

    --[[!
    @fqxn LXC.GraphAccess.validate
    @param table tGraph Schema-validated or internally generated graph records.
    @param table tCaller Using-scope class, or nil for external code.
    @param table tDefinitions Optional snapshot-local qualified class records.
    @desc Checks storage authority and directly readable graph paths from the
        root. Tracks each node/scope pair, including aliased public/private paths.
        Uses a worklist so aliases/cycles never recurse.
    !]]
    function GraphAccess.validate(tGraph, tCaller, tDefinitions)
        local tPending, tSeen = {{Value = tGraph.Root, Scope = tCaller}}, {};

        local function fFind(sName)
            return assert((tDefinitions and tDefinitions[sName]) or Model.Classes[sName], 'Missing saved class: '..sName);
        end

        local function fPush(tValue, tScope)
            tPending[#tPending + 1] = {Value = tValue, Scope = tScope};
        end

        -- Storage is validated under its actual declaration's authority. Also
        -- validate direct fields/automatic getters that the recipient can read.
        -- Custom getters execute their own authored access decisions at runtime.
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
