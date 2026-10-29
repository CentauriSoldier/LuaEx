--[[!
@fqxn LuaEx.LXC.Model
@desc <h3>Model — responsibility and connections</h3><p>Stores published class definitions and shared rules for
    name resolution, ancestry and access. Parser creates records; Model links parents and orders batches;
    Validation checks contracts. Runtime, Environment, Helpers and graph services reuse these queries so source
    validation and live access follow the same model.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
@field table Classes Published definitions keyed by exact qualified name; pending batches remain separate until
    successful publication.
!]]

--[[!
@fqxn LuaEx.LXC.Model.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param function ValidationFactory Private injected dependency; its role is described in the module map.
@param table Diagnostics Private injected dependency; its role is described in the module map.
@param table Names Private injected dependency; its role is described in the module map.
@param table Operators Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(ValidationFactory, Diagnostics, Names, Operators)
    local Model = {Classes = {}};

    
    --[[!
    @fqxn LuaEx.LXC.Model.descends
    @desc Follows Parent links including equality. Internal ancestry/type checks treat a class as its own
        ancestor; Helpers.ischild adds strict inequality.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param table tBase Ancestor/base class definition for the comparison.
    @ret boolean bMatch Whether class is or descends from base.
    @vis internal
    !]]
    function Model.descends(tClass, tBase)
        while (tClass) do if (tClass == tBase) then return true; end; tClass = tClass.Parent; end
        return false;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Model.allowed
    @desc Checks caller and enclosing lexical classes. Public always permits access; private admits
        owner/lexical descendants; protected additionally admits inheritance descendants.
    @param string sVisibility public, protected or private visibility spelling.
    @param table tOwner Class definition that declares this code or storage.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @ret boolean bAllowed Whether scope satisfies visibility.
    @vis internal
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
    @fqxn LuaEx.LXC.Model.memberAllowed
    @desc Uses the original override's access contract. Protected instance access also requires a receiver in
        the derived caller's branch, blocking sibling-instance access. Accessors use the original property's
        accessor contract.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @param table tReceiver Concrete receiving instance's class definition.
    @ret boolean bAllowed Whether caller may access this member/receiver.
    @vis internal
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
    @fqxn LuaEx.LXC.Model.visible
    @desc Checks every restricted enclosing level; a public nested type cannot escape a private outer
        declaration.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @ret boolean bVisible Whether the entire nesting path is accessible.
    @vis internal
    !]]
    function Model.visible(tClass, tCaller)
        while (tClass) do
            if (tClass.Outer and not Model.allowed(tClass.Visibility, tClass.Outer, tCaller)) then return false; end
            tClass = tClass.Outer;
        end
        return true;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Model.member
    @desc Selects a lexical owner's private declaration on a compatible receiver before ordinary most-derived
        lookup, preserving distinct same-name parent/child private members.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @ret table|nil tMember Selected definition or nil.
    @vis internal
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
    @fqxn LuaEx.LXC.Model.resolve
    @desc Resolves exact qualified paths, lexical/nested/inherited nested names, current namespace, then using
        namespaces. Conflicting imported matches fail. Callers separately check visibility/usability.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @param table tOwner Class definition that declares this code or storage.
    @param table tBatch Pending class definitions keyed by qualified name.
    @ret table|nil tClass Matched definition or nil.
    @vis internal
    !]]
    function Model.resolve(sName, tOwner, tBatch)
        --[[!
        @fqxn LuaEx.LXC.Model.resolve.find
        @desc Looks up an exact qualified name in pending definitions first, then the published registry.
        @param string sFull Exact fully qualified class name.
        @ret table|nil tClass Definition or nil.
        @vis internal
        !]]
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
    @fqxn LuaEx.LXC.Model.validate
    @desc Links parents and deterministically orders dependency-first initialization. Explicit work frames
        detect inheritance/requires cycles without one recursive C call per ancestor; member validation finishes
        after prerequisites.
    @param table tBatch Pending class definitions keyed by qualified name.
    @ret table tOrder Validated initialization sequence.
    @vis internal
    !]]
    function Model.validate(tBatch)
        local tOrder, tActive, tDone = {}, {}, {};

        
        --[[!
        @fqxn LuaEx.LXC.Model.validate.enter
        @desc Checks class contracts and resolves an optional parent, failing on missing parent before
            initialization.
        @param table tClass Internal class definition with names, flags, members and resolved ancestry.
        @ret nil No return value; sets Parent.
        @vis internal
        !]]
        local function fEnter(tClass)
            Validation.class(tClass);
            if (tClass.ParentName) then
                tClass.Parent = assert(Model.resolve(tClass.ParentName, tClass, tBatch), 'Missing parent: '..tClass.ParentName);
            end
        end

        
        --[[!
        @fqxn LuaEx.LXC.Model.validate.dependencies
        @desc Checks inheritance restrictions and resolves visible qualified requires entries.
        @param table tClass Internal class definition with names, flags, members and resolved ancestry.
        @ret table tDependencies Definitions to visit first.
        @vis internal
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
        @fqxn LuaEx.LXC.Model.validate.finish
        @desc Checks members, constructors and nested classes after prerequisites, preparing runtime
            override/accessor/operator metadata.
        @param table tClass Internal class definition with names, flags, members and resolved ancestry.
        @ret nil No return value; finalizes metadata.
        @vis internal
        !]]
        local function fFinish(tClass)
            Validation.members(tClass);
            Validation.constructors(tClass);
            Validation.nested(tClass);
        end

        
        --[[!
        @fqxn LuaEx.LXC.Model.validate.push
        @desc Pushes an unvisited definition, skips completed/published classes and reports an active-class
            cycle.
        @param table tPending Explicit dependency frame stack.
        @param table tClass Internal class definition with names, flags, members and resolved ancestry.
        @ret nil No return value; updates worklist/sets.
        @vis internal
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
