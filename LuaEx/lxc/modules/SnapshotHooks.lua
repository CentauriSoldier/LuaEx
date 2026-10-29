--[[!
@fqxn LXC.SnapshotHooks
@desc Class-owned snapshot preparation and validation, without constructors.
    Hooks receive a projection of their declaring level's fields, never runtime
    registries. Prepared values must preserve each field's established contract.
!]]
return function(Runtime)
    local Hooks = {};
    local _, _, fWrite, _, _, fInvoke = Runtime.services();
    local tVisibility = {private = 'pri', protected = 'pro', public = 'pub'};

    --[[!
    @fqxn LXC.SnapshotHooks.project
    @desc Builds a declaration-owned field projection. Hooks replace projected
        values; they should not mutate referenced input tables during preparation.
    !]]
    local function fProject(tState, tOwner)
        local tProjection, tMembers = {pri = {}, pro = {}, pub = {}}, {};
        for _, tMember in ipairs(tOwner.Members) do
            if (tMember.Kind ~= 'method' and not tMember.Flags.static and not tMember.Overrides) then
                local tSlot = assert(tState.Values[tMember], 'Snapshot requires complete instance state.');
                local sVisibility = tVisibility[tMember.Visibility];
                tProjection[sVisibility][tMember.Name] = tSlot.Value;
                tMembers[#tMembers + 1] = {Member = tMember, Slot = tSlot, Visibility = sVisibility};
            end
        end
        return tProjection, tMembers;
    end

    --[[!
    @fqxn LXC.SnapshotHooks.find
    @desc Finds a class-owned hook through inheritance. Returns an internal
        definition only to injected runtime services, never to application code.
    !]]
    function Hooks.find(tClass, sName)
        while (tClass) do
            local tHook = tClass.ByName[sName];
            if (tHook) then
                assert(tHook.Kind == 'method' and not tHook.Flags.static, 'Snapshot hook must be an instance method: '..sName);
                return tHook;
            end
            tClass = tClass.Parent;
        end
    end

    --[[!
    @fqxn LXC.SnapshotHooks.prepare
    @desc Invokes each declaring class's preparation hook and returns only the
        replacement values; original slots retain their values, types and locks.
        The selected serialize operator edits its owner's projection in place.
    !]]
    function Hooks.prepare(tState)
        local tValues, tClass = {}, tState.Class;
        local tOperator = Hooks.find(tClass, '__serialize');
        while (tClass) do
            local tHook = tClass.ByName.prepareSnapshot;
            local bOperator = tOperator and tOperator.Owner == tClass;
            if (tHook or bOperator) then
                local tProjection, tMembers = fProject(tState, tClass);
                if (tHook) then fInvoke(tState, tHook, tProjection); end
                if (bOperator) then fInvoke(tState, tOperator, tProjection); end
                for _, tEntry in ipairs(tMembers) do
                    local tMember, tSlot = tEntry.Member, tEntry.Slot;
                    local vValue = tProjection[tEntry.Visibility][tMember.Name];
                    local tTrial = {Member = tMember, Type = tSlot.Type};
                    fWrite(tTrial, vValue, true);
                    assert(tTrial.Type == tSlot.Type, 'Preparation cannot change a field type.');
                    tValues[tMember] = vValue;
                end
            end
            tClass = tClass.Parent;
        end
        return tValues;
    end

    --[[!
    @fqxn LXC.SnapshotHooks.validate
    @desc Runs parent-first validation after all restored graph values exist.
        Changed cache values still obey typing and readonly binding restrictions.
    @param boolean bDeserialize Enables the selected deserialize operator only
        for restoration, never for the generic clone validation path.
    !]]
    function Hooks.validate(tState, bDeserialize)
        local tHierarchy, tClass = {}, tState.Class;
        local tOperator = bDeserialize and Hooks.find(tClass, '__deserialize');
        while (tClass) do tHierarchy[#tHierarchy + 1] = tClass; tClass = tClass.Parent; end
        for n = #tHierarchy, 1, -1 do
            local tOwner = tHierarchy[n];
            local tHook = tOwner.ByName.validateSnapshot;
            local bOperator = tOperator and tOperator.Owner == tOwner;
            if (tHook or bOperator) then
                local tProjection, tMembers = fProject(tState, tOwner);
                if (tHook) then fInvoke(tState, tHook, tProjection); end
                if (bOperator) then fInvoke(tState, tOperator, tProjection); end
                for _, tEntry in ipairs(tMembers) do
                    local vValue = tProjection[tEntry.Visibility][tEntry.Member.Name];
                    if (not rawequal(vValue, tEntry.Slot.Value)) then fWrite(tEntry.Slot, vValue, false); end
                end
            end
        end
    end

    return Hooks;
end;
