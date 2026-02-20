local rawsetmetatable   = rawsetmetatable
local math              = math
local sqrt              = math.sqrt
local nPi               = math.pi

-- Custom circle primitive
return function(nInpCenterX, nInpCenterY, nInpRadius, bSkipFirstUpdate)
    local   tActual,        tDecoy,         tMeta,
            tCenterActual, tCenterDecoy,    tCenterMeta;

    local bAutoUpdate = true

    tActual = {
        autoUpdate   = true,
        radius          = nInpRadius,
        diameter        = 0,
        circumference   = 0,
        area            = 0,
        update = function()
            local nCenterX = tCenterActual.x
            local nCenterY = tCenterActual.y
            local nRadius  = tActual.radius

            tActual.circumference   = 2 * nPi * nRadius;
            tActual.area            = nPi * nRadius ^ 2;
            tActual.diameter        = 2 * nRadius;
        end,
    };

    -- Center point
    tCenterActual  = {
        x = nInpCenterX,
        y = nInpCenterY,
    };
    tCenterDecoy   = {};
    tCenterMeta    = {
        __index = tCenterActual,
        __newindex = function(t, k, v)
            if (tCenterActual[k] ~= nil) then
                tCenterActual[k] = v;
            end

        end,
    };
    rawsetmetatable(tCenterDecoy, tCenterMeta);

    tActual.center = tCenterDecoy;

    tDecoy    = {};
    tMeta     = {
        __index     = tActual,
        __newindex  = function(t, k, v)
            if (k == "autoUpdate" and rawtype(v) == "boolean") then
                tActual.autoUpdate = v;
                bAutoUpdate = v;

            elseif (k == "radius") then
                tActual.radius = v;

                if (bAutoUpdate) then
                    local nCenterX = tCenterActual.x;
                    local nCenterY = tCenterActual.y;

                    tActual.circumference   = 2 * nPi * v;
                    tActual.diameter        = 2 * v;
                    tActual.area            = nPi * v ^ 2;
                end

            end

        end,
        __type      = "primitive",
        __subtype   = "circle",
    };
    rawsetmetatable(tDecoy, tMeta);

    -- Update the circle (if requested)
    if not (bSkipFirstUpdate) then
        local nCenterX = tCenterActual.x
        local nCenterY = tCenterActual.y
        local nRadius  = tActual.radius

        tActual.circumference   = 2 * nPi * nRadius;
        tActual.area            = nPi * nRadius ^ 2;
        tActual.diameter        = 2 * nRadius;
    end

    return tDecoy;
end
