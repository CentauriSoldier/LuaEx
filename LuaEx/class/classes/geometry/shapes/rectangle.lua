--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
	<h2>rectangle</h2>
	<p></p>
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

--localization
local class 		= class;
local constant		= constant;
local deserialize	= deserialize;
local math			= math;
local point			= point;
local rawtype 		= rawtype;
local serialize		= serialize;
local type 			= type;

local tProtectedRepo = {};

return class "rectangle" : extends(polygon) {

	--[[
	@desc The constructor for the rectangle class.
	@func rectangle
	@mod rectangle
	@ret oRectangle rectangle A rectangle object. Public properties are vertices (a numerically-indexed table containing points for each corner), width and height.
	]]
	__construct = function(this, tProtected, pTopLeft, nWidth, nHeight)
		tProtectedRepo[this] = tProtected;
		local tFields = tProtectedRepo[this];

		--set th width and height
		nWidth 	= rawtype(nWidth) 	== "number" and nWidth 	or 0;
		nHeight = rawtype(nHeight) 	== "number" and nHeight or 0;

		--tFields.verticesCount = 4;
		local tVertices = {
			[1] = point(),
			[2]	= point(),
			[3]	= point(),
			[4]	= point(),
		};

		--check the point input
		if (type(pTopLeft) == "point") then
			tVertices[1].x = pTopLeft.x;
			tVertices[1].y = pTopLeft.y;
			tVertices[2].x = pTopLeft.x + nWidth;
			tVertices[2].y = pTopLeft.y;
			tVertices[3].x = pTopLeft.x + nWidth;
			tVertices[3].y = pTopLeft.y + nHeight;
			tVertices[4].x = pTopLeft.x;
			tVertices[4].y = pTopLeft.y + nHeight;
		end

		--call the parent constructor with the protected table, no vertices and skipping auto-update
		this:super(tVertices);

		--set the anchor point (to the top left vertex)
		tFields.anchorIndex = 1;

		--set th width and height
		tFields.width 	= nWidth;
		tFields.height 	= nHeight;

		--override the required protected methods
		tFields.updateArea = function(tFields)
			tFields.area = tFields.width * tFields.height;
		end


		--update the rectangle
		--tFields:updatePerimeterAndEdges();
		--tFields:updateDetector();
		--tFields:updateAnchors();
		--tFields:updateArea();
		--tFields:updateAngles();
	end,


	deserialize = function(this, sData)
		local tData = deserialize.table(sData);

		--this.vertices[]	 	= this.vertices.topLeft:deserialize(tData.vertices.topLeft);
		--this.vertices[]		= this.vertices.topRight:deserialize(tData.vertices.topRight);
		--this.vertices[] 	= this.vertices.bottomLeft:deserialize(tData.vertices.bottomLeft);
		--this.vertices[] 	= this.vertices.bottomRight:deserialize(tData.vertices.bottomRight);
		--this.vertices[]		= this.vertices.center:deserialize(tData.vertices.center);

		this.width 		= tData.width;
		this.height 	= tData.height;
	end,

	getHeight = function(this)
		return tProtectedRepo[this].height;
	end,

	getWidth = function(this)
		return tProtectedRepo[this].width;
	end,


	--[[!
		@desc Serializes the object's data.
		@func rectangle.serialize
		@module rectangle
		@param bDefer boolean Whether or not to return a table of data to be serialized instead of a serialize string (if deferring serializtion to another object).
		@ret sData StringOrTable The data, returned as a serialized table (string) or a table is the defer option is set to true.
	!
	serialize = function(this, bDefer)
		local tData = {
			vertices 	= {
				topLeft		= this.vertices.topLeft:seralize(),
				topRight	= this.vertices.topRight:seralize(),
				bottomLeft 	= this.vertices.bottomLeft:seralize(),
				bottomRight = this.vertices.bottomRight:seralize(),
				center		= this.vertices.center:seralize(),
			},
			width 		= this.width,
			height 		= this.height,
		};

		if (not bDefer) then
			tData = serialize.table(tData);
		end

		return tData;
	end,]]


	setHeight = function(this, nHeight)
		local tFields 	= tProtectedRepo[this];
		local tVertices = tFields.vertices;
		local nDelta 	= nHeight - tFields.height;
		tFields.height 	= nHeight;

		tVertices[3].y = tVertices[3].y + nDelta;
		tVertices[4].y = tVertices[4].y + nDelta;

		tFields:updateAnchors();
		tFields:updateDetector();
		tFields:updatePerimeterAndEdges();
		tFields:updateArea();
	end,


	setWidth = function(this, nWidth)
		local tFields 	= tProtectedRepo[this];
		local tVertices = tFields.vertices;
		local nDelta 	= nWidth - tFields.width;
		tFields.height 	= nWidth;

		tVertices[2].x = tVertices[2].x + nDelta;
		tVertices[3].x = tVertices[3].x + nDelta;

		tFields:updateAnchors();
		tFields:updateDetector();
		tFields:updatePerimeterAndEdges();
		tFields:updateArea();
	end,
};
