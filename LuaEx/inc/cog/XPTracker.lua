local class     = class;
local enum      = enum;
local math      = math;
local type      = type;
local Protean   = Protean;

return class("XPTracker",
{--METAMETHODS

},
{--STATIC PUBLIC
    TYPE = enum("XPTracker.TYPE", {"LINEAR", "LOGARITHMIC", "EXPONENTIAL", "QUADRATIC", "CUBIC", "SIGMOID", "STEP"}, nil, true),
    --XPTracker = function(stapub) end,
},
{--PRIVATE
    --CurrentXP__autoAF             = 0,
    level1XP__RO                    = null,
    levelBounds                     = {},
    levelBoundsCount                = 0,
    maxLevel__RO                    = null,--QUESTION allow this to be changed?
    maxXP__RO                       = null,
    midpoint__RO                    = null,
    onChange                        = null,
    IsCallbackActive__autoAA        = null,
    IsCallbackLocked__autoAA        = false,
    progressionValue__RO            = null,
    steepness__RO                   = null,
    stepsize__RO                    = null,
    type__RO                        = null,--QUESTION allow this to be changed?

    calculateLevelBounds = function(this, cdat)
        local pri               = cdat.pri;
        local nProgressionValue = pri.progressionValue;
        local nMaxlevel         = pri.maxLevel;
        local nMaxXP            = pri.maxXP;
        local nMidpoint         = pri.midpoint;
        local nSteepness        = pri.steepness;
        local nStepSize         = pri.stepsize;
        local eType             = pri.type;
        local eTrackerType      = XPTracker.TYPE;

        pri.levelBounds     = {};
        pri.levelBounds[0]  = 0;
        local nCurrentXP    = 0;--pri.level1XP;

        for nLevel = 1, nMaxlevel do

            if (eType == eTrackerType.LINEAR) then
                nCurrentXP = nCurrentXP + nProgressionValue;
            elseif (eType == eTrackerType.LOGARITHMIC) then
                nCurrentXP = nLevel1XP + (nProgressionValue * math.log(nLevel))
            elseif (eType == eTrackerType.EXPONENTIAL) then
                nCurrentXP = nCurrentXP * nProgressionValue;
            elseif eType == eType.QUADRATIC then
                nCurrentXP = nLevel1XP + (nProgressionValue * (nLevel^2))
            elseif eType == eTrackerType.CUBIC then
                nCurrentXP = nLevel1XP + (nProgressionValue * (nLevel^3))
            elseif eType == eTrackerType.SIGMOID then
                nCurrentXP = nMaxXP / (1 + math.exp(-nSteepness * (nLevel - nMidpoint)))
            elseif eType == eTrackerType.STEP then
                nCurrentXP = nLevel1XP + (nProgressionValue * math.floor(nLevel / nStepSize))
            end

            pri.levelBounds[nLevel] = math.ceil(nCurrentXP);
        end

        pri.levelBoundsCount = #pri.levelBounds;

    end
},--TODO discreet values
{--PROTECTED
    Level__autoAF       = 0,
    XPProtean__autoAA   = null,
},
{--PUBLIC
    XPTracker = function(this, cdat, eType, nLevel1XP, nMaxlevel, nProgressionValue, nMaxXP, nSteepness, nMidpoint, nStepSize)
        local pri = cdat.pri;
        local pro = cdat.pro;
        local eTrackerType  = XPTracker.TYPE;

        --safety defaults for potentially-nil parameters
        pri.maxXP       = type(nMaxXP)      == "number" and nMaxXP      or 1000;
        pri.midpoint    = type(nMidpoint)   == "number" and nMidpoint   or nMaxlevel / 2;
        pri.steepness   = type(nSteepness)  == "number" and nSteepness  or 0.1;
        pri.stepsize    = type(nStepSize)   == "number" and nStepSize   or 5;

        type.assert.custom(eType, "XPTracker.TYPE");
        type.assert.number(nLevel1XP, true, true, false, false, false);
        type.assert.number(nMaxlevel, true, true, false, true, false);
        type.assert.number(nProgressionValue, true, true, false, false, false);

        if eType == eTrackerType.SIGMOID then
            type.assert.number(nMaxXP,      true, true, false, false, false);
            type.assert.number(nSteepness,  true, true, false, false, false);
            type.assert.number(nMidpoint,   true, true, false, false, false);
        end

        if eType == eTrackerType.STEP then
            type.assert.number(nStepSize, true, true, false, false, false);
        end

        pri.level1XP            = nLevel1XP;
        pri.maxLevel            = nMaxlevel;
        pri.progressionValue    = nProgressionValue;

        pri.type                = eType;

        pri.calculateLevelBounds();

        local tBounds  = pri.levelBounds;
        pro.XPProtean = Protean(0, 0, 0, 0, 0, 0, 0, nil, nil,
        function(prot)
            local nFinalXP  = prot.getValue();
            local nNewLevel = pro.Level;
            local nOldLevel = pro.Level;

            for x = 0, pri.levelBoundsCount do

                if (nFinalXP >= tBounds[x]) then
                    nNewLevel = x;
                else
                    break;
                end

            end

            if (nOldLevel ~= nNewLevel) then
                pro.Level = nNewLevel;

                if (pri.IsCallbackActive) then
                    pri.onChange(this, nOldLevel, nNewLevel, nFinalXP);
                end

            end

        end)
        pro.XPProtean.lockCallback();--prevent tampering with the callback

    end,
    getXPToLevel = function(this, cdat, nLevel)
        local nRet      = -1;
        local pri       = cdat.pri;
        local pro       = cdat.pro;
        local tBounds   = pri.levelBounds;
        type.assert.number(nLevel, true, true, false, true, false);

        if (nLevel < pri.levelBoundsCount) then
            nRet = tBounds[nLevel] - pro.XPProtean.getValue();
        end

        return nRet;
    end,
    getXPToNextLevel = function(this, cdat)
        local nRet      = -1;
        local pri       = cdat.pri;
        local pro       = cdat.pro;
        local nLevel    = pro.Level;
        local tBounds   = pri.levelBounds;

        if (nLevel < pri.levelBoundsCount) then
            nRet = tBounds[nLevel + 1] - pro.XPProtean.getValue();
        end

        return nRet;
    end,
    getXPRequired = function(this, cdat, nLevel)
        local nRet      = -1;
        local pri       = cdat.pri;
        local pro       = cdat.pro;
        local tBounds   = pri.levelBounds;
        type.assert.number(nLevel, true, true, false, true, false);

        if (nLevel < pri.levelBoundsCount) then
            nRet = tBounds[nLevel];
        end

        return nRet;
    end,
    setCallback = function(this, cdat, fCallback, bDoNotSetActive)
        local pri = cdat.pri;

        if (pri.IsCallbackLocked) then
            error("Error setting XPTracker callback function.\nCallback is locked.");
        end

        if (rawtype(fCallback) == "function") then
            pri.onChange 			= fCallback;
            pri.IsCallbackActive 	= not (rawtype(bDoNotSetActive) == "boolean" and bDoNotSetActive or false);

        else
            pri.onChange 			= nil;
            pri.IsCallbackActive	= false;
        end

        return this;
    end,
    XPBoundsIterator = function(this, cdat)
        local pri       = cdat.pri;
        local nIndex    = 0;
        local nMax      = pri.levelBoundsCount;
        local tBounds   = pri.levelBounds;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return nIndex, tBounds[nIndex];
            end

        end

    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
