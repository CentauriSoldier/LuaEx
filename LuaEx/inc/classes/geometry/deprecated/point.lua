--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
	<h2>rectangle</h2>
	<p>This is a basic point class. Unlike many classes, it has no private members or properties. x and y will grant access to the respective values.</p>
@license <p>The Unlicense<br>
<br>
@moduleid rectangle
@version 1.1
@versionhistory
<ul>
	<li>
		<b>1.0</b>
		<br>
		<p>Created the module.</p>
	</li>
	<li>
		<b>1.1</b>
		<br>
		<p>Add serialize and deserialize methods.</p>
	</li>
</ul>
@website https://github.com/CentauriSoldier
*]]
constant("QUADRANT_I", 		"I");
constant("QUADRANT_II", 	"II");
constant("QUADRANT_III", 	"III");
constant("QUADRANT_IV",		"IV");
constant("QUADRANT_O", 		"O");
constant("QUADRANT_X",		"X");
constant("QUADRANT_X_NEG",	"-X");
constant("QUADRANT_Y", 		"Y");
constant("QUADRANT_Y_NEG",	"-Y");

--localization
local class 		= class;
local serialize		= serialize;
local deserialize	= deserialize;
local type 			= type;
local rawtype		= rawtype;
local math			= math;

local point = class "point" {

	--[[
	@desc This is the constructor for the point class.
	@func point The constructor for the point class.
	@mod point
	@param nX number The x value. If nil, it defaults to 0.
	@param nY number The y value. If nil, it defaults to 0.
	]]
	__construct = function(this, _ignore_, nX, nY)
		this.x = rawtype(nX) == "number" and nX or 0;
		this.y = rawtype(nY) == "number" and nY or 0;
	end,

	--[[
	@desc Adds two points together.
	@func __add
	@mod point
	@ret oPoint point A new point with the values of the two points added together. If an incorrect paramters is passed, a new point with the values of the correct paramter (the point) is returned.
	]]
	__add = function(this, vRight)

		if (type(this) == "point" and type(vRight) == "point") then
			return point(this.x + vRight.x,
						 this.y + vRight.y);
		end


	end,

	--[[__div = function(this, vRight)
		local sType = type(vRight);

		if (sType == "point") then
			this.x = this.x / vRight.x;
			this.y = this.y + vRight.y;
		--elseif (sType == "table") then

		end

		return this;
	end,
]]
	__eq = function(this, vRight)
		return type(vRight) == "point" and this.x == vRight.x and this.y == vRight.y;
	end,

	__le = function(this, vRight)
		return type(vRight) == "point" and this.x <= vRight.x and this.y <= vRight.y;
	end,


	__lt = function(this, vRight)
		return type(vRight) == "point" and this.x < vRight.x and this.y < vRight.y;
	end,


	--[[__mul = function(this, vRight)
		local sType = type(vRight);

		if (sType == "point") then
			this.x = this.x + vRight.x;
			this.y = this.y + vRight.y;
		--elseif (sType == "table") then

		end

		return this;
	end,]]


	__sub = function(this, vRight)
		local sType = type(vRight);

		if (sType == "point") then
			return point(this.x - vRight.x,
						 this.y - vRight.y);
		end

	end,

	__tostring = function(this)
		return "x: "..this.x.." y: "..this.y;
	end,

	deserialize = function(this, sData)
		local tData = deserialize.table(sData);

		this.x = tData.x;
		this.y = tData.y;

		return this;
	end,

	clone = function(this)
		return point(this.x, this.y);
	end,

	--return O, X, Y, -X, -Y, I, II, III or IV
	getQuadrant = function(this)
		local sRet 		= "ERROR";
		local bYIsNeg 	= this.y < 0;
		local bYIs0 	= this.y == 0;
		local bYIsPos 	= this.y > 0;--not bYIsNeg and not bYIs0;

		if (this.x < 0) then

			if (bYIsNeg) then
				sRet = "III";
			elseif (bYIs0) then
				sRet = "-X";
			elseif (bYIsPos) then
				sRet = "II";
			end

		elseif (this.x == 0) then

			if (bYIsNeg) then
				sRet = "-Y";
			elseif (bYIs0) then
				sRet = "O";
			elseif (bYIsPos) then
				sRet = "Y";
			end

		elseif (this.x > 0) then

			if (bYIsNeg) then
				sRet = "IV";
			elseif (bYIs0) then
				sRet = "X";
			elseif (bYIsPos) then
				sRet = "I";
			end

		end

		return sRet;
	end,

	--[[deprecated...this is a line function
	distanceTo = function(this, oOther)
		local nRet = 0;

		if (type(this) == "point" and type(oOther) == "point") then
			nRet = math.sqrt( (this.x - oOther.x) ^ 2 + (this.y - oOther.y) ^ 2);
		end

		return nRet;
	end,
	]]

	--[[!
		@desc Serializes the object's data.
		@func point.serialize
		@module point
		@param bDefer boolean Whether or not to return a table of data to be serialized instead of a serialize string (if deferring serializtion to another object).
		@ret sData StringOrTable The data returned as a serialized table (string) or a table is the defer option is set to true.
	!]]
	serialize = function(this, bDefer)
		local tData = {
			x = this.x,
			y = this.y,
		};

		if (not bDefer) then
			tData = serialize.table(tData);
		end

		return tData;
	end,

	--[[deprecated...this is a line function
	slopeTo = function(this, oOther)
		local nRet = 0;

		if (type(this) == "point" and type(oOther) == "point") then
			nXDelta = this.x - oOther.x;
			nYDelta = this.y - oOther.y;

			if (nYDelta == 0) then
				nRet = MATH_UNDEF;
			else
				nRet = math.atan(nYDelta / nXDelta);
				--nRet = nYDelta / nXDelta;
			end

		end

		return nRet;
	end,]]
};

return point;
