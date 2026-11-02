--[[!
@fqxn LuaEx.LXE.Parser
@desc Parses enum and extension declarations without executing Lua. The read entry
    accepts an existing token stream so LXC can delegate inline declarations without
    rescanning the file. Expression and body text retain original source locations.
!]]
local Tokens = require("LuaEx.lib.lxe.Tokens");
local Parser = {};
local _tReserved = {};
for sWord in ("and break do else elseif end false for function goto if in local nil not or repeat return then true until while namespace class enum extension within using requires public private protected final const this base abstract override static permits excludes null operator"):gmatch("%S+") do
    _tReserved[sWord] = true;
end

--[[!
@fqxn LuaEx.LXE.Parser.read
@desc Reads one declaration from a shared token cursor and returns its next index.
@param table tInput Source, File, Tokens, Index, Namespace, Imports, Outer, Flags.
@ret table Declaration record, followed by the first unconsumed token index.
!]]
function Parser.read(tInput)
    local tTokens, nIndex = tInput.Tokens, tInput.Index;
    local sSource, pFile = tInput.Source, tInput.File;
    local function fFail(sMessage)
        error(pFile..":"..tTokens[nIndex].Line..": "..sMessage, 0);
    end
    local function fPeek() return tTokens[nIndex].Text; end
    local function fTake(sExpected)
        local sText = fPeek();
        if (sExpected and sText ~= sExpected) then fFail("Expected "..sExpected..", got "..sText); end
        nIndex = nIndex + 1;
        return sText;
    end
    local function fName()
        local sName = fPeek();
        if (not sName:match("^[%a_][%w_]*$") or _tReserved[sName] or
            sName == "_ENV" or sName:match("^__lx[ce]")) then fFail("Invalid identifier: "..sName); end
        return fTake();
    end
    local function fQualified()
        local sName = fName();
        while (fPeek() == ".") do fTake(); sName = sName.."."..fName(); end
        return sName;
    end
    local function fBody()
        local nStart = tTokens[nIndex].Stop + 1;
        fTake("{");
        local nDepth = 1;
        while (nDepth > 0) do
            if (fPeek() == "<eof>") then fFail("Unterminated body."); end
            if (fPeek() == "{") then nDepth = nDepth + 1; end
            if (fPeek() == "}") then nDepth = nDepth - 1; end
            if (nDepth > 0) then nIndex = nIndex + 1; end
        end
        local sBody = sSource:sub(nStart, tTokens[nIndex].Start - 1);
        fTake("}");
        return sBody;
    end
    -- Brackets and Lua blocks protect semicolons in tables/functions. A second
    -- outer brace after a complete expression begins an embedded member block.
    local function fExpression()
        fTake("=");
        local nStart, nFirst, nDepth = tTokens[nIndex].Start, nIndex, 0;
        local tBlocks = {};
        while (true) do
            local sToken = fPeek();
            if (nDepth == 0 and #tBlocks == 0 and
                (sToken == ";" or (sToken == "{" and nIndex > nFirst))) then break; end
            if (sToken == "<eof>") then fFail("Unterminated value expression."); end
            if (sToken == "(" or sToken == "[" or sToken == "{") then nDepth = nDepth + 1; end
            if (sToken == ")" or sToken == "]" or sToken == "}") then nDepth = nDepth - 1; end
            if (nDepth < 0) then fFail("Expected a semicolon after the value expression."); end
            if (sToken == "function" or sToken == "if" or sToken == "repeat" or sToken == "for" or sToken == "while") then
                tBlocks[#tBlocks + 1] = {AwaitDo = sToken == "for" or sToken == "while"};
            elseif (sToken == "do") then
                local tBlock = tBlocks[#tBlocks];
                if (tBlock and tBlock.AwaitDo) then tBlock.AwaitDo = false;
                else tBlocks[#tBlocks + 1] = {}; end
            elseif (sToken == "end" or sToken == "until") then
                if (#tBlocks == 0) then fFail("Unexpected Lua block end."); end
                tBlocks[#tBlocks] = nil;
            end
            nIndex = nIndex + 1;
        end
        if (nFirst == nIndex) then fFail("Expected a value expression."); end
        return sSource:sub(nStart, tTokens[nIndex].Start - 1);
    end
    local function fMembers()
        fTake("{");
        local tMembers = {};
        while (fPeek() ~= "}") do
            if (fPeek() == "<eof>") then fFail("Unterminated enum."); end
            local tMember = {Line = tTokens[nIndex].Line, File = pFile, Name = fName()};
            if (fPeek() == "=") then tMember.Expression = fExpression(); end
            if (fPeek() == "{") then
                tMember.Members = fMembers();
                if (fPeek() == ";") then fTake(); end
            else fTake(";"); end
            tMembers[#tMembers + 1] = tMember;
        end
        fTake("}");
        return tMembers;
    end
    local tRecord = {File = pFile, Line = tTokens[nIndex].Line, Namespace = tInput.Namespace,
        Imports = {}, Outer = tInput.Outer, Flags = tInput.Flags or {}};
    for n, sImport in ipairs(tInput.Imports or {}) do tRecord.Imports[n] = sImport; end
    if (fPeek() == "extension") then
        fTake();
        tRecord.Kind, tRecord.Target = "extension", fQualified();
        tRecord.Target, tRecord.Name = tRecord.Target:match("^(.*)%.([^.]+)$");
        if (not tRecord.Target) then fFail("Extension requires EnumName.methodName."); end
        fTake("("); fTake("this");
        tRecord.Parameters = {"this"};
        local tSeen = {this = true};
        while (fPeek() == ",") do
            fTake();
            if (fPeek() == "...") then fTake(); tRecord.Parameters[#tRecord.Parameters + 1] = "..."; break; end
            local sName = fName();
            if (tSeen[sName]) then fFail("Duplicate parameter: "..sName); end
            tSeen[sName], tRecord.Parameters[#tRecord.Parameters + 1] = true, sName;
        end
        fTake(")"); tRecord.Body = fBody();
    else
        fTake("enum");
        tRecord.Kind, tRecord.Name = "enum", fName();
        if (fPeek() == "within") then fTake(); tRecord.Within = fQualified(); end
        if (tRecord.Outer and tRecord.Within ~= tRecord.Outer.FullName) then
            fFail("Inline enum within must match its enclosing class.");
        end
        if (fPeek() == "requires") then
            fTake(); fTake("("); tRecord.Requires = {};
            repeat
                tRecord.Requires[#tRecord.Requires + 1] = fQualified();
                if (fPeek() ~= ",") then break; end
                fTake();
            until false;
            fTake(")");
        end
        tRecord.Members = fMembers();
        tRecord.FullName = (tRecord.Within or tRecord.Namespace).."."..tRecord.Name;
    end
    return tRecord, nIndex;
end

--[[!
@fqxn LuaEx.LXE.Parser.parse
@desc Parses standalone LXE files. File/namespace extensions may precede their enum.
@param string sSource Source text.
@param string pFile Diagnostic filename.
@ret table Ordered declarations.
!]]
function Parser.parse(sSource, pFile)
    local tTokens, nIndex, tRecords, tImports = Tokens.scan(sSource, pFile), 1, {}, {};
    local function fFail(sMessage)
        error(pFile..":"..tTokens[nIndex].Line..": "..sMessage, 0);
    end
    local function fTake(sExpected)
        local sText = tTokens[nIndex].Text;
        if (sExpected and sText ~= sExpected) then fFail("Expected "..sExpected); end
        nIndex = nIndex + 1;
        return sText;
    end
    local function fPath()
        local tParts = {};
        repeat
            local sPart = fTake();
            if (not sPart:match("^[%a_][%w_]*$") or _tReserved[sPart]) then fFail("Invalid name."); end
            tParts[#tParts + 1] = sPart;
            if (tTokens[nIndex].Text ~= ".") then break; end
            fTake();
        until false;
        return table.concat(tParts, ".");
    end
    local function fDeclaration(sNamespace)
        local tFlags = {};
        local sText = tTokens[nIndex].Text;
        if (sText == "public" or sText == "private" or sText == "protected") then
            tFlags.Visibility = fTake();
        end
        local tRecord;
        tRecord, nIndex = Parser.read({Source = sSource, File = pFile, Tokens = tTokens,
            Index = nIndex, Namespace = sNamespace, Imports = tImports, Flags = tFlags});
        tRecords[#tRecords + 1] = tRecord;
    end
    while (tTokens[nIndex].Text ~= "<eof>") do
        local sText = tTokens[nIndex].Text;
        if (sText == "using") then
            fTake(); tImports[#tImports + 1] = fPath(); fTake(";");
        elseif (sText == "extension") then fDeclaration("");
        else
            fTake("namespace"); local sNamespace = fPath(); fTake("{");
            local tOuterImports = tImports;
            tImports = {}; for n, sImport in ipairs(tOuterImports) do tImports[n] = sImport; end
            local bDeclared = false;
            while (tTokens[nIndex].Text ~= "}") do
                if (tTokens[nIndex].Text == "using") then
                    if (bDeclared) then fFail("using must precede declarations."); end
                    fTake(); tImports[#tImports + 1] = fPath(); fTake(";");
                else bDeclared = true; fDeclaration(sNamespace); end
            end
            fTake("}"); tImports = tOuterImports;
        end
    end
    return tRecords;
end

return Parser;


