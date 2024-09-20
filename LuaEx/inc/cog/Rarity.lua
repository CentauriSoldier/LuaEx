local class             = class;
local clone             = clone;
local enum              = enum;
local rawsetmetatable   = rawsetmetatable;
local type              = type;
local RNG               = RNG;

--get the info from the Cog config file
local _tConfig          = luaex.cog.config;
local _tRarity          = _tConfig.Rarity;
local _tLevel           = _tRarity.LEVEL;
local _tColor           = _tRarity.COLOR;
local _tChance          = _tRarity.CHANCE;
local _tMinAffixTier    = _tRarity.MIN_AFFIX_TIER;
local _tMaxAffixTier    = _tRarity.MAX_AFFIX_TIER;
local _tMinPrefix       = _tRarity.MIN_PREFIX;
local _tMaxPrefix       = _tRarity.MAX_PREFIX;
local _tMinSuffix       = _tRarity.MIN_SUFFIX;
local _tMaxSuffix       = _tRarity.MAX_SUFFIX;

local _nRarityLevels    = #_tLevel;

--[[!
@fqxn CoG.Rarity
@des A static helper class that uses various properites found in the CoG <a href="#CoG.Config">config</a> file to create aspects like LEVEL, COLOR, CHANCE, MIN_TIER, etc. in order to facilitate tracking and interacting with the rarity of an object.
!]]
return class("Rarity",
{--METAMETHODS

},
{--STATIC PUBLIC
    --[[!
    @fqxn CoG.Rarity.Enums.LEVEL
    @desc The rarity level as defined in CoG's <a href="#CoG.Config">config</a> file.
    !]]
    LEVEL       = enum("Rarity.LEVEL",      _tLevel,    nil,            true),
    --[[-!
    @fqxn CoG.Rarity.Enums.
    @desc The COlor level as define in CoG's <a href="#CoG.Config">config</a> file.
    !]]
    --COLOR       = enum("Rarity.COLOR",      _tLevel,    _tColor,        true),
    --[[!
    @fqxn CoG.Rarity.Enums.
    @desc The rarity level as define in CoG's <a href="#CoG.Config">config</a> file.
    !]]
    --CHANCE      = enum("Rarity.CHANCE",     _tLevel,    _tChance,       true),
    --[[-!
    @fqxn CoG.Rarity.Enums.
    @desc The rarity level as define in CoG's <a href="#CoG.Config">config</a> file.
    --!]]
    --MIN_AFFIX_TIER = enum("Rarity.MIN_TIER",   _tLevel,    _tMinAffixTier, true),
    --[[-!
    @fqxn CoG.Rarity.Enums.
    @desc The rarity level as define in CoG's <a href="#CoG.Config">config</a> file.
    !]]
    --MAX_AFFIX_TIER    = enum("Rarity.MAX_TIER",   _tLevel,    _tMaxAffixTier, true),
    --[[-!
    @fqxn CoG.Rarity.Enums.
    @desc The rarity level as define in CoG's <a href="#CoG.Config">config</a> file.
    !]]
    --MIN_PREFIX  = enum("Rarity.MIN_PREFIX", _tLevel,    _tMinPrefix,    true),
    --[[-!
    @fqxn CoG.Rarity.Enums.
    @desc The rarity level as define in CoG's <a href="#CoG.Config">config</a> file.
    !]]
    --MAX_PREFIX  = enum("Rarity.MAX_PREFIX", _tLevel,    _tMaxPrefix,    true),
    --[[-!
    @fqxn CoG.Rarity.Enums.
    @desc The rarity level as define in CoG's <a href="#CoG.Config">config</a> file.
    !]]
    --MIN_SUFFIX  = enum("Rarity.MIN_SUFFIX", _tLevel,    _tMinSuffix,    true),
    --[[-!
    @fqxn CoG.Rarity.Enums.
    @desc The rarity level as define in CoG's <a href="#CoG.Config">config</a> file.
    !]]
    --MAX_SUFFIX  = enum("Rarity.MAX_SUFFIX", _tLevel,    _tMaxSuffix,    true),

    --[[Rarity = function(stapub)
        local tIndices = {"COLOR", "CHANCE", "MIN_AFFIX_TIER", "MAX_AFFIX_TIER", "MIN_PREFIX", "MAX_PREFIX", "MIN_SUFFIX", "MAX_SUFFIX"};

        for nIndex, sLevel in ipairs(_tLevel) do
            stapub[sLevel] = enum("Rarity."..sLevel,
                tIndices,
                {
                _tColor[nIndex],
                _tChance[nIndex],
                _tMinAffixTier[nIndex],
                _tMaxAffixTier[nIndex],
                _tMinPrefix[nIndex],
                _tMaxPrefix[nIndex],
                _tMinSuffix[nIndex],
                _tMaxSuffix[nIndex],
                },
                true);
        end

    end,]]

    getColor = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tColor[eLevel.value];
    end,

    getChance = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tChance[eLevel.value];
    end,

    getMinAffixTier = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinAffixTier[eLevel.value];
    end,

    getMaxAffixTier = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxAffixTier[eLevel.value];
    end,

    getMinPrefixCount = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinPrefix[eLevel.value];
    end,

    getMaxPrefixCount = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxPrefix[eLevel.value];
    end,

    getMinSuffixCount = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinSuffix[eLevel.value];
    end,

    getMaxSuffixCount = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxSuffix[eLevel.value];
    end,

    --chooses the highest given the roll
    --negative nAdjustment is good, positive is bad
    getRandom = function(nAdjustment)
        local eRet = _eLevel[1];
        local nRoll = RNG.percent();
        nAdjustment =    rawtype(nAdjustment) == "number" and
                    (nAdjustment < 0 and nAdjustment or -nAdjustment)
                    or 0;

        for x = _nRarityLevels, 1, -1 do
            local eRarity       = _eLevel[x];
            local nChanceToGet  = _tChance[eRarity];

            if (nRoll <= (nChanceToGet + nAdjustment)) then
                eRet = eRarity;
                break;
            end

        end

        return eRet;
    end,

},
{--PRIVATE
    Rarity = function(this, cdat) end,

},
{--PROTECTED
    --Rarity = function(stapub) end,
},
{--PUBLIC

},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
