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
        <li>1 	 = 100%</li>
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
    same base value for all of them. In this case, it would be cumbersome to have to set the
    base value for each Protean object. So, a Protean object may be told to use an external
    reference for the base value. In this case, a table is provided to the Protean object with a key
    of PROTEAN.EXTERNAL_INDEX and a number value. This allows for multiple Protean objects to reference
    the same base value without the need for resetting the base value of each object. Note: the table
    input will have a metamethod (__index) added to it which will update the final value of the Protean objects
    whenever the value is changed. If the table input already has a metamethod of __index, the Protean's __index
    metamethod will overwrite it.
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
local tProteans = {};
local Protean;

local class 	= class;
local constant 	= constant;
local math 		= math;
local pairs 	= pairs;
local table 	= table;
local type 		= type;
local rawtype 	= rawtype;



local ProteanValue 	= ProteanValue;
local ProteanLimit 	= ProteanLimit;
local ProteanMod 	= ProteanMod;

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
_nIndexMin      = _nValueBase;
_nIndexMax      = _nLimitMax;

local function onChangePlaceHolder() end

--[[
 Stores linkers for Protean objects with a shared base value.
 The table is structure is as follows:
 tLinkers[nLinkerID] = {
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
local tLinkers = {};

--[[
    @desc
    @mod
    @param this
    @param nLinkerID
    @scope local
]]
local function linkerIDIsValid(nLinkerID)
    return rawtype(nLinkerID) == "number" and math.floor(nLinkerID) == nLinkerID and nLinkerID > 0 and tLinkers[nLinkerID];
end

--[[
    @desc
    @mod
    @param this
    @param nLinkerID
    @scope local
]]
local function unlink(this, cdat)
    local pri = cdat.pri;
    local nLinkerID = pri.linkerID;

    if (pri.isLinked and linkerIDIsValid(nLinkerID) and tLinkers[nLinkerID].Proteans[this]) then

        --set the object's base value to it's original value or the linker's base value
        pri.values[_nValueBase] = tLinkers[nLinkerID].baseValue;

        --update its linked status and linkerID
        pri.isLinked = false;
        pri.linkerID = -1;

        --remove the object from the linker
        tLinkers[nLinkerID].Proteans[this] = nil;
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
    nLinkerID = linkerIDIsValid(nLinkerID) and nLinkerID or #tLinkers + 1;

    --make sure it's not trying to be linked to its current linker
    if not (pri.linkerID == nLinkerID) then

        --create the linker if it doesn't exist
        if not (tLinkers[nLinkerID]) then
            tLinkers[nLinkerID] = {
                --the new linker will start with the creating object's base value
                baseValue   = pri.values[_nValueBase],
                --byObject    = {},
                Proteans	= {},
            };
        end

        --unlink if currently linked
        if (pri.isLinked) then
            unlink(pri, false);
        end

        local tLinker = tLinkers[nLinkerID];

        --link it only if it's not already linked
        if not (tLinker.Proteans[this]) then
            local tValues = pri.values;

            --get the object's original value
            local nOriginalValue = tValues[_nValueBase]

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
--	return rawtype(tTable) == "table" and rawtype(tTable[PROTEAN.EXTERNAL_INDEX]) == "number";
--end


--[[
    @desc
    @mod
    @param this
    @param nLinkerID
    @scope local
]]
calculateFinalValue = function(this, cdat)
    local pri       = cdat.pri;
    local tValues   = pri.values;
    local nBase     = pri.isLinked and tLinkers[pri.linkerID].baseValue or tValues[_nValueBase];

    local nBaseBonus	= tValues[_nBaseBonus];
    local nBasePenalty	= tValues[_nBasePenalty];
    local nMultBonus	= tValues[_nMultBonus];
    local nMultPenalty	= tValues[_nMultPenalty];
    local nAddBonus		= tValues[_nAddBonus];
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
    @desc
    @mod
    @param this
    @param nLinkerID
    @scope local
]]
local function setValue(this, cdat, nType, nValue)--TODO send old and new final values through callback
    local pri = cdat.pri;
    local bCalculated 		= false;
    local bCallbackCalled 	= false;
    local tValues           = pri.values;
    local nFinal            = -1;

    --get the old value (for the callback function)
    local nOldValue = tValues[nType];

    --set the value
    tValues[nType] = nValue;

    if (nType == _nLimitMin or nType == _nLimitMax) then

        if (tValues[_nLimitMin] > tValues[_nLimitMax]) then
            tValues[_nLimitMin] = tValues[_nLimitMax];
        end

    end

    --check if this object is linked and, if so, update the linker and it's Proteans
    if (pri.isLinked and nType == _nValueBase) then
        local nLinkerID = pri.linkerID;

        tLinkers[nLinkerID].baseValue = nValue;

        --update the linked Proteans' final value
        for oProtean, tCDAT in pairs(tLinkers[nLinkerID].Proteans) do
            local tPrivate = tCDAT.pri;

            if (tPrivate.autoCalculate) then
                --(re)calculate the final value
                nFinal = calculateFinalValue(oProtean, tCDAT);
            end

            if (tPrivate.isCallbackActive) then
                --process the callback function
                oProtean.onChange(oProtean, nType, nOldValue, nValue, nFinal);
            end

        end

        --indicate that this Protean has also been calulated
        bCalculated 	= true;
        --and the callback has been called
        bCallbackCalled = true;
    end

    if (not bCalculated and pri.autoCalculate) then
        ---(re)calculate the final value
        nFinal = calculateFinalValue(this, cdat);
    end

    if (not bCallbackCalled and pri.isCallbackActive) then
        pri.onChange(this, nType, nOldValue, nValue, nFinal);
    end

end


--[[
    @desc returns a number that is one greater than the maximum number of linkers in the Hub. This is used for determining the next, empty, available linker ID.
    @func Protean.getAvailableLinkerID
    @module Protean
    @return nLinkerID number The next open index in the Hub.
]]
function ProteangetAvailableLinkerID()
    return #tLinkers + 1;
end

return class("Protean",
{--METAMETHODS
    __clone = function(this, cdat)

    end,
    --[[
    @desc Serializes the object's data. Note: This does NOT serialize callback functions.
    @func Protean.serialize
    @module Protean
    @param bDefer boolean Whether or not to return a table of data to be serialized instead of a serialize string (if deferring serializtion to another object).
    @ret sData StringOrTable The data returned as a serialized table (string) or a table is the defer option is set to true.
    ]]
    __serialize = function(this, cdat)
        local tFields = tProteans[this];


        local tData = {
            [ProteanValue.Base]					= tFields.isLinked and tLinkers[tFields.linkerID].baseValue or tFields[ProteanValue.Base],
            [ProteanMod.BaseBonus] 				= tFields[ProteanMod.BaseBonus],
            [ProteanMod.BasePenalty] 			= tFields[ProteanMod.BasePenalty],
            [ProteanMod.MultiplicativeBonus] 	= tFields[ProteanMod.MultiplicativeBonus],
            [ProteanMod.MultiplicativePenalty] 	= tFields[ProteanMod.MultiplicativePenalty],
            [ProteanMod.AddativeBonus] 			= tFields[ProteanMod.AddativeBonus],
            [ProteanMod.AddativePenalty] 		= tFields[ProteanMod.AddativePenalty],
            [ProteanValue.Final]				= tFields[ProteanValue.Final],
            [ProteanLimit.Min]	 				= tFields[ProteanLimit.Min],
            [ProteanLimit.Max] 					= tFields[ProteanLimit.Max],
            isLinked							= tFields.isLinked,
            linkerID							= tFields.linkerID,
            autoCalculate						= tFields.autoCalculate,
            onChange 							= tFields.onChange,
            isCallbackActive					= tFields.isCallbackActive,
        };

        if (not bDefer) then
            tData = serialize.table(tData);
        end

        return tData;
    end,
},
{--STATIC PUBLIC
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
    --MOD     = enum("Protean.MOD", 	    {"ADDATIVE_BONUS",       "ADDATIVE_PENALTY",
    --                                     "BASE_BONUS",           "BASE_PENALTY",
    --                                     "MULTIPLICATIVE_BONUS", "MULTIPLICATIVE_PENALTY"}, true);
    --VALUE   = enum("Protean.VALUE", 	{"BASE", "FINAL"}, true);
    --Protean = function(stapub) end,
    --[[
        @desc Deserializes data and sets the object's properties accordingly.
        @func Protean.deserialize
        @module Protean
    ]]
    deserialize = function(this, sTable)
        local oProtean 	= tProteans[this];
        local tData 	= deserialize.table(sTable);
        local eValue 	= ProteanValue
        local eMod 		= ProteanMod;
        local eLimit	= ProteanLimit;

        oProtean[eValue.Base] 					= tData[eValue.Base];
        oProtean[eMod.BaseBonus] 				= tData[eMod.BaseBonus];
        oProtean[eMod.BasePenalty] 				= tData[eMod.BasePenalty];
        oProtean[eMod.MultiplicativeBonus] 		= tData[eMod.MultiplicativeBonus];
        oProtean[eMod.MultiplicativePenalty] 	= tData[eMod.MultiplicativePenalty];
        oProtean[eMod.AddativeBonus] 			= tData[eMod.AddativeBonus];
        oProtean[eMod.AddativePenalty]			= tData[eMod.AddativePenalty];
        oProtean[eValue.Final]					= tData[eValue.Final];
        oProtean[eLimit.Min]					= tData[eLimit.Min];
        oProtean[eLimit.Max] 					= tData[eLimit.Max];
        oProtean.isLinked						= tData.isLinked;
        oProtean.linkerID						= tData.linkerID;
        oProtean.autoCalculate					= tData.autoCalculate;
        oProtean.onChange						= tData.onChange;
        oProtean.isCallbackActive 				= tData.isCallbackActive;

        --relink this object if it was before
        if (oProtean.isLinked) then
            link(this, tData.linkerID);
        end

    end,
},
{--PRIVATE
    limitMin                = false,
    limitMax                = false,
    linkerID			    = -1,
    isLinked			    = false, --for fast queries
    autoCalculate		    = true,
    onChange                = onChangePlaceHolder,
    isCallbackActive        = false,
    isCallbackLocked        = false,
    isCallbackToggleLocked  = false,
    values = {
        [_nValueBase]       = 0,
        [_nValueFinal]      = 0, --this is (re)calcualted whenever another item is changed
        [_nBaseBonus]       = 0,
        [_nBasePenalty]     = 0,
        [_nMultBonus]       = 0,
        [_nMultPenalty]     = 0,
        [_nAddBonus]	    = 0,
        [_nAddPenalty]      = 0,
        [_nLimitMin] 	    = 0,
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
    @param fonChange function/nil If the (optional) input is a function, this will be called whenever a change is made to this object (unless callback is inactive).
    <br>Note: the callback function must accept the following paramters:
    <ol>
        <li>The Protean object. <em>(Protean)</em>.</li>
        <li>The value type. <em>(number)</em></li>
        <li>The previous value. <em>(number)</em></li>
        <li>The changed value. <em>(number)</em></li>
        <li>The final value. <em>(number)</em></li>
    </ol>
    @param bDoNotAutoCalculate Whether or not this object should auto-calculate the final value whenever a change is made. This is true by default. If set to nil, it will default to true.
    @return oProtean Protean A Protean object.
    !]]
    Protean = function(this, cdat, nBaseValue,  nBaseBonus,             nBasePenalty,
                                                nMultiplicativeBonus,   nMultiplicativePenalty,
                                                nAddativeBonus,         nAddativePenalty,
                                                nMinLimit,              nMaxLimit,
                                                fonChange,              bDontAutoCalculate)

        local pri       = cdat.pri;
        local tValues   = pri.values;
        local bHasCallbackFunction  = rawtype(fonChange) == "function";
        pri.limitMin = rawtype(nMinLimit) == "number";
        pri.limitMax = rawtype(nMaxLimit) == "number";

        --local eLimit    = Protean.LIMIT;
        --local eMod      = Protean.MOD;
        --local eValue    = Protean.VALUE;

        tValues[_nValueBase]	= rawtype(nBaseValue) 				== "number" 	and nBaseValue 				or 0;
        tValues[_nBaseBonus] 	= rawtype(nBaseBonus) 				== "number"		and nBaseBonus  			or 0;
        tValues[_nBasePenalty]  = rawtype(nBasePenalty) 			== "number"		and nBasePenalty 			or 0;
        tValues[_nMultBonus] 	= rawtype(nMultiplicativeBonus) 	== "number"		and nMultiplicativeBonus 	or 0;
        tValues[_nMultPenalty]  = rawtype(nMultiplicativePenalty) 	== "number"		and nMultiplicativePenalty 	or 0;
        tValues[_nAddBonus] 	= rawtype(nAddativeBonus) 			== "number"		and nAddativeBonus 			or 0;
        tValues[_nAddPenalty]	= rawtype(nAddativePenalty) 		== "number"		and nAddativePenalty 		or 0;
        tValues[_nLimitMin] 	= pri.limitMin                                      and nMinLimit               or -math.huge;
        tValues[_nLimitMax] 	= pri.limitMax                                      and nMaxLimit               or math.huge;
        tValues[_nValueFinal]	= 0; --this is (re)calcualted whenever another item is changed
        pri.autoCalculate		= not (rawtype(bDontAutoCalculate) == "boolean"     and bDontAutoCalculate      or false);
        pri.onChange 			= bHasCallbackFunction						 		and fonChange				or onChangePlaceHolder;
        pri.isCallbackActive    = bHasCallbackFunction;

        --calculate the final value for the first time
        calculateFinalValue(this, cdat);
    end,
    --[[!
    @fqxn LuaEx.Classes.Protean.Methods.adjust
    @desc Adjusts the given value by the amount input. Note: if using an external table which contains the base value, and the rawtype provided is ProteanValue.Base, nil will be returned. An external base value cannot be adjusted from inside the Protean	object (although the base bonus and base penalty may be).
    @note If only one parameter is given, it is assumed that the base value is intended to be adjusted using the value input.
    @param nType number The type of value to adjust.
    @param nValue number The value by which to adjust the given value.
    @return oProtean Protean This Protean object.
    !]]
    adjustValue = function(this, cdat, nType, nValue)
        local pri = cdat.pri;

        if not (rawtype(nType) == "number") then
            error("Error adjusting Protean value.\nValue category type expected: number. Type given: "..rawtype(nType));
        end

        if (nType < _nIndexMin or nType > _nIndexMax or nType == _nValueFinal) then
            error("Error setting Protean value.\nValue category out of range.");
        end

        if (sValueType == "nil") then
            nValue  = nType;
            nType   = _nValueBase;
        end

        if not (rawtype(nValue) == "number") then
            error("Error adjusting Protean value.\nNew value must be of type number. Type given: "..rawtype(nValue));
        end

        setValue(this, cdat, nType, pri.values[nType] + nValue);
        return this;
    end,

    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.calculateFinalValue
        @desc Calculates the final value of the Protean. This is done on-change by default so that the final value (when requested) is always up-to-date and accurate. There is no need to call this unless auto-calculate has been disabled. In that case, this serves an external utility function to perform the normally-internal operation of calculating and updating the final value.
        @return nValue number The calculated final value.
    !]]
    calulateFinalValue = function(this, cdat)
        calculateFinalValue(this, cdat);
        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.get
        @desc Gets the value of the given value type. Note: if the type provided is ProteanValue.Final and MIN or MAX limits have been set, the returned value will fall within the confines of those paramter(s).
        @note If no parameter is given, the base value is returned.
        @param nType number The type of value to adjust.
        @return nValue number The value of the given type.
    !]]
    getValue = function(this, cdat, nType)
        local pri   = cdat.pri;
        local sType = rawtype(nType);

        if (sType == "nil") then
            nType = _nValueFinal;
            sType = "number";
        end

        if not (sType == "number") then
            error("Error getting Protean value.\nValue category type expected: number. Type given: "..rawtype(nType));
        end

        if (nType < _nIndexMin or nType > _nIndexMax) then
            error("Error getting Protean value.\nValue category out of range.");
        end

        if (nType == _nValueBase) then
            nRet = pri.isLinked and tLinkers[pri.linkerID].baseValue or pri.values[_nValueBase];
        else
            nRet = pri.values[nType];
        end

        return nRet;
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

    lockCallback = function(this, cdat)
        cdat.pri.isCallbackLocked = true;
    end,

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
        tProteans[this].autoCalculate = rawtype(bFlag) == "boolean" and bFlag or false;
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

        if (rawtype(fCallback) == "function") then
            pri.onChange 			= fCallback;
            pri.isCallbackActive 	= not (rawtype(bDoNotSetActive) == "boolean" and bDoNotSetActive or false);

        else
            pri.onChange 			= nil;
            pri.isCallbackActive	= false;
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
        cdat.pri.limitMax = rawtype(bFlag) == "boolean" and bFlag or false;
        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Protean.Methods.setLimitMin
        @desc Tells the Protean whether to enable the minimum limiter.
        @param bLimit boolean|nil If true, will enable the limiter, if not, it will disable it.
        @return oProtean Protean This Protean object.
    !]]
    setLimitMin = function(this, cdat, bFlag)
        cdat.pri.limitMin = rawtype(bFlag) == "boolean" and bFlag or false;
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

        if not (rawtype(nType) == "number") then
            error("Error setting Protean value.\nValue category type expected: number. Type given: "..rawtype(nType));
        end

        local sValueType = rawtype(nValue);

        if (sValueType == "nil") then
            nValue  = nType;
            nType   = _nValueBase;
        end

        if (nType < _nIndexMin or nType > _nIndexMax or nType == _nValueFinal) then
            error("Error setting Protean value.\nValue category out of range.");
        end

        if not (rawtype(nValue) == "number") then
            error("Error setting Protean value.\nNew value must be of type number. Type given: "..rawtype(nValue));
        end

        setValue(this, cdat, nType, nValue);
        return this;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
