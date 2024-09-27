--used to handle environments

local tRepo;
tRepo = {
    envs = { --repo table for all env. Index by string, values are env tables
        _DEFAULT = _G, --default env when none is provided by functions/classes/etc. that use this module
    },
    getDefault = function()
        return tRepo.envs._DEFAULT;
    end,
    getDefaultName = function()
        return "_DEFAULT";
    end,
    setDefault = function(wEnv)
        local bRet = false;

        if (type(wEnv) == "table") then
            tRepo.envs._DEFAULT = wEnv;
        end

    end,
};
local tRepoDecoy    = {};
local tRepoMeta     = {
    index = function(t, k)
        return tRepo.envs[k] or nil;
    end,
    newindex = function(t, k, v) --registers a new env (does not allow overwrite)
        local bRet = false;

        if (type(k) == "string" and k:find("%S+") and
            type(v) == "table"  and tRepo.envs[k] == nil) then
            tRepo.envs[k] = v; --WARNING: do NOT attempt to clone the env here (or anywhere)
            bRet = true; --indicate the addition was successful
        end

        return bRet; --indicate to the user whether the env was added
    end,
    __type = "envrepo",
};

setmetatable(tRepoDecoy, tRepoMeta);

return tRepoDecoy;
