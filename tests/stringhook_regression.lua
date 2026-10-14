if (not LUAEX_INIT) then
    require("LuaEx.init");
end

assert(string.cap("") == "" and string.cap("a") == "A");
assert(string.cap("hELLO", true) == "Hello");
local sText, nItems, tItems = string.capall("alpha::beta::gamma", "::");
assert(sText == "Alpha::Beta::Gamma" and nItems == 3 and tItems[1] == "alpha");
sText, nItems, tItems = string.capall(" \t\n");
assert(sText == "" and nItems == 0 and #tItems == 0);
assert(string.collapse("a \t b\nc") == "abc");
assert(string.trim(" \t test \n") == "test");
assert(string.trimleft("  test  ") == "test  ");
assert(string.trimright("  test  ") == "  test");
assert(string.trimright(" \t\n") == "");
assert(string.isempty("") and string.isempty(" \t\n"));
assert(not string.isempty(" x ") and not string.isempty(nil));

for _, sNumber in ipairs({ "0", "-2", "+3.5", ".5", "1e3", "0xFF", " 12 " }) do
    assert(string.isnumeric(sNumber));
end

for _, sNumber in ipairs({ "", " ", ".", "1.2.3", "abc" }) do
    assert(not string.isnumeric(sNumber));
end

assert(not string.isnumeric(12));
assert(string.isdatevalid("2024-02-29") == true);
assert(string.isdatevalid("2000-02-29") == true);
assert(string.isdatevalid("1900-02-29") == false);
assert(string.isdatevalid("2026-04-31") == false);
assert(string.isdatevalid("2026-00-01") == false);
assert(string.isdatevalid("2026-01-00") == false);
assert(string.isdatevalid("bad") == false and string.isdatevalid(nil) == false);
assert(string.iskeyword("end") and not string.iskeyword("End"));
assert(not string.isvariablecompliant("end"));
assert(string.isvariablecompliant("end", true));
assert(string.isvariablecompliant("_MyVariable2"));
assert(not string.isvariablecompliant("2bad") and not string.isvariablecompliant(nil));

local tSplit = string.totable("::a::::b::", "::", true);
assert(#tSplit == 5 and tSplit[1] == "" and tSplit[3] == "" and tSplit[5] == "");
assert(#string.totable("", ",", false) == 0);
assert(#string.totable("", ",", true) == 1);
assert(#string.totable("a.*b.*c", ".*") == 3);
tSplit = string.totable("1,,2,3", ",", false, function(sItem)
    if (sItem == "2") then
        return nil;
    end

    return tonumber(sItem);
end);
assert(#tSplit == 2 and tSplit[1] == 1 and tSplit[2] == 3);
assert(#stringtotableOLD("a||b", "||") == 2);

assert(string.patterns.missing == nil);
assert(not pcall(function() string.patterns.uuid = "changed"; end));
assert(not pcall(function() string.patterns.extra = "changed"; end));
assert(string.isuuid(string.uuid()));
assert(not string.isuuid(false));
local sUpperUUID = string.uuid(true);
assert(sUpperUUID == sUpperUUID:upper() and string.isuuid(sUpperUUID));
assert(string.tosid("  HeLLo \t world ") == string.tosid("hello world"));
assert(string.htmltomd("<b>Bold</b><br/><i>Italic</i>") == "**Bold**  \n*Italic*");
assert(string.htmltomd("\\<b>literal\\</b>") == "<b>literal</b>");
assert(string.htmltomd("\1".."123".."\2<b>x</b>") == "\1".."123".."\2**x**");
assert(string.htmltomd('<span class="test">x</span>') == '<span class="test">x</span>');

-- Exercise both host naming policies without needing a Windows-native Lua runtime.
local sOriginalConfig = package.config;

for _, sSeparator in ipairs({ "/", "\\" }) do
    package.config = sSeparator..sOriginalConfig:sub(2);
    assert(loadfile("/LuaEx/hook/stringhook.lua"))();
    assert(string.isfilesafe("report.txt"));
    assert(not string.isfilesafe("") and not string.isfilesafe(".") and not string.isfilesafe(".."));
    assert(not string.isfilesafe("path/file") and not string.isfilesafe("a\0b"));
    assert(not string.isfilesafe(string.rep("a", 256)));

    if (sSeparator == "\\") then
        for _, sBad in ipairs({ "CON", "con.txt", "NUL.tar.gz", "COM1.log", "LPT².txt", "trailing.", "space " }) do
            assert(not string.isfilesafe(sBad));
        end
    else
        assert(string.isfilesafe("CON.txt") and string.isfilesafe("trailing."));
    end

    for _, sInput in ipairs({ "", "...", "CON.txt", "COM1", "a/b:c*?", " \t ", string.rep("a", 300) }) do
        local sSafe = string.makefilesafe(sInput);
        assert(sSafe ~= "" and #sSafe <= 255 and string.isfilesafe(sSafe));
    end

    local sUTF8 = string.makefilesafe(string.rep("é", 200));
    assert(#sUTF8 <= 255 and utf8.len(sUTF8) ~= nil);
    assert(#string.makefilesafe("CON."..string.rep("a", 251)) <= 255);
end

package.config = sOriginalConfig;
assert(loadfile("/LuaEx/hook/stringhook.lua"))();
print("PASS stringhook: capitalization, numeric/date/identifier checks, literal splitting, immutable patterns, trimming, filename policies, UUID shape and HTML conversion");
