local type				= type;
local math				= math;
local floor 			= math.floor;

local _nValueBase     = Protean.VALUE_BASE;
local _nValueFinal    = Protean.VALUE_FINAL;
local _nBaseBonus     = Protean.BASE_BONUS;
local _nBasePenalty   = Protean.BASE_PENALTY;
local _nMultBonus     = Protean.MULTIPLICATIVE_BONUS;
local _nMultPenalty   = Protean.MULTIPLICATIVE_PENALTY;
local _nAddBonus      = Protean.ADDATIVE_BONUS;
local _nAddPenalty    = Protean.ADDATIVE_PENALTY;
local _nLimitMax      = Protean.LIMIT_MAX;



local _nDefaultReverseMax   = 0.5;
local _nReverseHardCeiling  = 0.99; --the max reservation allowed

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












local function eventPlaceholder() end

local function calulateFinal(this, cdat, sIndex)
    local pro       = cdat.pro;
    local tValue    = pro[sIndex];
    return (tValue[_nValueBase] + tValue[_nBaseBonus] - tValue[_nBasePenalty]) *
           (1 + tValue[_nMultBonus] - tValue[_nMultPenalty]) +
           (tValue[_nAddBonus] - tValue[_nAddPenalty]);
end


local function processEvent(this, cdat, sEvent)
    local pro           = cdat.pro;
    local tActiveEvents = pro.activeEvents;
    local tEvents       = pro.events;

    if (tActiveEvents[sEvent]) then
        tEvents[sEvent](this);

    elseif (tActiveEvents.onChange) then
        tEvents.onChange(this);

    end

end


local function clampCurrent()
    local pro       = cdat.pro;
    local nMax      = pro.max[_nValueFinal];
    local nCurrent  = pro.current;

    if (pro.hasReservation) then
        pro.current     =   (nCurrent <= nMax)                  and
                            (nCurrent >= 0 and nCurrent or 0)   or
                            nMax;
    else
        pro.current     =   (nCurrent <= nMax)                  and
                            (nCurrent >= 0 and nCurrent or 0)   or
                            nMax;
    end

end


local function updateReserved(this, cdat)
    local pro   = cdat.pro;
    local tRes  = pro.reserved;
    local tMax  = pro.max;

    calulateFinal(this, cdat, "reserved");


end



local function attemptReservationSetOLD(this, cdat, bIsPercent, nValue)
    local bRet          = true;
    local pro           = cdat.pro;
    local tMax          = pro.max;
    local nMax          = tMax.final;
    local tReserved     = pro.reserved;
    --local bIsNegative   = nValue;
    --local nBaseValue    = 0;

    if (bIsPercent) then
        local nPercent = tReserved.percent + nValue;

        if (nPercent <= _nReverseHardCeiling) then
            local nOldBaseValue = tReserved[_nValueBase];
            tReserved[_nValueBase] = tReserved.flat + nMax * nPercent;

            if (tReserved[_nValueBase] >= 0) then--TODO allow 0-?
                local nFinal = calulateFinal(this, cdat, "reserved");
                local nTotalPercent = nFinal / nMax;

                if (nTotalPercent <= _nReverseHardCeiling and nTotalPercent <= tReserved.max) then
                    tReserved[_nValueFinal] = nFinal;
                    tReserved.percent = nPercent;
                    bRet = true;
                else
                    tReserved[_nValueBase] = nOldBaseValue;
                end

            end

        end

    else
        local nFlat = tReserved.flat + nValue;
        local nPercent = tReserved.percent;
        local nOldBaseValue = tReserved[_nValueBase];
        tReserved[_nValueBase] = tReserved.flat + nMax * nPercent;

        if (tReserved[_nValueBase] >= 0) then
            local nFinal = calulateFinal(this, cdat, "reserved");
            local nTotalPercent = nFinal / nMax;

            if (nTotalPercent <= _nReverseHardCeiling and nTotalPercent <= tReserved.max) then
                tReserved[_nValueFinal] = nFinal;
                tReserved.flat = nFlat;
                bRet = true;
            else
                tReserved[_nValueBase] = nOldBaseValue;
            end

        end

    end

    --TODO update other final values

    return bRet;
end

local function attemptReservationSet(this, cdat, bIsPercent, nValue)
    local bRet          = false;
    local pro           = cdat.pro;
    local tMax          = pro.max;
    local nMax          = tMax.final;
    local tReserved     = pro.reserved;
    local nPercent      = tReserved.percent;
    local nFlat         = tReserved.flat;
    local nOldBaseValue = tReserved[_nValueBase];

    if bIsPercent then
        nPercent = tReserved.percent + nValue;
    else
        nFlat = tReserved.flat + nValue;
    end

    local nNewBaseValue = nFlat + nMax * nPercent;
    tReserved[_nValueBase] = nNewBaseValue >= 0 and nNewBaseValue or 0;

    local nFinal = calulateFinal(this, cdat, "reserved");
    local nTotalPercent = nFinal / nMax;

    if (nTotalPercent <= tReserved.max) then
        tReserved[_nValueFinal] = nFinal;

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


    return bRet;
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
    @version 2.0
    @todo Complete the binary operator metamethods.
!]]
return class("Pool",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Pool = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    activeEvents = {
        onChange        = false,
        onIncrease      = false,
        onDecrease      = false,
        onEmpty         = false,
        onFull          = false,
        onRegen         = false,
    },
    events = {
        onChange        = eventPlaceholder,
        onIncrease      = eventPlaceholder,
        onDecrease      = eventPlaceholder,
        onEmpty         = eventPlaceholder,
        onFull          = eventPlaceholder,
        onRegen         = eventPlaceholder,
    },
    current             = 0,
    max                 = {
        [_nValueBase]   = 0,
        [_nValueFinal]  = 0,
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,
        [_nAddBonus]    = 0,
        [_nAddPenalty]  = 0,
        min             = 1,
        final           = 0, --cached value updated on change
    },
    regen               = {
        [_nValueBase]   = 0,
        [_nValueFinal]  = 0,
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,
        [_nAddBonus]    = 0,
        [_nAddPenalty]  = 0,
        final           = 0, --cached value updated on change
    },
    reserved            = {
        [_nValueBase]   = 0, --this is updated whenever flat or percent are changed.
        [_nValueFinal]  = 0,
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,        
        max             = _nDefaultReverseMax, --MUST be a percentage
        flat            = 0,
        percent         = 0,
        final           = 0, --cached value updated on change
        remaining       = 0, --cached value updated on change -the difference between max and reserved flat (max - reserved flat)
    },
    hasReservation      = 0,
    --baseMod         = 0, --             _nBaseBonus - _nBasePenalty
    --multMod         = 1, --1      +     _nMultBonus - _nMultPenalty
    --addMod          = 0, --_nValueBase  _nAddBonus  - _nAddPenalty
},
{--PUBLIC

    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setReservation
    @desc Sets an amount of the max pool that should be reserved. When checking current, it will account for reservations.
    <br>Note: if the value is between 0 and .99, it will be considered a percentage reservation rather than a flat value.
    @param nValue number The flat or percentage value of reservation to set.
    @ret bSuccess boolean Whether the reservation was able to be set.
    !]]
    setReservation = function(this, cdat, nValue)
        if (rawtype(nValue) ~= "number") then
            error("Error adding Pool reservation.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        if (nValue == 0) then
            error("Error adding Pool reservation.\nValue must be non-zero.");
        end

        local bIsPercent = math.abs(nValue) <= _nReverseHardCeiling;
        return attemptReservationSet(this, cdat, bIsPercent, nValue);
    end,

    adjustReservation = function(this, cdat, nValue)
        if (rawtype(nValue) ~= "number") then
            error("Error adding Pool reservation.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        if (nValue == 0) then
            error("Error adding Pool reservation.\nValue must be non-zero.");
        end

        local tReserved = cdat.pro.reserved;

        local bIsPercent     = math.abs(nValue) <= _nReverseHardCeiling;
        local nAdjustedValue = bIsPercent and (tReserved.percent + nValue) or (tReserved.flat + nValue);
        return attemptReservationSet(this, cdat, bIsPercent, nAdjustedValue);
    end,

    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.Pool
    @desc The constructor for the <b>Pool</b> class.
    @param nMax number|nil The maximum value of the Pool.
    @param nCurrent number|nil The current value of the Pool.
    @param nRegen number|nil The amount the Pool should regenerate when the <a href="#LuaEx.Classes.CoG.Pool.Methods.regen">regen</a> method is called.
    @param nReservation number|nil The reservation value of the Pool.
    !]]
    Pool = function(this, cdat, nMax, nCurrent, nRegen, nReserved)
        local pro   = cdat.pro;
        nMax        = type(nMax) 		== "number"	and nMax	    or 1;
        nCurrent	= type(nCurrent) 	== "number" and nCurrent    or 1;
        nRegen 	    = type(nRegen) 		== "number" and nRegen 		or 0;
        nReserved   = type(nReserved)   == "number" and nReserved   or 0;

        if (nMax <= 0) then
            error("Error creating Pool object.\nMax value must be positive.");
        end

        if (nCurrent <= 0) then
            error("Error creating Pool object.\nCurrent value must be non-negative.");
        end

        --set the values
        --TODO check and clamp ALL values!
        pro.max[_nValueBase]        = nMax;
        pro.current[_nValueBase]    = nCurrent;
        pro.regen[_nValueBase]      = nRegen;
        pro.reserved[_nValueBase]   = nReserved;
    end,


    adjustByPortion = function(this, cdat) --TODO FINISH

    end,

    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.adjustCurrent
    @desc Adjusts the base value of the 'current' Protean.
    @param nValue number The value by which to adjust the current value.
    @ret oPool Pool The Pool object.
    !]]
    adjustCurrent = function(this, cdat, nValue)

        if (rawtype(nValue) ~= "number") then
            error("Error adjusting Pool's current value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        local pro           = cdat.pro;
        local nCurrent      = pro.current;
        local nMax          = pro.max[_nValueFinal];
        local bIsDecrease   = nValue < 0 and nCurrent ~= 0;
        local bIsIncrease   = nValue > 0 and nCurrent ~= nMax;

        if (bIsDecrease) then
            pro.current = pro.current + nValue;
            clampCurrent(this, cdat);
            processEvent("onDecrease");
        elseif (bIsIncrease) then
            pro.current = pro.current + nValue;
            clampCurrent(this, cdat);
            processEvent("onIncrease");
        end

    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.adjustMax
    @desc Adjusts the base value of the 'max' Protean.
    @param nValue number The value by which to adjust the current value.
    @ret oPool Pool The Pool object.
    !]]
    adjustMax = function(this, cdat, nValue)

        if (rawtype(nValue) ~= "number") then
            error("Error setting max base value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        cdat.pro.max.setValue(_nValueBase, nValue + cdat.pro.max.getValue(_nValueBase));
        updateFinalValues(this, cdat, true, false);
        --updateCurrentMax(this, cdat);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.adjustMaxModifier
    @desc Adjusts the value of the given 'max' modifier.
    <br>
    <h3>Permitted Modifiers</h3>
    <ul>
        <li>Protean.BASE_BONUS</li>
        <li>Protean.BASE_PENALTY</li>
        <li>Protean.MULTIPLICATIVE_BONUS</li>
        <li>Protean.MULTIPLICATIVE_PENALTY</li>
        <li>Protean.ADDATIVE_BONUS</li>
        <li>Protean.ADDATIVE_PENALTY</li>
    </ul>
    @param nModifier number the number of the Protean modifier ID.
    @param nValue number The value by which to adjust.
    @ret oPool Pool The Pool object.
    !]]
    adjustMaxModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("max", "set", nModifier, nValue)
        cdat.pro.max.setValue(nModifier, nValue + cdat.pro.max.getValue(nModifier));
        updateFinalValues(this, cdat, true, false);
        --updateCurrentMax(this, cdat);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.adjustRegen
    @desc Adjusts the base value of the 'regen' Protean.
    @param nValue number The value by which to adjust the current value.
    @ret oPool Pool The Pool object.
    !]]
    adjustRegen = function(this, cdat, nValue)

        if (rawtype(nValue) ~= "number") then
            error("Error setting regen base value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end



        cdat.pro.regen.setValue(_nValueBase, nValue + cdat.pro.regen.getValue(_nValueBase));
        setValue(this, cdat, false, true);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.adjustRegenModifier
    @desc Adjusts the value of the given 'regen' modifier.
    <br>
    <h3>Permitted Modifiers</h3>
    <ul>
        <li>Protean.BASE_BONUS</li>
        <li>Protean.BASE_PENALTY</li>
        <li>Protean.MULTIPLICATIVE_BONUS</li>
        <li>Protean.MULTIPLICATIVE_PENALTY</li>
        <li>Protean.ADDATIVE_BONUS</li>
        <li>Protean.ADDATIVE_PENALTY</li>
    </ul>
    @param nModifier number the number of the Protean modifier ID.
    @param nValue number The value by which to adjust.
    @ret oPool Pool The Pool object.
    !]]
    adjustRegenModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("regen", "set", nModifier, nValue);
        cdat.pro.regen.setValue(nModifier, nValue + cdat.pro.regen.getValue(nModifier));
        updateFinalValues(this, cdat, false, true);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.getCurrent
    @desc Gets the current value of the Pool (after all modifiers have been applied).
    <br><b>Note</b>: this will never exceed the maximum value. While the current
    <br>value can be higher than the max value on the back end, it will always be
    <br>clampled on return to ensure it doesn't exceed the max value during actual,
    <br>applied use.
    @ret nCurrent number The current value of the Pool.
    !]]
    getCurrent = function(this, cdat)
        return cdat.pro.current;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.getCurrentModifier
    @desc
    <br>
    <h3>Permitted Modifiers</h3>
    <ul>
        <li>Protean.BASE_BONUS</li>
        <li>Protean.BASE_PENALTY</li>
        <li>Protean.MULTIPLICATIVE_BONUS</li>
        <li>Protean.MULTIPLICATIVE_PENALTY</li>
        <li>Protean.ADDATIVE_BONUS</li>
        <li>Protean.ADDATIVE_PENALTY</li>
    </ul>
    @param
    @ret
    !]]
    getCurrentModifier = function(this, cdat, nModifier)
        validateModifier("current", "get", nModifier);
        return cdat.pro.value.get(nModifier);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.getMax
    @desc Gets the maximum value of the Pool (after all modifiers have been applied).
    @ret nMax number The max value of the Pool.
    !]]
    getMax = function(this, cdat)
        return cdat.pro.maxFinal;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.getMaxModifier
    @desc
    <br>
    <h3>Permitted Modifiers</h3>
    <ul>
        <li>Protean.BASE_BONUS</li>
        <li>Protean.BASE_PENALTY</li>
        <li>Protean.MULTIPLICATIVE_BONUS</li>
        <li>Protean.MULTIPLICATIVE_PENALTY</li>
        <li>Protean.ADDATIVE_BONUS</li>
        <li>Protean.ADDATIVE_PENALTY</li>
    </ul>
    @param
    @ret
    !]]
    getMaxModifier = function(this, cdat, nModifier)
        validateModifier("max", "get", nModifier);
        return cdat.pro.max.get(nModifier);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.getRegen
    @desc Gets the regen value of the Pool (after all modifiers have been applied).
    @ret nRegen number The regen value of the Pool.
    !]]
    getRegen = function(this, cdat)
        return cdat.pro.regenFinal;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.getRegenModifier
    @desc
    <br>
    <h3>Permitted Modifiers</h3>
    <ul>
        <li>Protean.BASE_BONUS</li>
        <li>Protean.BASE_PENALTY</li>
        <li>Protean.MULTIPLICATIVE_BONUS</li>
        <li>Protean.MULTIPLICATIVE_PENALTY</li>
        <li>Protean.ADDATIVE_BONUS</li>
        <li>Protean.ADDATIVE_PENALTY</li>
    </ul>
    @param
    @ret
    !]]
    getRegenModifier = function(this, cdat, nModifier)
        validateModifier("regen", "get", nModifier);
        return cdat.pro.regen.get(nModifier);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.isEmpty
    @desc Determines whether the Pool is empty.
    <br>This is true when the current value is less or equal to 0.
    @ret bEmpty boolean True if the Pool is empty, false otherwise.
    !]]
    isEmpty = function(this, cdat)
        return cdat.pro.current <= 0;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.isFull
    @desc Determines whether the Pool is full.
    <br>This is true when the current value is (<em>greater than or</em>) equal to the maximum value.
    @ret bEmpty boolean True if the Pool is full, false otherwise.
    !]]
    isFull = function(this, cdat)
        local pro = cdat.pro;
        return pro.current >= pro.max[_nValueFinal];
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.regen
    @desc Causes the Pool to regenerate based on the regen value (after all modifiers have been applied).
    <br>Note: The (active) regen event is called only if a regen is possible (that is, if current is less than max).
    @param nMultiple number|nil If a number is provided, it will regen the number of times input, otherwise, once.
    @ret oPool Pool The Pool object.
    !]]
    regen = function(this, cdat, nMultiple)
        local pro       = cdat.pro;
        local nCurrent  = pro.currentFinal;
        local nBase     = pro.current.getValue(_nValueBase);
        local nMax      = pro.maxFinal

        if (nCurrent < nMax) then
            nMultiple = (rawtype(nMultiple) == "number" and nMultiple ~= 0) and nMultiple or 1;
            local nRegen = pro.regenFinal;

            pro.current.setValue(nBase + nRegen * nMultiple);
            updateFinalValues(this, cdat, true, false);

            if (pro.activeEvents.onRegen) then
                pro.events.onRegen(this);
            end

        end

        return this;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setCurrent
    @desc Sets the base value of the 'current' Protean.
    <br>Note: if the 'current' value is set to 0, it will nullify all bonuses and penalties until it goes above 0 again.
    @param nValue number The value to set.
    @ret oPool Pool The Pool object.
    !]]
    setCurrent = function(this, cdat, nValue)

        if (rawtype(nValue) ~= "number") then
            error("Error setting Pool's current value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        local pro           = cdat.pro;
        local nCurrent      = pro.current;
        local nMax          = pro.max[_nValueFinal];
        local bIsDecrease   = nValue < nCurrent and nCurrent ~= 0;
        local bIsIncrease   = nValue > nCurrent and nCurrent ~= nMax;

        if (bIsDecrease) then
            pro.current = nValue;
            clampCurrent(this, cdat);
            processEvent("onDecrease");
        elseif (bIsIncrease) then
            pro.current = nValue;
            clampCurrent(this, cdat);
            processEvent("onIncrease");
        end
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setCurrentModifier
    @desc Sets the value of the given 'current' modifier.
    <br>
    <h3>Permitted Modifiers</h3>
    <ul>
        <li>Protean.BASE_BONUS</li>
        <li>Protean.BASE_PENALTY</li>
        <li>Protean.MULTIPLICATIVE_BONUS</li>
        <li>Protean.MULTIPLICATIVE_PENALTY</li>
        <li>Protean.ADDATIVE_BONUS</li>
        <li>Protean.ADDATIVE_PENALTY</li>
    </ul>
    @param nModifier number the number of the Protean modifier ID.
    @param nValue number The value to set.
    @ret oPool Pool The Pool object.
    !]]
    setCurrentModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("current", "set", nModifier, nValue);
        cdat.pro.current.setValue(nModifier, nValue);
        updateFinalValues(this, cdat, true, false);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setEmpty
    @desc Set the Pool to empty (if not already empty).
    @ret oPool Pool The Pool object.
    !]]
    setEmpty = function(this, cdat)
        local pro       = cdat.pro;

        --process only if the Pool isn't already empty
        if (pro.current > 0) then
            pro.current = 0;

            processEvent("onEmpty");
        end

    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setFull
    @desc Sets Pool to full (if not already full).
    @ret oPool Pool The Pool object.
    !]]
    setFull = function(this, cdat)
        local pro       = cdat.pro;
        local nMax      = pro.max[_nValueFinal];

        --process only if the Pool isn't already full
        if (pro.current ~= nMax) then
            pro.current = nMax;

            processEvent("onFull");
        end

        return this;
    end,

    setPortion = function(this, cdat, nFloat) --TODO FINISH
        local pro = cdat.pro;

        if (rawtype(nValue) ~= "number") then
            error("Error setting Pool current value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        local nTarget = pro.max[_nValueFinal] * nFloat;
        clampAndSetCurrent(nTarget);

        --processEvent();
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setMax
    @desc Sets the base value of the 'max' Protean.
    @param nValue number The value to set.
    @ret oPool Pool The Pool object.
    !]]
    setMax = function(this, cdat, nValue)

        if (rawtype(nValue) ~= "number") then
            error("Error setting max base value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        cdat.pro.max.setValue(_nValueBase, nValue);
        updateFinalValues(this, cdat, true, false);
        updateCurrentMax(this, cdat);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setMaxModifier
    @desc Sets the value of the given 'max' modifier.
    <br>
    <h3>Permitted Modifiers</h3>
    <ul>
        <li>Protean.BASE_BONUS</li>
        <li>Protean.BASE_PENALTY</li>
        <li>Protean.MULTIPLICATIVE_BONUS</li>
        <li>Protean.MULTIPLICATIVE_PENALTY</li>
        <li>Protean.ADDATIVE_BONUS</li>
        <li>Protean.ADDATIVE_PENALTY</li>
    </ul>
    @param nModifier number the number of the Protean modifier ID.
    @param nValue number The value to set.
    @ret oPool Pool The Pool object.
    !]]
    setMaxModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("max", "set", nModifier, nValue)
        cdat.pro.max.setValue(nModifier, nValue);
        updateFinalValues(this, cdat, true, false);
        updateCurrentMax(this, cdat);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setRegen
    @desc Sets the base value of the 'regen' Protean.
    @param nValue number The value to set.
    @ret oPool Pool The Pool object.
    !]]
    setRegen = function(this, cdat, nValue)

        if (rawtype(nValue) ~= "number") then
            error("Error setting regen base value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        cdat.pro.regen.setValue(_nValueBase, nValue);
        updateFinalValues(this, cdat, false, true);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setRegenModifier
    @desc Sets the value of the given 'regen' modifier.
    <br>
    <h3>Permitted Modifiers</h3>
    <ul>
        <li>Protean.BASE_BONUS</li>
        <li>Protean.BASE_PENALTY</li>
        <li>Protean.MULTIPLICATIVE_BONUS</li>
        <li>Protean.MULTIPLICATIVE_PENALTY</li>
        <li>Protean.ADDATIVE_BONUS</li>
        <li>Protean.ADDATIVE_PENALTY</li>
    </ul>
    @param nModifier number the number of the Protean modifier ID.
    @param nValue number The value to set.
    @ret oPool Pool The Pool object.
    !]]
    setRegenModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("regen", "set", nModifier, nValue);
        cdat.pro.regen.setValue(nModifier, nValue);
        updateFinalValues(this, cdat, false, true);
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setEventActive
    @desc
    @param
    @ret oPool Pool The Pool object.
    !]]
    setEventActive = function(this, cdat, sEvent, bFlag)
        local pro = cdat.pro;

        if not (rawtype(sEvent) == "string" and pro.events[sEvent]) then
            error("Error setting event callback in Pool class.\nInvalid event type.");
        end

        pro.activeEvents[sEvent] = rawtype(bFlag == "boolean") and (bFlag and pro.events[sEvent] ~= eventPlaceholder) or false;
        return this;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setEventCallback
    @desc
    @param
    @ret oPool Pool The Pool object.
    !]]
    setEventCallback = function(this, cdat, sEvent, fCallback)
        local pro = cdat.pro;

        if not (rawtype(sEvent) == "string" and pro.events[sEvent]) then
            error("Error setting event callback in Pool class.\nInvalid event type.");
        end

        if (rawtype(fCallback) == "function") then
            pro.events[sEvent]          = fCallback;
            pro.activeEvents[sEvent]    = true;

        else
            pro.events[sEvent]          = eventPlaceholder;
            pro.activeEvents[sEvent]    = false;
        end

        return this;
    end,

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
