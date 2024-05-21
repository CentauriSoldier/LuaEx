--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
	<h2>triangle</h2>
	<p></p>
@license <p>The Unlicense<br>
<br>
@moduleid triangle
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
local serialize		= serialize;
local deserialize	= deserialize;
local point			= point;
local table			= table;
local type 			= type;


local tProtectedRepo = {};

--[[assumes the other update functions have been called]]
local function update(tFields)
	--update the sides
	local nSide1 		= tFields.edges[1]:getLength();
	local nSide2 		= tFields.edges[2]:getLength();
	local nSide3 		= tFields.edges[3]:getLength();

	--sort the sides by value
	local tSort3 = {nSide1, nSide2, nSide3};

	table.sort(tSort3);

	tFields.smallSide	= tSort3[1];
	tFields.midSide		= tSort3[2];
	tFields.largeSide	= tSort3[3];

	--update the angles
	local tAngles 	= tFields.angles;

	--TODO update the angles
	local nAngle1 	= tAngles[1];
	local nAngle2 	= tAngles[2];
	local nAngle3 	= tAngles[3];

	--sort the angles by value
	tSort3 = {nAngle1, nAngle2, nAngle3};
	table.sort(tSort3);
	tFields.smallAngle	= tSort3[1];
	tFields.largeAngle	= tSort3[2];
	tFields.midAngle	= tSort3[3];

	--update the other fields
	tFields.isAcute 		= nAngle1 < 90 and nAngle2 < 90 and nAngle1 < 90;
	tFields.isEquilateral	= (nSide1 == nSide2) and (nSide2 == nSide3);
	tFields.isIsosceles		= (not tFields.isEquilateral) and ( (nSide1 == nSide2) or (nSide1 == nSide3) or (nSide2 == nSide3) );
	tFields.isObtuse		= nAngle1 > 90 or nAngle2 > 90 or nAngle3 > 90;
	tFields.isRight 		= nAngle1 == 90 or nAngle2 == 90 or nAngle3 == 90;
	tFields.isScalene 		= (nSide1 ~= nSide2) and (nSide1 ~= nSide3) and (nSide2 ~= nSide3);
end

local triangle = class "triangle" : extends(polygon) {

	--[[
	@desc The constructor for the triangle class.
	@func triangle
	@mod triangle
	@ret oTriangle triangle A triangle object. Public properties are vertices (a table containing points for each corner [topLeft, topRight, bottomRight, bottomLeft, center]), width and height.
	]]
	__construct = function(this, tProtected, oPoint1, oPoint2, oPoint3)
		tProtectedRepo[this] = tProtected or {};
		local tFields = tProtectedRepo[this];

		--default the values in case the initial update is skipped
		tFields.angles 			= {};
		tFields.isAcute 		= false;
		tFields.isEquilateral	= false;
		tFields.isIsosceles		= false;
		tFields.isObtuse		= false;
		tFields.isRight 		= false;
		tFields.isScalene 		= false;
		tFields.smallAngle		= 0;
		tFields.midAngle		= 0;
		tFields.largeAngle		= 0;
		tFields.smallSide		= 0;
		tFields.midSide			= 0;
		tFields.largeSide		= 0;

		--tFields.verticesCount = 3;
		local tVertices = {
			[1]	= type(oPoint1) == "point" and point(oPoint1.x, oPoint1.y) or point(),
			[2]	= type(oPoint2) == "point" and point(oPoint2.x, oPoint2.y) or point(),
			[3] = type(oPoint3) == "point" and point(oPoint3.x, oPoint3.y) or point(),
		};

		this:super(tVertices, true);

		update(tFields);

		--update the triangle
		tFields:updatePerimeterAndEdges();
		tFields:updateDetector();
		tFields:updateAnchors();
		tFields:updateArea();
		tFields:updateAngles();
	end,

	deserialize = function(this, sData)
		local tData = deserialize.table(sData);

		error("Complete this function.");
	end,

	getAltitude = function(this)

	end,

	getSmallAngle = function(this)
		return tProtectedRepo[this].smallAngle;
	end,

	getMidAngle = function(this)
		return tProtectedRepo[this].midAngle;
	end,

	getLargeAngle = function(this)
		return tProtectedRepo[this].largeAngle;
	end,

	getSmallSide = function(this)
		return tProtectedRepo[this].smallSide;
	end,

	getMidSide = function(this)
		return tProtectedRepo[this].midSide;
	end,

	getLargeSide = function(this)
		return tProtectedRepo[this].largeSide;
	end,

	isAcute = function(this)
		return tProtectedRepo[this].isAcute;
	end,

	isEquilateral = function(this)
		return tProtectedRepo[this].isEquilateral;
	end,

	isIsosceles = function(this)
		return tProtectedRepo[this].isIsosceles;
	end,

	isObtuse = function(this)
		return tProtectedRepo[this].isObtuse;
	end,

	isRight = function(this)
	   return tProtectedRepo[this].isRight;
   	end,

	isScalene = function(this)
		return tProtectedRepo[this].isScalene;
	end,

--[[
	pointIsOnPerimeter = function(this, vPoint, vY)

	end
]]
	--[[!
		@desc Serializes the object's data.
		@func triangle.serialize
		@module triangle
		@param bDefer boolean Whether or not to return a table of data to be serialized instead of a serialize string (if deferring serializtion to another object).
		@ret sData StringOrTable The data, returned as a serialized table (string) or a table is the defer option is set to true.
	!]]
	serialize = function(this, bDefer)
		error("Complete this function.");
	end,

	--setPos = function(this)

	--end,



};

return triangle;
