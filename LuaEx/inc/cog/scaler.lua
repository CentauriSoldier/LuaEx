local tScaler = {
    build = {
        width   = 0,
        height  = 0,
    },
    screen = {
        width   = 0,
        height  = 0,
    },
    viewport = { --this will be scaled and centered
        width   = 0,
        height  = 0,
    },
    cov = {
        xw = 0,
        yh = 0,
    },
    coordOffset = {
        x = 0,
        y = 0,
    },
};

local scaler = {
    adjust = function(tRect)
        return {width   = tRect.width   * tScaler.cov.xw,
                height  = tRect.height  * tScaler.cov.yh,
                x       = tRect.x * tScaler.cov.xw + tScaler.coordOffset.x,
                y       = tRect.y * tScaler.cov.yh + tScaler.coordOffset.y};
    end,
    adjustSize = function(width, height)
        return {width   = width *   tScaler.cov.xw,
                height  = height *  tScaler.cov.yh};
    end,
    adjustPos = function(x, y)
        return {x   = x * tScaler.cov.xw + tScaler.viewport.x,
                y   = y * tScaler.cov.yh + tScaler.viewport.y};
    end,
    getBuildSize = function()
        return {width = tScaler.build.width, height = tScaler.build.height};
    end,
    getCOV = function()
        return {xw = tScaler.cov.xw, yh = tScaler.cov.yh};
    end,
    getScreenSize = function()
        return {width = tScaler.screen.width, height = tScaler.screen.height};
    end,
    getViewport = function()
        local tV = tScaler.viewport;
        return {width = tV.width, height = tV.height, x = tV.x, y = tV.y};
    end,
    init = function(buildWidth, buildHeight, screenWidth, screenHeight, bFullscreen)--, nAdditionalXOffset, nAdditionalYOffset)
        assert(rawtype(buildWidth)      == "number", "Build width must be of type number. Type given was '${w}'" % {w = rawtype(buildWidth)});
        assert(rawtype(buildHeight)     == "number", "Build height must be of type number. Type given was '${h}'" % {h = rawtype(buildHeight)});
        assert(rawtype(screenWidth)     == "number", "Screen width must be of type number. Type given was '${w}'" % {w = rawtype(screenWidth)});
        assert(rawtype(screenHeight)    == "number", "Screen height must be of type number. Type given was '${h}'" % {h = rawtype(screenHeight)});
        assert(buildWidth > 0,      "Build Width must be a positive number");
        assert(buildHeight > 0,     "Build Height must be a positive number");
        assert(screenWidth > 0,     "Screen Width must be a positive number");
        assert(screenHeight > 0,    "Screen Height must be a positive number");

        tScaler.build.width     = buildWidth;
        tScaler.build.height    = buildHeight;
        tScaler.screen.width    = screenWidth;
        tScaler.screen.height   = screenHeight;

        --TODO app asserts
        --configure the app window
        --tScaler.app.width   = tApp.width;
        --tScaler.app.height  = tApp.height;
        --tScaler.app.x       = tApp.x;
        --tScaler.app.y       = tApp.y;

        --configure the viewport
        tScaler.viewport = math.geometry.fitrect({width = screenWidth, height = screenHeight, x = 0, y = 0}, {width = buildWidth, height = buildHeight}, 1, true);

        tScaler.cov.xw = tScaler.viewport.width / buildWidth;
        tScaler.cov.yh = tScaler.viewport.height / buildHeight;
        --error(tScaler.cov.xw.." "..tScaler.cov.yh)

        if (bFullscreen) then
            tScaler.coordOffset.x = tScaler.viewport.x;-- + math.abs(tScaler.viewport.width - buildWidth) + (nAdditionalXOffset or 0);
            tScaler.coordOffset.y = tScaler.viewport.y;-- + math.abs(tScaler.viewport.height - buildHeight) + (nAdditionalYOffset or 0);
        end

    end,
    --[[setApp = function(tApp)--TODO asserts
        tScaler.app.width   = tApp.width;
        tScaler.app.height  = tApp.height;
        tScaler.app.x       = tApp.x;
        tScaler.app.y       = tApp.y;
    end,]]
};

return scaler;
