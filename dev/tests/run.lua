--[[!
    @fqxn Tests.Run
    @desc Runs configured core checks in fresh native Lua processes. Returns a
    failing process status when any selected check fails or cannot start.
    Run lua tests/run.lua; optional arguments are --list, --suite NAME and --lua PATH.
!]]
local sSource = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local sRoot = (sSource:match("^(.*)/") or ".").."/..";
package.path = sRoot.."/?.lua;"..package.path;
local tConfiguration = require("tests.suites");
local sLua = arg[-1] or "lua";
local sSelected;
local bList = false;
local bFailed = false;

--[[!
    @fqxn Tests.Run.quoteArgument
    @desc Quotes subprocess arguments for the native host shell. Windows rejects
    command-expansion characters instead of interpreting them in executable paths.
    @param string sValue One argument.
    @ret string sQuoted Shell-safe argument.
!]]
local function quoteArgument(sValue)
    if (package.config:sub(1, 1) == "\\") then
        assert(not sValue:find('["%%!%^\r\n]'), "Unsupported shell character in test executable path.");
        return '"'..sValue..'"';
    end

    return "'"..sValue:gsub("'", "'\"'\"'").."'";
end

local nIndex = 1;
while (nIndex <= #arg) do
    local sOption = arg[nIndex];

    if (sOption == "--list") then
        bList = true;
    elseif (sOption == "--suite" or sOption == "--lua") then
        nIndex = nIndex + 1;
        assert(arg[nIndex], "Missing value for "..sOption);
        if (sOption == "--suite") then sSelected = arg[nIndex]; else sLua = arg[nIndex]; end
    else
        error("Unknown test option: "..sOption);
    end

    nIndex = nIndex + 1;
end

local tSelected = {};
for _, tSuite in ipairs(tConfiguration.core) do
    if (not sSelected or sSelected == tSuite.name) then
        tSelected[#tSelected + 1] = tSuite;
    end
end
assert(#tSelected > 0, "Unknown core suite: "..tostring(sSelected));

if (bList) then
    for _, tSuite in ipairs(tSelected) do print(tSuite.name.." -> "..tSuite.file); end
else
    local nPassed = 0;
    local nFailed = 0;

    for _, tSuite in ipairs(tSelected) do
        print("RUN "..tSuite.name);
        io.stdout:flush();
        local sCommand = quoteArgument(sLua).." "..quoteArgument(sRoot.."/tests/run_case.lua").." "..quoteArgument(tSuite.name);

        -- cmd.exe requires an outer quote pair around a command beginning with a quoted path.
        if (package.config:sub(1, 1) == "\\") then sCommand = '"'..sCommand..'"'; end
        local bOK, sKind, nCode = os.execute(sCommand);

        if (bOK == true and sKind == "exit" and nCode == 0) then
            nPassed = nPassed + 1;
        else
            nFailed = nFailed + 1;
            print("FAIL "..tSuite.name.." ("..tostring(sKind)..", "..tostring(nCode)..")");
        end
    end

    print("Core results: "..nPassed.." passed; "..nFailed.." failed.");
    bFailed = nFailed > 0;
end

print("Coverage exclusions (not passing tests):");
for _, sReason in ipairs(tConfiguration.unavailable) do print("  "..sReason); end
print("Readiness limits: Tree serialization and legacy collection persistence methods remain unresolved; see tests/README.md.");
if (bFailed) then os.exit(1); end
