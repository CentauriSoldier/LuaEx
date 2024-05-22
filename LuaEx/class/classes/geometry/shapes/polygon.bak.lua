local tProtectedRepo 	= {};
local tPrivate			= {};

local QUADRANT_I 		= QUADRANT_I;
local QUADRANT_II 		= QUADRANT_II
local QUADRANT_III		= QUADRANT_III;
local QUADRANT_IV 		= QUADRANT_IV;
local QUADRANT_O		= QUADRANT_O;
local QUADRANT_X		= QUADRANT_X;
local QUADRANT_X_NEG 	= QUADRANT_X_NEG;
local QUADRANT_Y		= QUADRANT_Y;
local QUADRANT_Y_NEG	= QUADRANT_Y_NEG;
local SHAPE_ANCHOR_COUNT		= SHAPE_ANCHOR_COUNT;
local SHAPE_ANCHOR_TOP_LEFT 	= SHAPE_ANCHOR_TOP_LEFT;
local SHAPE_ANCHOR_TOP_RIGHT 	= SHAPE_ANCHOR_TOP_RIGHT;
local SHAPE_ANCHOR_BOTTOM_RIGHT = SHAPE_ANCHOR_BOTTOM_RIGHT;
local SHAPE_ANCHOR_BOTTOM_LEFT 	= SHAPE_ANCHOR_BOTTOM_LEFT;
local SHAPE_ANCHOR_CENTROID		= SHAPE_ANCHOR_CENTROID;
local SHAPE_ANCHOR_DEFAULT		= SHAPE_ANCHOR_DEFAULT;
local class 					= class;
local deserialize				= deserialize;
local line 						= line;
local math 						= math;
local pairs 					= pairs;
local point 					= point;
local rawtype 					= rawtype;
local serialize					= serialize;
local table 					= table;
local tostring 					= tostring;
local type 						= type;


local SIDE_TRIANGLE_DIFFERENTIAL 		= 3;
local SIDE_ANGLE_FACTOR_DIFFERENTIAL	= 2;
local SUM_OF_EXTERIOR_ANGLES			= 360;
--[[
list of protected properties
area
anchorPoint
anchors
detector
edges 		-
edgesCount
exteriorAngles
interiorAngles
perimeter
sumOfInteriorAngles
vertices 	-
verticesCount
x
y

list of protected methods
updatePerimeterAndEdges
updateDetector
updateAnchors
updateArea
updateAngles

]]

local function importVertices(tFields, tVertices, nMax)
	nMax = rawtype(nMax) == "number" and nMax or #tVertices;

	tFields.vertices 		= {};
	tFields.verticesCount 	= 0;

	for nVertex, oPoint in ipairs(tVertices) do
		tFields.verticesCount = tFields.verticesCount + 1;

		--make sure the input indices are sequential integers
		if (nVertex ~= tFields.verticesCount) then
			error("Cannot create polygon; vertices must be of type point; vertex ${vertexID} is out of bounds. It should be ${vertexCount}" % {vertexID = nVertex, vertexCount = tFields.verticesCount});
		end

		--make sure each vertex is a point
		if (type(oPoint) ~= "point") then
			error("Cannot create polygon; vertices must be of type point; vertex ${vertexID} is of type ${vertexType}" % {vertexID = nVertex, vertexType = type(oPoint)});
		end

		tFields.vertices[tFields.verticesCount] = point(oPoint.x, oPoint.y);
	end

	if (tFields.verticesCount < 3) then
		error("Cannot create polygon; must have 3 or more sides; given only "..tFields.verticesCount.." vertices.");
	end

	tFields.sumOfInteriorAngles = (tFields.verticesCount - 2) * 180;
end

local function updateDetector(tFields)
	tFields.detector = {};

	--calculate the poly
	local oLastPoint = tFields.vertices[tFields.verticesCount];
	local nLastX = oLastPoint.x;
	local nLastY = oLastPoint.y;

	for x = 1, tFields.verticesCount do
		local oPoint = tFields.vertices[x];
		local nX = oPoint.x;
		local nY = oPoint.y;
		-- Only store non-horizontal edges.
		if nY ~= nLastY then
			local index = #tFields.detector;
			tFields.detector[index+1] = nX;
			tFields.detector[index+2] = nY;
			tFields.detector[index+3] = (nLastX - nX) / (nLastY - nY);
		end
		nLastX = nX;
		nLastY = nY;
	end

end

local function updateAnchors(tFields)
	local nSumX 				= 0;
	local nSumY					= 0;
	local tVertices 			= tFields.vertices;
	local nVertices 			= tFields.verticesCount;
	local oAnchorTopLeft 		= tFields.anchors[SHAPE_ANCHOR_TOP_LEFT];
	local oAnchorTopRight		= tFields.anchors[SHAPE_ANCHOR_TOP_RIGHT];
	local oAnchorBottomRight 	= tFields.anchors[SHAPE_ANCHOR_BOTTOM_RIGHT];
	local oAnchorBottomLeft 	= tFields.anchors[SHAPE_ANCHOR_BOTTOM_LEFT];

	--prep the 'corner' anchor points
	local oPoint1 = tVertices[1];

	--top left
	oAnchorTopLeft.x 		= oPoint1.x;
	oAnchorTopLeft.y 		= oPoint1.y;
	--top right
	oAnchorTopRight.x 		= oPoint1.x;
	oAnchorTopRight.y 		= oPoint1.y;
	--bottom right
	oAnchorBottomRight.x 	= oPoint1.x;
	oAnchorBottomRight.y 	= oPoint1.y;
	--bottom left
	oAnchorBottomLeft.x 	= oPoint1.x;
	oAnchorBottomLeft.y 	= oPoint1.y;

	for x = 1, nVertices do
		--process data for the centroid
		local oPoint = tVertices[x];
		nSumX = nSumX + oPoint.x;
		nSumY = nSumY + oPoint.y;

		--update the 'corner' anchor points

		--top left
		oAnchorTopLeft.x 		= oPoint.x < oAnchorTopLeft.x 		and oPoint.x or oAnchorTopLeft.x;
		oAnchorTopLeft.y 		= oPoint.y < oAnchorTopLeft.y 		and oPoint.y or oAnchorTopLeft.y;
		--top right
		oAnchorTopRight.x 		= oPoint.x > oAnchorTopRight.x 		and oPoint.x or oAnchorTopRight.x;
		oAnchorTopRight.y 		= oPoint.y < oAnchorTopRight.y 		and oPoint.y or oAnchorTopRight.y;
		--bottom right
		oAnchorBottomRight.x 	= oPoint.x > oAnchorBottomRight.x 	and oPoint.x or oAnchorBottomRight.x;
		oAnchorBottomRight.y 	= oPoint.y > oAnchorBottomRight.y 	and oPoint.y or oAnchorBottomRight.y;
		--bottom left
		oAnchorBottomLeft.x 	= oPoint.x < oAnchorBottomLeft.x 	and oPoint.x or oAnchorBottomLeft.x;
		oAnchorBottomLeft.y 	= oPoint.y > oAnchorBottomLeft.y 	and oPoint.y or oAnchorBottomLeft.y;
	end

	--update the centroid anchor
	tFields.anchors[SHAPE_ANCHOR_CENTROID].x = nSumX / nVertices;--tFields.centroid.x;
	tFields.anchors[SHAPE_ANCHOR_CENTROID].y = nSumY / nVertices;--tFields.centroid.y;
end

local function updateArea(tFields)--this algorithm doesn't work on complex polygons, find one which does and check before returning the area
	local nSum = 0;
	local tVertices = tFields.vertices;
	local nVerticesCount = #tVertices;

	for i = 1, nVerticesCount do
		local oPoint1 = tVertices[i];
		local oPoint2 = i < nVerticesCount and tVertices[i + 1] or tVertices[1];

		nSum = nSum + (oPoint1.x * oPoint2.y - oPoint1.y * oPoint2.x)
	end

	tFields.area = nSum / 2;
	--make sure it's a positive number (since the loop goes clockwise instead of CCW)
	tFields.area = tFields.area >= 0 and tFields.area or -tFields.area;
end

local function updatePerimeterAndEdges(tFields)
	tFields.perimeter		= 0;
	local tVertices 		= tFields.vertices;
	local nVerticesCount 	= tFields.verticesCount;

	if (tFields.edges[nVerticesCount] == nil) then
		tFields.edges	= {};

		for x = 1, nVerticesCount do
			tFields.edges[x] = line(nil, nil, true);
		end

	end

	for i = 1, nVerticesCount do
		local oPoint1 = tVertices[i];
		local oPoint2 = i < nVerticesCount and tVertices[i + 1] or tVertices[1];

		tFields.edges[i]:setStart(oPoint1, true);
		tFields.edges[i]:setEnd(oPoint2);

		tFields.perimeter = tFields.perimeter + tFields.edges[i]:getLength();
	end

	tFields.edgesCount = #tFields.edges;
end

local function updateAngles(tFields)
	tFields.interiorAngles 		= {};
	tFields.exteriorAngles 		= {};
	tFields.isConcave 			= false;
	tFields.isRegular			= false;
	local nRegularityAngleMark	= 0;
	local nRegularityEdgeMark	= 0;
	local bRegularityFailed		= false;
	local tEdges 				= tFields.edges;
	local nEdges				= #tFields.edges;


	for nLine = 1, tFields.edgesCount do --use the number of vertices since it's the same as the number of edges
		local bIsFirstLine 	= nLine == 1;

		--determine the lines between which the angle will be
		local oLine1 = tEdges[nLine];
		local oLine2 = bIsFirstLine and tEdges[nEdges] or tEdges[nLine - 1];
		--[[create a ghost triangle by creating a third, ghost line between
			the start of the first line and the end of the second line]]
		local oLine3 = line(oLine1:getEnd(), oLine2:getStart()); --ghost line

		--get the length of each line
		local nLength1 = oLine1:getLength();
		local nLength2 = oLine2:getLength();
		local nLength3 = oLine3:getLength();

		--get the angle opposite the ghost side using law of cosines (c^2 = a^2 + b^2 - 2ab*cos(C))
		local nTheta = math.deg(math.acos((nLength1 ^ 2 + nLength2 ^ 2 - nLength3 ^ 2) / (2 * nLength1 * nLength2)));

		--save the angle
		tFields.interiorAngles[nLine] = nTheta;

		--check for concavity
		if (nTheta > 180) then
			tFields.isConcave = true;
		end

		--regularity check init
		if (bIsFirstLine) then
			nRegularityAngleMark 	= nTheta;
			nRegularityEdgeMark 	= nLength1;
		end

		--regularity check
		if not (bRegularityFailed) then
			--[[check that this angle is the same as
				the last and the side, the same as the last]]
			bRegularityFailed = not (nRegularityAngleMark == nTheta and nRegularityEdgeMark == nLength1);
		end

		--if this is the last line and all angles/edges are repectively equal
		if (not bRegularityFailed and nLine == nEdges) then
			tFields.isRegular = true;
		end

		--get the exterior angle: this allows for negative interior angles so all ext angles == 360 even on concave polygons
		tFields.exteriorAngles[nLine] = 180 - tFields.interiorAngles[nLine];
	end

end

--[[!
	@mod polygon
	@func polygon
	@desc Used for creating various polygons and handling point
	detection and detector properties. The child class is responsible
	for creating vertices (upon construction) and storing them
	in the protected property of 'vertices' (a numerically-indexed
	table whose values are points). The child class is also
	responsible for updating the polygon whenever changes are
	made to size or position. This is done by calling super:update().
	It is expected, when creating the vertices, that a child class will
	insert them into the table starting with the first vertex and continuing
	around the polygon clockwise.

	Protected fields and methods:
	anchorIndex
	area 					(number)
	edges					(numerically-indexed table of lines)
	perimeter				(number)
	isConcave				(boolean)  NO CHILD CLASS SHOULD MODIFY THIS VALUE;
	isRegular				(boolean)  NO CHILD CLASS SHOULD MODIFY THIS VALUE;
	tweener					(table)
	vertices 				(numerically-indexed table of points)
	verticesCount			(number) NO CHILD CLASS SHOULD MODIFY THIS VALUE
	importVertices 			(function)
	updateArea				(function)
	updateAnchors 			(function)
	updateDetector 			(function)
	updatePerimeterAndEdges (function)


]]
local polygon = class "polygon" : extends(shape) {

	__construct = function(this, tProtected, tVertices, bSkipUpdate)
		tProtectedRepo[this] = tProtected;

		--super(tProtectedRepo[this], true);
		local tFields = tProtectedRepo[this];

		--import (or setup) the protected fields
		tFields.perimeter				= {};--rawtype(tFields.perimeter) 	== "number" and tFields.perimeter 		or 0;
		tFields.vertices				= rawtype(tFields.vertices)			== "table" 	and tFields.vertices 			or {};
		tFields.edges					= {};--rawtype(tFields.edges)			== "table" 	and tFields.edges 			or {};
		tFields.area 					= {};--rawtype(tFields.area) 			== "number" and tFields.area 				or 0;
		tFields.isConcave				= false;
		tFields.isRegular				= false;
		--this can be be set to a vertex ID or one of the shape anchor constants
		tFields.anchorIndex 		= rawtype(tFields.anchorIndex) 	== "number" and tFields.anchorIndex		or SHAPE_ANCHOR_DEFAULT;
		tFields.tweener				= {
			inProgress 	= false,
			line 		= line(nil, nil, true),
			pot 		= pot(0, 1, 0, 1, POT_CONTINUITY_NONE),
		};

		--setup the anchor points
		tFields.anchors	=  {
			[SHAPE_ANCHOR_TOP_LEFT] 	= point(),
			[SHAPE_ANCHOR_TOP_RIGHT]	= point(),
			[SHAPE_ANCHOR_BOTTOM_RIGHT]	= point(),
			[SHAPE_ANCHOR_BOTTOM_LEFT]	= point(),
			[SHAPE_ANCHOR_CENTROID]		= point(),
		}

		--setup the protected methods
		tFields.importVertices			= importVertices;
		tFields.updateArea				= updateArea;
		tFields.updateAnchors 			= updateAnchors;
		tFields.updateDetector 			= updateDetector;
		tFields.updatePerimeterAndEdges = updatePerimeterAndEdges;
		tFields.updateAngles 			= updateAngles;

		--import the vertices (if present)
		if (rawtype(tVertices) == "table") then
			importVertices(tFields, tVertices);
		end

		--update the polygon (if not skipped)
		if (not bSkipUpdate) then
			tFields:updatePerimeterAndEdges();
			tFields:updateDetector();
			tFields:updateAnchors();
			tFields:updateArea();
			tFields:updateAngles();
		end

		if not (tFields.verticesCount) then
			tFields.verticesCount = #tFields.vertices;
		end

		if not (tFields.edgesCount) then
			tFields.edgesCount	= #tFields.edges;
		end

	end,

	__tostring = function(this)
		local sRet = "";

		for k, v in pairs(tProtectedRepo[this]) do
			local sVType = type(v);

			if sVType == "number" 		or sVType == "point" 	or
			   sVType == "line"			or sVType == "shape" 	or
			   sVType == "polygon"		or sVType == "circle" 	or
			   sVType == "hexagon"		or sVType == "triangle" or
			   sVType == "rectangle"	then
				sRet = sRet..tostring(k)..": "..tostring(v).."\r\n";
			end

		end

		return sRet;
	end,


	containsCoord 	= function(this, nX, nY)
		local tFields 	= tProtectedRepo[this];
		local tDetector = tFields.detector;
		local nDetector = #tDetector;
		local nLastPX 	= tDetector[nDetector-2]
		local nLastPY 	= tDetector[nDetector-1]
		local bInside 	= false;

		for index = 1, #tDetector, 3 do
			local nPX = tDetector[index];
			local nPY = tDetector[index+1];
			local nDeltaX_Div_DeltaY = tDetector[index+2];

			if ((nPY > nY) ~= (nLastPY > nY)) and (nX < (nY - nPY) * nDeltaX_Div_DeltaY + nPX) then
				bInside = not bInside;
			end

			nLastPX = nPX;
			nLastPY = nPY;
		end

		return bInside;
	end,

	containsPoint = function(this, oPoint)
		local tFields 	= tProtectedRepo[this];
		local tDetector = tFields.detector;
		local nDetector = #tDetector;
		local nLastPX 	= tDetector[nDetector-2]
		local nLastPY 	= tDetector[nDetector-1]
		local bInside 	= false;

		for index = 1, #tDetector, 3 do
			local nPX = tDetector[index];
			local nPY = tDetector[index+1];
			local nDeltaX_Div_DeltaY = tDetector[index+2];

			if ((nPY > oPoint.y) ~= (nLastPY > oPoint.y)) and (oPoint.x < (oPoint.y - nPY) * nDeltaX_Div_DeltaY + nPX) then
				bInside = not bInside;
			end

			nLastPX = nPX;
			nLastPY = nPY;
		end

		return bInside;
	end,

	deserialize = function(this)
		error("COMPLETE THIS")
	end,

	getSumofExteriorAngles = function()
		return SUM_OF_EXTERIOR_ANGLES;
	end,

	--gets the sum of all interior angles
	getSumofInteriorAngles = function(this)
		return tProtectedRepo[this].sumOfInteriorAngles;
	end,

--TODO should these return a copy of the point?
	getPos = function(this)
		local tFields = tProtectedRepo[this];
		local oRet;

		if (tFields.vertices[tFields.anchorIndex] ~= nil) then--TODO is this right?
			oRet = tFields.vertices[tFields.anchorIndex];
		elseif (tFields.anchors[tFields.anchorIndex] ~= nil) then
			oRet = tFields.anchors[tFields.anchorIndex];
		end

		return oRet;
	end,

	getInteriorAngle = function(this, nVertex)
		return tProtectedRepo[this].interiorAngles[nVertex] or nil;
	end,

	getExteriorAngle = function(this, nVertex)
		return tProtectedRepo[this].exteriorAngles[nVertex] or nil;
	end,

	intersects = function(this, oOther)
		error("This function has not yet been written. Please refrain from using this function for the time being.");
	end,

	isConcave = function(this)--at least one angle that is greater than 180 degrees
		return tProtectedRepo[this].isConcave;
	end,

	isConvex = function(this)--no angle greater than 180 degrees
		return not tProtectedRepo[this].isConcave;
	end,

	isComplex = function(this)--when crossing over itself
		return false;
	end,

	isIrregular = function(this, oOther)
		return not tProtectedRepo[this].isRegular;
	end,

	isRegular = function(this)--when all sides are equal and all angles are equal
		return tProtectedRepo[this].isRegular;
	end,

	getAnchorIndex = function(this)
		return tProtectedRepo[this].anchorIndex;
	end,

	getArea = function(this)
		return tProtectedRepo[this].area;
	end,
	--TODO should these return a copy of the point?
	getCentroid = function(this)
		return tProtectedRepo[this].anchors[SHAPE_ANCHOR_CENTROID];
	end,
--TODO should these return a copy
	getEdge = function(this, nIndex)
		return tProtectedRepo[this].edges[nIndex] or nil;
	end,
	--TODO return a copy (yes, because edges cannot be properly modified by the client; they must use the vertices)
	getEdges = function(this)
		return table.clone(tProtectedRepo[this].edges, false) or nil;
	end,

	getVertex = function(this, nIndex)--TODO check input value
		local oVertex = tProtectedRepo[this].vertices[nIndex];
		return point(oVertex.x, oVertex.y);
	end,

	--scales the shape out from the centroid (or perhaps I can allow any anchor point?)
	scale = function(this, nScale)

	end,

	serialize = function(this)
		return serialize.table(tProtectedRepo[this]);
	end,
	--TODO should this auto-update position or at least have an optional arg for that?
	setAnchorIndex = function(this, nIndex)
		local tFields	= tProtectedRepo[this];

		if (tFields.vertices[nIndex] ~= nil or tFields.anchors[nIndex] ~= nil) then
			tFields.anchorIndex = nIndex;
		end

		return this;
	end,

	setPos = function(this, nX, nY)
		local tFields = tProtectedRepo[this];
		local oPivot;
		local nXDelta;
		local nYDelta;

		if (tFields.vertices[tFields.anchorIndex] ~= nil) then
			oPivot = tFields.vertices[tFields.anchorIndex];
		elseif (tFields.anchors[tFields.anchorIndex] ~= nil) then
			oPivot = tFields.anchors[tFields.anchorIndex];
		end

		--get the delta values
		nXDelta = nX - oPivot.x;
		nYDelta = nY - oPivot.y;

		--shift the vertices by the delta values
		for x = 1, tFields.verticesCount do
			local oPoint = tFields.vertices[x];
			oPoint.x = oPoint.x + nXDelta;
			oPoint.y = oPoint.y + nYDelta;
		end

		--update the centroid and anchors
		updateAnchors(tFields);

		return this;
	end,

	setVertex = function(this, nIndex, oPoint)
		local tFields = tProtectedRepo[this];

		if (tFields.vertices[nIndex] ~= nil) then
			tFields.vertices[nIndex].x = oPoint.x;
			tFields.vertices[nIndex].y = oPoint.y;
			tFields:updatePerimeterAndEdges();
			tFields:updateDetector();
			tFields:updateAnchors();
			tFields:updateArea();
			tFields:updateAngles();
		end

		return this;
	end,

	setVertices = function(this, tPoints, nVerticesCount)
		local tFields = tProtectedRepo[this];

		if (#tPoints ~= nVerticesCount) then
			error("Cannot set vertices for shape. Expected #{expected} points; given #{count} points." % {expected  = nVerticesCount, count = #tPoints});
		end

		--TODO this function has been updated and, as such, these input arguments are wrong
		tFields:importVertices(tPoints, tFields.verticesCount);
		--TODO doesn't this need updated here?
		return this;
	end,

	translate = function(this, nX, nY)
		local tFields = tProtectedRepo[this];

		--update all vertices
		for nVertex, oVertex in ipairs(tFields.vertices) do
			oVertex.x = oVertex.x + nX;
			oVertex.y = oVertex.y + nY;
		end

		--update all anchors
		for nVertex, oVertex in ipairs(tFields.anchors) do
			oVertex.x = oVertex.x + nX;
			oVertex.y = oVertex.y + nY;
		end

		return this;
	end,

	translateTo = function(this, oPoint)
		local tFields = tProtectedRepo[this];

		--get the anchor point and find the change in x and y
		local oAnchor = tFields.anchors[tFields.anchorIndex];
		local nDeltaX = oPoint.x - oAnchor.x;
		local nDeltaY = oPoint.y - oAnchor.y;

		--adjust all vertices to reflect that change
		for nVertex, oVertex in ipairs(tFields.vertices) do
			oVertex.x = oVertex.x + nDeltaX;
			oVertex.y = oVertex.y + nDeltaY;
		end

		--update all anchors
		for nVertex, oVertex in ipairs(tFields.anchors) do
			oVertex.x = oVertex.x + nDeltaX;
			oVertex.y = oVertex.y + nDeltaY;
		end

		return this;
	end,

--TODO allow arc tweening
	tween = function(this, oPoint, nStepDistance)
	    local tFields 	= tProtectedRepo[this];
		local oAnchor 	= tFields.anchors[tFields.anchorIndex];

	    if (oAnchor.x ~= oPoint.x or oAnchor.y ~= oPoint.y) then
			local tTweener 	= tFields.tweener;
			local oPot 		= tTweener.pot;
			local oLine 	= tTweener.line;

			--setup the tweener if this is the first call
			if not (tTweener.inProgress) then
				tTweener.inProgress = true;
				oLine:setStart(oAnchor, true):setEnd(oPoint);
			end

	        --make sure we don't overstep
	        if (nStepDistance > oLine:length()) then
				oAnchor.x = oPoint.x;
				oAnchor.y = oPoint.y;
				tTweener.inProgress = false;
	        else

				--WAITING TO FINISH line:getPointAtDistance method
	            --update all vertices


	            --update all anchors

	            --check if we've arrived

	        end

	    end

	end
};

return polygon;
