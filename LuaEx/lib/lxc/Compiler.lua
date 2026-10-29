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
    @desc Resolves free class names before static execution, rewrites accessor field references and wraps member
        receivers in a lexical view. Edits run backwards by source offset. Nested functions retain their class
        environment and a Lua 5.4 frame guard.
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
                tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tToken.Stop, Text = '__lxc_field.value'};
            elseif (not tReference.Definition and (tTokens[n + 1].Text == '.' or tTokens[n + 1].Text == '[')) then
                tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tToken.Stop,
                    Text = '__lxc_view('..tToken.Text..')'};
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
        local sCode = 'return function('..table.concat(tParameters, ',')..') local __lxc_context = _ENV; local __lxc_guard <close> = nil; '..
            string.rep('\n', (tMember.Line or 1) - 1)..sBody..'\nend';
        tMember.Function = assert(load(sCode, '@'..tMember.Owner.File, 't', tScope))();
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
        end
    end

    return Compiler;
end;
