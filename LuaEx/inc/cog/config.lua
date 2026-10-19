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
    StatusTracker is an application-defined hierarchy and replaces its section in full.
    The final table and its ordinary subtables are read-only at runtime.
    TIER is a private enum stored in this table, not registered globally. Project
    overrides load first so the selected tier is available to dependent defaults.
    The bundled Rarity section receives that selected enum explicitly.
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

-- Load the project table once before constructing defaults which depend on TIER.
local tUserConfig = {};
if (_pUserDirectory ~= nil) then
    local sUserFilename = _tConfigOptions.userFilename or "config.lua";
    local pUserConfigFile = _pUserDirectory.."/"..sUserFilename;
    local userConfigLoader, sError = loadfile(pUserConfigFile);
    assert(userConfigLoader, "Unable to load CoG user config at '"..pUserConfigFile.."': "..tostring(sError));
    tUserConfig = userConfigLoader(_sConfigModule, {directory = _pUserDirectory});
    type.assert.custom(tUserConfig, "table", "CoG user config at '"..pUserConfigFile.."' must return a table.");
end

-- Typed enum overrides retain identity; do not deep-merge their member objects.
local eTier = tUserConfig.TIER;
if (eTier == nil) then eTier = require(_sConfigModule..".TIER"); end
assert(enum.isenum(eTier), "CoG config TIER must be an enum collection.");

-- Always load framework-adjacent defaults; Rarity must use the selected tier.
local tConfig = {
    TIER          = eTier,
    app           = require(_sConfigModule..".app"),
    AStar         = require(_sConfigModule..".AStar"),
    Pool          = require(_sConfigModule..".Pool"),
    BaseObject    = require(_sConfigModule..".BaseObject"),
    BaseVehicle   = require(_sConfigModule..".BaseVehicle"),
    BaseMod       = require(_sConfigModule..".BaseMod"),
    Rarity        = require(_sConfigModule..".Rarity")(eTier),
    StatusTracker = require(_sConfigModule..".StatusTracker"),
};
tConfig = applySettings(copySettings(tConfig, {}, false), tUserConfig, {}, {});

-- StatusTracker is an application-defined hierarchy, not an overlay of fixed default keys.
if (tUserConfig.StatusTracker ~= nil) then
    type.assert.custom(tUserConfig.StatusTracker, "table", "CoG StatusTracker config must be a table.");
    tConfig.StatusTracker = copySettings(tUserConfig.StatusTracker, {}, true);
end
-- Keep typed enums intact while locking ordinary configuration tables.
return table.readonly(tConfig);
