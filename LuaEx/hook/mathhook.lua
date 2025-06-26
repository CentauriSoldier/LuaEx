local math      = math;
local rawtype   = rawtype;
local string    = string;

math.e = math.exp(1);

--local constant = _G.__LUAEX__.constant;
--constant("MATH_ARL", 	"all real numbers");
--constant("MATH_UNDEF", 	"undefined");
--TODO complete these
local nanDivision = math.huge / math.huge;



math.allrealnumbers = setmetatable(
{
    deserialize = function()
        return math.huge + 42;
    end,
    serialize = function()
        return "inf";
    end,
},
{--TODO other metamethods
    __add = function(left, right)

        if (type(right) ~= "number") then
            error("Error: attempt to perform arithmatic on non-number type, ${rightitem} (${type})." % {type = type(right), rightitem = tostring(rightitem)});
        end

        return math.huge + 42 + right;
    end,
    __div = function(left, right)
        local vRet = "undefined";

        if (type(right) ~= "number") then
            error("Error: attempt to perform arithmatic on non-number type, ${rightitem} (${type})." % {type = type(right), rightitem = tostring(rightitem)});
        end

        if (right == math.nan) then
            vRet = math.nan;
        elseif (right == math.undefined) then
            vRet = math.undefined;
        elseif (right == math.inf) then
            vRet = 1;
        else
            vRet = (math.huge + 42) / right;
        end

        return vRet;
    end,
    __eq = function(left, right)
        return type(left) == type(right) and right == math.huge + 42;
    end,
    __le = function(left, right)
        return type(left) == type(right) and right <= math.huge + 42;
    end,
    __lt = function(left, right)
        return type(left) == type(right) and right < math.huge + 42;
    end,
    __sub = function(left, right)--TODO apply thius logic to all metatables for each math.x item
        if (type(right) ~= "number") then
            error("Error: attempt to perform arithmatic on non-number type, ${rightitem} (${type})." % {type = type(right), rightitem = tostring(rightitem)});
        end

        local vRet = math.huge + 42;

        if (right == math.nan) then
            vRet = math.nan;
        elseif (right == math.undefined) then
            vRet = math.undefined;
        elseif (right == math.inf) then
            vRet = 0;
        end

        return vRet;
    end,
    __tostring = function()
        return "inf";
    end,
    __type = "number",
    __unm = function(this)
        return -(math.huge + 42);
    end
});




math.inf = setmetatable(
{
    deserialize = function()
        return math.huge;
    end,
    serialize = function()
        return "inf";
    end,
},
{--TODO other metamethods
    __add = function(left, right)

        if (type(right) ~= "number") then
            error("Error: attempt to perform arithmatic on non-number type, ${rightitem} (${type})." % {type = type(right), rightitem = tostring(rightitem)});
        end

        return math.huge + right;
    end,
    __div = function(left, right)
        local vRet = "undefined";

        if (type(right) ~= "number") then
            error("Error: attempt to perform arithmatic on non-number type, ${rightitem} (${type})." % {type = type(right), rightitem = tostring(rightitem)});
        end

        if (right == math.nan) then
            vRet = math.nan;
        elseif (right == math.undefined) then
            vRet = math.undefined;
        elseif (right == math.inf) then
            vRet = 1;
        else
            vRet = math.huge / right;
        end

        return vRet;
    end,
    __eq = function(left, right)
        return type(left) == type(right) and right == math.huge;
    end,
    __le = function(left, right)
        return type(left) == type(right) and right <= math.huge;
    end,
    __lt = function(left, right)
        return type(left) == type(right) and right < math.huge;
    end,
    __sub = function(left, right)--TODO apply thius logic to all metatables for each math.x item
        if (type(right) ~= "number") then
            error("Error: attempt to perform arithmatic on non-number type, ${rightitem} (${type})." % {type = type(right), rightitem = tostring(rightitem)});
        end

        local vRet = math.huge;

        if (right == math.nan) then
            vRet = math.nan;
        elseif (right == math.undefined) then
            vRet = math.undefined;
        elseif (right == math.inf) then
            vRet = 0;
        end

        return vRet;
    end,
    __tostring = function()
        return "inf";
    end,
    __type = "number",
    __unm = function(this)
        return -math.huge;
    end
});



math.nan = setmetatable(
{

    deserialize = function()
        return nanDivision;
    end,
    serialize = function()
        return "nan";
    end,
},
{
    __add = function(left, right)
        return nanDivision;
    end,
    __div = function(lef, right)
        return nanDivision;
    end,
    __eq = function(left, right)
        return type(left) == type(right) and left == nanDivision and right == nanDivision;
    end,
    __le = function(left, right)
        return false;
    end,
    __lt = function(left, right)
        return false;
    end,
    __mul = function(lef, right)
        return nanDivision;
    end,
    __sub = function(left, right)
        return nanDivision;
    end,
    __tostring = function()
        return "nan";
    end,
    __type = "number",
    __unm = function(this)
        return nanDivision;
    end
});


math.undefined = setmetatable(
{
    deserialize = function()
        return math.huge / 0;
    end,
    serialize = function()
        return "undefined";
    end,
},
{

    __tostring = function()
        return "undefined";
    end,
    __type = "number",
});


function math.isabstract(vInput)
    return  type(vInput) == "number"        and
            (vInput == math.allrealnumbers  or
            vInput  == math.inf             or
            vInput  == math.nan             or
            vInput  == math.undefined       or
            vInput  == 1 / 0);
end


-- Function to convert a number from base x to base b
function math.convertbase(number, fromBase, toBase)
    -- Convert number to base 10
    local base10Number = tonumber(number, fromBase)

    -- Convert base 10 number to desired base
    local result = ""
    repeat
        local remainder = base10Number % toBase
        result = string.format("%X", remainder) .. result
        base10Number = math.floor(base10Number / toBase)
    until base10Number == 0

    return result
end

--the Eucclidian algorithm for finding the gcf
--[[local function eucclidiangcf(nDividend, nDivisor)
    local nRet = 0;

    local nRemainder = nDividend % nDivisor;
    local nQuotient	= (nDividend - nRemainder) / nDivisor;

    if (nRemainder == 0) then
        nRet = nDivisor;
    else
        nRet = eucclidiangcf(nDivisor, nRemainder);
    end

    return nRet;
end]]

local function eucclidiangcf(nDividend, nDivisor)
    local nRemainder = nDividend % nDivisor;
    local nQuotient	= (nDividend - nRemainder) / nDivisor;

    return nRemainder == 0 and nDivisor or eucclidiangcf(nDivisor, nRemainder);
end

function math.clamp(nValue, nMinValue, nMaxValue)
    local nRet = nValue;

    if (nRet < nMinValue) then
        nRet = nMinValue;
    elseif (nRet > nMaxValue) then
        nRet = nMaxValue;
    end

    return nRet;
end


function math.factorial(nVal)
    local nRet = 1;

    for x = 2, nVal do
        nRet = nRet * x;
    end

    return nRet;
end

--TODO put a safety switch in here
--gets the largest rectangle will fit within the given rectangle (then, optionally, scales it and centers it if requested)
--[[function math.fitrect(tContainer, tOriginal, nScale, bCenter)
    --this is the original container
    local nOuterWidth 	= tContainer.width;
    local nOuterHeight 	= tContainer.height;
    local nRectX 		= tContainer.x;
    local nRectY 		= tContainer.y;
    --get the container ratios
    local tWidthRatio = math.ratio(tOriginal.width, tOriginal.height);
    local tHeightRatio = math.ratio(tOriginal.height, tOriginal.width);
    --get the width and height factors
    local nWidthFactor = tWidthRatio.left / tWidthRatio.right;
    local nHeightFactor = tHeightRatio.left / tHeightRatio.right;

    --the final, resultant values
    local nWidth 		= 0;
    local nHeight 		= 0;
    --the position of the new rectangle inside the parent
    local nX			= tContainer.x;
    local nY			= tContainer.y;
    --this tells when the tested size falls outside of the parent's boundary
    local bIsSmaller	= true;
    --increments each iteration to increase the test rectangle size
    local nCounter 		= 0;
    --the values to be tested each iteration
    local nTestWidth	= nWidth;
    local nTestHeight	= nHeight;

    --check and clamp the scale value
    nScale = (type(nScale) == "number") 	and nScale or 1;
    nScale = (nScale >= 0) 					and nScale or -nScale;

    --check the center value
    bCenter = type(bCenter) == "boolean" and bCenter or false;

    while (bIsSmaller) do
        --increment the counter
        nCounter = nCounter + 1;

        --create the new test rectangle size
        nTestWidth 	= nWidthFactor  * nCounter;
        nTestHeight = nHeightFactor * nCounter;

        --check to see if it fits inside the parent...
        if (nTestWidth <= nOuterWidth and nTestHeight <= nOuterHeight) then

            --...and, store it as a valid size if it does fit
            nWidth 	= nTestWidth;
            nHeight = nTestHeight;

        else
            --...or, end the loop (using the last, viable size) if it does not fit
            bIsSmaller = false;

            --scale the rectangle
            nWidth 	= nWidth  * nScale;
            nHeight = nHeight * nScale;

            --calculate the centered position of the rectangle inside the parent
            if (bCenter) then
                nX = nRectX + (nOuterWidth 	- nWidth) 	/ 2;
                nY = nRectY + (nOuterHeight 	- nHeight) 	/ 2;
            end

        end

    end

    return {width = nWidth, height = nHeight, x = nX, y = nY};
end]]

math.geometry = {};

function math.geometry.rectcontains(tMe, tOther)
  -- Calculate the bounding coordinates for each object
  local leftMe = tMe.x
  local rightMe = tMe.x + tMe.width
  local topMe = tMe.y
  local bottomMe = tMe.y + tMe.height

  local leftOther = tOther.x
  local rightOther = tOther.x + tOther.width
  local topOther = tOther.y
  local bottomOther = tOther.y + tOther.height

  -- Check for collision by comparing the bounding coordinates
  if leftMe <= rightOther and
     rightMe >= leftOther and
     topMe <= bottomOther and
     bottomMe >= topOther then
    -- Collision detected
    local intersectionLeft = math.max(leftMe, leftOther)
    local intersectionRight = math.min(rightMe, rightOther)
    local intersectionTop = math.max(topMe, topOther)
    local intersectionBottom = math.min(bottomMe, bottomOther)

    local intersectionWidth = intersectionRight - intersectionLeft
    local intersectionHeight = intersectionBottom - intersectionTop

    return intersectionWidth > 0 and intersectionHeight > 0
  else
    -- No collision
    return false
  end

end

function math.geometry.rectcontainsfully(tMe, tOther)
    local bRet = false;

    -- Calculate the bounding coordinates for each object
    local leftMe = tMe.x
    local rightMe = tMe.x + tMe.width
    local topMe = tMe.y
    local bottomMe = tMe.y + tMe.height

    local leftOther = tOther.x
    local rightOther = tOther.x + tOther.width
    local topOther = tOther.y
    local bottomOther = tOther.y + tOther.height

    -- Check for collision by comparing the bounding coordinates
    if leftMe <= rightOther and
     rightMe >= leftOther and
     topMe <= bottomOther and
     bottomMe >= topOther then
    -- Collision detected
    bRet = true
    end

    return bRet;
end

function math.geometry.fitrect(tOuter, tInner, bCenter)
    local nInnerAspectRatio = tInner.width / tInner.height;
    local nOuterAspectRatio = tOuter.width / tOuter.height;

    local nWidth, nHeight;
    local nX = tOuter.x;
    local nY = tOuter.y;

    if (nInnerAspectRatio >= nOuterAspectRatio) then
      nWidth = tOuter.width;
      nHeight = nWidth / nInnerAspectRatio;
    else
      nHeight = tOuter.height;
      nWidth = nHeight * nInnerAspectRatio;
    end

    if (bCenter) then
      nX = tOuter.x + (tOuter.width - nWidth) / 2;
      nY = tOuter.y + (tOuter.height - nHeight) / 2;
    end

    return {width = nWidth, height = nHeight, x = nX, y = nY};
end





function math.gcf(nNum, nDen)
    local nRet 		= 1;
    local nSmall 	= 0;
    local nLarge 	= 0;

    if (nNum ~= 0 and nDen ~= 0) then
            nSmall = math.abs(nNum);
            nLarge = math.abs(nDen);

            --get the largest of the numbers
            if (nSmall > nLarge) then
                local nTemp = nSmall;
                nSmall = nLarge;
                nLarge = nTemp;
                nTemp = nil;
            end

            --perfom the Eucclidian algorithm
            nRet = eucclidiangcf(nLarge, nSmall);
        end

    return nRet;
end

function math.iseven(nValue)
    return (nValue % 2 == 0);
end

function math.isinteger(nValue)
    return (nValue == math.floor(nValue));
end

function math.isodd(nValue)--TODO check if this is an integer first
    return (nValue % 2 ~= 0);
end

function math.counting(nValue, bRaise) --natural numbers excluding zero
    local f = bRaise and math.ceil or math.floor;
    local nRet = f(math.abs(nValue));
    return nRet > 0 and nRet or 1;
end

function math.whole(nValue, bRaise) --natural numbers including zero
    local f = bRaise and math.ceil or math.floor;
    return f(math.abs(nValue));
end

function math.ratio(nLeft, nRight)
    local nGCD = math.gcf(nLeft, nRight);
    return 	{left = nLeft / nGCD, right = nRight / nGCD};
end
--TODO move these to a color module and put that module in CoG
function math.rgbtoint(nR, nG, nB)
    return nR + (nG * 256) + (nB * 65536)
end

-- Function to convert RGB values to hexadecimal color code
function math.rgbtohex(r, g, b)
    -- Ensure values are clamped between 0 and 255
    r = math.max(0, math.min(r, 255))
    g = math.max(0, math.min(g, 255))
    b = math.max(0, math.min(b, 255))

    -- Convert RGB values to hexadecimal format
    local hex = string.format("0x%02X%02X%02X", r, g, b)
    return hex
end
--[[
nR = nR;
nG = nG * 256
nB = nB * 65536
l = r + (b * 256) + (g * 65536)

x = r
y = b * 256
z = g * 65536
l = x + y + z
]]
function math.inttorgb(long_color)
    local red   = math.floor(long_color / 65536)
    local green = math.floor((long_color % 65536) / 256)
    local blue  = long_color % 256
    return red, green, blue
end

return math;
