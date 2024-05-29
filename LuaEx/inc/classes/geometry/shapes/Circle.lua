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

--localization
local class         = class;
local deserialize   = deserialize;
local math          = math;
local point         = point;
local serialize     = serialize;
local type          = type;
local shape         = shape;

local function update(pri)
    pri.area              = math.pi * pri.radius ^ 2;
    pri.circumference     = math.pi * pri.radius * 2;
end

--the unit circle
local _nStartArea           = math.pi;
local _nStartCircumference  = 2 * _nStartArea;
local _nStartRadius         = 1;

return class("Circle",
{--metamethods

},
{--static public

},
{--private
    area            = _nStartArea,
    center          = null,
    centroid        = null, --alias of center
    circumference   = _nStartCircumference,
    radius          = _nStartRadius,
},
{--protected
},
{--public
    --[[
    @desc The constructor for the circle class.
    @func circle
    @mod circle
    @ret oCircle circle A circle object. Public properties are center and radius.
    ]]
    Circle = function(this, cdat, super, pCenter, nRadius)
        super();
        local pri = cdat.pri;

        pri.center          = type(pCenter)     == "point"                      and pCenter.clone() or point();
        pri.centroid        = pri.center;     -- alias of center
        pri.radius          = (rawtype(nRadius) == "number" and nRadius >= 0)   and nRadius or pri.radius;
        pri.area            = 0;
        pri.circumference   = 0;
        update(pri);
    end,

    containsPoint = function(this, oPoint)
        local pri = cdat.pri;
        return math.sqrt( (pri.center.x - oPoint.getX()) ^ 2 + (pri.center.y - oPoint.getY()) ^ 2 ) < pri.radius;
    end,

    getArea = function(this, cdat)
        return cdat.pri.area;
    end,

    getCircumference = function(this, cdat)
        return cdat.pri.circumference;
    end,

    getPos = function(this, cdat)
        return cdat.pri.center:clone();
    end,

    getRadius = function(this, cdat)
        return cdat.pri.radius;
    end,

    --TODO FINISH
    deserialize = function(this, cdat, sData)
        local tData = deserialize.table(sData);

        this.center = tData.center;
        this.radius = this.radius:deserialize(tData.radius);

        return this;
    end,

    --TODO FINISH
    --[[!
        @desc Serializes the object's data.
        @func circle.serialize
        @module circle
        @param bDefer boolean Whether or not to return a table of data to be serialized instead of a serialize string (if deferring serializtion to another object).
        @ret sData StringOrTable The data returned as a serialized table (string) or a table is the defer option is set to true.
    !]]
    serialize = function(this, cdat, bDefer)
        local tData = {
            center = this.center.seralize(),
            radius = this.radius,
        };

        if (not bDefer) then
            tData = serialize.table(tData);
        end

        return tData;
    end,

    setArea = function(this, cdat)
        local tFields = cdat.pri;
    end,

    setCircumference = function(this, cdat)
        local tFields = cdat.pri;
    end,

    setRadius = function(this, cdat)
        local tFields = cdat.pri;
    end,

    translate = function(this, cdat, nX, nY)
        local tFields = cdat.pri;

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

    translateTo = function(this, cdat, oPoint)
        local tFields = cdat.pri;

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
},
shape,      --extending class
false,      --if the class is final
nil         --interface(s) (either nil, or interface(s))
);
