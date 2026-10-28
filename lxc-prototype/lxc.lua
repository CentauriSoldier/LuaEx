--[[!
@fqxn Experiments.LXC
@desc Standalone, deliberately limited .lxc compiler/runtime experiment. Does not
    initialize or modify LuaEx. Declarations resemble C#; method bodies are Lua.
!]]
local LXC = {};

--[[!
@fqxn Experiments.LXC.tokenize
@desc Scans declaration tokens while preserving source positions. Lua strings,
    long strings and comments are opaque, so their braces cannot end a method.
!]]
local function tokenize(sSource, pFile)
    local tTokens, nPos, nLength = {}, 1, #sSource;

    local function fFail(sMessage)
        local nLine = select(2, sSource:sub(1, nPos):gsub("\n", "")) + 1;
        error(pFile..":"..nLine..": "..sMessage, 0);
    end

    local function fLong(nStart)
        local sEquals = sSource:sub(nStart):match("^%[(=*)%[");
        if (not sEquals) then return nil; end
        local nEnd = sSource:find("]"..sEquals.."]", nStart + #sEquals + 2, true);
        if (not nEnd) then fFail("Unterminated long string/comment."); end
        return nEnd + #sEquals + 2;
    end

    while (nPos <= nLength) do
        local nStart, sChar = nPos, sSource:sub(nPos, nPos);

        if (sChar:match("%s")) then
            nPos = nPos + 1;
        elseif (sSource:sub(nPos, nPos + 1) == "--") then
            nPos = fLong(nPos + 2) or sSource:find("\n", nPos + 2, true) or (nLength + 1);
        elseif (sChar == "'" or sChar == '"') then
            nPos = nPos + 1;
            while (nPos <= nLength and sSource:sub(nPos, nPos) ~= sChar) do
                nPos = nPos + (sSource:sub(nPos, nPos) == "\\" and 2 or 1);
            end
            if (nPos > nLength) then fFail("Unterminated quoted string."); end
            nPos = nPos + 1;
            tTokens[#tTokens + 1] = {Text = sSource:sub(nStart, nPos - 1), Start = nStart, Stop = nPos - 1};
        else
            local nLongEnd = sChar == "[" and fLong(nPos);
            local sWord = sSource:sub(nPos):match("^[%a_][%w_]*");
            nPos = nLongEnd or (sWord and nPos + #sWord) or (nPos + 1);
            tTokens[#tTokens + 1] = {Text = sSource:sub(nStart, nPos - 1), Start = nStart, Stop = nPos - 1};
        end
    end

    tTokens[#tTokens + 1] = {Text = "<eof>", Start = nLength + 1, Stop = nLength + 1};
    return tTokens;
end

--[[!
@fqxn Experiments.LXC.parse
@desc Parses one namespace containing classes. Fields require initializers;
    visibility defaults to public. Unsupported declarations fail explicitly.
!]]
local function parse(sSource, pFile)
    local tTokens, nIndex, tClasses = tokenize(sSource, pFile), 1, {};

    local function fFail(sMessage)
        local nLine = select(2, sSource:sub(1, tTokens[nIndex].Start - 1):gsub("\n", "")) + 1;
        error(pFile..":"..nLine..": "..sMessage, 0);
    end

    local function fTake(sExpected)
        local tToken = tTokens[nIndex];
        if (sExpected and tToken.Text ~= sExpected) then fFail("Expected '"..sExpected.."', got '"..tToken.Text.."'."); end
        nIndex = nIndex + 1;
        return tToken.Text;
    end

    local function fName()
        local sName = tTokens[nIndex].Text;
        if (not sName:match("^[%a_][%w_]*$")) then fFail("Expected an identifier."); end
        return fTake();
    end

    local function fQualified()
        local sName = fName();
        while (tTokens[nIndex].Text == ".") do fTake("."); sName = sName.."."..fName(); end
        return sName;
    end

    fTake("namespace");
    local sNamespace = fQualified();
    fTake("{");

    while (tTokens[nIndex].Text ~= "}") do
        if (tTokens[nIndex].Text == "public") then fTake(); end
        fTake("class");
        local sName = fName();
        local tClass = {Name = sName, Namespace = sNamespace, FullName = sNamespace.."."..sName,
            Members = {}, File = pFile};
        if (tTokens[nIndex].Text == ":") then fTake(); tClass.ParentName = fQualified(); end
        fTake("{");

        while (tTokens[nIndex].Text ~= "}") do
            local sVisibility, bFinal = "public", false;
            local sToken = tTokens[nIndex].Text;
            if (sToken == "public" or sToken == "private" or sToken == "protected") then sVisibility = fTake(); end
            if (tTokens[nIndex].Text == "final") then fTake(); bFinal = true; end
            local sMember = fName();
            if (tClass.Members[sMember]) then fFail("Duplicate member: "..sMember); end
            local tMember = {Name = sMember, Visibility = sVisibility, Final = bFinal};

            if (tTokens[nIndex].Text == "(") then
                fTake("(");
                local tParameters = {};
                while (tTokens[nIndex].Text ~= ")") do
                    local sParameter = fName();
                    if (sParameter == "this" or sParameter == "base") then fFail("Reserved parameter: "..sParameter); end
                    tParameters[#tParameters + 1] = sParameter;
                    if (tTokens[nIndex].Text ~= ",") then break; end
                    fTake(",");
                end
                fTake(")"); fTake("{");
                local nStart, nDepth = tTokens[nIndex - 1].Stop + 1, 1;
                while (nDepth > 0) do
                    local sBodyToken = tTokens[nIndex].Text;
                    if (sBodyToken == "<eof>") then fFail("Unterminated method body."); end
                    if (sBodyToken == "{") then nDepth = nDepth + 1; end
                    if (sBodyToken == "}") then nDepth = nDepth - 1; end
                    if (nDepth > 0) then nIndex = nIndex + 1; end
                end
                tMember.Body = sSource:sub(nStart, tTokens[nIndex].Start - 1);
                tMember.Line = select(2, sSource:sub(1, nStart - 1):gsub("\n", "")) + 1;
                tMember.Parameters = tParameters;
                fTake("}");
            else
                if (bFinal) then fFail("This prototype supports final methods only."); end
                fTake("=");
                local nStart, nDepth = tTokens[nIndex].Start, 0;
                while (tTokens[nIndex].Text ~= ";" or nDepth > 0) do
                    local sFieldToken = tTokens[nIndex].Text;
                    if (sFieldToken == "<eof>") then fFail("Unterminated field initializer."); end
                    if (sFieldToken == "{" or sFieldToken == "(" or sFieldToken == "[") then nDepth = nDepth + 1; end
                    if (sFieldToken == "}" or sFieldToken == ")" or sFieldToken == "]") then
                        nDepth = nDepth - 1;
                        if (nDepth < 0) then fFail("Missing field initializer semicolon."); end
                    end
                    nIndex = nIndex + 1;
                end
                tMember.Initializer = sSource:sub(nStart, tTokens[nIndex].Start - 1);
                if (not tMember.Initializer:match("%S")) then fFail("Expected a field initializer."); end
                fTake(";");
            end

            if (sMember == sName) then
                if (tClass.Constructor) then fFail("Duplicate constructor: "..sName); end
                if (not tMember.Body or sVisibility ~= "public" or bFinal) then fFail("Constructors must be public methods without final."); end
                tClass.Constructor = tMember;
            else
                tClass.Members[sMember] = tMember;
            end
        end

        fTake("}");
        tClasses[#tClasses + 1] = tClass;
    end

    fTake("}"); fTake("<eof>");
    return tClasses;
end

--[[!
@fqxn Experiments.LXC.descends
@desc Tests inheritance using internal class definitions, never instance fields.
!]]
local function descends(tClass, tAncestor)
    while (tClass) do
        if (tClass == tAncestor) then return true; end
        tClass = tClass.Parent;
    end
    return false;
end

--[[!
@fqxn Experiments.LXC.findMember
@desc Gives a declaring class its own private member, then searches the dynamic
    hierarchy. Access enforcement remains separate from member resolution.
!]]
local function findMember(tClass, tCaller, sName)
    local tOwn = tCaller and tCaller.Members[sName];
    if (tOwn and tOwn.Visibility == "private") then return tOwn; end
    while (tClass) do
        if (tClass.Members[sName]) then return tClass.Members[sName]; end
        tClass = tClass.Parent;
    end
end

--[[!
@fqxn Experiments.LXC.instantiate
@desc Builds per-instance field storage and access-controlled views. Methods use
    dot calls, matching existing LuaEx usage. Private/protected access is lexical
    to the method's declaring class, not the most-derived instance class.
!]]
local function instantiate(tClass, ...)
    local tValues, tViews = {}, {};
    local fView, fInvoke;

    local function fCheck(tMember, tCaller)
        local sVisibility = tMember.Visibility;
        assert(sVisibility == "public" or (sVisibility == "private" and tCaller == tMember.Owner)
            or (sVisibility == "protected" and tCaller and descends(tCaller, tMember.Owner)),
            "Cannot access "..sVisibility.." member "..tMember.Owner.FullName.."."..tMember.Name);
    end

    fInvoke = function(tMember, ...)
        local tOwner = tMember.Owner;
        local function fBase(...)
            assert(tOwner.Parent, "No parent constructor exists.");
            assert(tOwner.Parent.Constructor, "Parent has no explicit constructor.");
            return fInvoke(tOwner.Parent.Constructor, ...);
        end
        local tResults = table.pack(tMember.Function(fView(tOwner), fBase, ...));
        -- Returning this directly must not expose the declaring-class access view.
        for nIndex = 1, tResults.n do
            for _, tView in pairs(tViews) do
                if (tResults[nIndex] == tView) then tResults[nIndex] = fView(nil); break; end
            end
        end
        return table.unpack(tResults, 1, tResults.n);
    end;

    fView = function(tCaller)
        local vKey = tCaller or false;
        if (tViews[vKey]) then return tViews[vKey]; end
        local tView = setmetatable({}, {
            __index = function(_, sName)
                local tMember = findMember(tClass, tCaller, sName);
                assert(tMember, "Unknown member: "..tostring(sName));
                fCheck(tMember, tCaller);
                if (tMember.Function) then return function(...) return fInvoke(tMember, ...); end; end
                return tValues[tMember];
            end,
            __newindex = function(_, sName, vValue)
                local tMember = findMember(tClass, tCaller, sName);
                assert(tMember, "Unknown member: "..tostring(sName));
                fCheck(tMember, tCaller);
                assert(not tMember.Function, "Cannot replace a method.");
                tValues[tMember] = vValue;
            end,
            __metatable = "LXC instance",
        });
        tViews[vKey] = tView;
        return tView;
    end;

    local function fInitialize(tCurrent)
        if (tCurrent.Parent) then fInitialize(tCurrent.Parent); end
        for _, tMember in ipairs(tCurrent.Fields) do tValues[tMember] = tMember.FunctionInitializer(); end
    end

    fInitialize(tClass);
    if (tClass.Constructor) then fInvoke(tClass.Constructor, ...); end
    return fView(nil);
end

--[[!
@fqxn Experiments.LXC.loadFiles
@desc Reads explicit .lxc paths, resolves same-namespace or fully qualified parents,
    rejects cycles/duplicates, compiles Lua bodies, and publishes namespace tables.
    Returns deterministic load order. Compilation never executes method bodies.
    Input files are trusted application code, not sandboxed scripts.
!]]
function LXC.loadFiles(tPaths, tEnvironment)
    assert(type(tEnvironment) == "table", "Supply the public environment table.");
    local tDefinitions, tNames, tOrder, tVisiting, tDone = {}, {}, {}, {}, {};

    for _, pFile in ipairs(tPaths) do
        local hFile = assert(io.open(pFile, "rb"));
        local sSource = hFile:read("*a"); hFile:close();
        for _, tClass in ipairs(parse(sSource, pFile)) do
            assert(not tDefinitions[tClass.FullName], "Duplicate class: "..tClass.FullName);
            tDefinitions[tClass.FullName] = tClass;
            tNames[#tNames + 1] = tClass.FullName;
        end
    end
    table.sort(tNames);

    local function fVisit(sName)
        if (tDone[sName]) then return; end
        assert(not tVisiting[sName], "Inheritance cycle at "..sName);
        local tClass = tDefinitions[sName];
        assert(tClass, "Missing class: "..sName);
        tVisiting[sName] = true;
        if (tClass.ParentName) then
            local sParent = tClass.ParentName:find(".", 1, true) and tClass.ParentName
                or tClass.Namespace.."."..tClass.ParentName;
            assert(tDefinitions[sParent], "Missing parent "..sParent.." for "..sName);
            fVisit(sParent);
            tClass.Parent = tDefinitions[sParent];
        end
        tVisiting[sName], tDone[sName] = nil, true;
        tOrder[#tOrder + 1] = sName;
    end

    for _, sName in ipairs(tNames) do fVisit(sName); end

    -- Validate namespace structure in a staging tree before modifying the caller.
    local tStaged = {Children = {}};
    for _, sName in ipairs(tOrder) do
        local tClass, tNode = tDefinitions[sName], tStaged;
        for sPart in tClass.Namespace:gmatch("[^.]+") do
            assert(not tNode.Children[sPart] or not tNode.Children[sPart].Definition, "Namespace/class collision: "..sName);
            tNode.Children[sPart] = tNode.Children[sPart] or {Children = {}};
            tNode = tNode.Children[sPart];
        end
        assert(not tNode.Children[tClass.Name], "Namespace/class collision: "..sName);
        tNode.Children[tClass.Name] = {Definition = tClass};
    end

    local function fCheckTree(tSource, tTarget)
        for sKey, tValue in pairs(tSource.Children) do
            local vExisting = rawget(tTarget, sKey);
            if (tValue.Definition) then
                assert(vExisting == nil, "Public class binding already exists: "..sKey);
            else
                assert(vExisting == nil or (type(vExisting) == "table" and getmetatable(vExisting) == nil),
                    "Namespace must be a plain table: "..sKey);
                fCheckTree(tValue, vExisting or {});
            end
        end
    end
    fCheckTree(tStaged, tEnvironment);

    for _, sName in ipairs(tOrder) do
        local tClass = tDefinitions[sName];
        -- Names in this namespace are resolved at invocation, after publication.
        local tScope = setmetatable({}, {__index = function(_, sKey)
            local tNamespace = tEnvironment;
            for sPart in tClass.Namespace:gmatch("[^.]+") do
                tNamespace = type(tNamespace) == "table" and rawget(tNamespace, sPart) or nil;
            end
            local vValue = tNamespace and rawget(tNamespace, sKey);
            if (vValue ~= nil) then return vValue; end
            return tEnvironment[sKey];
        end, __newindex = tEnvironment});
        tClass.Fields = {};
        local tMemberNames = {};
        for sMember in pairs(tClass.Members) do tMemberNames[#tMemberNames + 1] = sMember; end
        table.sort(tMemberNames);
        for _, sMember in ipairs(tMemberNames) do
            local tMember = tClass.Members[sMember];
            tMember.Owner = tClass;
            local tInherited = tClass.Parent and findMember(tClass.Parent, nil, sMember);
            assert(not tInherited or not tInherited.Final, "Cannot override final member: "..sName.."."..sMember);
            assert(not tInherited or tInherited.Visibility == "private"
                or (tInherited.Visibility == tMember.Visibility and not not tInherited.Body == not not tMember.Body),
                "Overrides must preserve member kind and visibility: "..sName.."."..sMember);
            if (not tMember.Body) then
                tMember.FunctionInitializer = assert(load("return "..tMember.Initializer, "@"..tClass.File, "t", tScope));
                tClass.Fields[#tClass.Fields + 1] = tMember;
            end
        end

        local tMethods = {};
        for _, tMember in pairs(tClass.Members) do if (tMember.Body) then tMethods[#tMethods + 1] = tMember; end; end
        if (tClass.Constructor) then tClass.Constructor.Owner = tClass; tMethods[#tMethods + 1] = tClass.Constructor; end
        for _, tMember in ipairs(tMethods) do
            local sParameters = #tMember.Parameters > 0 and ", "..table.concat(tMember.Parameters, ", ") or "";
            local sCode = "return function(this, base"..sParameters..") "..string.rep("\n", tMember.Line - 1)..tMember.Body.."\nend";
            tMember.Function = assert(load(sCode, "@"..tClass.File, "t", tScope))();
        end
        tClass.Public = setmetatable({}, {__call = function(_, ...) return instantiate(tClass, ...); end,
            __newindex = function() error("Class bindings are immutable.", 2); end, __metatable = "LXC class"});
    end

    local function fPublish(tSource, tTarget)
        for sKey, tValue in pairs(tSource.Children) do
            if (tValue.Definition) then
                rawset(tTarget, sKey, tValue.Definition.Public);
            else
                local tNext = rawget(tTarget, sKey) or {};
                rawset(tTarget, sKey, tNext);
                fPublish(tValue, tNext);
            end
        end
    end
    fPublish(tStaged, tEnvironment);
    return tOrder;
end

--[[!
@fqxn Experiments.LXC.discover
@desc Uses LuaEx's existing io.listfiles API to scan package.path directory roots
    recursively for .lxc files. Literal prefixes before ? become search roots;
    overlapping roots are deduplicated by normalized path. No framework is loaded.
!]]
function LXC.discover(sPackagePath)
    assert(type(io.listfiles) == "function", "Initialize LuaEx before using discovery; loadFiles works independently.");
    local tRoots, tSeen, tFiles = {}, {}, {};
    for sTemplate in (sPackagePath or package.path):gmatch("[^;]+") do
        local sPrefix = sTemplate:match("^(.-)%?");
        if (sPrefix) then
            local pRoot = sPrefix:match("^(.*)[/\\]") or ".";
            if (pRoot == "") then pRoot = sPrefix:sub(1, 1); end
            if (not tRoots[pRoot]) then
                tRoots[pRoot] = true;
                local tFound, sReason = io.listfiles(pRoot, true, nil, "lxc");
                assert(tFound, sReason);
                for _, pFile in ipairs(tFound) do
                    local pKey = pFile:gsub("\\", "/"):gsub("/%./", "/");
                    if (package.config:sub(1, 1) == "\\") then pKey = pKey:lower(); end
                    if (not tSeen[pKey]) then tSeen[pKey] = true; tFiles[#tFiles + 1] = pFile; end
                end
            end
        end
    end
    table.sort(tFiles);
    return tFiles;
end

return LXC;
