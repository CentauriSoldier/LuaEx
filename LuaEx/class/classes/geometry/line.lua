--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
	<h2>line</h2>
	<p></p>
@license <p>The Unlicense<br>
<br>
@moduleid line
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
local nSpro			= class.args.staticprotected;
local nPri 			= class.args.private;
local nPro 			= class.args.protected;
local nPub 			= class.args.public;
local nIns			= class.args.instances;

--a location for storing temporary points so they don't need to be created every calcualtion
local tTempPoints = {};

local function update(pri)
	local oMidPoint = pri.midpoint;
	local nStartX 	= pri.start.getX();
	local nStartY 	= pri.start.getY();
	local nStopX  	= pri.stop.getX();
	local nStopY 	= pri.stop.getY();

	--update the line's midpoint
	oMidPoint.setX((nStartX + nStopX) / 2);
	oMidPoint.setY((nStartY + nStopY) / 2);

	--update the line's slope, theta and y intercept
	local nYDelta = nStopX - nStartY;
	local nXDelta = nStopX - nStartX;
	pri.slopeIsUndefined = nXDelta == 0;

	--get the quadrant addative for theta
	local nXIsPos	= nXDelta > 0;
	local nYIsPos	= nYDelta > 0;

	--determine slope and y-intercept
	if (pri.slopeIsUndefined) then
		pri.slope 		= MATH_UNDEF;
		pri.yIntercept 	= nStartX == 0 and MATH_ARL or MATH_UNDEF;
	else
		pri.slope 		= nYDelta / nXDelta;
		pri.yIntercept 	= nStartY - pri.slope * nStartX;
	end

	--translate end point to the origin (using the object's temp point) in order to find theta
	local oEnd = tTempPoints[pri];
--TODO optimize this...no need for oEnd Calls
	oEnd.setX(nStopX - nStartX);
	oEnd.setY(nStopY - nStartY);

	pri.theta = math.deg(math.atan2(oEnd.getY(), oEnd.getX()));
	--make sure the value is positive
	pri.theta = pri.theta >= 0 and pri.theta or 360 + pri.theta;

	--get the standard-form components and set the x intercept
	pri.a = nYDelta;--pri.stop.y - pri.start.y;
	pri.b = nStartX - nStopX;
	pri.c = pri.a * nStartX + pri.b * nStartY;

	--y = mx + b => 0 = mx + b => -b = mx => x = -b/m
	pri.xIntercept = pri.slopeIsUndefined and nStartX or (pri.slope == 0 and MATH_UNDEF or -pri.yIntercept / pri.slope);


	--update whether or not the intercepts are defined
	pri.xInterceptIsUndefined = rawtype(pri.xIntercept) == "string";
	pri.yInterceptIsUndefined = rawtype(pri.yIntercept) == "string";

	--update the deltas
	pri.deltaX = nXDelta;
	pri.deltaY = nYDelta;

	--update the line's length
	pri.length = math.sqrt( (nStartX - nStopX) ^ 2 + (nStartY - nStopY) ^ 2);
end

--local spro = args[nSpro];
--local pri = args[nPri];
--local pro = args[nPro];
--local pub = args[nPub];
--local ins = args[nIns];

return class(
"line",
{--metamethods
	__tostring = function(args, this)
		local pri = args[nPri];
		local sRet 	= "";

		sRet = sRet.."start: "		..tostring(pri.start).."\r\n";
		sRet = sRet.."end: "		..tostring(pri.stop).."\r\n";
		sRet = sRet.."midpoint: "	..tostring(pri.midpoint).."\r\n";
		sRet = sRet.."slope: "		..pri.slope.."\r\n";
		sRet = sRet.."theta: "		..pri.theta.."\r\n";
		sRet = sRet.."delta x: "	..pri.deltaX.."\r\n";
		sRet = sRet.."delta y: "	..pri.deltaY.."\r\n";
		sRet = sRet.."length: "		..pri.length.."\r\n";
		sRet = sRet.."x intercept: "..pri.xIntercept.."\r\n";
		sRet = sRet.."y intercept: "..pri.yIntercept.."\r\n";
		sRet = sRet.."A: "			..pri.a.."\r\n";
		sRet = sRet.."B: "			..pri.b.."\r\n";
		sRet = sRet.."C: "			..pri.c.."\r\n";
		sRet = sRet.."Vector: <"	..pri.a..", "..pri.b..">";

		return sRet;
	end,


	__len = function(args, this)
		return args[nPri].length;
	end,


	__eq = function(args, this, other)
		local tMe 		= args[nPri];
		local tOther 	= args[nIns][other][nPri];
		--TODO optimize this by reducing redundant calls
		return tMe.start.x 	== tOther.start.getX() 	and tMe.start.getY() 	== tOther.start.getY() and
			   tMe.stop.x 	== tOther.stop.getX() 	and tMe.stop.getY() 	== tOther.stop.getY();
	end,
},
{--static protected

},
{--static public

},
{--private
	midpoint,
	start,
	stop,
	a,
	b,
	c,
	deltaX,
	deltaY,
	length,
	slope,
	slopeIsUndefined,
	theta,
	yIntercept,
	yInterceptIsUndefined,
	xIntercept,
	xInterceptIsUndefined,
},
{--protected

},
{--public

	line = function(this, args, oStartPoint, oEndPoint, bSkipUpdate)
		local pri = args[nPri];

		pri.start 		= type(oStartPoint) == "point" 	and point(oStartPoint.getX(), 	oStartPoint.getY())	or point();
		pri.stop 		= type(oEndPoint)	== "point" 	and point(oEndPoint.getX(), 	oEndPoint.getY()) 	or point();
		pri.midpoint  	= point();

		--default the fields (in case no update is performed)
		pri.a 						= 0;
		pri.b 						= 0;
		pri.c 						= 0;
		pri.deltaX 					= 0;
		pri.deltaY 					= 0;
		pri.length 					= 0;
		pri.slope 					= 0;
		pri.slopeIsUndefined 		= true;
		pri.theta 					= 0;
		pri.yIntercept 				= 0;
		pri.yInterceptIsUndefined 	= true;
		pri.xIntercept 				= 0;
		pri.xInterceptIsUndefined 	= true;
		--pri. = 0;

		--create this line's temp point (used during updates)
		tTempPoints[pri] = point(0, 0);

		if (not bSkipUpdate) then
			update(pri);
		end

	end,

	deserialize = function(this, args, sData)
		local tData = deserialize.table(sData);

		this.start 	= this.start.deserialize(tData.start);
		this.stop	= this.stop.deserialize(tData.stop);
		error("UDPATE THIS FUNCTION")
		return this;
	end,


	getASCII = function(this, args)
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

	getDeltaX = function(this, args)
		return args[nPri].deltaX;
	end,

	getDeltaY = function(this, args)
		return args[nPri].deltaY;
	end,

	getEnd = function(this, args)
		return args[nPri].stop;
	end,

	getLength = function(this, args)
		return args[nPri].length;
	end,

	getMidPoint = function(this, args)
		return args[nPri].midpoint;
	end,

	getPointAtDistance = function(this, args, nDistance)
		--https://stackoverflow.com/questions/1250419/finding-points-on-a-line-with-a-given-distance
	end,

	getPointOfIntersection = function(this, args, other)
		local tMe 		= args[nPri];
		local tOther 	= args[nIns][other][nPri];
		local oRet		= MATH_UNDEF;
--TODO optimize function calls
		local A1 = tMe.stop.getY() - tMe.start.getY();
		local B1 = tMe.start.getX() - tMe.stop.getX();
		local C1 = A1 * tMe.start.getX() + B1 * tMe.start.getY();

		local A2 = tOther.stop.getY() - tOther.start.getY();
		local B2 = tOther.start.getX() - tOther.stop.getX();
		local C2 = A2 * tOther.start.getX() + B2 * tOther.start.getY();

		local nDeterminate = (A1 * B2 - A2 * B1);

		if (nDeterminate ~= 0) then
			local x = (B2 * C1 - B1 * C2) / nDeterminate;
			local y = (A1 * C2 - A2 * C1) / nDeterminate;

			oRet = point(x, y);
		end

		return oRet;
	end,

	--get the polar radius
	getR = function(this, args)
		return args[nPri].length;
	end,

	getSlope = function(this, args)
		return args[nPri].slope;
	end,


	getStart = function(this, args)
		return args[nPri].start;
	end,

	--get the polar angles from the x-axis
	getTheta = function(this, args)
		return args[nPri].theta;
	end,


	getXIntercept = function(this, args)
		return args[nPri].xIntercept;
	end,

	getYIntercept = function(this, args)
		return args[nPri].yIntercept;
	end,

	intersects = function(this, args, other)
		local tMe 		= args[nPri];
		local tOther 	= args[nIns][other][nPri];

		local A1 = tMe.stop.getY() - tMe.start.getY();
		local B1 = tMe.start.getX() - tMe.stop.getX();

		local A2 = tOther.stop.getY() - tOther.start.getY();
		local B2 = tOther.start.getX() - tOther.stop.getX();

		return (A1 * B2 - A2 * B1) ~= 0;
	end,

	isDistinctFrom = function(this, args, other)

	end,

	isParrallelTo = function(this, args, other)
		local tMe 						= args[nPri];
		local tOther 					= args[nIns][other][nPri];
		local bBothSlopesAreDefined 	= (not tMe.slopeIsUndefined) and (not tOther.slopeIsUndefined);
		local bBothSlopesAreUndefined 	= tMe.slopeIsUndefined and tOther.slopeIsUndefined;

		return bBothSlopesAreUndefined or (bBothSlopesAreDefined and (tMe.slope == tOther.slope));
	end,

	coincidesWith = function(this, args, other)
		local tMe 							= args[nPri];
		local tOther 						= args[nIns][other][nPri];
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
	serialize = function(this, args, bDefer)
		local pri = args[nPri];
		--[[local tData = {
			start 	= pri.start:seralize(),
			stop 	= pri.stop:serialize(),
		};

		if (not bDefer) then
			tData = serialize.table(tData);
		end

		return tData;]]
		return serialize.table(pri);
	end,

	setEnd = function(this, args, oPoint, bSkipUpdate)
		local pri = args[nPri];
		pri.stop.setX(oPoint.getX());
		pri.stop.setY(oPoint.getY());

		if (not bSkipUpdate) then
			update(pri);
		end

	end,

	setStart = function(this, oPoint, bSkipUpdate)
		local pri = tProtectedRepo[this];
		pri.start.setX(oPoint.getX());
		pri.start.setY(oPoint.getY());

		if (not bSkipUpdate) then
			update(pri);
		end

	end,

	slopeIsDefined = function(this, args)
		return not args[nPri].slopeIsUndefined;
	end,

	xInterceptIsDefined = function(this, args)
		return not args[nPri].xInterceptIsUndefined;
	end,

	yInterceptIsDefined = function(this, args)
		return not args[nPri].yInterceptIsUndefined;
	end,
},
nil,    --extending class
nil,    --interface(s) (either nil, an interface or a table of interfaces)
false  	--if the class is final
);
