--LOCALIZATION
local class = class;

local function validateNumber(nValue, nMinimum, bInteger)
    assert(rawtype(nValue) == "number" and nValue >= nMinimum and nValue < math.huge and
           (not bInteger or nValue % 1 == 0), "Invalid creature trait or resource amount.");
end

local function resource(oInput, sName)

    if (oInput == nil) then
        return Pool(100, 100);
    end

    assert(class.isinstance(oInput) and class.ischildorself(class.of(oInput), Pool), sName.." must be a Pool instance.");
    return oInput;
end

local function adjustResource(this, oPool, nAmount)
    local nBefore = oPool.get();
    oPool.adjust(nAmount);
    return this, oPool.get() - nBefore;
end

--[[!
    @fqxn CoG.CreatureSystem.BaseCreature
    @desc Basic creature identity and resource Pools. Concrete subclasses supply
    gameplay rules. Depleted health does not automatically kill the creature.
    Omitted Pools are created per instance; supplied Pools retain their identity.
!]]
return class("BaseCreature",
{--METAMETHODS
    __clone = function()
        error("BaseCreature subclasses must define __clone for their creature state.");
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
},
{--PROTECTED
    Species__autoA_ = "Unknown",
    Faction__autoA_ = "Neutral",
    Level__autoA_ = 1,
    Age__autoA_ = 0,
    Health__autoA_ = null,
    Mana__autoA_ = null,
    Stamina__autoA_ = null,

},
{--PUBLIC
    -- tTraits accepts Species, Faction, Level, Age, Health, Mana and Stamina.
    BaseCreature = function(this, cdat, super, sName, sDescription, eRarity, wEventrix, tTraits)
        tTraits = tTraits == nil and {} or tTraits;
        assert(rawtype(tTraits) == "table" and not class.isinstance(tTraits), "Creature traits must be a table.");
        local nLevel = tTraits.Level == nil and 1 or tTraits.Level;
        local nAge = tTraits.Age == nil and 0 or tTraits.Age;
        local sSpecies = tTraits.Species == nil and "Unknown" or tTraits.Species;
        local sFaction = tTraits.Faction == nil and "Neutral" or tTraits.Faction;
        validateNumber(nLevel, 1, true);
        validateNumber(nAge, 0, false);
        assert(rawtype(sSpecies) == "string" and sSpecies:find("%S"), "Species cannot be blank.");
        assert(rawtype(sFaction) == "string" and sFaction:find("%S"), "Faction cannot be blank.");
        local oHealth = resource(tTraits.Health, "Health");
        local oMana = resource(tTraits.Mana, "Mana");
        local oStamina = resource(tTraits.Stamina, "Stamina");
        super(sName or "Creature", sDescription or "A creature.", eRarity, wEventrix);
        local pro = cdat.pro;
        pro.Species, pro.Faction = sSpecies, sFaction;
        pro.Level, pro.Age = nLevel, nAge;
        pro.Health, pro.Mana, pro.Stamina = oHealth, oMana, oStamina;
    end,

    setLevel = function(this, cdat, nLevel)
        validateNumber(nLevel, 1, true);
        cdat.pro.Level = nLevel;
        return this;
    end,

    setAge = function(this, cdat, nAge)
        validateNumber(nAge, 0, false);
        cdat.pro.Age = nAge;
        return this;
    end,

    setFaction = function(this, cdat, sFaction)
        assert(rawtype(sFaction) == "string" and sFaction:find("%S"), "Faction cannot be blank.");
        cdat.pro.Faction = sFaction;
        return this;
    end,

    takeDamage = function(this, cdat, nAmount)
        validateNumber(nAmount, 0, false);
        local _, nDelta = adjustResource(this, cdat.pro.Health, -nAmount);
        return this, -nDelta;
    end,

    heal = function(this, cdat, nAmount)
        validateNumber(nAmount, 0, false);
        return adjustResource(this, cdat.pro.Health, nAmount);
    end,

    spendMana = function(this, cdat, nAmount)
        validateNumber(nAmount, 0, false);
        local oPool = cdat.pro.Mana;

        if (oPool.get() < nAmount) then
            return this, false;
        end

        oPool.adjust(-nAmount);
        return this, true;
    end,

    spendStamina = function(this, cdat, nAmount)
        validateNumber(nAmount, 0, false);
        local oPool = cdat.pro.Stamina;

        if (oPool.get() < nAmount) then
            return this, false;
        end

        oPool.adjust(-nAmount);
        return this, true;
    end,

    isHealthDepleted = function(this, cdat)
        return cdat.pro.Health.get() == 0;
    end,

    isExhausted = function(this, cdat)
        return cdat.pro.Stamina.get() == 0;
    end,

    restoreResources = function(this, cdat)
        cdat.pro.Health.setFull();
        cdat.pro.Mana.setFull();
        cdat.pro.Stamina.setFull();
        return this;
    end,

    cycleResources = function(this, cdat, nMultiplier)
        cdat.pro.Health.cycle(nMultiplier);
        cdat.pro.Mana.cycle(nMultiplier);
        cdat.pro.Stamina.cycle(nMultiplier);
        return this;
    end,

},
BaseObject,
false,
nil
);
