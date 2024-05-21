--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
	<h2>pot</h2>
	<p>A logical potentiometer object. The client can set minimum and maximum values for the object, as well as rate of increase/decrease.
	Note: 'increase' and 'decrease' are logical terms referring to motion along a line based on the current direction. E.g., If a pot is
	alternating and descening, 'increase' would cause the positional value to be absolutely reduced, while 'decrease' would have the opposite
	affect.
	By default, values are clamped at min and max; however, if the object is set to be revolving (or alternating), any values which exceed the minimum or maximum
	boundaries, are carried over. For example, imagine a pot is set to have a min value of 0 and a max of 100. Then, imagine its position is set to 120.
	If revolving, it would have a final positional value of 19; if alternating it would have a final positional value of 80 and, if neither, its final positional
	value would be 100.</p>
@license <p>The Unlicense<br>
<br>
@moduleid pot
@version 1.2
@versionhistory
<ul>
    <li>
        <b>1.5</b>
        <br>
        <p>Change: updated to be compatible with new LuaEx class system.</p>
    </li>
	<li>
		<b>1.4</b>
		<br>
		<p>Bugfix: clamping values was not working correctly cause unpredictable results.</p>
	</li>
	<li>
		<b>1.3</b>
		<br>
		<p>Added serialization and deserialization methods.</p>
	</li>
	<li>
		<b>1.2</b>
		<br>
		<p>Fixed a bug in the revolution mechanism.</p>
		<p>Added the ability which allows the potentiometer to be continuous in a revolving or alternating manner.</p>
	</li>
	<li>
		<b>1.1</b>
		<br>
		<p>Added the option for the potentiometer to be continuous in a revolving manner.</p>
	</li>
	<li>
		<b>1.0</b>
		<br>
		<p>Created the module.</p>
	</li>
</ul>
@website https://github.com/CentauriSoldier
*]]

--the default values in case constructor input is bad
local nMinDefault 	= 0;
local nMaxDefault 	= 99;
local nRateDefault 	= 1;

--make these publicy available
constant("POT_CONTINUITY_NONE", 	0);
constant("POT_CONTINUITY_REVOLVE", 	1);
constant("POT_CONTINUITY_ALT", 		2);

--now localize them
local POT_CONTINUITY_NONE 		= POT_CONTINUITY_NONE;
local POT_CONTINUITY_REVOLVE 	= POT_CONTINUITY_REVOLVE;
local POT_CONTINUITY_ALT 		= POT_CONTINUITY_ALT;

--TODO localize more stuff
local class 					= class;
local serialize 				= serialize;
local deserialize 				= deserialize;
local math 						= math;


local function continuityIsValid(nVal)

	return rawtype(nVal) == "number" and
		   (nVal == POT_CONTINUITY_NONE 	or
		    nVal == POT_CONTINUITY_REVOLVE 	or
			nVal == POT_CONTINUITY_ALT);
end


local function clampMin(pri)

	if (pri.min >= pri.max) then
		pri.min = pri.max - 1;
	end

end

local function clampMax(pri)

	if (pri.max <= pri.min) then
		pri.max = pri.min + 1;
	end

end

--this is a placeholder so clampPosMin can call clampPosMax
local function clampPosMax()end --TODO does it need to be a function at fiorst? how about null?

local function clampPosMin(pri)

	if (pri.pos < pri.min) then

		if (pri.continuity == POT_CONTINUITY_REVOLVE) then
			pri.pos = pri.min + math.abs(pri.max - math.abs(-pri.pos + 1));
			clampPosMin(pri);

		elseif (pri.continuity == POT_CONTINUITY_ALT) then
			pri.pos = pri.min + (pri.min - pri.pos);
			pri.toggleAlternator = true;
			clampPosMax(pri);

		else
			pri.pos = pri.min;

		end

	else

		--check if the alternator needs toggled
		if (pri.toggleAlternator) then
			pri.alternator = pri.alternator * -1;
			pri.toggleAlternator = false;
		end

	end

end

local function clampPosMax(pri)

	if (pri.pos > pri.max) then

		if (pri.continuity == POT_CONTINUITY_REVOLVE) then
			pri.pos = pri.pos - math.abs(pri.max - pri.min + 1);
			clampPosMax(pri);

		elseif (pri.continuity == POT_CONTINUITY_ALT) then
			pri.pos = pri.max - (pri.pos - pri.max);
			pri.toggleAlternator = true;
			clampPosMin(pri);

		else
			pri.pos = pri.max;

		end

	else

		--check if the alternator needs toggled
		if (pri.toggleAlternator) then
			pri.alternator = pri.alternator * -1;
			pri.toggleAlternator = false;
		end

	end

end

local function clampRate(pri)
	local nVariance = pri.max - pri.min;

	if (math.abs(pri.rate) > math.abs(nVariance)) then
		pri.rate = nVariance;
	end

end


local function udpateStatus(pri)
	pri.isAtStart = pos == min;
	pri.isAtEnd 	= pos == max;
end


return class("potentiometer",
{--metamethods

},
{--static public

},
{--private
    alternator			= 1,
    continuity			= POT_CONTINUITY_NONE,
    isAtStart			= false,
    isAtEnd				= false,
    min 				= 0,
    max 				= 1,
    pos 				= 0,
    toggleAlternator 	= false,
    rate 				= 1,
},
{--protected

},
{--public
    potentiometer = function(this, cdat, nMin, nMax, nPos, nRate, nContinuity)
        local pri = cdat.pri;

        pri.alternator			= 1;
        pri.continuity			= continuityIsValid(nContinuity) and nContinuity or POT_CONTINUITY_NONE;
        pri.isAtStart			= false;
        pri.isAtEnd				= false;
        pri.min 				= rawtype(nMin) == "number" and nMin or nMinDefault;
        pri.max 				= rawtype(nMax) == "number" and nMax or nMaxDefault;
        pri.pos 				= rawtype(nPos) == "number" and nPos or nMinDefault;
        pri.toggleAlternator 	= false;
        pri.rate 				= rawtype(nRate) == "number" and nRate or nRateDefault;

        clampPosMin(pri);
		clampPosMax(pri);
		clampRate(pri);
		udpateStatus(pri);
    end,


    adjust = function(this, cdat, nValue)
		local pri = cdat.pri;
		local nAmount = pri.rate;

		--allow correct input
		if (rawtype(nValue) == "number") then
			nAmount = nValue;
		end

		--set the value
		pri.pos = pri.pos + nAmount;

		--clamp it
		clampPosMin(pri);
		clampPosMax(pri);
		udpateStatus(pri);

		return this;
	end,


    decrease = function(this, cdat, nTimes)
        local pri = cdat.pri;
		local nCount = 1;

		if (rawtype(nTimes) == "number") then
			nCount = nTimes;
		end

		--set the value
		pri.pos = pri.pos - pri.rate * nCount * pri.alternator;

		--clamp it
		if (pri.continuity == POT_CONTINUITY_ALT) then
			clampPosMax(pri);
		end

		clampPosMin(pri);
		udpateStatus(pri);

		return this;
	end,


    deserialize = function(this, cdat, sData)--TODO this is done with newly added items!
		local pri = cdat.pri;
		local tData = deserialize.table(sData);

		pri.alternator 		    = tData.alternator;
		pri.continuity 		    = tData.continuity;
		pri.min 				= tData.min;
		pri.max 				= tData.max;
		pri.pos 				= tData.pos;
		pri.toggleAlternator 	= tData.toggleAlternator;
		pri.rate 				= tData.rate;

		return this;
	end,


    getMax = function(this, cdat)
		return cdat.pri.max;
	end,


    getMin = function(this, cdat)
		return cdat.pri.min;
	end,


	getPos = function(this, cdat)
		return cdat.pri.pos;
	end,


	getRate = function(this, cdat)
		return cdat.pri.rate;
	end,


    getContinuity = function(this, cdat)
		return cdat.pri.continuity;
	end,


	increase = function(this, cdat, nTimes)
		local pri = cdat.pri;
		local nCount 	= rawtype(nTimes) == "number" and nTimes or 1;

		--set the value
		pri.pos = pri.pos + (pri.rate * nCount * pri.alternator);

		--clamp it
		if (pri.continuity == POT_CONTINUITY_ALT) then
			clampPosMin(pri);
		end

		clampPosMax(pri);
		udpateStatus(pri);

		return this;
	end,

    isAlternating = function(this, cdat)
		return cdat.pri.continuity == POT_CONTINUITY_ALT;
	end,

	isAscending = function(this, cdat)
		return (
			(cdat.pri.continuity == POT_CONTINUITY_REVOLVE or
		    cdat.pri.continuity 	== POT_CONTINUITY_ALT) and
	        cdat.pri.alternator 	== 1
		  );
	end,

	isAtStart = function(this, cdat)
		return cdat.pri.isAtStart;
	end,

	isAtEnd = function(this, cdat)
		return cdat.pri.isAtEnd;
	end,


	isDescending = function(this, cdat)
		return (
			(cdat.pri.continuity == POT_CONTINUITY_REVOLVE or
		    cdat.pri.continuity 	== POT_CONTINUITY_ALT) and
	        cdat.pri.alternator 	== -1
		  );
	end,


	isRevolving = function(this, cdat)
		return cdat.pri.revolving == POT_CONTINUITY_REVOLVE;
	end,

	--[[!
		@desc Serializes the object's data.
		@func pot.serialize
		@module pot
		@param bDefer boolean Whether or not to return a table of data to be serialized instead of a serialize string (if deferring serializtion to another object).
		@ret sData StringOrTable The data returned as a serialized table (string) or a table is the defer option is set to true.
	!]]
	serialize = function(this, cdat, bDefer)--TODO not done
		local pri = cdat.pri;
		local tData = {
			alternator			= pri.alternator,
			continuity			= pri.continuity,
			min 				= pri.min,
			max 				= pri.max,
			pos 				= pri.pos,
			toggleAlternator 	= pri.toggleAlternator,
			rate 				= pri.rate,
		};

		if (not bDefer) then
			tData = serialize.table(tData);
		end

		return tData;
	end,


	setMax = function(this, cdat, nValue)
		local pri = cdat.pri;

		if (rawtype(nValue) == "number") then
			pri.max = nValue;
			clampMax(pri);
			clampPosMax(pri);
			udpateStatus(pri);
		end

		return this;
	end,

	setMin = function(this, cdat, nValue)
		local pri = cdat.pri;

		if (rawtype(nValue) == "number") then
			pri.min = nValue;
			clampMin(pri);
			clampPosMin(pri);
			udpateStatus(pri);
		end

		return this;
	end,


	setPos = function(this, cdat, nValue)
		local pri = cdat.pri;

		if (rawtype(nValue) == "number") then
			pri.pos = nValue;
			clampPosMin(pri);
			clampPosMax(pri);
			udpateStatus(pri);
		end

		return this;
	end,


	setRate = function(this, cdat, nValue)
	    local pri = cdat.pri;

		if (rawtype(nValue) == "number") then
			pri.rate = math.abs(nValue);
			clampRate(pri);
		end

		return this;
	end,

	setContinuity = function(this, cdat, nContinuity)
		local pri = cdat.pri;
		pri.continuity = continuityIsValid(nContinuity) and nContinuity or pri.continuity;
		print("Continuity Set to :"..pri.continuity.." from input value of: "..nContinuity);
		return this;
	end,
},
nil,    --extending class
false,   --if the class is final
nil   --interface(s) (either nil, or interface(s))
);
