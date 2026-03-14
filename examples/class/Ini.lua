--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
local sSourcePath = "";
if not (LUAEX_INIT) then
    --sSourccePath = "";

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
    package.path = package.path..";"..sSourcePath.."\\..\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================

-- =========================
-- TEST INPUTS
-- =========================

local sINI1 = [[
# top comment
; another top comment

[General]
Name = Skystrike
Version = 1
Enabled = true

[Style]
Family = Times New Roman
Size = 18
Color = 255, 255, 255, 255
]]

local sINI2 = "[General]\nName = Test\n"

local sINI3 = [[
[General]
Name = A

[General]
Name = B
]]

local sINI4 = [[
[General]
Name = A
Name = B
]]

local sINI5 = [[
[General]
ThisIsBad
]]

-- =========================
-- BASIC TEST RUNNER
-- =========================

local function Test(sName, fn)
    local bOK, vErr = pcall(fn);

    if (bOK) then
        print("[PASS] "..sName);
    else
        print("[FAIL] "..sName);
        print(tostring(vErr));
    end

    print("----------------------------------------");
end

-- =========================
-- TESTS
-- =========================

Test("Round-trip with comments, blanks, sections, values", function()
    local oIni = Ini(sINI1);
    local sOut = tostring(oIni);

    print("INPUT:");
    print(sINI1);
    print("OUTPUT:");
    print(sOut);
end);

Test("Preserve ending newline true", function()
    local oIni = Ini(sINI2);
    local sOut = tostring(oIni);

    print("Raw output ends with newline:", sOut:match("\n$") ~= nil);
    print("Output:");
    print(sOut);
end);

Test("Deserialize from serialized table", function()
    local oIni1 = Ini(sINI1);
    local tData = oIni1.serialize and oIni1.serialize() or nil;

    if not (tData) then
        error("serialize() method not available through your class system.");
    end

    local oIni2 = Ini.deserialize(tData);

    print("Original:");
    print(tostring(oIni1));
    print("Deserialized:");
    print(tostring(oIni2));
end);

Test("Duplicate section should error", function()
    local oIni = Ini(sINI3);
    print(tostring(oIni));
end);

Test("Duplicate value in same section should error", function()
    local oIni = Ini(sINI4);
    print(tostring(oIni));
end);

Test("Malformed line should error", function()
    local oIni = Ini(sINI5);
    print(tostring(oIni));
end);

Test("Construct from table directly", function()
    local oIni = Ini({
        top = {
            { prefix = "#", coupler = " ", suffix = "hello", rawIndex = 1 },
            { prefix = "",  coupler = "",  suffix = "",      rawIndex = 2 },
        },
        sectionOrder = { "General" },
        sections = {
            General = {
                ordinal = 1,
                lines = {
                    { prefix = "Name",    coupler = " = ", suffix = "Skystrike", rawIndex = 3 },
                    { prefix = "Version", coupler = " = ", suffix = "1",         rawIndex = 4 },
                },
            },
        },
        endingLine = true,
    });

    print(tostring(oIni));
end);
