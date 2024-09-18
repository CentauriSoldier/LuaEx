local class             = class;
local clone             = clone;
local enum              = enum;
local rawsetmetatable   = rawsetmetatable;
local type              = type;
local RNG               = RNG;

--get the info from the Cog config file
local _tConfig          = luaex.cog.config;
local _tRarity          = _tConfig.Rarity;
local _eLevel           = _tRarity.LEVEL;
local _tColor           = _tRarity.COLOR;
local _tChance          = _tRarity.CHANCE;
local _tMinTier         = _tRarity.MIN_TIER;
local _tMaxTier         = _tRarity.MAX_TIER;
local _tMinPrefix       = _tRarity.MIN_PREFIX;
local _tMaxPrefix       = _tRarity.MAX_PREFIX;
local _tMinSuffix       = _tRarity.MIN_SUFFIX;
local _tMaxSuffix       = _tRarity.MAX_SUFFIX;

local _nRarityLevels    = #_eLevel;

return class("Rarity",
{--METAMETHODS

},
{--STATIC PUBLIC
    LEVEL       = enum("Rarity.LEVEL",      _eLevel,    nil,            true),
    COLOR       = enum("Rarity.COLOR",      _eLevel,    _tColor,        true),
    CHANCE      = enum("Rarity.CHANCE",     _eLevel,    _tChance,       true),
    MIN_TIER    = enum("Rarity.MIN_TIER",   _eLevel,    _tMinTier,      true),
    MAX_TIER    = enum("Rarity.MAX_TIER",   _eLevel,    _tMinTier,      true),
    MIN_PREFIX  = enum("Rarity.MIN_PREFIX", _eLevel,    _tMinPrefix,    true),
    MAX_PREFIX  = enum("Rarity.MAX_PREFIX", _eLevel,    _tMaxPrefix,    true),
    MIN_SUFFIX  = enum("Rarity.MIN_SUFFIX", _eLevel,    _tMinSuffix,    true),
    MAX_SUFFIX  = enum("Rarity.MAX_SUFFIX", _eLevel,    _tMinSuffix,    true),


--[[
    getColor = function(this, cdat, eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tColor[eLevel.__value];
    end,

    getChance = function(this, cdat, eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tChance[eLevel.__value];
    end,

    getMinTier = function(this, cdat, eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinTier[eLevel.__value];
    end,

    getMaxTier = function(this, cdat, eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxTier[eLevel.__value];
    end,

    getMinPrefixCount = function(this, cdat, eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinPrefix[eLevel.__value];
    end,

    getMaxPrefixCount = function(this, cdat, eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxPrefix[eLevel.__value];
    end,

    getMinSuffixCount = function(this, cdat, eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinSuffix[eLevel.__value];
    end,

    getMaxSuffixCount = function(this, cdat, eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxSuffix[eLevel.__value];
    end,
]]
    --chooses the highest given the roll
    --negative nAdjustment is good, positive is bad
    getRandom = function(this, cdat, nAdjustment)
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
