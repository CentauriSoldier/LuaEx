-- Define the restricted environment
local tEnvRestricted = {--TODO update with new luaex functions too
    -- Basic functions
    assert = assert,
    error = error,
    ipairs = ipairs,
    next = next,
    pairs = pairs,
    pcall = pcall,
    print = print,
    select = select,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    unpack = unpack or table.unpack,
    xpcall = xpcall,

    -- String functions
    string = {
        byte = string.byte,
        char = string.char,
        find = string.find,
        format = string.format,
        gmatch = string.gmatch,
        gsub = string.gsub,
        len = string.len,
        lower = string.lower,
        match = string.match,
        rep = string.rep,
        reverse = string.reverse,
        sub = string.sub,
        upper = string.upper,
    },

    -- Table functions
    table = {
        insert = table.insert,
        remove = table.remove,
        sort = table.sort,
        concat = table.concat,
        unpack = table.unpack,
    },

    -- Math functions
    math = {
        abs = math.abs,
        acos = math.acos,
        asin = math.asin,
        atan = math.atan,
        ceil = math.ceil,
        cos = math.cos,
        deg = math.deg,
        exp = math.exp,
        floor = math.floor,
        fmod = math.fmod,
        huge = math.huge,
        log = math.log,
        max = math.max,
        min = math.min,
        modf = math.modf,
        pi = math.pi,
        rad = math.rad,
        random = math.random,
        randomseed = math.randomseed,
        sin = math.sin,
        sqrt = math.sqrt,
        tan = math.tan,
    },

    -- Coroutine functions
    coroutine = {
        create = coroutine.create,
        resume = coroutine.resume,
        running = coroutine.running,
        status = coroutine.status,
        wrap = coroutine.wrap,
        yield = coroutine.yield,
    }
}

local function copytable(t)
    local tRet = {};

    for k, v in pairs(t) do
        tRet[k] = type(v) == "table" and copytable(v) or v;
    end

    return tRet;
end

local safeenv = {

    append = function(vItem)

    end,

    get = function()
        return copytable(tEnvRestricted);
    end,

    -- Function to safely load and execute code
    load = function(sCode)

        local fFunction, sError = load(sCode, nil, "t", tEnvRestricted);

        if not fFunction then
            error("Failed to load code: " .. sError);
        end

        return fFunction;
    end,
};
