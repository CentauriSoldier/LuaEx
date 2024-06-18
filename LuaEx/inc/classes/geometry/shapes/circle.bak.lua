--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
	<h2>circle</h2>
	<p></p>
@license <p>The Unlicense<br>
<br>
@moduleid circle
@version 1.1
@versionhistory
<ul>
    <li>
        <b>1.2</b>
        <br>
        <p>Change: updated to work with new LuaEx class system.</p>
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

tProtectedRepo = {};

--localization
local class 		= class;
local deserialize	= deserialize;
local math 			= math;
local point			= point;
local serialize		= serialize;
local type 			= type;
local shape 		= shape;

local function update(tFields)
	tFields.area 			= math.pi * this.radius ^ 2;
	tFields.circumference 	= math.pi * this.radius * 2;
end

local circle = class "circle" : extends(shape) {

	--[[
    @fqxn LuaEx.Classes.Geometry.Circle
	@desc The constructor for the circle class.
	@mod circle
	@ret oCircle circle A circle object. Public properties are center and radius.
	]]
	__construct = function(this, tProtected, pCenter, nRadius)
		tProtectedRepo[this] = tProtected or {};
		--super(tProtectedRepo[this], true);
		local tFields = tProtectedRepo[this];

		tFields.center 			= type(pCenter) 	== "point" 						and pCenter or point();
		tFields.centroid		= tFields.center; 	-- alias
		tFields.radius 			= (type(nRadius) 	== "number" and nRadius >= 0) 	and nRadius or 1;
		tFields.area   			= 0;
		tFields.circumference 	= 0;
		update();
	end,

	containsPoint = function(this, oPoint)
		return math.sqrt( (this.center.x - oPoint.x) ^ 2 + (this.center.y - oPoint.y) ^ 2 ) < this.radius;
	end,

	getArea = function(this)
		return tProtectedRepo[this].area;
	end,

	getCircumference = function(this)
		return tProtectedRepo[this].circumference;
	end,

	getPos = function(this)
		return tProtectedRepo[this].center:clone();
	end,

	getRadius = function(this)
		return tProtectedRepo[this].raidus;
	end,

	--TODO FINISH
	deserialize = function(this, sData)
		local tData = deserialize.table(sData);

		this.center 	= tData.center;
		this.radius 	= this.radius:deserialize(tData.radius);

		return this;
	end,

	setArea = function(this)
		local tFields = tProtectedRepo[this];
	end,

	setCircumference = function(this)
		local tFields = tProtectedRepo[this];
	end,

	setRadius = function(this)
		local tFields = tProtectedRepo[this];
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
};

return circle;
