local rawsetmetatable   = rawsetmetatable;
local math              = math;
local sqrt              = math.sqrt;
local atan2             = math.atan2;
local nPi               = math.pi;

--custom line primitive
return function(nInpStartX, nInpStartY, nInpStopX, nInpStopY, bSkipFirstUpdate)
    local   tActual,        tDecoy,         tMeta,
            tStartActual,   tStartDecoy,    tStartMeta,
            tStopActual,    tStopDecoy,     tStopMeta;

    local bAutoCalculate = true;

    tActual = {
        autoCalculate               = true,
        start                       = {x = 0, y = 0},
        stop                        = {x = 0, y = 0},
        midpoint                    = {x = 0, y = 0},
        a = 0,
        b = 0,
        c = 0,
        deltaX                      = 0,
        deltaY                      = 0,
        isHorizontal                = 0,
        isVertical                  = 0,
        length                      = 0,
        slope                       = 0,
        slopeIsUndefined            = true,
        theta                       = 0,
        yIntercept                  = 0,
        yInterceptIsUndefined       = true,
        xIntercept                  = 0,
        xInterceptIsUndefined       = true,
    };

    --start point
    tStartActual  = {x = nInpStartX, y = nInpStartY};
    tStartDecoy   = {};
    tStartMeta    = {
        __index = tStartActual,
        __newindex = function(t, k, v)

            if (tStartActual[k] ~= nil) then
                tStartActual[k] = v;

                if (bAutoCalculate) then
                    local nStartX = tStartActual.x;
                    local nStartY = tStartActual.y;
                    local nStopX  = tStopActual.x;
                    local nStopY  = tStopActual.y;
                    local bXsSame = nStartX == nStopX;

                    local vSlope                    = bXsSame and "undefined" or (nStopY - nStartY) / (nStopX - nStartX);
                    tActual.slope                   = vSlope;
                    tActual.slopeIsUndefined        = vSlope == "undefined";
                    tActual.a                       = vSlope;
                    tActual.b                       = bXsSame and "undefined" or (nStartY - tActual.a * nStartX);
                    tActual.c                       = bXsSame and "undefined" or - (tActual.a * nStartX + tActual.b);
                    tActual.midpoint.x              = (nStartX + nStopX) / 2;
                    tActual.midpoint.y              = (nStartY + nStopY) / 2;
                    tActual.deltaX                  = nStopX - nStartX;
                    tActual.deltaY                  = nStopY - nStartY;
                    tActual.length                  = sqrt( (nStartX - nStopX) ^ 2 + (nStartY - nStopY) ^ 2);
                    tActual.isHorizontal            = tActual.a == 0;
                    tActual.isVertical              = bXsSame;
                    tActual.theta                   = bXsSame and (nPi / 2) or atan2(nStopY - nStartY, nStopX - nStartX);
                    tActual.yIntercept              = bXsSame and "undefined" or tActual.b;
                    tActual.yInterceptIsUndefined   = tActual.yIntercept == "undefined";
                    tActual.xIntercept              = bXsSame and nStartX or (tActual.a == 0 and "undefined" or -tActual.b / tActual.a);
                    tActual.xInterceptIsUndefined   = tActual.xIntercept == "undefined";
                end

            end

        end,
    };
    rawsetmetatable(tStartDecoy, tStartMeta);

    --stop point
    tStopActual   = {x = nInpStopX, y = nInpStopY};
    tStopDecoy    = {};
    tStopMeta     = {
        __index = tStopActual,
        __newindex = function(t, k, v)

            if (tStopActual[k] ~= nil) then
                tStopActual[k] = v;

                if (bAutoCalculate) then
                    local nStartX = tStartActual.x;
                    local nStartY = tStartActual.y;
                    local nStopX  = tStopActual.x;
                    local nStopY  = tStopActual.y;
                    local bXsSame = nStartX == nStopX;

                    local vSlope                    = bXsSame and "undefined" or (nStopY - nStartY) / (nStopX - nStartX);
                    tActual.slope                   = vSlope;
                    tActual.slopeIsUndefined        = vSlope == "undefined";
                    tActual.a                       = vSlope;
                    tActual.b                       = bXsSame and "undefined" or (nStartY - tActual.a * nStartX);
                    tActual.c                       = bXsSame and "undefined" or - (tActual.a * nStartX + tActual.b);
                    tActual.midpoint.x              = (nStartX + nStopX) / 2;
                    tActual.midpoint.y              = (nStartY + nStopY) / 2;
                    tActual.deltaX                  = nStopX - nStartX;
                    tActual.deltaY                  = nStopY - nStartY;
                    tActual.length                  = sqrt( (nStartX - nStopX) ^ 2 + (nStartY - nStopY) ^ 2);
                    tActual.isHorizontal            = tActual.a == 0;
                    tActual.isVertical              = bXsSame;
                    tActual.theta                   = bXsSame and (nPi / 2) or atan2(nStopY - nStartY, nStopX - nStartX);
                    tActual.yIntercept              = bXsSame and "undefined" or tActual.b;
                    tActual.yInterceptIsUndefined   = tActual.yIntercept == "undefined";
                    tActual.xIntercept              = bXsSame and nStartX or (tActual.a == 0 and "undefined" or -tActual.b / tActual.a);
                    tActual.xInterceptIsUndefined   = tActual.xIntercept == "undefined";
                end

            end

        end,
    };
    rawsetmetatable(tStopDecoy, tStopMeta);

    --line
    tActual.start   = tStartDecoy;
    tActual.stop    = tStopDecoy;
    tActual.update  = function()
        local nStartX = tStartActual.x;
        local nStartY = tStartActual.y;
        local nStopX  = tStopActual.x;
        local nStopY  = tStopActual.y;
        local bXsSame = nStartX == nStopX;

        local vSlope                    = bXsSame and "undefined" or (nStopY - nStartY) / (nStopX - nStartX);
        tActual.slope                   = vSlope;
        tActual.slopeIsUndefined        = vSlope == "undefined";
        tActual.a                       = vSlope;
        tActual.b                       = bXsSame and "undefined" or (nStartY - tActual.a * nStartX);
        tActual.c                       = bXsSame and "undefined" or - (tActual.a * nStartX + tActual.b);
        tActual.midpoint.x              = (nStartX + nStopX) / 2;
        tActual.midpoint.y              = (nStartY + nStopY) / 2;
        tActual.deltaX                  = nStopX - nStartX;
        tActual.deltaY                  = nStopY - nStartY;
        tActual.length                  = sqrt( (nStartX - nStopX) ^ 2 + (nStartY - nStopY) ^ 2);
        tActual.isHorizontal            = tActual.a == 0;
        tActual.isVertical              = bXsSame;
        tActual.theta                   = bXsSame and (nPi / 2) or atan2(nStopY - nStartY, nStopX - nStartX);
        tActual.yIntercept              = bXsSame and "undefined" or tActual.b;
        tActual.yInterceptIsUndefined   = tActual.yIntercept == "undefined";
        tActual.xIntercept              = bXsSame and nStartX or (tActual.a == 0 and "undefined" or -tActual.b / tActual.a);
        tActual.xInterceptIsUndefined   = tActual.xIntercept == "undefined";
    end

    tDecoy    = {};
    tMeta     = {
        __index     = tActual,
        __newindex  = function(t, k, v)

            if (k == "autoCalculate" and rawtype(v) == "boolean") then
                tActual.autoCalculate = v;
                bAutoCalculate = v;
            end

        end,
        __type      = "primitive",
        __subtype   = "line",
    };
    rawsetmetatable(tDecoy, tMeta);

    --update the line (if requested)
    if not (bSkipFirstUpdate) then
        tActual.update();
    end

    --return it
    return tDecoy;
end
