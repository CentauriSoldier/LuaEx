--[[!
@fqxn LuaEx.LXC.Parser
@desc <h3>Parser — responsibility and connections</h3><p>Reads the LXC declaration language into class/member
    records without executing application code. Tokens protects strings/comments; Parser recognizes namespaces,
    imports, modifiers, inheritance clauses, fields, properties, constructors and operators. Bodies remain Lua
    text for Compiler; Model and Validation enforce semantic contracts afterwards.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
@prifield table tModifiers Private local map: Parser recognizes
    public/private/protected/static/final/const/abstract/override flags; Validation decides where each is legal.
!]]

--[[!
@fqxn LuaEx.LXC.Parser.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Tokens Private injected dependency; its role is described in the module map.
@param table Names Private injected dependency; its role is described in the module map.
@param table Operators Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Tokens, Names, Operators)
    local Parser = {};
    local tModifiers = {public = true, private = true, protected = true,
        static = true, final = true, const = true, abstract = true, override = true};

    
    --[[!
    @fqxn LuaEx.LXC.Parser.parse
    @desc Produces a flat list of linked class/nested definitions. Preserves member order and Lua
        body/initializer text; imports are copied at declaration time. Does not execute application code or
        create live classes.
    @param string sSource Source text; the operation description specifies whether this is LXC, Lua or snapshot
        data.
    @param string pFile Diagnostic source filename; source-map loads do not require a physical file.
    @ret table tClasses Parsed records.
    @vis internal
    !]]
    function Parser.parse(sSource, pFile)
        local tTokens, nIndex, tClasses, tImports = Tokens.scan(sSource, pFile), 1, {}, {};

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.fail
        @desc Raises a diagnostic at the current filename/token line.
        @param string sMessage Grammar failure explanation.
        @ret nil Never returns; raises a grammar error.
        @vis internal
        !]]
        local function fFail(sMessage)
            error(pFile..':'..tTokens[nIndex].Line..': '..sMessage, 0);
        end

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.peek
        @desc Reads the current token without advancing.
        @ret string sText Token spelling.
        @vis internal
        !]]
        local function fPeek() return tTokens[nIndex].Text; end

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.take
        @desc Consumes a token after an optional exact-spelling requirement.
        @param string|nil sExpected Optional exact token spelling required at the cursor.
        @ret string sText Consumed spelling.
        @vis internal
        !]]
        local function fTake(sExpected)
            local tToken = tTokens[nIndex];
            if (sExpected and tToken.Text ~= sExpected) then fFail('Expected '..sExpected..', got '..tToken.Text); end
            nIndex = nIndex + 1;
            return tToken.Text;
        end

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.name
        @desc Reads an identifier and applies Names.valid, rejecting reserved/compiler-private names.
        @ret string sName Valid identifier.
        @vis internal
        !]]
        local function fName()
            if (not string.match(fPeek(), '^[%a_][%w_]*$')) then fFail('Expected an identifier.'); end
            local sName = fTake();
            if (not Names.valid(sName)) then fFail('Reserved identifier: '..sName); end
            return sName;
        end

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.qualified
        @desc Reads dot-separated valid identifiers for namespaces/imports/parent references/clauses.
        @ret string sName Dotted path.
        @vis internal
        !]]
        local function fQualified()
            local sName = fName();
            while (fPeek() == '.') do fTake(); sName = sName..'.'..fName(); end
            return sName;
        end

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.modifiers
        @desc Collects flags and rejects duplicates/contradictory visibility. Validation checks their legality
            for the declaration kind.
        @ret table tFlags Modifier flags and optional Visibility.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.body
        @desc Captures original text inside balanced braces and its first token line; string/comment tokens
            protect internal braces.
        @ret string sBody Followed by number nLine for diagnostics.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.initializer
        @desc Captures an expression after = through its required outer semicolon, tracking Lua blocks/brackets
            so function-valued initializers may contain internal semicolons.
        @ret string sExpression Text without = or final semicolon.
        @vis internal
        !]]
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

        --[[!
        @fqxn LuaEx.LXC.Parser.parse.parameters
        @desc Reads untyped identifiers and optional final vararg; rejects duplicates and this/base parameters
            supplied implicitly by LXC.
        @ret table tParameters Followed by boolean bVariadic.
        @vis internal
        !]]
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
        --[[!
        @fqxn LuaEx.LXC.Parser.parse.class
        @desc Parses classes/nested classes, clauses, fields, properties, methods and operators. Recognizes
            constructors by class name and builds accessor argument metadata.
        @param string sNamespace Qualified namespace containing the declaration.
        @param table|nil tOuter Enclosing class for a nested declaration, otherwise nil.
        @param table tFlags Parsed visibility/modifier flags.
        @ret table tClass New definition also added to the flat output.
        @vis internal
        !]]
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
