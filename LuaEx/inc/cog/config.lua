--[[!
    @fxqn LuaEx.CoG.Config
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
    AStar = {
        nodeEdges = {
            entry   = {},
            exit    = {},
        },
    },
    Pool = {

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
