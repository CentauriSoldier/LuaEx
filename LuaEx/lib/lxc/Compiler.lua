--[[!
@fqxn LuaEx.LXC.Compiler
@desc <h3>Compiler — responsibility and connections</h3><p>Turns Lua bodies inside declarations into callable
    Lua 5.4 functions. Parser supplies source text; LuaScope distinguishes local variables from free class
    references; Model resolves those references. Compiler supplies this/base and accessor backing-field access.
    Runtime executes the resulting functions.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.Compiler.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Tokens Private injected dependency; its role is described in the module map.
@param table Model Private injected dependency; its role is described in the module map.
@param table LuaScope Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Tokens, Model, LuaScope)
    local Compiler = {};

    
    --[[!
    @fqxn LuaEx.LXC.Compiler.rewrite
    @desc Resolves free class names before static execution and selects accessible this-field descriptors
        for direct runtime reads. Assignment targets retain checked writes; properties, dynamic names and
        other receivers use lexical views. Edits run backwards by source offset. Nested functions retain
        their class environment and a Lua 5.4 frame guard.
    @param string sBody Uncompiled Lua method body or initializer text.
    @param string pFile Diagnostic source filename; source-map loads do not require a physical file.
    @param boolean bAccessor Whether field denotes accessor backing storage.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @param boolean bExpression True for an expression list; false/nil for a statement body.
    @ret string sBody Rewritten, unexecuted Lua source.
    @vis internal
    !]]
    local function fRewrite(sBody, pFile, bAccessor, tMember, bExpression)
        local tParameters = {'this', 'base'};
        for _, sName in ipairs(tMember.Parameters or {}) do tParameters[#tParameters + 1] = sName; end
        if (bAccessor) then tParameters[#tParameters + 1] = 'field'; end
        local tReferences, tTokens = LuaScope.references(sBody, pFile, tParameters, bExpression);
        local tEdits = {};
        local bUsesThisView = false;
        local bUsesDirectRead = false;
        local bStableThis = not bExpression;
        for _, tReference in ipairs(tReferences) do
            local nIndex = tReference.Index;
            if (tReference.Initial and tTokens[nIndex].Text == 'this' and
                tTokens[nIndex + 1].Text ~= '.' and tTokens[nIndex + 1].Text ~= '[') then
                -- A bare parameter use may assign or capture a reassigned this.
                -- Keep the original per-access path when stability is uncertain.
                bStableThis = false;
                break;
            end
        end
        for _, tReference in ipairs(tReferences) do
            local n = tReference.Index;
            local tToken = tTokens[n];
            if (tReference.Initial and (tToken.Text == 'this' or tToken.Text == 'base')) then
                assert(not (tMember.Flags and tMember.Flags.static), 'Static members cannot use '..tToken.Text..'.');
                assert(tToken.Text ~= 'base' or tTokens[n + 1].Text ~= '(',
                    'Parent constructor call must be first and only in a constructor.');
            end
            if (not tReference.Local) then
                -- Resolution here diagnoses ambiguous imports before any static
                -- initializer runs. Locals and parameters retain ordinary Lua lookup.
                Model.resolve(tToken.Text, tMember.Owner, tMember.Owner.Batch);
            end
            if (bAccessor and tToken.Text == 'field' and tReference.Initial) then
                tMember.UsesBacking = true;
                tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tToken.Stop, Text = '__lxc_field.value'};
            elseif (not tReference.Definition and (tTokens[n + 1].Text == '.' or tTokens[n + 1].Text == '[')) then
                local tKnown = tReference.Initial and tToken.Text == 'this' and
                    tTokens[n + 1].Text == '.' and Model.member(tMember.Owner, tMember.Owner, tTokens[n + 2].Text);
                local sFollowing = tTokens[n + 3] and tTokens[n + 3].Text;
                -- '=' and ',' can end an assignment target. Leave those on the
                -- checked write path; bracket access and properties stay dynamic.
                local bDirect = not bExpression and tKnown and tKnown.Kind == 'field' and
                    not tKnown.Flags.static and sFollowing ~= '=' and sFollowing ~= ',' and
                    Model.memberAllowed(tKnown, tMember.Owner, tMember.Owner);
                if (bDirect) then
                    local tOwner = tMember.Owner;
                    tOwner.DirectReadMembers = tOwner.DirectReadMembers or {};
                    tOwner.DirectReadIndexes = tOwner.DirectReadIndexes or {};
                    local nSlot = tOwner.DirectReadIndexes[tKnown];
                    if (not nSlot) then
                        nSlot = #tOwner.DirectReadMembers + 1;
                        tOwner.DirectReadMembers[nSlot] = tKnown;
                        tOwner.DirectReadIndexes[tKnown] = nSlot;
                    end
                    bUsesDirectRead = true;
                    tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tTokens[n + 2].Stop,
                        Text = '__lxc_read(this,'..nSlot..')'};
                else
                    -- Reuse a stable receiver's lexical view on accesses that
                    -- cannot use a compiler-selected field descriptor.
                    local bThis = bStableThis and tReference.Initial and tToken.Text == 'this';
                    bUsesThisView = bUsesThisView or bThis;
                    tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tToken.Stop,
                        Text = bThis and '__lxc_this' or '__lxc_view('..tToken.Text..')'};
                end
            end
        end
        for n, tToken in ipairs(tTokens) do
            assert(tToken.Text ~= '_ENV' and not string.match(tToken.Text, '^__lxc'), 'Reserved compiler identifier in '..pFile);
            if (tToken.Text == 'function') then
                local x = n + 1;
                while (tTokens[x] and tTokens[x].Text ~= '(') do x = x + 1; end
                assert(tTokens[x], 'Malformed Lua function.');
                while (tTokens[x] and tTokens[x].Text ~= ')') do x = x + 1; end
                assert(tTokens[x], 'Malformed Lua function parameters.');
                tEdits[#tEdits + 1] = {Start = tTokens[x].Stop + 1, Stop = tTokens[x].Stop,
                    Text = ' local __lxc_context = _ENV; local __lxc_guard <close> = nil; '};
            end
        end
        table.sort(tEdits, function(a, b) return a.Start > b.Start; end);
        for _, tEdit in ipairs(tEdits) do
            sBody = string.sub(sBody, 1, tEdit.Start - 1)..tEdit.Text..string.sub(sBody, tEdit.Stop + 1);
        end
        if (bUsesThisView) then sBody = 'local __lxc_this = __lxc_view(this); '..sBody; end
        if (bUsesDirectRead) then sBody = 'local __lxc_read = __lxc_read; '..sBody; end
        return sBody;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Compiler.method
    @desc Compiles a concrete member into Function with hidden this/base/backing-field arguments before declared
        parameters. A declaration without a body remains uncompiled; Runtime.invoke supplies hidden arguments
        later.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @param table tScope Class environment supplied to compilation or registered for lexical ownership.
    @ret nil No return value; updates Function.
    @vis internal
    !]]
    function Compiler.method(tMember, tScope)
        if (not tMember.Body) then return; end
        local tParameters = {'this', 'base', '__lxc_field'};
        for _, sName in ipairs(tMember.Parameters or {}) do tParameters[#tParameters + 1] = sName; end
        if (tMember.Variadic) then tParameters[#tParameters + 1] = '...'; end
        local sBody = fRewrite(tMember.Body, tMember.Owner.File, tMember.Kind == 'accessor', tMember, false);
        -- A nil to-be-closed local keeps Lua 5.4 from eliminating this lexical
        -- frame in return Class() / return callback() tail calls. No __close runs.
        local sHelpers = 'local __lxc_view = __lxc_view; local __lxc_read = __lxc_read; ';
        local sCode = sHelpers..'return function('..table.concat(tParameters, ',')..') local __lxc_context = _ENV; local __lxc_guard <close> = nil; '..
            string.rep('\n', (tMember.Line or 1) - 1)..sBody..'\nend';
        tMember.Function = assert(load(sCode, '@'..tMember.Owner.File, 't', tScope))();

        --[[!
        @fqxn LuaEx.LXC.Compiler.publicBoundMethod
        @desc Emits an instance-bound public body without the generic invocation
            trampoline. Hidden receiver/base/storage bindings are private upvalues;
            this remains a fresh local per call so reassignment cannot persist.
            Restricted/static methods, properties and operators retain their checked
            invocation paths. Every bound call rejects failed/discarded state.
        @vis internal
        !]]
        if (tMember.Kind == 'method' and tMember.Visibility == 'public' and not tMember.Flags.static) then
            -- Select only a complete one-parameter assignment to mutable instance
            -- storage. All bodies are compiled above before native selection.
            if (not tMember.Variadic and #tMember.Parameters == 1 and
                tMember.Parameters[1] ~= 'this' and tMember.Parameters[1] ~= 'base') then
                local tTokens = Tokens.scan(tMember.Body, tMember.Owner.File);
                local bComplete = (#tTokens == 6 and tTokens[6].Text == '<eof>') or
                    (#tTokens == 7 and tTokens[6].Text == ';' and tTokens[7].Text == '<eof>');
                if (bComplete and tTokens[1].Text == 'this' and tTokens[2].Text == '.' and
                    tTokens[4].Text == '=' and tTokens[5].Text == tMember.Parameters[1]) then
                    local tField = Model.member(tMember.Owner, tMember.Owner, tTokens[3].Text);
                    if (tField and tField.Kind == 'field' and not tField.Flags.static and
                        not tField.Flags.const and not tField.Flags.final and
                        Model.memberAllowed(tField, tMember.Owner, tMember.Owner)) then
                        tMember.SetterRoot = tField.Slot or tField;
                    end
                end
            end
            local tArguments = {};
            for _, sName in ipairs(tMember.Parameters or {}) do tArguments[#tArguments + 1] = sName; end
            if (tMember.Variadic) then tArguments[#tArguments + 1] = '...'; end
            local sBoundBody = sBody;
            local sField, sTail = string.match(tMember.Body, '^%s*return%s+this%.([%a_][%w_]*)([%.%w_]*)%s*;?%s*$');
            local tGetter = sField and Model.member(tMember.Owner, tMember.Owner, sField);
            if (tGetter and tGetter.Kind == 'field' and not tGetter.Flags.static and
                Model.memberAllowed(tGetter, tMember.Owner, tMember.Owner)) then
                -- A single-return getter executes no user code before its field
                -- read. Its entry guard covers the read; use live storage directly
                -- rather than repeating receiver checks in the general read helper.
                tMember.GetterRoot = tGetter.Slot or tGetter;
                sBoundBody = 'local __lxc_slot = __lxc_live.Values[__lxc_root]; '..
                    'if not __lxc_slot then error("Field read before initialization: '..tGetter.Name..'"); end; '..
                    'return __lxc_slot.Value'..sTail..';';

                --[[!
                @fqxn LuaEx.LXC.Compiler.slotGetter
                @desc Binds an already allocated instance field's current value for a
                    single-return getter. Validated writes publish new values through
                    a private updater; table contents remain live references. Failed
                    instance/class checks remain on every call; the global error
                    reference also retains the declaring environment for Context.
                    Runtime uses the ordinary bound body if storage is not ready.
                @vis internal
                !]]
                local sGetter = 'return function(__lxc_live,__lxc_value) return function('..
                    table.concat(tArguments, ',')..') '..
                    'if __lxc_live.Failed then error("Instance belongs to a failed load or construction."); end; '..
                    'return __lxc_value'..sTail..'; end, function(__lxc_new) __lxc_value = __lxc_new; end end';
                tMember.SlotGetterFactory = assert(load(sGetter, '@'..tMember.Owner.File, 't', tScope))();
            end
            local sBound = sHelpers..'return function(__lxc_receiver,__lxc_parent,__lxc_live,__lxc_root) return function('..
                table.concat(tArguments, ',')..') local __lxc_context = _ENV; local __lxc_guard <close> = nil; '..
                'if __lxc_live.Failed or __lxc_live.Class.Discarded then error("Instance belongs to a failed load or construction."); end; '..
                'local this = __lxc_receiver; local base = __lxc_parent; local __lxc_field; '..
                string.rep('\n', (tMember.Line or 1) - 1)..sBoundBody..'\nend end';
            tMember.BoundFactory = assert(load(sBound, '@'..tMember.Owner.File, 't', tScope))();
        end
    end

    
    --[[!
    @fqxn LuaEx.LXC.Compiler.constructor
    @desc Separates a unique first-statement base(...) call into ParentArguments. Parent arguments cannot access
        an unconstructed this/base. Compiles the remaining constructor body for Runtime's parent-first
        construction.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @param table tScope Class environment supplied to compilation or registered for lexical ownership.
    @ret nil No return value; updates ParentArguments, Body and Function.
    @vis internal
    !]]
    function Compiler.constructor(tMember, tScope)
        if (not tMember) then return; end
        local tParameters = {'this', 'base'};
        for _, sName in ipairs(tMember.Parameters) do tParameters[#tParameters + 1] = sName; end
        local tReferences, tTokens = LuaScope.references(tMember.Body, tMember.Owner.File, tParameters, false);
        local nCalls = 0;
        for _, tReference in ipairs(tReferences) do
            local n = tReference.Index;
            if (tReference.Initial and tTokens[n].Text == 'base' and tTokens[n + 1].Text == '(') then
                nCalls = nCalls + 1;
                assert(n == 1 and nCalls == 1 and not tMember.Flags.static, 'Parent constructor call must be first and unique.');
            end
        end
        if (nCalls == 1) then
            assert(tMember.Owner.Parent, 'Root class has no parent constructor.');
            local nDepth, x = 1, 3;
            while (nDepth > 0) do
                assert(tTokens[x].Text ~= '<eof>', 'Unterminated parent call.');
                if (tTokens[x].Text == '(') then nDepth = nDepth + 1; end
                if (tTokens[x].Text == ')') then nDepth = nDepth - 1; end
                if (nDepth > 0) then x = x + 1; end
            end
            local sArguments = string.sub(tMember.Body, tTokens[2].Stop + 1, tTokens[x].Start - 1);
            local tArgumentReferences, tArgumentTokens = LuaScope.references(sArguments, tMember.Owner.File, tParameters, true);
            for _, tReference in ipairs(tArgumentReferences) do
                local sName = tArgumentTokens[tReference.Index].Text;
                assert(not tReference.Initial or (sName ~= 'this' and sName ~= 'base'),
                    'Parent arguments cannot access an unconstructed instance.');
            end
            local sTail = string.gsub(string.sub(tMember.Body, tTokens[x].Stop + 1), '^%s*;', '', 1);
            local tArgs = {Owner = tMember.Owner, Line = tMember.Line, Parameters = tMember.Parameters,
                Variadic = tMember.Variadic, Body = 'return '..sArguments};
            Compiler.method(tArgs, tScope);
            tMember.ParentArguments, tMember.Body = tArgs.Function, sTail;
        end
        Compiler.method(tMember, tScope);
    end

    
    --[[!
    @fqxn LuaEx.LXC.Compiler.directInitializerType
    @desc Recognizes a whole table literal, direct class reference or direct class call without execution. More
        complex expressions defer their type contract until ordinary initialization.
    @param table tTokens Token records from Tokens.scan including the final end-of-file token.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @ret string|table|nil vType Primitive/class marker, instance-class definition, or nil.
    @vis internal
    !]]
    local function fDirectInitializerType(tTokens, tMember)
        if (tTokens[1].Text == '{') then
            local nDepth = 0;
            for n, tToken in ipairs(tTokens) do
                if (tToken.Text == '{') then nDepth = nDepth + 1; end
                if (tToken.Text == '}') then
                    nDepth = nDepth - 1;
                    if (nDepth == 0) then return n == #tTokens - 1 and 'table' or nil; end
                end
            end
            return;
        end

        local nIndex, tNames = 1, {};
        while (string.match(tTokens[nIndex].Text, '^[%a_][%w_]*$')) do
            tNames[#tNames + 1] = tTokens[nIndex].Text;
            nIndex = nIndex + 1;
            if (tTokens[nIndex].Text ~= '.') then break; end
            nIndex = nIndex + 1;
        end
        if (#tNames == 0) then return; end
        local tClass = Model.resolve(table.concat(tNames, '.'), tMember.Owner, tMember.Owner.Batch);
        if (not tClass) then return; end
        if (tTokens[nIndex].Text == '<eof>') then return 'class'; end
        if (tTokens[nIndex].Text ~= '(') then return; end

        local nDepth = 0;
        for n = nIndex, #tTokens do
            if (tTokens[n].Text == '(') then nDepth = nDepth + 1; end
            if (tTokens[n].Text == ')') then
                nDepth = nDepth - 1;
                if (nDepth == 0) then return n == #tTokens - 1 and tClass or nil; end
            end
        end
    end

    
    --[[!
    @fqxn LuaEx.LXC.Compiler.initializer
    @desc Compiles Initialize(this), infers literal/direct-construction type contracts without executing
        application code and remembers scalar const values for restore checks. Dynamic contracts are established
        on first ordinary initialization.
    @param table tMember Member definition with Owner, Flags and source metadata.
    @param table tScope Class environment supplied to compilation or registered for lexical ownership.
    @ret nil No return value; updates initializer/contract metadata.
    @vis internal
    !]]
    function Compiler.initializer(tMember, tScope)
        -- Enum payloads are already built by LXE. Keep their initializer private
        -- and let normal static const storage enforce visibility and assignment.
        if (tMember.EnumDefinition) then
            tMember.Initialize = function() return tMember.EnumDefinition.Object; end;
            tMember.ConstValue = tMember.EnumDefinition.Object;
            return;
        end
        if (tMember.Initializer) then
            local sBody = fRewrite(tMember.Initializer, tMember.Owner.File, false, tMember, true);
            tMember.Initialize = assert(load('return function(this) local __lxc_context = _ENV; local __lxc_guard <close> = nil; return '..
                string.rep('\n', (tMember.Line or 1) - 1)..sBody..'\nend',
                '@'..tMember.Owner.File, 't', tScope))();
            -- Literal contracts are inferred without executing application code.
            -- Dynamic initializer contracts are captured on normal construction.
            local sExpression = string.match(tMember.Initializer, '^%s*(.-)%s*$');
            local tLiteral = Tokens.scan(sExpression, tMember.Owner.File);
            local vLiteral;
            if (sExpression == 'true' or sExpression == 'false') then
                tMember.DeclaredType, vLiteral = 'boolean', sExpression == 'true';
            elseif (tonumber(sExpression)) then
                tMember.DeclaredType, vLiteral = 'number', tonumber(sExpression);
            elseif (#tLiteral == 2 and tLiteral[1].Kind == 'string') then
                tMember.DeclaredType = 'string';
                vLiteral = assert(load('return '..sExpression, '@'..tMember.Owner.File, 't', {}))();
            else
                tMember.DeclaredType = fDirectInitializerType(tLiteral, tMember);
            end
            if (tMember.Flags.const) then tMember.ConstValue = vLiteral; end
            local tContract, zInferred = tMember.TypeContract, tMember.DeclaredType;
            if (tContract and zInferred) then
                local bCompatible = tContract.Class and type(zInferred) == 'table' and Model.descends(zInferred, tContract.Class) or
                    not tContract.Class and zInferred == tContract.Name;
                assert(bCompatible, 'Initializer conflicts with @type '..tContract.Name..'.');
            end
        end
    end

    return Compiler;
end;

