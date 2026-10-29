--[[!
@fqxn LXC.Parser
@desc Parses declarations into class/member records. Owns grammar, never runtime
    access or inheritance policy. Ordered Members preserve initialization order.
!]]
return function(Tokens, Names, Operators)
    local Parser = {};
    local tModifiers = {public = true, private = true, protected = true,
        static = true, final = true, const = true, abstract = true, override = true};

    --[[!
    @fqxn LXC.Parser.parse
    @param string sSource One source file, with imports and namespace blocks.
    @param string pFile Source filename used by diagnostics.
    @ret table Flat class list; enclosing classes are linked through Outer.
    !]]
    function Parser.parse(sSource, pFile)
        local tTokens, nIndex, tClasses, tImports = Tokens.scan(sSource, pFile), 1, {}, {};

        local function fFail(sMessage)
            error(pFile..':'..tTokens[nIndex].Line..': '..sMessage, 0);
        end

        local function fPeek() return tTokens[nIndex].Text; end

        local function fTake(sExpected)
            local tToken = tTokens[nIndex];
            if (sExpected and tToken.Text ~= sExpected) then fFail('Expected '..sExpected..', got '..tToken.Text); end
            nIndex = nIndex + 1;
            return tToken.Text;
        end

        local function fName()
            if (not string.match(fPeek(), '^[%a_][%w_]*$')) then fFail('Expected an identifier.'); end
            local sName = fTake();
            if (not Names.valid(sName)) then fFail('Reserved identifier: '..sName); end
            return sName;
        end

        local function fQualified()
            local sName = fName();
            while (fPeek() == '.') do fTake(); sName = sName..'.'..fName(); end
            return sName;
        end

        local function fModifiers()
            local tResult = {};
            while (tModifiers[fPeek()]) do
                local sModifier = fTake();
                if (tResult[sModifier]) then fFail('Duplicate modifier: '..sModifier); end
                tResult[sModifier] = true;
                if (sModifier == 'public' or sModifier == 'private' or sModifier == 'protected') then
                    if (tResult.Visibility) then fFail('Contradictory visibility.'); end
                    tResult.Visibility = sModifier;
                end
            end
            return tResult;
        end

        local function fBody()
            fTake('{');
            local nStart, nLine, nDepth = tTokens[nIndex].Start, tTokens[nIndex].Line, 1;
            while (nDepth > 0) do
                if (fPeek() == '<eof>') then fFail('Unterminated body.'); end
                if (fPeek() == '{') then nDepth = nDepth + 1; end
                if (fPeek() == '}') then nDepth = nDepth - 1; end
                if (nDepth > 0) then nIndex = nIndex + 1; end
            end
            local sBody = string.sub(sSource, nStart, tTokens[nIndex].Start - 1);
            fTake('}');
            return sBody, nLine;
        end

        local function fInitializer()
            fTake('=');
            local nStart, nDepth = tTokens[nIndex].Start, 0;
            local tBlocks = {};
            while (fPeek() ~= ';' or nDepth > 0 or #tBlocks > 0) do
                local sToken = fPeek();
                if (sToken == '<eof>') then fFail('Unterminated initializer.'); end
                if (sToken == '{' or sToken == '(' or sToken == '[') then nDepth = nDepth + 1; end
                if (sToken == '}' or sToken == ')' or sToken == ']') then nDepth = nDepth - 1; end
                if (nDepth < 0) then fFail('Missing initializer semicolon.'); end
                -- Lua function-valued initializers may contain semicolons and
                -- nested Lua blocks independently of declaration/table braces.
                if (sToken == 'function' or sToken == 'if' or sToken == 'repeat' or sToken == 'for' or sToken == 'while') then
                    tBlocks[#tBlocks + 1] = {Kind = sToken, AwaitDo = sToken == 'for' or sToken == 'while'};
                elseif (sToken == 'do') then
                    local tBlock = tBlocks[#tBlocks];
                    if (tBlock and tBlock.AwaitDo) then tBlock.AwaitDo = false;
                    else tBlocks[#tBlocks + 1] = {Kind = 'do'}; end
                elseif (sToken == 'end' or sToken == 'until') then
                    if (#tBlocks == 0) then fFail('Unexpected Lua block end in initializer.'); end
                    tBlocks[#tBlocks] = nil;
                end
                nIndex = nIndex + 1;
            end
            if (tTokens[nIndex].Start == nStart) then fFail('Expected initializer.'); end
            local sExpression = string.sub(sSource, nStart, tTokens[nIndex].Start - 1);
            fTake(';');
            return sExpression;
        end

        local function fParameters()
            fTake('(');
            local tParameters, tSeen, bVariadic = {}, {}, false;
            while (fPeek() ~= ')') do
                if (fPeek() == '...') then fTake(); bVariadic = true; break; end
                local sName = fName();
                if (tSeen[sName] or sName == 'this' or sName == 'base') then
                    fFail('Invalid parameter: '..sName);
                end
                tSeen[sName], tParameters[#tParameters + 1] = true, sName;
                if (fPeek() ~= ',') then break; end
                fTake(',');
            end
            fTake(')');
            return tParameters, bVariadic;
        end

        local fClass;
        fClass = function(sNamespace, tOuter, tFlags)
            fTake('class');
            local sName = fName();
            local tClass = {Name = sName, Namespace = sNamespace, Outer = tOuter, Flags = tFlags,
                FullName = (tOuter and tOuter.FullName or sNamespace)..'.'..sName,
                Members = {}, ByName = {}, Nested = {}, Imports = {}, File = pFile, Line = tTokens[nIndex - 1].Line,
                Visibility = tFlags.Visibility or (tOuter and 'private' or 'public')};
            for n, sImport in ipairs(tImports) do tClass.Imports[n] = sImport; end
            tClasses[#tClasses + 1] = tClass;
            if (tOuter) then
                if (tOuter.Nested[sName] or tOuter.ByName[sName]) then fFail('Duplicate nested member: '..sName); end
                tOuter.Nested[sName] = tClass;
            end
            if (fPeek() == ':') then fTake(); tClass.ParentName = fQualified(); end
            while (fPeek() == 'requires' or fPeek() == 'permits' or fPeek() == 'excludes') do
                local sClause, tNames = fTake(), {};
                if (tClass[sClause]) then fFail('Duplicate clause: '..sClause); end
                fTake('(');
                while (fPeek() ~= ')') do
                    tNames[#tNames + 1] = fQualified();
                    if (fPeek() ~= ',') then break; end
                    fTake(',');
                end
                fTake(')'); tClass[sClause] = tNames;
            end
            fTake('{');
            while (fPeek() ~= '}') do
                local tFlags = fModifiers();
                if (fPeek() == 'class') then
                    fClass(sNamespace, tClass, tFlags);
                else
                    local sName, sOperator;
                    if (fPeek() == 'operator') then
                        fTake(); sOperator = fTake();
                        if (sOperator == '(') then fTake(')'); sOperator = '()';
                        elseif (sOperator == '[') then
                            fTake(']'); sOperator = '[]';
                            if (fPeek() == '=') then fTake(); sOperator = '[]='; end
                        end
                        sName = sOperator;
                    else sName = fName(); end
                    local nLine = tTokens[nIndex - 1].Line;
                    local tMember = {Name = sName, Flags = tFlags, Owner = tClass,
                        Visibility = tFlags.Visibility or 'private', Line = nLine};
                    if (fPeek() == '(') then
                        tMember.Kind = 'method';
                        tMember.Parameters, tMember.Variadic = fParameters();
                        if (sOperator) then
                            sName = Operators.resolve(sOperator, #tMember.Parameters);
                            if (not sName) then fFail('Unsupported operator: '..sOperator); end
                            tMember.Name, tMember.OperatorSpelling = sName, sOperator;
                        end
                        if (tFlags.abstract) then fTake(';');
                        else tMember.Body, tMember.Line = fBody(); end
                    elseif (sOperator) then fFail('Operator declarations require method parameters.');
                    elseif (fPeek() == '{') then
                        tMember.Kind, tMember.Accessors = 'property', {};
                        fTake('{');
                        while (fPeek() ~= '}') do
                            local tAccessFlags = fModifiers();
                            local sAccess = fTake();
                            if (sAccess ~= 'get' and sAccess ~= 'set') then fFail('Expected get or set.'); end
                            if (tMember.Accessors[sAccess]) then fFail('Duplicate accessor.'); end
                            local tAccessor = {Name = sAccess, Kind = 'accessor', Owner = tClass,
                                Flags = {static = tFlags.static}, Visibility = tAccessFlags.Visibility or tMember.Visibility,
                                Parameters = sAccess == 'set' and {'value'} or {}, Property = tMember};
                            for k in pairs(tAccessFlags) do if (k ~= 'Visibility' and k ~= tAccessFlags.Visibility) then fFail('Invalid accessor modifier.'); end end
                            tAccessor.Prefix = sAccess;
                            if (fPeek() == '(') then
                                fTake();
                                local fLiteral = load('return '..fTake(), '@'..pFile, 't', {});
                                if (not fLiteral) then fFail('Expected quoted prefix.'); end
                                local bOK, sPrefix = pcall(fLiteral);
                                if (not bOK or type(sPrefix) ~= 'string' or not string.match(sPrefix, '^[%a_][%w_]*$')) then fFail('Invalid accessor prefix.'); end
                                tAccessor.Prefix, tAccessor.ExplicitPrefix = sPrefix, true;
                                fTake(')');
                            end
                            if (fPeek() == ';') then fTake();
                            else tAccessor.Body, tAccessor.Line = fBody(); end
                            tMember.Accessors[sAccess] = tAccessor;
                        end
                        fTake('}');
                        if (fPeek() == '=') then tMember.Initializer = fInitializer();
                        elseif (fPeek() == ';') then fTake(); end
                    else
                        tMember.Kind = 'field';
                        if (fPeek() == '=') then tMember.Initializer = fInitializer(); else fTake(';'); end
                    end
                    if (sName == tClass.Name and tMember.Kind == 'method') then
                        local sKey = tFlags.static and 'StaticConstructor' or 'Constructor';
                        if (tClass[sKey]) then fFail('Duplicate constructor.'); end
                        tClass[sKey] = tMember;
                    else
                        if (tClass.ByName[sName] or tClass.Nested[sName]) then fFail('Duplicate member: '..sName); end
                        tClass.ByName[sName], tClass.Members[#tClass.Members + 1] = tMember, tMember;
                    end
                end
            end
            fTake('}');
            return tClass;
        end;

        while (fPeek() ~= '<eof>') do
            if (fPeek() == 'using') then
                fTake(); tImports[#tImports + 1] = fQualified(); fTake(';');
            else
                fTake('namespace'); local sNamespace = fQualified(); fTake('{');
                local tFileImports = tImports;
                tImports = {}; for n, sImport in ipairs(tFileImports) do tImports[n] = sImport; end
                local bDeclared = false;
                while (fPeek() ~= '}') do
                    if (fPeek() == 'using') then
                        if (bDeclared) then fFail('using declarations must precede classes.'); end
                        fTake(); tImports[#tImports + 1] = fQualified(); fTake(';');
                    else bDeclared = true; fClass(sNamespace, nil, fModifiers()); end
                end
                fTake('}');
                tImports = tFileImports;
            end
        end
        return tClasses;
    end

    return Parser;
end;
