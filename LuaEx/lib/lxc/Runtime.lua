--[[!
@fqxn LuaEx.LXC.Runtime
@desc <h3>Runtime — responsibility and connections</h3><p>Creates live classes and instances from validated
    definitions. Owns private storage, access checks, member/property/operator dispatch, construction and static
    initialization. Compiler supplies executable bodies; Environment supplies names; Context identifies callers.
    Trusted graph services receive internal operations through closure injection, never public API fields.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
@field table Null Host-reused or standalone null singleton.
@field table Helpers Read-only class helper facade injected by Loader before class compilation.
@field table API Public LXC facade injected after composition; used for host binding.
@field boolean Loading True only during preparation/static execution; rejects reentrant loads.
@field function HostReference Internal legacy host-export marker callback supplied by HostGraph.
!]]

--[[!
@fqxn LuaEx.LXC.Runtime.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Model Private injected dependency; its role is described in the module map.
@param table Context Private injected dependency; its role is described in the module map.
@param table Facades Private injected dependency; its role is described in the module map.
@param table Compiler Private injected dependency; its role is described in the module map.
@param table Environment Private injected dependency; its role is described in the module map.
@param table Diagnostics Private injected dependency; its role is described in the module map.
@param table|nil oHostNull Private injected dependency; reuses the initialized host null singleton when
    provided.
@param table Operators Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Model, Context, Facades, Compiler, Environment, Diagnostics, oHostNull, Operators)
    local __lxc_guard <close> = nil;
    local Runtime = {};
    local Native = require('LuaEx.lib.lxc.Native');
    -- Freeze entry points before application code can replace module table keys.
    local bNative, fNativeSetter = Native.Available, Native.setter;
    local Directives = require('LuaEx.lib.lxc.Directives')(Model, Diagnostics);
    local tClasses, tObjects = setmetatable({}, {__mode = 'k'}), setmetatable({}, {__mode = 'k'});
    local oNull = oHostNull or Facades.create({
        --[[!
        @fqxn LuaEx.LXC.Runtime.null.toString
        @desc Returns the standalone null singleton's display spelling.
        @ret string sText The string null.
        @vis internal
        !]]
        __tostring = function() return 'null'; end,
        --[[!
        @fqxn LuaEx.LXC.Runtime.null.read
        @desc Rejects all member reads on the standalone null singleton.
        @ret nil Never returns successfully; null has no members.
        @vis internal
        !]]
        __index = function()
            local __lxc_guard <close> = nil;
            error('Null has no members.');
        end,
        --[[!
        @fqxn LuaEx.LXC.Runtime.null.write
        @desc Rejects all mutation of the standalone null singleton.
        @ret nil Never returns successfully; null is immutable.
        @vis internal
        !]]
        __newindex = function()
            local __lxc_guard <close> = nil;
            error('Cannot modify null.');
        end,
    });
    Runtime.Null = oNull;

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.internal
    @desc Registers a trusted runtime frame for Context to skip, preserving actual application lexical
        authority.
    @param function fFunction Function identity to register or recognize.
    @ret function fFunction Original function.
    @vis internal
    !]]
    local function fInternal(fFunction)
        local __lxc_guard <close> = nil;
        return Context.internal(fFunction);
    end
    fInternal(fInternal);

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.check
    @desc Checks caller/receiver access through Model.memberAllowed, reporting the declaring class/member on
        failure.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @param table tReceiver Concrete receiving instance's class definition.
    @ret nil No return value; raises on denied access.
    @vis internal
    !]]
    local function fCheck(tMember, tCaller, tReceiver)
        local __lxc_guard <close> = nil;
        assert(Model.memberAllowed(tMember, tCaller, tReceiver),
            'Cannot access '..tMember.Visibility..' member '..tMember.Owner.FullName..'.'..tMember.Name);
    end
    fInternal(fCheck);

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.checkClass
    @desc Rejects discarded definitions, unpublished classes outside caller's batch and hidden nested types.
        Checks class use, not just name resolution.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @ret nil No return value; raises for unusable classes.
    @vis internal
    !]]
    local function fCheckClass(tClass, tCaller)
        local __lxc_guard <close> = nil;
        assert(not tClass.Discarded, 'Class belongs to a failed load.');
        assert(tClass.Published or (tCaller and tCaller.Batch == tClass.Batch), 'Class is not published.');
        assert(Model.visible(tClass, tCaller), 'Cannot access class '..tClass.FullName);
    end
    fInternal(fCheckClass);

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.caller
    @desc Uses an explicit compiler lexical owner when supplied. Unambiguous public instance lookups avoid stack
        scans; static/base/private-name-sensitive lookups recover actual caller scope.
    @param table tLookup Definition where member/operator lookup begins.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @param boolean bStatic True for class storage/qualification, false for instance state.
    @param boolean bBase Whether lookup starts through a base view.
    @param table|nil tLexical Explicit declaring owner supplied by a compiler-created lexical view.
    @ret table|nil tCaller Calling class or external nil.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.slotOwner
    @desc Finds the declaration owning the stored value. If Base declares property Health and Child overrides
        its getter, Child changes how Health is read but does not allocate another Health value. Validation sets
        Child.Health.Slot to Base.Health; this returns Base.Health for either declaration. Ordinary fields
        return themselves.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @ret table tRoot Original storage-owning declaration.
    @vis internal
    !]]
    local function fSlotOwner(tMember)
        local __lxc_guard <close> = nil;
        return tMember.Slot or tMember;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.write
    @desc Rejects nil, binding-lock violations and type changes. Null is allowed only before a type is
        established. First non-null assignment fixes a primitive/class/instance-ancestry contract; const/final
        then lock. Deferred finals require their declaring constructor context. Repeated number/string/boolean
        writes compare captured native Lua types directly; class/enum/foreign values retain full identity checks.
    @param table tSlot Private storage record with Member, Value, Type and Locked fields.
    @param any vValue Value to inspect, assign, copy or serialize.
    @param boolean bInitialize True for declaration initialization/validated restore; false for assignment.
    @ret nil No return value; updates Value/Type/Locked.
    @vis internal
    !]]
    local function fWrite(tSlot, vValue, bInitialize)
        local __lxc_guard <close> = nil;
        local tMember = tSlot.Member;
        local tFlags = tMember.Flags;
        -- Format diagnostics only on failure, rather than allocating qualified
        -- error strings on every successful assignment.
        if (vValue == nil) then error('Declared fields cannot be nil.'); end
        if (tSlot.Locked) then error('Cannot reassign const/final field: '..tMember.Name); end
        if (tFlags.const and not bInitialize) then error('Const initialized outside declaration.'); end
        if (tFlags.final and not tSlot.Type and not bInitialize) then
            local tOwner = tMember.Owner;
            local bConstructing = tFlags.static and tOwner.StaticRunning or
                (tSlot.State and tSlot.State.Constructing == tOwner);
            assert(bConstructing and Model.allowed('private', tOwner, Context.caller()),
                'Final initialization requires declaring constructor.');
        end
        -- The runtime's type function is captured native Lua type. Canonical
        -- class/enum identities are facade objects, never these scalar values.
        -- Mismatches still use the original classifier and diagnostic path.
        local sNativeType = type(vValue);
        local bTypedScalar = tSlot.Type == sNativeType and
            (sNativeType == 'number' or sNativeType == 'string' or sNativeType == 'boolean');
        if (bTypedScalar) then
            tSlot.Locked = tFlags.const or tFlags.final or false;
        elseif (rawequal(vValue, oNull)) then
            assert(not tSlot.Type, 'Typed field cannot return to null.');
            assert(not tFlags.const, 'Const cannot start null.');
        else
            local tObject = tObjects[vValue];
            -- LXE supplies canonical type identity through the private connector.
            -- This extends the existing slot check without trusting public metadata.
            local zForeign = Runtime.ForeignType and Runtime.ForeignType(vValue);
            local zType = tObject and tObject.Class or (tClasses[vValue] and 'class' or zForeign or sNativeType);
            if (tSlot.Type) then
                if (not ((type(tSlot.Type) == 'table' and tObject and Model.descends(tObject.Class, tSlot.Type)) or
                    tSlot.Type == zType)) then
                    error('Field type mismatch: '..tMember.Owner.FullName..'.'..tMember.Name);
                end
            else tSlot.Type = zType; end
            tSlot.Locked = tFlags.const or tFlags.final or false;
        end
        tSlot.Value = vValue;
        -- Bound getter values are updated only after validation and the storage
        -- commit. These private runtime callbacks execute no application code.
        if (tSlot.GetterUpdates) then
            for _, fUpdate in ipairs(tSlot.GetterUpdates) do fUpdate(vValue); end
        end
    end
    fInternal(fWrite);

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.getSlot
    @desc Uses slotOwner to select original-owner static storage or receiver instance storage. Overrides share
        the backing value; reads before allocation fail.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @ret table tSlot Member/Value/Type/Locked record.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.operator
    @desc Rejects failed/discarded state. One-parameter binary methods receive the other operand; two-parameter
        forms receive original left/right operands in order.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tLookup Definition where member/operator lookup begins.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @param any ... Additional arguments forwarded in order.
    @ret any ... Operator results.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.declaredSpecial
    @desc Recognizes generated accessor aliases and nested types so missing-member operators cannot intercept
        declared metadata names.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @ret boolean bDeclared Whether the name has special declaration meaning.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.storageView
    @desc Returns a property's private backing facade; only value is allowed and every access checks declaring
        scope. Compiler rewrites field to this view's value; writes keep type/lock checks.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @ret table oView Cached backing-storage view.
    @vis internal
    !]]
    local function fStorageView(tState, tMember)
        local __lxc_guard <close> = nil;
        tState.StorageViews = tState.StorageViews or {};
        if (tState.StorageViews[tMember]) then return tState.StorageViews[tMember]; end
        local tSlot = fGetSlot(tState, tMember);
        local tOwner = tMember.Owner;
        local oView = Facades.create({
            --[[!
            @fqxn LuaEx.LXC.Runtime.storageView.read
            @desc Reads only the backing view value after checking private access for the property declaring
                class.
            @param string sKey Requested namespace or member name.
            @ret any vValue Current backing value.
            @vis internal
            !]]
            __index = fInternal(function(sKey)
                local __lxc_guard <close> = nil;
                assert(sKey == 'value' and Model.allowed('private', tOwner, Context.caller()), 'Backing storage is private.');
                return tSlot.Value;
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.storageView.write
            @desc Writes only the backing value after private declaring-scope checks, retaining type and binding
                locks.
            @param string sKey Requested namespace or member name.
            @param any vValue Value to inspect, assign, copy or serialize.
            @ret nil No return value; updates the backing slot.
            @vis internal
            !]]
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
    @fqxn LuaEx.LXC.Runtime.baseView
    @desc Returns a checked view starting at declaring-class Parent. Escaped use fails; direct calls fail
        because Compiler handles base(...) only as a leading constructor declaration.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tOwner Class definition that declares this code or storage.
    @ret table oView Cached parent-lookup view.
    @vis internal
    !]]
    local function fBaseView(tState, tOwner)
        local __lxc_guard <close> = nil;
        tState.BaseViews = tState.BaseViews or {};
        if (tState.BaseViews[tOwner]) then return tState.BaseViews[tOwner]; end
        local oView = Facades.create({
            --[[!
            @fqxn LuaEx.LXC.Runtime.baseView.read
            @desc Checks that the base view has not escaped its declaring lexical scope, then reads from that
                class's parent.
            @param string sName Name/path to resolve or inspect under the lookup rules described above.
            @ret any vValue Parent-selected member.
            @vis internal
            !]]
            __index = fInternal(function(sName)
                local __lxc_guard <close> = nil;
                assert(Context.caller() == tOwner or Model.allowed('private', tOwner, Context.caller()), 'Escaped base access.');
                assert(tOwner.Parent, 'No parent class.');
                return fRead(tState, tOwner.Parent, sName, false, true);
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.baseView.write
            @desc Rejects escaped use and assigns through parent-selected lookup for this declaring class.
            @param string sName Name/path to resolve or inspect under the lookup rules described above.
            @param any vValue Value to inspect, assign, copy or serialize.
            @ret any ... Parent setter results or no results for a field.
            @vis internal
            !]]
            __newindex = fInternal(function(sName, vValue)
                local __lxc_guard <close> = nil;
                assert(Model.allowed('private', tOwner, Context.caller()), 'Escaped base access.');
                return fAssign(tState, assert(tOwner.Parent, 'No parent.'), sName, vValue, false, true);
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.baseView.call
            @desc Rejects a runtime base-view call: parent constructor arguments are extracted by Compiler
                instead.
            @ret nil Never returns successfully; direct base calls fail.
            @vis internal
            !]]
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
    @fqxn LuaEx.LXC.Runtime.invoke
    @desc Supplies hidden this/base/backing-field arguments before explicit parameters; static members receive
        nil this. Selection paths check access and abstract bodies cannot execute.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @param any ... Additional arguments forwarded in order.
    @ret any ... Compiled body results.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.method
    @desc Caches a bound dot-call closure: user supplies declared arguments, Runtime supplies this.
        Public access is fixed by the validated contract. Restricted invocations still check their caller,
        and every invocation checks failed state, so saved restricted methods do not bypass rules.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @ret function fMethod Checked bound closure.
    @vis internal
    !]]
    local function fMethod(tState, tMember)
        local __lxc_guard <close> = nil;
        tState.Methods = tState.Methods or {};
        if (not tState.Methods[tMember]) then
            -- Public instance bodies can bind their hidden arguments once.
            -- Their compiled entry guard runs on every call; the actual body
            -- retains its declaring _ENV for private access and nested callbacks.
            if (tMember.BoundFactory) then
                -- Native setters share production slots and the original checked
                -- writer. Final/const/property/complex bodies keep their Lua frames.
                local tSetter = bNative and tMember.SetterRoot and tState.Values[tMember.SetterRoot];
                if (tSetter) then
                    tState.Methods[tMember] = fInternal(fNativeSetter(tState, tSetter, fWrite));
                    return tState.Methods[tMember];
                end
                -- Instance slots are allocated once. Constructors, clone and
                -- restoration each create their own records; writes change Value.
                -- Early binding before a field exists must keep the live lookup.
                local tSlot = tMember.GetterRoot and tState.Values[tMember.GetterRoot];
                if (tSlot and tMember.SlotGetterFactory) then
                    local fGetter, fUpdate = tMember.SlotGetterFactory(tState, tSlot.Value);
                    tSlot.GetterUpdates = tSlot.GetterUpdates or {};
                    tSlot.GetterUpdates[#tSlot.GetterUpdates + 1] = fInternal(fUpdate);
                    tState.Methods[tMember] = fGetter;
                    return tState.Methods[tMember];
                end
                tState.Methods[tMember] = tMember.BoundFactory(tState.Object, fBaseView(tState, tMember.Owner), tState, tMember.GetterRoot);
                return tState.Methods[tMember];
            end
            -- A public access contract is independent of the calling class.
            -- Resolve overrides once; restricted contracts retain runtime checks.
            local bPublic = Model.memberAllowed(tMember, nil, tState.Class);
            --[[!
            @fqxn LuaEx.LXC.Runtime.method.invokeBound
            @desc Caches a bound dot-call closure: user supplies declared arguments, Runtime supplies this.
                Restricted invocations recheck caller access; all invocations check failed state.
            @param any ... Additional arguments forwarded in order.
            @ret function fMethod Checked bound closure.
            @vis internal
            !]]
            local fMethod = fInternal(function(...)
                local __lxc_guard <close> = nil;
                local tCaller;
                if (tMember.Visibility ~= 'public' or tMember.Flags.static) then tCaller = Context.caller(); end
                assert(not tState.Class.Discarded and not tState.Failed, 'Instance belongs to a failed load or construction.');
                if (not bPublic) then fCheck(tMember, tCaller, tState.Class); end
                if (tMember.Flags.static) then fCheckClass(tMember.Owner, tCaller); end
                return fInvoke(tState, tMember, ...);
            end);
            tState.Methods[tMember] = fMethod;
        end
        return tState.Methods[tMember];
    end
    fInternal(fMethod);

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.accessor
    @desc Checks get/set presence/visibility, executes custom bodies or automatically reads/writes storage.
        Storage writes retain type/binding restrictions.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tProperty Property definition with Accessors and original backing Slot.
    @param string sAccess get or set accessor selector.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @param any ... Additional arguments forwarded in order.
    @ret any ... Getter/custom body results or none for automatic setters.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.read
    @desc Reads nested types, aliases, bound methods, properties and fields with caller/base/receiver context.
        Unknown undeclared instance names may reach index; declared/inaccessible names retain ordinary checks.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tLookup Definition where member/operator lookup begins.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @param boolean bStatic True for class storage/qualification, false for instance state.
    @param boolean bBase Whether lookup starts through a base view.
    @param table|nil tLexical Explicit declaring owner supplied by a compiler-created lexical view.
    @ret any vValue Value or bound callable.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.assign
    @desc Checks access/qualifier and writes a slot or invokes setter; methods cannot be replaced. Only
        otherwise undeclared instance names reach newindex.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tLookup Definition where member/operator lookup begins.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @param any vValue Value to inspect, assign, copy or serialize.
    @param boolean bStatic True for class storage/qualification, false for instance state.
    @param boolean bBase Whether lookup starts through a base view.
    @param table|nil tLexical Explicit declaring owner supplied by a compiler-created lexical view.
    @ret any ... Setter/operator results or none for a field write.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.allocate
    @desc Creates an empty private state/facade without fields or constructors. Callbacks route
        reads/writes/operators, host markers and ready-only successful finalization.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @ret table tState New Object/Class/Values/Methods state.
    @vis internal
    !]]
    local function fAllocate(tClass)
        local __lxc_guard <close> = nil;
        local tState = {Class = tClass, Values = {}, Methods = {}};
        -- Failure propagation owns the shared lifetime guard used by bound
        -- getters. Weak state keys do not keep otherwise unreachable objects alive.
        tClass.InstanceStates = tClass.InstanceStates or setmetatable({}, {__mode = 'k'});
        tClass.InstanceStates[tState] = true;
        local tPublicMethods = {};
        local tPublicFields = bNative and (tClass.NativePublicFields or {});
        if (bNative) then tClass.NativePublicFields = tPublicFields; end
        local oObject;
        oObject = Facades.create({
            NativeState = bNative and tState or nil,
            NativeMethods = bNative and tPublicMethods or nil,
            NativeFields = tPublicFields,
            --[[!
            @fqxn LuaEx.LXC.Runtime.allocate.read
            @desc Checks the first concrete-class lookup and reuses unambiguous public methods.
                Private-name-sensitive lookups stay lexical; values/properties are never cached.
                Cached reads still reject failed/discarded instances.
            @param string sName Name/path to resolve or inspect under the lookup rules described above.
            @ret any vValue Instance member or bound method.
            @vis internal
            !]]
            __index = fInternal(function(sName)
                local __lxc_guard <close> = nil;
                local fKnown = tPublicMethods[sName];
                if (fKnown) then
                    assert(not tClass.Discarded and not tState.Failed,
                        'Instance belongs to a failed load or construction.');
                    return fKnown;
                end
                local vValue = fRead(tState, tClass, sName, false);
                if (not tClass.PrivateNames[sName]) then
                    local tMember = Model.member(tClass, nil, sName);
                    if (tMember and tMember.Kind == 'method' and tMember.Visibility == 'public' and not tMember.Flags.static) then
                        tPublicMethods[sName] = vValue;
                    elseif (bNative and tMember and tMember.Kind == 'field' and
                        tMember.Visibility == 'public' and not tMember.Flags.static) then
                        -- Cache declaration identity, never a value or a storage
                        -- record that constructor-free restoration could replace.
                        tPublicFields[sName] = fSlotOwner(tMember);
                    end
                end
                return vValue;
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.allocate.write
            @desc Assigns through the instance facade with checked access and concrete receiver selection.
            @param string sName Name/path to resolve or inspect under the lookup rules described above.
            @param any vValue Value to inspect, assign, copy or serialize.
            @ret any ... Setter/operator results or no results for a field.
            @vis internal
            !]]
            __newindex = fInternal(function(sName, vValue)
                local __lxc_guard <close> = nil;
                if (bNative and not tClass.PrivateNames[sName]) then
                    local tMember = Model.member(tClass, nil, sName);
                    if (tMember and tMember.Kind == 'field' and tMember.Visibility == 'public' and not tMember.Flags.static) then
                        fAssign(tState, tClass, sName, vValue, false);
                        tPublicFields[sName] = fSlotOwner(tMember);
                        return;
                    end
                end
                return fAssign(tState, tClass, sName, vValue, false);
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.__supports
            @desc Advertises whether the concrete class implements the requested operator for operand selection.
            @param string sOperation Canonical Lua metamethod operation name.
            @ret any vResult Result of the owning view operation; see the enclosing view contract.
            @vis internal
            !]]
            __supports = function(sOperation) return tClass.Operators[sOperation] ~= nil; end,
            --[[!
            @fqxn LuaEx.LXC.Runtime.allocate.hostReference
            @desc Requests the active host graph's prepared marker for this instance identity.
            @ret table oMarker Export identity marker.
            @vis internal
            !]]
            __serialize = fInternal(function()
                local __lxc_guard <close> = nil;
                return assert(Runtime.HostReference, 'Bind host serialization before exporting references.')(tState.Object);
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.__operator
            @desc Routes a canonical operation to checked instance operator invocation.
            @param string sOperation Canonical Lua metamethod operation name.
            @param any ... Additional arguments forwarded in order.
            @ret any vResult Result of the owning view operation; see the enclosing view contract.
            @vis internal
            !]]
            __operator = fInternal(function(sOperation, ...)
                local __lxc_guard <close> = nil;
                return fOperator(tState, tClass, sOperation, ...);
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.allocate.toString
            @desc Invokes an authored tostring operator when present, otherwise returns a qualified instance
                label.
            @ret string sText Instance text.
            @vis internal
            !]]
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
    @fqxn LuaEx.LXC.Runtime.initializeFields
    @desc Allocates storage in declaration order for one class/category, skipping methods/overrides. Runs
        initializers once for that storage, otherwise writes null; false is a valid value.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param boolean bStatic True for class storage/qualification, false for instance state.
    @ret nil No return value; fills slots/contracts.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.checkFinals
    @desc Ensures final slots owned by this class obtained a non-null type before construction/static
        initialization completes.
    @param table tValues Allocated graph identities or storage records used by this operation.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @ret nil No return value; raises for uninitialized finals.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.construct
    @desc Constructs parent levels first using explicit base arguments or none, initializes this level's fields,
        executes its constructor and checks finals. Constructors cannot return values.
    @param table tState Private live state containing Class, Object and storage maps.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param table|nil tCaller Calling class definition; nil means external unregistered code.
    @param any ... Additional arguments forwarded in order.
    @ret nil No return value; constructs hierarchy state.
    @vis internal
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
    @fqxn LuaEx.LXC.Runtime.lexicalView
    @desc Passes foreign values through; caches LXC views bound to the source's declaring class so private-name
        selection stays lexical on derived receivers and through callbacks.
    @param any vValue Value to inspect, assign, copy or serialize.
    @param table tOwner Class definition that declares this code or storage.
    @ret any vView Foreign value or lexical facade.
    @vis internal
    !]]
    local function fLexicalView(vValue, tOwner)
        local __lxc_guard <close> = nil;
        local tClass = tClasses[vValue];
        local tState = tClass and tClass.State or tObjects[vValue];
        if (not tState) then return vValue; end
        tState.LexicalViews = tState.LexicalViews or {};
        if (not tState.LexicalViews[tOwner]) then
            local bStatic = tClass ~= nil;
            local tReads = {};
            tState.LexicalViews[tOwner] = Facades.create({
                --[[!
                @fqxn LuaEx.LXC.Runtime.lexicalView.read
                @desc Reads with the source's explicit declaring owner. Successful field/method resolution
                    is retained for this receiver/owner pair; fields still read live storage and bound
                    methods still enforce invocation access. Properties and dynamic indexers use read.
                @param string sName Name/path to resolve or inspect under the lookup rules described above.
                @ret any vValue Lexically selected member.
                @vis internal
                !]]
                __index = fInternal(function(sName)
                    local __lxc_guard <close> = nil;
                    local fReadKnown = tReads[sName];
                    if (fReadKnown) then return fReadKnown(); end

                    -- Establish ordinary lookup, qualification and access first.
                    -- Only immutable member selection is cached, never its value.
                    local vValue = fRead(tState, tState.Class, sName, bStatic, false, tOwner);
                    local tMember = Model.member(tState.Class, tOwner, sName);
                    local tNested = bStatic and tState.Class;
                    local bNested = false;
                    while (tNested) do
                        if (tNested.Nested[sName]) then bNested = true; break; end
                        tNested = tNested.Parent;
                    end
                    if (not bNested and tMember and (tMember.Kind == 'field' or tMember.Kind == 'method') and
                        not not tMember.Flags.static == bStatic) then
                        tReads[sName] = fInternal(function()
                            assert(not tState.Class.Discarded and not tState.Failed,
                                'Instance belongs to a failed load or construction.');
                            if (bStatic) then fCheckClass(tState.Class, tOwner); end
                            if (tMember.Kind == 'method') then return vValue; end
                            return fGetSlot(tState, tMember).Value;
                        end);
                    end
                    return vValue;
                end),
                --[[!
                @fqxn LuaEx.LXC.Runtime.lexicalView.write
                @desc Assigns through an LXC reference while preserving the compiled source's declaring-class
                    access context.
                @param string sName Name/path to resolve or inspect under the lookup rules described above.
                @param any vNew New value assigned through a lexical view.
                @ret any ... Setter/operator results or no results for a field.
                @vis internal
                !]]
                __newindex = fInternal(function(sName, vNew)
                    local __lxc_guard <close> = nil;
                    return fAssign(tState, tState.Class, sName, vNew, bStatic, false, tOwner);
                end),
            });
        end
        return tState.LexicalViews[tOwner];
    end

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.completeConstruction
    @desc Runs the hierarchy and one final stored-state check inside the existing
        construction failure boundary. Custom copy sessions defer that final check.
    @param table tState Allocated instance state.
    @param table tClass Most-derived class.
    @param table|nil tCaller Original constructing scope.
    @param any ... Constructor arguments.
    !]]
    local function fCompleteConstruction(tState, tClass, tCaller, ...)
        fConstruct(tState, tClass, tCaller, ...);
        if (not Runtime.DeferCompletion or not Runtime.DeferCompletion(tState)) then
            Directives.check(tState, false, tObjects, tClasses, oNull);
        end
    end
    fInternal(fCompleteConstruction);

    --[[!
    @fqxn LuaEx.LXC.Runtime.instantiate
    @desc Checks visibility/abstract status, allocates and constructs. Failure marks state failed with
        declaration context; success marks Ready.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param any ... Additional arguments forwarded in order.
    @ret table oObject Ready instance.
    @vis internal
    !]]
    local function fInstantiate(tClass, ...)
        local __lxc_guard <close> = nil;
        local tCaller = Context.caller();
        fCheckClass(tClass, tCaller);
        assert(not tClass.Flags.abstract, 'Cannot instantiate abstract class: '..tClass.FullName);

        local tState = fAllocate(tClass);
        local bOK, vError = pcall(fCompleteConstruction, tState, tClass, tCaller, ...);
        if (not bOK) then
            tState.Failed = true;
            error(Diagnostics.format(tClass.Constructor or tClass, vError), 0);
        end
        tState.Ready = true;
        return tState.Object;
    end
    fInternal(fInstantiate);

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.defineClass
    @desc Creates callable class facade/static state once. Calls instantiate, static reads/writes use
        qualification checks, serialization requests identity markers.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @ret nil No return value; sets Object/Static/State and identity map.
    @vis internal
    !]]
    local function fDefineClass(tClass)
        if (tClass.Object) then return; end
        tClass.Static = {};
        tClass.State = {Class = tClass, Methods = {}};
        tClass.Object = Facades.create({
            --[[!
            @fqxn LuaEx.LXC.Runtime.defineClass.read
            @desc Reads the class facade with static qualification and nested-type checks.
            @param string sName Name/path to resolve or inspect under the lookup rules described above.
            @ret any vValue Static member or nested class.
            @vis internal
            !]]
            __index = fInternal(function(sName)
                local __lxc_guard <close> = nil;
                return fRead(tClass.State, tClass, sName, true);
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.defineClass.write
            @desc Assigns through the class facade using static member access/type/lock checks.
            @param string sName Name/path to resolve or inspect under the lookup rules described above.
            @param any vValue Value to inspect, assign, copy or serialize.
            @ret any ... Setter results or no results for a static field.
            @vis internal
            !]]
            __newindex = fInternal(function(sName, vValue)
                local __lxc_guard <close> = nil;
                return fAssign(tClass.State, tClass, sName, vValue, true);
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.defineClass.call
            @desc Constructs a new instance of this class using caller checks and parent-first construction.
            @param any ... Additional arguments forwarded in order.
            @ret table oObject New ready instance.
            @vis internal
            !]]
            __call = fInternal(function(...)
                local __lxc_guard <close> = nil;
                return fInstantiate(tClass, ...);
            end),
            --[[!
            @fqxn LuaEx.LXC.Runtime.defineClass.toString
            @desc Returns a qualified class label without exposing private state.
            @ret string sText Class display label.
            @vis internal
            !]]
            __tostring = function() return '<class '..tClass.FullName..'>'; end,
            --[[!
            @fqxn LuaEx.LXC.Runtime.defineClass.hostReference
            @desc Requests the active host graph's prepared marker for this class identity.
            @ret table oMarker Export identity marker.
            @vis internal
            !]]
            __serialize = fInternal(function()
                local __lxc_guard <close> = nil;
                return assert(Runtime.HostReference, 'Bind host serialization before exporting references.')(tClass.Object);
            end),
        });
        tClasses[tClass.Object] = tClass;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Runtime.compileClass
    @desc Creates the registered environment with null/class/compiler-view bindings, compiles
        initializers/methods/accessors/constructors and marks Compiled. Failures carry declaration diagnostics.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @param table tBatch Pending class definitions keyed by qualified name.
    @param table tEnvironment Destination environment for namespace or host bindings.
    @ret nil No return value; fills executable records.
    @vis internal
    !]]
    local function fCompileClass(tClass, tBatch, tEnvironment)
        if (tClass.Compiled) then return; end
        local tScope = Environment.create(tClass, tBatch, tEnvironment, {
            null = oNull,
            class = Runtime.Helpers,
            --[[!
            @fqxn LuaEx.LXC.Runtime.__lxc_view
            @desc Wraps a value with the class that authored this compiled source so member access retains
                lexical private-name selection.
            @param any vValue Value to inspect, assign, copy or serialize.
            @ret any vResult Result of the owning view operation; see the enclosing view contract.
            @vis internal
            !]]
            __lxc_view = function(vValue) return fLexicalView(vValue, tClass); end,
            --[[!
            @fqxn LuaEx.LXC.Runtime.compiledRead
            @desc Reads a compiler-selected instance field directly from live storage.
                The compiler proves lexical access; the runtime checks receiver ancestry
                and failed state. Reassigned foreign receivers use ordinary lookup.
            @param any vReceiver Current this value, including a reassigned parameter.
            @param number nSlot Private compiler field-descriptor index.
            @ret any vValue Current field value.
            @vis internal
            !]]
            __lxc_read = function(vReceiver, nSlot)
                local tMember = tClass.DirectReadMembers[nSlot];
                local tState = tObjects[vReceiver];
                if (not tState or not Model.descends(tState.Class, tClass)) then
                    return fLexicalView(vReceiver, tClass)[tMember.Name];
                end
                assert(not tState.Class.Discarded and not tState.Failed,
                    'Instance belongs to a failed load or construction.');
                local tRoot = tMember.Slot or tMember;
                local tSlot = assert(tState.Values[tRoot], 'Field read before initialization: '..tRoot.Name);
                return tSlot.Value;
            end,
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
    @fqxn LuaEx.LXC.Runtime.prepare
    @desc Defines every class facade before compiling any, enabling cross-batch names without running static
        application code.
    @param table tOrder Validated dependency-first sequence of definitions.
    @param table tBatch Pending class definitions keyed by qualified name.
    @param table tEnvironment Destination environment for namespace or host bindings.
    @ret nil No return value; prepares identities/functions.
    @vis internal
    !]]
    function Runtime.prepare(tOrder, tBatch, tEnvironment)
        for _, tClass in ipairs(tOrder) do fDefineClass(tClass); end
        for _, tClass in ipairs(tOrder) do fCompileClass(tClass, tBatch, tEnvironment); end
        Directives.prepare(tOrder);
    end

    --[[!
    @fqxn LuaEx.LXC.Runtime.discard
    @desc Invalidates a failed class batch and every instance allocated from its
        definitions, including constructor-free clones/restores. Propagation keeps
        prebound getter failure checks to one live instance flag without allowing
        captured objects or callbacks from a failed static initializer to survive.
    @param table tClass Definition belonging to the failed batch.
    @vis internal
    !]]
    function Runtime.discard(tClass)
        tClass.Discarded = true;
        if (tClass.State) then tClass.State.Failed = true; end
        for tState in pairs(tClass.InstanceStates or {}) do tState.Failed = true; end
    end
    
    --[[!
    @fqxn LuaEx.LXC.Runtime.initialize
    @desc Initializes static fields and optional parameterless static constructor once, checks finals and marks
        Initialized in Loader-supplied dependency order.
    @param table tClass Internal class definition with names, flags, members and resolved ancestry.
    @ret nil No return value; updates flags/static state.
    @vis internal
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
        Directives.check(tClass.State, true, tObjects, tClasses, oNull);
        tClass.StaticRunning, tClass.Initialized = nil, true;
    end

    --[[!
    @fqxn LuaEx.LXC.Runtime.complete
    @desc Checks constructor-free final storage through private completion metadata.
    @param table tState Complete instance state owned by clone or restore.
    !]]
    function Runtime.complete(tState)
        Directives.check(tState, false, tObjects, tClasses, oNull);
    end

    -- Internal codec/helper integration receives registries by closure injection;
    -- neither these services nor the returned registries become public API.

    --[[!
    @fqxn LuaEx.LXC.Runtime.services
    @desc Injects private class/instance registries, slot writer, raw allocator, null and member invoker into
        trusted services. None become public LXC fields.
    @ret table tClasses Followed by table tObjects, function fWrite, function fAllocate, table oNull and
        function fInvoke.
    @vis internal
    !]]
    function Runtime.services()
        local __lxc_guard <close> = nil;
        return tClasses, tObjects, fWrite, fAllocate, oNull, fInvoke;
    end
    return Runtime;
end;

