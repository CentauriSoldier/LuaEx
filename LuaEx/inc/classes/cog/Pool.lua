--TODO finish this. It needs to use a protean and be integer values only Zero or less  means it's empty

--[[*
	@moduleid pool
	@authors Centauri Soldier
	@copyright Copyright © 2020 Centauri Soldier
	@description <h2>pool</h2><h3>Utility class used to keep track of things like Health, Magic, etc.</h3><p>You can operate on <strong>pool</strong> objects using some math operators.</p>
	<ul>
		<li><p><b>+</b>: adds a number to the pool's CURRENT value or, if adding another pool object instead of a number, it will add the other pool's CURRENT value to it's own <em>(up to it's MAX)</em> value.</p></li>
		<li><p><b>-</b>: does the same as addition but for subtraction. Will not go below the pool's MIN value.</p></li>
		<li><p><b>%</b>: will modify a pool's MAX value using a number value or another pool object <em>(uses it's MAX value)</em>. Will not allow itself to be set at or below the MIN value.</p></li>
		<li><p><b>*</b>: operates as expected on the object's CURRENT value.</p></li>
		<li><p><b>/</b>: operates as expected on the object's CURRENT value. All div is floored.</p></li>
		<li><p><b>-</b><em>(unary minus)</em>: will set the object's CURRENT value to the value of MIN.</p></li>
		<li><p><b>#</b>: will set the object's CURRENT value to the value of MAX.</p></li>
		<li><p><b></b></p></li>
		<li><p><b></b></p></li>
	</ul>
	@version 0.2
	@todo Complete the binary operator metamethods.
	*]]

local type				= type;
local math				= math;
local counting 			= math.counting;
local whole 			= math.whole;
local floor 			= math.floor;

local _nValueBase     = Protean.VALUE_BASE;
local _nBaseBonus     = Protean.BASE_BONUS;
local _nBasePenalty   = Protean.BASE_PENALTY;
local _nMultBonus     = Protean.MULTIPLICATIVE_BONUS;
local _nMultPenalty   = Protean.MULTIPLICATIVE_PENALTY;
local _nAddBonus      = Protean.ADDATIVE_BONUS;
local _nAddPenalty    = Protean.ADDATIVE_PENALTY;
local _nLimitMax      = Protean.LIMIT_MAX;

--[[
local function clampRegen(this, cdat)
	local tFields 		= tPools[this];
	local tValues 		= tFields.values;
	local eRegen 	 	= PoolValue.Regen;

	tValues[eRegen] = math.floor(tValues[eRegen]);
end
]]


local function validateModifier(sIndex, sSetOrGet, nMod)

    if (rawtype(nMod) ~= "number") and
       (nMod == _nValueBase     or nMod == _nBaseBonus or
        nMod == _nBasePenalty   or nMod == _nMultBonus or
        nMod == _nMultPenalty   or nMod == _nAddBonus  or
        nMod == _nAddPenalty    or nMod == _nLimitMax) then

        error("Error "..sSetOrGet.."ting Pool "..sIndex.." modifier. Modifer value must be of type number and be one of the permitted Protean modifer values.");
    end

end


local function validateModifierAndValue(sIndex, sSetOrGet, nMod, nValue)

    if (rawtype(nMod) ~= "number") and
       (nMod == _nValueBase     or nMod == _nBaseBonus or
        nMod == _nBasePenalty   or nMod == _nMultBonus or
        nMod == _nMultPenalty   or nMod == _nAddBonus  or
        nMod == _nAddPenalty    or nMod == _nLimitMax) then

        error("Error "..sSetOrGet.."ting Pool "..sIndex.." modifier. Modifer value must be of type number and be one of the permitted Protean modifer values.");
    end

    if (rawtype(nValue) ~= "number") then
        error("Error "..sSetOrGet.."ting Pool "..sIndex.." modifier.\nValue must be of type number. Type given: "..type(nValue)..'.');
    end

end





local function clampMax(this, cdat)
	local tFields 		= tPools[this];
	local tValues 		= tFields.values;
	local eMax			= PoolValue.Max;
	local oMax 			= tValues[eMax];
	local nMax 			= counting(oMax:get(ProteanValue.Final));

	local nBaseAddative = 0;

	while (nMax <= tValues.Min) do
		--increase the addative
		nBaseAddative = nBaseAddative + 1;
		--set the new value
		oMax:set(ProteanValue.Base, nMax + nBaseAddative);
		--reget the final value (clamped to be a counting number)
		nMax = counting(oMax:get(ProteanValue.Final));
	end

end


local function clampCurrent(this, cdat)
	local tFields 		= tPools[this];
	local tValues 		= tFields.values;
	local eMax			= PoolValue.Max;
	local eCurrent  	= PoolValue.Current;
	local nMax 			= counting(tValues[eMax]:get(ProteanValue.Final));

	tValues[eCurrent] = tValues[eCurrent];

	if (tValues[eCurrent] > nMax) then
		tValues[eCurrent] = nMax;
	end

end

local function setValue(sIndex, nValue)
    local tFields 	= tPools[this];
    local tValues 	= tFields.values;
    local eBase		= ProteanValue.Base;

    if (type(eValue) == "PoolValue" and type(nValue) == "number") then
        local oProtean = tValues[eValue];

        if (eValue == PoolValue.Max) then
            oProtean:set(eBase, counting(nValue));
            clampMax(this, cdat);
            clampCurrent(this, cdat);

        elseif (eValue == PoolValue.Current) then
            oProtean:set(eBase, whole(nValue));
            clampCurrent(this, cdat);

        elseif (eValue == PoolValue.Regen) then
            oProtean:set(eBase, math.floor(nValue));
        end

    end

    return this;
end

local function setModifierValue(sIndex, nModifier, nValue)

end

local function eventPlaceholder() end



enum("PoolCallback", 	{"OnAdjust", "OnIncrease", "OnDecrease", "OnEmpty", "OnMin", "OnMax", "OnRegen"});

return class("Pool",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Pool = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    callbacks = {
        onAdjust    = eventPlaceholder,
        onIncrease  = eventPlaceholder,
        onDecrease  = eventPlaceholder,
        onEmpty     = eventPlaceholder,
        onFull      = eventPlaceholder,
        onRegen     = eventPlaceholder,
    },
    current = null,
    max     = null,
    regen   = null,
},
{--PUBLIC
    Pool = function(this, cdat, nMax, nCurrent, nRegen)
        local pro = cdat.pro;
        nCurrent	= type(nCurrent) 	== "number" and whole(nCurrent)     or 1;
        nMax        = type(nMax) 		== "number"	and counting(nMax)		or 1;
        nMax        = nMax < nCurrent               and nCurrent            or nMax;
		nRegen 	    = type(nRegen) 		== "number" and nRegen 		        or 0;

		--create the proteans
        pro.max     = Protean(nMax,     0, 0, 0, 0, 0, 0, 0, nil,   true, nil);
        pro.current = Protean(nCurrent, 0, 0, 0, 0, 0, 0, 0, nMax,  true, nil);
		pro.regen   = Protean(nRegen,   0, 0, 0, 0, 0, 0, 0, nMax,  true, nil);

		--clamp the values
		clampMax(this, cdat);
		clampCurrent(this, cdat);
    end,

    getCurrent = function(this, cdat)
        return cdat.pro.value.get();
    end,

    getCurrentModifier = function(this, cdat, nModifier)
        validateModifier("current", "get", nModifier);
        return cdat.pro.value.get(nModifier);
    end,

    getMax = function(this, cdat)
        return cdat.pro.max.get();
    end,

    getMaxModifier = function(this, cdat, nModifier)
        validateModifier("max", "get", nModifier);
        return cdat.pro.max.get(nModifier);
    end,

    getRegen = function(this, cdat)
        return cdat.pro.regen.get();
    end,

    getRegenModifier = function(this, cdat, nModifier)
        validateModifier("regen", "get", nModifier);
        return cdat.pro.regen.get(nModifier);
    end,

	isEmpty = function(this, cdat)
        local pro = cdat.pro;
		return pro.current.get() <= 0;
	end,

	isFull = function(this, cdat)
        local pro = cdat.pro;
		return pro.current.get() >= pro.max.get();
	end,

	regen = function(this, cdat)
		local pro 	   = cdat.pro;
		local oCurrent = pro.current;

		pro = tValues[eCurrent] + math.floor(tValues[eRegen]:get(eFinal));
		clampCurrent(this, cdat);
        --TODO check values and onEvents
		return this;
	end,

	setCurrent = function(this, cdat, nValue)
        if (rawtype(nValue) ~= "number") then
            error("Error setting current value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end
        --TODO
	end,

    setCurrentModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("current", "set", nModifier, nValue);
        setModifierValue("current", nModifier, nValue)
    end,

    setMax = function(this, cdat, nValue)
        if (rawtype(nValue) ~= "number") then
            error("Error setting max value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end
    end,

    setMaxModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("max", "set", nModifier, nValue)
        setModifierValue("regen", nModifier, nValue);
    end,

    setRegen = function(this, cdat, nValue)

        if (rawtype(nValue) ~= "number") then
            error("Error setting regen value.\nValue must be of type number. Type given: "..type(nValue)..'.');
        end

    end,

    setRegenModifier = function(this, cdat, nModifier, nValue)
        validateModifierAndValue("regen", "set", nModifier, nValue);
        setModifierValue("regen", nModifier, nValue);
    end,

	setCallback = function(this, cdat, eEvent, fCallback)

		if (eEvent and fCallback and type(eEvent) == 'PoolCallback' and type(fCallback) == 'function') then
			tPools[this].callbacks[eEvent] = fCallback;
		end

		return this;
	end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
