--LOCALIZATION
local floor 			= math.floor;
local math				= math;
local rawtype           = rawtype;
local type				= type;
--TODO NEXT LEFT OFF HERE Do events on other items (onFull, Empty etc.)
--CLASS-LEVEL ENUMS
local _eAspect      = enum("Pool.ASPECT",   {"CURRENT", "MAX", "CYCLE", "CYCLE_FLAT", "CYCLE_PERCENT", "RESERVED", "RESERVED_FLAT", "RESERVED_PERCENT"},
                                            {"current", "max", "cycle", "cycle_flat", "cycle_percent", "reserved", "reserved_flat", "reserved_percent"}, true);

--local _eMode        = enum("Pool.MODE",     {"FLAT", "PERCENT"}, {"flat", "percent"}, true);

local _eModifier    = enum("Pool.MODIFIER", {   "BASE",     "FINAL",    "MAX",
                                                "BASE_BONUS",           "BASE_PENALTY",
                                                "MULTIPLICATIVE_BONUS", "MULTIPLICATIVE_PENALTY",
                                                "ADDITIVE_BONUS",       "ADDITIVE_PENALTY"},
                                                {1, 2, 3, 4, 5, 6, 7, 8, 9}, true);

local _eEvent       = enum("Pool.EVENT",    {"ON_INCREASE", "ON_DECREASE",  "ON_EMPTY", "ON_FULL",  "ON_LOW",   "ON_CYCLE", "ON_RESERVE", "ON_UNRESERVE"},
                                            {"onIncrease",  "onDecrease",   "onEmpty",  "onFull",   "onLow",    "onCycle",  "OnReserve",  "onUnreserve"}, true);

--ASPECT LOCALIZATION
local _eAspectCurrent           = _eAspect.CURRENT;
local _eAspectMax               = _eAspect.MAX;
local _eAspectCycle             = _eAspect.CYCLE;
local _eAspectCycleFlat         = _eAspect.CYCLE_FLAT;
local _eAspectCyclePercent      = _eAspect.CYCLE_PERCENT;
local _eAspectReserved          = _eAspect.RESERVED;
local _eAspectReservedFlat      = _eAspect.RESERVED_FLAT;
local _eAspectReservedPercent   = _eAspect.RESERVED_PERCENT;

local _sAspectCurrent           = _eAspectCurrent.value;
local _sAspectMax               = _eAspectMax.value;
local _sAspectCycle             = _eAspectCycle.value;
local _sAspectCycleFlat         = _eAspectCycleFlat.value;
local _sAspectCyclePercent      = _eAspectCyclePercent.value;
local _sAspectReserved          = _eAspectReserved.value;
local _sAspectReservedFlat      = _eAspectReservedFlat.value;
local _sAspectReservedPercent   = _eAspectReservedPercent.value;

--MODE LOCALIZATION
--local _eModeFlat                = _eMode.FLAT;
--local _eModePercent             = _eMode.PERCENT;

--local _sModeFlat                = _eModeFlat.value;
--local _sModePercent             = _eModePercent.value;

--MODIFIER LOCALIZATION
local _eBase        = _eModifier.BASE;
local _eFinal       = _eModifier.FINAL;
local _eMax         = _eModifier.MAX;
local _eBaseBonus   = _eModifier.BASE_BONUS;
local _eBasePenalty = _eModifier.BASE_PENALTY;
local _eMultBonus   = _eModifier.MULTIPLICATIVE_BONUS;
local _eMultPenalty = _eModifier.MULTIPLICATIVE_PENALTY;
local _eAddBonus    = _eModifier.ADDITIVE_BONUS;
local _eAddPenalty  = _eModifier.ADDITIVE_PENALTY;

local _nBase        = _eBase.value;
local _nFinal       = _eFinal.value;
local _nMax         = _eMax.value;
local _nBaseBonus   = _eBaseBonus.value;
local _nBasePenalty = _eBasePenalty.value;
local _nMultBonus   = _eMultBonus.value;
local _nMultPenalty = _eMultPenalty.value;
local _nAddBonus    = _eAddBonus.value;
local _nAddPenalty  = _eAddPenalty.value;

--EVENT LOCALIZATION
local _eOnIncrease  = _eEvent.ON_INCREASE;
local _eOnDecrease  = _eEvent.ON_DECREASE;
local _eOnEmpty     = _eEvent.ON_EMPTY;
local _eOnFull      = _eEvent.ON_FULL;
local _eOnLow       = _eEvent.ON_LOW;
local _eOnCycle     = _eEvent.ON_CYCLE;
local _eOnReserve   = _eEvent.ON_RESERVE;
local _eOnUnreserve = _eEvent.ON_UNRESERVE;

local _sOnIncrease  = _eOnIncrease.value;
local _sOnDecrease  = _eOnDecrease.value;
local _sOnEmpty     = _eOnEmpty.value;
local _sOnFull      = _eOnFull.value;
local _sOnLow       = _eOnLow.value;
local _sOnCycle     = _eOnCycle.value;
local _sOnReserve   = _eOnReserve.value;
local _sOnUnreserve = _eOnUnreserve.value;

local _nDefaultReverseMax       = 0.5;
local _nReverseHardMax          = 0.99; --the max reservation allowed
local eventPlaceholder          = function() end




local function  updatePoolStatus(this, cdat)
    local pro      = cdat.pro;
    local nCurrent = pro[_sAspectCurrent];

    if (nCurrent == 0) then
        pro.isEmpty     = true;
        pro.isLow       = false;
        pro.isFull      = false;
    else
        local nMax          = pro[_sAspectMax][_nFinal];
        --local nReserved     = pro[_eAspectReserved];
        --local nAvailable    = nMax - nReserved; --TODO allow reserved to coubnt if user sets that

        pro.isEmpty     = false;
        pro.isLow       = nCurrent <= (nMax * pro.lowMarker);
        pro.isFull      = nCurrent >= (nMax * pro.fullMarker);
    end

end




local function clampCurrent(this, cdat)
    local pro           = cdat.pro;
    local nMax          = pro[_sAspectMax][_nFinal];
    local nCurrent      = pro[_sAspectCurrent];
    local nReserved     = pro[_sAspectReserved];
    local nAvailable    = nMax - nReserved;
    local bWasEmpty     = pro.isEmpty;
    local bWasLow       = pro.isLow;
    local bWasFull      = pro.isFull;
    local bIsEmpty;
    local bIsLow;
    local bIsFull;

    if (nCurrent <= 0) then-- or nAvailable <= 0) then
        pro[_sAspectCurrent] = 0;
        pro.isEmpty,    bIsEmpty = true,    true;
        pro.isLow,      bIsLow   = false,   false;
        pro.isFull,     bIsFull  = false,   false;
    else
        --set the current value
        local nNewCurrent = (nCurrent <= nAvailable) and nCurrent or nAvailable;
        pro[_sAspectCurrent] = nNewCurrent;

        bIsEmpty    = false;
        bIsLow      = nCurrent <= (nMax * pro.lowMarker);
        bIsFull     = nCurrent >= (nMax * pro.fullMarker);

        pro.isEmpty     = bIsEmpty;
        pro.isLow       = bIsLow;
        pro.isFull      = bIsFull;
    end

    local bEmptyChange  = bWasEmpty ~= bIsEmpty;
    local bLowChange    = bWasLow   ~= bIsLow;
    local bFullChange   = bWasFull  ~= bIsFull;

    return bEmptyChange, bLowChange, bFullChange, bIsEmpty, bIsLow, bIsFull;
end


--Final = ((nBase + nBaseBonus - nBasePenalty) * (1 + nMultBonus - nMultPenalty)) + nAddBonus - nAddPenalty;
local function calulateFinal(this, cdat, sIndex)
    local pro       = cdat.pro;
    local tValue    = pro[sIndex];
    local nRet      = ( tValue[_nBase] +
                        tValue[_nBaseBonus] - tValue[_nBasePenalty]) *
                        (1 + tValue[_nMultBonus] - tValue[_nMultPenalty]);

    --if (sIndex ~= _sAspectReserved) then --no addative bonus/penalty for reserved table
    --    nRet = nRet + (tValue[_nAddBonus] - tValue[_nAddPenalty]);
    --end

    return nRet;
end


local function attemptSettingMax(this, cdat, nValue, nModifier)

    return bRet, nOverage
end



local function attemptSettingReserved(this, cdat, sReserveAspect, nValue, nModifier)--TODO return overage
    local pro           = cdat.pro;
    local bRet          = false;
    local nOverage      = 0;

    --TODO check input values!!!
    --_nReverseHardMax

    local bIsFlat       = sReserveAspect == _sAspectReservedFlat;
    local bIsPercent    = not bIsFlat;

    --get the max, current and total reserved final values
    local nMax              = pro[_sAspectMax][_nFinal];
    local nCurrent          = pro[_sAspectCurrent];
    local nOldTotalReserved = pro[_sAspectReserved];

    --reserve tables and final values
    local tResPercent   = pro[_sAspectReservedPercent];
    local tResFlat      = pro[_sAspectReservedFlat];
    local tActive       = bIsPercent and tResPercent or tResFlat;

    --store the old value
    local nOldValue     = tActive[nModifier];
    --set the new value
    tActive[nModifier]  = nValue;

    --get the final values of the reserve aspects
    local nResFlat      = bIsPercent and tResFlat[_nFinal] or calulateFinal(this, cdat, sReserveAspect);
    local nResPercent   = bIsFlat and tResPercent[_nFinal] or calulateFinal(this, cdat, sReserveAspect);

    --get the total reserved
    local nTotalReserved = nResFlat + (nMax * nResPercent);
    --determine if the reservation is permitted
    bRet = (    (nOldTotalReserved ~= nTotalReserved) and
                (nTotalReserved / nMax) <= tResPercent[_nMax]);

    --if the reservation is allowed, process it
    if (bRet) then
        --set the new final value
        tActive[_nFinal]        = bIsPercent and nResPercent or nResFlat;
        --update the reserved total
        pro[_sAspectReserved]   = nTotalReserved;
        --update the current value
        local nNewCurrent       = nMax - nTotalReserved;
        local bChangeInCurrent  = nCurrent ~= nNewCurrent;

        if (bChangeInCurrent) then
            pro[_sAspectCurrent] = nNewCurrent;
        end

        --check for and fire reserve event
        local bOnReserve   = nOldTotalReserved < nTotalReserved;
        local bOnUnReserve = nOldTotalReserved > nTotalReserved;

        if (bOnReserve and pro.activeEvents[_sOnReserve]) then
            pro.events[_sOnReserve](this, nOldTotalReserved, nTotalReserved);
        elseif (bOnUnReserve and pro.activeEvents[_sOnUnReserve]) then
            pro.events[_sOnUnReserve](this, nOldTotalReserved, nTotalReserved);
        end

        --if the current value was changed, process events
        if (bChangeInCurrent) then
            local   bEmptyChange, bLowChange, bFullChange,
                    bIsEmpty, bIsLow, bIsFull = clampCurrent(this, cdat);
            local   bIsIncrease = nNewCurrent > nCurrent;
            local   bIsDecrease = nNewCurrent < nCurrent;

            if (bIsIncrease and pro.activeEvents[_sOnIncrease]) then
                pro[_sOnIncrease].events(this, nCurrent, nNewCurrent);
            elseif (bIsDecrease and pro.activeEvents[_sOnDecrease]) then
                pro[_sOnDecrease].events(this, nCurrent, nNewCurrent);
            end

            if (bEmptyChange and bIsEmpty and pro.activeEvents[_eOnEmpty]) then
                pro[_eOnEmpty].events(this);
            elseif (bLowChange and bIsLow and pro.activeEvents[_sOnLow]) then
                pro[_sOnLow].events(this);
            elseif (bFullChange and bIsFull and pro.activeEvents[_sOnFull]) then
                pro[_sOnFull].events(this);
            end

        end

    else
        --set the old value
        tActive[nModifier] = nOldValue;
        --indicate the overage
        --nOverage = bIsPercent and nResPercent or nResFlat TODO
    end


    return bRet, nOverage;
end


--@see class method of the same name
local function set(this, cdat, nValue, eAspectOrNil, eModifierOrNil)
    local pro           = cdat.pro;
    local bSuccess      = false;
    local nOverage      = 0;
    local eAspect       = (type(eAspectOrNil)   == "Pool.ASPECT")   and eAspectOrNil    or _eAspectCurrent;
    local sAspect       =  eAspect.value;
    local eModifier     = (type(eModifierOrNil) == "Pool.MODIFIER") and eModifierOrNil  or _eBase;
    local nModifier     = eModifier.value;
    local sEvent        = "NONE";

    if (type(nValue) ~= "number") then
        error("Error setting value in Pool class.\nExpected type number; got type: "..type(nValue)..'.');
    end

    if (nModifier == _nFinal) then
        error("Error setting value in Pool class.\nFinal values are calculated internally and may not be set manually.");
    end

    --TODO error for RESERVED

    --process CURRENT aspect
    if (sAspect == _sAspectCurrent) then --since current doesn't have a table
        local nPrevious = pro[_sAspectCurrent];

        if (nPrevious ~= nValue) then
            pro[_sAspectCurrent] = nValue;
            local bWasEmpty      = pro.isEmpty;
            local bWasLow

            clampCurrent(this, cdat);
            nNew                 = pro[_sAspectCurrent];
            bSuccess             = true;
            if (nNew > nPrevious) then --onIncrease

                if (pro.activeEvents[_sOnIncrease]) then
                    pro.events[_sOnIncrease](this, nPrevious, nValue);
                end

            elseif (nNew < nPrevious) then --onDecrease

                if (pro.activeEvents[_sOnDecrease]) then
                    pro.events[_sOnDecrease](this, nPrevious, nValue);
                end

            end

            if (nNew == pro[_sAspectMax][_nFinal]) then --onFull

                if (pro.activeEvents[_sOnFull]) then
                    pro.events[_sOnFull](this);
                end

            elseif (nNew == 0) then --onEmpty

                if (pro.activeEvents[_sOnEmpty]) then
                    pro.events[_sOnEmpty](this);
                end

            end

        end

    --process all other aspects
    elseif pro[sAspect][nModifier] then

        --process MAX aspect
        if (sAspect == _sAspectMax) then
            bSuccess, nOverage = attemptSettingMax(this, cdat, nValue, nModifier);

        --process CYCLE aspect
    elseif (sAspect == _sAspectCycleFlat or sAspect == _sAspectCyclePercent) then
            bSuccess, nOverage = setCycle(this, cdat, sAspect, nValue, nModifier);

        --process RESERVED_FLAT aspect
        elseif (sAspect == _sAspectReservedFlat or sAspect == _sAspectReservedPercent) then
            bSuccess, nOverage = attemptSettingReserved(this, cdat, sAspect, nValue, nModifier);
        end


    else --for tables like reserved which have only certain modifiers
        error(  "Error setting value in Pool class.\nNo '${modifier}' modifier exists for aspect, '${aspect}'." %
                {modifier = eModifier.name, aspect = eAspect.name});
    end

    return this, bSuccess, nOverage;
end


--[[!
@fqxn LuaEx.Classes.CoG.Pool.Functions
@desc
@param
@ret
!]]
local function validateModifier(sIndex, sSetOrGet, nMod)

    if (rawtype(nMod) ~= "number") then
        error("Error "..sSetOrGet.."ting Pool '"..sIndex.."' modifier. Modifer value must be of type number.");
    end

    if (nMod ~= _nBaseBonus and nMod ~= _nBasePenalty and
        nMod ~= _nMultBonus and nMod ~= _nMultPenalty and
        nMod ~= _nAddBonus  and nMod ~= _nAddPenalty) then
        error("Error "..sSetOrGet.."ting Pool '"..sIndex.."' modifier. Modifer value must be one of the permitted Protean modifer values.");
    end

end


--[[!
@fqxn LuaEx.Classes.CoG.Pool.Functions
@desc
@param
@ret
!]]
local function validateModifierAndValue(sIndex, sSetOrGet, nMod, nValue)

    if (rawtype(nMod) ~= "number") then
        error("Error "..sSetOrGet.."ting Pool '"..sIndex.."' modifier. Modifer value must be of type number. Type given: "..type(nMod)..'.');
    end

    if (rawtype(nValue) ~= "number") then
        error("Error "..sSetOrGet.."ting Pool '"..sIndex.."' modifier.\nValue must be of type number. Type given: "..type(nValue)..'.');
    end

    if (nMod ~= _nBaseBonus and nMod ~= _nBasePenalty and
        nMod ~= _nMultBonus and nMod ~= _nMultPenalty and
        nMod ~= _nAddBonus  and nMod ~= _nAddPenalty) then
        error("Error "..sSetOrGet.."ting Pool '"..sIndex.."' modifier. Modifer value must be one of the permitted Protean modifer values.");
    end

end




--[[!
    @fqxn LuaEx.Classes.CoG.Pool
    @authors Centauri Soldier
    @desc <h2>Pool</h2><h3>Utility class used to keep track of things like Health, Magic, etc.</h3><p>You can operate on <strong>Pool</strong> objects using some math operators.</p>
    <b>TODO</b>
    <ul>
        <li><p><b>+</b>: adds a number to the Pool's CURRENT value or, if adding another Pool object instead of a number, it will add the other Pool's CURRENT value to it's own <em>(up to it's MAX)</em> value.</p></li>
        <li><p><b>-</b>: does the same as addition but for subtraction. Will not go below the Pool's MIN value.</p></li>
        <li><p><b>%</b>: will modify a Pool's MAX value using a number value or another Pool object <em>(uses it's MAX value)</em>. Will not allow itself to be set at or below the MIN value.</p></li>
        <li><p><b>*</b>: operates as expected on the object's CURRENT value.</p></li>
        <li><p><b>/</b>: operates as expected on the object's CURRENT value. All div is floored.</p></li>
        <li><p><b>-</b><em>(unary minus)</em>: will set the object's CURRENT value to the value of MIN.</p></li>
        <li><p><b>#</b>: will set the object's CURRENT value to the value of MAX.</p></li>
        <li><p><b></b></p></li>
        <li><p><b></b></p></li>
    </ul>
    @version 2.1
    @todo Complete the binary operator metamethods.
!]]
return class("Pool",
{--METAMETHODS

},
{--STATIC PUBLIC
    ASPECT__RO      = _eAspect,
    EVENT__RO       = _eEvent,
    --MODE__RO        = _eMode,
    MODIFIER__RO    = _eModifier,
    --Pool = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    activeEvents = {
        [_sOnIncrease]  = false,
        [_sOnDecrease]  = false,
        [_sOnEmpty]     = false,
        [_sOnFull]      = false,
        [_sOnCycle]     = false,
        [_sOnReserve]   = false,
        [_sOnUnreserve] = false,
    },
    events = {
        [_sOnIncrease]  = eventPlaceholder,
        [_sOnDecrease]  = eventPlaceholder,
        [_sOnEmpty]     = eventPlaceholder,
        [_sOnFull]      = eventPlaceholder,
        [_sOnCycle]     = eventPlaceholder,
        [_sOnReserve]   = eventPlaceholder,
        [_sOnUnreserve] = eventPlaceholder,
    },
    [_sAspectCurrent] = 1,
    [_sAspectReserved]= 0, --cached value updated on change
    [_sAspectMax]     = {
        [_nBase]        = 0,
        [_nFinal]       = 0,
        [_nMax]         = math.huge,
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,
        [_nAddBonus]    = 0,
        [_nAddPenalty]  = 0,
        min             = 1,
        final           = 0, --cached value updated on change
    },
    [_sAspectCycle]     = 0, --cached value updated on change
    [_sAspectCycleFlat] = {
        [_nBase]        = 0,
        [_nFinal]       = 0,
        [_nMax]         = math.huge,
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,
        [_nAddBonus]    = 0,
        [_nAddPenalty]  = 0,
        final           = 0, --cached value updated on change
    },
    [_sAspectCyclePercent] = {
        [_nBase]        = 0,
        [_nFinal]       = 0,
        [_nMax]         = math.huge,
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,
        [_nAddBonus]    = 0,
        [_nAddPenalty]  = 0,
        final           = 0, --cached value updated on change
    },
    [_sAspectReservedFlat] = {
        [_nBase]        = 0, --this is updated whenever flat or percent are changed.
        [_nFinal]       = 0,
        [_nMax]         = math.huge, --MUST be a percentage
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,
        [_nAddBonus]    = 0,
        [_nAddPenalty]  = 0,
        final           = 0, --cached value updated on change
    },
    [_sAspectReservedPercent] = {
        [_nBase]        = 0, --this is updated whenever flat or percent are changed.
        [_nFinal]       = 0,
        [_nMax]         = _nDefaultReverseMax, --MUST be a percentage
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,
        [_nAddBonus]    = 0,
        [_nAddPenalty]  = 0,
        final           = 0, --cached value updated on change
    },
    lowMarker       = 0.3,  --TODO
    fullMarker      = 1,    --TODO QUESTION should full include reserved?
    isEmpty         = false,
    isFull          = false,
    isLow           = false,
    --hasReservation      = 0, --cached value updated on change
},
{--PUBLIC

    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.Pool
    @desc The constructor for the <b>Pool</b> class.
    @param nMax number|nil The maximum value of the Pool.
    @param nCurrent number|nil The current value of the Pool.
    @param nCycle number|nil The amount the Pool should fill or delete when the <a href="#LuaEx.Classes.CoG.Pool.Methods.cycle">cycle</a> method is called.
    @param nReservation number|nil The reservation value of the Pool.
    !]]
    Pool = function(this, cdat, nMax, nCurrent)
        local pro   = cdat.pro;
        nMax        = type(nMax) 		== "number"	and nMax	    or 1;
        nCurrent	= type(nCurrent) 	== "number" and nCurrent    or 1;
        nCycle 	    = type(nCycle) 		== "number" and nCycle 		or 0;
        nReserved   = type(nReserved)   == "number" and nReserved   or 0;

        if (nMax <= 1) then
            error("Error creating Pool object.\nMax value must be positive number greater than or equal to 1.");
        end

        if (nCurrent < 0) then
            error("Error creating Pool object.\nCurrent value must be non-negative.");
        end

        --set the values
        --TODO check and clamp ALL values!
        pro[_sAspectMax][_nBase]        = nMax;
        pro[_sAspectMax][_nFinal]       = nMax;
        pro[_sAspectCurrent]            = nCurrent;

        clampCurrent(this, cdat);
    end,


    adjust = function()
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.isEmpty
    @desc Determines whether the Pool is empty.
    <br>This is true when the current value is less or equal to 0.
    @ret bEmpty boolean True if the Pool is empty, false otherwise.
    !]]
    isEmpty = function(this, cdat)
        return cdat.pro.isEmpty;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.isFull
    @desc Determines whether the Pool is full.
    <br>This is true when the current value is (<em>greater than or</em>) equal to the maximum value.
    @ret bEmpty boolean True if the Pool is full, false otherwise.
    !]]
    isFull = function(this, cdat)
        return cdat.pro.isFull;
    end,


    isLow = function(this, cdat)
        return cdat.pro.isLow;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.get
    @desc TODO
    @ex TODO
    @param eAspect Pool.ASPECT|nil If provided, this refers to the aspect of the pool to get such as MAX or CYCLE.
    <br>If not provided it will default to CURRENT.
    @param eModifier Pool.MODIFIER|nil If provided, this indicates which modifier to get such as BASE, BASE_BONUS, etc.
    <br>If not provided, it will default to BASE.
    <br><strong>Note</strong>: not all aspects have all modifiers. E.g., Pool.ASPECT.RESERVED does not have ADDITIVE_BONUS or ADDITIVE_PENALTY and Pool.ASPECT.CURRENT has no modifiers whatsoever.
    @ret nRet number The value requested in either a flat value or a percentage between 0 and 1.
    !]]
    get = function(this, cdat, eAspectOrNil, eModifierOrNil)
        local nRet;
        local pro       = cdat.pro;
        local eAspect   = (type(eAspectOrNil)   == "Pool.ASPECT")   and eAspectOrNil    or _eAspectCurrent;
        local sAspect   =  eAspect.value;
        local eModifier = (type(eModifierOrNil) == "Pool.MODIFIER") and eModifierOrNil  or _eFinal;
        local nModifier = eModifier.value;

        if (sAspect == _sAspectCurrent) then --since current doesn't have a table
            nRet = pro[_sAspectCurrent];

        elseif (sAspect == _sAspectReserved) then --for reserved total
            nRet = pro[_sAspectReserved];

        elseif (sAspect == _sAspectCycle) then --for cycle total
            nRet = pro[_sAspectCycle];

        elseif pro[sAspect][nModifier] then
            nRet = pro[sAspect][nModifier];

        else --for tables like reserved which have only certain modifiers
            error(  "Error accessing value in Pool class.\nNo '${modifier}' modifier exists for aspect, '${aspect}'." %
                    {modifier = eModifier.name, aspect = eAspect.name});
        end

        return nRet;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.cycle
    @desc Causes the Pool to cycle based on the cycle value (after all modifiers have been applied).
    <br>This is used for things like regeneration of mana, regen and/or poisoning of life, consumption of fuel, etc.
    @param nMultiple number|nil If a number is provided, it will cycle the number of times input, otherwise, once.
    @ret oPool Pool The Pool object.
    !]]
    cycle = function(this, cdat, nMultiplier, bSkipOnEmpty, bSkipOnLow, bSkipOnFull, bSkipOnIncrease, bSkipOnDecrease)
        local pro       = cdat.pro;
        local nCurrent  = pro[_sAspectCurrent];
        local nMax      = pro[_sAspectMax][_nFinal];
        local nCycle    = pro[_sAspectCycle][_nFinal]; --TODO LEFT OFF HERE

        if (nCurrent < nMax and nCycle ~= 0) then
            --process the cycle
            nMultiplier = (rawtype(nMultiplier) == "number" and nMultiplier ~= 0) and nMultiplier or 1;
            pro[_sAspectCurrent] = pro[_sAspectCurrent] + nCycle * nMultiplier;

            --clamp the current value
            clampCurrent(this, cdat, nCurrent, bSkipOnEmpty, bSkipOnLow, bSkipOnFull, bSkipOnIncrease, bSkipOnDecrease);

            local nNew = pro[_sAspectCurrent];

            --run the cycle event if active
            if (pro.activeEvents[_sOnCycle]) then
                pro.events[_sOnCycle](  this, nCycle, nMultiplier,
                                        nCurrent, nNew, nMax,
                                        bSkipOnEmpty, bSkipOnLow, bSkipOnFull,
                                        bSkipOnIncrease, bSkipOnDecrease);
            end

            --run the onEmpty or onFull events if active
            if (not bSkipOnFull and nNew == pro[_sAspectMax][_nFinal]) then --onFull TODO not coorrect!

                if (pro.activeEvents[_sOnFull]) then
                    pro.events[_sOnFull](this);
                end

            elseif (not bSkipOnEmpty and nNew == 0) then --onEmpty

                if (pro.activeEvents[_sOnEmpty]) then
                    pro.events[_sOnEmpty](this);
                end

            end

            --run the onIncrease and onDecrease events
            if (not bSkipOnIncrease and nCycle > 0) then --onIncrease

                if (pro.activeEvents[_sOnIncrease]) then
                    pro.events[_sOnIncrease](this);
                end

            elseif (not bSkipOnDecrease and nCycle < 0) then --onDecrease

                if (pro.activeEvents[_sOnDecrease]) then
                    pro.events[_sOnDecrease](this);
                end

            end

        end

        return this;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.set
    @desc TODO
    @ex TODO
    @param nValue number The value to which the item should be set.
    @param eAspect Pool.ASPECT|nil If provided, this refers to the aspect of the pool to set such as MAX or CYCLE.
    <br>If not provided it will default to CURRENT.
    @param eModifier Pool.MODIFIER|nil If provided, this indicates which modifier to set such as BASE, BASE_BONUS, etc.
    <br>If not provided, it will default to BASE.
    <br><strong>Note</strong>: not all aspects have all modifiers. E.g., Pool.ASPECT.CURRENT has no modifiers whatsoever.
    !]]
    set = set,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setEmpty
    @desc Set the Pool to empty (if not already empty).
    @ret oPool Pool The Pool object.
    !]]
    setEmpty = function(this, cdat)
        local pro       = cdat.pro;

        --process only if the Pool isn't already empty
        if (pro[_sAspectCurrent] > 0) then
            pro[_sAspectCurrent] = 0;

            pro.isEmpty     = true;
            pro.isLow       = false;
            pro.isFull      = false;

            if (pro.activeEvents[_sOnEmpty]) then
                pro.events[_sOnEmpty](this);
            end

        end

        return this;

    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setEventActive
    @desc
    @param
    @ret oPool Pool The Pool object.
    !]]
    setEventActive = function(this, cdat, eEvent, bFlag)
        local pro = cdat.pro;

        if (type(eEvent) ~= "Pool.EVENT") then
            error("Error setting event callback in Pool class.\nExpected Pool.EVENT.Get type, "..type(eEvent)..'.');
        end

        local sEvent = eEvent.value;
        pro.activeEvents[sEvent] = rawtype(bFlag == "boolean") and (bFlag and pro.events[sEvent] ~= eventPlaceholder) or false;

        return this;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setEventCallback
    @desc
    @param
    @ret oPool Pool The Pool object.
    !]]
    setEventCallback = function(this, cdat, eEvent, fCallback)
        local pro = cdat.pro;

        if (type(eEvent) ~= "Pool.EVENT") then
            error("Error setting event callback in Pool class.\nExpected Pool.EVENT.Get type, "..type(eEvent)..'.');
        end

        local sEvent = eEvent.value;

        if (rawtype(fCallback) == "function") then
            pro.events[sEvent]          = fCallback;
            pro.activeEvents[sEvent]    = true;

        else
            pro.events[sEvent]          = eventPlaceholder;
            pro.activeEvents[sEvent]    = false;
        end

        return this;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setFull
    @desc Sets Pool to full (if not already full).
    @ret oPool Pool The Pool object.
    !]]
    setFull = function(this, cdat) --TODO account for reserved
        local pro           = cdat.pro;
        local nMax          = pro[_sAspectMax][_nFinal];
        local nAvailable    = nMax - pro[_sAspectReserved];

        --process only if the Pool isn't already full
        if (pro[_sAspectCurrent] < nAvailable) then
            pro[_sAspectCurrent] = nAvailable;

            pro.isEmpty     = false;
            pro.isLow       = nCurrent <= (nMax * pro.lowMarker);
            pro.isFull      = nCurrent >= (nMax * pro.fullMarker);

            if (pro.activeEvents[_sOnFull]) then
                pro.events[_sOnFull](this);
            end

        end

        return this;
    end,

    setFullMarker = function(this, cdat, nValue)
        --must be float
        --must be great than low
    end,
    --TODO setLow
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
