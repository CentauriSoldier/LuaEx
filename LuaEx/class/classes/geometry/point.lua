--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
	<h2>point</h2>
	<p>This is a basic point class.</p>
@license <p>The Unlicense<br>
<br>
@moduleid point
@version 1.2
@versionhistory
<ul>
	<li>
		<b>1.2</b>
		<br>
		<p>Updated to work with new LuaEx class system.</p>
	</li>
	<li>
		<b>1.1</b>
		<br>
		<p>Add serialize and deserialize methods.</p>
	</li>
	<li>
		<b>1.0</b>
		<br>
		<p>Created the module.</p>
	</li>
</ul>
@website https://github.com/CentauriSoldier
*]]

local nSpro	= class.args.staticprotected;
local nPri 	= class.args.private;
local nPro 	= class.args.protected;
local nPub 	= class.args.public;
local nIns	= class.args.instances;

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

local point = class(
"point",
{--metamethods
	--[[
	@desc Adds two points together.
	@func __add
	@mod point
	@ret oPoint point A new point with the values of the two points added together. If an incorrect paramters is passed, a new point with the values of the correct paramter (the point) is returned.
	]]
	__add = function(args, this, other)

		if (type(this) == "point" and type(other) == "point") then
			local pri = args[nPri];
			local otherpri = args[nIns][other][nPri];

			return point(pri.x + otherpri.x,
						 pri.y + otherpri.y);
		end

	end,

	__eq = function(args, this, other)
		local bRet = false;

		if (type(this) == "point" and type(other) == "point") then
			local pri = args[nPri];
			local otherpri = args[nIns][other][nPri];
			bRet = pri.x == otherpri.x and pri.y == otherpri.y;
	 	end

		return bRet;
	end,

	__le = function(args, this, other)
		local bRet = false;

		if (type(this) == "point" and type(other) == "point") then
			local pri = args[nPri];
			local otherpri = args[nIns][other][nPri];
			bRet = pri.x <= otherpri.x and pri.y <= otherpri.y;
	 	end

		return bRet;
	end,

	__lt = function(args, this, other)
		local bRet = false;

		if (type(this) == "point" and type(other) == "point") then
			local pri = args[nPri];
			local otherpri = args[nIns][other][nPri];
			bRet = pri.x < otherpri.x and pri.y < otherpri.y;
	 	end

		return bRet;
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

	__sub = function(args, this, other)

		if (type(this) == "point" and type(other) == "point") then
			local pri = args[nPri];
			local otherpri = args[nIns][other][nPri];

			return point(pri.x - otherpri.x,
						 pri.y - otherpri.y);
		end

	end,

	__tostring = function(args, this)
		local pri = args[nPri];
		return "x: "..pri.x.." y: "..pri.y;
	end,
},
{--static protected

},
{--static public

},
{--private
	x,
	y,
},
{--protected

},
{--public
	--[[
	@desc This is the constructor for the point class.
	@func point The constructor for the point class.
	@mod point
	@param nX number The x value. If nil, it defaults to 0.
	@param nY number The y value. If nil, it defaults to 0.
	]]

	point = function(this, args, nX, nY)
		local pri = args[nPri];
		pri.x = rawtype(nX) == "number" and nX or 0;
		pri.y = rawtype(nY) == "number" and nY or 0;
	end,

	deserialize = function(this, sData)
		local tData = deserialize.table(sData);

		this.x = tData.x;
		this.y = tData.y;

		return this;
	end,

	clone = function(this, args)
		local pri = args[nPri];
		return point(pri.x, pri.y);
	end,

	getX = function(this, args)
		local pri = args[nPri];
		return pri.x;
	end,

	getY = function(this, args)
		local pri = args[nPri];
		return pri.y;
	end,

	--return O, X, Y, -X, -Y, I, II, III or IV
	getQuadrant = function(this, args)
		local pri = args[nPri];
		local sRet 		= "ERROR";
		local bYIsNeg 	= pri.y < 0;
		local bYIs0 	= pri.y == 0;
		local bYIsPos 	= pri.y > 0;--not bYIsNeg and not bYIs0;

		if (pri.x < 0) then

			if (bYIsNeg) then
				sRet = "III";
			elseif (bYIs0) then
				sRet = "-X";
			elseif (bYIsPos) then
				sRet = "II";
			end

		elseif (pri.x == 0) then

			if (bYIsNeg) then
				sRet = "-Y";
			elseif (bYIs0) then
				sRet = "O";
			elseif (bYIsPos) then
				sRet = "Y";
			end

		elseif (pri.x > 0) then

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
	serialize = function(this, args, bDefer)
		local pri = args[nPri];

		local tData = {
			x = pri.x,
			y = pri.y,
		};

		if (not bDefer) then
			tData = serialize.table(tData);
		end

		return tData;
	end,


	setX = function(this, args, nX)
		local pri = args[nPri];
		pri.x = type(nX) == "number" and nX or pri.x;
		return this;
	end,

	setY = function(this, args, nY)
		local pri = args[nPri];
		pri.y = type(nY) == "number" and nY or pri.y;
		return this;
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
},
nil,    --extending class
nil,    --interface(s) (either nil, an interface or a table of interfaces)
false  --if the class is final
);

return point;
