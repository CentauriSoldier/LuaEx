--[[!
@fqxn Pulsar.LinterLXC.Worker
@desc Reads a length-prefixed source batch. Uses trusted LXC compiler modules,
    never LuaEx.load, Runtime, application require, loadSources or initializers.
    Ordinary Lua chunks are compiled in text mode and never invoked.
!]]
local _tMessages = {};
local _tFiles = {};
local _tClassNames = {};

local function quoted(sValue)
    local tEscapes = {['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t'};
    return '"'..tostring(sValue):gsub('[%z\1-\31\\"]', function(sChar)
        return tEscapes[sChar] or string.format('\\u%04x', string.byte(sChar));
    end)..'"';
end

local function report(pFile, nLine, sPhase, sMessage)
    _tMessages[#_tMessages + 1] = {File = pFile, Line = math.max(1, nLine or 1),
        Phase = sPhase, Message = tostring(sMessage)};
end

local function readLength(nMaximum)
    local sLength = assert(io.read('*l'), 'Missing request length.');
    assert(sLength:match('^%d+$'), 'Invalid request length.');
    local nLength = tonumber(sLength);
    assert(nLength <= nMaximum, 'Request limit exceeded.');
    return nLength;
end

local function readString(nMaximum)
    local nLength = readLength(nMaximum);
    if (nLength == 0) then return ''; end
    local sValue = assert(io.read(nLength), 'Incomplete source request.');
    assert(#sValue == nLength, 'Truncated source request.');
    return sValue;
end

-- LXC diagnostics are line-based. Native Lua errors retain their padded source
-- line; LuaScope/Tokens errors inside a member are relative to that member body.
local function diagnostic(vError, sPhase, tDefinition, pFallback)
    local sError = tostring(vError);
    local pFile, sLine = sError:match('^LXC %[%s*(.-):(%d+)%s');
    local nLine = tonumber(sLine) or (tDefinition and tDefinition.Line) or 1;
    pFile = pFile or (tDefinition and (tDefinition.Owner or tDefinition).File) or pFallback;
    for _, tFile in ipairs(_tFiles) do
        local sPattern = tFile.File:gsub('([^%w])', '%%%1')..':(%d+):';
        local sFound = sError:match(sPattern);
        if (sFound) then
            pFile, nLine = tFile.File, tonumber(sFound);
            if (tDefinition and (sError:find('LuaScope.lua:', 1, true) or sError:find('Tokens.lua:', 1, true))) then
                nLine = nLine + (tDefinition.Line or 1) - 1;
            end
            break;
        end
    end
    report(pFile, nLine, sPhase, sError);
end

local function main()
    assert(_VERSION == 'Lua 5.4', 'The LXC linter requires Lua 5.4.');
    local nFiles = readLength(1000);
    for n = 1, nFiles do
        _tFiles[n] = {File = readString(65536), Source = readString(16 * 1024 * 1024)};
    end
    assert(#_tFiles > 0, 'No source supplied.');
    if (arg[2] == 'lua') then
        for _, tFile in ipairs(_tFiles) do
            local sSource = tFile.Source:gsub('^\239\187\191', ''):gsub('^#![^\n]*', '');
            local fChunk, sError = load(sSource, '@'..tFile.File, 't', {});
            if (not fChunk) then diagnostic(sError, 'Lua 5.4 syntax', nil, tFile.File); end
        end
        return;
    end
    assert(arg[2] == 'lxc', 'Unknown lint mode.');
    local pModules = arg[1]..'/LuaEx/lxc/modules/';
    local function fModule(sName)
        return assert(loadfile(pModules..sName..'.lua', 't', _G))();
    end
    local Tokens, Names, Operators = fModule('Tokens'), fModule('Names'), fModule('Operators');
    local Diagnostics = fModule('Diagnostics');
    local Parser = fModule('Parser')(Tokens, Names, Operators);
    local Model = fModule('Model')(fModule('Validation'), Diagnostics, Names, Operators);
    local Compiler = fModule('Compiler')(Tokens, Model, fModule('LuaScope')(Tokens));
    local tBatch = {};

    for _, tFile in ipairs(_tFiles) do
        local bOK, tClasses = pcall(Parser.parse, tFile.Source, tFile.File);
        if (not bOK) then diagnostic(tClasses, 'LXC declaration syntax', nil, tFile.File);
        else
            for _, tClass in ipairs(tClasses) do
                _tClassNames[#_tClassNames + 1] = tClass.Name;
                if (tBatch[tClass.FullName]) then
                    report(tClass.File, tClass.Line, 'LXC declarations', 'Duplicate class: '..tClass.FullName);
                else tClass.Batch = tBatch; tBatch[tClass.FullName] = tClass; end
            end
        end
    end
    -- A broken dependency source must not create invented missing-parent errors.
    if (#_tMessages > 0) then return; end
    local bOK, tOrder = pcall(Model.validate, tBatch);
    if (not bOK) then diagnostic(tOrder, 'LXC declaration semantics', nil, _tFiles[1].File); return; end

    for _, tClass in ipairs(tOrder) do
        local function fCheck(tMember, fCompile)
            local bCompiled, sError = pcall(fCompile, tMember, {});
            if (not bCompiled) then diagnostic(sError, 'LXC Lua body / compile-time rules', tMember, tClass.File); end
        end
        for _, tMember in ipairs(tClass.Members) do
            fCheck(tMember, Compiler.initializer);
            fCheck(tMember, Compiler.method);
            for _, tAccess in pairs(tMember.Accessors or {}) do fCheck(tAccess, Compiler.method); end
        end
        if (tClass.Constructor) then fCheck(tClass.Constructor, Compiler.constructor); end
        if (tClass.StaticConstructor) then fCheck(tClass.StaticConstructor, Compiler.method); end
    end
end

local _bOK, _sError = pcall(main);
if (not _bOK) then
    report((_tFiles[1] and _tFiles[1].File) or '', 1, 'Linter configuration / protocol', _sError);
end
local _tOutput = {};
for _, tMessage in ipairs(_tMessages) do
    _tOutput[#_tOutput + 1] = '{"file":'..quoted(tMessage.File)..',"line":'..tMessage.Line..
        ',"severity":"error","phase":'..quoted(tMessage.Phase)..',"message":'..quoted(tMessage.Message)..'}';
end
local _tNames = {};
for _, sName in ipairs(_tClassNames) do _tNames[#_tNames + 1] = quoted(sName); end
io.write('{"diagnostics":['..table.concat(_tOutput, ',')..'],"classNames":['..table.concat(_tNames, ',')..']}');
