--[[!
@fqxn LuaEx.LXC.Directives
@desc Resolves LXC type annotations at compilation and checks stored values only
    at creation completion. Never changes inferred slot types or invokes accessors.
!]]
local _ipairs, _pairs, _rawequal, _error = ipairs, pairs, rawequal, error;
return function(Model, Diagnostics)
    local Directives = {};
    local tPrimitives = {boolean = true, number = true, string = true, table = true,
        ['function'] = true, thread = true, userdata = true};

    --[[!
    @fqxn LuaEx.LXC.Directives.resolve
    @desc Resolves annotation names after the complete inheritance graph is linked.
        Type references do not add static initialization dependencies.
    @param table tOrder Dependency-ordered selected classes.
    @param table tBatch Selected class definitions.
    !]]
    function Directives.resolve(tOrder, tBatch)
        for _, tClass in _ipairs(tOrder) do
            for _, tMember in _ipairs(tClass.Members) do
                local tAnnotation = tMember.TypeAnnotation;
                if (tAnnotation) then
                    local tType;
                    if (not tPrimitives[tAnnotation.Name]) then
                        tType = Diagnostics.run(tMember, Model.resolve, tAnnotation.Name, tClass, tBatch);
                        if (not tType or not Model.visible(tType, tClass)) then
                            _error(Diagnostics.format(tMember, 'Unresolved or inaccessible @type: '..tAnnotation.Name), 0);
                        end
                    end
                    tMember.TypeContract = {Name = tAnnotation.Name, Class = tType,
                        Nullable = tAnnotation.Nullable};
                end
                if (tMember.Kind == 'property' and tMember.Overrides) then
                    local tInherited = tMember.Overrides.TypeContract;
                    local tOwn = tMember.TypeContract;
                    if (tInherited and tOwn) then
                        local bCompatible = tInherited.Class == tOwn.Class and
                            (tOwn.Class ~= nil or tInherited.Name == tOwn.Name) and
                            tInherited.Nullable == tOwn.Nullable;
                        if (not bCompatible) then _error(Diagnostics.format(tMember, 'Conflicting overridden @type.'), 0); end
                    elseif (tOwn and not tInherited) then
                        _error(Diagnostics.format(tMember, 'An override cannot introduce a new @type storage contract.'), 0);
                    end
                    tMember.TypeContract = tInherited;
                end
            end
        end
    end

    --[[!
    @fqxn LuaEx.LXC.Directives.prepare
    @desc Precomputes annotated storage lists after accessor compilation identifies
        contextual field use. A computed property retains metadata without checks.
    @param table tOrder Compiled classes, parents before descendants.
    !]]
    function Directives.prepare(tOrder)
        for _, tClass in _ipairs(tOrder) do
            tClass.AnnotatedInstance, tClass.AnnotatedStatic = {}, {};
            local tHierarchy, tOwner = {}, tClass;
            while (tOwner) do tHierarchy[#tHierarchy + 1] = tOwner; tOwner = tOwner.Parent; end
            for n = #tHierarchy, 1, -1 do
                for _, tMember in _ipairs(tHierarchy[n].Members) do
                    if (tMember.TypeContract and not tMember.Overrides) then
                        local tEffective = tMember;
                        -- Dynamic property overrides share the original slot.
                        if (tMember.Kind == 'property' and tMember.Visibility ~= 'private' and not tMember.Flags.static) then
                            tEffective = Model.member(tClass, tMember.Owner, tMember.Name);
                        end
                        local bStored = tMember.Kind == 'field' or tMember.Initializer ~= nil;
                        local tImplementation = tEffective;
                        while (tImplementation) do
                            for _, tAccessor in _pairs(tImplementation.Accessors or {}) do
                                bStored = bStored or not tAccessor.Body or tAccessor.UsesBacking;
                            end
                            tImplementation = tImplementation.Overrides;
                        end
                        if (bStored) then
                            local tTarget = tMember.Flags.static and tClass.AnnotatedStatic or tClass.AnnotatedInstance;
                            -- Static validation belongs only to the declaring class.
                            if (not tMember.Flags.static or tMember.Owner == tClass) then
                                tTarget[#tTarget + 1] = tMember;
                            end
                        end
                    end
                end
            end
        end
    end

    --[[!
    @fqxn LuaEx.LXC.Directives.check
    @desc Validates private annotated slots once at the requested completion boundary.
    @param table tState Instance or declaring static state.
    @param boolean bStatic Whether this is declaring-class static completion.
    @param table tObjects Private canonical instance registry.
    @param table tClasses Private canonical class registry.
    @param table oNull Runtime null singleton.
    !]]
    function Directives.check(tState, bStatic, tObjects, tClasses, oNull)
        local tClass = tState.Class;
        local tMembers = bStatic and tClass.AnnotatedStatic or tClass.AnnotatedInstance;
        for _, tMember in _ipairs(tMembers or {}) do
            local tSlot = (bStatic and tClass.Static or tState.Values)[tMember];
            local tContract = tMember.TypeContract;
            local vValue = tSlot and tSlot.Value;
            local bValid = false;
            if (_rawequal(vValue, oNull)) then bValid = tContract.Nullable;
            elseif (vValue ~= nil) then
                local tObject = tObjects[vValue];
                if (tContract.Class) then
                    bValid = tObject ~= nil and not tObject.Failed and not tObject.Class.Discarded and
                        Model.descends(tObject.Class, tContract.Class);
                else
                    -- Use the actual runtime slot type, not LuaEx's public type
                    -- display or application-replaced global functions.
                    bValid = not tObject and not tClasses[vValue] and tSlot.Type == tContract.Name;
                end
            end
            if (not bValid) then
                _error(Diagnostics.format(tMember, '@type '..tContract.Name..
                    (tContract.Nullable and '?' or '')..' is not satisfied at completion.'), 0);
            end
        end
    end

    return Directives;
end;
