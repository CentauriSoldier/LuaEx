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
return {
    Affix = {
        maxTier = TIER.VI, --TODO move this to rarity
    },
    AStar = {
        nodeEdges = {
            entry   = {},
            exit    = {},
        },
    },
    Pool = {

    },
    Rarity = {
        Colors  = {"#bbbbbb", "#0000b3", "#a7a000", "#00c202", "#ba0000", "#CF7136"},
        LEVEL   = enum("Rarity.LEVEL",  {"COMMON",  "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "SINGULAR"}, nil, true),
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
