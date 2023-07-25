local math = math;
--local constant = _G.__LUAEX__.constant;
constant("MATH_ARL", 	"all real numbers");
constant("MATH_INF", 	"infinite");
constant("MATH_NAN", 	"not a number");
constant("MATH_UNDEF", 	"undefined");

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
  local leftMe = tMe.X
  local rightMe = tMe.X + tMe.Width
  local topMe = tMe.Y
  local bottomMe = tMe.Y + tMe.Height

  local leftOther = tOther.X
  local rightOther = tOther.X + tOther.Width
  local topOther = tOther.Y
  local bottomOther = tOther.Y + tOther.Height

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
    local leftMe = tMe.X
      local rightMe = tMe.X + tMe.Width
      local topMe = tMe.Y
      local bottomMe = tMe.Y + tMe.Height

      local leftOther = tOther.X
      local rightOther = tOther.X + tOther.Width
      local topOther = tOther.Y
      local bottomOther = tOther.Y + tOther.Height

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
function math.rgbtolong(nR, nG, nB)
	return nR + (nG * 256) + (nB * 65536);
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
--TODO fix this! the math is wrong...find a good example
function math.longtorgb(nLong)
	local b = nLong / 65536;
	--local g = (nLong - b * 65536) / 256;
	local g = (nLong / 256) - b;
 	--local r	= nLong - b * 65536 - g * 256;
	local r = nLong - g - b;
	return r, g, b;
	--[[
	local nBlue		= math.floor(nValue / 65536);
	local nGreen 	= math.floor((nValue % 65536) / 256);
	local nRed		= nValue % 256;

	return {
		r = nRed,
		g = nGreen,
		b = nBlue,
	};]]
end

return math;
