--[[!
    @fqxn LuaEx.Utilities.prettyLua
    @pulsarlua function prettyLua
    @desc Formats a Lua chunk or expression using four-space indentation. Supports
    Lua 5.3 syntax and Lua 5.4 local attributes. Strings, comments, numerals and
    operators retain their original bytes; only whitespace between tokens changes.
    Source is parsed, never executed. No globals or framework objects are required.
    This is a syntax formatter, not a compiler: scope and runtime rules still apply.
    @param string sSource Lua source, including standalone serialized expressions.
    @ret string|nil sFormatted Formatted source, or nil on a lexical/syntax error.
    @ret string|nil sReason Diagnostic on failure; nil on success.
    @ex local sPretty, sReason = prettyLua(serialize(oObject));
!]]
local _tKeywords = {};
for sWord in ("and break do else elseif end false for function goto if in local nil not or repeat return then true until while"):gmatch("%S+") do
    _tKeywords[sWord] = true;
end

-- Left and right binding powers preserve Lua's precedence and associativity.
local _tOperators = {
    ["or"] = {1, 1}, ["and"] = {2, 2},
    ["<"] = {3, 3}, [">"] = {3, 3}, ["<="] = {3, 3}, [">="] = {3, 3}, ["~="] = {3, 3}, ["=="] = {3, 3},
    ["|"] = {4, 4}, ["~"] = {5, 5}, ["&"] = {6, 6}, ["<<"] = {7, 7}, [">>"] = {7, 7},
    [".."] = {8, 7}, ["+"] = {9, 9}, ["-"] = {9, 9},
    ["*"] = {10, 10}, ["/"] = {10, 10}, ["//"] = {10, 10}, ["%"] = {10, 10}, ["^"] = {12, 11},
};
local _tUnary = {["not"] = true, ["#"] = true, ["-"] = true, ["~"] = true};
local _tStops = {["end"] = true, ["else"] = true, ["elseif"] = true, ["until"] = true};

--[[!
    @fqxn LuaEx.Utilities.prettyLua.Internal.longBracket
    @desc Finds a long string/comment delimiter of any equals-sign depth.
    @param string sSource Source text.
    @param number nStart Opening bracket position.
    @ret number|nil nAfter Position after the closing delimiter, if present.
    @ret boolean bOpened Whether an opening delimiter was found.
!]]
local function longBracket(sSource, nStart)
    local sEquals = sSource:match("^%[(=*)%[", nStart);
    if (not sEquals) then
        return nil, false;
    end

    local _, nLast = sSource:find("]"..sEquals.."]", nStart + #sEquals + 2, true);
    return nLast and nLast + 1, true;
end

--[[!
    @fqxn LuaEx.Utilities.prettyLua.Internal.lex
    @desc Splits source into exact tokens, retaining comments and preceding line
    counts. Quoted escapes and long brackets are consumed before code punctuation.
    @param string sSource Source text.
    @ret table tTokens All tokens, including comments.
    @ret table tCode References to the non-comment tokens.
    @throws Unterminated literals, invalid numerals and unknown characters.
!]]
local function lex(sSource)
    local tTokens, tCode = {}, {};
    local nPosition, nLength = 1, #sSource;
    local nLines = 0;

    while (nPosition <= nLength) do
        local sChar = sSource:sub(nPosition, nPosition);
        local nStart = nPosition;
        local sKind;

        if (sChar:match("%s")) then
            local sSpace = sSource:match("^%s+", nPosition);
            local _, nCount = sSpace:gsub("\r\n", "\n"):gsub("[\r\n]", "");
            nLines    = nLines + nCount;
            nPosition = nPosition + #sSpace;
        else
            if (sSource:sub(nPosition, nPosition + 1) == "--") then
                local nAfter, bOpened = longBracket(sSource, nPosition + 2);
                assert(not bOpened or nAfter, "Unterminated long comment at byte "..nStart..".");
                nPosition = nAfter or sSource:find("[\r\n]", nPosition) or (nLength + 1);
                sKind     = bOpened and "longComment" or "lineComment";
            elseif (nPosition == 1 and sSource:sub(1, 2) == "#!") then
                nPosition = sSource:find("[\r\n]", nPosition) or (nLength + 1);
                sKind = "lineComment";
            elseif (sChar == "'" or sChar == '"') then
                nPosition = nPosition + 1;
                while (nPosition <= nLength and sSource:sub(nPosition, nPosition) ~= sChar) do
                    local sNext = sSource:sub(nPosition, nPosition);
                    assert(sNext ~= "\n" and sNext ~= "\r", "Unescaped newline in string at byte "..nStart..".");

                    if (sNext == "\\") then
                        nPosition = nPosition + 1;
                        sNext = sSource:sub(nPosition, nPosition);
                        if (sNext == "z") then
                            nPosition = nPosition + 1;
                            local sSpace = sSource:match("^%s*", nPosition);
                            nPosition = nPosition + #sSpace;
                        elseif (sNext == "\r" or sNext == "\n") then
                            nPosition = nPosition + 1;
                            local sFollowing = sSource:sub(nPosition, nPosition);
                            if ((sNext == "\r" and sFollowing == "\n") or (sNext == "\n" and sFollowing == "\r")) then
                                nPosition = nPosition + 1;
                            end
                        elseif (sNext:match("%d")) then
                            local sDigits = sSource:match("^%d%d?%d?", nPosition);
                            assert(tonumber(sDigits) <= 255, "Invalid decimal escape at byte "..nPosition..".");
                            nPosition = nPosition + #sDigits;
                        elseif (sNext == "x") then
                            assert(sSource:sub(nPosition + 1, nPosition + 2):match("^%x%x$"), "Invalid hexadecimal escape at byte "..nPosition..".");
                            nPosition = nPosition + 3;
                        elseif (sNext == "u") then
                            local sEscape = sSource:match("^u{%x+}", nPosition);
                            assert(sEscape and tonumber(sEscape:sub(3, -2), 16) <= 0x7FFFFFFF, "Invalid Unicode escape at byte "..nPosition..".");
                            nPosition = nPosition + #sEscape;
                        else
                            assert(sNext ~= "" and sNext:match("^[abfnrtv\\'\"]$"), "Invalid escape at byte "..nPosition..".");
                            nPosition = nPosition + 1;
                        end
                    else
                        nPosition = nPosition + 1;
                    end
                end

                assert(nPosition <= nLength, "Unterminated string at byte "..nStart..".");
                nPosition = nPosition + 1;
                sKind = "string";
            elseif (sChar == "[" and sSource:match("^%[=*%[", nPosition)) then
                nPosition = longBracket(sSource, nPosition);
                assert(nPosition, "Unterminated long string at byte "..nStart..".");
                sKind = "string";
            elseif (sChar:match("[%a_]")) then
                local sWord = sSource:match("^[%w_]+", nPosition);
                nPosition = nPosition + #sWord;
                sKind = _tKeywords[sWord] and "keyword" or "name";
            elseif (sChar:match("%d") or (sChar == "." and sSource:sub(nPosition + 1, nPosition + 1):match("%d"))) then
                local bHex = sSource:sub(nPosition, nPosition + 1):lower() == "0x";
                nPosition = nPosition + 1;
                while (nPosition <= nLength) do
                    local sNext = sSource:sub(nPosition, nPosition);
                    local sPrevious = sSource:sub(nPosition - 1, nPosition - 1);
                    if (sNext:match("[%w_%.]") or ((sNext == "+" or sNext == "-") and sPrevious:match(bHex and "[pP]" or "[eE]"))) then
                        nPosition = nPosition + 1;
                    else
                        break;
                    end
                end
                assert(tonumber(sSource:sub(nStart, nPosition - 1)), "Invalid numeral at byte "..nStart..".");
                sKind = "number";
            else
                local sThree = sSource:sub(nPosition, nPosition + 2);
                local sTwo   = sSource:sub(nPosition, nPosition + 1);
                if (sThree == "...") then
                    nPosition = nPosition + 3;
                elseif (sTwo == ".." or sTwo == "//" or sTwo == "<<" or sTwo == ">>" or sTwo == "==" or sTwo == "~=" or sTwo == "<=" or sTwo == ">=" or sTwo == "::") then
                    nPosition = nPosition + 2;
                else
                    assert(sChar:match("^[%+%-%*/%%%^#&|~<>=%(%){}%[%];:,%.]$"), "Unexpected character at byte "..nStart..".");
                    nPosition = nPosition + 1;
                end
                sKind = "symbol";
            end

            local tToken = {text = sSource:sub(nStart, nPosition - 1), kind = sKind, lines = nLines, position = nStart};
            tTokens[#tTokens + 1] = tToken;
            if (sKind ~= "lineComment" and sKind ~= "longComment") then
                tCode[#tCode + 1] = tToken;
            end
            nLines = 0;
        end
    end

    return tTokens, tCode;
end

--[[!
    @fqxn LuaEx.Utilities.prettyLua.Internal.parse
    @desc Parses a chunk or a single expression and marks indentation, statement
    boundaries and punctuation spacing on its tokens. Binding powers handle all
    Lua operators without rewriting expressions or inserting/removing tokens.
    @param table tCode Non-comment tokens.
    @param boolean bExpression Parse a standalone expression instead of a chunk.
    @throws An unexpected or missing grammar token.
!]]
local function parse(tCode, bExpression)
    local nIndex = 1;
    local fExpression, fBlock, fBody, fTable, fPrefix;

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.peek
        @desc Reads token text without advancing the parser.
        @param number|nil nOffset Optional lookahead offset.
        @ret string sText Token text, or an empty string at end of input.
    !]]
    local function fPeek(nOffset)
        local tToken = tCode[nIndex + (nOffset or 0)];
        return tToken and tToken.text or "";
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.take
        @desc Consumes a token, validates optional expected text and records depth.
        @param number nDepth Indentation depth.
        @param string|nil sExpected Required token text, when supplied.
        @ret table tToken Consumed token.
    !]]
    local function fTake(nDepth, sExpected)
        local tToken = tCode[nIndex];
        assert(tToken and (not sExpected or tToken.text == sExpected), "Expected "..(sExpected or "a token").." at "..(tToken and ("byte "..tToken.position) or "end of input")..".");
        tToken.depth = nDepth;
        nIndex = nIndex + 1;
        return tToken;
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.name
        @desc Consumes an identifier, rejecting reserved keywords.
        @param number nDepth Indentation depth.
    !]]
    local function fName(nDepth)
        assert(tCode[nIndex] and tCode[nIndex].kind == "name", "Expected an identifier near '"..fPeek().."'.");
        fTake(nDepth);
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.line
        @desc Begins a structural line, preserving at most one existing blank line.
    !]]
    local function fLine()
        if (tCode[nIndex]) then
            tCode[nIndex].breaks = tCode[nIndex].lines > 1 and 2 or 1;
        end
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.list
        @desc Parses one or more comma-separated expressions.
        @param number nDepth Indentation depth.
    !]]
    local function fList(nDepth)
        fExpression(nDepth, 0);
        while (fPeek() == ",") do
            fTake(nDepth);
            fExpression(nDepth, 0);
        end
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.arguments
        @desc Parses parenthesized, table-constructor or string call arguments.
        @param number nDepth Indentation depth.
    !]]
    local function fArguments(nDepth)
        if (fPeek() == "(") then
            fTake(nDepth).join = true;
            if (fPeek() ~= ")") then
                fList(nDepth);
            end
            fTake(nDepth, ")");
        elseif (fPeek() == "{") then
            fTable(nDepth);
        else
            assert(tCode[nIndex] and tCode[nIndex].kind == "string", "Expected function arguments.");
            fTake(nDepth);
        end
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.prefix
        @desc Parses a variable/group followed by indexing and call suffixes.
        @param number nDepth Indentation depth.
        @ret string sKind Final form: variable, call or grouped expression.
    !]]
    fPrefix = function(nDepth)
        local sKind;
        if (fPeek() == "(") then
            fTake(nDepth);
            fExpression(nDepth, 0);
            fTake(nDepth, ")");
            sKind = "group";
        else
            fName(nDepth);
            sKind = "variable";
        end

        while (true) do
            local sNext = fPeek();
            if (sNext == "[") then
                fTake(nDepth).join = true;
                fExpression(nDepth, 0);
                fTake(nDepth, "]");
                sKind = "variable";
            elseif (sNext == ".") then
                fTake(nDepth);
                fName(nDepth);
                sKind = "variable";
            elseif (sNext == ":") then
                fTake(nDepth);
                fName(nDepth);
                fArguments(nDepth);
                sKind = "call";
            elseif (sNext == "(" or sNext == "{" or (tCode[nIndex] and tCode[nIndex].kind == "string")) then
                fArguments(nDepth);
                sKind = "call";
            else
                break;
            end
        end
        return sKind;
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.table
        @desc Places each constructor field on its own line, preserving separators.
        @param number nDepth Constructor indentation depth.
    !]]
    fTable = function(nDepth)
        fTake(nDepth, "{");
        local bEmpty = fPeek() == "}";
        while (fPeek() ~= "}") do
            fLine();
            if (fPeek() == "[") then
                fTake(nDepth + 1);
                fExpression(nDepth + 1, 0);
                fTake(nDepth + 1, "]");
                fTake(nDepth + 1, "=");
                fExpression(nDepth + 1, 0);
            elseif (tCode[nIndex] and tCode[nIndex].kind == "name" and fPeek(1) == "=") then
                fName(nDepth + 1);
                fTake(nDepth + 1, "=");
                fExpression(nDepth + 1, 0);
            else
                fExpression(nDepth + 1, 0);
            end

            if (fPeek() ~= "," and fPeek() ~= ";") then
                break;
            end
            fTake(nDepth + 1);
        end
        if (not bEmpty) then
            fLine();
        end
        fTake(nDepth, "}");
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.body
        @desc Parses function parameters and its nested statement block.
        @param number nDepth Function indentation depth.
    !]]
    fBody = function(nDepth)
        fTake(nDepth, "(").join = true;
        if (fPeek() ~= ")") then
            while (true) do
                if (fPeek() == "...") then
                    fTake(nDepth);
                    break;
                end
                fName(nDepth);
                if (fPeek() ~= ",") then
                    break;
                end
                fTake(nDepth);
            end
        end
        fTake(nDepth, ")");
        fBlock(nDepth + 1);
        fLine();
        fTake(nDepth, "end");
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.expression
        @desc Parses unary, binary and primary expressions by binding power.
        @param number nDepth Indentation depth.
        @param number nLimit Minimum binding power for binary operators.
    !]]
    fExpression = function(nDepth, nLimit)
        local sNext = fPeek();
        local tToken = tCode[nIndex];
        if (_tUnary[sNext]) then
            fTake(nDepth);
            fExpression(nDepth, 11);
        elseif (sNext == "nil" or sNext == "true" or sNext == "false" or sNext == "..." or (tToken and (tToken.kind == "number" or tToken.kind == "string"))) then
            fTake(nDepth);
        elseif (sNext == "function") then
            fTake(nDepth);
            fBody(nDepth);
        elseif (sNext == "{") then
            fTable(nDepth);
        else
            fPrefix(nDepth);
        end

        local tPower = _tOperators[fPeek()];
        while (tPower and tPower[1] > nLimit) do
            fTake(nDepth);
            fExpression(nDepth, tPower[2]);
            tPower = _tOperators[fPeek()];
        end
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.attribute
        @desc Parses a local variable and an optional Lua 5.4 const/close attribute.
        @param number nDepth Indentation depth.
    !]]
    local function fAttribute(nDepth)
        fName(nDepth);
        if (fPeek() == "<") then
            fTake(nDepth);
            assert(fPeek() == "const" or fPeek() == "close", "Expected const or close attribute.");
            fTake(nDepth).join = true;
            fTake(nDepth, ">").join = true;
        end
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.statement
        @desc Parses a Lua statement and marks its nested blocks and boundaries.
        @param number nDepth Statement indentation depth.
        @ret boolean bReturn Whether this is the terminal return statement.
    !]]
    local function fStatement(nDepth)
        local sNext = fPeek();
        if (sNext == ";" or sNext == "break") then
            fTake(nDepth);
        elseif (sNext == "goto") then
            fTake(nDepth);
            fName(nDepth);
        elseif (sNext == "::") then
            fTake(nDepth);
            fName(nDepth);
            fTake(nDepth, "::");
        elseif (sNext == "do" or sNext == "while" or sNext == "for") then
            fTake(nDepth);
            if (sNext == "while") then
                fExpression(nDepth, 0);
                fTake(nDepth, "do");
            elseif (sNext == "for") then
                fName(nDepth);
                if (fPeek() == "=") then
                    fTake(nDepth);
                    fExpression(nDepth, 0);
                    fTake(nDepth, ",");
                    fExpression(nDepth, 0);
                    if (fPeek() == ",") then
                        fTake(nDepth);
                        fExpression(nDepth, 0);
                    end
                else
                    while (fPeek() == ",") do
                        fTake(nDepth);
                        fName(nDepth);
                    end
                    fTake(nDepth, "in");
                    fList(nDepth);
                end
                fTake(nDepth, "do");
            end
            fBlock(nDepth + 1);
            fLine();
            fTake(nDepth, "end");
        elseif (sNext == "repeat") then
            fTake(nDepth);
            fBlock(nDepth + 1);
            fLine();
            fTake(nDepth, "until");
            fExpression(nDepth, 0);
        elseif (sNext == "if") then
            fTake(nDepth);
            fExpression(nDepth, 0);
            fTake(nDepth, "then");
            fBlock(nDepth + 1);
            while (fPeek() == "elseif") do
                fLine();
                fTake(nDepth);
                fExpression(nDepth, 0);
                fTake(nDepth, "then");
                fBlock(nDepth + 1);
            end
            if (fPeek() == "else") then
                fLine();
                fTake(nDepth);
                fBlock(nDepth + 1);
            end
            fLine();
            fTake(nDepth, "end");
        elseif (sNext == "function") then
            fTake(nDepth);
            fName(nDepth);
            while (fPeek() == ".") do
                fTake(nDepth);
                fName(nDepth);
            end
            if (fPeek() == ":") then
                fTake(nDepth);
                fName(nDepth);
            end
            fBody(nDepth);
        elseif (sNext == "local") then
            fTake(nDepth);
            if (fPeek() == "function") then
                fTake(nDepth);
                fName(nDepth);
                fBody(nDepth);
            else
                fAttribute(nDepth);
                while (fPeek() == ",") do
                    fTake(nDepth);
                    fAttribute(nDepth);
                end
                if (fPeek() == "=") then
                    fTake(nDepth);
                    fList(nDepth);
                end
            end
        elseif (sNext == "return") then
            fTake(nDepth);
            if (fPeek() ~= "" and fPeek() ~= ";" and not _tStops[fPeek()]) then
                fList(nDepth);
            end
            if (fPeek() == ";") then
                fTake(nDepth);
            end
            return true;
        else
            local sKind = fPrefix(nDepth);
            if (sKind ~= "call" or fPeek() == "=" or fPeek() == ",") then
                assert(sKind == "variable", "Expected an assignable variable.");
                while (fPeek() == ",") do
                    fTake(nDepth);
                    assert(fPrefix(nDepth) == "variable", "Expected an assignable variable.");
                end
                fTake(nDepth, "=");
                fList(nDepth);
            end
        end

        -- A statement's optional semicolon stays attached to that statement.
        if (fPeek() == ";") then
            fTake(nDepth);
        end
        return false;
    end

    --[[!
        @fqxn LuaEx.Utilities.prettyLua.Internal.parse.block
        @desc Parses statements until a closing keyword, enforcing terminal return.
        @param number nDepth Block indentation depth.
    !]]
    fBlock = function(nDepth)
        while (fPeek() ~= "" and not _tStops[fPeek()]) do
            fLine();
            if (fStatement(nDepth)) then
                break;
            end
        end
    end

    if (bExpression) then
        fExpression(0, 0);
    else
        fBlock(0);
    end
    assert(nIndex > #tCode, "Unexpected token '"..fPeek().."' after "..(bExpression and "expression" or "chunk")..".");
end

--[[!
    @fqxn LuaEx.Utilities.prettyLua.Internal.render
    @desc Emits marked tokens with stable spacing. Comments remain in token order;
    line comments always terminate their line. Literal contents are never indented.
    @param table tTokens Parsed tokens including comments.
    @ret string sFormatted Formatted source.
!]]
local function render(tTokens)
    local tParts = {};
    local tPrevious;
    local nDepth = 0;
    local bCommentLine = false;

    -- Resolve comment indentation once, including long runs of comment-only lines.
    for nIndex = #tTokens, 1, -1 do
        local tToken = tTokens[nIndex];
        nDepth = tToken.depth or nDepth;
        tToken.commentDepth = nDepth;
    end

    for nIndex, tToken in ipairs(tTokens) do
        local sText = tToken.text;
        local bComment = tToken.kind == "lineComment" or tToken.kind == "longComment";
        local nBreaks = tToken.breaks or 0;
        if (bComment) then
            if (tToken.lines > 0) then
                nBreaks = tToken.lines > 1 and 2 or 1;
            end
            -- Leading comments belong to the following structural indentation.
            nDepth = tToken.commentDepth;
        else
            nDepth = tToken.depth;
        end
        if (bCommentLine) then
            nBreaks = math.max(nBreaks, 1);
        end

        if (tPrevious) then
            if (nBreaks > 0) then
                tParts[#tParts + 1] = string.rep("\n", nBreaks)..string.rep("    ", nDepth);
            else
                local sPrevious = tPrevious.text;
                local bTight = tToken.join or sText == "," or sText == ";" or sText == ")" or sText == "]" or sText == "." or sText == ":" or sText == "::" or
                    sPrevious == "(" or sPrevious == "[" or sPrevious == "." or sPrevious == ":" or sPrevious == "::" or (sPrevious == "{" and sText == "}");
                if (bComment or tPrevious.kind == "longComment") then
                    bTight = false;
                end
                if (sPrevious == "[" and sText:sub(1, 1) == "[") then
                    bTight = false;
                end
                if (not bTight) then
                    tParts[#tParts + 1] = " ";
                end
            end
        end
        tParts[#tParts + 1] = sText;
        tPrevious = tToken;
        bCommentLine = tToken.kind == "lineComment";
    end

    return table.concat(tParts);
end

--[[!
    @fqxn LuaEx.Utilities.prettyLua.Internal.format
    @desc Tries chunk syntax first, then standalone expression syntax. Retokenizes
    the result to reject any accidental token merging before returning output.
    @param string sSource Lua source text.
    @ret string sFormatted Formatted source with the exact original token stream.
    @throws Lexical, syntax or token-preservation errors.
!]]
local function format(sSource)
    local tTokens, tCode = lex(sSource);
    local bChunk, sChunkReason = pcall(parse, tCode, false);
    if (not bChunk) then
        for _, tToken in ipairs(tCode) do
            tToken.depth, tToken.breaks, tToken.join = nil, nil, nil;
        end
        local bExpression, sExpressionReason = pcall(parse, tCode, true);
        assert(bExpression, "Invalid Lua source. Chunk: "..tostring(sChunkReason).." Expression: "..tostring(sExpressionReason));
    end

    local sFormatted = render(tTokens);
    local tCheck = lex(sFormatted);
    assert(#tCheck == #tTokens, "Formatting would change the Lua token stream.");
    for nIndex, tToken in ipairs(tTokens) do
        assert(tCheck[nIndex].text == tToken.text and tCheck[nIndex].kind == tToken.kind, "Formatting would change a Lua token.");
    end
    return sFormatted;
end

--[[!
    @fqxn LuaEx.Utilities.prettyLua.Call
    @desc Returns formatted Lua source, or nil and a reason. Does not throw for
    invalid input and never loads, executes or evaluates the supplied source.
    @param string sSource Lua chunk or expression.
    @ret string|nil sFormatted Formatted source.
    @ret string|nil sReason Failure diagnostic.
!]]
local function prettyLua(sSource)
    local sType = (rawtype or type)(sSource);
    if (sType ~= "string") then
        return nil, "Expected Lua source as a string.";
    end

    local bSuccess, sResult = pcall(format, sSource);
    if (not bSuccess) then
        return nil, tostring(sResult);
    end
    return sResult;
end

return prettyLua;
