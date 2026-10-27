--[[!
    @fqxn Tests.RunCase
    @desc Executes exactly one configured suite in a fresh process. Load checks
    run before framework initialization; other checks use the shared test bootstrap.
!]]
local sSource = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local sRoot = (sSource:match("^(.*)/") or ".").."/..";
package.path = sRoot.."/?.lua;"..package.path;
local tSelected;

for _, tSuite in ipairs(require("tests.suites").core) do
    if (tSuite.name == arg[1]) then tSelected = tSuite; break; end
end
assert(tSelected, "Unknown test suite: "..tostring(arg[1]));

if (tSelected.level ~= nil) then
    assert(loadfile(sRoot.."/"..tSelected.file))()(tSelected.level);
else
    require("tests.bootstrap").run(sRoot, tSelected.file);
end
