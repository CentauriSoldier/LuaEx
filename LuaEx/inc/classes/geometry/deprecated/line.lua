--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
	<h2>line</h2>
	<p></p>
@license <p>The Unlicense<br>
<br>
@moduleid line
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

--localization
local class 		= class;
local deserialize	= deserialize;
local math			= math;
local point 		= point;
local rawtype		= rawtype;
local serialize		= serialize;
local type 			= type;
local MATH_ARL		= MATH_ARL;
local MATH_UNDEF	= MATH_UNDEF;

--a location for storing temporary points so they don't need to be created every calcualtion
local tTempPoints = {};

local tProtectedRepo = {};

local function update(this)
	local tProt = tProtectedRepo[this];
	--update the line's midpoint
	tProt.midpoint.x = (tProt.start.x + tProt.stop.x) / 2;
	tProt.midpoint.y = (tProt.start.y + tProt.stop.y) / 2;

	--update the line's slope, theta and y intercept
	local nYDelta = tProt.stop.y - tProt.start.y;
	local nXDelta = tProt.stop.x - tProt.start.x;
	tProt.slopeIsUndefined = nXDelta == 0;

	--get the quadrant addative for theta
	local nXIsPos	= nXDelta > 0;
	local nYIsPos	= nYDelta > 0;

	--determine slope and y-intercept
	if (tProt.slopeIsUndefined) then
		tProt.slope 		= MATH_UNDEF;
		tProt.yIntercept 	= tProt.start.x == 0 and MATH_ARL or MATH_UNDEF;
	else
		tProt.slope 		= nYDelta / nXDelta;
		tProt.yIntercept 	= tProt.start.y - tProt.slope * tProt.start.x;
	end

	--translate end point to the origin (using the object's temp point) in order to find theta
	local oEnd = tTempPoints[this];

	oEnd.x = tProt.stop.x - tProt.start.x;
	oEnd.y = tProt.stop.y - tProt.start.y;

	tProt.theta = math.deg(math.atan2(oEnd.y, oEnd.x));
	--make sure the value is positive
	tProt.theta = tProt.theta >= 0 and tProt.theta or 360 + tProt.theta;

	--get the standard-form components and set the x intercept
	tProt.a = nYDelta;--tProt.stop.y - tProt.start.y;
	tProt.b = tProt.start.x - tProt.stop.x;
	tProt.c = tProt.a * tProt.start.x + tProt.b * tProt.start.y;

	--y = mx + b => 0 = mx + b => -b = mx => x = -b/m
	tProt.xIntercept = tProt.slopeIsUndefined and tProt.start.x or (tProt.slope == 0 and MATH_UNDEF or -tProt.yIntercept / tProt.slope);


	--update whether or not the intercepts are defined
	tProt.xInterceptIsUndefined = rawtype(tProt.xIntercept) == "string";
	tProt.yInterceptIsUndefined = rawtype(tProt.yIntercept) == "string";

	--update the deltas
	tProt.deltaX = nXDelta;
	tProt.deltaY = nYDelta;

	--update the line's length
	tProt.length = math.sqrt( (tProt.start.x - tProt.stop.x) ^ 2 + (tProt.start.y - tProt.stop.y) ^ 2);
end

return class "line" {

	__construct = function(this, tProtected, oStartPoint, oEndPoint, bSkipUpdate)
		tProtectedRepo[this] = tProtected;
		local tProt = tProtectedRepo[this];

		tProt.midpoint  = point();
		tProt.start = type(oStartPoint) == "point" 	and point(oStartPoint.x, 	oStartPoint.y) 	or point();
		tProt.stop 	= type(oEndPoint)	== "point" 	and point(oEndPoint.x, 		oEndPoint.y) 	or point();

		--default the fields (in case no update is performed)
		tProt.a 					= 0;
		tProt.b 					= 0;
		tProt.c 					= 0;
		tProt.deltaX 				= 0;
		tProt.deltaY 				= 0;
		tProt.length 				= 0;
		tProt.slope 				= 0;
		tProt.slopeIsUndefined 		= true;
		tProt.theta 				= 0;
		tProt.yIntercept 			= 0;
		tProt.yInterceptIsUndefined = true;
		tProt.xIntercept 			= 0;
		tProt.xInterceptIsUndefined = true;
		--tProt. = 0;

		--create this line's temp point (used during updates)
		tTempPoints[this] = point(0, 0);

		if (not bSkipUpdate) then
			update(this);
		end

	end,

	__tostring = function(this)
		local tProt = tProtectedRepo[this];
		local sRet 	= "";

		sRet = sRet.."start: "..tostring(tProt.start).."\r\n";
		sRet = sRet.."end: "..tostring(tProt.stop).."\r\n";
		sRet = sRet.."midpoint: "..tostring(tProt.midpoint).."\r\n";
		sRet = sRet.."slope: "..tProt.slope.."\r\n";
		sRet = sRet.."theta: "..tProt.theta.."\r\n";
		sRet = sRet.."delta x: "..tProt.deltaX.."\r\n";
		sRet = sRet.."delta y: "..tProt.deltaY.."\r\n";
		sRet = sRet.."length: "..tProt.length.."\r\n";
		sRet = sRet.."x intercept: "..tProt.xIntercept.."\r\n";
		sRet = sRet.."y intercept: "..tProt.yIntercept.."\r\n";
		sRet = sRet.."A: "..tProt.a.."\r\n";
		sRet = sRet.."B: "..tProt.b.."\r\n";
		sRet = sRet.."C: "..tProt.c.."\r\n";
		sRet = sRet.."Vector: <"..tProt.a..", "..tProt.b..">";

		return sRet;
	end,


	__len = function(this)
		return tProtectedRepo[this].length;
	end,


	__eq = function(this, oOther)
		local tMe 		= tProtectedRepo[this];
		local tOther 	= tProtectedRepo[oOther];
		return tMe.start.x 	== tOther.start.x 	and tMe.start.y == tOther.start.y and
			   tMe.stop.x 	== tOther.stop.x 	and tMe.stop.y 	== tOther.stop.y;
	end,


	deserialize = function(this, sData)
		local tData = deserialize.table(sData);

		this.start 	= this.start:deserialize(tData.start);
		this.stop	= this.stop:deserialize(tData.stop);
		error("UDPATE THIS FUNCTION")
		return this;
	end,


	getASCII = function(this)
		--TODO shrink the line to proportions of 10s
		local sRet = "";


		return sRet;
	end,

	--TODO finish this! Check if it's accurate
	--[[getObtuseAngleTo = function(this, oOther)
		local tMe 		= tProtectedRepo[this];
		local tOther 	= tProtectedRepo[oOther];

		local nAngle = math.abs(tMe.theta - tOther.theta);
		return nAngle <= 90 and nAngle or 90 + nAngle;
	end,


	getAcuteAngleTo = function(this, oOther)
		local tMe 		= tProtectedRepo[this];
		local tOther 	= tProtectedRepo[oOther];

		local nAngle = math.abs(tMe.theta - tOther.theta);
		return nAngle < 90 and nAngle or 180 - nAngle;
	end,]]

	getDeltaX = function(this)
		return tProtectedRepo[this].deltaX;
	end,

	getDeltaY = function(this)
		return tProtectedRepo[this].deltaY;
	end,

	getEnd = function(this)
		return tProtectedRepo[this].stop;
	end,

	getLength = function(this)
		return tProtectedRepo[this].length;
	end,

	getMidPoint = function(this)
		return tProtectedRepo[this].midpoint;
	end,

	getPointAtDistance = function(this, nDistance)
		--https://stackoverflow.com/questions/1250419/finding-points-on-a-line-with-a-given-distance
	end,

	getPointOfIntersection = function(this, oOther)
		local tMe 		= tProtectedRepo[this];
		local tOther 	= tProtectedRepo[oOther];
		local oRet		= MATH_UNDEF;

		local A1 = tMe.stop.y - tMe.start.y;
		local B1 = tMe.start.x - tMe.stop.x;
		local C1 = A1 * tMe.start.x + B1 * tMe.start.y;

		local A2 = tOther.stop.y - tOther.start.y;
		local B2 = tOther.start.x - tOther.stop.x;
		local C2 = A2 * tOther.start.x + B2 * tOther.start.y;

		local nDeterminate = (A1 * B2 - A2 * B1);

		if (nDeterminate ~= 0) then
			local x = (B2 * C1 - B1 * C2) / nDeterminate;
			local y = (A1 * C2 - A2 * C1) / nDeterminate;

			oRet = point(x, y);
		end

		return oRet;
	end,

	--get the polar radius
	getR = function(this)
		return tProtectedRepo[this].length;
	end,

	getSlope = function(this)
		return tProtectedRepo[this].slope;
	end,


	getStart = function(this)
		return tProtectedRepo[this].start;
	end,

	--get the polar angles from the x-axis
	getTheta = function(this)
		return tProtectedRepo[this].theta;
	end,


	getXIntercept = function(this)
		return tProtectedRepo[this].xIntercept;
	end,

	getYIntercept = function(this)
		return tProtectedRepo[this].yIntercept;
	end,

	intersects = function(this, oOther)
		local tMe 		= tProtectedRepo[this];
		local tOther 	= tProtectedRepo[oOther];

		local A1 = tMe.stop.y - tMe.start.y;
		local B1 = tMe.start.x - tMe.stop.x;

		local A2 = tOther.stop.y - tOther.start.y;
		local B2 = tOther.start.x - tOther.stop.x;

		return (A1 * B2 - A2 * B1) ~= 0;
	end,

	isDistinctFrom = function(this, oOther)

	end,

	isParrallelTo = function(this, oOther)
		local tMe 		= tProtectedRepo[this];
		local tOther 	= tProtectedRepo[oOther];
		local bBothSlopesAreDefined 	= (not tMe.slopeIsUndefined) and (not tOther.slopeIsUndefined);
		local bBothSlopesAreUndefined 	= tMe.slopeIsUndefined and tOther.slopeIsUndefined;

		return bBothSlopesAreUndefined or (bBothSlopesAreDefined and (tMe.slope == tOther.slope));
	end,

	coincidesWith = function(this, oOther)
		local tMe 							= tProtectedRepo[this];
		local tOther 						= tProtectedRepo[oOther];
		local bBothSlopesAreDefined 		= (not tMe.slopeIsUndefined) and (not tOther.slopeIsUndefined);
		local bBothSlopesAreUndefined 		= tMe.slopeIsUndefined and tOther.slopeIsUndefined;
		local bBothXInterceptsAreDefined 	= (not tMe.xInterceptIsUndefined) and (not tOther.xInterceptIsUndefined);
		local bBothXInterceptsAreUndefined 	= tMe.xInterceptIsUndefined and tOther.xInterceptIsUndefined;
		local bBothYInterceptsAreDefined 	= (not tMe.yInterceptIsUndefined) and (not tOther.yInterceptIsUndefined);
		local bBothYInterceptsAreUndefined 	= tMe.yInterceptIsUndefined and tOther.yInterceptIsUndefined;
		local bAreParrallel					= (bBothSlopesAreUndefined or (bBothSlopesAreDefined and (tMe.slope == tOther.slope)));

		return bAreParrallel and
			   (
			   (bBothXInterceptsAreUndefined	or (bBothXInterceptsAreDefined and (tMe.xIntercept == tOther.xIntercept))) and
			   (bBothYInterceptsAreUndefined	or (bBothYInterceptsAreDefined and (tMe.yIntercept == tOther.yIntercept)))
			   );
	end,

	--[[!
		@desc Serializes the object's data.
		@func line.serialize
		@module line
		@param bDefer boolean Whether or not to return a table of data to be serialized instead of a serialize string (if deferring serializtion to another object).
		@ret sData StringOrTable The data, returned as a serialized table (string) or a table is the defer option is set to true.
	!]]
	serialize = function(this, bDefer)
		local tProt = tProtectedRepo[this];
		--[[local tData = {
			start 	= tProt.start:seralize(),
			stop 	= tProt.stop:serialize(),
		};

		if (not bDefer) then
			tData = serialize.table(tData);
		end

		return tData;]]
		return serialize.table(tProt);
	end,

	setEnd = function(this, oPoint, bSkipUpdate)
		local tProt = tProtectedRepo[this];
		tProt.stop.x = oPoint.x;
		tProt.stop.y = oPoint.y;

		if (not bSkipUpdate) then
			update(this);
		end

	end,

	setStart = function(this, oPoint, bSkipUpdate)
		local tProt = tProtectedRepo[this];
		tProt.start.x = oPoint.x;
		tProt.start.y = oPoint.y;

		if (not bSkipUpdate) then
			update(this);
		end

	end,

	slopeIsDefined = function(this)
		return not tProtectedRepo[this].slopeIsUndefined;
	end,

	xInterceptIsDefined = function(this)
		return not tProtectedRepo[this].xInterceptIsUndefined;
	end,

	yInterceptIsDefined = function(this)
		return not tProtectedRepo[this].yInterceptIsUndefined;
	end,

};
