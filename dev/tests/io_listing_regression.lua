-- Native filesystem checks. The shared test bootstrap prohibits ordinary writes;
-- this suite creates only its own os.tmpname-derived scratch tree through io.*.
if (not LUAEX_INIT) then require("LuaEx.init"); end
local _sSource = debug.getinfo(1, "S").source:sub(2);
local _pRoot = assert(_sSource:gsub("\\", "/"):match("^(.*)/tests/[^/]+$"));
local _sTemporary = os.tmpname();
local _pTemporary = _sTemporary;
if (_pTemporary:match("^\\[^\\]") and os.getenv("TEMP")) then
    _pTemporary = os.getenv("TEMP").._pTemporary;
end
local _pScratch = _pTemporary.."-luaex-io";
os.remove(_pTemporary);
local _fExecute, _fPopen = os.execute, io.popen;
local _hStdout = io.stdout;
local _nCalls, _nChecks = 0, 0;
local function check(bCondition, sLabel)
    _nChecks = _nChecks + 1;
    assert(bCondition, sLabel);
end
local function fromHex(sHex)
    return (sHex:gsub("%x%x", function(sByte) return string.char(tonumber(sByte, 16)); end));
end
local bOK, sFailure = xpcall(function()
    os.execute = function() _nCalls = _nCalls + 1; error("Forbidden shell call."); end;
    io.popen = function() _nCalls = _nCalls + 1; error("Forbidden process pipe."); end;
    assert(io.mkdir(_pScratch.."/nested/deep"));
    assert(io.copy(_sSource, _pScratch.."/alpha.lua"));
    assert(io.copy(_sSource, _pScratch.."/nested/beta.LUA"));
    assert(io.copy(_sSource, _pScratch.."/nested/deep/gamma.txt"));
    assert(io.mkdir(_pScratch.."/literal % ! & $ folder"));
    check(io.isdir(_pScratch) and not io.isfile(_pScratch), "directory classification");
    check(io.isfile(_pScratch.."/alpha.lua") and not io.isdir(_pScratch.."/alpha.lua"), "file classification");
    check(not io.exists(_pScratch.."/missing"), "missing path");
    check(#assert(io.listfiles(_pScratch, false)) == 1, "nonrecursive files");
    check(#assert(io.listfiles(_pScratch, true, nil, "lua")) == 2, "recursive extension filtering");
    check(#assert(io.listdirs(_pScratch)) == 2, "child directories exclude root");
    check(#assert(io.list(_pScratch, true)) == 6, "combined directory/file listing");
    check(#assert(io.listfiles(_pScratch.."/nested/deep", false, nil, "lxc")) == 0, "empty filtered listing succeeds");
    assert(io.copy(_sSource, _pScratch.."/nested/Probe.lxc"));
    assert(io.copy(_sSource, _pScratch.."/Order.LXE"));
    -- Inspect the actual module selected by the hook rather than assuming a host architecture.
    local fPaths;
    for nIndex = 1, 30 do
        local sName, vValue = debug.getupvalue(io.scanfiles, nIndex);
        if (sName == "listPaths") then fPaths = vValue; break; end
    end
    local Native;
    for nIndex = 1, 30 do
        local sName, vValue = debug.getupvalue(fPaths, nIndex);
        if (sName == "_tNative") then Native = vValue; break; end
    end
    assert(Native);
    local tEntries = assert(Native.list(_pScratch, true));
    for _, tEntry in ipairs(tEntries) do
        local tStatus = assert(Native.stat(tEntry.Path));
        check(tEntry.Kind == tStatus.Kind and tEntry.Identity == tStatus.Identity, "enumerated metadata agrees with standalone stat");
    end
    check(Native.list(_pScratch.."/missing", true) == nil, "metadata listing propagates missing-directory errors");
    local nStats, nLists = 0, 0;
    local fHook, sMask, nCount = debug.gethook();
    debug.sethook(function()
        local fCalled = debug.getinfo(2, "f").func;
        if (fCalled == Native.stat) then nStats = nStats + 1; end
        if (fCalled == Native.list) then nLists = nLists + 1; end
    end, "c");
    local tSources, sScanReason, tScan = io.scanfiles({_pScratch.."/nested", _pScratch, _pScratch.."/./", _pScratch.."/missing", _pScratch.."/alpha.lua"}, "lxc", "lxe");
    debug.sethook(fHook, sMask, nCount);
    check(nStats == 5 and nLists == 4, "only roots need explicit stat calls; each distinct directory is enumerated once");
    check(tSources and #tSources == 2, sScanReason or "approved extensions across overlapping roots");
    check(tSources[1] < tSources[2] and tScan.Directories == 4, "sorted unique sources and one enumeration per directory");
    check(tScan.Roots[_pScratch] == tScan.Roots[_pScratch.."/./"], "root aliases share canonical identity");
    local tEmpty, _, tEmptyScan = io.scanfiles({}, "lxc", "lxe");
    check(#tEmpty == 0 and tEmptyScan.Directories == 0, "empty scan succeeds without traversal");
    check(not pcall(io.scanfiles, {[2] = _pScratch}), "sparse roots rejected");
    check(not pcall(io.scanfiles, {false}), "non-string roots rejected");
    check(not pcall(io.scanfiles, {_pScratch}, "lxc", nil), "nil scan filter rejected");
    assert(io.delete(_pScratch.."/nested/Probe.lxc"));
    assert(io.delete(_pScratch.."/Order.LXE"));
    local nCallbacks = 0;
    assert(io.listfiles(_pScratch, true, function(_, bFile) check(bFile, "file callback kind"); nCallbacks = nCallbacks + 1; end));
    check(nCallbacks == 3, "callback count");
    local tResult, sReason = io.listfiles(_pScratch, false, function() error("callback marker"); end);
    check(tResult == nil and sReason:find("callback marker", 1, true), "callback failure is reported");
    check(io.listfiles(_pScratch.."/missing") == nil, "missing directory is not an empty success");
    check(not pcall(io.listfiles, _pScratch, false, nil, "lua", nil), "nil extension filter rejected");
    check(not pcall(io.listfiles, _pScratch.."\0"), "NUL path rejected");
    check(not pcall(io.copy, _pScratch.."/alpha.lua", {}), "invalid native second path rejected");
    check(io.copy(_pScratch.."/missing", _pScratch.."/copy.lua") == nil, "native error returned");
    check(io.findfile("beta.LUA", _pScratch) ~= nil, "native recursive file search");
    check(io.move(_pScratch.."/alpha.lua", _pScratch.."/moved.lua"), "move");
    check(io.chmod("644", _pScratch.."/moved.lua"), "portable permission bits");
    check(io.chmod("u+rw", _pScratch.."/moved.lua"), "symbolic permissions");
    check(io.zip({_pScratch.."/moved.lua"}, _pScratch.."/native.zip"), "stored ZIP creation");
    check(io.unzip(_pScratch.."/native.zip", _pScratch.."/unpacked"), "stored ZIP extraction");
    check(io.isfile(_pScratch.."/unpacked/moved.lua"), "ZIP output");
    local Archive = require("LuaEx.lib.io.Archive");
    local tWritten = {};
    for _, tFixture in ipairs(assert(loadfile(_pRoot.."/tests/io_archive_fixtures.lua"))()) do
        local sArchive = fromHex(tFixture.Archive);
        local tBackend = {
            read = function() return sArchive; end,
            stat = function() return nil; end,
            mkdir = function() return true; end,
            write = function(pPath, sData) tWritten[pPath] = sData; return true; end,
        };
        assert(Archive.extract("fixture.zip", "sandbox", tBackend));
        check(tWritten["sandbox/nested/data.bin"] == tFixture.Payload, "independent DEFLATE block "..tFixture.Block);
        local sOriginal = sArchive;
        local sOriginalName = "nested/data.bin";
        local sTraversal = "../"..string.rep("x", #sOriginalName - 3);
        sArchive = sOriginal:gsub("nested/data%.bin", sTraversal);
        check(not Archive.extract("traversal.zip", "sandbox", tBackend), "ZIP traversal rejected");
        sArchive = sOriginal:gsub("nested/data%.bin", ".. /"..string.rep("x", #sOriginalName - 4));
        check(not Archive.extract("windows-traversal.zip", "sandbox", tBackend), "Windows trailing-space traversal rejected");
        sArchive = sOriginal;
        sArchive = sArchive:sub(1, #sArchive - 4);
        check(not Archive.extract("broken.zip", "sandbox", tBackend), "truncated archive rejected");
    end
    assert(io.copy(_sSource, _pScratch.."/λ search ☃.txt"));
    local tPrinted = {};
    io.stdout = {write = function(this, sText) tPrinted[#tPrinted + 1] = sText; return this; end};
    local bMatched, nMatches = io.findstr("Forbidden ".."shell call.", _pScratch.."/λ search ☃.txt");
    check(bMatched and nMatches == 1, "UTF-8 literal text search");
    bMatched, nMatches = io.grep("Forbidden%s+shell%s+call", _pScratch.."/λ search ☃.txt");
    check(bMatched and nMatches == 1, "UTF-8 Lua-pattern search");
    check(#tPrinted == 2, "text matches are written to stdout");
    check(io.grep("[", _pScratch.."/λ search ☃.txt") == nil, "invalid text pattern is reported");
    io.stdout = _hStdout;
    check(io.delete(_pScratch.."/moved.lua"), "delete");
    check(_nCalls == 0, "zero shell calls across native I/O operations");
end, debug.traceback);
os.execute, io.popen = _fExecute, _fPopen;
io.stdout = _hStdout;
local bRemoved, sRemoval = io.rmdir(_pScratch);
assert(bRemoved, sRemoval);
if (not bOK) then error(sFailure, 0); end
print("PASS native I/O: ".._nChecks.." checks, no shell calls; Windows runtime tested, other platforms require native runs.");
