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
@desc
<div class="text-center" style="margin: 20px;">
    <div class="alert" style="background-color: #CCDC90; color: #333333; border-radius: 15px; padding: 10px; display: inline-block;">
        <b>Overview of the Rarity Class</b>
        <br>
        The Rarity class is a static helper class and defines the properties and characteristics of objects based on their rarity levels.
        The system is flexible, allowing for easy customization through a configuration table.
        Each rarity level is associated with unique attributes, which can impact gameplay, item appearance, and player experience.
    </div>
</div>

<table class="table table-bordered">
    <thead>
        <tr>
            <th style="background-color: #CCDC90; color: #000000;">Aspect</th>
            <th style="background-color: #CCDC90; color: #000000;">Description</th>
        </tr>
    </thead>
    <tbody style="background-color: #3F3F3F; color: #DCDCCC;">
        <tr>
            <td><b>Affix System</b></td>
            <td>Defines the maximum tier of affixes applicable to items, influencing their capabilities and attributes.</td>
        </tr>
        <tr>
            <td><b>Rarity Levels</b></td>
            <td>Specifies multiple rarity levels, each with distinct characteristics affecting item drop rates, appearances, and enhancements.</td>
        </tr>
        <tr>
            <td><b>Color Coding</b></td>
            <td>Each rarity level can have an associated color for visual differentiation in the UI, enhancing user experience.</td>
        </tr>
        <tr>
            <td><b>Chance Mechanism</b></td>
            <td>Establishes the probability of obtaining items of varying rarities, allowing for balanced item distribution.</td>
        </tr>
        <tr>
            <td><b>Affix Tiers</b></td>
            <td>Sets the minimum and maximum affix tiers for each rarity level, impacting the potential power and utility of items.</td>
        </tr>
        <tr>
            <td><b>Prefix and Suffix Ranges</b></td>
            <td>Defines the range of prefixes and suffixes that can be assigned to items, further diversifying their properties and effects.</td>
        </tr>        
    </tbody>
</table>

@note
The Rarity system's configuration is designed for customization on a per-game basis, enabling developers to establish unique rarity systems tailored to their specific game mechanics and aesthetics. However, once the game is running, the configuration data is immutable and cannot be altered during gameplay. This intentional design choice ensures that the rarity framework remains stable and consistent, preventing any tampering or unintended modifications while the game is in execution. By restricting changes to the configuration file outside of gameplay, developers can maintain the integrity of the game's mechanics, fostering a reliable experience for players.
!]]
return class("Rarity",
{--METAMETHODS

},
{--STATIC PUBLIC
    --NOTE: Docs in config file.
    LEVEL = enum("Rarity.LEVEL", _tLevel, nil, true),

    --[[!
    @fqxn CoG.Rarity.Methods.getColor
    @desc The color associated with the input Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> as defined in CoG's <a href="#CoG.Config">config</a> file.
    @vis Public Static
    @param Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a>.
    @ret string sColor The hex value of the color of the Rarity.
    !]]
    getColor = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tColor[eLevel.value];
    end,

    --[[!
    @fqxn CoG.Rarity.Methods.getChance
    @desc The frequency of occurrence associated with the input Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> as defined in CoG's <a href="#CoG.Config">config</a> file.
    @vis Public Static
    @param Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a>.
    @ret number nChance The numeric value of the chance of this Rarity occurring.
    !]]
    getChance = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tChance[eLevel.value];
    end,

    --[[!
    @fqxn CoG.Rarity.Methods.getMinAffixTier
    @desc The minimum permitted <href="#CoG.Affix">Affix</a> <a href="#CoG.Rarity.Enums.TIER">TIER</a> associated with the input Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> as defined in CoG's <a href="#CoG.Config">config</a> file.
    @vis Public Static
    @param Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a>.
    @ret TIER eTier The minimum Affix TIER permitted on an object of the given Rarity level.
    !]]
    getMinAffixTier = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinAffixTier[eLevel.value];
    end,

    --[[!
    @fqxn CoG.Rarity.Methods.getMaxAffixTier
    @desc The maximum permitted <href="#CoG.Affix">Affix</a> <a href="#CoG.Rarity.Enums.TIER">TIER</a> associated with the input Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> as defined in CoG's <a href="#CoG.Config">config</a> file.
    @vis Public Static
    @param Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a>.
    @ret TIER eTier The maximum Affix TIER permitted on an object of the given Rarity level.
    !]]
    getMaxAffixTier = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxAffixTier[eLevel.value];
    end,

    --[[!
    @fqxn CoG.Rarity.Methods.getMinPrefixCount
    @desc The minimum number of <a href="#CoG.Affix.Enums.TYPE">Prefixes</a> <href="#CoG.Affix">Affix</a> permitted for the input Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> as defined in CoG's <a href="#CoG.Config">config</a> file.
    @vis Public Static
    @param Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a>.
    @ret number nMinPrefixes The minimum number of Prefixes required to be on an object of the given Rarity level (if Affixes are present).
    !]]
    getMinPrefixCount = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinPrefix[eLevel.value];
    end,

    --[[!
    @fqxn CoG.Rarity.Methods.getMaxPrefixCount
    @desc The maximum number of <a href="#CoG.Affix.Enums.TYPE">Prefixes</a> <href="#CoG.Affix">Affix</a> permitted for the input Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> as defined in CoG's <a href="#CoG.Config">config</a> file.
    @vis Public Static
    @param Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a>.
    @ret number nMinPrefixes The maximum number of Prefixes permitted to be on an object of the given Rarity level (if Affixes are present).
    !]]
    getMaxPrefixCount = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxPrefix[eLevel.value];
    end,

    --[[!
    @fqxn CoG.Rarity.Methods.getMinSuffixCount
    @desc The minimum number of <a href="#CoG.Affix.Enums.TYPE">Suffixes</a> <href="#CoG.Affix">Affix</a> permitted for the input Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> as defined in CoG's <a href="#CoG.Config">config</a> file.
    @vis Public Static
    @param Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a>.
    @ret number nMinPrefixes The minimum number of Suffixes required to be on an object of the given Rarity level (if Affixes are present).
    !]]
    getMinSuffixCount = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMinSuffix[eLevel.value];
    end,

    --[[!
    @fqxn CoG.Rarity.Methods.getMaxSuffixCount
    @desc The maximum number of <a href="#CoG.Affix.Enums.TYPE">Suffixes</a> <href="#CoG.Affix">Affix</a> permitted for the input Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> as defined in CoG's <a href="#CoG.Config">config</a> file.
    @vis Public Static
    @param Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a>.
    @ret number nMinPrefixes The maximum number of Suffixes permitted to be on an object of the given Rarity level (if Affixes are present).
    !]]
    getMaxSuffixCount = function(eLevel)
        type.assert.custom(eLevel, "Rarity.LEVEL");
        return _tMaxSuffix[eLevel.value];
    end,

    --[[!
        @fqxn CoG.Rarity.Methods.getRandom
        @desc This method selects a Rarity LEVEL based on a random roll against defined occurrence frequencies for each rarity. It rolls a random percentage and iterates through the rarity levels from highest to lowest, comparing the roll to the adjusted chance of each rarity. If the roll is less than or equal to the chance (plus any adjustment), the method selects that rarity level. A negative adjustment value increases the likelihood of obtaining a higher rarity, while a positive adjustment value decreases it.
        @vis Public Static
        @param number|nil nAdjustment An optional numeric adjustment to the chance roll. Negative values enhance the chance for higher rarities, while positive values diminish it.
        @return Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> determined based on the random roll and any adjustments made.
    !]]
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
