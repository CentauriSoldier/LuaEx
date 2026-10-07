--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
local sSourcePath = "";
if not (LUAEX_INIT) then

    function getsourcepath()
        --determine the call location
        local sPath = debug.getinfo(1, "S").source;
        --remove the calling filename
        local sFilenameRAW = sPath:match("^.+"..package.config:sub(1,1).."(.+)$");
        --make a pattern to account for case
        local sFilename = "";
        for x = 1, #sFilenameRAW do
            local sChar = sFilenameRAW:sub(x, x);

            if (sChar:find("[%a]")) then
                sFilename = sFilename.."["..sChar:upper()..sChar:lower().."]";
            else
                sFilename = sFilename..sChar;
            end

        end

        sPath = sPath:gsub("@", ""):gsub(sFilename, "");
        --remove the "/" at the end
        sPath = sPath:sub(1, sPath:len() - 1);

        return sPath;
    end

    --determine the call location
    sSourcePath = getsourcepath();

    --update the package.path (use the main directory to prevent namespace issues)
    package.path = package.path..";"..sSourcePath.."\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================

--[[NOTE:
Dox-specific reproductions. Run in a fresh Lua process using the same standalone
loader as the examples. LuaEx's class implementation is not changed here.

There are two normal-behavior controls and eleven failure reproductions.
Expected after fixes: controls pass and all failure reproductions pass.
Current: controls pass and eleven failure reproductions fail.
The Pulsar case documents an explicitly unfinished output builder.

Each case prints its expectation and actual result. Cause notes name the method
and source location. Locations refer to the source when this file was written.
Paths below are relative to LuaEx/inc/classes/util/Dox/ unless stated otherwise.

File imports and exports are simulated in memory. io.open is restored even when
an operation fails. No fixture files or generated documentation are written.
HTML assets are read normally by the builder. Browser interaction and CDN
availability are outside this file's checks.
]]

local nFailed = 0;
local nControlsFailed = 0;

local function RunTest(sName, fTest, bControl)
    print("\n"..sName);
    local bSuccess, bPassed = pcall(fTest);
    local bResult = bSuccess and bPassed == true;
    print((bResult and "PASS: " or "FAIL: ")..sName);

    if (not bSuccess) then
        print("Actual error: "..tostring(bPassed));
    end

    if (not bResult) then

        if (bControl) then
            nControlsFailed = nControlsFailed + 1;
        else
            nFailed = nFailed + 1;
        end

    end

end

--capture the public export path without creating an output file
local function CaptureExport(oDox)
    local fOpen = io.open;
    local sCaptured = "";
    local nWrites = 0;

    io.open = function(pFile, sMode)

        if (sMode == "w") then
            nWrites = nWrites + 1;
            return {
                write = function(this, sContent)
                    sCaptured = sCaptured..sContent;
                end,
                close = function(this)
                end,
            };
        end

        return fOpen(pFile, sMode);
    end;

    local bSuccess, vError = pcall(function()
        oDox.setOutputPath("DoxBugMemory");
        oDox.export("probe");
    end);
    io.open = fOpen;

    if (not bSuccess) then
        error(vError, 0);
    end

    assert(nWrites == 1, "Expected exactly one captured export.");
    assert(sCaptured == oDox.getOutput(), "Captured export differs from getOutput().");
    return sCaptured;
end

--simulate a source file for importFile/importFiles, restoring io.open afterward
local function WithMemoryFile(pFile, sContent, fOperation)
    local fOpen = io.open;

    io.open = function(pRequested, sMode)

        if (pRequested == pFile and sMode == "r") then
            return {
                read = function(this, sFormat)
                    return sContent;
                end,
                close = function(this)
                end,
            };
        end

        return fOpen(pRequested, sMode);
    end;

    local bSuccess, vResult = pcall(fOperation);
    io.open = fOpen;

    if (not bSuccess) then
        error(vResult, 0);
    end

    return vResult;
end

local function ImportLua(oDox, sBlock)
    oDox.importString(sBlock, DoxMime("lua"));
end

--==============================================================================
--============================ Normal-behavior controls ========================
--==============================================================================
RunTest("CONTROL: ordinary parsing and HTML export", function()
    local oDox = DoxLua("Dox normal control");
    ImportLua(oDox, "--[[! @fqxn DoxControl @desc DOX_NORMAL_MARKER !]]");
    oDox.refresh();
    local sHTML = CaptureExport(oDox);
    print("Expected: HTML contains the imported description.");
    print("Actual output bytes: "..tostring(#sHTML));
    return sHTML:find("DOX_NORMAL_MARKER", 1, true) ~= nil;
end, true);

RunTest("CONTROL: a missing FQXN is rejected", function()
    local oDox = DoxLua("Dox validation control");
    ImportLua(oDox, "--[[! @desc No FQXN here !]]");
    local bAccepted = pcall(function()
        oDox.refresh();
    end);
    print("Expected: refresh rejects the missing required tag.");
    print("Actual accepted: "..tostring(bAccepted));
    return not bAccepted;
end, true);

--==============================================================================
--============================== MIME registration =============================
--==============================================================================
--[[NOTE:
Expected: addMimeType(DoxMime(...)) adds the MIME to this parser.
Current: it errors while indexing global pri, which is nil.
Cause: Dox.lua:477-479, addMimeType uses pri.mimeTypes without obtaining cdat.pri.
]]
RunTest("Dox.addMimeType registers a MIME", function()
    local oDox = DoxLua("Dox MIME registration");
    print("Expected: registering 'extra' succeeds.");
    oDox.addMimeType(DoxMime("extra"));

    for sName, oMime in oDox.getMimeTypes()() do

        if (sName == "extra") then
            return oMime.getName() == "extra";
        end

    end

    return false;
end);

--==============================================================================
--============================== MIME preprocessing ============================
--==============================================================================
--[[NOTE:
Expected: setPreProcessor replaces the MIME's preprocessing function.
Current: it errors while indexing global pri.
Cause: Components/DoxMime.lua:30-32, the setter uses pri.preProcessor without
obtaining cdat.pri. Its constructor and getter do use the correct private data.
]]
RunTest("DoxMime.setPreProcessor replaces the function", function()
    local oMime = DoxMime("extra");
    print("Expected: the updated preprocessor returns 'input!'.");
    oMime.setPreProcessor(function(sInput)
        return sInput.."!";
    end);
    local sResult = oMime.getPreProcessor()("input");
    print("Actual result: "..sResult);
    return sResult == "input!";
end);

--==============================================================================
--============================== Column wrapper clearing =======================
--==============================================================================
--[[NOTE:
Expected: clearColumnWrappers removes the builder's wrappers.
Current: it errors while indexing global pri.
Cause: Components/DoxBuilder.lua:104-105 uses pri.columnWrappers. Apart from
pri being undefined, columnWrappers actually belongs to cdat.pro, not cdat.pri.
]]
RunTest("DoxBuilder.clearColumnWrappers clears existing wrappers", function()
    local oBuilder = DoxBuilderHTML();
    assert(oBuilder.getColumnWrapperCount("Parameter(s)") > 0,
        "The wrapper control must begin with parameter wrappers.");
    print("Expected: clearing succeeds and the wrapper count becomes zero.");
    oBuilder.clearColumnWrappers();
    local nCount = oBuilder.getColumnWrapperCount("Parameter(s)");
    print("Actual remaining parameter wrappers: "..tostring(nCount));
    return nCount == 0;
end);

--==============================================================================
--============================== Block-tag iteration ===========================
--==============================================================================
--[[NOTE:
Expected: eachBlockTag returns every built-in and parser-specific block tag.
Current: it omits the last tag. For DoxLua, the missing tag is PulsarLua.
Cause: Dox.lua:486-494, the iterator increments its index and then tests
nIndex < nMax instead of including the final index.
]]
RunTest("Dox.eachBlockTag includes the last tag", function()
    local oDox = DoxLua("Dox iterator");
    local tBuiltIn = require("LuaEx.inc.classes.util.Dox.Statics.BuiltInBlockTags");
    local nCount = 0;
    local bPulsarFound = false;

    for oTag in oDox.eachBlockTag() do
        nCount = nCount + 1;
        bPulsarFound = bPulsarFound or oTag.getDisplay() == "PulsarLua";
    end

    print("Expected tag count: "..tostring(#tBuiltIn + 1));
    print("Actual tag count: "..tostring(nCount));
    print("PulsarLua tag returned: "..tostring(bPulsarFound));
    return nCount == #tBuiltIn + 1 and bPulsarFound;
end);

--==============================================================================
--============================== File MIME selection ===========================
--==============================================================================
--[[NOTE:
Expected: importing a .lua file uses its lua MIME, even with an earlier-sorting
MIME named aaa registered. Both public file-import methods should behave alike.
Current: both methods use aaa's preprocessor for the .lua source.
Cause: Dox.lua:583 and :625, the loop variable sExt shadows the actual extension.
The condition then compares the dictionary key with that same MIME's own name,
which is true for the first entry regardless of the imported file's extension.
The dictionary is modified only on this in-memory parser to isolate MIME
selection from the separately reproduced addMimeType failure.
]]
local function CheckFileMime(bMultiple)
    local oDox = DoxLua("Dox file MIME");
    local nWrongCalls = 0;
    oDox.getMimeTypes().add("aaa", DoxMime("aaa", function(sInput)
        nWrongCalls = nWrongCalls + 1;
        return sInput;
    end));

    WithMemoryFile("DoxMimeProbe.lua",
        "--[[! @fqxn DoxMimeProbe @desc File content !]]", function()

        if (bMultiple) then
            oDox.importFiles({"DoxMimeProbe.lua"});
        else
            oDox.importFile("DoxMimeProbe.lua");
        end

    end);

    print("Expected aaa preprocessor calls for a .lua file: 0");
    print("Actual aaa preprocessor calls: "..tostring(nWrongCalls));
    return nWrongCalls == 0;
end

RunTest("Dox.importFile selects the MIME by file extension", function()
    return CheckFileMime(false);
end);
RunTest("Dox.importFiles selects the MIME by file extension", function()
    return CheckFileMime(true);
end);

--==============================================================================
--============================== Multiple required tags ========================
--==============================================================================
--[[NOTE:
Expected: a block containing both required tags passes validation.
Current: the second required tag is reported missing even though it is present.
Cause: Components/DoxBlock.lua:109-115, the required-tag matching loop breaks
unconditionally after inspecting its first required tag. Later required tags
therefore never get marked as found. The default single-required-tag case
passes; this failure affects parsers that add custom required tags.
]]
RunTest("DoxBlock recognizes both required tags", function()
    local oFQXN = DoxBlockTag({"fqxn"}, "FQXN", true, false);
    local oNeeded = DoxBlockTag({"need"}, "Needed", true, false);
    print("Expected: FQXN and Needed are both recognized as present.");
    local oBlock = DoxBlock("@fqxn Required.Test @need present",
        Dox.SYNTAX.LUA, "@", {oFQXN, oNeeded}, {oFQXN, oNeeded});
    return class.isinstanceof(oBlock, DoxBlock);
end);

--==============================================================================
--============================== Parameter whitespace ==========================
--==============================================================================
--[[NOTE:
Expected: column separation handles ordinary whitespace without creating an
empty parameter-name column. Equivalent tabs and multiple spaces should either
parse correctly or receive explicit, intentional format validation.
Current: tabs cause refresh to fail; multiple spaces silently create an empty
name wrapper and put the parameter name into the description column.
Cause: Dox.lua:287-308, processBlockItem splits on one literal space at a time
rather than consuming a whitespace separator.
]]
RunTest("Parameter columns handle tabs and repeated spaces", function()
    local oTabs = DoxLua("Dox tab parameters");
    ImportLua(oTabs, "--[[! @fqxn Tabs @param string\tsName\tdescription !]]");
    local bTabsAccepted, vTabError = pcall(function()
        oTabs.refresh();
    end);

    local oSpaces = DoxLua("Dox spaced parameters");
    ImportLua(oSpaces, "--[[! @fqxn Spaces @param string  sName  description !]]");
    oSpaces.refresh();
    local sHTML = CaptureExport(oSpaces);
    local bEmptyName = sHTML:find("<em></em>", 1, true) ~= nil;
    local bCorrectName = sHTML:find("<em>sName</em>", 1, true) ~= nil;
    print("Expected: tabs accepted; repeated spaces preserve sName's column.");
    print("Tabs accepted: "..tostring(bTabsAccepted));

    if (not bTabsAccepted) then
        print("Actual tab error: "..tostring(vTabError));
    end

    print("Repeated spaces produced an empty name wrapper: "..tostring(bEmptyName));
    return bTabsAccepted and not bEmptyName and bCorrectName;
end);

--==============================================================================
--============================== Intro text escaping ===========================
--==============================================================================
--[[NOTE:
Expected: a literal Windows path in the intro survives JavaScript evaluation.
Current: C:\new becomes C: followed by a newline and 'ew' in the rendered intro.
Cause: Builders/HTML/DoxBuilderHTML.lua:122 escapes backticks and interpolation
markers in the intro but not backslashes. The intro is inserted into a
JavaScript template literal, so \n is interpreted instead of preserved.
This file checks the emitted escape sequence. During review, the generated
intro template was also evaluated with Node.js and confirmed to lose the path.
No Node.js dependency is needed to run this standalone reproduction.
]]
RunTest("HTML intro escapes a literal Windows path", function()
    local oDox = DoxLua("Dox intro path");
    oDox.setIntro("<p>C:\\new</p>");
    oDox.refresh();
    local sHTML = CaptureExport(oDox);
    local bEscaped = sHTML:find("<p>C:\\\\new</p>", 1, true) ~= nil;
    print("Expected generated JavaScript: a doubled backslash in the intro path.");
    print("Actual doubled backslash present: "..tostring(bEscaped));
    return bEscaped;
end);

--==============================================================================
--============================== FQXN output validity ==========================
--==============================================================================
--[[NOTE:
Expected: a quoted FQXN is either rejected as unsupported input or escaped so
its generated JavaScript remains valid. Accepted input must not break the page.
Current: @fqxn A"B is accepted and exported as an unescaped quoted object key,
which makes the generated JavaScript invalid.
Cause: Builders/HTML/DoxBuilderHTML.lua:178 only encodes spaces in keys; it
inserts the rest of the FQXN directly between double quotes.
During review, generated inline JavaScript was syntax-checked with Node.js:
the ordinary-name control passed; the quoted-name case failed to compile.
The standalone test detects the reproduced unescaped key without needing Node.
]]
RunTest("Accepted FQXNs do not generate an unescaped quoted key", function()
    local oDox = DoxLua("Dox quoted FQXN");
    local bAccepted, vResult = pcall(function()
        ImportLua(oDox, '--[[! @fqxn A"B @desc quoted name !]]');
        oDox.refresh();
        return CaptureExport(oDox);
    end);
    print("Expected: reject this name or emit valid escaped JavaScript.");
    print("Input accepted and exported: "..tostring(bAccepted));

    if (not bAccepted) then
        print("Input rejected: "..tostring(vResult));
        return true;
    end

    local bBadKey = vResult:find('"A"B": {', 1, true) ~= nil;
    print("Actual unescaped quoted key present: "..tostring(bBadKey));
    return not bBadKey;
end);

--==============================================================================
--============================== Pulsar builder completion =====================
--==============================================================================
--[[NOTE:
Expected: the selected Pulsar Lua builder exports the documented function in a
complete JSON document for the completion file.
Current: the export is only the opening JSON wrapper; it contains neither the
function entry nor the closing object braces. This is unfinished functionality,
not a claim that a previously completed builder regressed.
Cause: Builders/Pulsar/Lua/DoxBuilderPulsarLua.lua:247-258, build starts with
_sOutputWrapperPre, its output-append loop is commented out, and it returns
without appending _sOutputWrapperPost. refresh also prints debug data.
]]
RunTest("Pulsar export includes entries and a complete document", function()
    local oDox = DoxLua("Dox Pulsar output");
    oDox.setBuilder(Dox.BUILDER.PULSAR_LUA);
    ImportLua(oDox,
        "--[[! @fqxn Sample.work @desc Work here @pulsarlua function Sample.work !]]");
    oDox.refresh();
    local sOutput = CaptureExport(oDox);
    local bEntryPresent = sOutput:find('"work"', 1, true) ~= nil;
    local bClosed = sOutput:match("}%s*$") ~= nil;
    print("Expected: function entry and closing JSON braces.");
    print("Actual output bytes: "..tostring(#sOutput));
    print("Function entry present: "..tostring(bEntryPresent));
    print("Document ends with a closing brace: "..tostring(bClosed));
    return bEntryPresent and bClosed;
end);

print("\nNormal controls failed: "..tostring(nControlsFailed));
print("Dox failure reproductions: "..tostring(nFailed));
