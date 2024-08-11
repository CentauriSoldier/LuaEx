local assert    = assert;
local class     = class;
local math      = math;
local rawtype   = rawtype;
local fitrect   = math.geometry.fitrect;

return class("Scaler",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Scaler = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    buildWidth      = 0,
    buildHeight     = 0,
    screenWidth     = 0,
    screenHeight    = 0,
    viewportWidth   = 0, --this will be scaled and centered
    viewportHeight  = 0, --this will be scaled and centered
    viewportX       = 0, --this will be scaled and centered
    viewportY       = 0, --this will be scaled and centered
    covXW           = 0,
    covYH           = 0,
    coordOffsetX    = 0,
    coordOffsetY    = 0,
},
{--PUBLIC
    Scaler = function(this, cdat, nBuildWidth, nBuildHeight, nScreenWidth, nScreenHeight, bFullscreen)--, nAdditionalXOffset, nAdditionalYOffset)
        local pro = cdat.pro;
        assert(rawtype(nBuildWidth)     == "number", "Build width must be of type number. Type given was '${w}'"      % {w = rawtype(nBuildWidth)});
        assert(rawtype(nBuildHeight)    == "number", "Build height must be of type number. Type given was '${h}'"     % {h = rawtype(nBuildHeight)});
        assert(rawtype(nScreenWidth)    == "number", "Screen width must be of type number. Type given was '${w}'"     % {w = rawtype(nScreenWidth)});
        assert(rawtype(nScreenHeight)   == "number", "Screen height must be of type number. Type given was '${h}'"    % {h = rawtype(nScreenHeight)});
        assert(nBuildWidth      > 0, "Build Width must be a positive number");
        assert(nBuildHeight     > 0, "Build Height must be a positive number");
        assert(nScreenWidth     > 0, "Screen Width must be a positive number");
        assert(nScreenHeight    > 0, "Screen Height must be a positive number");

        pro.buildWidth   = nBuildWidth;
        pro.buildHeight  = nBuildHeight;
        pro.screenWidth  = nScreenWidth;
        pro.screenHeight = nScreenHeight;

        --TODO app asserts
        --configure the app window
        --tScaler.app.width   = tApp.width;
        --tScaler.app.height  = tApp.height;
        --tScaler.app.x       = tApp.x;
        --tScaler.app.y       = tApp.y;

        --configure the viewport
        local tViewport = fitrect({width = nScreenWidth, height = nScreenHeight, x = 0, y = 0}, {width = nBuildWidth, height = nBuildHeight}, 1, true);

        local nViewportWidth    = tViewport.width;
        local nViewportHeight   = tViewport.height;
        local nViewportX        = tViewport.x;
        local nViewportY        = tViewport.y;

        pro.viewportWidth   = nViewportWidth;
        pro.viewportHeight  = nViewportHeight;
        pro.viewportX       = nViewportX;
        pro.viewportY       = nViewportY;

        pro.covXW = nViewportWidth  / nBuildWidth;
        pro.covYH = nViewportHeight / nBuildHeight;

        if (bFullscreen) then
            pro.coordOffsetX = nViewportX;-- + math.abs(tScaler.viewport.width - nBuildWidth) + (nAdditionalXOffset or 0);
            pro.coordOffsetY = nViewportY;-- + math.abs(tScaler.viewport.height - nBuildHeight) + (nAdditionalYOffset or 0);
        end
    end,
    adjust = function(this, cdat, tRect)
        local pro = cdat.pro;
        local nCOV_XW = pro.covXW;
        local nCOV_YH = pro.covYH;

        return {width   = tRect.width   * nCOV_XW,
                height  = tRect.height  * nCOV_YH,
                x       = tRect.x * nCOV_XW + pro.coordOffsetX,
                y       = tRect.y * nCOV_YH + pro.coordOffsetY};
    end,
    adjustSize = function(this, cdat, width, height)
        local pro = cdat.pro;
        return {width   = width *   pro.covXW,
                height  = height *  pro.covYH};
    end,
    adjustPos = function(this, cdat, x, y)
        local pro = cdat.pro;
        return {x   = x * pro.covXW + pro.viewportX,
                y   = y * pro.covYH + pro.viewportY};
    end,
    getBuildSize = function(this, cdat)
        local pro = cdat.pro;
        return {width = pro.buildWidth, height = pro.buildHeight};
    end,
    getCOV = function(this, cdat)
        local pro = cdat.pro;
        return {xw = pro.covXW, yh = pro.covYH};
    end,
    getScreenSize = function(this, cdat)
        local pro = cdat.pro;
        return {width = pro.viewportWidth, height = pro.viewportHeight};
    end,
    getViewport = function(this, cdat)
        local pro   = cdat.pro;
        return {width = pro.viewportWidth, height = pro.viewportHeight, x = pro.viewportX, y = pro.viewportY};
    end,
    onResize = function(this, cdat)

    end,
    setOnResizeCallback = function(this, cdat, fCallback)

    end
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
