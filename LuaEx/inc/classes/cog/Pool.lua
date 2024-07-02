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

--updates the max value of the "current" Protean - called whenever the "max" value changes
local function updateCurrentMax(this, cdat)--TODO check this
    local pro = cdat.pro;
    pro.current.setValue(_nLimitMax, pro.maxFinal);
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
        pro.regenFinal      = pro.regen.getValue();
    end

    if (bCurrentAndMax) then
        local nMax          = pro.max.getValue();
        local nCurrent      = pro.current.getValue();

        pro.maxFinal        =   nMax-- >= 0 and nMax or 1;
        pro.currentFinal    =   nCurrent-- <= nMax and
                               --(nCurrent >= 0 and nCurrent or 0)
                            --    or nMax;
    end

end

local function setCurrent(this, cdat, nTarget, bForceEmpty)
    local bSetEmpty = bForceEmpty or nTarget <= 0;
    local oCurrent  = cdat.pro.current;

    if (bSetEmpty) then
        local nAddativeBonus    = oCurrent.getValue(_nAddBonus);
        local nAddativePenalty  = oCurrent.getValue(_nAddPenalty);
        oCurrent.setValue(nAddativePenalty - nAddativeBonus);
    else
        oCurrent.setValue(nTarget);
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
        onAdjust        = false,
        onIncrease      = false,
        onDecrease      = false,
        onEmpty         = false,
        onFull          = false,
        onRegen         = false,
    },
    events = {
        onAdjust        = eventPlaceholder,
        onIncrease      = eventPlaceholder,
        onDecrease      = eventPlaceholder,
        onEmpty         = eventPlaceholder,
        onFull          = eventPlaceholder,
        onRegen         = eventPlaceholder,
    },
    current             = {
        [_nValueBase]   = 0,
        [_nValueFinal]  = 0,
        [_nBaseBonus]   = 0,
        [_nBasePenalty] = 0,
        [_nMultBonus]   = 0,
        [_nMultPenalty] = 0,
        [_nAddBonus]    = 0,
        [_nAddPenalty]  = 0,
        min             = 0,
        max             = 1,
        baseMod         = 0, --             _nBaseBonus - _nBasePenalty
        multMod         = 1, --1      +     _nMultBonus - _nMultPenalty
        addMod          = 0, --_nValueBase  _nAddBonus  - _nAddPenalty
        final           = 0, --cached value updated on change
    },
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
        baseMod         = 0, --             _nBaseBonus - _nBasePenalty
        multMod         = 1, --1      +     _nMultBonus - _nMultPenalty
        addMod          = 0, --_nValueBase  _nAddBonus  - _nAddPenalty
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
        baseMod         = 0, --             _nBaseBonus - _nBasePenalty
        multMod         = 1, --1      +     _nMultBonus - _nMultPenalty
        addMod          = 0, --_nValueBase  _nAddBonus  - _nAddPenalty
        final           = 0, --cached value updated on change
    },
    --isEmpty         = false, --used to account for zero current value and addative modifiers
},
{--PUBLIC
    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.Pool
    @desc The constructor for the <b>Pool</b> class.
    @param nMax number The maximum value of the Pool.
    @param nCurrent number The current value of the Pool.
    @param nRegen number The amount the Pool should regenerate when the <a href="#LuaEx.Classes.CoG.Pool.Methods.regen">regen</a> method is called.
    !]]
    Pool = function(this, cdat, nMax, nCurrent, nRegen)
        local pro   = cdat.pro;
        nMax        = type(nMax) 		== "number"	and nMax	    or 1;
        nCurrent	= type(nCurrent) 	== "number" and nCurrent    or 1;
        nRegen 	    = type(nRegen) 		== "number" and nRegen 		or 0;

        if (nMax <= 0) then
            error("Error creating Pool object.\nMax value must be positive.");
        end

        if (nCurrent <= 0) then
            error("Error creating Pool object.\nCurrent value must be positive.");
        end

        --if (nCurrent > nMax) then
            --error("Error creating Pool object.\nThe current value must be less than or equal to max.");
        --end

        --create the proteans
        pro.max[_nValueBase]     = nMax;
        pro.current[_nValueBase] = nCurrent;
        pro.regen[_nValueBase]   = nRegen;


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
            error("Error adjusting current base value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        local pro       = cdat.pro;
        local oCurrent  = pro.current;

        oCurrent.setValue(oCurrent.getValue(_nValueBase) + nTarget);

        pro.currentFinal = oCurrent.getValue();
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.adjustCurrentModifier
    @desc Adjusts the value of the given 'current' modifier.
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
    adjustCurrentModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("current", "set", nModifier, nValue);
        local pro       = cdat.pro;
        local oCurrent  = pro.current;

        oCurrent.setValue(nModifier, nValue + oCurrent.getValue(nModifier));
        pro.currentFinal = oCurrent.getValue();
        --updateFinalValues(this, cdat, true, false);
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
        updateCurrentMax(this, cdat);
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
        updateCurrentMax(this, cdat);
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
        return cdat.pro.current.final;
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
        return cdat.pro.currentFinal <= 0;
    end,


    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.isFull
    @desc Determines whether the Pool is full.
    <br>This is true when the current value is (<em>greater than or</em>) equal to the maximum value.
    @ret bEmpty boolean True if the Pool is full, false otherwise.
    !]]
    isFull = function(this, cdat)
        local pro = cdat.pro;
        return pro.currentFinal >= pro.maxFinal;
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
            error("Error setting current base value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

        setValue(this, cdat, "current", _nValueBase, nValue);
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
    @desc Set the Pool to empty.
    @ret oPool Pool The Pool object.
    !]]
    setEmpty = function(this, cdat) --TODO FINISHs
        processZeroCurrentValue(this, cdat);
        updateFinalValues(this, cdat, true, false);
    end,

--Final = ((nBase + nBaseBonus - nBasePenalty) * (1 + nMultBonus - nMultPenalty)) + nAddBonus - nAddPenalty;
    --[[!
    @fqxn LuaEx.Classes.CoG.Pool.Methods.setFull
    @desc Sets Pool is full.
    <br>This is true when the current value is (<em>greater than or</em>) equal to the maximum value.
    @ret oPool Pool The Pool object.
    !]]
    setFull = function(this, cdat) --TODO FINISH
        local pro = cdat.pro;
        return pro.currentFinal >= pro.maxFinal;
    end,

    setPortion = function(this, cdat) --TODO FINISH

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
