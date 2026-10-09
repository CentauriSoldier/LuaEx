local class             = class;
local enum              = enum;
local type              = type;
-- RNG is loaded after Rarity by LuaEx.init; resolve it when getRandom is called.

--get the info from the Cog config file
local _tConfig          = luaex.cog.config;


local function validateList(tList, sField, nExpected)
    local sContext = "Rarity config "..sField;
    type.assert.table(tList, "number", nil, nil, nil, "\n"..sContext);
    local nCount = 0;

    for nIndex in pairs(tList) do

        assert(nIndex >= 1 and nIndex % 1 == 0,
               sContext.." indices must be positive integers.");
        nCount = nCount + 1;
    end

    nExpected = nExpected or nCount;
    assert(nCount == nExpected, sContext.." must have "..nExpected.." entries.");

    -- Counting entries alone cannot detect holes; require every corresponding row.
    for nIndex = 1, nExpected do
        assert(tList[nIndex] ~= nil, sContext.." is missing row "..nIndex..'.');
    end

    return nCount;
end


local function validateNumber(nValue, sContext, bInteger)
    type.assert.number(nValue, nil, nil, nil, nil, nil, nil, nil, "\n"..sContext);
    assert(nValue == nValue and nValue >= 0 and nValue < math.huge,
           sContext.." must be a finite nonnegative number.");
    assert(not bInteger or nValue % 1 == 0, sContext.." must be an integer.");
end


local function validateConfig(tRarity)
    type.assert.table(tRarity, nil, nil, nil, nil, "\nRarity config must be a table.");
    local nLevels = validateList(tRarity.LEVEL, "LEVEL");
    assert(nLevels > 0, "Rarity config LEVEL must contain at least one level.");

    local tFields = {"COLOR", "CHANCE", "MIN_AFFIX_TIER", "MAX_AFFIX_TIER",
                     "MIN_PREFIXES", "MAX_PREFIXES", "MIN_SUFFIXES", "MAX_SUFFIXES"};

    for _, sField in ipairs(tFields) do
        validateList(tRarity[sField], sField, nLevels);
    end

    type.assert.table(tRarity.Affix, nil, nil, nil, nil, "\nRarity config Affix must be a table.");
    type.assert.custom(tRarity.Affix.maxTier, "TIER", "\nRarity config Affix.maxTier must be a TIER.");
    local tNames = {};
    local nPreviousChance = 100;

    for nIndex = 1, nLevels do
        local sContext = "Rarity config row "..nIndex;
        local sName = tRarity.LEVEL[nIndex];
        type.assert.string(sName, nil, "\n"..sContext.." LEVEL");
        assert(string.isvariablecompliant(sName, true), sContext.." LEVEL must be a valid enum member name.");
        assert(not tNames[sName], sContext.." LEVEL duplicates '"..sName.."'.");
        tNames[sName] = true;

        type.assert.string(tRarity.COLOR[nIndex], "^#%x%x%x%x%x%x$", "\n"..sContext.." COLOR must be #RRGGBB.");
        local nChance = tRarity.CHANCE[nIndex];
        validateNumber(nChance, sContext.." CHANCE", true);
        assert(nChance <= 100, sContext.." CHANCE cannot exceed 100.");
        assert(nChance <= nPreviousChance, sContext.." CHANCE must not increase toward rarer levels.");
        assert(nIndex ~= 1 or nChance == 100, "Rarity config first CHANCE must be 100.");
        nPreviousChance = nChance;

        -- Equal thresholds intentionally permit zero-probability rarities.
        -- Tier and count ranges must remain internally ordered for every row.
        local eMinTier = tRarity.MIN_AFFIX_TIER[nIndex];
        local eMaxTier = tRarity.MAX_AFFIX_TIER[nIndex];
        type.assert.custom(eMinTier, "TIER", "\n"..sContext.." MIN_AFFIX_TIER");
        type.assert.custom(eMaxTier, "TIER", "\n"..sContext.." MAX_AFFIX_TIER");
        assert(eMinTier <= eMaxTier, sContext.." minimum affix tier exceeds maximum.");
        assert(eMaxTier <= tRarity.Affix.maxTier, sContext.." affix tier exceeds Affix.maxTier.");

        for _, sKind in ipairs({"PREFIXES", "SUFFIXES"}) do
            local nMinimum = tRarity["MIN_"..sKind][nIndex];
            local nMaximum = tRarity["MAX_"..sKind][nIndex];
            validateNumber(nMinimum, sContext.." MIN_"..sKind, true);
            validateNumber(nMaximum, sContext.." MAX_"..sKind, true);
            assert(nMinimum <= nMaximum, sContext.." minimum "..sKind.." exceeds maximum.");
        end

    end
end


-- Fail during module loading rather than surfacing malformed rows during gameplay.
validateConfig(_tConfig.Rarity);

-- Keep validated values independent of the source tables. The config metatable
-- cannot prevent overwriting existing keys, so references alone are not immutable.
local function snapshotList(tInput)
    local tCopy = {};

    for nIndex, vValue in ipairs(tInput) do
        tCopy[nIndex] = vValue;
    end

    return tCopy;
end


local _tRarity          = _tConfig.Rarity;
local _tLevel           = snapshotList(_tRarity.LEVEL);
local _tColor           = snapshotList(_tRarity.COLOR);
local _tChance          = snapshotList(_tRarity.CHANCE);
local _tMinAffixTier    = snapshotList(_tRarity.MIN_AFFIX_TIER);
local _tMaxAffixTier    = snapshotList(_tRarity.MAX_AFFIX_TIER);
local _tMinPrefixes     = snapshotList(_tRarity.MIN_PREFIXES);
local _tMaxPrefixes     = snapshotList(_tRarity.MAX_PREFIXES);
local _tMinSuffixes     = snapshotList(_tRarity.MIN_SUFFIXES);
local _tMaxSuffixes     = snapshotList(_tRarity.MAX_SUFFIXES);

local _nRarityLevels    = #_tLevel;

-- Configuration supplies names; selection returns members of the resulting enum.
local _eLevel          = enum("Rarity.LEVEL", _tLevel, nil, true);

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
            <td>Defines the numeric range of prefixes and suffixes that can be assigned to items, further diversifying their properties and effects.</td>
        </tr>
    </tbody>
</table>

@note
Configuration is validated when this module loads: all lists must be dense and the
same length, level names unique, colors #RRGGBB, chances descending integer thresholds
in [0,100] beginning at 100, and affix tiers/counts valid ordered ranges. Equal chance
thresholds permit zero-probability levels. Validated lists are retained as private snapshots.

The Rarity system's configuration is designed for customization on a per-game basis, enabling developers to establish unique rarity systems tailored to their specific game mechanics and aesthetics. However, once the game is running, the configuration data is immutable and cannot be altered during gameplay. This intentional design choice ensures that the rarity framework remains stable and consistent, preventing any tampering or unintended modifications while the game is in execution. By restricting changes to the configuration file outside of gameplay, developers can maintain the integrity of the game's mechanics, fostering a reliable experience for players.
!]]
return class("Rarity",
{--METAMETHODS

},
{--STATIC PUBLIC
    --NOTE: Docs in config file.
    LEVEL = _eLevel,

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
    @ret number nChance The cumulative percentage threshold for this rarity or any rarer level, not its individual occurrence probability.
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
        return _tMinPrefixes[eLevel.value];
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
        return _tMaxPrefixes[eLevel.value];
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
        return _tMinSuffixes[eLevel.value];
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
        return _tMaxSuffixes[eLevel.value];
    end,

    --[[!
        @fqxn CoG.Rarity.Methods.getRandom
        @desc This method selects a Rarity LEVEL based on cumulative percentage thresholds. It rolls an integer percentage, adds the adjustment to the roll, and checks rarity levels from highest to lowest. The first threshold at least as large as the adjusted roll wins; the lowest rarity is the fallback. A negative adjustment increases the likelihood of obtaining a higher rarity, while a positive adjustment decreases it.
        @vis Public Static
        @param number|nil nAdjustment An optional numeric adjustment to the chance roll. Negative values enhance the chance for higher rarities, while positive values diminish it.
        @return Rarity.LEVEL eLevel The Rarity <a href="#CoG.Rarity.Enums.LEVEL">LEVEL</a> determined based on the random roll and any adjustments made.
    !]]
    getRandom = function(nAdjustment)
        local eRet = _eLevel[1];
        local nRoll = RNG.percent();
        nAdjustment = nAdjustment == nil and 0 or nAdjustment;
        type.assert.number(nAdjustment);
        assert(nAdjustment == nAdjustment and nAdjustment > -math.huge and nAdjustment < math.huge,
               "Rarity adjustment must be finite.");

        -- Lower adjusted rolls favor rarer outcomes; positive adjustments do the reverse.
        nRoll = nRoll + nAdjustment;

        for x = _nRarityLevels, 1, -1 do
            local eRarity       = _eLevel[x];
            local nChanceToGet  = _tChance[x];

            if (nRoll <= nChanceToGet) then
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
