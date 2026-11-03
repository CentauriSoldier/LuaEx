--[[!
@fqxn Tests.PrettyLua
@desc Checks formatting against the maintained runtime corpus without executing formatted sources.
    Parsing, executable token bytes and formatting idempotence must all agree.
!]]
local pretty = require("LuaEx.util.prettylua");
local scan = require("LuaEx.lib.lxc.Tokens").scan;
local _nChecks = 0;
local function check(bCondition, sMessage)
    assert(bCondition, sMessage);
    _nChecks = _nChecks + 1;
end
local _tCorpus = {
    "LuaEx/constants.lua",
    "LuaEx/libext/schema.lua",
    "LuaEx/hook/iohook.lua",
    "LuaEx/hook/math/geometry.lua",
    "LuaEx/hook/mathhook.lua",
    "LuaEx/hook/metahook.lua",
    "LuaEx/hook/stringhook.lua",
    "LuaEx/hook/tablehook.lua",
    "LuaEx/hook/typehook.lua",
    "LuaEx/lib/array.lua",
    "LuaEx/lib/base64.lua",
    "LuaEx/lib/cloner.lua",
    "LuaEx/lib/constant.lua",
    "LuaEx/lib/directive.lua",
    "LuaEx/lib/directives.lua",
    "LuaEx/lib/directives/Diagnostics.lua",
    "LuaEx/lib/directives/Parser.lua",
    "LuaEx/lib/directives/Registry.lua",
    "LuaEx/lib/directives/Selection.lua",
    "LuaEx/lib/enum.lua",
    "LuaEx/lib/envrepo.lua",
    "LuaEx/lib/eventrix.lua",
    "LuaEx/lib/infusedhelp.lua",
    "LuaEx/lib/interface.lua",
    "LuaEx/lib/lxc.lua",
    "LuaEx/lib/lxc/Compiler.lua",
    "LuaEx/lib/lxc/Context.lua",
    "LuaEx/lib/lxc/Diagnostics.lua",
    "LuaEx/lib/lxc/Directives.lua",
    "LuaEx/lib/lxc/Environment.lua",
    "LuaEx/lib/lxc/Facades.lua",
    "LuaEx/lib/lxc/GraphAccess.lua",
    "LuaEx/lib/lxc/GraphClone.lua",
    "LuaEx/lib/lxc/Helpers.lua",
    "LuaEx/lib/lxc/Host.lua",
    "LuaEx/lib/lxc/HostGraph.lua",
    "LuaEx/lib/lxc/HostStaged.lua",
    "LuaEx/lib/lxc/Literal.lua",
    "LuaEx/lib/lxc/Loader.lua",
    "LuaEx/lib/lxc/LuaScope.lua",
    "LuaEx/lib/lxc/Model.lua",
    "LuaEx/lib/lxc/Names.lua",
    "LuaEx/lib/lxc/Operators.lua",
    "LuaEx/lib/lxc/Parser.lua",
    "LuaEx/lib/lxc/Persistence.lua",
    "LuaEx/lib/lxc/Runtime.lua",
    "LuaEx/lib/lxc/SnapshotHooks.lua",
    "LuaEx/lib/lxc/SnapshotSchema.lua",
    "LuaEx/lib/lxc/Tokens.lua",
    "LuaEx/lib/lxc/Validation.lua",
    "LuaEx/lib/lxe.lua",
    "LuaEx/lib/lxe/Extensions.lua",
    "LuaEx/lib/lxe/Loader.lua",
    "LuaEx/lib/lxe/Parser.lua",
    "LuaEx/lib/lxe/Persistence.lua",
    "LuaEx/lib/lxe/Registry.lua",
    "LuaEx/lib/lxe/Runtime.lua",
    "LuaEx/lib/lxe/Tokens.lua",
    "LuaEx/lib/lxe/Validation.lua",
    "LuaEx/lib/null.lua",
    "LuaEx/lib/qr.lua",
    "LuaEx/lib/serializer.lua",
    "LuaEx/lib/stdlib.lua",
    "LuaEx/lib/strata.lua",
    "LuaEx/lib/struct.lua",
    "LuaEx/lib/textcatalog.lua",
    "LuaEx/init.lua",
    "LuaEx/primitives/circle.lua",
    "LuaEx/primitives/circlearc.lua",
    "LuaEx/primitives/ellipse.lua",
    "LuaEx/primitives/info.lua",
    "LuaEx/primitives/line.lua",
    "LuaEx/primitives/point.lua",
    "LuaEx/primitives/polygon.lua",
    "LuaEx/util/isotominutes.lua",
    "LuaEx/util/prettylua.lua",
    "LuaEx/util/source.lua",
};

for _, pFile in ipairs(_tCorpus) do
    local hFile = assert(io.open(pFile, "rb"));
    local sSource = hFile:read("*a");
    hFile:close();
    local sFormatted, sReason = pretty(sSource);
    check(sFormatted ~= nil, pFile..": "..tostring(sReason));
    check(load(sFormatted, "@formatted-corpus", "t", {}) ~= nil, pFile..": formatted syntax");
    local tOriginal, tFormatted = scan(sSource, pFile), scan(sFormatted, pFile);
    check(#tOriginal == #tFormatted, pFile..": token count");
    for nIndex, tToken in ipairs(tOriginal) do
        check(tToken.Text == tFormatted[nIndex].Text and tToken.Kind == tFormatted[nIndex].Kind,
            pFile..": executable token "..nIndex);
    end
    check(pretty(sFormatted) == sFormatted, pFile..": formatting is idempotent");
end
for _, sInvalid in ipairs({"local = 1", "function broken(", "local x = 'unfinished", "if true then", "return 1 +"}) do
    local sFormatted, sReason = pretty(sInvalid);
    check(sFormatted == nil and type(sReason) == "string", "Malformed source rejected");
end
for _, value in ipairs({false, 1, {}}) do
    check(pretty(value) == nil, "Non-string formatting input rejected");
end
check(pretty(nil) == nil, "Nil formatting input rejected");
print("PASS prettyLua: ".._nChecks.." checks across "..#_tCorpus.." source files.");
