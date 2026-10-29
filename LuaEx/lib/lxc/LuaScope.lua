--[[!
@fqxn LuaEx.LXC.LuaScope
@desc <h3>LuaScope — responsibility and connections</h3><p>Walks Lua source to distinguish local/parameter uses
    from free variable references. Compiler uses this to resolve class names and preserve declaring-class member
    access. It tracks nested functions, blocks, loops and precedence; Lua load still performs final
    compilation.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.LuaScope.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Tokens Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
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
    @fqxn LuaEx.LXC.LuaScope.references
    @desc Tracks local scopes and seeded parameters while walking Lua. Returns variable token indices with
        Local/Initial/Definition flags; selectors, table keys and labels are not free variables. An optional
        callback receives top-level statement token ranges.
    @param string sSource Source text; the operation description specifies whether this is LXC, Lua or snapshot
        data.
    @param string pFile Diagnostic source filename; source-map loads do not require a physical file.
    @param table|nil tParameters Parameter names seeded into the initial lexical scope.
    @param boolean bExpression True for an expression list; false/nil for a statement body.
    @param function|nil fStatement Optional callback(tokens, firstIndex, lastIndex) for top-level statement
        boundaries.
    @ret table tReferences Followed by table tTokens from Tokens.scan.
    @vis internal
    !]]
    function LuaScope.references(sSource, pFile, tParameters, bExpression, fStatement)
        local tTokens = Tokens.scan(sSource, pFile);
        local nIndex, tScopes, tReferences = 1, {{}}, {};
        local nBlockDepth = bExpression and 1 or 0;
        for _, sName in ipairs(tParameters or {}) do tScopes[1][sName] = 'parameter'; end

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.peek
        @desc Looks ahead without consuming a token; nil offset means current token.
        @param number|nil nOffset Lookahead offset; nil means zero.
        @ret string sText Token spelling.
        @vis internal
        !]]
        local function fPeek(nOffset) return tTokens[nIndex + (nOffset or 0)].Text; end

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.take
        @desc Consumes a token after an optional exact-spelling check, with filename/line diagnostics on
            mismatch.
        @param string|nil sExpected Optional exact token spelling required at the cursor.
        @ret string sText Consumed spelling.
        @vis internal
        !]]
        local function fTake(sExpected)
            local sText = fPeek();
            assert(not sExpected or sText == sExpected,
                pFile..':'..tTokens[nIndex].Line..': Expected '..tostring(sExpected)..', got '..sText);
            nIndex = nIndex + 1;
            return sText;
        end

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.bind
        @desc Adds a local to the innermost scope; ordinary initializers are walked before binding new names so
            outer bindings remain visible there.
        @param string sName Name/path to resolve or inspect under the lookup rules described above.
        @ret nil No return value; updates scope.
        @vis internal
        !]]
        local function fBind(sName) tScopes[#tScopes][sName] = true; end
        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.push
        @desc Starts a scope while retaining outer bindings for reference lookup.
        @ret nil No return value; appends a scope.
        @vis internal
        !]]
        local function fPush() tScopes[#tScopes + 1] = {}; end
        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.pop
        @desc Ends the innermost block/function scope.
        @ret nil No return value; removes a scope.
        @vis internal
        !]]
        local function fPop() tScopes[#tScopes] = nil; end

        -- Record only variable uses. Table keys, labels, selectors and parameter
        -- declarations do not resolve through the class environment.
        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.reference
        @desc Records a variable use or named-function definition, searching inner-to-outer scopes and marking
            seeded parameters. Compiler uses this to avoid treating locals as class names.
        @param boolean bDefinition Whether this reference defines a named function.
        @ret nil No return value; records and consumes a reference.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.expressionList
        @desc Walks comma-separated Lua expressions.
        @ret nil No return value; advances the cursor.
        @vis internal
        !]]
        local function fExpressionList()
            fExpression(0);
            while (fPeek() == ',') do fTake(); fExpression(0); end
        end

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.table
        @desc Walks a table constructor, visiting expression keys but not confusing bare-name keys with variable
            uses. Supports commas/semicolons.
        @ret nil No return value; consumes a constructor.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.prefix
        @desc Walks a variable/parenthesized expression and selectors, indexing and calls. Only the initial
            variable is recorded; dotted member names remain selectors.
        @ret nil No return value; consumes the chain.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.arguments
        @desc Walks parenthesized argument lists or table/string call shorthand.
        @ret nil No return value; consumes arguments.
        @vis internal
        !]]
        fArguments = function()
            if (fPeek() == '(') then
                fTake();
                if (fPeek() ~= ')') then fExpressionList(); end
                fTake(')');
            elseif (fPeek() == '{') then fTable();
            else assert(tTokens[nIndex].Kind == 'string', pFile..': Expected call arguments.'); fTake(); end
        end;

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.function
        @desc Walks parameters/body in a new scope. Colon methods bind self and nested functions retain outer
            lexical bindings.
        @param boolean bMethod Whether colon-method syntax binds self locally.
        @ret nil No return value; consumes through end.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.expression
        @desc Walks expressions by precedence without evaluating them. Power/concatenation associate right;
            literals/functions/tables/unary expressions enter their respective walkers.
        @param number nMinimum Minimum precedence for this recursive expression step.
        @ret nil No return value; consumes an expression.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.scopedBlock
        @desc Pairs scope push/pop around a statement block so local bindings do not leak outward.
        @ret nil No return value; leaves the closing token.
        @vis internal
        !]]
        local function fScopedBlock()
            fPush(); fBlock(); fPop();
        end

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.local
        @desc Walks local declarations and Lua 5.4 attributes. Local functions bind before their body for
            recursion; ordinary locals bind after initializers.
        @ret nil No return value; updates cursor/bindings.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.for
        @desc Walks numeric/generic for. Iterator/range expressions see outer scope; loop variables become local
            only in the body after do.
        @ret nil No return value; consumes through end.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.LuaScope.references.block
        @desc Walks statements until end/else/elseif/until/end-of-file, including goto/labels/returns and nested
            blocks. Calls an optional observer for top-level statement boundaries.
        @ret nil No return value; leaves the boundary token.
        @vis internal
        !]]
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
