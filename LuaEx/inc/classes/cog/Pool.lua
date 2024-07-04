--LOCALIZATION
local floor 			= math.floor;
local math				= math;
local rawtype           = rawtype;
local type				= type;

--CLASS-LEVEL ENUMS
local _eAspect      = enum("Pool.ASPECT",   {"CURRENT", "MAX", "REGEN", "RESERVED_FLAT", "RESERVED_PERCENT"}, {"current", "max", "regen", "reserved_flat", "reserved_percent"}, true);

--local _eMode        = enum("Pool.MODE",     {"FLAT", "PERCENT"}, {"flat", "percent"}, true);

local _eModifier    = enum("Pool.MODIFIER", {   "BASE",     "FINAL",    "MAX",
                                                "BASE_BONUS",           "BASE_PENALTY",
                                                "MULTIPLICATIVE_BONUS", "MULTIPLICATIVE_PENALTY",
                                                "ADDITIVE_BONUS",       "ADDITIVE_PENALTY"},
                                                {1, 2, 3, 4, 5, 6, 7, 8, 9}, true);

local _eEvent       = enum("Pool.EVENT",    {"ON_INCREASE", "ON_DECREASE",  "ON_EMPTY", "ON_FULL",  "ON_REGEN", "ON_RESERVE", "ON_UNRESERVE"},
                                            {"onIncrease",  "onDecrease",   "onEmpty",  "onFull",   "onRegens", "OnReserve",  "onUnreserve"}, true);

--ASPECT LOCALIZATION
local _eAspectCurrent           = _eAspect.CURRENT;
local _eAspectMax               = _eAspect.MAX;
local _eAspectRegen             = _eAspect.REGEN;
local _eAspectReservedFlat      = _eAspect.RESERVED_FLAT;
local _eAspectReservedPercent   = _eAspect.RESERVED_PERCENT;

local _sAspectCurrent           = _eAspectCurrent.value;
local _sAspectMax               = _eAspectMax.value;
local _sAspectRegen             = _eAspectRegen.value;
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
local _eOnRegen     = _eEvent.ON_REGEN;
local _eOnReserve   = _eEvent.ON_RESERVE;
local _eOnUnreserve = _eEvent.ON_UNRESERVE;

local _sOnIncrease  = _eOnIncrease.value;
local _sOnDecrease  = _eOnDecrease.value;
local _sOnEmpty     = _eOnEmpty.value;
local _sOnFull      = _eOnFull.value;
local _sOnRegen     = _eOnRegen.value;
local _sOnReserve   = _eOnReserve.value;
local _sOnUnreserve = _eOnUnreserve.value;

local _nDefaultReverseMax       = 0.5;
local _nReverseHardMax          = 0.99; --the max reservation allowed

--Final = ((nBase + nBaseBonus - nBasePenalty) * (1 + nMultBonus - nMultPenalty)) + nAddBonus - nAddPenalty;

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
@fqxn LuaEx.Classes.CoG.Pool.Functions
@desc
@param
@ret
!]]
local function updateFinalValues(this, cdat, bCurrentAndMax, bRegen)
    local pro   = cdat.pro;

    if (bRegen) then
        pro.regenFinal = pro.regen.getValue();
    end

    if (bCurrentAndMax) then
        local nMax      = pro.max.getValue();
        pro.maxFinal    = nMax;
        local nCurrent  = pro.current;
        pro.current  = (nCurrent <= nMax) and (nCurrent >= 0 and nCurrent or 0) or nMax;
    end

end





local function setValue(this, cdat, sIndex, nMod, nValue)

    if (nMod ~= _nValueFinal) then
        local pro       = cdat.pro;
        local tValue    = pro[sIndex];

        if (sIndex == "current") then
            tValue[nMod] = nValue;
            local nMax = pro.max.final;

            local nFinal = calulateFinal(this, cdat, "current");
            tValue[_nValueFinal] = nValue <= nMax and nValue or nMax;

        elseif (sIndex == "max") then

        elseif (sIndex == "regen") then

        end

    end

end

local function clampCurrent(this, cdat)
    local pro           = cdat.pro;
    local nMax          = pro[_sAspectMax][_nFinal];
    local nCurrent      = pro[_sAspectCurrent];
    --local nReserved     = pro[_sAspectReserved][_nFinal]; TODO
    local nAvailable    = nMax--nMax - nReserved;

    if (nCurrent <= 0 or nAvailable <= 0) then
        pro[_sAspectCurrent] = 0;
    else
        pro[_sAspectCurrent] = (nCurrent <= nMax) and nCurrent or nMax;
    end

end







--[[ORDER OF ASPECT UPDATE
regen

max (checks reserved)

reserved (checks max)




current
]]










--GOOD, WORKING FUNCTION
local function eventPlaceholder() end

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



local function attemptSettingReservedFlat(this, cdat, nValue, nModifier)
    local bRet          = false;
    local nOverage      = 0;
    local pro           = cdat.pro;
    local tMax          = pro[_sAspectMax];
    local nMaxlife      = tMax[_sFinal];
    local tReserved     = pro[_sAspectReservedFlat];
    local nOldBaseValue = tReserved[_nValueBase];
    local nNewBaseValue = nFlat + nMax * nPercent;

    tReserved[_nValueBase] = nNewBaseValue >= 0 and nNewBaseValue or 0;

    local nFinal = calulateFinal(this, cdat, _sAspectReserved);
    local nTotalPercent = nFinal / nMax;

    if (nTotalPercent <= tReserved[_nMax]) then
        tReserved[_nFinal] = nFinal;

        if bIsPercent then
            tReserved.percent = nPercent;
        else
            tReserved.flat = nFlat;
        end

        tReserved.remaining = nMax - nFinal;
        bRet = true;
    else
        tReserved[_nValueBase] = nOldBaseValue;
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
    local nPreviousBase = pro[_sAspectCurrent];
    local nNewBase      = pro[_sAspectCurrent];
    local sEvent        = "NONE";

    if not (type(nValue) == "number") then
        error("Error setting value in Pool class.\nExpected type number; got type: "..type(nValue)..'.');
    end

    if (nModifier == _nFinal) then
        error("Error setting value in Pool class.\nFinal values are calculated internally and may not be set manually.");
    end

    --process CURRENT aspect
    if (sAspect == _sAspectCurrent) then --since current doesn't have a table

        if (nPrevious ~= nValue) then
            pro[_sAspectCurrent] = nValue;
            clampCurrent(this, cdat);
            nNew                 = pro[_sAspectCurrent];
            bSuccess             = true;

            if (nNew > nPrevious) then --onIncrease

                if (pro.activeEvents[_sOnIncrease]) then
                    pro.events[_sOnIncrease](this);
                end

            elseif (nNew < nPrevious) then --onDecrease

                if (pro.activeEvents[_sOnDecrease]) then
                    pro.events[_sOnDecrease](this);
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

        --process REGEN aspect
        elseif (sAspect == _sAspectRegen) then
            pro[sAspect][nModifier] = nValue;
            nNew                    = calulateFinal(this, cdat, sAspect);
            pro[sAspect][_nFinal]   = nNew;
            bSuccess                = true;

        --process RESERVED_FLAT aspect
        elseif (sAspect == _sAspectReservedFlat) then
            bSuccess, nOverage = attemptSettingReservedFlat(this, cdat, nValue, nModifier);
            --TODO LEFT OFF HERE...create these methods
        --process RESERVED_PERCENT aspect
        elseif (sAspect == _sAspectReservedPercent) then
            bSuccess, nOverage = attemptSettingReservedPercent(this, cdat, nValue, nModifier);
        end


    else --for tables like reserved which have only certain modifiers
        error(  "Error setting value in Pool class.\nNo '${modifier}' modifier exists for aspect, '${aspect}'." %
                {modifier = eModifier.name, aspect = eAspect.name});
    end

    return this, bSuccess, nOverage;
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
        [_sOnRegen]     = false,
        [_sOnReserve]   = false,
        [_sOnUnreserve] = false,
    },
    events = {
        [_sOnIncrease]  = eventPlaceholder,
        [_sOnDecrease]  = eventPlaceholder,
        [_sOnEmpty]     = eventPlaceholder,
        [_sOnFull]      = eventPlaceholder,
        [_sOnRegen]     = eventPlaceholder,
        [_sOnReserve]   = eventPlaceholder,
        [_sOnUnreserve] = eventPlaceholder,
    },
    [_sAspectCurrent] = 1,
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
    [_sAspectRegen]    = {
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
    hasReservation      = 0, --cached value updated on change
    --baseMod         = 0, --             _nBaseBonus - _nBasePenalty
    --multMod         = 1, --1      +     _nMultBonus - _nMultPenalty
    --addMod          = 0, --_nValueBase  _nAddBonus  - _nAddPenalty
},
{--PUBLIC

    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.Pool
    @desc The constructor for the <b>Pool</b> class.
    @param nMax number|nil The maximum value of the Pool.
    @param nCurrent number|nil The current value of the Pool.
    @param nRegen number|nil The amount the Pool should regenerate when the <a href="#LuaEx.Classes.CoG.Pool.Methods.regen">regen</a> method is called.
    @param nReservation number|nil The reservation value of the Pool.
    !]]
    Pool = function(this, cdat, nMax, nCurrent, nRegen)
        local pro   = cdat.pro;
        nMax        = type(nMax) 		== "number"	and nMax	    or 1;
        nCurrent	= type(nCurrent) 	== "number" and nCurrent    or 1;
        nRegen 	    = type(nRegen) 		== "number" and nRegen 		or 0;
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
        pro[_sAspectRegen][_nBase]      = nRegen;
        pro[_sAspectRegen][_nFinal]     = nRegen;
    end,


    adjust = function()
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.get
    @desc TODO
    @ex TODO
    @param eAspect Pool.ASPECT|nil If provided, this refers to the aspect of the pool to get such as MAX or REGEN.
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

        elseif pro[sAspect][nModifier] then
            nRet = pro[sAspect][nModifier];

        else --for tables like reserved which have only certain modifiers
            error(  "Error accessing value in Pool class.\nNo '${modifier}' modifier exists for aspect, '${aspect}'." %
                    {modifier = eModifier.name, aspect = eAspect.name});
        end

        return nRet;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.regen
    @desc Causes the Pool to regenerate based on the regen value (after all modifiers have been applied).
    <br>Note: The (active) regen event is called only if a regen is possible (that is, if current is less than max).
    @param nMultiple number|nil If a number is provided, it will regen the number of times input, otherwise, once.
    @ret oPool Pool The Pool object.
    !]]
    regen = function(this, cdat, nMultiplier, bSkipOnFull, bSkipOnEmpty, bSkipOnIncrease, bSkipOnDecrease)
        local pro       = cdat.pro;
        local nCurrent  = pro[_sAspectCurrent];
        local nMax      = pro[_sAspectMax][_nFinal];
        local nRegen    = pro[_sAspectRegen][_nFinal];

        if (nCurrent < nMax and nRegen ~= 0) then
            --process the regen
            nMultiplier = (rawtype(nMultiplier) == "number" and nMultiplier ~= 0) and nMultiplier or 1;
            pro[_sAspectCurrent] = pro[_sAspectCurrent] + nRegen * nMultiplier;

            --clamp the current value
            clampCurrent(this, cdat);

            local nNew = pro[_sAspectCurrent];

            --run the regen event if active
            if (pro.activeEvents[_sOnRegen]) then
                pro.events[_sOnRegen](  this, nRegen, nMultiplier,
                                        nCurrent, nNew, nMax,
                                        bSkipOnFull, bSkipOnEmpty,
                                        bSkipOnIncrease, bSkipOnDecrease);
            end

            --run the onEmpty or onFull events if active
            if (not bSkipOnFull and nNew == pro[_sAspectMax][_nFinal]) then --onFull

                if (pro.activeEvents[_sOnFull]) then
                    pro.events[_sOnFull](this);
                end

            elseif (not bSkipOnEmpty and nNew == 0) then --onEmpty

                if (pro.activeEvents[_sOnEmpty]) then
                    pro.events[_sOnEmpty](this);
                end

            end

            --run the onIncrease and onDecrease events
            if (not bSkipOnIncrease and nRegen > 0) then --onIncrease

                if (pro.activeEvents[_sOnIncrease]) then
                    pro.events[_sOnIncrease](this);
                end

            elseif (not bSkipOnDecrease and nRegen < 0) then --onDecrease

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
    @param eAspect Pool.ASPECT|nil If provided, this refers to the aspect of the pool to set such as MAX or REGEN.
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
    setFull = function(this, cdat)
        local pro       = cdat.pro;
        local nMax      = pro[_sAspectMax][_nFinal];

        --process only if the Pool isn't already full
        if (pro[_sAspectCurrent] < nMax) then
            pro[_sAspectCurrent] = nMax;

            if (pro.activeEvents[_sOnFull]) then
                pro.events[_sOnFull](this);
            end

        end

        return this;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
