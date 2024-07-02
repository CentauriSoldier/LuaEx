return class("StatusHandler",
{--METAMETHODS
},
{--STATIC PUBLIC
    --[[effects = {
        "ARMOURED",
        "BERSERK",
        "BLESSED",
        "BLIND",
        "BURNED",
        "CHARMED",
        "CHILLED",
        "CONFUSED",
        "CURSED",
        "DEBILITATED",
        "DEAFENED",
        "DISARMED",
        "DISORIENTED",
        "DISEASED",
        "DOMINATED",
        "EMPOWERED",
        "ENFEEBLED",
        "ENAMORED",
        "ENERGIZED",
        "ENRAGED",
        "ENTANGLED",
        "ENTHRALLED",
        "EXHAUSTED",
        "FRIGHTENED",
        "FROZEN",
        "GUARDED",
        "GUARDING",
        "HASTENED",
        "IMMOBILIZED",
        "INCAPACITATED",
        "INTIMIDATED",
        "INVIGORATED",
        "INVISIBLE",
        "MEDITATING",
        "MARKED",
        "MUTED",
        "NERVOUS",
        "PANICKED",
        "PACIFIED",
        "PARALYZED",
        "PETRIFIED",
        "PHASED",
        "POISONED",
        "REFLECTED",
        "REGENERATING",
        "REJUVENATED",
        "ROOTED",
        "RUSHED",
        "SAPPED",
        "SCORCHED",
        "SHATTERED",
        "SHIELDED",
        "SHIELDING",
        "SHOCKED",
        "SILENCED",
        "STUNNED",
        "SLEEP",
        "SLOWED",
        "SURPRISED",
        "TERRIFIED",
        "TRANQUILIZED",
        "UNCONSCIOUS",
        "VEXED",
        "VULNERABLE",
        "WEAKENED",
    },
    Status = function(stapub)

        for nIndex, sEffect in pairs(stapub.effects) do
            stapub[sEffect] = nIndex;
        end

    end,]]
},
{--PRIVATE

},
{--PROTECTED
    effects = {

    },
},
{--PUBLIC
    StatusHandler = function(this, cdat, tStatuses)

    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
