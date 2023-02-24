local type      = type;
local rawtype   = rawtype;

local tEnv = {
    assert          = assert,
    error           = error,
    ipairs          = ipairs,
    next            = next,
    pairs           = pairs,
    print           = print,
    select          = select,
    metatable       = metatable,
    tonumber        = tonumber,
    tostring        = tostring,
    type            = type,
    xpcall          = xpcall,
};

local import = function(_, pFile)
    local _ENV = tEnv;
    require(pFile:gsub(""));
end

return setmetatable{
    {
    allow = function(sName, vValue)

        if (rawtype(sName) == "string" and #string > 0 and rawtype(vValue) ~= "nil") then
            tEnv[sName] = vValue;
        end

    end,
    disallow = function(sName)
        if (rawtype(sName) == "string" and rawtype(tEnv[sName]) ~= "nil") then
            tEnv[sName] = vValue;
        end
    end,
    },
    {
        _call = import,
    },
};
