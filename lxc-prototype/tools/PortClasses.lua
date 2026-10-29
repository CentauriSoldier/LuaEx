--[[!
@fqxn LXC.Tools.PortClasses
@desc One-time source migration aid. Reads legacy declarations and emits native
    LXC source for review; it never loads the legacy class factory or executes
    class bodies. The deployed runtime has no dependency on this development tool.
!]]
local Tokens = assert(loadfile('LuaEx/lxc/modules/Tokens.lua'))();
local LuaScope = assert(loadfile('LuaEx/lxc/modules/LuaScope.lua'))()(Tokens);
local _tPaths = {
    'Queue', 'Stack', 'Set', 'Tree', 'SortedDictionary', 'ClassRegistry', 'XML',
    'Grid', 'EventSystem', 'component/Potentiometer', 'component/Protean',
    'util/Ini', 'util/BaseLog', 'util/VFS',
};

--[[!
@fqxn LXC.Tools.PortClasses.read
@desc Reads a source file without executing its contents.
!]]
local function read(pPath)
    local hFile = assert(io.open(pPath, 'rb'));
    local sSource = hFile:read('*a');
    hFile:close();
    return (sSource:gsub('\r\n', '\n'));
end

--[[!
@fqxn LXC.Tools.PortClasses.split
@desc Splits top-level comma/semicolon expressions, respecting Lua blocks,
    nested delimiters, comments and strings. Used for arguments and table fields.
!]]
local function split(sSource)
    local tTokens = Tokens.scan(sSource, 'migration expression');
    local tParts, tBlocks, nDepth, nStart = {}, {}, 0, 1;
    for _, tToken in ipairs(tTokens) do
        local s = tToken.Text;
        if (s == '<eof>' or ((s == ',' or s == ';') and nDepth == 0 and #tBlocks == 0)) then
            local sPart = sSource:sub(nStart, tToken.Start - 1);
            if (sPart:match('%S')) then tParts[#tParts + 1] = sPart; end
            nStart = tToken.Stop + 1;
        else
            if (s == '(' or s == '{' or s == '[') then nDepth = nDepth + 1; end
            if (s == ')' or s == '}' or s == ']') then nDepth = nDepth - 1; end
            if (s == 'function' or s == 'if' or s == 'repeat' or s == 'for' or s == 'while') then
                tBlocks[#tBlocks + 1] = {AwaitDo = s == 'for' or s == 'while'};
            elseif (s == 'do') then
                local tBlock = tBlocks[#tBlocks];
                if (tBlock and tBlock.AwaitDo) then tBlock.AwaitDo = false;
                else tBlocks[#tBlocks + 1] = {}; end
            elseif (s == 'end' or s == 'until') then tBlocks[#tBlocks] = nil; end
        end
    end
    return tParts;
end

--[[!
@fqxn LXC.Tools.PortClasses.functionInfo
@desc Extracts an anonymous function's parameters and body without execution.
!]]
local function functionInfo(sExpression)
    local tTokens = Tokens.scan(sExpression, 'migration function');
    if (tTokens[1].Text ~= 'function' or tTokens[2].Text ~= '(' or tTokens[#tTokens - 1].Text ~= 'end') then return; end
    local nClose = 3;
    while (tTokens[nClose].Text ~= ')') do nClose = nClose + 1; end
    local tParameters = {};
    for n = 3, nClose - 1 do
        if (tTokens[n].Text ~= ',') then tParameters[#tParameters + 1] = tTokens[n].Text; end
    end
    return {Parameters = tParameters,
        Body = sExpression:sub(tTokens[nClose].Stop + 1, tTokens[#tTokens - 1].Start - 1)};
end

--[[!
@fqxn LXC.Tools.PortClasses.fields
@desc Reads ordered identifier-keyed entries from a legacy visibility table.
!]]
local function fields(sTable)
    local tTokens = Tokens.scan(sTable, 'migration table');
    assert(tTokens[1].Text == '{' and tTokens[#tTokens - 1].Text == '}', 'Expected visibility table.');
    local tFields = {};
    for _, sPart in ipairs(split(sTable:sub(tTokens[1].Stop + 1, tTokens[#tTokens - 1].Start - 1))) do
        local tPart = Tokens.scan(sPart, 'migration field');
        if (tPart[1].Text ~= '<eof>') then
            assert(tPart[2].Text == '=', 'Expected a named legacy field: '..sPart);
            local sValue = sPart:sub(tPart[2].Stop + 1);
            tFields[#tFields + 1] = {Name = tPart[1].Text, Value = sValue,
                Documentation = sPart:sub(1, tPart[1].Start - 1), Function = functionInfo(sValue)};
        end
    end
    return tFields;
end

--[[!
@fqxn LXC.Tools.PortClasses.edits
@desc Applies non-overlapping token replacements in reverse source order.
!]]
local function edits(sSource, tEdits)
    table.sort(tEdits, function(a, b) return a.Start > b.Start; end);
    local nBoundary = #sSource + 1;
    for _, tEdit in ipairs(tEdits) do
        if (tEdit.Stop < nBoundary) then
            sSource = sSource:sub(1, tEdit.Start - 1)..tEdit.Text..sSource:sub(tEdit.Stop + 1);
            nBoundary = tEdit.Start;
        end
    end
    return sSource;
end

--[[!
@fqxn LXC.Tools.PortClasses.indent
@desc Removes common indentation and places a source block at its new class depth.
!]]
local function indent(sSource, nSpaces)
    sSource = sSource:gsub('^%s*\n', ''):gsub('%s+$', '');
    local nMinimum;
    for sLine in (sSource..'\n'):gmatch('(.-)\n') do
        if (sLine:match('%S')) then
            local n = #(sLine:match('^ *'));
            nMinimum = nMinimum and math.min(nMinimum, n) or n;
        end
    end
    local tLines = {};
    for sLine in (sSource..'\n'):gmatch('(.-)\n') do
        tLines[#tLines + 1] = sLine:match('%S') and string.rep(' ', nSpaces)..sLine:sub((nMinimum or 0) + 1) or '';
    end
    return table.concat(tLines, '\n');
end

--[[!
@fqxn LXC.Tools.PortClasses.rewrite
@desc Replaces metadata views with explicit instances and qualifies former
    file-local helpers as private static members. It leaves strings opaque.
!]]
local function rewrite(sBody, tClass, tParameters, tRename)
    local tReferences, tTokens = LuaScope.references(sBody, tClass.Path, tParameters, false);
    local tEdits = {};
    for _, tReference in ipairs(tReferences) do
        local tToken = tTokens[tReference.Index];
        if (tReference.Initial and tRename[tToken.Text]) then
            tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tToken.Stop, Text = tRename[tToken.Text]};
        elseif (tToken.Text == '_ENV') then
            tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tToken.Stop, Text = '_G'};
        end
    end
    sBody = edits(sBody, tEdits);
    tTokens = Tokens.scan(sBody, tClass.Path);
    tEdits = {};
    for _, tToken in ipairs(tTokens) do
        if (tToken.Kind == 'string') then
            local sValue = assert(load('return '..tToken.Text, 'migration literal', 't', {}))();
            if (tClass.FieldNames[sValue]) then
                tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tToken.Stop,
                    Text = string.format('%q', tClass.FieldNames[sValue])};
            end
        end
    end
    local tViews = {pri = true, pro = true};
    for n, tToken in ipairs(tTokens) do
        if (tToken.Text:lower():find('cdat', 1, true)) then tViews[tToken.Text] = true; end
        if (tTokens[n + 1] and tTokens[n + 1].Text == '=' and tTokens[n + 4] and
            tTokens[n + 3].Text == '.' and (tTokens[n + 4].Text == 'pri' or tTokens[n + 4].Text == 'pro')) then
            tViews[tToken.Text] = true;
        end
    end
    for n, tToken in ipairs(tTokens) do
        local sRoot = tToken.Text;
        local bRecord = sRoot == 'this' or sRoot == 'other' or sRoot:lower():find('cdat', 1, true);
        local nEnd, sReplacement;
        if (bRecord and tTokens[n + 1] and tTokens[n + 1].Text == '.') then
            local sSelector = tTokens[n + 2].Text;
            if (sSelector == 'pri' or sSelector == 'pro' or sSelector == 'pub') then
                nEnd, sReplacement = n + 2, sRoot;
            elseif (sSelector == 'ins' and tTokens[n + 3].Text == '[') then
                local x, nDepth = n + 4, 1;
                while (nDepth > 0) do
                    if (tTokens[x].Text == '[') then nDepth = nDepth + 1; end
                    if (tTokens[x].Text == ']') then nDepth = nDepth - 1; end
                    if (nDepth > 0) then x = x + 1; end
                end
                local sObject = sBody:sub(tTokens[n + 3].Stop + 1, tTokens[x].Start - 1);
                sReplacement = sObject:match('^[%w_%[%]%.]+$') and sObject or '('..sObject..')';
                nEnd = x;
                if (tTokens[x + 1].Text == '.' and
                    (tTokens[x + 2].Text == 'pri' or tTokens[x + 2].Text == 'pro' or tTokens[x + 2].Text == 'pub')) then nEnd = x + 2; end
            end
        end
        if (nEnd) then
            tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tTokens[nEnd].Stop, Text = sReplacement};
            if (tTokens[nEnd + 1].Text == '.' and tClass.FieldNames[tTokens[nEnd + 2].Text]) then
                local tField = tTokens[nEnd + 2];
                tEdits[#tEdits + 1] = {Start = tField.Start, Stop = tField.Stop, Text = tClass.FieldNames[tField.Text]};
            end
        elseif (tViews[sRoot] and tTokens[n + 1] and tTokens[n + 1].Text == '.' and tClass.FieldNames[tTokens[n + 2].Text]) then
            local tField = tTokens[n + 2];
            tEdits[#tEdits + 1] = {Start = tField.Start, Stop = tField.Stop, Text = tClass.FieldNames[tField.Text]};
        end
    end
    sBody = edits(sBody, tEdits);

    -- Drop the obsolete metadata argument from calls to migrated static helpers.
    local tCurrentParameters = {};
    for _, sName in ipairs(tParameters) do tCurrentParameters[#tCurrentParameters + 1] = tRename[sName] or sName; end
    tReferences, tTokens = LuaScope.references(sBody, tClass.Path, tCurrentParameters, false);
    tEdits = {};
    for _, tReference in ipairs(tReferences) do
        local n = tReference.Index;
        local tSymbol = tClass.Symbols[tTokens[n].Text];
        if (not tReference.Local and tSymbol and tSymbol.DropMetadata and tTokens[n + 1].Text == '(') then
            local x, nDepth = n + 2, 1;
            while (nDepth > 0) do
                if (tTokens[x].Text == '(') then nDepth = nDepth + 1; end
                if (tTokens[x].Text == ')') then nDepth = nDepth - 1; end
                if (nDepth > 0) then x = x + 1; end
            end
            local tArguments = split(sBody:sub(tTokens[n + 1].Stop + 1, tTokens[x].Start - 1));
            table.remove(tArguments, 2);
            tEdits[#tEdits + 1] = {Start = tTokens[n + 1].Stop + 1, Stop = tTokens[x].Start - 1, Text = table.concat(tArguments, ',')};
        end
    end
    sBody = edits(sBody, tEdits);
    tReferences, tTokens = LuaScope.references(sBody, tClass.Path, tCurrentParameters, false);
    tEdits = {};
    for _, tReference in ipairs(tReferences) do
        local tToken = tTokens[tReference.Index];
        local tSymbol = tClass.Symbols[tToken.Text];
        if (not tReference.Local and tSymbol) then
            tEdits[#tEdits + 1] = {Start = tToken.Start, Stop = tToken.Stop, Text = tClass.Name..'.'..tSymbol.Name};
        end
    end
    return edits(sBody, tEdits);
end

--[[!
@fqxn LXC.Tools.PortClasses.migrate
@desc Emits one class, with file helpers converted to private static members.
    Outputs require review and the framework acceptance suite before retirement
    of their old Lua source. No compatibility factory remains in deployed code.
!]]
local function migrate(sRelative)
    local pPath = 'LuaEx/classes/'..sRelative..'.lua';
    local sSource = read(pPath);
    local sName = sRelative:match('([^/]+)$');
    local tTokens = Tokens.scan(sSource, pPath);
    local nCall;
    for n, tToken in ipairs(tTokens) do
        if (tToken.Text == 'class' and tTokens[n + 1].Text == '(' and tTokens[n + 2].Kind == 'string') then nCall = n; break; end
    end
    assert(nCall, 'Missing legacy declaration: '..pPath);
    local x, nDepth = nCall + 2, 1;
    while (nDepth > 0) do
        if (tTokens[x].Text == '(') then nDepth = nDepth + 1; end
        if (tTokens[x].Text == ')') then nDepth = nDepth - 1; end
        if (nDepth > 0) then x = x + 1; end
    end
    local tArguments = split(sSource:sub(tTokens[nCall + 1].Stop + 1, tTokens[x].Start - 1));
    local tClass = {Name = sName, Path = pPath, Symbols = {}, Prefix = {}, Buckets = {}, FieldNames = {}};
    local tMembers = {};
    for n = 2, 6 do
        tClass.Buckets[n] = fields(tArguments[n]);
        for _, tField in ipairs(tClass.Buckets[n]) do
            if (tField.Function) then tMembers[tField.Name] = true; end
        end
    end
    for n = 3, 6 do
        for _, tField in ipairs(tClass.Buckets[n]) do
            if (not tField.Function and tMembers[tField.Name]) then tClass.FieldNames[tField.Name] = '_'..tField.Name; end
        end
    end
    local sPrefix = sSource:sub(1, tTokens[nCall].Start - 1);
    sPrefix = sPrefix:gsub('return%s*$', ''):gsub('local%s+'..sName..'%s*=%s*$', ''):gsub(sName..'%s*=%s*$', '');
    LuaScope.references(sPrefix, pPath, {}, false, function(t, nStart, nStop)
        local s = sPrefix:sub(t[nStart].Start, t[nStop].Stop):gsub(';%s*$', '');
        if (s == ';' or s == '') then return; end
        local sLocalName, sValue;
        if (t[nStart].Text == 'local' and t[nStart + 1].Text == 'function') then
            sLocalName = t[nStart + 2].Text;
            sValue = 'function'..sPrefix:sub(t[nStart + 2].Stop + 1, t[nStop].Stop):gsub(';%s*$', '');
        elseif (t[nStart].Text == 'local') then
            sLocalName = t[nStart + 1].Text;
            if (t[nStart + 2] and t[nStart + 2].Text == '=') then sValue = sPrefix:sub(t[nStart + 2].Stop + 1, t[nStop].Stop):gsub(';%s*$', ''); end
        elseif (t[nStart + 1] and t[nStart + 1].Text == '=') then
            sLocalName, sValue = t[nStart].Text, sPrefix:sub(t[nStart + 1].Stop + 1, t[nStop].Stop):gsub(';%s*$', '');
        else tClass.Prefix[#tClass.Prefix + 1] = {Statement = s}; return; end
        if (sLocalName == sName or not sValue) then return; end
        if (sValue:match('^%s*(.-)%s*$') == sLocalName) then return; end
        local tFunction = functionInfo(sValue);
        local sMember = tFunction and ('helper'..sLocalName:gsub('^_', ''):gsub('^%l', string.upper)) or sLocalName;
        local tDefinition = {Original = sLocalName, Name = sMember, Value = sValue, Function = tFunction};
        tDefinition.DropMetadata = tFunction and tFunction.Parameters[2] == 'cdat';
        tClass.Symbols[sLocalName] = tDefinition;
        tClass.Prefix[#tClass.Prefix + 1] = tDefinition;
    end);

    local tOutput = {'--[[!\n@fqxn LuaEx.Classes.'..sName..'\n@desc Native LXC migration; explicit instance access and private class helpers.\n!]]',
        'namespace LuaEx.Classes\n{\n    class '..sName..'\n    {'};
    local tStaticStatements = {};
    local function fEmitMethod(tField, sModifiers, bHelper, bStatic)
        local tFunction = tField.Function;
        local tParameters, tRename = {}, {};
        for n, sParameter in ipairs(tFunction.Parameters) do
            if (sParameter == 'cdat') then
                tRename[sParameter] = bHelper and 'other' or 'this';
            elseif (sParameter == 'this') then
                if (bHelper) then tParameters[#tParameters + 1] = 'other'; tRename.this = 'other'; end
            elseif (not bHelper and sModifiers == 'public' and tField.Name:match('^__') and sParameter == 'left') then
                tRename.left = 'this';
            elseif (not bHelper and tField.Name:match('^__') and sParameter == 'right') then
                tRename.right = 'other'; tParameters[#tParameters + 1] = 'other';
            else tParameters[#tParameters + 1] = sParameter; end
        end
        if (bStatic and tRename.cdat == 'this') then tRename.cdat = sName; end
        local sBody = rewrite(tFunction.Body, tClass, tFunction.Parameters, tRename);
        local sMethodName = tField.Name == '__eq' and 'equals' or tField.Name;
        if (tField.Documentation and tField.Documentation:find('@')) then
            local sDocumentation = tField.Documentation:gsub('[^\n]*@param%s+table%s+cdat[^\n]*\n', '');
            tOutput[#tOutput + 1] = indent(sDocumentation, 8);
        else
            tOutput[#tOutput + 1] = '        --[[!\n        @fqxn LuaEx.Classes.'..sName..'.'..sMethodName..'\n        @desc '..(bHelper and 'Private class helper migrated from '..tField.Original..'.' or 'Retains the existing '..sName..' operation.')..'\n        !]]';
        end
        tOutput[#tOutput + 1] = '        '..sModifiers..' '..sMethodName..'('..table.concat(tParameters, ', ')..')\n        {\n'..indent(sBody, 12)..'\n        }\n';
    end
    for _, tDefinition in ipairs(tClass.Prefix) do
        if (tDefinition.Statement) then
            tStaticStatements[#tStaticStatements + 1] = rewrite(tDefinition.Statement, tClass, {}, {});
        elseif (tDefinition.Function) then
            fEmitMethod(tDefinition, 'private static', true, true);
        else
            local sValue = rewrite('return '..tDefinition.Value, tClass, {}, {}):gsub('^return%s+', '');
            tOutput[#tOutput + 1] = '        private static '..tDefinition.Name..' = '..sValue..';\n';
        end
    end
    if (#tStaticStatements > 0) then
        tOutput[#tOutput + 1] = '        static '..sName..'()\n        {\n'..indent(table.concat(tStaticStatements, '\n'), 12)..'\n        }\n';
    end
    local tVisibility = {[2] = 'public', [3] = 'public static', [4] = 'private', [5] = 'protected', [6] = 'public'};
    for n = 2, 6 do
        for _, tField in ipairs(tClass.Buckets[n]) do
            if (n == 3 and tField.Name == sName) then
                -- Legacy static self-capture is unnecessary with lexical class lookup.
            elseif (tField.Function) then fEmitMethod(tField, tVisibility[n], false, n == 3);
            else
                local sField = tClass.FieldNames[tField.Name] or tField.Name;
                local sModifiers = tVisibility[n];
                if (sField:find('__RO', 1, true)) then sField = sField:gsub('__RO', ''); sModifiers = sModifiers..' const'; end
                local sValue = rewrite('return '..tField.Value, tClass, {}, {}):gsub('^return%s+', ''):gsub('%s+$', '');
                tOutput[#tOutput + 1] = '        '..sModifiers..' '..sField..' = '..sValue..';\n';
            end
        end
    end
    tOutput[#tOutput + 1] = '    }\n}\n';
    local pOutput = 'LuaEx/classes/'..sRelative..'.lxc';
    local hFile = assert(io.open(pOutput, 'wb'));
    hFile:write(table.concat(tOutput, '\n')); hFile:close();
    print('Ported '..sName..' to '..pOutput);
end

for _, sPath in ipairs(_tPaths) do migrate(sPath); end
