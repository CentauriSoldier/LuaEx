--[[!
    @fqxn Tests.Suites
    @desc Lists current LuaEx checks. Fresh cases own initialization; other cases
        use the shared bootstrap. Missing configured files are failures.
!]]
local tSuites = {
    {name = "init", file = "tests/load_regression.lua", fresh = true},
    {name = "io-discovery", file = "tests/io_discovery_regression.lua", fresh = true},
};

for _, tCase in ipairs({
    {"collections", "collections_regression.lua"},
    {"class-scope", "class_scope_regression.lua"},
    {"lookup-cache", "environment_lookup_regression.lua"},
    {"native-lxc", "native_lxc_regression.lua"},
    {"eventrix", "eventrix_regression.lua"},
    {"io-listing", "io_listing_regression.lua"},
    {"metahook", "metahook_regression.lua"},
    {"primitives", "primitive_copy_regression.lua"},
    {"stringhook", "stringhook_regression.lua"},
    {"string-runtime", "string_runtime_regression.lua"},
    {"xml", "xml_regression.lua"},
    {"prettylua", "prettylua_regression.lua"},
    {"serializer", "serializer_regression.lua"},
    {"vfs", "vfs_regression.lua"},
    {"directives", "directives_regression.lua"},
    {"enums", "lxe/regression.lua"},
}) do
    tSuites[#tSuites + 1] = {name = tCase[1], file = "tests/"..tCase[2]};
end

return {
    core = tSuites,
    unavailable = {
        "CoG and Dox are separate projects; their modules are not covered by this LuaEx suite.",
    },
};
