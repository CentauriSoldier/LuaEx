--TODO clone & serialize

local class     = class;
local enum      = enum;
local math      = math;
local type      = type;
local Protean   = Protean;

local function updateSystem(this, cdat)
    local pri       = cdat.pri;
    local pro       = cdat.pro;
    local tBounds   = pri.levelBounds;
    local nFinalXP  = pro.XPProtean.getValue();

    pri.calculateLevelBounds();

    for x = 0, pri.levelBoundsCount do

        if (nFinalXP >= tBounds[x]) then
            nNewLevel = x;
        else
            break;
        end

    end

    if (nOldLevel ~= nNewLevel) then
        pro.Level = nNewLevel;
    end

end

return class("XPSystem",
{--METAMETHODS

},
{--STATIC PUBLIC
    TYPE = enum("XPSystem.TYPE", {"LINEAR", "LOGARITHMIC", "EXPONENTIAL", "QUADRATIC", "CUBIC", "STEP"}, nil, true),
    --XPSystem = function(stapub) end,
},
{--PRIVATE
    --CurrentXP__autoAF             = 0,
    levelOneXP__RO                  = null,
    levelBounds                     = {},
    levelBoundsCount                = 0,
    MaxLevel__autoAA                = 1,--QUESTION allow this to be changed?
    onChange                        = null,
    IsCallbackActive__autoAA        = false,
    IsCallbackLocked__autoAA        = false,
    Progression__autoAA        = 0,
    StepSize__autoAA                = 0,
    Type__autoAA                    = null,--QUESTION allow this to be changed?

    calculateLevelBounds = function(this, cdat)
        local pri          = cdat.pri;
        local nProgression = pri.Progression;
        local nMaxlevel    = pri.MaxLevel;
        local nStepSize    = pri.StepSize;
        local eType        = pri.Type;
        local eTrackerType = XPSystem.TYPE;
        local nLevelOneXP  = pri.levelOneXP;
        local nCurrentXP   = nLevelOneXP;

        pri.levelBounds     = {};
        pri.levelBounds[0]  = 0;
        pri.levelBounds[1]  = nLevelOneXP;
        local bIsStep       = eType == eTrackerType.STEP;
        local nStartIndex   = bIsStep and 1 or 2;

        for nLevel = nStartIndex, nMaxlevel do

            if (eType == eTrackerType.LINEAR) then
                nCurrentXP = nCurrentXP + nProgression;
            elseif (eType == eTrackerType.LOGARITHMIC) then
                nCurrentXP = nLevelOneXP + (nProgression * math.log(nLevel))
            elseif (eType == eTrackerType.EXPONENTIAL) then
                nCurrentXP = nCurrentXP * nProgression;
            elseif (eType == eTrackerType.QUADRATIC) then
                nCurrentXP = nLevelOneXP + (nProgression * (nLevel^2))
            elseif (eType == eTrackerType.CUBIC) then
                nCurrentXP = nLevelOneXP + (nProgression * (nLevel^3))
            elseif (bIsStep) then
                local nCurrentStep = math.floor((nLevel - 1) / nStepSize);
                local nCurrentStepValue = nLevelOneXP + (nProgression * nCurrentStep);
                local nLastLevelXP = pri.levelBounds[nLevel - 1];
                nCurrentXP = nCurrentStepValue + nLastLevelXP;
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
    XPSystem = function(this, cdat, eType, nLevelOneXP, nMaxlevel, nProgression, nStepSize)
        local pri = cdat.pri;
        local pro = cdat.pro;
        local eTrackerType  = XPSystem.TYPE;

        --safety defaults for potentially-nil parameters
        pri.StepSize    = type(nStepSize)   == "number" and nStepSize or 2;

        type.assert.custom(eType, "XPSystem.TYPE");
        type.assert.number(nLevelOneXP,         true, true, false, true, false);
        type.assert.number(nMaxlevel,           true, true, false, true, false);
        type.assert.number(nProgression,   true, true, false, false, false);

        if eType == eTrackerType.STEP then
            type.assert.number(nStepSize, true, true, false, true, false);
        end

        pri.levelOneXP  = nLevelOneXP;
        pri.MaxLevel    = nMaxlevel;
        pri.Progression = nProgression;

        pri.Type        = eType;

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

        if (nLevel <= pri.levelBoundsCount) then
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

        if (nLevel <= pri.levelBoundsCount) then
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

        if (nLevel <= pri.levelBoundsCount) then
            nRet = tBounds[nLevel];
        end

        return nRet;
    end,
    setCallback = function(this, cdat, fCallback, bDoNotSetActive)
        local pri = cdat.pri;

        if (pri.IsCallbackLocked) then
            error("Error setting XPSystem callback function.\nCallback is locked.");
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
    setLevel = function(this, cdat, nLevel)
        local pri = cdat.pri;
        type.assert.number(nLevel, true, false, false, true, false, 0, pri.levelBoundsCount);
        local nXP = cdat.pri.levelBounds[nLevel];
        cdat.pro.XPProtean.setValue(nXP);
    end,
    setMaxLevel = function(this, cdat, nMaxLevel, bSkipUpdate)
        type.assert.number(nMaxLevel, true, true, false, true, false);
        bSkipUpdate = rawtype(bSkipUpdate) == "boolean" and bSkipUpdate or false;
        cdat.pri.MaxLevel = nMaxLevel;

        if not (bSkipUpdate) then
            updateSystem(this, cdat);
        end

        return this;
    end,
    setProgression = function(this, cdat, nProgression, bSkipUpdate)
        type.assert.number(nProgression, true, true, false, false, false);
        bSkipUpdate = rawtype(bSkipUpdate) == "boolean" and bSkipUpdate or false;
        cdat.pri.Progression = nProgression;

        if not (bSkipUpdate) then
            updateSystem(this, cdat);
        end

        return this;
    end,
    setStepInterval = function(this, cdat, nStep)
        type.assert.number(nStep, true, true, false, false, false);
        bSkipUpdate = rawtype(bSkipUpdate) == "boolean" and bSkipUpdate or false;
        cdat.pri.StepSize = nStep;

        if not (bSkipUpdate) then
            updateSystem(this, cdat);
        end

        return this;
    end,
    setType = function(this, cdat, eType, bSkipUpdate)
        type.assert.custom(eType, "XPSystem.TYPE");
        bSkipUpdate = rawtype(bSkipUpdate) == "boolean" and bSkipUpdate or false;
        cdat.pri.Type = eType;

        if not (bSkipUpdate) then
            updateSystem(this, cdat);
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
