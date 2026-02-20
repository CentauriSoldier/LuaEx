local rawsetmetatable = rawsetmetatable
local math = math
local nPi = math.pi

-- Custom circle primitive
return function(nInpCenterX, nInpCenterY, nInpRadius, bSkipFirstUpdate)
    local tActual, tDecoy, tMeta, tCenterActual, tCenterDecoy, tCenterMeta
    local bAutoUpdate = true

    -- Actual circle properties
    tActual = {
        autoUpdate = true,
        radius = nInpRadius,
        diameter = 0,
        circumference = 0,
        area = 0,
        update = function()
            local nCenterX = tCenterActual.x
            local nCenterY = tCenterActual.y
            local nRadius = tActual.radius

            -- Recalculate the derived properties (centralized)
            tActual.circumference = 2 * nPi * nRadius
            tActual.area = nPi * nRadius ^ 2
            tActual.diameter = 2 * nRadius
        end,
    }

    -- Center point
    tCenterActual = { x = nInpCenterX, y = nInpCenterY }
    tCenterDecoy = {}
    tCenterMeta = {
        __index = tCenterActual,
        __newindex = function(t, k, v)
            if tCenterActual[k] ~= nil then
                tCenterActual[k] = v
                if bAutoUpdate then
                    tActual.update()  -- Recompute whenever center changes
                end
            end
        end,
    }
    rawsetmetatable(tCenterDecoy, tCenterMeta)

    tActual.center = tCenterDecoy

    -- Public decoy object for the circle
    tDecoy = {}
    tMeta = {
        __index = tActual,
        __newindex = function(t, k, v)
            if k == "autoUpdate" and rawtype(v) == "boolean" then
                tActual.autoUpdate = v
                bAutoUpdate = v
            elseif k == "radius" then
                tActual.radius = v
                if bAutoUpdate then
                    tActual.update()  -- Recompute whenever radius changes
                end
            end
        end,
        __type = "primitive",
        __subtype = "circle",
        __tostring = function()
            return string.format(
                "Circle(center: (%.2f, %.2f), radius: %.2f, diameter: %.2f, circumference: %.2f, area: %.2f)",
                tCenterActual.x, tCenterActual.y, tActual.radius, tActual.diameter, tActual.circumference, tActual.area
            )
        end,
    }
    rawsetmetatable(tDecoy, tMeta)

    -- Update the circle (if requested)
    if not bSkipFirstUpdate then
        tActual.update()  -- Ensure values are up-to-date on creation
    end

    return tDecoy
end
