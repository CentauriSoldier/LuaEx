--[[!
@fqxn LXC.Model
@desc Private definition graph, lexical lookup, visibility, and compile-time
    validation. A factory instance belongs to one LXC runtime, never package.loaded.
!]]
return function(ValidationFactory, Diagnostics, Names, Operators)
    local Model = {Classes = {}};

    --[[!
    @fqxn LXC.Model.descends
    @desc Inclusive ancestry check on registered internal class records.
    !]]
    function Model.descends(tClass, tBase)
        while (tClass) do if (tClass == tBase) then return true; end; tClass = tClass.Parent; end
        return false;
    end

    --[[!
    @fqxn LXC.Model.allowed
    @desc Class-owned private rights flow into lexical nested types, never siblings.
        Protected rights also permit descendant declaring contexts.
    !]]
    function Model.allowed(sVisibility, tOwner, tCaller)
        if (sVisibility == 'public') then return true; end
        while (tCaller) do
            if (tCaller == tOwner or (sVisibility == 'protected' and Model.descends(tCaller, tOwner))) then return true; end
            tCaller = tCaller.Outer;
        end
        return false;
    end

    --[[!
    @fqxn LXC.Model.memberAllowed
    @desc Applies declaring-class rights and the C#-guided protected receiver
        restriction. A derived scope may use protected instance state through
        its own type or descendants, never an arbitrary base/sibling instance.
    @param table tMember Member or accessor definition.
    @param table tCaller Lexical declaring class, or nil for external code.
    @param table tReceiver Concrete receiver class.
    @ret boolean Whether this member operation is permitted.
    !]]
    function Model.memberAllowed(tMember, tCaller, tReceiver)
        -- Overrides preserve the original access contract. Dynamic selection
        -- must not revoke the declaring base's rights to its own virtual member.
        if (tMember.Kind == 'accessor') then
            tMember = (tMember.Property.Slot or tMember.Property).Accessors[tMember.Name];
        else
            while (tMember.Overrides) do tMember = tMember.Overrides; end
        end
        if (tMember.Visibility ~= 'protected' or tMember.Flags.static) then
            return Model.allowed(tMember.Visibility, tMember.Owner, tCaller);
        end

        while (tCaller) do
            if (tCaller == tMember.Owner) then return true; end
            if (Model.descends(tCaller, tMember.Owner) and Model.descends(tReceiver, tCaller)) then return true; end
            tCaller = tCaller.Outer;
        end

        return false;
    end

    --[[!
    @fqxn LXC.Model.visible
    @desc Checks every enclosing visibility boundary for a class reference.
    @param table tClass Candidate internal class record.
    @param table tCaller Lexical class, or nil for an external caller.
    @ret boolean Whether the caller can name/use this class.
    !]]
    function Model.visible(tClass, tCaller)
        while (tClass) do
            if (tClass.Outer and not Model.allowed(tClass.Visibility, tClass.Outer, tCaller)) then return false; end
            tClass = tClass.Outer;
        end
        return true;
    end

    --[[!
    @fqxn LXC.Model.member
    @desc Resolve private storage lexically before dynamic inherited members.
    !]]
    function Model.member(tClass, tCaller, sName)
        local tScope = tCaller;
        while (tScope) do
            local tOwn = tScope.ByName[sName];
            if (Model.descends(tClass, tScope) and tOwn and tOwn.Visibility == 'private') then return tOwn; end
            tScope = tScope.Outer;
        end
        while (tClass) do
            if (tClass.ByName[sName]) then return tClass.ByName[sName]; end
            tClass = tClass.Parent;
        end
    end

    --[[!
    @fqxn LXC.Model.resolve
    @desc Searches lexical types, the current namespace and imports in that order.
        Reports ambiguous imports. Visibility is checked by the using operation.
    @param string sName Simple or fully qualified class name.
    @param table tOwner Declaring class supplying lookup scope/imports.
    @param table tBatch Definitions in the current load transaction.
    @ret table|nil Matching class record, never a public reference.
    !]]
    function Model.resolve(sName, tOwner, tBatch)
        local function fFind(sFull) return tBatch[sFull] or Model.Classes[sFull]; end
        if (string.find(sName, '.', 1, true)) then
            local tQualified = fFind(sName);
            if (tQualified) then return tQualified; end
        end
        local tScope = tOwner;
        while (tScope) do
            local tFound = fFind(tScope.FullName..'.'..sName);
            if (tFound) then return tFound; end
            if (tScope.Name == sName) then return tScope; end
            local tParent = tScope.Parent;
            while (tParent) do
                local tInherited = tParent.Nested[sName];
                if (tInherited and Model.visible(tInherited, tOwner)) then return tInherited; end
                tParent = tParent.Parent;
            end
            tScope = tScope.Outer;
        end
        local tFound = fFind(tOwner.Namespace..'.'..sName);
        if (tFound) then return tFound; end
        for _, sImport in ipairs(tOwner.Imports) do
            local tOther = fFind(sImport..'.'..sName);
            assert(not tOther or not tFound or tOther == tFound, 'Ambiguous class: '..sName);
            tFound = tOther or tFound;
        end
        return tFound;
    end

    local Validation = ValidationFactory(Model, Diagnostics, Names, Operators);

    --[[!
    @fqxn LXC.Model.validate
    @desc Resolves the complete dependency graph and validates declarations before
        application code runs. Returns parent/dependency-first class records.
    @param table tBatch Qualified-name-to-definition map for this transaction.
    @ret table Ordered class definitions; already-published definitions are skipped.
    !]]
    function Model.validate(tBatch)
        local tOrder, tActive, tDone = {}, {}, {};

        --[[!
        @fqxn LXC.Model.validate.enter
        @desc Validates the header and resolves the immediate parent. Parent
            completion precedes dependency-access and member-contract checks.
        !]]
        local function fEnter(tClass)
            Validation.class(tClass);
            if (tClass.ParentName) then
                tClass.Parent = assert(Model.resolve(tClass.ParentName, tClass, tBatch), 'Missing parent: '..tClass.ParentName);
            end
        end

        --[[!
        @fqxn LXC.Model.validate.dependencies
        @desc Validates a completed parent and resolves explicit dependencies
            under the now-established full ancestry of the using class.
        !]]
        local function fDependencies(tClass)
            if (tClass.Parent) then Validation.parent(tClass); end
            local tDependencies = {};
            for _, sName in ipairs(tClass.requires or {}) do
                local tRequired = assert(tBatch[sName] or Model.Classes[sName], 'Missing required class: '..sName);
                assert(Model.visible(tRequired, tClass), 'Inaccessible dependency: '..sName);
                tDependencies[#tDependencies + 1] = tRequired;
            end
            return tDependencies;
        end

        --[[!
        @fqxn LXC.Model.validate.finish
        @desc Checks declarations only after all parent/dependency records are
            complete. Does not initialize storage or run application code.
        !]]
        local function fFinish(tClass)
            Validation.members(tClass);
            Validation.constructors(tClass);
            Validation.nested(tClass);
        end

        --[[!
        @fqxn LXC.Model.validate.push
        @desc Adds an unfinished definition to the iterative DFS work stack;
            published classes are already complete and active nodes are cycles.
        !]]
        local function fPush(tPending, tClass)
            if (tDone[tClass]) then return; end
            if (Model.Classes[tClass.FullName] == tClass) then
                tDone[tClass] = true;
                return;
            end
            if (tActive[tClass]) then
                error(Diagnostics.format(tClass, 'Dependency/inheritance cycle: '..tClass.FullName), 0);
            end
            tActive[tClass] = true;
            tPending[#tPending + 1] = {Class = tClass, Stage = 'enter'};
        end

        local tNames = {};
        for sName in pairs(tBatch) do tNames[#tNames + 1] = sName; end
        table.sort(tNames);

        -- Explicit frames avoid a pcall/C-stack level for each ancestor. There
        -- is no configured class-depth limit, and diagnostics remain per stage.
        for _, sName in ipairs(tNames) do
            local tPending = {};
            fPush(tPending, tBatch[sName]);
            while (#tPending > 0) do
                local tFrame = tPending[#tPending];
                local tClass = tFrame.Class;
                if (tFrame.Stage == 'enter') then
                    Diagnostics.run(tClass, fEnter, tClass);
                    tFrame.Stage = 'dependencies';
                    if (tClass.Parent) then fPush(tPending, tClass.Parent); end
                elseif (tFrame.Stage == 'dependencies') then
                    tFrame.Dependencies = Diagnostics.run(tClass, fDependencies, tClass);
                    tFrame.Next, tFrame.Stage = 1, 'finish';
                elseif (tFrame.Next <= #tFrame.Dependencies) then
                    local tDependency = tFrame.Dependencies[tFrame.Next];
                    tFrame.Next = tFrame.Next + 1;
                    fPush(tPending, tDependency);
                else
                    Diagnostics.run(tClass, fFinish, tClass);
                    tActive[tClass], tDone[tClass] = nil, true;
                    tOrder[#tOrder + 1] = tClass;
                    tPending[#tPending] = nil;
                end
            end
        end
        return tOrder;
    end
    return Model;
end;
