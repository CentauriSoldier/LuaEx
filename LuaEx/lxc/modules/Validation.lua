--[[!
@fqxn LXC.Validation
@desc Declaration contracts, separated from graph traversal and name resolution.
    Model supplies ancestry/access queries. All checks run before application
    initializers; this module never publishes classes or executes method bodies.
!]]
return function(Model, Diagnostics, Names, Operators)
    local Validation = {};
    local tRanks = {private = 1, protected = 2, public = 3};

    --[[!
    @fqxn LXC.Validation.class
    @desc Checks class modifiers and qualified dependency/subclass-list entries.
    @param table tClass Parsed class record.
    !]]
    function Validation.class(tClass)
        local tFlags = tClass.Flags;
        assert(tClass.Outer or tClass.Visibility == 'public', 'Namespace classes must be public.');
        assert(not (tFlags.abstract and tFlags.final), 'abstract final class is invalid.');
        assert(not tFlags.static and not tFlags.const and not tFlags.override, 'Invalid class modifier.');
        assert(not (tClass.permits and tClass.excludes), 'Cannot combine permits and excludes.');

        for _, sClause in ipairs({'permits', 'excludes', 'requires'}) do
            local tNames = tClass[sClause];
            if (tNames) then
                local tSeen = {};
                assert(#tNames > 0, 'Empty '..sClause..' clause.');
                for _, sName in ipairs(tNames) do
                    assert(string.find(sName, '.', 1, true), 'Clause entries must be fully qualified: '..sName);
                    assert(not tSeen[sName] and sName ~= tClass.FullName, 'Duplicate/self clause entry: '..sName);
                    tSeen[sName] = true;
                end
            end
        end
    end

    --[[!
    @fqxn LXC.Validation.domainImplies
    @desc Tests whether one nested declaration restriction implies another.
        Private domains include lexical descendants; protected domains also
        include inheritance descendants. Public declarations add no restriction.
    !]]
    local function fDomainImplies(tRestriction, tRequired)
        if (tRestriction.Visibility == 'private') then
            return Model.allowed(tRequired.Visibility, tRequired.Outer, tRestriction.Outer);
        end
        if (tRestriction.Visibility == 'protected' and tRequired.Visibility == 'protected') then
            return Model.descends(tRestriction.Outer, tRequired.Outer);
        end
        return false;
    end

    --[[!
    @fqxn LXC.Validation.baseDomain
    @desc Every restricted enclosing level of a base must also restrict access
        to the derived declaration. Compare whole nesting domains, not ranks.
    !]]
    local function fBaseDomain(tClass, tBase)
        while (tBase and tBase.Outer) do
            if (tBase.Visibility ~= 'public') then
                local tScope, bCovered = tClass, false;
                while (tScope and tScope.Outer) do
                    if (fDomainImplies(tScope, tBase)) then bCovered = true; break; end
                    tScope = tScope.Outer;
                end
                assert(bCovered, 'Derived class has wider accessibility than its base: '..tClass.FullName);
            end
            tBase = tBase.Outer;
        end
    end

    --[[!
    @fqxn LXC.Validation.parent
    @desc Validates accessibility, final inheritance and direct-child restrictions.
    @param table tClass Class whose Parent has already been resolved and validated.
    !]]
    function Validation.parent(tClass)
        local tParent = tClass.Parent;
        assert(not tParent.Flags.final, 'Cannot inherit final class: '..tParent.FullName);
        assert(Model.visible(tParent, tClass.Outer), 'Inaccessible parent: '..tParent.FullName);
        fBaseDomain(tClass, tParent);

        local function fListed(tNames)
            for _, sName in ipairs(tNames or {}) do
                if (sName == tClass.FullName) then return true; end
            end
            return false;
        end

        assert(not tParent.permits or fListed(tParent.permits), 'Class not permitted: '..tClass.FullName);
        assert(not fListed(tParent.excludes), 'Class excluded: '..tClass.FullName);
    end

    --[[!
    @fqxn LXC.Validation.inheritedNested
    @desc Finds inherited nested-type names accessible from the derived scope.
        Such names cannot be hidden by another class, field, method or accessor.
    !]]
    local function fInheritedNested(tClass, sName)
        local tParent = tClass.Parent;
        while (tParent) do
            local tNested = tParent.Nested[sName];
            if (tNested and Model.visible(tNested, tClass)) then return tNested; end
            tParent = tParent.Parent;
        end
    end

    --[[!
    @fqxn LXC.Validation.memberModifiers
    @desc Rejects modifier combinations without a defined member meaning.
    !]]
    local function fMemberModifiers(tMember)
        local tFlags = tMember.Flags;
        assert(not (tFlags.const and tFlags.final), 'const final is redundant/invalid.');
        assert(not (tFlags.abstract and (tFlags.final or tFlags.static or tFlags.const)), 'Invalid abstract modifiers.');
        assert(not tFlags.abstract or tMember.Owner.Flags.abstract, 'Abstract member requires abstract class.');
        assert(not tFlags.abstract or tMember.Visibility ~= 'private', 'Abstract member cannot be private.');
        assert(not tFlags.abstract or tMember.Kind == 'method', 'Only methods may declare abstract member contracts.');
        assert(not tFlags.static or not tFlags.override, 'Static members cannot override.');
        assert(not tFlags.const or tMember.Kind ~= 'method', 'const method is invalid.');
        assert(tMember.Kind ~= 'field' or (not tFlags.abstract and not tFlags.override), 'Field cannot be abstract/override.');
        assert(not tFlags.const or tMember.Initializer, 'Const requires declaration initialization.');
        assert(not (tFlags.const and tMember.Kind == 'property' and tMember.Accessors.set),
            'Const property cannot declare a setter.');
    end

    --[[!
    @fqxn LXC.Validation.propertyOverride
    @desc Preserves accessor presence/visibility/names and the original backing slot.
    !]]
    local function fPropertyOverride(tMember, tInherited)
        assert(not tMember.Initializer, 'Overriding property cannot reinitialize inherited storage.');
        for _, sAccess in ipairs({'get', 'set'}) do
            local tAccess, tBase = tMember.Accessors[sAccess], tInherited.Accessors[sAccess];
            assert(not not tAccess == not not tBase, 'Override must preserve accessor set.');
            if (tAccess) then
                assert(tAccess.Visibility == tBase.Visibility, 'Override must preserve accessor visibility.');
                assert(not tAccess.ExplicitPrefix or tAccess.Prefix == tBase.Prefix, 'Conflicting accessor prefix.');
                tAccess.Prefix = tBase.Prefix;
            end
        end
    end

    --[[!
    @fqxn LXC.Validation.override
    @desc Checks override compatibility once at compilation, without call-time checks.
    !]]
    local function fOverride(tMember, tInherited)
        assert(tMember.Flags.override, 'Inherited member requires override; hiding forbidden: '..tMember.Name);
        assert(not tInherited.Flags.final, 'Cannot override final member: '..tMember.Name);
        assert(tMember.Kind ~= 'field' and tMember.Kind == tInherited.Kind, 'Cannot hide inherited member kind.');
        assert(not tMember.Flags.static and not tInherited.Flags.static, 'Static hiding is forbidden.');
        assert(tMember.Visibility == tInherited.Visibility, 'Override must preserve visibility.');
        tMember.Overrides = tInherited;

        if (tMember.Kind == 'method') then
            assert(#tMember.Parameters == #tInherited.Parameters and tMember.Variadic == tInherited.Variadic,
                'Override parameter contract mismatch: '..tMember.Name);
        else fPropertyOverride(tMember, tInherited); end
    end

    --[[!
    @fqxn LXC.Validation.property
    @desc Establishes backing-slot identity and registers generated accessor names.
    !]]
    local function fProperty(tClass, tMember, tInherited)
        assert(next(tMember.Accessors), 'Property needs an accessor.');
        tMember.Slot = tInherited and tInherited.Slot or tMember;
        for sAccess, tAccessor in pairs(tMember.Accessors) do
            assert(tRanks[tAccessor.Visibility] <= tRanks[tMember.Visibility], 'Accessor cannot widen visibility.');
            local sAlias = tAccessor.Prefix..tMember.Name;
            assert(Names.valid(sAlias), 'Invalid generated accessor name: '..sAlias);
            local tExisting = tClass.Aliases[sAlias];
            local tInheritedMember = tClass.Parent and Model.member(tClass.Parent, nil, sAlias);
            assert(not tInheritedMember or not Model.allowed(tInheritedMember.Visibility, tInheritedMember.Owner, tClass),
                'Generated accessor hides inherited member: '..sAlias);
            assert(not tClass.ByName[sAlias] and not tClass.Nested[sAlias] and not fInheritedNested(tClass, sAlias) and
                (not tExisting or (tExisting.Property.Name == tMember.Name and tExisting.Access == sAccess)),
                'Generated accessor collision: '..sAlias);
            tClass.Aliases[sAlias] = {Property = tMember, Access = sAccess};
        end
    end

    --[[!
    @fqxn LXC.Validation.member
    @desc Validates one member and updates its class's dispatch/storage contracts.
    !]]
    local function fMember(tClass, tMember)
        fMemberModifiers(tMember);
        if (type(Operators[tMember.Name]) == 'table') then
            local tContract = Operators[tMember.Name];
            assert(tMember.Kind == 'method' and not tMember.Flags.static and tMember.Visibility == 'public',
                'Operators must be public instance methods: '..tMember.Name);
            assert(#tMember.Parameters >= tContract.Min and #tMember.Parameters <= tContract.Max and
                (not tMember.Variadic or tContract.Variadic), 'Invalid operator signature: '..tMember.Name);
            tClass.Operators[tMember.Name] = tMember;
        end
        assert(tMember.Name ~= '__metatable' and tMember.Name ~= '__mode' and tMember.Name ~= '__name',
            'Metatable protection and identity metadata are owned by LXC.');
        assert(not fInheritedNested(tClass, tMember.Name), 'Member hides inherited nested class: '..tMember.Name);
        local tInherited = tClass.Parent and Model.member(tClass.Parent, nil, tMember.Name);
        if (tInherited and not Model.allowed(tInherited.Visibility, tInherited.Owner, tClass)) then tInherited = nil; end
        if (tInherited) then fOverride(tMember, tInherited);
        else assert(not tMember.Flags.override, 'No accessible override target: '..tMember.Name); end

        if (tMember.Kind == 'property') then fProperty(tClass, tMember, tInherited); end
        tClass.AbstractMembers[tMember.Name] = tMember.Flags.abstract or nil;
    end

    --[[!
    @fqxn LXC.Validation.members
    @desc Validates members in declaration order and resolves remaining abstraction.
    !]]
    function Validation.members(tClass)
        tClass.AbstractMembers, tClass.Aliases, tClass.PrivateNames, tClass.Operators = {}, {}, {}, {};
        if (tClass.Parent) then
            for k, v in pairs(tClass.Parent.AbstractMembers) do tClass.AbstractMembers[k] = v; end
            for k, v in pairs(tClass.Parent.Aliases) do tClass.Aliases[k] = v; end
            for k in pairs(tClass.Parent.PrivateNames) do tClass.PrivateNames[k] = true; end
            for k, v in pairs(tClass.Parent.Operators) do tClass.Operators[k] = v; end
        end

        for _, tMember in ipairs(tClass.Members) do
            Diagnostics.run(tMember, fMember, tClass, tMember);
            if (tMember.Visibility == 'private') then tClass.PrivateNames[tMember.Name] = true; end
        end

        assert(tClass.Flags.abstract or next(tClass.AbstractMembers) == nil,
            'Concrete class has abstract methods: '..tClass.FullName);
        for sAlias in pairs(tClass.Aliases) do
            assert(not tClass.ByName[sAlias] and not tClass.Nested[sAlias], 'Generated accessor collision: '..sAlias);
        end
    end

    --[[!
    @fqxn LXC.Validation.constructors
    @desc Checks constructor modifiers/signatures and accessible parent construction.
    !]]
    function Validation.constructors(tClass)
        for _, sKey in ipairs({'Constructor', 'StaticConstructor'}) do
            local tConstructor = tClass[sKey];
            if (tConstructor) then
                local tFlags = tConstructor.Flags;
                assert(not tFlags.final and not tFlags.const and not tFlags.abstract and not tFlags.override,
                    'Invalid constructor modifier.');
                if (sKey == 'StaticConstructor') then
                    assert(#tConstructor.Parameters == 0 and not tConstructor.Variadic and not tFlags.Visibility,
                        'Static constructor must be parameterless without visibility.');
                end
            end
        end

        if (tClass.Parent) then
            local tParentConstructor = tClass.Parent.Constructor;
            local sVisibility = tParentConstructor and tParentConstructor.Visibility or tClass.Parent.Visibility;
            assert(Model.allowed(sVisibility, tClass.Parent, tClass), 'Inaccessible parent constructor: '..tClass.Parent.FullName);
        end
    end

    --[[!
    @fqxn LXC.Validation.nested
    @desc Rejects nested declarations that hide accessible inherited names.
    !]]
    function Validation.nested(tClass)
        for sName in pairs(tClass.Nested) do
            local tInherited = tClass.Parent and Model.member(tClass.Parent, nil, sName);
            assert(not tInherited or not Model.allowed(tInherited.Visibility, tInherited.Owner, tClass),
                'Nested class hides inherited member: '..sName);
            assert(not fInheritedNested(tClass, sName), 'Nested class hides inherited nested class: '..sName);
            assert(not tClass.Aliases[sName], 'Nested class/accessor collision: '..sName);
        end
    end

    return Validation;
end;
