--[[!
@fqxn LuaEx.LXC.SnapshotHooks
@desc <h3>SnapshotHooks — responsibility and connections</h3><p>Runs preparation/validation around persistence
    and automatic copying. Each hook receives pri/pro/pub tables for fields declared at its own inheritance
    level, including property backing values. Preparation edits outgoing projections; validation may update
    restored state within type/binding rules. Constructors do not run during automatic restore/copy.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.SnapshotHooks.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Runtime Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Runtime)
    local Hooks = {};
    local _, _, fWrite, _, _, fInvoke = Runtime.services();
    local tVisibility = {private = 'pri', protected = 'pro', public = 'pub'};

    
    --[[!
    @fqxn LuaEx.LXC.SnapshotHooks.project
    @desc Builds pri/pro/pub for exactly one declaring level plus entry-to-slot metadata. Values are shallow
        references: replace entries instead of mutating referenced source tables during preparation.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tOwner Class definition that declares this code or storage.
    @ret table tProjection Followed by table tMembers linking entries to slots.
    @vis internal
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
    @fqxn LuaEx.LXC.SnapshotHooks.find
    @desc Searches the class then parents for a hook/operator, rejecting a matching non-instance-method
        declaration.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @ret table|nil tHook First internal hook definition or nil.
    @vis internal
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
    @fqxn LuaEx.LXC.SnapshotHooks.prepare
    @desc Visits concrete-to-parent levels. Each prepareSnapshot and selected serialize operator edits a
        projection; trial writes enforce established types. Original slot values/types/locks are not replaced.
    @param table tState Private live state containing Class, Object and storage maps.
    @ret table tValues Replacements keyed by storage definition.
    @vis internal
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
    @fqxn LuaEx.LXC.SnapshotHooks.validate
    @desc Visits parent-to-concrete levels after graph creation. Runs validateSnapshot and, only for
        deserialize, the selected deserialize operator. Changed entries use normal writes and cannot replace
        locked const/final bindings.
    @param table tState Private live state containing Class, Object and storage maps.
    @param boolean bDeserialize Whether to include the selected deserialize operator in validation.
    @ret nil No return value; checks/updates restored state.
    @vis internal
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
