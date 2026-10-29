--[[!
@fqxn LXC.LuaScope
@desc Compile-time lexical analysis of Lua 5.4 bodies. Records variable-reference
    tokens and whether a local/parameter shadows class-name lookup. Does not
    execute source, infer method types, or replace Lua's own syntax validation.
    Compiler uses these references for precise rewriting and ambiguity checks.
!]]
return function(Tokens)
    local LuaScope = {};
    local tBinary = {
        ['or'] = 1, ['and'] = 2,
        ['<'] = 3, ['>'] = 3, ['<='] = 3, ['>='] = 3, ['~='] = 3, ['=='] = 3,
        ['|'] = 4, ['~'] = 5, ['&'] = 6, ['<<'] = 7, ['>>'] = 7,
        ['..'] = 8, ['+'] = 9, ['-'] = 9,
        ['*'] = 10, ['/'] = 10, ['//'] = 10, ['%'] = 10, ['^'] = 12,
    };
    local tUnary = {['not'] = true, ['#'] = true, ['-'] = true, ['~'] = true};
    local tEnd = {['end'] = true, ['else'] = true, ['elseif'] = true,
        ['until'] = true, ['<eof>'] = true};

    --[[!
    @fqxn LXC.LuaScope.references
    @param string sSource Lua body or initializer expression.
    @param string pFile Filename used in lexical diagnostics.
    @param table tParameters Initially bound method parameters and implicit names.
    @param boolean bExpression Analyze an initializer instead of a statement block.
    @ret table Reference records {Index, Local, Definition}, followed by tokens.
    !]]
    function LuaScope.references(sSource, pFile, tParameters, bExpression, fStatement)
        local tTokens = Tokens.scan(sSource, pFile);
        local nIndex, tScopes, tReferences = 1, {{}}, {};
        local nBlockDepth = bExpression and 1 or 0;
        for _, sName in ipairs(tParameters or {}) do tScopes[1][sName] = 'parameter'; end

        local function fPeek(nOffset) return tTokens[nIndex + (nOffset or 0)].Text; end

        local function fTake(sExpected)
            local sText = fPeek();
            assert(not sExpected or sText == sExpected,
                pFile..':'..tTokens[nIndex].Line..': Expected '..tostring(sExpected)..', got '..sText);
            nIndex = nIndex + 1;
            return sText;
        end

        local function fBind(sName) tScopes[#tScopes][sName] = true; end
        local function fPush() tScopes[#tScopes + 1] = {}; end
        local function fPop() tScopes[#tScopes] = nil; end

        -- Record only variable uses. Table keys, labels, selectors and parameter
        -- declarations do not resolve through the class environment.
        local function fReference(bDefinition)
            local sName, bLocal, bInitial = fPeek(), false, false;
            assert(string.match(sName, '^[%a_][%w_]*$'),
                pFile..':'..tTokens[nIndex].Line..': Expected Lua variable, got '..sName..'.');
            for n = #tScopes, 1, -1 do
                if (tScopes[n][sName]) then
                    bLocal, bInitial = true, tScopes[n][sName] == 'parameter';
                    break;
                end
            end
            tReferences[#tReferences + 1] = {Index = nIndex, Local = bLocal, Initial = bInitial, Definition = bDefinition};
            fTake();
        end

        local fExpression, fBlock, fFunction, fArguments;

        local function fExpressionList()
            fExpression(0);
            while (fPeek() == ',') do fTake(); fExpression(0); end
        end

        local function fTable()
            fTake('{');
            while (fPeek() ~= '}') do
                if (fPeek() == '[') then
                    fTake(); fExpression(0); fTake(']'); fTake('='); fExpression(0);
                elseif (fPeek(1) == '=') then
                    fTake(); fTake('='); fExpression(0);
                else fExpression(0); end
                if (fPeek() ~= ',' and fPeek() ~= ';') then break; end
                fTake();
            end
            fTake('}');
        end

        local function fPrefix()
            if (fPeek() == '(') then fTake(); fExpression(0); fTake(')');
            else fReference(false); end

            while (true) do
                local sToken = fPeek();
                if (sToken == '.') then fTake(); fTake();
                elseif (sToken == '[') then fTake(); fExpression(0); fTake(']');
                elseif (sToken == ':') then fTake(); fTake(); fArguments();
                elseif (sToken == '(' or sToken == '{' or tTokens[nIndex].Kind == 'string') then fArguments();
                else break; end
            end
        end

        fArguments = function()
            if (fPeek() == '(') then
                fTake();
                if (fPeek() ~= ')') then fExpressionList(); end
                fTake(')');
            elseif (fPeek() == '{') then fTable();
            else assert(tTokens[nIndex].Kind == 'string', pFile..': Expected call arguments.'); fTake(); end
        end;

        fFunction = function(bMethod)
            fTake('('); fPush();
            if (bMethod) then fBind('self'); end
            while (fPeek() ~= ')') do
                local sName = fTake();
                if (sName == '...') then break; end
                fBind(sName);
                if (fPeek() ~= ',') then break; end
                fTake();
            end
            fTake(')'); fBlock(); fTake('end'); fPop();
        end;

        fExpression = function(nMinimum)
            local sToken, sKind = fPeek(), tTokens[nIndex].Kind;
            if (tUnary[sToken]) then fTake(); fExpression(11);
            elseif (sToken == 'function') then fTake(); fFunction(false);
            elseif (sToken == '{') then fTable();
            elseif (sKind == 'number' or sKind == 'string' or sToken == 'nil' or
                sToken == 'true' or sToken == 'false' or sToken == '...') then fTake();
            else fPrefix(); end

            while (tBinary[fPeek()] and tBinary[fPeek()] > nMinimum) do
                local sOperator = fTake();
                local nRank = tBinary[sOperator];
                fExpression((sOperator == '^' or sOperator == '..') and nRank - 1 or nRank);
            end
        end;

        local function fScopedBlock()
            fPush(); fBlock(); fPop();
        end

        local function fLocal()
            fTake('local');
            if (fPeek() == 'function') then
                fTake(); fBind(fTake()); fFunction(false);
                return;
            end

            local tNames = {};
            repeat
                tNames[#tNames + 1] = fTake();
                if (fPeek() == '<') then fTake(); fTake(); fTake('>'); end
                if (fPeek() ~= ',') then break; end
                fTake();
            until (false);
            if (fPeek() == '=') then fTake(); fExpressionList(); end
            -- A local's initializer still sees its previous outer binding.
            for _, sName in ipairs(tNames) do fBind(sName); end
        end

        local function fFor()
            fTake('for');
            local tNames = {fTake()};
            while (fPeek() == ',') do fTake(); tNames[#tNames + 1] = fTake(); end
            if (fPeek() == '=') then fTake(); fExpressionList();
            else fTake('in'); fExpressionList(); end
            fTake('do'); fPush();
            for _, sName in ipairs(tNames) do fBind(sName); end
            fBlock(); fTake('end'); fPop();
        end

        fBlock = function()
            nBlockDepth = nBlockDepth + 1;
            while (not tEnd[fPeek()]) do
                local nStatementStart = nIndex;
                local sToken = fPeek();
                if (sToken == ';' or sToken == 'break') then fTake();
                elseif (sToken == '::') then fTake(); fTake(); fTake('::');
                elseif (sToken == 'goto') then fTake(); fTake();
                elseif (sToken == 'local') then fLocal();
                elseif (sToken == 'for') then fFor();
                elseif (sToken == 'do') then fTake(); fScopedBlock(); fTake('end');
                elseif (sToken == 'while') then
                    fTake(); fExpression(0); fTake('do'); fScopedBlock(); fTake('end');
                elseif (sToken == 'repeat') then
                    fTake(); fPush(); fBlock(); fTake('until'); fExpression(0); fPop();
                elseif (sToken == 'if') then
                    fTake(); fExpression(0); fTake('then'); fScopedBlock();
                    while (fPeek() == 'elseif') do
                        fTake(); fExpression(0); fTake('then'); fScopedBlock();
                    end
                    if (fPeek() == 'else') then fTake(); fScopedBlock(); end
                    fTake('end');
                elseif (sToken == 'function') then
                    fTake(); fReference(true);
                    while (fPeek() == '.') do fTake(); fTake(); end
                    local bMethod = fPeek() == ':';
                    if (bMethod) then fTake(); fTake(); end
                    fFunction(bMethod);
                elseif (sToken == 'return') then
                    fTake();
                    if (not tEnd[fPeek()] and fPeek() ~= ';') then fExpressionList(); end
                else
                    fPrefix();
                    while (fPeek() == ',') do fTake(); fPrefix(); end
                    if (fPeek() == '=') then fTake(); fExpressionList(); end
                end
                if (fStatement and nBlockDepth == 1) then fStatement(tTokens, nStatementStart, nIndex - 1); end
            end
            nBlockDepth = nBlockDepth - 1;
        end;

        if (bExpression) then
            if (fPeek() ~= '<eof>') then fExpressionList(); end
        else fBlock(); end
        fTake('<eof>');
        return tReferences, tTokens;
    end

    return LuaScope;
end;
