--[[!
@fqxn LXC.Runtime
@desc Owns opaque class/instance identities, typed slots, constructors, property
    dispatch and static storage. All mutable state is held in private registries.
    Application rights are obtained from Context's lexical caller, not a view.
!]]
return function(Model, Context, Facades, Compiler, Environment, Diagnostics, oHostNull, Operators)
    local __lxc_guard <close> = nil;
    local Runtime = {};
    local tClasses, tObjects = setmetatable({}, {__mode = 'k'}), setmetatable({}, {__mode = 'k'});
    local oNull = oHostNull or Facades.create({
        __tostring = function() return 'null'; end,
        __index = function()
            local __lxc_guard <close> = nil;
            error('Null has no members.');
        end,
        __newindex = function()
            local __lxc_guard <close> = nil;
            error('Cannot modify null.');
        end,
    });
    Runtime.Null = oNull;

    --[[!
    @fqxn LXC.Runtime.internal
    @desc Registers a trusted runtime frame; it never supplies application privileges.
    !]]
    local function fInternal(fFunction)
        local __lxc_guard <close> = nil;
        return Context.internal(fFunction);
    end
    fInternal(fInternal);

    --[[!
    @fqxn LXC.Runtime.check
    @desc Rejects inaccessible members, including invalid protected instance receivers.
    !]]
    local function fCheck(tMember, tCaller, tReceiver)
        local __lxc_guard <close> = nil;
        assert(Model.memberAllowed(tMember, tCaller, tReceiver),
            'Cannot access '..tMember.Visibility..' member '..tMember.Owner.FullName..'.'..tMember.Name);
    end
    fInternal(fCheck);

    --[[!
    @fqxn LXC.Runtime.checkClass
    @desc Checks class lifecycle, transaction membership and effective use-site visibility.
    !]]
    local function fCheckClass(tClass, tCaller)
        local __lxc_guard <close> = nil;
        assert(not tClass.Discarded, 'Class belongs to a failed load.');
        assert(tClass.Published or (tCaller and tCaller.Batch == tClass.Batch), 'Class is not published.');
        assert(Model.visible(tClass, tCaller), 'Cannot access class '..tClass.FullName);
    end
    fInternal(fCheckClass);

    --[[!
    @fqxn LXC.Runtime.caller
    @desc Uses explicit compiled context when available. Public instance members
        without any same-name private declaration cannot depend on caller scope;
        those operations avoid stack inspection. Private-name ancestry is kept
        by Validation so this optimization cannot hide base-owned private state.
    !]]
    local function fCaller(tLookup, sName, bStatic, bBase, tLexical)
        local __lxc_guard <close> = nil;
        if (tLexical) then return tLexical; end
        if (not bStatic and not bBase and not tLookup.PrivateNames[sName]) then
            local tMember = Model.member(tLookup, nil, sName);
            if (tMember and tMember.Visibility == 'public') then return nil; end
        end
        return Context.caller();
    end
    fInternal(fCaller);

    --[[!
    @fqxn LXC.Runtime.slotOwner
    @desc Returns the original declaration owning storage shared by property overrides.
    !]]
    local function fSlotOwner(tMember)
        local __lxc_guard <close> = nil;
        return tMember.Slot or tMember;
    end

    --[[!
    @fqxn LXC.Runtime.write
    @desc Enforces slot type/ancestry constraints and binding locks on every write.
        Null placeholders do not establish a type or initialize a final binding.
    !]]
    local function fWrite(tSlot, vValue, bInitialize)
        local __lxc_guard <close> = nil;
        assert(vValue ~= nil, 'Declared fields cannot be nil.');
        assert(not tSlot.Locked, 'Cannot reassign const/final field: '..tSlot.Member.Name);
        assert(not tSlot.Member.Flags.const or bInitialize, 'Const initialized outside declaration.');
        if (tSlot.Member.Flags.final and not tSlot.Type and not bInitialize) then
            local tOwner = tSlot.Member.Owner;
            local bConstructing = tSlot.Member.Flags.static and tOwner.StaticRunning or
                (tSlot.State and tSlot.State.Constructing == tOwner);
            assert(bConstructing and Model.allowed('private', tOwner, Context.caller()),
                'Final initialization requires declaring constructor.');
        end
        if (rawequal(vValue, oNull)) then
            assert(not tSlot.Type, 'Typed field cannot return to null.');
            assert(not tSlot.Member.Flags.const, 'Const cannot start null.');
        else
            local tObject = tObjects[vValue];
            local zType = tObject and tObject.Class or (tClasses[vValue] and 'class' or type(vValue));
            if (tSlot.Type) then
                assert((type(tSlot.Type) == 'table' and tObject and Model.descends(tObject.Class, tSlot.Type)) or
                    tSlot.Type == zType, 'Field type mismatch: '..tSlot.Member.Owner.FullName..'.'..tSlot.Member.Name);
            else tSlot.Type = zType; end
            tSlot.Locked = tSlot.Member.Flags.const or tSlot.Member.Flags.final or false;
        end
        tSlot.Value = vValue;
    end
    fInternal(fWrite);

    --[[!
    @fqxn LXC.Runtime.getSlot
    @desc Selects instance or declaring-class static storage; rejects reads before initialization.
    !]]
    local function fGetSlot(tState, tMember)
        local __lxc_guard <close> = nil;
        local tRoot = fSlotOwner(tMember);
        local tValues = tMember.Flags.static and tRoot.Owner.Static or tState.Values;
        return assert(tValues[tRoot], 'Field read before initialization: '..tRoot.Name);
    end
    fInternal(fGetSlot);

    local fInvoke, fRead, fAssign, fConstruct;

    --[[!
    @fqxn LXC.Runtime.operator
    @desc Invokes the selected operator in its declaring scope. Binary two-arg
        declarations receive original operands; one-arg declarations receive the
        other operand with this bound to the selected receiver.
    !]]
    local function fOperator(tState, tLookup, sName, ...)
        local __lxc_guard <close> = nil;
        assert(not tState.Failed and not tState.Class.Discarded, 'Instance belongs to a failed load or construction.');
        local tMember = assert(tLookup.Operators[sName], 'Unsupported instance operator: '..sName);
        local tContract = Operators[sName];
        if (tContract.Kind == 'binary') then
            local vLeft, vRight = ...;
            if (#tMember.Parameters == 2) then return fInvoke(tState, tMember, vLeft, vRight); end
            if (rawequal(vLeft, tState.Object)) then return fInvoke(tState, tMember, vRight); end
            return fInvoke(tState, tMember, vLeft);
        end
        if (tContract.Kind == 'unary') then return fInvoke(tState, tMember); end
        return fInvoke(tState, tMember, ...);
    end
    fInternal(fOperator);

    --[[!
    @fqxn LXC.Runtime.declaredSpecial
    @desc Nested types and generated accessor names remain declared names. An
        unknown-member operator must never turn an access/qualifier error into
        an alternate route around those declarations.
    !]]
    local function fDeclaredSpecial(tClass, sName)
        if (tClass.Aliases[sName]) then return true; end
        while (tClass) do
            if (tClass.Nested[sName]) then return true; end
            tClass = tClass.Parent;
        end
        return false;
    end

    --[[!
    @fqxn LXC.Runtime.storageView
    @desc Caches an opaque accessor backing handle; every use rechecks declaring-class rights.
    !]]
    local function fStorageView(tState, tMember)
        local __lxc_guard <close> = nil;
        tState.StorageViews = tState.StorageViews or {};
        if (tState.StorageViews[tMember]) then return tState.StorageViews[tMember]; end
        local tSlot = fGetSlot(tState, tMember);
        local tOwner = tMember.Owner;
        local oView = Facades.create({
            __index = fInternal(function(sKey)
                local __lxc_guard <close> = nil;
                assert(sKey == 'value' and Model.allowed('private', tOwner, Context.caller()), 'Backing storage is private.');
                return tSlot.Value;
            end),
            __newindex = fInternal(function(sKey, vValue)
                local __lxc_guard <close> = nil;
                assert(sKey == 'value' and Model.allowed('private', tOwner, Context.caller()), 'Backing storage is private.');
                fWrite(tSlot, vValue, false);
            end),
        });
        tState.StorageViews[tMember] = oView;
        return oView;
    end
    fInternal(fStorageView);

    --[[!
    @fqxn LXC.Runtime.baseView
    @desc Caches a checked immediate-parent view bound to the current instance and declaring class.
    !]]
    local function fBaseView(tState, tOwner)
        local __lxc_guard <close> = nil;
        tState.BaseViews = tState.BaseViews or {};
        if (tState.BaseViews[tOwner]) then return tState.BaseViews[tOwner]; end
        local oView = Facades.create({
            __index = fInternal(function(sName)
                local __lxc_guard <close> = nil;
                assert(Context.caller() == tOwner or Model.allowed('private', tOwner, Context.caller()), 'Escaped base access.');
                assert(tOwner.Parent, 'No parent class.');
                return fRead(tState, tOwner.Parent, sName, false, true);
            end),
            __newindex = fInternal(function(sName, vValue)
                local __lxc_guard <close> = nil;
                assert(Model.allowed('private', tOwner, Context.caller()), 'Escaped base access.');
                return fAssign(tState, assert(tOwner.Parent, 'No parent.'), sName, vValue, false, true);
            end),
            __call = function()
                local __lxc_guard <close> = nil;
                error('Parent constructor calls must be first-statement declarations.');
            end,
        });
        tState.BaseViews[tOwner] = oView;
        return oView;
    end
    fInternal(fBaseView);

    --[[!
    @fqxn LXC.Runtime.invoke
    @desc Calls a compiled body with its instance, declaring-class base view and optional backing handle.
    !]]
    fInvoke = fInternal(function(tState, tMember, ...)
        local __lxc_guard <close> = nil;
        assert(not tMember.Flags.abstract, 'Cannot call abstract member.');
        local oThis = not tMember.Flags.static and tState.Object or nil;
        local oField;
        if (tMember.Kind == 'accessor') then oField = fStorageView(tState, tMember.Property); end
        return tMember.Function(oThis, fBaseView(tState, tMember.Owner), oField, ...);
    end);

    --[[!
    @fqxn LXC.Runtime.method
    @desc Caches a bound method wrapper that rechecks current caller rights and failed-instance state.
    !]]
    local function fMethod(tState, tMember)
        local __lxc_guard <close> = nil;
        tState.Methods = tState.Methods or {};
        if (not tState.Methods[tMember]) then
            local fMethod = fInternal(function(...)
                local __lxc_guard <close> = nil;
                local tCaller;
                if (tMember.Visibility ~= 'public' or tMember.Flags.static) then tCaller = Context.caller(); end
                assert(not tState.Class.Discarded and not tState.Failed, 'Instance belongs to a failed load or construction.');
                fCheck(tMember, tCaller, tState.Class);
                if (tMember.Flags.static) then fCheckClass(tMember.Owner, tCaller); end
                return fInvoke(tState, tMember, ...);
            end);
            tState.Methods[tMember] = fMethod;
        end
        return tState.Methods[tMember];
    end
    fInternal(fMethod);

    --[[!
    @fqxn LXC.Runtime.accessor
    @desc Runs the selected accessor or automatic storage operation under the same access rules.
    !]]
    local function fAccessor(tState, tProperty, sAccess, tCaller, ...)
        local __lxc_guard <close> = nil;
        assert(not tProperty.Flags.abstract, 'Cannot invoke abstract property.');
        local tAccessor = assert(tProperty.Accessors[sAccess], 'Property has no '..sAccess..': '..tProperty.Name);
        if (not tCaller and tAccessor.Visibility ~= 'public') then tCaller = Context.caller(); end
        fCheck(tAccessor, tCaller, tState.Class);
        if (tAccessor.Function) then return fInvoke(tState, tAccessor, ...); end
        local tSlot = fGetSlot(tState, tProperty);
        if (sAccess == 'get') then return tSlot.Value; end
        fWrite(tSlot, (...), false);
    end
    fInternal(fAccessor);

    --[[!
    @fqxn LXC.Runtime.read
    @desc Resolves a qualified member, nested type or accessor alias and applies access/dispatch rules.
    !]]
    fRead = fInternal(function(tState, tLookup, sName, bStatic, bBase, tLexical)
        local __lxc_guard <close> = nil;
        local tCaller = fCaller(tLookup, sName, bStatic, bBase, tLexical);
        assert(not tState.Class.Discarded and not tState.Failed, 'Instance belongs to a failed load or construction.');
        local tNested = tLookup;
        if (bStatic) then
            fCheckClass(tLookup, tCaller);
            while (tNested) do
                if (tNested.Nested[sName]) then
                    fCheckClass(tNested.Nested[sName], tCaller);
                    return tNested.Nested[sName].Object;
                end
                tNested = tNested.Parent;
            end
        end
        local tAlias = tLookup.Aliases[sName];
        local tMember = Model.member(tLookup, bBase and nil or tCaller, sName);
        if (not tMember and tAlias) then
            tMember = Model.member(tLookup, bBase and nil or tCaller, tAlias.Property.Name);
            -- Same-name private properties own distinct slots. An inherited
            -- alias must not silently switch to an unrelated child declaration.
            if (fSlotOwner(tMember) ~= fSlotOwner(tAlias.Property)) then tMember = tAlias.Property; end
            assert(not not tMember.Flags.static == bStatic, 'Use the correct class/instance qualifier.');
            fCheck(tMember.Accessors[tAlias.Access], tCaller, tState.Class);
            return fInternal(function(...)
                local __lxc_guard <close> = nil;
                if (bStatic) then fCheckClass(tLookup, Context.caller()); end
                return fAccessor(tState, tMember, tAlias.Access, nil, ...);
            end);
        end
        if (not tMember and not bStatic and not fDeclaredSpecial(tLookup, sName) and tLookup.Operators.__index) then
            return fOperator(tState, tLookup, '__index', sName);
        end
        assert(tMember, 'Unknown member: '..tostring(sName));
        assert(not not tMember.Flags.static == bStatic, 'Use the correct class/instance qualifier.');
        fCheck(tMember, tCaller, tState.Class);
        if (tMember.Kind == 'method') then return fMethod(tState, tMember); end
        if (tMember.Kind == 'property') then return fAccessor(tState, tMember, 'get', tCaller); end
        return fGetSlot(tState, tMember).Value;
    end);

    --[[!
    @fqxn LXC.Runtime.assign
    @desc Resolves a writable field/property and enforces access, type and binding restrictions.
    !]]
    fAssign = fInternal(function(tState, tLookup, sName, vValue, bStatic, bBase, tLexical)
        local __lxc_guard <close> = nil;
        local tCaller = fCaller(tLookup, sName, bStatic, bBase, tLexical);
        assert(not tState.Class.Discarded and not tState.Failed, 'Instance belongs to a failed load or construction.');
        if (bStatic) then fCheckClass(tLookup, tCaller); end
        local tMember = Model.member(tLookup, bBase and nil or tCaller, sName);
        if (not tMember and not bStatic and not fDeclaredSpecial(tLookup, sName) and tLookup.Operators.__newindex) then
            return fOperator(tState, tLookup, '__newindex', sName, vValue);
        end
        assert(tMember, 'Unknown field: '..tostring(sName));
        assert(not not tMember.Flags.static == bStatic, 'Use the correct class/instance qualifier.');
        fCheck(tMember, tCaller, tState.Class);
        assert(tMember.Kind ~= 'method', 'Cannot replace a method.');
        if (tMember.Kind == 'property') then return fAccessor(tState, tMember, 'set', tCaller, vValue); end
        local tSlot = fGetSlot(tState, tMember);
        fWrite(tSlot, vValue, false);
    end);

    --[[!
    @fqxn LXC.Runtime.allocate
    @desc Creates an opaque instance shell and private state without initializing fields or running constructors.
    !]]
    local function fAllocate(tClass)
        local __lxc_guard <close> = nil;
        local tState = {Class = tClass, Values = {}, Methods = {}};
        local oObject;
        oObject = Facades.create({
            __index = fInternal(function(sName)
                local __lxc_guard <close> = nil;
                return fRead(tState, tClass, sName, false);
            end),
            __newindex = fInternal(function(sName, vValue)
                local __lxc_guard <close> = nil;
                return fAssign(tState, tClass, sName, vValue, false);
            end),
            __supports = function(sOperation) return tClass.Operators[sOperation] ~= nil; end,
            __serialize = fInternal(function()
                local __lxc_guard <close> = nil;
                return assert(Runtime.HostReference, 'Bind host serialization before exporting references.')(tState.Object);
            end),
            __operator = fInternal(function(sOperation, ...)
                local __lxc_guard <close> = nil;
                return fOperator(tState, tClass, sOperation, ...);
            end),
            __tostring = fInternal(function()
                local __lxc_guard <close> = nil;
                if (tClass.Operators.__tostring) then return fInvoke(tState, tClass.Operators.__tostring); end
                return '<'..tClass.FullName..' instance>';
            end),
            __finalize = tClass.Operators.__gc and fInternal(function()
                local __lxc_guard <close> = nil;
                if (not tState.Ready or tState.Failed or tClass.Discarded) then return; end
                tObjects[tState.Object] = tState;
                return fOperator(tState, tClass, '__gc');
            end) or nil,
        });
        tState.Object, tObjects[oObject] = oObject, tState;
        return tState;
    end

    --[[!
    @fqxn LXC.Runtime.initializeFields
    @desc Evaluates original field/property initializers once each in source order for one class level.
    !]]
    local function fInitializeFields(tState, tClass, bStatic)
        local __lxc_guard <close> = nil;
        for _, tMember in ipairs(tClass.Members) do
            if (tMember.Kind ~= 'method' and not tMember.Overrides and not not tMember.Flags.static == bStatic) then
                local tSlot = {Member = tMember, Value = oNull, State = tState};
                local tTarget = bStatic and tClass.Static or tState.Values;
                tTarget[tMember] = tSlot;
                local vValue = oNull;
                -- Use explicit nil checks: false is a valid initialized value.
                if (tMember.Initialize) then vValue = tMember.Initialize(bStatic and nil or tState.Object); end
                fWrite(tSlot, vValue, true);
            end
        end
    end

    --[[!
    @fqxn LXC.Runtime.checkFinals
    @desc Rejects an initialization stage leaving a final binding owned by this class unset.
    !]]
    local function fCheckFinals(tValues, tClass)
        local __lxc_guard <close> = nil;
        for _, tSlot in pairs(tValues) do
            if (tSlot.Member.Owner == tClass and tSlot.Member.Flags.final) then
                assert(tSlot.Type, 'Uninitialized final: '..tClass.FullName..'.'..tSlot.Member.Name);
            end
        end
    end

    --[[!
    @fqxn LXC.Runtime.construct
    @desc Constructs parents before child fields/body, validates return values and requires initialized finals.
    !]]
    fConstruct = fInternal(function(tState, tClass, tCaller, ...)
        local __lxc_guard <close> = nil;
        local tConstructor = tClass.Constructor;
        local sVisibility = tConstructor and tConstructor.Visibility or tClass.Visibility;
        assert(Model.allowed(sVisibility, tClass, tCaller), 'Inaccessible constructor: '..tClass.FullName);
        if (tClass.Parent) then
            local tArguments = {n = 0};
            if (tConstructor and tConstructor.ParentArguments) then
                tArguments = table.pack(tConstructor.ParentArguments(nil, nil, nil, ...));
            end
            fConstruct(tState, tClass.Parent, tClass, table.unpack(tArguments, 1, tArguments.n));
        end
        tState.Constructing = tClass;
        fInitializeFields(tState, tClass, false);
        if (tConstructor) then
            local tResult = table.pack(fInvoke(tState, tConstructor, ...));
            assert(tResult.n == 0, 'Constructors cannot return values.');
        end
        fCheckFinals(tState.Values, tClass);
        tState.Constructing = nil;
    end);

    --[[!
    @fqxn LXC.Runtime.lexicalView
    @desc Compiler-only qualified-access view. Expression rewriting never replaces
        bare values, so application callbacks and returns receive public identities.
        The factory binding is absent from source-visible names and environments.
    !]]
    local function fLexicalView(vValue, tOwner)
        local __lxc_guard <close> = nil;
        local tClass = tClasses[vValue];
        local tState = tClass and tClass.State or tObjects[vValue];
        if (not tState) then return vValue; end
        tState.LexicalViews = tState.LexicalViews or {};
        if (not tState.LexicalViews[tOwner]) then
            local bStatic = tClass ~= nil;
            tState.LexicalViews[tOwner] = Facades.create({
                __index = fInternal(function(sName)
                    local __lxc_guard <close> = nil;
                    return fRead(tState, tState.Class, sName, bStatic, false, tOwner);
                end),
                __newindex = fInternal(function(sName, vNew)
                    local __lxc_guard <close> = nil;
                    return fAssign(tState, tState.Class, sName, vNew, bStatic, false, tOwner);
                end),
            });
        end
        return tState.LexicalViews[tOwner];
    end

    --[[!
    @fqxn LXC.Runtime.instantiate
    @desc Checks using-scope construction rights and invalidates any leaked shell
        when field initialization or a constructor fails.
    !]]
    local function fInstantiate(tClass, ...)
        local __lxc_guard <close> = nil;
        local tCaller = Context.caller();
        fCheckClass(tClass, tCaller);
        assert(not tClass.Flags.abstract, 'Cannot instantiate abstract class: '..tClass.FullName);

        local tState = fAllocate(tClass);
        local bOK, vError = pcall(fConstruct, tState, tClass, tCaller, ...);
        if (not bOK) then
            tState.Failed = true;
            error(Diagnostics.format(tClass.Constructor or tClass, vError), 0);
        end
        tState.Ready = true;
        return tState.Object;
    end
    fInternal(fInstantiate);

    --[[!
    @fqxn LXC.Runtime.defineClass
    @desc Allocates one class identity and private static state. It does not run
        application initializers or publish the new reference.
    !]]
    local function fDefineClass(tClass)
        if (tClass.Object) then return; end
        tClass.Static = {};
        tClass.State = {Class = tClass, Methods = {}};
        tClass.Object = Facades.create({
            __index = fInternal(function(sName)
                local __lxc_guard <close> = nil;
                return fRead(tClass.State, tClass, sName, true);
            end),
            __newindex = fInternal(function(sName, vValue)
                local __lxc_guard <close> = nil;
                return fAssign(tClass.State, tClass, sName, vValue, true);
            end),
            __call = fInternal(function(...)
                local __lxc_guard <close> = nil;
                return fInstantiate(tClass, ...);
            end),
            __tostring = function() return '<class '..tClass.FullName..'>'; end,
            __serialize = fInternal(function()
                local __lxc_guard <close> = nil;
                return assert(Runtime.HostReference, 'Bind host serialization before exporting references.')(tClass.Object);
            end),
        });
        tClasses[tClass.Object] = tClass;
    end

    --[[!
    @fqxn LXC.Runtime.compileClass
    @desc Builds the lexical scope and compiles one class's declarations. Reports
        failures against the member being compiled, before static code executes.
    !]]
    local function fCompileClass(tClass, tBatch, tEnvironment)
        if (tClass.Compiled) then return; end
        local tScope = Environment.create(tClass, tBatch, tEnvironment, {
            null = oNull,
            class = Runtime.Helpers,
            __lxc_view = function(vValue) return fLexicalView(vValue, tClass); end,
        }, fCheckClass);

        for _, tMember in ipairs(tClass.Members) do
            Diagnostics.run(tMember, Compiler.initializer, tMember, tScope);
            Diagnostics.run(tMember, Compiler.method, tMember, tScope);
            for _, tAccess in pairs(tMember.Accessors or {}) do
                Diagnostics.run(tMember, Compiler.method, tAccess, tScope);
            end
        end
        if (tClass.Constructor) then
            Diagnostics.run(tClass.Constructor, Compiler.constructor, tClass.Constructor, tScope);
        end
        if (tClass.StaticConstructor) then
            Diagnostics.run(tClass.StaticConstructor, Compiler.method, tClass.StaticConstructor, tScope);
        end
        tClass.Compiled = true;
    end

    --[[!
    @fqxn LXC.Runtime.prepare
    @desc Allocates all class identities before compiling any body, so forward
        references can resolve. Leaves static initialization to ordered staging.
    @param table tOrder Dependency-first class records.
    @param table tBatch Qualified definitions in the current transaction.
    @param table tEnvironment Host bindings and publication destination.
    !]]
    function Runtime.prepare(tOrder, tBatch, tEnvironment)
        for _, tClass in ipairs(tOrder) do fDefineClass(tClass); end
        for _, tClass in ipairs(tOrder) do fCompileClass(tClass, tBatch, tEnvironment); end
    end
    --[[!
    @fqxn LXC.Runtime.initialize
    @desc Initializes one class once: static fields, optional static constructor, then final-field validation.
    !]]
    function Runtime.initialize(tClass)
        local __lxc_guard <close> = nil;
        if (tClass.Initialized) then return; end
        tClass.StaticRunning = true;
        fInitializeFields(tClass.State, tClass, true);
        if (tClass.StaticConstructor) then
            local tResult = table.pack(fInvoke(tClass.State, tClass.StaticConstructor));
            assert(tResult.n == 0, 'Static constructor cannot return values.');
        end
        fCheckFinals(tClass.Static, tClass);
        tClass.StaticRunning, tClass.Initialized = nil, true;
    end

    -- Internal codec/helper integration receives registries by closure injection;
    -- neither these services nor the returned registries become public API.
    --[[!
    @fqxn LXC.Runtime.services
    @desc Supplies private registries and trusted operations only to injected helper/persistence factories.
    !]]
    function Runtime.services()
        local __lxc_guard <close> = nil;
        return tClasses, tObjects, fWrite, fAllocate, oNull, fInvoke;
    end
    return Runtime;
end;
