--credits https://www.redblobgames.com/grids/hexagons/
local tProtectedRepo = {};

--localization
local assert 		= assert;
local class 		= class;
local constant 		= constant;
local deserialize	= deserialize;
local math			= math;
local point			= point;
local serialize		= serialize;
local type 			= type;
local rawtype		= rawtype;
local shape			= shape;

constant("HEX_POINT_TOP_DEGREE_MODIFIER", 30);
local HEX_POINT_TOP_DEGREE_MODIFIER = HEX_POINT_TOP_DEGREE_MODIFIER;

local function recalculateVertices(this)
	local tFields = tProtectedRepo[this];

	tFields.vertices 	= {};
	local nDegreeMod 	= tFields.isFlat and HEX_POINT_TOP_DEGREE_MODIFIER or 0;

	--calculate the vertices
	for x = 1, 6 do
		local angle_deg = 60 * (x - 1) - nDegreeMod;
		local angle_rad = math.pi / 180 * angle_deg

		tFields.vertices[x] = point(tFields.center.x + tFields.size * math.cos(angle_rad),
								 	tFields.center.y + tFields.size * math.sin(angle_rad));
	end

end

local hexagon = class "hexagon" : extends(polygon) {

	__construct = function(this, tProtected, oCenterPoint, nSize, bIsFlat)
		tProtectedRepo[this] = tProtected or {};

		local tFields 			= tProtectedRepo[this];
		tFields.size 			= type(nSize) 	== "number" 	and nSize 	or 1;
		tFields.isFlat			= type(bIsFlat) == "boolean" 	and bIsFlat or false;
		tFields.verticesCount	= 6;

		if (type(oCenterPoint) == "point") then
			tFields.centroid.x = oCenterPoint.x;
			tFields.centroid.y = oCenterPoint.y;
		end

		--calculate the width and height
		tFields.width 	= math.sqrt(3) * this.size;
		tFields.height	= this.size * 2;

		this:super(nil, true);

		--calculate the vertices
		this:recalculateVertices();

		--update the hexagon
		tFields:updatePerimeterAndEdges();
		tFields:updateDetector();
		tFields:updateAnchors();
		tFields:updateArea();
		tFields:updateAngles();

	end,

	setSize = function(this, nSize)
		local tFields 			= tProtectedRepo[this];

		if (type(nSize) == "number" and nSize > 0) then
			error("Size must be a number greater than 0.")
		end

		tFields.size = nSize;

		this:recalculateVertices();
		tProt:updatePerimeterAndEdges();
		tProt:updateDetector();
		tProt:updateAnchors();
		tProt:updateArea();
		tProt:updateAngles();
	end,
};

return hexagon;
