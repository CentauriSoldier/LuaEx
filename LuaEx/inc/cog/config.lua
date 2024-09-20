--[[!
    @fqxn CoG.Config
    @desc <p>This table (found in the directory <strong><em>LuaEx/inc/cog/config.lua</em></strong>) is for the user to edit (pre-runtime).
    <br>It is available at runtime by accessing the global variable:
    <br><strong><em>luaex.cog.config</strong></em>
    <br>It (and any subtables it contains) are read-only at runtime, preventing potential issues of unexpected data changes.
    <br>It's designed to allow configurability in CoG classes and user classes that may need different data from one project to the next.
    <br><strong>Note</strong>: exsiting subtables should not be removed or renamed but the values can be changed without issue.
    <br>More subtables may be added as desired.
    </p>
!]]
local tConfig = {--TODO basic things like units of measurement
    AStar = {
        nodeEdges = {
            entry   = {},
            exit    = {},
        },
    },
    Pool = {

    },
    BaseObject = {

    },
    BaseVehicle = {
        COMPONENT = {"BODY"},        
    },
    Rarity = {
        Affix = {
            maxTier = TIER.VI,--NOTE: must be no higher than the rarity max affix tier
        },
        LEVEL           = {"COMMON",    "UNCOMMON",     "RARE",         "EPIC",     "LEGENDARY",    "SINGULAR"},
        COLOR           = {"#BBBBBB",   "#0000B3",      "#AFC657",      "#00C202",  "#BA0000",      "#CF7136"},
        CHANCE          = {100,         21,             13,             8,          5,              3},
        MIN_AFFIX_TIER  = {TIER.I,      TIER.I,         TIER.I,         TIER.II,    TIER.II,        TIER.V},
        MAX_AFFIX_TIER  = {TIER.I,      TIER.II,        TIER.III,       TIER.IV,    TIER.V,         TIER.VI},
        MIN_PREFIX      = {0,           1,              1,              2,          2,              3},
        MAX_PREFIX      = {1,           1,              2,              2,          3,              3},
        MIN_SUFFIX      = {0,           1,              1,              3,          2,              3},
        MAX_SUFFIX      = {1,           2,              2,              3,          3,              3},
    },
    StatusSystem = {
        EFFECT = {
            --"ARMOURED",
            "BERSERK",
            "BLESSED",
            "BLIND",
            "BURNED",
            --"CHARMED",
            "CHILLED",
            "CONFUSED",
            "CURSED",
            --"DEBILITATED",
            "DEAFENED",
            --"DISARMED",
            --"DISORIENTED",
            "DISEASED",
            --"DOMINATED",
            "EMPOWERED",
            "ENFEEBLED",
            --"ENAMORED",
            --"ENERGIZED",
            --"ENRAGED",
            "ENTANGLED",
            --"ENTHRALLED",
            "EXHAUSTED",
            "FRIGHTENED",
            "FROZEN",
            "GUARDED",
            "GUARDING",
            "HASTENED",
            "IMMOBILIZED",
            --"INCAPACITATED",
            "INTIMIDATED",
            --"INVIGORATED",
            "INVISIBLE",
            --"MEDITATING",
            --"MARKED",
            --"NERVOUS",
            --"PANICKED",
            "PACIFIED",
            "PARALYZED",
            "PETRIFIED",
            "PHASED",
            "POISONED",
            --"REFLECTED",
            "REGENERATING",
            --"REJUVENATED",
            "ROOTED",
            --"RUSHED",
            "SAPPED",
            "SCORCHED",
            "SHATTERED",
            --"SHIELDED",
            --"SHIELDING",
            "SHOCKED",
            "SILENCED",
            "STUNNED",
            "SLEEP",
            "SLOWED",
            "SURPRISED",
            --"TERRIFIED",
            --"TRANQUILIZED",
            "UNCONSCIOUS",
            --"VEXED",
            "VULNERABLE",
            --"WEAKENED",
        },
    },
};

--[[🅳🅾 🅽🅾🆃 🅼🅾🅳🅸🅵🆈 🅱🅴🅻🅾🆆 🆃🅷🅸🆂 🅻🅸🅽🅴]]

--localize
local pairs         = pairs;
local setmetatable  = setmetatable;

--prep the metatable
local tMeta = {
    __newindex = function()
        error("Error: attempt to modify read-only CoG Config table.", 2);
    end,
};

--sets the metatable for a table recursively
local function setMeta(tInput)

    setmetatable(tInput, tMeta);

    for k, v in pairs(tInput) do

        if type(v) == "table" then
            setMeta(v);
        end

    end

end

--restrict the config table to access only
setMeta(tConfig);
--return the modified table
return tConfig;
