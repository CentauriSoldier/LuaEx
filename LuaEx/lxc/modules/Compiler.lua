--[[!
@fqxn LXC.Compiler
@desc Compiles preserved Lua bodies in private lexical class environments. Keeps
    nested Lua closures associated with their declaration context. Does not publish.
!]]
return function(Tokens, Model, LuaScope)
    local Compiler = {};

    --[[!
    @fqxn LXC.Compiler.rewrite
    @desc Inserts lexical context retention into nested functions and maps the
        accessor-only field name to a checked storage reference. Strings are opaque.
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
    @fqxn LXC.Compiler.method
    @desc Creates one method with hidden this/base/storage arguments. Signature
        compatibility counts only source-declared parameters.
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
    @fqxn LXC.Compiler.constructor
    @desc Extracts an explicit first-statement base call into argument evaluation.
        The runtime performs parent construction before child fields/body.
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
    @fqxn LXC.Compiler.directInitializerType
    @desc Infers only complete table literals and direct registered class values
        or constructor calls. Constructors cannot return replacement objects, so
        these class constraints are known without executing application code.
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
    @fqxn LXC.Compiler.initializer
    @desc Compiles one initializer without running it. Only complete primitive
        literals establish static persistence constraints; dynamic values remain
        per-slot data. Retains lexical context during initializer tail calls.
    @param table tMember Field/property definition, optionally with Initializer.
    @param table tScope Private registered compiler environment.
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
