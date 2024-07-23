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
local rawtype       = rawtype;
local serialize     = serialize;
local type          = type;
local shape         = shape;
local nPi           = math.pi;

--the unit circle
local _nStartArea           = nPi;
local _nStartCircumference  = 2 * _nStartArea;
local _nStartRadius         = 1;

return class("Circle",
{--metamethods

},
{--static public
    deserialize = function(sData)--TODO FINISH
        local tData = deserialize.table(sData);

        this.center = tData.center;
        this.radius = this.radius:deserialize(tData.radius);

        return this;
    end,
},
{--private
},
{--protected
    area            = _nStartArea,
    center          = {x = 0, y = 0},
    centroid        = null, --alias of center
    circumference   = _nStartCircumference,
    radius          = _nStartRadius,
},
{--public
    --[[
    @fqxn LuaEx.Classes.Geometry.circle
    @desc The constructor for the circle class.
    @ret oCircle circle A circle object. Public properties are center and radius.
    ]]
    Circle = function(this, cdat, super, oCenter, nRadius)
        super();
        local pro = cdat.pro;

        if (type(pCenter) == "point") then
            local tCenter = pro.center;
            tCenter.x = oCenter.getX();
            tCenter.y = oCenter.getY();
        end

        pro.centroid = pro.center; --alias of center

        if (rawtype(nRadius) == "number" and nRadius > 0) then
            pro.radius = nRadius;
        end

        pro.area          = nPi * nRadius ^ 2;
        pro.circumference = nPi * nRadius * 2;
    end,

    containsCoords = function(this, nX, nY)
        local pro       = cdat.pro;
        local oCenter   = pro.center;

        return (rawtype(nX) == "number" and rawtype(nY) == "number") and
        math.sqrt( (oCenter.x - nX) ^ 2 + (oCenter.y - nY) ^ 2 ) < pro.radius;
    end,

    containsPoint = function(this, oPoint)
        local pro       = cdat.pro;
        local oCenter   = pro.center;
        return (rawtype(oPoint) == "Point") and
        math.sqrt( (oCenter.x - oPoint.getX()) ^ 2 + (oCenter.y - oPoint.getY()) ^ 2 ) < pro.radius;
    end,

    getArea = function(this, cdat)
        return cdat.pro.area;
    end,

    getCircumference = function(this, cdat)
        return cdat.pro.circumference;
    end,

    getPos = function(this, cdat)
        local tCenter = cdat.pro.center;
        return {x = tCenter.x, y = tCenter.y};
    end,

    getRadius = function(this, cdat)
        return cdat.pro.radius;
    end,

    setArea = function(this, cdat, nArea)

        if not (rawtype(nArea) == "number") then
            error("Area must be of type number.\nGot type: "..rawtype(nArea));
        end

        if (nArea <= 0) then
            error("Area must be a positive value.\nGot: "..nArea);
        end

        local pro           = cdat.pro;
        pro.area            = nArea;
        pro.radius          = math.sqrt(nArea / nPi);
        pro.circumference   = 2 * nPi * pro.radius;
    end,

    setCircumference = function(this, cdat, nCircumference)
        if not (rawtype(nCircumference) == "number") then
            error("Error setting circle radius. Radius must of type number.\nGot type: "..rawtype(nCircumference));
        end

        if (nCircumference <= 0) then
            error("Error setting circle radius. Radius must a positive value.\nGot: "..nCircumference);
        end

        local pro           = cdat.pro;
        pro.circumference   = nCircumference;
        pro.radius          = nCircumference / (nPi * 2);
        pro.area            = nPi * pro.radius ^ 2;
    end,

    setRadius = function(this, cdat, nRadius)

        if not (rawtype(nRadius) == "number") then
            error("Error setting circle radius. Radius must of type number.\nGot type: "..rawtype(nRadius));
        end

        if (nRadius <= 0) then
            error("Error setting circle radius. Radius must a positive value.\nGot: "..nRadius);
        end

        local pro = cdat.pro;
        pro.radius        = nRadius;
        pro.area          = nPi * nRadius ^ 2;
        pro.circumference = nPi * nRadius * 2;
    end,

    translate = function(this, cdat, nX, nY)
        local tCenter = cdat.pro.center;

        if not (rawtype(nX) == "number" and rawtype(nY) == "number") then
            error("Error translating circle position. X and Y values must be of type number.\nGot types:\nx: "..rawtype(nX)..' | y: '..rawtype(nY));
        end

        tCenter.x = tCenter.x + nX;
        tCenter.y = tCenter.y + nY;

        return this;
    end,

    translateTo = function(this, cdat, nX, nY)
        local tCenter = cdat.pro.center;

        if not (rawtype(nX) == "number" and rawtype(nY) == "number") then
            error("Error translating circle position. X and Y values must be of type number.\nGot types:\nx: "..rawtype(nX)..' | y: '..rawtype(nY));
        end

        tCenter.x = nX;
        tCenter.y = nY;

        return this;
    end,
},
Shape, --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
