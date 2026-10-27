--[[!
    @fqxn Tests.IOListing
    @desc Exercises real LuaEx listing hooks with fake process pipes. Covers empty
    success, open/read/callback/close failures, legacy exit statuses and io.list
    propagation. The original io API and module state are restored on completion.
!]]
if (not LUAEX_INIT) then require("LuaEx.load")(4); end

local _nChecks = 0;

--[[!
    @fqxn Tests.IOListing.Helpers.check
    @scope local
    @desc Asserts and counts a listing regression expectation.
    @param string sLabel Expected behavior.
    @param boolean bCondition Whether the behavior occurred.
!]]
local function check(sLabel, bCondition)
    assert(bCondition, sLabel);
    _nChecks = _nChecks + 1;
end

local _tOriginalIO = {};
for sName, vValue in pairs(io) do _tOriginalIO[sName] = vValue; end
local _sOriginalConfig = package.config;
local _vOriginalModule = package.loaded["LuaEx.hook.iohook"];

local bOK, sFailure = pcall(function()
    package.config = "/".._sOriginalConfig:sub(2);
    local sMode, sFailGroup = "success", nil;
    local nOpened, nClosed, nCallbacks = 0, 0, 0;

    io.popen = function(sCommand)
        nOpened = nOpened + 1;
        local sGroup = sCommand:find("-type d", 1, true) and "directories" or "files";
        local sPipeMode = (not sFailGroup or sFailGroup == sGroup) and sMode or "success";
        if (sPipeMode == "open_nil") then return nil, "open failed"; end
        if (sPipeMode == "open_throw") then error("open failed"); end
        local tLines = sGroup == "directories" and {"/fixture", "/fixture/sub"} or
                       {"/fixture/a.lua", "/fixture/b.txt"};
        if (sPipeMode == "empty") then tLines = {}; end

        return {
            lines = function()
                if (sPipeMode == "lines_throw") then error("lines failed"); end
                local nIndex = 0;
                return function()
                    nIndex = nIndex + 1;
                    if (sPipeMode == "read_throw" and nIndex == 2) then error("read failed"); end
                    return tLines[nIndex];
                end;
            end,
            close = function()
                nClosed = nClosed + 1;
                if (sPipeMode == "close_throw") then error("close failed"); end
                if (sPipeMode == "close_nil") then return nil, "exit", 1; end
                if (sPipeMode == "close_false") then return false; end
                if (sPipeMode == "signal") then return nil, "signal", 9; end
                if (sPipeMode == "legacy_success") then return 0; end
                if (sPipeMode == "legacy_failure") then return 1; end
                return true, "exit", 0;
            end,
        };
    end;
    package.loaded["LuaEx.hook.iohook"] = nil;
    require("LuaEx.hook.iohook");

    for _, sName in ipairs({"listfiles", "listdirs"}) do
        local fList = io[sName];
        for _, sCase in ipairs({"empty", "legacy_success", "success"}) do
            sMode, nOpened, nClosed = sCase, 0, 0;
            local tItems, sReason = fList("/fixture", false);
            check("Successful listing returns a table", rawtype(tItems) == "table" and sReason == nil);
            check("Successful listing closes once", nOpened == 1 and nClosed == 1);
            if (sCase == "empty") then check("Empty success stays empty", #tItems == 0); end
        end

        for _, sCase in ipairs({"open_nil", "open_throw", "lines_throw", "read_throw",
                                 "close_throw", "close_nil", "close_false", "signal", "legacy_failure"}) do
            sMode, nOpened, nClosed = sCase, 0, 0;
            local tItems, sReason = fList("/fixture", false);
            check("Listing failure returns nil and reason", tItems == nil and rawtype(sReason) == "string");
            local nExpectedCloses = (sCase == "open_nil" or sCase == "open_throw") and 0 or 1;
            check("Failure attempts closure exactly once when opened", nClosed == nExpectedCloses);
        end

        sMode, nClosed = "success", 0;
        local tItems, sReason = fList("/fixture", false, function()
            error("callback failed");
        end);
        check("Callback failure propagates", tItems == nil and sReason:find("callback failed", 1, true));
        check("Callback failure still closes the pipe", nClosed == 1);
    end

    for _, sGroup in ipairs({"directories", "files"}) do
        sMode, sFailGroup, nClosed = "read_throw", sGroup, 0;
        local tItems, sReason = io.list("/fixture", false);
        check("Combined listing propagates either child failure", tItems == nil and rawtype(sReason) == "string");
        check("Combined failure closes every opened pipe", nClosed == (sGroup == "directories" and 1 or 2));
    end

    sMode, sFailGroup = "success", nil;
    local tItems = assert(io.list("/fixture", false, function()
        nCallbacks = nCallbacks + 1;
    end));
    check("Successful combined listing preserves both arrays", #tItems.directories == 2 and #tItems.files == 2);
    check("Successful callbacks remain supported", nCallbacks == 4);
    local tFiltered = assert(io.listfiles("/fixture", false, nil, "lua"));
    check("Extension filtering remains supported", #tFiltered == 1 and tFiltered[1] == "/fixture/a.lua");

    -- Windows must distinguish an empty file selection from process failure.
    -- Enumerating all entries and excluding known directories avoids treating a
    -- no-match exit from dir /a-d as an operational failure.
    package.config = "\\".._sOriginalConfig:sub(2);
    local sWindowsMode = "mixed";
    local nWindowsOpened, nWindowsClosed = 0, 0;
    io.popen = function(sCommand)
        nWindowsOpened = nWindowsOpened + 1;
        local bDirectories = sCommand:find("/ad", 1, true) ~= nil;
        local bRecursive   = sCommand:find("/s", 1, true) ~= nil;
        local tLines = {"directory.txt", "sub"};
        if (not bDirectories and sWindowsMode ~= "only_directories") then
            tLines[#tLines + 1] = "actual.txt";
        end
        if (sWindowsMode == "empty") then tLines = {}; end

        return {
            lines = function()
                local nIndex = 0;
                return function()
                    nIndex = nIndex + 1;
                    local sLine = tLines[nIndex];
                    if (sLine and bRecursive) then return "C:\\fixture\\"..sLine; end
                    return sLine;
                end;
            end,
            close = function()
                nWindowsClosed = nWindowsClosed + 1;
                if ((sWindowsMode == "directory_failure" and bDirectories) or
                    (sWindowsMode == "all_failure" and not bDirectories)) then
                    return nil, "exit", 1;
                end
                return true, "exit", 0;
            end,
        };
    end;
    package.loaded["LuaEx.hook.iohook"] = nil;
    require("LuaEx.hook.iohook");

    for _, bRecursive in ipairs({false, true}) do
        local tWindowsFiles = assert(io.listfiles("C:\\fixture", bRecursive, nil, "txt"));
        check("Windows filtering excludes directories even with matching suffixes",
              #tWindowsFiles == 1 and tWindowsFiles[1] == "C:\\fixture\\actual.txt");
    end
    sWindowsMode = "only_directories";
    check("Windows directory-only folder has an empty successful file list",
          #assert(io.listfiles("C:\\fixture", false)) == 0);
    sWindowsMode = "empty";
    local tEmpty = assert(io.list("C:\\fixture", false));
    check("Empty Windows combined listing succeeds", #tEmpty.files == 0 and #tEmpty.directories == 0);

    for _, sCase in ipairs({"directory_failure", "all_failure"}) do
        sWindowsMode, nWindowsOpened, nWindowsClosed = sCase, 0, 0;
        local tResult, sReason = io.listfiles("C:\\fixture", false);
        check("Windows enumeration failures are not normalized into empty success",
              tResult == nil and rawtype(sReason) == "string");
        check("Windows failure closes every opened process", nWindowsOpened == nWindowsClosed);
    end
end);

-- Restore all hook functions, not only popen: reloading iohook replaces its API.
for sName in pairs(io) do
    if (_tOriginalIO[sName] == nil) then io[sName] = nil; end
end
for sName, vValue in pairs(_tOriginalIO) do io[sName] = vValue; end
package.config = _sOriginalConfig;
package.loaded["LuaEx.hook.iohook"] = _vOriginalModule;
if (not bOK) then error(sFailure, 0); end

print("PASS io listing regression: ".._nChecks.." checks; failures, pipe cleanup and success behavior.");
