--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
    <h2>Protean</h2>
    <p>An object designed to hold a base value (or use an external one) as well
    as adjuster values which operate on the base value to produce a final result.
    Designed to be a simple-to-use modifier system.</p>
    <br>
    <p>
    <b>Note:</b> <em>"bonus"</em> and <em>"penalty"</em> are logical concepts.
    How they are calculated is up to the client. They should be set, applied
    and processed as if they infer their respective, purported affects. That is,
    a <em>"bonus"</em> could be a positve value in one case or a negative value
    in another, so long as the target is gaining some net benefit. The sign of
    the value should not be assumed but, rather, tailored to apply a beneficial
    affect (for bonus) or detramental affect (for penalty).
    <br>
    <br>
    Also, any multiplicative value is treated as a percetage and should be a float value.
    <br>
    E.g.,
    <br>
    <ul>
        <li>1    = 100%</li>
        <li>0.2  = 20%</li>
        <li>1.65 = 165%</li>
    </ul>
    <br>
    In order of altering affect intensity (descending):
    Base, Multiplicative, Addative
    <br>
    <br>
    How the final value is calcualted:
    <br>
    Let V be some value, B be the base adjustment,
    M be the multiplicative adjustment, A be the
    addative adjustment and sub-b be the bonus and sub-p be the penalty.
    <br>
    <br>
    V = [(V + Bb - Bp) * (1 + Mb - Mp)] + Ab - Ap
    <br>
    <br>
    There may be some instances where a client may use several Protean objects but wants the
    same base value for all of them. Call <code>setLinker(number)</code> to create or join a linker,
    and <code>getLinkerID()</code> to share its ID. Call <code>setLinker()</code> to detach,
    retaining the current shared base. Modifiers and limits remain per instance.
    Cloning creates an independent, unlinked copy of the current shared base.
    Cloning retains callback references. Serialization is supplied by the class system.
    </p>
@license <p>The Unlicense<br>
<br>
@moduleid Protean
@version 1.3
@versionhistory
<ul>
    <li>
        <b>1.3</b>
        <br>
        <p>Added a linker system allowing multiple Protean objects to share the same base value. This makes for much faster processing of Proteans which have a common base value.</p>
        <p>Bugfix: Proteans were not linking properly.</p>
        <p>Bugfix: deserialize function was not relinking Protean.</p>
        <p>Feature: added the ability, upon unlinking, to restore a Proteans original value.</p>
    </li>
    <li>
        <b>1.2</b>
        <br>
        <p>Forced safe and default input for constructor.</p>
    </li>
    <li>
        <b>1.1</b>
        <br>
        <p>Added the ability to set a callback function on value change.</p>
        <p>Added the ability to enable or disable the callback function.</p>
        <p>Added the ability to disable auto-calculation of the final value.</p>
        <p>Added the ability to manually call for calculation of the final value.</p>
    </li>
    <li>
        <b>1.0</b>
        <br>
        <p>Created the module.</p>
    </li>
</ul>
@website https://github.com/CentauriSoldier
*]]
local Protean;

local class     = class;
local constant  = constant;
local math      = math;
local pairs     = pairs;
local table     = table;
local type      = type;
local rawtype   = rawtype;



--placeholder so higher functions can access it
local calculateFinalValue;

local _nValueBase     = 1;
local _nValueFinal    = 2; --this is (re)calcualted whenever another item is changed
local _nBaseBonus     = 3;
local _nBasePenalty   = 4;
local _nMultBonus     = 5;
local _nMultPenalty   = 6;
local _nAddBonus      = 7;
local _nAddPenalty    = 8;
local _nLimitMin      = 9;
local _nLimitMax      = 10;
--for value getting/setting
local _nIndexMin = _nValueBase;
local _nIndexMax = _nLimitMax;

local function onChangePlaceHolder() end

--[[
 Stores linkers for Protean objects with a shared base value.
 The table is structure is as follows:
 _tLinkers[nLinkerID] = {
         baseValue = x,
        index = {--for fast existential queries of a Protean object within a linker
            Proteanobject1 = true,
            Proteanobject2 = true,
            etc...
        }
         Proteans = {
            [1] = Proteanobject1,
            [2] = Proteanobject2,
            etc...
        },
        totalLinked = 0,
    };
]]
local _tLinkers = {};

--[[
    @desc Checks whether the supplied ID refers to an existing linker.
    @mod
    @param this
    @param nLinkerID
    @scope local
]]
local function linkerIDIsValid(nLinkerID)
    return rawtype(nLinkerID) == "number" and math.floor(nLinkerID) == nLinkerID and nLinkerID > 0 and _tLinkers[nLinkerID];
end

--[[
    @desc Detaches the object from its linker and retains the current shared base value.
    @mod
    @param this
    @param nLinkerID
    @scope local
]]
local function unlink(this, cdat)
    local pri = cdat.pri;
    local nLinkerID = pri.linkerID;

    if (pri.isLinked and linkerIDIsValid(nLinkerID) and _tLinkers[nLinkerID].Proteans[this]) then

        --set the object's base value to it's original value or the linker's base value
        pri.values[_nValueBase] = _tLinkers[nLinkerID].baseValue;

        --update its linked status and linkerID
        pri.isLinked = false;
        pri.linkerID = -1;

        --remove the object from the linker
        _tLinkers[nLinkerID].Proteans[this] = nil;
    end

end

--[[
    @desc Links a Protean object to the specified (or new) linker. If the object is currently linked to another linker, it will be unlinked from that linker.
    @mod Protean
    @param nLinkerID number The linker ID; that is, the ID of the linker to which the Protean will be linked. If this is nil or otherwise invalid, a new linker will be created.
    @scope local
]]
local function link(this, cdat, nLinkerID)
    local pri = cdat.pri;
    nLinkerID = linkerIDIsValid(nLinkerID) and nLinkerID or #_tLinkers + 1;

    --make sure it's not trying to be linked to its current linker
    if not (pri.linkerID == nLinkerID) then

        --create the linker if it doesn't exist
        if not (_tLinkers[nLinkerID]) then
            _tLinkers[nLinkerID] = {
                --the new linker will start with the creating object's base value
                baseValue   = pri.values[_nValueBase],
                --byObject    = {},
                Proteans    = {},
            };
        end

        --unlink if currently linked
        if (pri.isLinked) then
            unlink(this, cdat);
        end

        local tLinker = _tLinkers[nLinkerID];

        --link it only if it's not already linked
        if not (tLinker.Proteans[this]) then
            local tValues = pri.values;


            --set the object's base value to be the same as the linker's
            tValues[_nValueBase] = tLinker.baseValue;

            --link the Protean and update its settings
            pri.isLinked = true;
            pri.linkerID = nLinkerID;

            --update the hub to reflect the new addition and store the object's original value
            --tLinker.byObject[this] = nOriginalValue;
            --tLinker.Proteans[#tLinker.Proteans + 1] = this;
            tLinker.Proteans[this] = cdat;
        end

        --NOTE: DO NOT REMOVE LINKERS OR ELSE THE LINKER IDs WILL REFERENCE THE WRONG TABLE INDEX

        --recalculate the final value
        if (pri.autoCalculate) then
            calculateFinalValue(this, cdat);
        end

        --update the linked count
        --tLinker.totalLinked = #tLinker.Proteans;

    end
end

--local function ExternalTableIsValid(tTable)
--  return rawtype(tTable) == "table" and rawtype(tTable[PROTEAN.EXTERNAL_INDEX]) == "number";
--end


--[[
    @desc Calculates and stores the final value using the modifiers and enabled limits.
    @mod
    @param this
    @param nLinkerID
    @scope local
]]
calculateFinalValue = function(this, cdat)
    local pri       = cdat.pri;
    local tValues   = pri.values;
    local nBase     = pri.isLinked and _tLinkers[pri.linkerID].baseValue or tValues[_nValueBase];

    local nBaseBonus    = tValues[_nBaseBonus];
    local nBasePenalty  = tValues[_nBasePenalty];
    local nMultBonus    = tValues[_nMultBonus];
    local nMultPenalty  = tValues[_nMultPenalty];
    local nAddBonus     = tValues[_nAddBonus];
    local nAddPenalty   = tValues[_nAddPenalty];
    local nFinal        = ((nBase + nBaseBonus - nBasePenalty) * (1 + nMultBonus - nMultPenalty)) + nAddBonus - nAddPenalty;

    --clamp the value if it has been limited
    if (pri.limitMin) then
        local nMin = tValues[_nLimitMin];
        nFinal = nFinal > nMin and nFinal or nMin;
    end

    if (pri.limitMax) then
        local nMax = tValues[_nLimitMax];
        nFinal = nFinal <= nMax and nFinal or nMax;
    end

    tValues[_nValueFinal] = nFinal;
    return nFinal;
end

--[[
    @desc Assigns a value, refreshes automatic final values and invokes active callbacks.
    @mod
    @param this
    @param nLinkerID
    @scope local
]]
local function setValue(this, cdat, nType, nValue)
    local pri = cdat.pri;
    local tValues = pri.values;
    local nOldValue = this.getValue(nType);

    tValues[nType] = nValue;

    if (nType == _nLimitMin or nType == _nLimitMax) then
        if (tValues[_nLimitMin] > tValues[_nLimitMax]) then
            tValues[_nLimitMin] = tValues[_nLimitMax];
        end
    end

    local tNotifications = {};

    local function update(oProtean, tCDat)
        local pri = tCDat.pri;

        if (pri.autoCalculate) then
            calculateFinalValue(oProtean, tCDat);
        end

        if (pri.isCallbackActive) then
            tNotifications[#tNotifications + 1] = {
                callback = pri.onChange,
                object = oProtean,
                final = pri.values[_nValueFinal],
            };
        end
    end

    if (pri.isLinked and nType == _nValueBase) then
        local tLinker = _tLinkers[pri.linkerID];
        tLinker.baseValue = nValue;

        for oProtean, tCDat in pairs(tLinker.Proteans) do
            update(oProtean, tCDat);
        end
    else
        update(this, cdat);
    end

    --Refresh every member before callbacks can inspect or change the group.
    for _, tNotification in ipairs(tNotifications) do
        tNotification.callback(tNotification.object, nType, nOldValue, nValue, tNotification.final);
    end
end

--[[
    @desc returns a number that is one greater than the maximum number of linkers in the Hub. This is used for determining the next, empty, available linker ID.
    @func Protean.getAvailableLinkerID
    @module Protean
    @return nLinkerID number The next open index in the Hub.
]]
local function getAvailableLinkerID()
    return #_tLinkers + 1;
end

local function categoryIsValid(nType)
    return rawtype(nType) == "number" and nType == math.floor(nType) and
           nType >= _nIndexMin and nType <= _nIndexMax;
end

local function validateValue(nValue)
    assert(rawtype(nValue) == "number" and nValue == nValue, "Protean value must be a number other than NaN.");
end

Protean = class("Protean",
{--METAMETHODS
    --[[!
    @fqxn LuaEx.Classes.Protean.Metamethods.__clone
    @desc Creates an independent, unlinked snapshot. Copies modifiers, bounds, calculation mode, cached final value and callback locks. Retains the callback reference and active state. Does not invoke callbacks.
    @ret Protean oClone A new snapshot instance.
    @ex
    local oCopy = clone(oProtean);
    !]]
    __clone = function(this, cdat)
        local oClone       = Protean();
        local pri          = cdat.pri;
        local tCopyPrivate = cdat.ins[oClone].pri;

        for sField, vValue in pairs(pri) do
            if (rawtype(vValue) ~= "function" and sField ~= "values" and sField ~= "isLinked" and sField ~= "linkerID") then
                tCopyPrivate[sField] = vValue;
            end
        end

        for nType = _nIndexMin, _nIndexMax do
            tCopyPrivate.values[nType] = this.getValue(nType);
        end

        tCopyPrivate.onChange = pri.onChange;
        return oClone;
    end,
},
{--STATIC PUBLIC
--[[!
    @fqxn LuaEx.Classes.Protean.Static Methods.getAvailableLinkerID
    @desc Returns the next available linker ID without creating a linker. Linker IDs are retained and are not recycled when their members detach.
    @ret number nLinkerID The next linker ID.
    !]]
    getAvailableLinkerID = getAvailableLinkerID,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.VALUE_BASE
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    VALUE_BASE__RO              = _nValueBase,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.VALUE_FINAL
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    VALUE_FINAL__RO             = _nValueFinal,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.BASE_BONUS
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    BASE_BONUS__RO              = _nBaseBonus,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.BASE_PENALTY
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    BASE_PENALTY__RO            = _nBasePenalty,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.MULTIPLICATIVE_BONUS
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    MULTIPLICATIVE_BONUS__RO    = _nMultBonus,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.MULTIPLICATIVE_PENALTY
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    MULTIPLICATIVE_PENALTY__RO  = _nMultPenalty,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.ADDATIVE_BONUS
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    ADDATIVE_BONUS__RO          = _nAddBonus,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.ADDATIVE_PENALTY
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    ADDATIVE_PENALTY__RO        = _nAddPenalty,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.LIMIT_MIN
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    LIMIT_MIN__RO               = _nLimitMin,
    --[[!
    @fqxn LuaEx.Classes.Protean.Fields.LIMIT_MAX
    @desc An alias for the number referring this specific value category. Used in Protean operations.
    @return nCategory number The value category number.
    !]]
    LIMIT_MAX__RO               = _nLimitMax,

    --LIMIT   = enum("Protean.LIMIT",     {"MIN", "MAX"}, true);
    --MOD     = enum("Protean.MOD",         {"ADDATIVE_BONUS",       "ADDATIVE_PENALTY",
    --                                     "BASE_BONUS",           "BASE_PENALTY",
    --                                     "MULTIPLICATIVE_BONUS", "MULTIPLICATIVE_PENALTY"}, true);
    --VALUE   = enum("Protean.VALUE",   {"BASE", "FINAL"}, true);
    --Protean = function(stapub) end,
},
{--PRIVATE
    limitMin                = false,
    limitMax                = false,
    linkerID                = -1,
    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.isLinked
    @desc Reports whether the base value belongs to a shared linker.
    @ret boolean bLinked Whether this instance is linked.
    !]]
    isLinked                = false, --for fast queries
    autoCalculate           = true,
    onChange                = onChangePlaceHolder,
    isCallbackActive        = false,
    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.isCallbackLocked
    @desc Reports whether callback replacement or clearing is locked.
    @ret boolean bLocked Whether callback changes are locked.
    !]]
    isCallbackLocked        = false,
    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.isCallbackToggleLocked
    @desc Reports whether callback activation changes are locked.
    @ret boolean bLocked Whether callback toggling is locked.
    !]]
    isCallbackToggleLocked  = false,
    values = {
        [_nValueBase]       = 0,
        [_nValueFinal]      = 0, --this is (re)calcualted whenever another item is changed
        [_nBaseBonus]       = 0,
        [_nBasePenalty]     = 0,
        [_nMultBonus]       = 0,
        [_nMultPenalty]     = 0,
        [_nAddBonus]        = 0,
        [_nAddPenalty]      = 0,
        [_nLimitMin]        = 0,
        [_nLimitMax]        = 0,
    },
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.Protean
    @desc The constructor for the Protean class.
    @param nBaseValue number This value is <code>Vb where Vf = [(Vb + Bb - Bp) * (1 + Mb - Mp)] + Ab - Ap</code> and where Vf is the calculated, final value. If set to nil, it will default to 0.
    @param nBaseBonus number/nil This value is Bb where Vf = [(Vb + Bb - Bp) * (1 + Mb - Mp)] + Ab - Ap and where Vf is the calculated, final value. If set to nil, it will default to 0.
    @param nBasePenalty number/nil This value is Bp where Vf = [(Vb + Bb - Bp) * (1 + Mb - Mp)] + Ab - Ap and where Vf is the calculated, final value. If set to nil, it will default to 0.
    @param nMultiplicativeBonus number/nil This value is Mb where Vf = [(Vb + Bb - Bp) * (1 + Mb - Mp)] + Ab - Ap and where Vf is the calculated, final value. If set to nil, it will default to 0.
    @param nMultiplicativePenalty number/nil This value is Mp where Vf = [(Vb + Bb - Bp) * (1 + Mb - Mp)] + Ab - Ap and where Vf is the calculated, final value. If set to nil, it will default to 0.
    @param nAddativeBonus number/nil This value is Ab where Vf = [(Vb + Bb - Bp) * (1 + Mb - Mp)] + Ab - Ap and where Vf is the calculated, final value. If set to nil, it will default to 0.
    @param nAddativePenalty number/nil This value is Ap where Vf = [(Vb + Bb - Bp) * (1 + Mb - Mp)] + Ab - Ap and where Vf is the calculated, final value. If set to nil, it will default to 0.
    @param nMinLimit number/nil This is the minimum value that the calculated, final value will return. If set to nil, it will be ignored and there will be no minimum value.
    @param nMaxLimit number/nil This is the maximum value that the calculated, final value will return. If set to nil, it will be ignored and there will be no maximum value.
    @param fonChange function/nil Called with instance, category, old value, new value and cached final value. In manual mode the final value is not refreshed.
    <br>Note: the callback function must accept the following paramters:
    <ol>
        <li>The Protean object. <em>(Protean)</em>.</li>
        <li>The value type. <em>(number)</em></li>
        <li>The previous value. <em>(number)</em></li>
        <li>The changed value. <em>(number)</em></li>
        <li>The final value. <em>(number)</em></li>
    </ol>
    @param bDontAutoCalculate boolean|nil Set true to disable automatic recalculation. Initial construction always calculates once.
    @return oProtean Protean A Protean object.
    !]]
    Protean = function(this, cdat, nBaseValue,  nBaseBonus,             nBasePenalty,
                                                nMultiplicativeBonus,   nMultiplicativePenalty,
                                                nAddativeBonus,         nAddativePenalty,
                                                nMinLimit,              nMaxLimit,
                                                fonChange,              bDontAutoCalculate)

        local pri       = cdat.pri;
        local tValues   = pri.values;
for _, nValue in pairs({nBaseValue, nBaseBonus, nBasePenalty, nMultiplicativeBonus, nMultiplicativePenalty,
                               nAddativeBonus, nAddativePenalty, nMinLimit, nMaxLimit}) do
            if (rawtype(nValue) == "number") then
                validateValue(nValue);
            end
        end

        local bHasCallbackFunction  = rawtype(fonChange) == "function";
        pri.limitMin = rawtype(nMinLimit) == "number";
        pri.limitMax = rawtype(nMaxLimit) == "number";

        --local eLimit    = Protean.LIMIT;
        --local eMod      = Protean.MOD;
        --local eValue    = Protean.VALUE;

        tValues[_nValueBase]    = rawtype(nBaseValue)               == "number"     and nBaseValue              or 0;
        tValues[_nBaseBonus]    = rawtype(nBaseBonus)               == "number"     and nBaseBonus              or 0;
        tValues[_nBasePenalty]  = rawtype(nBasePenalty)             == "number"     and nBasePenalty            or 0;
        tValues[_nMultBonus]    = rawtype(nMultiplicativeBonus)     == "number"     and nMultiplicativeBonus    or 0;
        tValues[_nMultPenalty]  = rawtype(nMultiplicativePenalty)   == "number"     and nMultiplicativePenalty  or 0;
        tValues[_nAddBonus]     = rawtype(nAddativeBonus)           == "number"     and nAddativeBonus          or 0;
        tValues[_nAddPenalty]   = rawtype(nAddativePenalty)         == "number"     and nAddativePenalty        or 0;
        tValues[_nLimitMin]     = pri.limitMin                                      and nMinLimit               or -math.huge;
        tValues[_nLimitMax]     = pri.limitMax                                      and nMaxLimit               or math.huge;
        tValues[_nValueFinal]   = 0; --this is (re)calcualted whenever another item is changed
        pri.autoCalculate       = not (rawtype(bDontAutoCalculate) == "boolean"     and bDontAutoCalculate      or false);
        pri.onChange            = bHasCallbackFunction                              and fonChange               or onChangePlaceHolder;
        pri.isCallbackActive    = bHasCallbackFunction;

        if (tValues[_nLimitMin] > tValues[_nLimitMax]) then
            tValues[_nLimitMin] = tValues[_nLimitMax];
        end

        --calculate the final value for the first time
        calculateFinalValue(this, cdat);

end,
    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.adjust
    @desc Adjusts a value by the amount input. Adjusting a linked base updates every member of that linker.
    @note If only one parameter is given, it is assumed that the base value is intended to be adjusted using the value input.
    @param nType number The type of value to adjust.
    @param nValue number The value by which to adjust the given value.
    @return oProtean Protean This Protean object.
    !]]
    adjustValue = function(this, cdat, nType, nValue)
        if (nValue == nil) then
            nValue = nType;
            nType = _nValueBase;
        end

        assert(categoryIsValid(nType) and nType ~= _nValueFinal, "Protean value category out of range.");
        validateValue(nValue);
        local nAdjusted = this.getValue(nType) + nValue;
        validateValue(nAdjusted);
        setValue(this, cdat, nType, nAdjusted);
        return this;
    end,

    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.calculateFinalValue
        @desc Calculates the final value of the Protean. This is done on-change by default so that the final value (when requested) is always up-to-date and accurate. There is no need to call this unless auto-calculate has been disabled. In that case, this serves an external utility function to perform the normally-internal operation of calculating and updating the final value.
        @return nValue number The calculated final value.
    !]]
    calculateFinalValue = function(this, cdat)
        calculateFinalValue(this, cdat);
        return this;
    end,

    --Compatibility alias for the original spelling.
    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.calulateFinalValue
    @desc Compatibility alias for calculateFinalValue(), retaining its original spelling and behavior.
    @ret Protean oProtean This instance, for chaining.
    !]]
    calulateFinalValue = function(this, cdat)
        calculateFinalValue(this, cdat);
        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.get
        @desc Gets the value of the given value type. Note: if the type provided is ProteanValue.Final and MIN or MAX limits have been set, the returned value will fall within the confines of those paramter(s).
        @note If no parameter is given, the final value is returned.
        @param nType number The type of value to adjust.
        @return nValue number The value of the given type.
    !]]
    getValue = function(this, cdat, nType)
        nType = nType == nil and _nValueFinal or nType;
        assert(categoryIsValid(nType), "Protean value category out of range.");
        local pri = cdat.pri;

        if (nType == _nValueBase and pri.isLinked) then
            return _tLinkers[pri.linkerID].baseValue;
        end

        return pri.values[nType];
    end,

    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.getLinkerID
        @desc Gets this Protean's linkerID.
        @return nID number The ID of the linker;
    !]]
    getLinkerID = function(this, cdat)
        return cdat.pri.linkerID;
    end,

    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.isAutoCalculated
        @desc Determines whether or not auto-calculate is active.
        @return bActive boolean Whether or not auto-calculate occurs on value change.
    !]]
    isAutoCalculated = function(this, cdat)
        return cdat.pri.autoCalculate;
    end,

    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.isCallbackActive
        @desc Determines whether or not the callback is called on change.
        @return bActive boolean Whether or not the callback is called on value change.
    !]]
    isCallbackActive = function(this, cdat)
        return cdat.pri.isCallbackActive;
    end,

    isCallbackLocked = function(this, cdat)
        return cdat.pri.isCallbackLocked;
    end,

    isCallbackToggleLocked = function(this, cdat)
        return cdat.pri.isCallbackToggleLocked;
    end,

    --@fqxn LuaEx.Classes.Protean
    isLinked = function(this, cdat)
        return cdat.pri.isLinked;
    end,

    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.lockCallback
    @desc Permanently prevents setCallback() from replacing or clearing this instance's callback. Activation remains independently controlled by the toggle lock.
    @ret nil No return value.
    !]]
    lockCallback = function(this, cdat)
        cdat.pri.isCallbackLocked = true;
    end,

    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.lockCallbackToggle
    @desc Permanently prevents setCallbackActive() calls and prevents setCallback() from changing the active state. Callback replacement with unchanged activation remains possible unless the callback itself is locked.
    @ret nil No return value.
    !]]
    lockCallbackToggle = function(this, cdat)
        cdat.pri.isCallbackToggleLocked = true;
    end,

    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.setAutoCalculate
        @desc By default, the final value is calculated whenever a change is made to a value; however, this method gives the power of that choice to the client. If disabled, the client will need to call calculateFinalValue to update the final value.
        @param bAutoCalculate boolean Whether or not the objects should auto-calculate the final value.
        @return oProtean Protean This Protean object.
    !]]
    setAutoCalculate = function(this, cdat, bFlag)
        local pri = cdat.pri;
        pri.autoCalculate = rawtype(bFlag) == "boolean" and bFlag or false;

        if (pri.autoCalculate) then
            calculateFinalValue(this, cdat);
        end

        return this;
    end,

    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.setCallback
        @desc Set the given function as this objects's onChange callback which is called whenever a change occurs (if active).
        @param fCallback function The callback function (which must accept the Protean object as its first parameter)
        @param bDoNotSetActive boolean If true, the function is not set to active, otherwise (even with nil value) the function is set to active.
        @return oProtean Protean This Protean object.
    !]]
    setCallback = function(this, cdat, fCallback, bDoNotSetActive)
        local pri = cdat.pri;

        if (pri.isCallbackLocked) then
            error("Error setting Protean callback function.\nCallback is locked.");
        end

        local bActive = rawtype(fCallback) == "function" and bDoNotSetActive ~= true;
        assert(not pri.isCallbackToggleLocked or bActive == pri.isCallbackActive, "Protean callback toggling is locked.");

        if (rawtype(fCallback) == "function") then
            pri.onChange            = fCallback;
            pri.isCallbackActive    = not (rawtype(bDoNotSetActive) == "boolean" and bDoNotSetActive or false);

        else
            pri.onChange            = onChangePlaceHolder;
            pri.isCallbackActive    = false;
        end

        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.setCallbackActive
        @desc Set the object's callback function (if any) to active/inactive. If active, it will fire whenever a change is made while nothing will occur if it is inactive.
        @param bActive boolean A boolean value indicating whether or no the callback function should be called.
        @return oProtean Protean This Protean object.
    !]]
    setCallbackActive = function(this, cdat, bFlag)
        local pri = cdat.pri;

        if (pri.isCallbackToggleLocked) then
            error("Error enabling/disabling Protean callback function.\nCallback toggling is locked.");
        end

        if (rawtype(bFlag) == "boolean") then

            if (rawtype(pri.onChange) == "function" and pri.onChange ~= onChangePlaceHolder) then
                pri.isCallbackActive = bFlag;
            end

        else
            pri.isCallbackActive = false;
        end

        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.setLimitMax
        @desc Tells the Protean whether to enable the maximum limiter.
        @param bLimit boolean|nil If true, will enable the limiter, if not, it will disable it.
        @return oProtean Protean This Protean object.
    !]]
    setLimitMax = function(this, cdat, bFlag)
        local pri = cdat.pri;
        pri.limitMax = rawtype(bFlag) == "boolean" and bFlag or false;

        if (pri.autoCalculate) then
            calculateFinalValue(this, cdat);
        end

        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.setLimitMin
        @desc Tells the Protean whether to enable the minimum limiter.
        @param bLimit boolean|nil If true, will enable the limiter, if not, it will disable it.
        @return oProtean Protean This Protean object.
    !]]
    setLimitMin = function(this, cdat, bFlag)
        local pri = cdat.pri;
        pri.limitMin = rawtype(bFlag) == "boolean" and bFlag or false;

        if (pri.autoCalculate) then
            calculateFinalValue(this, cdat);
        end

        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.setLinker
        @desc Links or unlinks this object based on the input.
        @param vLinkerID number If this is a number, the object will be linked to the provided linerkID (if valid). If the input linkerID is invalid, a proper one will be created. If the linkerID is nil, the object will be unlinked (if already linked).
        @return oProtean Protean This Protean object.
    !]]
    setLinker = function(this, cdat, nLinkerID)
        local sLinkerIDType = rawtype(nLinkerID);

        if (sLinkerIDType == "number") then
            link(this, cdat, nLinkerID);

        elseif (sLinkerIDType == "nil") then
            unlink(this, cdat);
        else
            error("Error setting Protean linker.\nLinker ID must of type number (or nil). Type given: "..type(sLinkerIDType));
        end

        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.set
        @desc Set the given value type to the value input. Note: if this object is linked, and the type provided is ProteanValue.Base, this linker's base value will also change, affecting every other linked object's base value.
        @note If only one parameter is given, it is assumed that the base value is intended to be set using the value input.
        @param nType number The type of value to adjust.
        @param nValue number The value which to set given value type.
        @return oProtean Protean This Protean object.
    !]]
    setValue = function(this, cdat, nType, nValue)
        if (nValue == nil) then
            nValue = nType;
            nType = _nValueBase;
        end

        assert(categoryIsValid(nType) and nType ~= _nValueFinal, "Protean value category out of range.");
        validateValue(nValue);
        setValue(this, cdat, nType, nValue);
        return this;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);

return Protean;
