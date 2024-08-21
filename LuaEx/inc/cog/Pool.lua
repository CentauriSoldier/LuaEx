--LOCALIZATION
local floor 			= math.floor;
local math				= math;
local rawtype           = rawtype;
local type				= type;
--TODO NEXT LEFT OFF HERE Do events on other items (onFull, Empty etc.)
--CLASS-LEVEL ENUMS                                       Note: AVAILABLE, CYCLE and RESERVED are calculated values and cannot be set directly
--[[!
    @fqxn CoG.Classes.Pool.Enums.ASPECT
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
    local oPool = Pool(200, 80); --create the Pool object with 200 max and 0 current
    oPool.set(0.36, Pool.ASPECT.RESERVED_PERCENT); --reserve 36% of the Pool
    print("Reserved: "..oPool.get(Pool.ASPECT.RESERVED)); --> Reserved: 72.0
    print("Available: "..oPool.get(Pool.ASPECT.AVAILABLE)); --> Available: 128.0
    oPool.set(0.10, Pool.ASPECT.MAX, Pool.MODIFIER.MULTIPLICATIVE_BONUS); --adjust the max value by 10%
    print("Max: "..oPool.get(Pool.ASPECT.MAX)); --> Max: 220.0
    print("Reserved: "..oPool.get(Pool.ASPECT.RESERVED)); --> Reserved: 79.2
    print("Available: "..oPool.get(Pool.ASPECT.AVAILABLE)); --> Available: 140.8
    @ex More Coming Soon (or later)
!]]
local _eAspect      = enum("Pool.ASPECT",   {"AVAILABLE", "CURRENT", "CYCLE", "RESERVED", "MAX", "CYCLE_FLAT", "CYCLE_PERCENT", "RESERVED_FLAT", "RESERVED_PERCENT"},
                                            {"available", "current", "cycle", "reserved", "max", "cycle_flat", "cycle_percent", "reserved_flat", "reserved_percent"}, true);
--[[!
    @fqxn CoG.Classes.Pool.Enums.MODIFIER
    @desc Used in class methods for getting/setting modifier values of <a href="#CoG.Classes.Pool.Enums.ASPECT" target="_blank">ASPECTS</a>.
    <ul>
        <li><b class="text-primary">BASE</b>
            <p></p>
        </li>
        <li><b class="text-primary">FINAL</b>
            <p></p>
        </li>
        <li><b class="text-primary">MAX</b>
            <p></p>
        </li>
        <li><b class="text-primary">BASE_BONUS</b>
            <p></p>
        </li>
        <li><b class="text-primary">BASE_PENALTY</b>
            <p></p>
        </li>
        <li><b class="text-primary">MULTIPLICATIVE_BONUS</b>
            <p></p>
        </li>
        <li><b class="text-primary">MULTIPLICATIVE_PENALTY</b>
            <p></p>
        </li>
        <li><b class="text-primary">ADDITIVE_BONUS</b>
            <p></p>
        </li>
        <li><b class="text-primary">ADDITIVE_PENALTY</b>
            <p></p>
        </li>
    </ul>
    @ex coming soon!
!]]
local _eModifier    = enum("Pool.MODIFIER", {   "BASE",     "FINAL",    "MAX",
                                                "BASE_BONUS",           "BASE_PENALTY",
                                                "MULTIPLICATIVE_BONUS", "MULTIPLICATIVE_PENALTY",
                                                "ADDITIVE_BONUS",       "ADDITIVE_PENALTY"},
                                                {1, 2, 3, 4, 5, 6, 7, 8, 9}, true);
--[[!
    @fqxn CoG.Classes.Pool.Enums.EVENT
    @desc <p>Used in class methods for setting/getting events.
    <br><b>Note</b>: events fire only if an event callback function has been set and only if the event is active.
    <br><b>Note</b>: events that trigger because of a change in the <b>Current</b> value, proccess before the <b>ON_CYCLE</b> event (if active).</p>
    <br><br>
    <h6>Setting an Event Callback</h6>
    <ol>
        <li>Create the function, ensuring it accepts the relevant arguments for that specific event (as shown below).</li>
        <li>Set the event by using the object's <b>setEventCallback</b> method.</li>
    </ol>
    <br><b>Note</b>: event callbacks are auto-enabled once set. To prevent this, provide false as a second argument to <b>setEventCallback</b>.
    <br><b>Note</b>: event callbacks can be changed (or deleted using nil as the first argument).
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
            <br><b>Note</b>: the <b>Low</b> value must be less than the <b>Full</b> value.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Current</b> value.</li>
                </ul>
            </p>
        </li>
        <li><b class="text-primary">ON_FULL</b>
            <p>This event occurs whenever the current value moves to or above the <b>Full</b> threshold.
            <br>The <b>Full</b> threshold is determined by the following formula:
            <br>Let <b><i>f</i></b> be a float value between 0 and 1 (exlusive).
            <br>Let <b><i>m</i></b> be the max value of the Pool.
            <b><i>FullThreshold</i></b> = <b><i>f</i></b> * <b><i>m</i></b>
            <br><br>The <b>Full</b> threshold can be set using the object's <b>setFullMarker</b> method.
            <br><b>Note</b>: the <b>Full</b> value must be greater than the <b>Low</b> value.</p>
            <p>This event callback function must accept the following arguments:
                <ul>
                    <li><b><i>Pool</i></b> <i>oPool</i> The Pool object.</li>
                    <li><b><i>number</i></b> <i>nOld</i> The old <b>Current</b> value.</li>
                    <li><b><i>number</i></b> <i>nNew</i> The new <b>Current</b> value.</li>
                </ul>
            </p>
        </li>
        <li><b class="text-primary">ON_CYCLE</b>
            <p>This event occurs whenever the object's <b>cycle</b> method is called.
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
    --optionally, disable auto-activation by providing false as the second argument.
    oPool.setEventCallback(adjustLifeUI);
!]]
local _eEvent       = enum("Pool.EVENT",    {"ON_INCREASE", "ON_DECREASE",  "ON_EMPTY", "ON_LOW",   "ON_FULL",  "ON_CYCLE", "ON_RESERVE", "ON_UNRESERVE"},
                                            {"onIncrease",  "onDecrease",   "onEmpty",  "onLow",    "onFull",   "onCycle",  "OnReserve",  "onUnreserve"}, true);

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

--TODO move _nDefaultReverseMax to config
local _nDefaultReverseMax       = 0.9999999999999;
local _nReverseHardMax          = 0.9999999999999; --the max reservation allowed
local eventPlaceholder          = function() end


local function setCurrent(this, cdat, nNew)
    local pro           = cdat.pro;
    local nMax          = pro[_sAspectMax][_nFinal];
    local nCurrent      = pro[_sAspectCurrent];
    local nReserved     = pro[_sAspectReserved];
    local nAvailable    = nMax - nReserved;
    local bWasEmpty     = pro.isEmpty;
    local bWasLow       = pro.isLow;
    local bWasFull      = pro.isFull;
    local bIsEmpty      = bWasEmpty;
    local bIsLow        = bWasLow;
    local bIsFull       = bWasFull;
    local bIsIncrease   = nNew > nCurrent;
    local bIsDecrease   = nNew < nCurrent;
    local bChanged      = bIsIncrease or bIsDecrease;
    local bCanGoUp      = bIsIncrease and nCurrent < nAvailable;
    local bCanGoDown    = bIsDecrease and nCurrent > 0;

    if (bCanGoUp or bCanGoDown) then

        --clamp the value
        if (nNew <= 0) then
            nNew = 0;
            pro[_sAspectCurrent] = nNew;
            pro.isEmpty,    bIsEmpty = true,    true;
            pro.isLow,      bIsLow   = false,   false;
            pro.isFull,     bIsFull  = false,   false;
        else
            --set the current value
            nNew = (nNew <= nAvailable) and nNew or nAvailable;
            pro[_sAspectCurrent] = nNew;

            bIsEmpty    = false;
            bIsLow      = nNew <= (nMax * pro.lowMarker);
            bIsFull     = nNew >= (nMax * pro.fullMarker);

            pro.isEmpty     = bIsEmpty;
            pro.isLow       = bIsLow;
            pro.isFull      = bIsFull;
        end

        --process events
        local tActiveEvents = pro.activeEvents;
        local tEvents       = pro.events;

        if (bIsIncrease and tActiveEvents[_sOnIncrease]) then
            tEvents[_sOnIncrease](this, nCurrent, nNew);
        elseif (bIsDecrease and pro.activeEvents[_sOnDecrease]) then
            pro[_sOnDecrease](this, nCurrent, nNew);
        end

        if (bIsEmpty    and bIsEmpty    ~= bWasEmpty    and tActiveEvents[_sOnEmpty])   then
            tEvents[_sOnEmpty](this, nCurrent);
        elseif (bIsLow  and bIsLow      ~= bWasLow      and tActiveEvents[_sOnLow])     then
            tEvents[_sOnLow](this, nCurrent, nNew);
        elseif (bIsFull and bIsFull     ~= bWasFull     and tActiveEvents[_sOnFull])    then
            tEvents[_sOnFull](this, nCurrent, nNew);
        end

    end

    return nCurrent ~= nNew, nNew;
end


--Final = ((nBase + nBaseBonus - nBasePenalty) * (1 + nMultBonus - nMultPenalty)) + nAddBonus - nAddPenalty;
local function calculateFinal(this, cdat, sIndex)
    local pro       = cdat.pro;
    local tValue    = pro[sIndex];
    return (    tValue[_nBase] +
                tValue[_nBaseBonus] - tValue[_nBasePenalty]) *
                (1 + tValue[_nMultBonus] - tValue[_nMultPenalty]);
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
    bRet = nNewAvailable > tMax.min;

    if (bRet) then
        --set the new max
        tMax[_nFinal] = nNewFinal;

        --set the new reserved
        pro[_sAspectReserved] = nTotalReserved;

        --set the new avaiable
        pro[_sAspectAvailable] = nNewAvailable;

        --check current and adjust if needed
        if (pro[_sAspectCurrent] > nNewAvailable) then
            setCurrent(this, cdat, nNewAvailable);
        end

    else
        nOverage = nNewAvailable - tMax.min;
    end

    return bRet, nOverage
end



local function attemptSettingReserved(this, cdat, sAspect, nValue, nModifier)--TODO return overage
    local pro           = cdat.pro;
    local bRet          = false;
    local nOverage      = 0;

    --TODO check input values!!!
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
    bRet = (    (nOldTotalReserved ~= nTotalReserved) and
                (nTotalReserved / nMax) <= tResPercent[_nMax]);

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
        end

        --check for and fire reserve event
        local bOnReserve   = nOldTotalReserved < nTotalReserved;
        local bOnUnReserve = nOldTotalReserved > nTotalReserved;

        if (bOnReserve and pro.activeEvents[_sOnReserve]) then
            pro.events[_sOnReserve](this, nOldTotalReserved, nTotalReserved, bChangeInCurrent, nNewCurrent, nAvailable, nMax);
        elseif (bOnUnReserve and pro.activeEvents[_sOnUnReserve]) then
            pro.events[_sOnUnReserve](this, nOldTotalReserved, nTotalReserved, bChangeInCurrent, nNewCurrent, nAvailable, nMax);
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


--[[!
    @fqxn CoG.Classes.Pool
    @author Centauri Soldier
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
        newpro.fullMarker           = pro.fullMarker;
        newpro.isEmpty              = pro.isEmpty;
        newpro.isFull               = pro.isFull;
        newpro.isLow                = pro.isLow;
        newpro[_sAspectAvailable]   = pro[_sAspectAvailable];
        newpro[_sAspectCurrent]     = pro[_sAspectCurrent];
        newpro[_sAspectCycle]       = pro[_sAspectCycle];
        newpro[_sAspectReserved]    = pro[_sAspectReserved];

        return oNew;
    end,
},
--TODO __serialize
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
    lowMarker       = 0.3,  --TODO
    fullMarker      = 1,    --TODO QUESTION should full include reserved?
    isEmpty         = false,
    isFull          = false,
    isLow           = false,
},
{--PUBLIC

    --[[!
    @fqxn CoG.Classes.Pool.Methods.Pool
    @desc The constructor for the <b>Pool</b> class.
    @param number|nil nMax The maximum value of the Pool (minimum 1).
    @param number|nil nCurrent The current value of the Pool (minimum 0, maximum nMax).
    !]]
    Pool = function(this, cdat, nMax, nCurrent)
        local pro   = cdat.pro;
        nMax        = type(nMax) 		== "number"	and nMax	    or 1;
        nCurrent	= type(nCurrent) 	== "number" and nCurrent    or 1;
        nCycle 	    = type(nCycle) 		== "number" and nCycle 		or 0;
        nReserved   = type(nReserved)   == "number" and nReserved   or 0;

        if (nMax < 1) then
            error("Error creating Pool object.\nMax value must be positive number greater than or equal to 1.");
        end

        if (nCurrent < 0) then
            error("Error creating Pool object.\nCurrent value must be non-negative.");
        end

        --set the values
        --TODO check and clamp ALL values!
        pro[_sAspectMax][_nBase]        = nMax;
        pro[_sAspectMax][_nFinal]       = nMax;
        pro[_sAspectAvailable]          = nMax;

        local bSuccess, nNew = setCurrent(this, cdat, nCurrent);
    end,


    adjust = function()
    end,


    --[[!
    @fqxn CoG.Classes.Pool.Methods.cycle
    @desc Causes the Pool to cycle based on the cycle value (after all modifiers have been applied).
    <br>This is used for things like regeneration of mana, regen and/or poisoning of life, consumption of fuel, etc.
    @param number|nil nMultiple If a number is provided, it will cycle the number of times input, otherwise, once.
    <br>Note: regardless of the multiple provided (if any), the <strong>onCycle</strong> event will fire only once per cycle.
    @ret Pool oPool The Pool object.
    !]]
    cycle = function(this, cdat, nMultiplier)
        local pro           = cdat.pro;
        local nCurrent      = pro[_sAspectCurrent];
        --local nMax          = pro[_sAspectMax][_nFinal];
        local nAvailable    = pro[_sAspectAvailable];
        local nCycle        = pro[_sAspectCycle];
        local bIsNegative   = nCycle < 0;
        local bIsPositive   = nCycle > 0;
        local bCanGoDown    = nCurrent > 0;
        local bCanGoUp      = nCurrent < nAvailable;

        if ( (bIsNegative and bCanGoDown) or (bIsPositive and bCanGoUp) ) then
            --process the cycle
            nMultiplier = (rawtype(nMultiplier) == "number" and nMultiplier ~= 0) and nMultiplier or 1;
            local nTotalChange = pro[_sAspectCurrent] + (nCycle * nMultiplier);

            --clamp the current value
            local bSuccess, nNew = setCurrent(this, cdat, nTotalChange);

            --run the cycle event if active (and something changed)
            if (bSuccess and pro.activeEvents[_sOnCycle]) then
                pro.events[_sOnCycle](this, nCurrent, nNew, nCycle, nMultiplier, nTotalChange, bIsPositive, nCurrent ~= nNew);
            end

        end

        return this;
    end,


    --[[!
    @fqxn CoG.Classes.Pool.Methods.isEmpty
    @desc Determines whether the Pool is empty.
    <br>This is true when the current value is less than or equal to 0.
    @ret boolean bEmpty True if the Pool is empty, false otherwise.
    !]]
    isEmpty = function(this, cdat)
        return cdat.pro.isEmpty;
    end,


    --[[!
    @fqxn CoG.Classes.Pool.Methods.isFull
    @desc Determines whether the Pool is full.
    <br>This is true when the current value is (<em>greater than or</em>) equal to the TODO value.
    @ret boolean bEmpty True if the Pool is full, false otherwise.
    !]]
    isFull = function(this, cdat)
        return cdat.pro.isFull;
    end,


    --[[!
    @fqxn CoG.Classes.Pool.Methods.isLow
    @desc Determines whether the Pool is low.
    <br>This is true when the current value is (<em>greater than or</em>) equal to the TODO value.
    @ret boolean bEmpty True if the Pool is low, false otherwise.
    !]]
    isLow = function(this, cdat)
        return cdat.pro.isLow;
    end,


    --[[!
    @fqxn CoG.Classes.Pool.Methods.get
    @desc TODO
    @ex TODO
    @param Pool.ASPECT|nil eAspect If provided, this refers to the aspect of the pool to get such as MAX or CYCLE.
    <br>If not provided it will default to CURRENT.
    @param Pool.MODIFIER|nil eModifier If provided, this indicates which modifier to get such as BASE, BASE_BONUS, etc.
    <br>If not provided, it will default to BASE.
    <br><strong>Note</strong>: not all aspects have all modifiers. E.g., Pool.ASPECT.RESERVED, Pool.ASPECT.CURRENT Pool.ASPECT.AVAILABLE have no modifiers whatsoever and only accessor methods.
    @ret number nRet The value requested in either a flat value or a percentage between 0 and 1.
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
    @fqxn CoG.Classes.Pool.Methods.set
    @desc TODO
    @ex TODO
    @param number nValue The value to which the item should be set.
    @param Pool.ASPECT|nil eAspect If provided, this refers to the aspect of the pool to set such as MAX or CYCLE.
    <br>If not provided it will default to <b>CURRENT</b>.
    @param Pool.MODIFIER|nil eModifier If provided, this indicates which modifier to set such as BASE, BASE_BONUS, etc.
    <br>If not provided, it will default to BASE.
    <br><strong>Note</strong>: not all aspects have all modifiers. E.g., Pool.ASPECT.CURRENT has no modifiers whatsoever.
    !]]
    set = set,


    --[[!
    @fqxn CoG.Classes.Pool.Methods.setEmpty
    @desc Set the Pool to empty (if not already empty).
    @ret Pool oPool The Pool object.
    !]]
    setEmpty = function(this, cdat)

        --process only if the Pool isn't already empty
        if (cdat.pro[_sAspectCurrent] > 0) then
            setCurrent(this, cdat, 0);
        end

        return this;
    end,


    --[[!
    @fqxn CoG.Classes.Pool.Methods.setEventActive
    @desc Enables\disables an event from triggering.
    <br>Note: this does not affect any current callback function for this event, it simply makes<br>
    the event dormant until manually reactivated.
    @param boolean bEnable Enables the event if true, disables it otherwise.
    @ret Pool oPool The Pool object.
    !]]
    setEventActive = function(this, cdat, eEvent, bFlag)
        local pro = cdat.pro;

        if (type(eEvent) ~= "Pool.EVENT") then
            error("Error setting event callback in Pool class.\nExpected Pool.EVENT.Got type, "..type(eEvent)..'.');
        end

        local sEvent = eEvent.value;
        pro.activeEvents[sEvent] = rawtype(bFlag == "boolean") and (bFlag and pro.events[sEvent] ~= eventPlaceholder) or false;

        return this;
    end,


    --[[!
    @fqxn CoG.Classes.Pool.Methods.setEventCallback
    @desc Sets a callback function for the specified event. The funciton will fire whenever the event is triggered.
    @param Pool.EVENT eEvent The event for which the function should be called.
    @param function|nil fCallback The callback function.
    <br>Note: If a function is not input, it will delete any previous callback function and disable the event trigger.
    @param boolean|nil bDoNotAutoActivate If a true value is input, it will prevent the event from being activated by this call.
    <br>If nothing is provided, the event is active by default and the callback function will fire on event trigger.
    @ret Pool oPool The Pool object.
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
    @fqxn CoG.Classes.Pool.Methods.setFull
    @desc Sets Pool's current value to the maximum available (if not already that high).
    <br>Note: this is not the same as the maximum value.
    <br>For instance, if 20% of a Pool (whose max is 100) is reserved, the value would be set to 80.
    @ret Pool oPool The Pool object.
    !]]
    setFull = function(this, cdat) --TODO account for reserved
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

    setFullMarker = function(this, cdat, nValue)
        --must be float
        --must be great than low
    end,
    --TODO setLow
    --TODO setLowMarker
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
