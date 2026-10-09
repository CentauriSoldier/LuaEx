--LOCALIZATION
local floor 			= math.floor;
local math				= math;
local rawtype           = rawtype;
local type				= type;
--CLASS-LEVEL ENUMS                                       Note: AVAILABLE, CYCLE and RESERVED are calculated values and cannot be set directly
--[[!
    @fqxn CoG.Pool.Enums.ASPECT
    @desc Used in class methods for setting/getting values.
    <ul>
        <li><b class="text-primary">AVAILABLE</b>
            <p>Used for getting the total <b>Available</b> (<i>Max - Reserved</i>).
            <br>This value is cached and changes only when the Pool's <b>Max</b> or <b>Reserved</b> values change.</p>
        </li>
        <li><b class="text-primary">CURRENT</b>
            <p>Used for getting the <b>Current</b> value.</p>
        </li>
        <li><b class="text-primary">CYCLE</b>
            <p>Used for getting the <b>Cycle</b> amount.</p>
        </li>
        <li><b class="text-primary">RESERVED</b>
            <p>Used for getting the total <b>Reserved</b> value.</p>
        </li>
        <li><b class="text-primary">MAX</b>
            <p>Used for setting/getting <b>Max</b> values.</p>
        </li>
        <li><b class="text-primary">CYCLE_FLAT</b>
            <p>Used for setting/getting <b>Cycle Flat</b> values.</p>
        </li>
        <li><b class="text-primary">CYCLE_PERCENT</b>
            <p>Used for setting/getting <b>Cycle Percent</b> values.</p>
        </li>
        <li><b class="text-primary">RESERVED_FLAT</b>
            <p>Used for setting/getting <b>Reserved Flat</b> values.</p>
        </li>
        <li><b class="text-primary">RESERVED_PERCENT</b>
            <p>Used for setting/getting <b>Reserved Percent</b> values.</p>
        </li>
    </ul>
    @ex
    local oPool = Pool(200, 80); --create the Pool object with 200 max and 80 current
    oPool.set(0.36, Pool.ASPECT.RESERVED_PERCENT); --reserve 36% of the Pool
    print("Reserved: "..oPool.get(Pool.ASPECT.RESERVED)); --> Reserved: 72.0
    print("Available: "..oPool.get(Pool.ASPECT.AVAILABLE)); --> Available: 128.0
    oPool.set(0.10, Pool.ASPECT.MAX, Pool.MODIFIER.MULTIPLICATIVE_BONUS); --adjust the max value by 10%
    print("Max: "..oPool.get(Pool.ASPECT.MAX)); --> Max: 220.0
    print("Reserved: "..oPool.get(Pool.ASPECT.RESERVED)); --> Reserved: 79.2
    print("Available: "..oPool.get(Pool.ASPECT.AVAILABLE)); --> Available: 140.8
    @ex
    local oPool = Pool(100, 20);
    oPool.set(10, Pool.ASPECT.CYCLE_FLAT);
    oPool.cycle(); --current is now 30
!]]
local _eAspect      = enum("Pool.ASPECT",   {"AVAILABLE", "CURRENT", "CYCLE", "RESERVED", "MAX", "CYCLE_FLAT", "CYCLE_PERCENT", "RESERVED_FLAT", "RESERVED_PERCENT"},
                                            {"available", "current", "cycle", "reserved", "max", "cycle_flat", "cycle_percent", "reserved_flat", "reserved_percent"}, true);
--[[!
    @fqxn CoG.Pool.Enums.MODIFIER
    @desc Used in class methods for getting/setting modifier values of <a href="#CoG.Pool.Enums.ASPECT" target="_blank">ASPECTS</a>.
    <ul>
        <li><b class="text-primary">BASE</b>
            <p>The unmodified starting value.</p>
        </li>
        <li><b class="text-primary">FINAL</b>
            <p>The calculated value; read-only.</p>
        </li>
        <li><b class="text-primary">MAX</b>
            <p>An upper cap on the calculated modifier-bearing value.</p>
        </li>
        <li><b class="text-primary">BASE_BONUS</b>
            <p>Added to the base before multiplication.</p>
        </li>
        <li><b class="text-primary">BASE_PENALTY</b>
            <p>Subtracted from the base before multiplication.</p>
        </li>
        <li><b class="text-primary">MULTIPLICATIVE_BONUS</b>
            <p>Added to the multiplier; 0.2 represents a 20% bonus.</p>
        </li>
        <li><b class="text-primary">MULTIPLICATIVE_PENALTY</b>
            <p>Subtracted from the multiplier.</p>
        </li>
        <li><b class="text-primary">ADDITIVE_BONUS</b>
            <p>Added after multiplication.</p>
        </li>
        <li><b class="text-primary">ADDITIVE_PENALTY</b>
            <p>Subtracted after multiplication.</p>
        </li>
    </ul>
    @ex
    local oPool = Pool(100, 50);
    oPool.set(0.2, Pool.ASPECT.MAX, Pool.MODIFIER.MULTIPLICATIVE_BONUS);
    print(oPool.get(Pool.ASPECT.MAX)); --120
!]]
local _eModifier    = enum("Pool.MODIFIER", {   "BASE",     "FINAL",    "MAX",
                                                "BASE_BONUS",           "BASE_PENALTY",
                                                "MULTIPLICATIVE_BONUS", "MULTIPLICATIVE_PENALTY",
                                                "ADDITIVE_BONUS",       "ADDITIVE_PENALTY"},
                                                {1, 2, 3, 4, 5, 6, 7, 8, 9}, true);
--[[!
    @fqxn CoG.Pool.Enums.EVENT
    @desc <p>Used in class methods for setting/getting events.
    <br><b>Note</b>: events fire only if an event callback function has been set and only if the event is active.
    <br><b>Note</b>: events that trigger because of a change in the <b>Current</b> value, proccess before the <b>ON_CYCLE</b> event (if active).</p>
    <br><br>
    <h6>Setting an Event Callback</h6>
    <ol>
        <li>Create the function, ensuring it accepts the relevant arguments for that specific event (as shown below).</li>
        <li>Set the event by using the object's <b>setEventCallback</b> method.</li>
    </ol>
    <br><b>Note</b>: event callbacks are auto-enabled once set. To prevent this, provide true as the third argument to <b>setEventCallback</b>.
    <br><b>Note</b>: event callbacks can be changed (or deleted using nil as the callback argument).
    <br><b>Note</b>: events can be activated/deactivated by using the <b>setEventActive</b> method.
    </p>
    <ul>
        <li><b class="text-primary">ON_INCREASE</b>
            <p>This event occurs whenever the current value is increased.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Current</b> value.</li>
                </ul>
            </p>
        </li>
        <li><b class="text-primary">ON_DECREASE</b>
            <p>This event occurs whenever the current value is decreased.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Current</b> value.</li>
                </ul>
            </p>
        </li>
        <li><b class="text-primary">ON_EMPTY</b>
            <p>This event occurs whenever the current value drops to 0.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Current</b> value.</li>
                </ul>
            </p>
        </li>
        <li><b class="text-primary">ON_LOW</b>
            <p>This event occurs whenever the current value drops to or below the <b>Low</b> threshold.
            <br>The <b>Low</b> threshold is determined by the following formula:
            <br>Let <b><i>l</i></b> be a float value between 0 and 1 (exlusive).
            <br>Let <b><i>m</i></b> be the max value of the Pool.
            <b><i>LowThreshold</i></b> = <b><i>l</i></b> * <b><i>m</i></b>
            <br><br>The <b>Low</b> threshold can be set using the object's <b>setLowMarker</b> method.
            <br><b>Note</b>: the <b>Low</b> value must be less than the <b>High</b> value.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Current</b> value.</li>
                </ul>
            </p>
        </li>
        <li><b class="text-primary">ON_HIGH</b>
            <p>This event occurs whenever the current value moves to or above the <b>High</b> threshold.
            <br>The <b>High</b> threshold is determined by the following formula:
            <br>Let <b><i>f</i></b> be a value greater than 0 and no greater than 1.
            <br>Let <b><i>m</i></b> be the max value of the Pool.
            <b><i>HighThreshold</i></b> = <b><i>f</i></b> * <b><i>m</i></b>
            <br><br>The <b>High</b> threshold can be set using the object's <b>setHighMarker</b> method.
            <br><b>Note</b>: the <b>High</b> value must be greater than the <b>Low</b> value.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Current</b> value.</li>
                </ul>
            </p>
        </li>
        <li><b class="text-primary">ON_FULL</b>
            <p>This event occurs when current fills the available capacity (maximum minus reserved). A Pool can be full and low at the same time.</p>
            <p>The callback receives the Pool, old current value and new current value.</p>
        </li>
        <li><b class="text-primary">ON_CYCLE</b>
            <p>This event occurs when the object's <b>cycle</b> method changes the current value.
            <b>Note</b>: this event fires after other events that may fire in this call.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nCycle</i> The <b>Cycle</b> value.</li>
                    <li><b><i>number</i></b> <i>nMultiplier</i> The multiplier used to multiply the <b>Cycle</b> value.</li>
                    <li><b><i>number</i></b> <i>nTotal</i> The total: multiplier times the <b>Cycle</b> value.</li>
                    <li><b><i>boolean</i></b> <i>bIsPositive</i> Whether the <b>Cycle</b> value was positive.</li>
                    <li><b><i>boolean</i></b> <i>bCurrentChanged</i> Whether the <b>Current</b> value actually changed.</li>
                </ul>
            </p>
        </li>
        <li><b class="text-primary">ON_RESERVE</b>
            <p>This event occurs whenever the resevered amount increases.
            <b>Note</b>: this can trigger other events such as <b>ON_LOW</b>, <b>ON_DECREASE</b>, etc.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Reserved</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Reserved</b> value.</li>
                    <li><b><i>boolean</i></b> <i>bIsPositive</i> Whether the <b>Current</b> value was changed.</li>
                    <li><b><i>number</i></b> <i>nCurrent</i> The <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nAvailable</i> The <b>Available</b> value.</li>
                    <li><b><i>number</i></b> <i>nMax</i> The <b>Max</b> value.</li>
                </ul>
            </p>
        </li>
            <li><b class="text-primary">ON_UNRESERVE</b>
            <p>This event occurs whenever the resevered amount decreases.
            <b>Note</b>: this can trigger other events such as <b>ON_FULL</b>, <b>ON_INCREASE</b>, etc.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Reserved</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Reserved</b> value.</li>
                    <li><b><i>boolean</i></b> <i>bIsPositive</i> Whether the <b>Current</b> value was changed.</li>
                    <li><b><i>number</i></b> <i>nCurrent</i> The <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nAvailable</i> The <b>Available</b> value.</li>
                    <li><b><i>number</i></b> <i>nMax</i> The <b>Max</b> value.</li>
                </ul>
            </p>
        </li>
    </ul>
    @ex
    local oPool = Pool(100, 100);

    local function adjustLifeUI(this, nPrevious, nCurrent)
        UI.LifeBar.SetCurrent(nCurrent);
    end
    --optionally, disable auto-activation by providing true as the third argument.
    oPool.setEventCallback(Pool.EVENT.ON_INCREASE, adjustLifeUI);
!]]
local _eEvent       = enum("Pool.EVENT",    {"ON_INCREASE", "ON_DECREASE",  "ON_EMPTY", "ON_LOW",   "ON_FULL",  "ON_CYCLE", "ON_RESERVE", "ON_UNRESERVE", "ON_HIGH"},
                                            {"onIncrease",  "onDecrease",   "onEmpty",  "onLow",    "onFull",   "onCycle",  "OnReserve",  "onUnreserve", "onHigh"}, true);

--ASPECT LOCALIZATION
local _eAspectAvailable         = _eAspect.AVAILABLE;
local _eAspectCurrent           = _eAspect.CURRENT;
local _eAspectMax               = _eAspect.MAX;
local _eAspectCycle             = _eAspect.CYCLE;
local _eAspectCycleFlat         = _eAspect.CYCLE_FLAT;
local _eAspectCyclePercent      = _eAspect.CYCLE_PERCENT;
local _eAspectReserved          = _eAspect.RESERVED;
local _eAspectReservedFlat      = _eAspect.RESERVED_FLAT;
local _eAspectReservedPercent   = _eAspect.RESERVED_PERCENT;

local _sAspectAvailable         = _eAspectAvailable.value;
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
local _eOnHigh      = _eEvent.ON_HIGH;
local _eOnFull      = _eEvent.ON_FULL;
local _eOnLow       = _eEvent.ON_LOW;
local _eOnCycle     = _eEvent.ON_CYCLE;
local _eOnReserve   = _eEvent.ON_RESERVE;
local _eOnUnreserve = _eEvent.ON_UNRESERVE;

local _sOnIncrease  = _eOnIncrease.value;
local _sOnDecrease  = _eOnDecrease.value;
local _sOnEmpty     = _eOnEmpty.value;
local _sOnHigh      = _eOnHigh.value;
local _sOnFull      = _eOnFull.value;
local _sOnLow       = _eOnLow.value;
local _sOnCycle     = _eOnCycle.value;
local _sOnReserve   = _eOnReserve.value;
local _sOnUnreserve = _eOnUnreserve.value;

local _nDefaultReverseMax       = luaex.cog.config.Pool.reservationMax;
local _nReverseHardMax          = 0.9999999999999; --the max reservation allowed
assert(rawtype(_nDefaultReverseMax) == "number" and _nDefaultReverseMax >= 0 and _nDefaultReverseMax <= _nReverseHardMax, "Pool reservationMax config must be within the supported nonnegative reservation range.");
local eventPlaceholder          = function() end

local _tDeferredEvents;

local function dispatchEvent(fCallback, ...)
    if (_tDeferredEvents ~= nil) then
        _tDeferredEvents[#_tDeferredEvents + 1] = {callback = fCallback, args = table.pack(...)};
    else
        fCallback(...);
    end
end

local function withDeferredEvents(fAction)
    type.assert.custom(fAction, "function");
    local bOwnQueue = _tDeferredEvents == nil;

    if (bOwnQueue) then
        _tDeferredEvents = {};
    end

    local tResult = table.pack(pcall(fAction));
    local sError = not tResult[1] and tResult[2] or nil;

    if (bOwnQueue) then
        local tEvents = _tDeferredEvents;
        _tDeferredEvents = nil;

        for _, tEvent in ipairs(tEvents) do
            local bCalled, sCallbackError = pcall(tEvent.callback, table.unpack(tEvent.args, 1, tEvent.args.n));

            if (not bCalled and sError == nil) then
                sError = sCallbackError;
            end
        end
    end

    if (sError ~= nil) then
        error(sError, 0);
    end

    return table.unpack(tResult, 2, tResult.n);
end



local function validateNumber(nValue, bAllowInfinity)
    type.assert.number(nValue);
    assert(nValue == nValue and (bAllowInfinity or (nValue ~= math.huge and nValue ~= -math.huge)), "Pool values must be finite numbers.");
end

local function updateStatus(this, cdat, bFireEvents)
    local pro           = cdat.pro;
    local nCurrent      = pro[_sAspectCurrent];
    local nStatus       = nCurrent;
    local nMax          = pro[_sAspectMax][_nFinal];
    local bWasEmpty     = pro.isEmpty;
    local bWasLow       = pro.isLow;
    local bWasFull      = pro.isFull;
    local bWasHigh      = pro.isHigh;

    pro.isEmpty = nCurrent <= 0;
    pro.isLow   = not pro.isEmpty and nStatus <= nMax * pro.lowMarker;
    pro.isHigh  = nStatus >= nMax * pro.highMarker;
    pro.isFull  = nCurrent >= pro[_sAspectAvailable];

    if (bFireEvents) then

        if (pro.isEmpty and not bWasEmpty and pro.activeEvents[_sOnEmpty]) then
            dispatchEvent(pro.events[_sOnEmpty], this, nCurrent);
        elseif (pro.isLow and not bWasLow and pro.activeEvents[_sOnLow]) then
            dispatchEvent(pro.events[_sOnLow], this, nCurrent, nCurrent);
        end

        if (pro.isHigh and not bWasHigh and pro.activeEvents[_sOnHigh]) then
            dispatchEvent(pro.events[_sOnHigh], this, nCurrent, nCurrent);
        end

        if (pro.isFull and not bWasFull and pro.activeEvents[_sOnFull]) then
            dispatchEvent(pro.events[_sOnFull], this, nCurrent, nCurrent);
        end

    end
end

local function setCurrent(this, cdat, nNew)
    validateNumber(nNew);
    local pro           = cdat.pro;
    local nCurrent      = pro[_sAspectCurrent];
    local nAvailable    = pro[_sAspectAvailable];
    local bWasEmpty     = pro.isEmpty;
    local bWasLow       = pro.isLow;
    local bWasFull      = pro.isFull;
    local bWasHigh      = pro.isHigh;

    --clamp the value
    nNew = math.max(0, math.min(nNew, nAvailable));
    local bChanged = nCurrent ~= nNew;

    --set the current value
    pro[_sAspectCurrent] = nNew;
    updateStatus(this, cdat, false);

    --process events
    local tActiveEvents = pro.activeEvents;
    local tEvents       = pro.events;

    if (bChanged) then

        if (nNew > nCurrent and tActiveEvents[_sOnIncrease]) then
            dispatchEvent(tEvents[_sOnIncrease], this, nCurrent, nNew);
        elseif (nNew < nCurrent and tActiveEvents[_sOnDecrease]) then
            dispatchEvent(tEvents[_sOnDecrease], this, nCurrent, nNew);
        end

        if (pro.isEmpty and not bWasEmpty and tActiveEvents[_sOnEmpty]) then
            dispatchEvent(tEvents[_sOnEmpty], this, nCurrent);
        elseif (pro.isLow and not bWasLow and tActiveEvents[_sOnLow]) then
            dispatchEvent(tEvents[_sOnLow], this, nCurrent, nNew);
        end

        if (pro.isHigh and not bWasHigh and tActiveEvents[_sOnHigh]) then
            dispatchEvent(tEvents[_sOnHigh], this, nCurrent, nNew);
        end

        if (pro.isFull and not bWasFull and tActiveEvents[_sOnFull]) then
            dispatchEvent(tEvents[_sOnFull], this, nCurrent, nNew);
        end

    end

    return bChanged, nNew;
end


--Final = ((nBase + nBaseBonus - nBasePenalty) * (1 + nMultBonus - nMultPenalty)) + nAddBonus - nAddPenalty;
local function calculateFinal(this, cdat, sIndex)
    local pro       = cdat.pro;
    local tValue    = pro[sIndex];
    local nFinal = (    tValue[_nBase] +
                tValue[_nBaseBonus] - tValue[_nBasePenalty]) *
                (1 + tValue[_nMultBonus] - tValue[_nMultPenalty]) + tValue[_nAddBonus] - tValue[_nAddPenalty];
    return math.min(nFinal, tValue[_nMax]);
end

local function setCycle(this, cdat, sAspect, nValue, nModifier)
    local pro = cdat.pro;
    local bRet          = false;
    local bIsFlat       = sAspect == _sAspectCycleFlat;
    local bIsPercent    = not bIsFlat;
    local tCyclePercent = pro[_sAspectCyclePercent];
    local tCycleFlat    = pro[_sAspectCycleFlat];
    local tActive       = bIsPercent and tCyclePercent or tCycleFlat;

    --set the new modifier value
    tActive[nModifier] = nValue;

    --calculate the final values
    local nFlatFinal        = calculateFinal(this, cdat, _sAspectCycleFlat);
    tCycleFlat[_nFinal]     = nFlatFinal;

    local nPercentFinal     = calculateFinal(this, cdat, _sAspectCyclePercent);
    tCyclePercent[_nFinal]  = nPercentFinal;
    pro[_sAspectCycle] = nFlatFinal + (nPercentFinal * pro[_sAspectMax][_nFinal]);
    return true, 0;
end


local function attemptSettingMax(this, cdat, nValue, nModifier)
    local pro           = cdat.pro;
    local bRet          = false;
    local nOverage      = 0;
    local tMax          = pro[_sAspectMax];

    --store the old value
    local nOldValue  = tMax[nModifier];

    --set the new value
    tMax[nModifier]  = nValue;

    --calculate the new final value
    local nNewFinal  = calculateFinal(this, cdat, _sAspectMax);

    --get the reserved
    local nResFlat      = pro[_sAspectReservedFlat][_nFinal]
    local nResPercent   = pro[_sAspectReservedPercent][_nFinal]

    --calucalte the new total reserved
    local nTotalReserved = nResFlat + (nNewFinal * nResPercent);


    --calculate the new available
    local nNewAvailable = nNewFinal - nTotalReserved;
    --check the success
    bRet = nNewFinal >= tMax.min and nTotalReserved >= 0 and nNewAvailable > 0 and nTotalReserved / nNewFinal <= _nReverseHardMax;

    if (bRet) then
        --set the new max
        tMax[_nFinal] = nNewFinal;

        --set the new reserved
        pro[_sAspectReserved] = nTotalReserved;

        --set the new avaiable
        pro[_sAspectAvailable] = nNewAvailable;

        pro[_sAspectCycle] = pro[_sAspectCycleFlat][_nFinal] + pro[_sAspectCyclePercent][_nFinal] * nNewFinal;

        --check current and adjust if needed
        if (pro[_sAspectCurrent] > nNewAvailable) then
            setCurrent(this, cdat, nNewAvailable);
        else
            updateStatus(this, cdat, true);
        end

    else
        tMax[nModifier] = nOldValue;
        nOverage = math.max(0, tMax.min - nNewFinal, -nNewAvailable);
    end

    return bRet, nOverage
end



local function attemptSettingReserved(this, cdat, sAspect, nValue, nModifier)
    local pro           = cdat.pro;
    local bRet          = false;
    local nOverage      = 0;

    --_nReverseHardMax

    local bIsFlat       = sAspect == _sAspectReservedFlat;
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
    local nResFlat      = bIsPercent and tResFlat[_nFinal] or calculateFinal(this, cdat, sAspect);
    local nResPercent   = bIsFlat and tResPercent[_nFinal] or calculateFinal(this, cdat, sAspect);

    --get the total reserved
    local nTotalReserved = nResFlat + (nMax * nResPercent);

    --determine if the reservation is permitted
    bRet = (nResFlat >= 0 and nResPercent >= 0 and
                nTotalReserved < nMax and
                (nTotalReserved / nMax) <= math.min(tResPercent[_nMax], _nReverseHardMax));

    --if the reservation is allowed, process it
    if (bRet) then
        --set the new final value
        tActive[_nFinal]        = bIsPercent and nResPercent or nResFlat;
        --update the reserved total
        pro[_sAspectReserved]   = nTotalReserved;
        --update the available value
        local nAvailable = nMax - nTotalReserved;
        pro[_sAspectAvailable] = nAvailable;

        --update the current value
        local nNewCurrent       = nCurrent > nAvailable and nAvailable or nCurrent;
        local bChangeInCurrent  = nCurrent ~= nNewCurrent;

        if (bChangeInCurrent) then
            local bSuccess, nNew = setCurrent(this, cdat, nNewCurrent);
        else
            updateStatus(this, cdat, true);
        end

        --check for and fire reserve event
        local bOnReserve   = nOldTotalReserved < nTotalReserved;
        local bOnUnReserve = nOldTotalReserved > nTotalReserved;

        if (bOnReserve and pro.activeEvents[_sOnReserve]) then
            dispatchEvent(pro.events[_sOnReserve], this, nOldTotalReserved, nTotalReserved, bChangeInCurrent, nNewCurrent, nAvailable, nMax);
        elseif (bOnUnReserve and pro.activeEvents[_sOnUnreserve]) then
            dispatchEvent(pro.events[_sOnUnreserve], this, nOldTotalReserved, nTotalReserved, bChangeInCurrent, nNewCurrent, nAvailable, nMax);
        end

    else
        --set the old value
        tActive[nModifier] = nOldValue;
        --indicate the overage
        nOverage = math.max(0, nTotalReserved - nMax * math.min(tResPercent[_nMax], _nReverseHardMax));
    end


    return bRet, nOverage;
end


--@see class method of the same name
local function set(this, cdat, nValue, eAspectOrNil, eModifierOrNil)
    validateNumber(nValue, eModifierOrNil == _eMax);

    if (eModifierOrNil == _eMax) then
        assert(nValue >= 0, "Modifier caps must be nonnegative.");
    end

    if (eAspectOrNil ~= nil) then
        type.assert.custom(eAspectOrNil, "Pool.ASPECT");
    end

    if (eModifierOrNil ~= nil) then
        type.assert.custom(eModifierOrNil, "Pool.MODIFIER");
    end

    local pro           = cdat.pro;
    local bSuccess      = false;
    local nOverage      = 0;
    local eAspect       = (type(eAspectOrNil)   == "Pool.ASPECT")   and eAspectOrNil    or _eAspectCurrent;
    local sAspect       =  eAspect.value;
    local eModifier     = (type(eModifierOrNil) == "Pool.MODIFIER") and eModifierOrNil  or _eBase;
    local nModifier     = eModifier.value;
    local sEvent        = "NONE";
    local nNew;

    if (type(nValue) ~= "number") then
        error("Error setting value in Pool class.\nExpected type number; got type: "..type(nValue)..'.');
    end

    if (nModifier == _nFinal) then
        error("Error setting value in Pool class.\nFinal values are calculated internally and may not be set manually.");
    end

    if (sAspect == _sAspectAvailable or sAspect == _sAspectCycle or sAspect == _sAspectReserved) then
        error("Error setting value in Pool class.\nAttempt to set calculated, read-only '"..sAspect:upper().."', value.");
    end

    --process CURRENT aspect
    if (sAspect == _sAspectCurrent) then --since current doesn't have a table

        if (nValue ~= pro[_sAspectCurrent]) then
            bSuccess, nNew = setCurrent(this, cdat, nValue);
        end

    --process all other aspects
    elseif pro[sAspect][nModifier] then

        --process MAX aspect
        if (sAspect == _sAspectMax) then
            bSuccess, nOverage = attemptSettingMax(this, cdat, nValue, nModifier);

        --process CYCLE_FLAT and CYCLE_PERCENT aspect
        elseif (sAspect == _sAspectCycleFlat or sAspect == _sAspectCyclePercent) then
            bSuccess, nOverage = setCycle(this, cdat, sAspect, nValue, nModifier);

        --process RESERVED_FLAT and RESERVED_PERCENT aspect
        elseif (sAspect == _sAspectReservedFlat or sAspect == _sAspectReservedPercent) then
            bSuccess, nOverage = attemptSettingReserved(this, cdat, sAspect, nValue, nModifier);
        end


    else --for tables like reserved which have only certain modifiers
        error(  "Error setting value in Pool class.\nNo '${modifier}' modifier exists for aspect, '${aspect}'." %
                {modifier = eModifier.name, aspect = eAspect.name});
    end

    return this, bSuccess, nOverage;
end


local function operandValue(this, other, bMaximum)
    type.assert.custom(this, "Pool");
    local nValue;

    if (type(other) == "Pool") then
        nValue = other.get(bMaximum and _eAspectMax or _eAspectCurrent);
    else
        validateNumber(other);
        nValue = other;
    end

    return nValue;
end

--[[!
    @fqxn CoG.Pool
    @author Centauri Soldier
    @desc <h2>Pool</h2><h3>Utility class used to keep track of things like Health, Magic, etc.</h3><p>You can operate on <strong>Pool</strong> objects using some math operators.</p>
    <ul>
        <li><p><b>+</b>: adds a number to the Pool's CURRENT value or, if adding another Pool object instead of a number, it will add the other Pool's CURRENT value to it's own <em>(up to its available capacity)</em> value.</p></li>
        <li><p><b>-</b>: does the same as addition but for subtraction. Will not go below the Pool's MIN value.</p></li>
        <li><p><b>%</b>: will modify a Pool's MAX value using a number value or another Pool object <em>(uses it's MAX value)</em>. Requires a calculated maximum of at least 1 and enough capacity for existing reservations.</p></li>
        <li><p><b>*</b>: operates as expected on the object's CURRENT value.</p></li>
        <li><p><b>/</b>: operates as expected on the object's CURRENT value. All div is floored.</p></li>
        <li><p><b>-</b><em>(unary minus)</em>: will set the object's CURRENT value to the value of MIN.</p></li>
        <li><p><b>#</b>: will set the object's CURRENT value to the available capacity and return that current value.</p></li>
    </ul>
    @version 2.1
    @note Arithmetic operators update the left Pool in place and return it. Unary minus empties it; length fills available capacity and returns current. Numbers on the left are not supported.
    @ex
    local oPool = Pool(100, 40);
    oPool.set(10, Pool.ASPECT.CYCLE_FLAT);
    oPool.cycle();
    assert(oPool.get() == 50);
    !]]
return class("Pool",
{--METAMETHODS
--[[!
    @fqxn CoG.Pool.Metamethods.__add
    @desc Adds a number or another Pool's current value to this Pool, clamped to available capacity.
    @param Pool|number other The right operand.
    @ret Pool oPool This Pool.
    @ex
    local oPool = Pool(100, 40);
    oPool = oPool + 10;
    assert(oPool.get() == 50);
    oPool = oPool + Pool(100, 20);
    assert(oPool.get() == 70);
    !]]
    __add = function(this, other, cdat)
        local nValue = operandValue(this, other, false);
        this.adjust(nValue);
        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Metamethods.__sub
    @desc Subtracts a number or another Pool's current value from this Pool, clamped at zero.
    @param Pool|number other The right operand.
    @ret Pool oPool This Pool.
    @ex
    local oPool = Pool(100, 40);
    oPool = oPool - 10;
    assert(oPool.get() == 30);
    !]]
    __sub = function(this, other, cdat)
        local nValue = operandValue(this, other, false);
        this.adjust(-nValue);
        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Metamethods.__mul
    @desc Multiplies current by a number or another Pool's current value, applying current bounds.
    @param Pool|number other The right operand.
    @ret Pool oPool This Pool.
    @ex
    local oPool = Pool(100, 40);
    oPool = oPool * 2;
    assert(oPool.get() == 80);
    !]]
    __mul = function(this, other, cdat)
        local nValue = operandValue(this, other, false);
        this.set(this.get() * nValue);
        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Metamethods.__div
    @desc Divides current by a number or another Pool's current value and floors the result. Zero divisors are rejected.
    @param Pool|number other The right operand.
    @ret Pool oPool This Pool.
    @ex
    local oPool = Pool(100, 41);
    oPool = oPool / 2;
    assert(oPool.get() == 20); --division is floored
    !]]
    __div = function(this, other, cdat)
        local nValue = operandValue(this, other, false);
        assert(nValue ~= 0, "Cannot divide a Pool by zero.");
        this.set(floor(this.get() / nValue));
        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Metamethods.__mod
    @desc Sets maximum base from a number or another Pool's calculated maximum, using normal capacity validation.
    @param Pool|number other The right operand.
    @ret Pool oPool This Pool.
    @ex
    local oPool = Pool(100, 40);
    oPool = oPool % 200; --sets maximum base, rather than calculating a remainder
    assert(oPool.get(Pool.ASPECT.MAX) == 200);
    !]]
    __mod = function(this, other, cdat)
        local nValue = operandValue(this, other, true);
        this.set(nValue, _eAspectMax);
        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Metamethods.__unm
    @desc Empties this Pool in place.
    @ret Pool oPool This Pool.
    @ex
    local oPool = Pool(100, 40);
    oPool = -oPool;
    assert(oPool.get() == 0);
    !]]
    __unm = function(this, cdat)
        this.setEmpty();
        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Metamethods.__len
    @desc Fills available capacity and returns the new current value.
    @ret number nCurrent The filled current value.
    @ex
    local oPool = Pool(100, 40);
    oPool.set(20, Pool.ASPECT.RESERVED_FLAT);
    assert(#oPool == 80); --also fills the Pool
    assert(oPool.isFull());
    !]]
    __len = function(this, cdat)
        this.setFull();
        return this.get();
    end,

    --[[!
    @fqxn CoG.Pool.Metamethods.__clone
    @desc Creates an independent Pool with the same values, thresholds and event activation. Callback function references are retained.
    @ret Pool oCopy The cloned Pool.
    @ex
    local oPool = Pool(100, 40);
    local oCopy = clone(oPool);
    oCopy.adjust(10);
    assert(oCopy.get() == 50 and oPool.get() == 40);
    !]]
    __clone = function(this, cdat)
        local pro       = cdat.pro;
        local oNew      = Pool(1, 1);
        local newpro    = cdat.ins[oNew].pro;

        local tTables = {
            "activeEvents",
            "events",
            _sAspectMax,
            _sAspectCycleFlat,
            _sAspectCyclePercent,
            _sAspectReservedFlat,
            _sAspectReservedPercent,
        };

        for _, sIndex in pairs(tTables) do

            for k, v in pairs(pro[sIndex]) do
                newpro[sIndex][k] = v;
            end

        end

        newpro.lowMarker            = pro.lowMarker;
        newpro.highMarker           = pro.highMarker;
        newpro.isEmpty              = pro.isEmpty;
        newpro.isHigh               = pro.isHigh;
        newpro.isFull               = pro.isFull;
        newpro.isLow                = pro.isLow;
        newpro[_sAspectAvailable]   = pro[_sAspectAvailable];
        newpro[_sAspectCurrent]     = pro[_sAspectCurrent];
        newpro[_sAspectCycle]       = pro[_sAspectCycle];
        newpro[_sAspectReserved]    = pro[_sAspectReserved];

        return oNew;
    end,
},
{--STATIC PUBLIC
    --[[!
    @fqxn CoG.Pool.Static Methods.withDeferredEvents
    @desc Runs a synchronous action, deferring Pool callbacks until it finishes. Values and status update immediately; callbacks then run in order and all queued callbacks are attempted. Nested calls share the outer queue. This is not a rollback transaction: action or callback errors leave committed values intact and the first error is rethrown after notifications. The action must not yield.
    @param function fAction The action to run.
    @ret any ... The action's return values.
    @ex
    local oFirst = Pool(100, 40);
    local oSecond = Pool(100, 40);
    oFirst.setEventCallback(Pool.EVENT.ON_DECREASE, function()
        assert(oFirst.get() == 30 and oSecond.get() == 30);
    end);
    Pool.withDeferredEvents(function()
        oFirst.adjust(-10);
        oSecond.adjust(-10);
    end);
    !]]
    withDeferredEvents = withDeferredEvents,
ASPECT__RO      = _eAspect,
    EVENT__RO       = _eEvent,
    --MODE__RO        = _eMode,
    MODIFIER__RO    = _eModifier,
    --Pool = function(stapub) end,
},
{--PRIVATE
    -- Keep autogenerated class persistence, with explicit runtime-event policy
    -- and domain validation for state imported without constructor execution.
    prepareSnapshot = function(tState)
        local pro = tState.pro;
        local tInactive = {};

        for sEvent in pairs(pro.activeEvents) do
            tInactive[sEvent] = false;
        end

        -- Callbacks belong to the live owner. Restore fresh placeholder events
        -- from class defaults rather than serialized closures and their upvalues.
        pro.activeEvents = tInactive;
        pro.events = nil;
    end,
    validateSnapshot = function(tState)
        local pro = tState.pro;
        type.assert.table(pro);
        type.assert.table(pro.activeEvents);
        assert(pro.events == nil or type(pro.events) == "table", "Invalid Pool snapshot events.");

        for _, eEvent in _eEvent() do
            assert(rawtype(pro.activeEvents[eEvent.value]) == "boolean", "Invalid Pool snapshot activation.");
            pro.activeEvents[eEvent.value] = false;
        end

        -- Discard older saved closures without calling them. Defaults provide
        -- fresh placeholders, and event registration stays a runtime operation.
        pro.events = nil;

        for _, sAspect in ipairs({_sAspectMax, _sAspectCycleFlat, _sAspectCyclePercent,
                _sAspectReservedFlat, _sAspectReservedPercent}) do
            local tValue = pro[sAspect];
            type.assert.table(tValue);

            for _, nModifier in ipairs({_nBase, _nFinal, _nBaseBonus, _nBasePenalty,
                    _nMultBonus, _nMultPenalty, _nAddBonus, _nAddPenalty}) do
                validateNumber(tValue[nModifier]);
            end

            validateNumber(tValue[_nMax], true);
            -- Cached values are derived, and older serialization rounded them.
            -- Recompute from validated modifiers rather than trusting the cache.
            tValue[_nFinal] = calculateFinal(nil, {pro=pro}, sAspect);
            validateNumber(tValue[_nFinal]);
        end

        local nMax = pro[_sAspectMax][_nFinal];
        local nFlat = pro[_sAspectReservedFlat][_nFinal];
        local nPercent = pro[_sAspectReservedPercent][_nFinal];
        assert(nMax >= 1, "Invalid Pool snapshot maximum.");
        assert(nFlat >= 0 and nPercent >= 0 and nPercent < 1, "Invalid Pool snapshot reservations.");
        local nReserved = nFlat + nPercent * nMax;
        local nAvailable = nMax - nReserved;
        assert(nReserved < nMax, "Pool snapshot reservations exhaust capacity.");
        validateNumber(pro[_sAspectCurrent]);
        assert(pro[_sAspectCurrent] >= 0 and pro[_sAspectCurrent] <= nAvailable,
               "Invalid Pool snapshot current value.");
        validateNumber(pro.lowMarker);
        validateNumber(pro.highMarker);
        assert(pro.lowMarker > 0 and pro.lowMarker < pro.highMarker and pro.highMarker <= 1,
               "Invalid Pool snapshot markers.");

        pro[_sAspectReserved] = nReserved;
        pro[_sAspectAvailable] = nAvailable;
        pro[_sAspectCycle] = pro[_sAspectCycleFlat][_nFinal] +
                            pro[_sAspectCyclePercent][_nFinal] * nMax;
        validateNumber(pro[_sAspectCycle]);
        updateStatus(nil, {pro=pro}, false);
    end,
},
{--PROTECTED
    activeEvents = {
        [_sOnLow]       = false,
        [_sOnIncrease]  = false,
        [_sOnDecrease]  = false,
        [_sOnEmpty]     = false,
        [_sOnHigh]      = false,
        [_sOnFull]      = false,
        [_sOnCycle]     = false,
        [_sOnReserve]   = false,
        [_sOnUnreserve] = false,
    },
    events = {

        [_sOnLow]       = eventPlaceholder,
        [_sOnIncrease]  = eventPlaceholder,
        [_sOnDecrease]  = eventPlaceholder,
        [_sOnEmpty]     = eventPlaceholder,
        [_sOnHigh]      = eventPlaceholder,
        [_sOnFull]      = eventPlaceholder,
        [_sOnCycle]     = eventPlaceholder,
        [_sOnReserve]   = eventPlaceholder,
        [_sOnUnreserve] = eventPlaceholder,
    },
    [_sAspectAvailable] = 1,    --cached value updated on change
    [_sAspectCurrent]   = -1,   --cached value updated on change
    [_sAspectCycle]     = 0,    --cached value updated on change
    [_sAspectReserved]  = 0,    --cached value updated on change
    [_sAspectMax]       = {
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
        [_nBase]        = 0,
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
        [_nBase]        = 0,
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
    lowMarker       = 0.3,
    highMarker      = 1,
    isEmpty         = false,
    isHigh          = false,
    isFull          = false,
    isLow           = false,
},
{--PUBLIC

    --[[!
    @fqxn CoG.Pool.Methods.Pool
    @desc The constructor for the <b>Pool</b> class.
    @param number|nil nMax The maximum value of the Pool (minimum 1).
    @param number|nil nCurrent The current value of the Pool (minimum 0, maximum nMax).
    @ex
    local oPool = Pool(100, 40); --maximum, current
    assert(oPool.get(Pool.ASPECT.MAX) == 100 and oPool.get() == 40);
    !]]
    Pool = function(this, cdat, nMax, nCurrent)
        local pro   = cdat.pro;
        nMax        = type(nMax) 		== "number"	and nMax	    or 1;
        nCurrent	= type(nCurrent) 	== "number" and nCurrent    or 1;
        validateNumber(nMax);
        validateNumber(nCurrent);

        if (nMax < 1) then
            error("Error creating Pool object.\nMax value must be positive number greater than or equal to 1.");
        end

        if (nCurrent < 0) then
            error("Error creating Pool object.\nCurrent value must be non-negative.");
        end

        --set the values
        pro[_sAspectMax][_nBase]        = nMax;
        pro[_sAspectMax][_nFinal]       = nMax;
        pro[_sAspectAvailable]          = nMax;

        local bSuccess, nNew = setCurrent(this, cdat, nCurrent);

end,


    --[[!
    @fqxn CoG.Pool.Methods.adjust
    @desc Adjusts the selected value by an amount. Defaults to CURRENT; modifier-bearing aspects default to their BASE value. Uses the same bounds and events as set.
    @param number nAmount The amount to add or subtract.
    @param Pool.ASPECT|nil eAspect The aspect to adjust.
    @param Pool.MODIFIER|nil eModifier The modifier to adjust.
    @ret Pool oPool This pool.
    @ret boolean bSuccess Whether the adjustment was accepted or changed CURRENT.
    @ret number nOverage The rejected capacity or reservation overage; zero for CURRENT changes.
    @ex
    local oPool = Pool(100, 40);
    local oResult, bSuccess, nOverage = oPool.adjust(-10);
    assert(oResult == oPool and bSuccess and nOverage == 0);
    assert(oPool.get() == 30);
    !]]
    adjust = function(this, cdat, nAmount, eAspect, eModifier)
        validateNumber(nAmount);
        local nCurrent = this.get(eAspect, eModifier or _eBase);
        return this.set(nCurrent + nAmount, eAspect, eModifier);
    end,


    --[[!
    @fqxn CoG.Pool.Methods.cycle
    @desc Causes the Pool to cycle based on the cycle value (after all modifiers have been applied).
    <br>This is used for things like regeneration of mana, regen and/or poisoning of life, consumption of fuel, etc.
    @param number|nil nMultiplier If a number is provided, it will cycle the number of times input, otherwise, once.
    <br>Note: regardless of the multiple provided (if any), the <strong>onCycle</strong> event will fire only once per cycle.
    @ret Pool oPool The Pool object.
    @ex
    local oPool = Pool(100, 40);
    oPool.set(10, Pool.ASPECT.CYCLE_FLAT);
    oPool.cycle(2); --two regeneration amounts in one call
    assert(oPool.get() == 60);
    !]]
    cycle = function(this, cdat, nMultiplier)
        nMultiplier = nMultiplier == nil and 1 or nMultiplier;
        validateNumber(nMultiplier);
        local pro           = cdat.pro;
        local nCurrent      = pro[_sAspectCurrent];
        --local nMax          = pro[_sAspectMax][_nFinal];
        local nAvailable    = pro[_sAspectAvailable];
        local nCycle        = pro[_sAspectCycle];
        local nDelta        = nCycle * nMultiplier;
        local bIsNegative   = nDelta < 0;
        local bIsPositive   = nDelta > 0;
        local bCanGoDown    = nCurrent > 0;
        local bCanGoUp      = nCurrent < nAvailable;

        if ( (bIsNegative and bCanGoDown) or (bIsPositive and bCanGoUp) ) then
            --process the cycle
            local nTotalChange = pro[_sAspectCurrent] + (nCycle * nMultiplier);

            --clamp the current value
            local bSuccess, nNew = setCurrent(this, cdat, nTotalChange);

            --run the cycle event if active (and something changed)
            if (bSuccess and pro.activeEvents[_sOnCycle]) then
                dispatchEvent(pro.events[_sOnCycle], this, nCurrent, nNew, nCycle, nMultiplier, nDelta, bIsPositive, nCurrent ~= nNew);
            end

        end

        return this;
    end,


    --[[!
    @fqxn CoG.Pool.Methods.isEmpty
    @desc Determines whether the Pool is empty.
    <br>This is true when the current value is less than or equal to 0.
    @ret boolean bEmpty True if the Pool is empty, false otherwise.
    @ex
    local oPool = Pool(100, 0);
    assert(oPool.isEmpty());
    !]]
    isEmpty = function(this, cdat)
        return cdat.pro.isEmpty;
    end,


    --[[!
    @fqxn CoG.Pool.Methods.isFull
    @desc Determines whether the Pool is full.
    <br>This is true when current fills available capacity (maximum minus reserved), independently of low/high status.
    @ret boolean bFull True if the Pool is full, false otherwise.
    @ex
    local oPool = Pool(100, 80);
    oPool.set(20, Pool.ASPECT.RESERVED_FLAT);
    assert(oPool.isFull()); --80 fills the available capacity
    !]]
    isFull = function(this, cdat)
        return cdat.pro.isFull;
    end,


    --[[!
    @fqxn CoG.Pool.Methods.isHigh
    @desc Determines whether current reaches the configurable high marker times total maximum. Reservations do not count toward this threshold.
    @ret boolean bHigh Whether the Pool is high.
    @ex
    local oPool = Pool(100, 80);
    oPool.setHighMarker(0.8);
    assert(oPool.isHigh());
    !]]
    isHigh = function(this, cdat)
        return cdat.pro.isHigh;
    end,

    --[[!
    @fqxn CoG.Pool.Methods.isLow
    @desc Determines whether the Pool is low.
    <br>This is true when a nonempty Pool has a status value at or below maximum times the low marker.
    @ret boolean bLow True if the Pool is low, false otherwise.
    @ex
    local oPool = Pool(100, 20);
    assert(oPool.isLow()); --default low marker is 30% of total maximum
    !]]
    isLow = function(this, cdat)
        return cdat.pro.isLow;
    end,


    --[[!
    @fqxn CoG.Pool.Methods.get
    @desc Gets a Pool aspect or one of its modifiers.
    @param Pool.ASPECT|nil eAspect If provided, this refers to the aspect of the pool to get such as MAX or CYCLE.
    <br>If not provided it will default to CURRENT.
    @param Pool.MODIFIER|nil eModifier If provided, this indicates which modifier to get such as BASE, BASE_BONUS, etc.
    <br>If not provided, it will default to FINAL.
    <br><strong>Note</strong>: not all aspects have all modifiers. E.g., Pool.ASPECT.RESERVED, Pool.ASPECT.CURRENT Pool.ASPECT.AVAILABLE have no modifiers whatsoever and only accessor methods.
    @ret number nRet The value requested in either a flat value or a percentage between 0 and 1.
    @ex
    local oPool = Pool(100, 40);
    assert(oPool.get() == 40);
    assert(oPool.get(Pool.ASPECT.MAX, Pool.MODIFIER.BASE) == 100);
    !]]
    get = function(this, cdat, eAspectOrNil, eModifierOrNil)

        if (eAspectOrNil ~= nil) then
            type.assert.custom(eAspectOrNil, "Pool.ASPECT");
        end

        if (eModifierOrNil ~= nil) then
            type.assert.custom(eModifierOrNil, "Pool.MODIFIER");
        end

        local nRet;
        local pro       = cdat.pro;
        local eAspect   = (type(eAspectOrNil)   == "Pool.ASPECT")   and eAspectOrNil    or _eAspectCurrent;
        local sAspect   =  eAspect.value;
        local eModifier = (type(eModifierOrNil) == "Pool.MODIFIER") and eModifierOrNil  or _eFinal;
        local nModifier = eModifier.value;

        if (sAspect == _sAspectCurrent) then --since current doesn't have a table
            nRet = pro[_sAspectCurrent];

        elseif (sAspect == _sAspectAvailable) then
            nRet = pro[_sAspectAvailable];

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
    @fqxn CoG.Pool.Methods.set
    @desc Sets a writable aspect or modifier. CURRENT is clamped to available capacity; invalid capacity or reservation changes are rejected without changing the prior settings.
    @param number nValue The value to which the item should be set.
    @param Pool.ASPECT|nil eAspect If provided, this refers to the aspect of the pool to set such as MAX or CYCLE.
    <br>If not provided it will default to <b>CURRENT</b>.
    @param Pool.MODIFIER|nil eModifier If provided, this indicates which modifier to set such as BASE, BASE_BONUS, etc.
    <br>If not provided, it will default to BASE.
    <br><strong>Note</strong>: not all aspects have all modifiers. E.g., Pool.ASPECT.CURRENT has no modifiers whatsoever.
    @ret Pool oPool This pool.
    @ret boolean bSuccess Whether the setting was accepted or changed CURRENT.
    @ret number nOverage The rejected capacity or reservation overage; zero for CURRENT changes.
    @ex
    local oPool = Pool(100, 40);
    local oResult, bSuccess, nOverage = oPool.set(120);
    assert(oResult == oPool and bSuccess and nOverage == 0);
    assert(oPool.get() == 100);
    oPool.set(10, Pool.ASPECT.CYCLE_FLAT); --BASE is the default modifier
    !]]
    set = set,


    --[[!
    @fqxn CoG.Pool.Methods.setEmpty
    @desc Set the Pool to empty (if not already empty).
    @ret Pool oPool The Pool object.
    @ex
    local oPool = Pool(100, 40);
    oPool.setEmpty();
    assert(oPool.isEmpty());
    !]]
    setEmpty = function(this, cdat)

        --process only if the Pool isn't already empty
        if (cdat.pro[_sAspectCurrent] > 0) then
            setCurrent(this, cdat, 0);
        end

        return this;
    end,


    --[[!
    @fqxn CoG.Pool.Methods.setEventActive
    @desc Enables\disables an event from triggering.
    <br>Note: this does not affect any current callback function for this event, it simply makes<br>
    the event dormant until manually reactivated.
    @param Pool.EVENT eEvent The event to enable or disable.
    @param boolean bFlag Enables the event if true, disables it otherwise.
    @ret Pool oPool The Pool object.
    @ex
    local oPool = Pool(100, 40);
    local nCalls = 0;
    oPool.setEventCallback(Pool.EVENT.ON_INCREASE, function() nCalls = nCalls + 1; end);
    oPool.setEventActive(Pool.EVENT.ON_INCREASE, false);
    oPool.adjust(10);
    assert(nCalls == 0);
    oPool.setEventActive(Pool.EVENT.ON_INCREASE, true);
    oPool.adjust(10);
    assert(nCalls == 1);
    !]]
    setEventActive = function(this, cdat, eEvent, bFlag)
        local pro = cdat.pro;

        if (type(eEvent) ~= "Pool.EVENT") then
            error("Error setting event callback in Pool class.\nExpected Pool.EVENT.Got type, "..type(eEvent)..'.');
        end

        local sEvent = eEvent.value;
        type.assert.custom(bFlag, "boolean");
        pro.activeEvents[sEvent] = bFlag and pro.events[sEvent] ~= eventPlaceholder;

        return this;
    end,


    --[[!
    @fqxn CoG.Pool.Methods.setEventCallback
    @desc Sets a callback function for the specified event. The function will fire whenever the event is triggered.
    @param Pool.EVENT eEvent The event for which the function should be called.
    @param function|nil fCallback The callback function.
    <br>Note: If a function is not input, it will delete any previous callback function and disable the event trigger.
    @param boolean|nil bDoNotAutoActivate If a true value is input, it will prevent the event from being activated by this call.
    <br>If nothing is provided, the event is active by default and the callback function will fire on event trigger.
    @ret Pool oPool The Pool object.
    @ex
    local oPool = Pool(100, 40);
    local nCalls = 0;
    oPool.setEventCallback(Pool.EVENT.ON_INCREASE, function() nCalls = nCalls + 1; end);
    oPool.adjust(10);
    assert(nCalls == 1);
    oPool.setEventCallback(Pool.EVENT.ON_INCREASE, nil); --clears and disables the callback
    !]]
    setEventCallback = function(this, cdat, eEvent, fCallback, bDoNotAutoActivate)
        local pro = cdat.pro;

        if (type(eEvent) ~= "Pool.EVENT") then
            error("Error setting event callback in Pool class.\nExpected Pool.EVENT.Got type, "..type(eEvent)..'.');
        end

        bDoNotAutoActivate = type(bDoNotAutoActivate) == "boolean" and bDoNotAutoActivate or false;

        local sEvent = eEvent.value;

        if (rawtype(fCallback) == "function") then
            pro.events[sEvent]          = fCallback;
            pro.activeEvents[sEvent]    = not bDoNotAutoActivate;

        else
            pro.events[sEvent]          = eventPlaceholder;
            pro.activeEvents[sEvent]    = false;
        end

        return this;
    end,


    --[[!
    @fqxn CoG.Pool.Methods.setFull
    @desc Sets Pool's current value to the maximum available (if not already that high).
    <br>Note: this is not the same as the maximum value.
    <br>For instance, if 20% of a Pool (whose max is 100) is reserved, the value would be set to 80.
    @ret Pool oPool The Pool object.
    @ex
    local oPool = Pool(100, 40);
    oPool.set(20, Pool.ASPECT.RESERVED_FLAT);
    oPool.setFull();
    assert(oPool.get() == 80);
    !]]
    setFull = function(this, cdat)
        local pro           = cdat.pro;
        local nMax          = pro[_sAspectMax][_nFinal];
        local nAvailable    = nMax - pro[_sAspectReserved];
        local nCurrent      = pro[_sAspectCurrent];

        --process only if the Pool isn't already full
        if (nCurrent < nAvailable) then
            setCurrent(this, cdat, nAvailable);
        end

        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Methods.setHighMarker
    @desc Sets the high threshold as a fraction of total maximum. Must be greater than the low marker and no greater than 1. Recalculates status immediately.
    @param number nValue The high marker.
    @ret Pool oPool This pool.
    @ex
    local oPool = Pool(100, 80);
    oPool.setHighMarker(0.8);
    assert(oPool.isHigh());
    !]]
    setHighMarker = function(this, cdat, nValue)
        validateNumber(nValue);
        assert(nValue > cdat.pro.lowMarker and nValue <= 1, "High marker must exceed low marker and be at most 1.");
        cdat.pro.highMarker = nValue;
        updateStatus(this, cdat, true);
        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Methods.setLowMarker
    @desc Sets the low threshold as a fraction of total maximum. Must be greater than 0 and less than the high marker. Recalculates status immediately.
    @param number nValue The low marker.
    @ret Pool oPool This pool.
    @ex
    local oPool = Pool(100, 20);
    oPool.setLowMarker(0.2);
    assert(oPool.isLow());
    !]]
    setLowMarker = function(this, cdat, nValue)
        validateNumber(nValue);
        assert(nValue > 0 and nValue < cdat.pro.highMarker, "Low marker must be positive and below full marker.");
        cdat.pro.lowMarker = nValue;
        updateStatus(this, cdat, true);
        return this;
    end,

    --[[!
    @fqxn CoG.Pool.Methods.getHighMarker
    @desc Gets the high-status fraction of total maximum.
    @ret number nMarker The configured value.
    @ex
    local oPool = Pool(100, 40);
    oPool.setHighMarker(0.8);
    assert(oPool.getHighMarker() == 0.8);
    !]]
    getHighMarker = function(this, cdat)
        return cdat.pro.highMarker;
    end,

    --[[!
    @fqxn CoG.Pool.Methods.getLowMarker
    @desc Gets the low-status fraction of total maximum.
    @ret number nMarker The configured value.
    @ex
    local oPool = Pool(100, 40);
    oPool.setLowMarker(0.2);
    assert(oPool.getLowMarker() == 0.2);
    !]]
    getLowMarker = function(this, cdat)
        return cdat.pro.lowMarker;
    end,


},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
