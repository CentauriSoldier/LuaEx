--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
    <h2>Point</h2>
    <p>This is a basic Point class.</p>
@license <p>The Unlicense<br>
<br>
@moduleid Point
@version 1.2
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
        <p>Feature: added serialize and deserialize methods.</p>
    </li>
    <li>
        <b>1.0</b>
        <br>
        <p>Change: created the module.</p>
    </li>
</ul>
@website https://github.com/CentauriSoldier
*]]

constant("QUADRANT_I",      "I");
constant("QUADRANT_II",     "II");
constant("QUADRANT_III",    "III");
constant("QUADRANT_IV",     "IV");
constant("QUADRANT_O",      "O");
constant("QUADRANT_X",      "X");
constant("QUADRANT_X_NEG",  "-X");
constant("QUADRANT_Y",      "Y");
constant("QUADRANT_Y_NEG",  "-Y");

--localization
local class         = class;
local serialize     = serialize;
local deserialize   = deserialize;
local type          = type;
local rawtype       = rawtype;
local math          = math;

return class("Point",
{--metamethods
    --[[
    @desc Adds two Points together.
    @func __add
    @mod Point
    @ret oPoint Point A new Point with the values of the two Points added together. If an incorrect paramters is passed, a new Point with the values of the correct paramter (the Point) is returned.
    ]]
    __add = function(this, other, cdat)

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;

            return Point(pri.x + otherpri.x,
                         pri.y + otherpri.y);
        end

    end,

    __clone = function(this, cdat)
        local pri = cdat.pri;
        return Point(pri.x, pri.y);
    end,

    __eq = function(this, other, cdat)
        local bRet = false;

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;
            bRet = pri.x == otherpri.x and pri.y == otherpri.y;
         end

        return bRet;
    end,

    __le = function(this, other, cdat)
        local bRet = false;

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;
            bRet = pri.x <= otherpri.x and pri.y <= otherpri.y;
         end

        return bRet;
    end,

    __lt = function(this, other, cdat)
        local bRet = false;

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;
            bRet = pri.x < otherpri.x and pri.y < otherpri.y;
         end

        return bRet;
    end,

    --[[__mul = function(this, vRight)
        local sType = type(vRight);

        if (sType == "Point") then
            this.x = this.x + vRight.x;
            this.y = this.y + vRight.y;
        --elseif (sType == "table") then

        end

        return this;
    end,]]
    __serialize = function(this, cdat)
        local pri = cdat.pri;

        local tData = {
            x = pri.x,
            y = pri.y,
        };

        return tData;
    end,
    __sub = function(this, other, cdat)

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;

            return Point(pri.x - otherpri.x,
                         pri.y - otherpri.y);
        end

    end,

    __tostring = function(this, cdat)
        local pri = cdat.pri;
        return "x: "..pri.x.." y: "..pri.y;
    end,

    __unm = function(this, cdat)
        cdat.pri.x = -cdat.pri.x;
        cdat.pri.y = -cdat.pri.y;

        return this;
    end,
},
{--static public
    deserialize = function(tData)
        return Point(tData.x, tData.y);
    end,

},
{--private
    x = 0,
    y = 0,
},
{--protected

},
{--public
    --[[
    @desc This is the constructor for the Point class.
    @func Point The constructor for the Point class.
    @mod Point
    @param nX number The x value. If nil, it defaults to 0.
    @param nY number The y value. If nil, it defaults to 0.
    ]]

    Point = function(this, cdat, nX, nY)
        local pri = cdat.pri;
        pri.x = rawtype(nX) == "number" and nX or pri.x;
        pri.y = rawtype(nY) == "number" and nY or pri.y;
    end,

    --[[deserialize = function(this, cdat, sData)
        local tData = deserialize.table(sData);

        this.x = tData.x;
        this.y = tData.y;

        return this;
    end,]]
    get = function(this, cdat)
        local pri = cdat.pri;
        return pri.x, pri.y;
    end,

    getX = function(this, cdat)
        local pri = cdat.pri;
        return pri.x;
    end,

    getY = function(this, cdat)
        local pri = cdat.pri;
        return pri.y;
    end,

    --return O, X, Y, -X, -Y, I, II, III or IV
    getQuadrant = function(this, cdat)--TODO use enum
        local pri = cdat.pri;
        local sRet      = "ERROR";
        local bYIsNeg   = pri.y < 0;
        local bYIs0     = pri.y == 0;
        local bYIsPos   = pri.y > 0;--not bYIsNeg and not bYIs0;

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

        if (type(this) == "Point" and type(oOther) == "Point") then
            nRet = math.sqrt( (this.x - oOther.x) ^ 2 + (this.y - oOther.y) ^ 2);
        end

        return nRet;
    end,
    ]]

    --[[!
        @desc Serializes the object's data.
        @func Point.serialize
        @module Point
        @param bDefer boolean Whether or not to return a table of data to be serialized instead of a serialize string (if deferring serializtion to another object).
        @ret sData StringOrTable The data returned as a serialized table (string) or a table is the defer option is set to true.
    !]]
    --[[serialize = function(this, cdat, bDefer)
        local pri = cdat.pri;

        local tData = {
            x = pri.x,
            y = pri.y,
        };

        if (not bDefer) then
            tData = serialize.table(tData);
        end

        return tData;
    end,]]

    set = function(this, cdat, nX, nY)
        local pri = cdat.pri;
        pri.x = type(nX) == "number" and nX or pri.x;
        pri.y = type(nY) == "number" and nY or pri.y;
        return this;
    end,

    setX = function(this, cdat, nX)
        local pri = cdat.pri;
        pri.x = type(nX) == "number" and nX or pri.x;
        return this;
    end,

    setY = function(this, cdat, nY)
        local pri = cdat.pri;
        pri.y = type(nY) == "number" and nY or pri.y;
        return this;
    end,


    --[[deprecated...this is a line function
    slopeTo = function(this, oOther)
        local nRet = 0;

        if (type(this) == "Point" and type(oOther) == "Point") then
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
nil,        --extending class
false      --if the class is final
--iCloneable, iSerializable   --interface(s) (either nil, or interface(s)) TODO readd these when serialization is complete
);
