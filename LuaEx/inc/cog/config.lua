--[[!
    @fqxn CoG.Config
    @pulsarlua table luaex.cog.config
    @desc Assembles bundled CoG defaults, then overlays an optional user config.lua.
    The loader always calls this bundled file. A positive config-parent level locates
    the user's config.lua above LuaEx/inc/cog; zero uses bundled defaults alone.
    User files return ordinary tables containing only the settings they override.
    Ordinary overrides apply recursively to existing keys only, including list indices.
    A user table whose metatable contains __purge = true replaces that branch with its supplied
    contents, allowing new keys and shorter lists. The marker is not runtime data.
    The final table and its ordinary subtables are read-only at runtime.
!]]
local _sConfigModule, _tConfigOptions = ...; -- require may supply a filename as its second argument.
local _pUserDirectory = rawtype(_tConfigOptions) == "table" and _tConfigOptions.userDirectory or nil;

-- __purge is an optional boolean metavalue on the user table's actual metatable.
-- false behaves like omission; other values are rejected rather than treated as truthy.
local function purgesDefaults(tInput)
    -- Read the actual metatable even when __metatable protects normal inspection.
    -- rawget avoids interpreting an inherited __index result as a declared metavalue.
    local tMeta = debug.getmetatable(tInput);
    local bPurge = tMeta and rawget(tMeta, "__purge");

    return rawtype(bPurge) == "boolean" and bPurge or false;
end

-- Copy data without changing cached defaults or caller-owned user tables.
-- Typed values, including enum members, retain their own framework identity.
-- User metatables are not copied, so purge instructions do not become runtime settings.
local function copySettings(vInput, tCopies, bUserConfig)

    if (type(vInput) ~= "table") then
        return vInput;
    end

    if (not tCopies[vInput]) then
        local tOutput = {};
        tCopies[vInput] = tOutput;

        if (bUserConfig) then
            purgesDefaults(vInput);
        end

        for k, v in pairs(vInput) do

            tOutput[k] = copySettings(v, tCopies, bUserConfig);
        end
    end

    return tCopies[vInput];
end

-- Merge into a copy of the defaults. Ordinary tables affect matching keys only;
-- a marked child may introduce a new branch because it supplies that branch in full.
-- Track source/destination pairs so cyclic or shared settings can be visited safely.
local function applySettings(tConfig, tUserConfig, tCopies, tMerged)

    if (purgesDefaults(tUserConfig) or type(tConfig) ~= "table") then
        return copySettings(tUserConfig, tCopies, true);
    end

    local tDestinations = tMerged[tUserConfig];

    if (not tDestinations) then
        tDestinations = {};
        tMerged[tUserConfig] = tDestinations;
    elseif (tDestinations[tConfig]) then
        return tConfig;
    end

    tDestinations[tConfig] = true;

    for k, v in pairs(tUserConfig) do

        local vCurrent = tConfig[k];
        local bUserTable = type(v) == "table";

        -- Test against nil so an existing false setting still counts as a matching key.
        if (vCurrent ~= nil or (bUserTable and purgesDefaults(v))) then

            if (bUserTable) then
                tConfig[k] = applySettings(vCurrent, v, tCopies, tMerged);
            else
                tConfig[k] = v;
            end
        end
    end

    return tConfig;
end

-- Always load the framework's adjacent section modules, never the user's directory.
local tConfig = {
    app           = require(_sConfigModule..".app"),
    AStar         = require(_sConfigModule..".AStar"),
    Pool          = require(_sConfigModule..".Pool"),
    BaseObject    = require(_sConfigModule..".BaseObject"),
    BaseVehicle   = require(_sConfigModule..".BaseVehicle"),
    BaseMod       = require(_sConfigModule..".BaseMod"),
    Rarity        = require(_sConfigModule..".Rarity"),
    StatusTracker = require(_sConfigModule..".StatusTracker"),
};

if (_pUserDirectory ~= nil) then
    -- The LuaEx loader validates the optional filename before framework initialization.
    local sUserFilename = _tConfigOptions.userFilename or "config.lua";
    local pUserConfigFile = _pUserDirectory.."/"..sUserFilename;
    local userConfigLoader, sError = loadfile(pUserConfigFile);
    assert(userConfigLoader, "Unable to load CoG user config at '"..pUserConfigFile.."': "..tostring(sError));

    -- Retain the module/directory arguments for user assemblers that load adjacent sections.
    local tUserConfig = userConfigLoader(_sConfigModule, {directory = _pUserDirectory});
    type.assert.custom(tUserConfig, "table", "CoG user config at '"..pUserConfigFile.."' must return a table.");
    -- Merge against independent defaults, then let a marker replace only its own branch.
    tConfig = applySettings(copySettings(tConfig, {}, false), tUserConfig, {}, {});
end

-- Snapshot the assembled settings once. The independent read-only result leaves
-- both cached default sections and the user's original table untouched.
return table.readonly(tConfig);
