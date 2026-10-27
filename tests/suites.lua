--[[!
    @fqxn Tests.Suites
    @desc Defines the current core release checks and records unavailable legacy
    coverage explicitly. Missing core files are failures, never automatic skips.
!]]
local tSuites = {};

for nLevel = 0, 5 do
    tSuites[#tSuites + 1] = {name = "load-"..nLevel, file = "tests/load_regression.lua", level = nLevel};
end

tSuites[#tSuites + 1] = {name = "load-options", file = "tests/load_regression.lua", level = "options"};

for _, tCase in ipairs({
    {"collections", "collections_regression.lua"},
    {"class-scope", "class_scope_regression.lua"},
    {"eventrix", "eventrix_regression.lua"},
    {"io-listing", "io_listing_regression.lua"},
    {"metahook", "metahook_regression.lua"},
    {"primitives", "primitive_copy_regression.lua"},
    {"stringhook", "stringhook_regression.lua"},
    {"xml", "xml_regression.lua"},
    {"prettylua", "prettylua_regression.lua"},
    {"serializer", "cog_serializer_contract.lua"},
    {"vfs", "vfs_regression.lua"},
}) do
    tSuites[#tSuites + 1] = {name = tCase[1], file = "tests/"..tCase[2]};
end

return {
    core = tSuites,
    unavailable = {
        "CoG, inventory, cards, affixes, mods, vehicles, status tracking and Tiled: implementation modules are absent from this checkout.",
        "Dox parsing and export: implementation modules are absent from this checkout.",
    },
};
