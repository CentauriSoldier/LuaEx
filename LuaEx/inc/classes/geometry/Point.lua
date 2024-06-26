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

            return Point(pri.X + otherpri.X,
                         pri.Y + otherpri.Y);
        end

    end,

    __clone = function(this, cdat)
        local pri = cdat.pri;
        return Point(pri.X, pri.Y);
    end,

    __eq = function(this, other, cdat)
        local bRet = false;

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;
            bRet = pri.X == otherpri.X and pri.Y == otherpri.Y;
         end

        return bRet;
    end,

    __le = function(this, other, cdat)
        local bRet = false;

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;
            bRet = pri.X <= otherpri.X and pri.Y <= otherpri.Y;
         end

        return bRet;
    end,

    __lt = function(this, other, cdat)
        local bRet = false;

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;
            bRet = pri.X < otherpri.X and pri.Y < otherpri.Y;
         end

        return bRet;
    end,

    --[[__mul = function(this, vRight)
        local sType = type(vRight);

        if (sType == "Point") then
            this.X = this.X + vRight.X;
            this.Y = this.Y + vRight.Y;
        --elseif (sType == "table") then

        end

        return this;
    end,]]
    __serialize = function(this, cdat)
        local pri = cdat.pri;

        local tData = {
            x = pri.X,
            y = pri.Y,
        };

        return tData;
    end,
    __sub = function(this, other, cdat)

        if (type(this) == "Point" and type(other) == "Point") then
            local pri = cdat.pri;
            local otherpri = cdat.ins[other].pri;

            return Point(pri.X - otherpri.X,
                         pri.Y - otherpri.Y);
        end

    end,

    __tostring = function(this, cdat)
        local pri = cdat.pri;
        return "x: "..pri.X.." y: "..pri.Y;
    end,

    __unm = function(this, cdat)
        cdat.pri.X = -cdat.pri.X;
        cdat.pri.Y = -cdat.pri.Y;

        return this;
    end,
},
{--static public
    deserialize = function(tData)
        return Point(tData.X, tData.Y);
    end,

},
{--private
    X__auto_F = 0,
    Y__auto_F = 0,
},
{--protected

},
{--public
    --[[
    @fqxn LuaEx.Classes.Line.Point
    @desc This is the constructor for the Point class.
    @mod Point
    @param nX number The x value. If nil, it defaults to 0.
    @param nY number The y value. If nil, it defaults to 0.
    ]]
    Point = function(this, cdat, nX, nY)
        local pri = cdat.pri;
        pri.X = rawtype(nX) == "number" and nX or pri.X;
        pri.Y = rawtype(nY) == "number" and nY or pri.Y;
    end,

    --[[deserialize = function(this, cdat, sData)
        local tData = deserialize.table(sData);

        this.X = tData.X;
        this.Y = tData.Y;

        return this;
    end,]]
    get = function(this, cdat)
        local pri = cdat.pri;
        return pri.X, pri.Y;
    end,

    --[[getX = function(this, cdat)
        local pri = cdat.pri;
        return pri.X;
    end,

    getY = function(this, cdat)
        local pri = cdat.pri;
        return pri.Y;
    end,]]

    --return O, X, Y, -X, -Y, I, II, III or IV
    getQuadrant = function(this, cdat)--TODO use enum
        local pri = cdat.pri;
        local sRet      = "ERROR";
        local bYIsNeg   = pri.Y < 0;
        local bYIs0     = pri.Y == 0;
        local bYIsPos   = pri.Y > 0;--not bYIsNeg and not bYIs0;

        if (pri.X < 0) then

            if (bYIsNeg) then
                sRet = "III";
            elseif (bYIs0) then
                sRet = "-X";
            elseif (bYIsPos) then
                sRet = "II";
            end

        elseif (pri.X == 0) then

            if (bYIsNeg) then
                sRet = "-Y";
            elseif (bYIs0) then
                sRet = "O";
            elseif (bYIsPos) then
                sRet = "Y";
            end

        elseif (pri.X > 0) then

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
            nRet = math.sqrt( (this.X - oOther.X) ^ 2 + (this.Y - oOther.Y) ^ 2);
        end

        return nRet;
    end,
    ]]


    set = function(this, cdat, nX, nY)
        local pri = cdat.pri;
        pri.X = type(nX) == "number" and nX or pri.X;
        pri.Y = type(nY) == "number" and nY or pri.Y;
        return this;
    end,

    setX = function(this, cdat, nX)
        local pri = cdat.pri;
        pri.X = type(nX) == "number" and nX or pri.X;
        return this;
    end,

    setY = function(this, cdat, nY)
        local pri = cdat.pri;
        pri.Y = type(nY) == "number" and nY or pri.Y;
        return this;
    end,


    --[[deprecated...this is a line function
    slopeTo = function(this, oOther)
        local nRet = 0;

        if (type(this) == "Point" and type(oOther) == "Point") then
            nXDelta = this.X - oOther.X;
            nYDelta = this.Y - oOther.Y;

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
