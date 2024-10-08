--[[!
@fqxn LuaEx.Libraries.envrepo
@desc The Environment Repository is a module providing a mechanism for managing and retrieving Lua environments.
      It allows for the registration of multiple environments indexed by string keys,
      with a default environment set to the global environment. Users can retrieve
      the default environment, set a new one, and add new environments while
      preventing overwriting existing ones.
@ex
    -- Retrieve the default environment
    local tDefaultEnv = envrepo.getDefault();

    -- Can also get the default like this
    local tAlsoDefaultEnv = envrepo._ENV;

    -- Show their equality
    print(tDefaultEnv == tAlsoDefaultEnv); --> true

    -- Create a new environment table
    envrepo.restricted = {
        print = print,
    };

    -- Store the old env
    local wOld = envrepo._ENV;

    -- Create and test the new env
    _ENV = envrepo.restricted;
    print("Hello"); --> Hello
    print(math) --> nil

    -- Restore the old env
    _ENV = wOld;
!]]

local _sDefaultName = "_ENV"; --NOTE: if this is changed, be sure to update the documentation.
local _wDefault     = _ENV;

local tRepo;
tRepo = {
    envs = { --repo table for all env. Index by string, values are env tables
        [_sDefaultName] = _wDefault, --default env when none is provided by functions/classes/etc. that use this module
    },

    --[[!
    @fqxn LuaEx.Libraries.envrepo.Methods.getDefault
    @desc Returns the default environment from the environment repository.
          This method provides access to the global environment, which is
          used when no specific environment is specified in functions or
          classes that utilize this module.
    @ex
    --get the default environment using the getDefault method
    local wDefault = envrepo.getDefault();

    --the default environment can also be accessed using the index, _ENV
    local wAlsoDefault = envrepo._ENV;

    print(wDefault == wAlsoDefault); --> true

    @return table wEnv The default environment is the loading environment of this module <i>(_ENV)</i> unless another is set as default.
    !]]
    getDefault = function()
        return tRepo.envs[_sDefaultName];
    end,

    --[[!
    @fqxn LuaEx.Libraries.envrepo.Methods.getDefaultName
    @desc Returns the name of the default environment in the environment repository.
          This method provides a way to retrieve the identifier for the default
          environment, which can be useful for reference or logging purposes.
    @ret string sEnv The name of the default environment.
    !]]
    getDefaultName = function()
        return _sDefaultName;
    end,

    --[[!
    @fqxn LuaEx.Libraries.envrepo.Methods.setDefault
    @desc Sets the default environment for the repository. This method checks if the specified
          environment name corresponds to an existing environment and updates the default if valid.
          If the specified environment does not exist, the default environment remains unchanged.
    @param string sEnv The name of the environment to be set as the default.
    !]]
    setDefault = function(sEnv)
        local bRet      = false;
        tRepo.envs[_sDefaultName] = type(tRepo.envs[k]) == "table" and tRepo.envs[k] or _wDefault;
    end,
};
local tRepoDecoy    = {};
local tRepoMeta     = {
    __index = function(t, k)
        return tRepo.envs[k] or tRepo[k] or nil;
    end,
    __newindex = function(t, k, v) --registers a new env (does not allow overwrite)
        --local bRet = false;

        if (type(k) == "string" and k:find("%S+") and
            k ~= _sDefaultName  and
            type(v) == "table"  and tRepo.envs[k] == nil) then
            tRepo.envs[k] = v; --WARNING: do NOT attempt to clone the env here (or anywhere)
            --bRet = true; --indicate the addition was successful
        end

        --return bRet; --indicate to the user whether the env was added
    end,
    __pairs = function()
        return next, tRepo.envs, nil;
    end,
    __type = "envrepo",
};

setmetatable(tRepoDecoy, tRepoMeta);

return tRepoDecoy;
