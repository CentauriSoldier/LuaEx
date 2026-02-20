local math = math
local pi = math.pi
local cos = math.cos
local sin = math.sin

-- Circle Arc Primitive
return function(centerX, centerY, radius, startAngle, endAngle, bSkipFirstUpdate)
    local tActual, tDecoy, tMeta, tCenterActual, tCenterDecoy, tCenterMeta

    local bAutoUpdate = true

    tActual = {
        autoUpdate   = true,
        radius       = radius,
        startAngle   = startAngle,
        endAngle     = endAngle,
        center       = {x = centerX, y = centerY},
        length       = 0,  -- Arc Length
        area         = 0,  -- Sector Area
        update = function()
            local r = tActual.radius
            local start = tActual.startAngle
            local finish = tActual.endAngle

            -- Arc Length = radius * (theta2 - theta1)
            tActual.length = r * (finish - start)

            -- Sector Area = 0.5 * radius^2 * (theta2 - theta1)
            tActual.area = 0.5 * r * r * (finish - start)
        end
    }

    -- Center Point
    tCenterActual = {x = centerX, y = centerY}
    tCenterDecoy = {}
    tCenterMeta = {
        __index = tCenterActual,
        __newindex = function(t, k, v)
            if (tCenterActual[k] ~= nil) then
                tCenterActual[k] = v
                if (bAutoUpdate) then
                    tActual.update()
                end
            end
        end,
    }
    rawsetmetatable(tCenterDecoy, tCenterMeta)

    tActual.center = tCenterDecoy

    -- Main metatable for managing updates and properties
    tDecoy = {}
    tMeta = {
        __index = tActual,
        __newindex = function(t, k, v)
            if (k == "autoUpdate" and type(v) == "boolean") then
                bAutoUpdate = v
                tActual.autoUpdate = v
            elseif (k == "radius" or k == "startAngle" or k == "endAngle") then
                tActual[k] = v
                if (bAutoUpdate) then
                    tActual.update()
                end
            end
        end,
        __type = "primitive",
        __subtype = "circle_arc",
    }
    rawsetmetatable(tDecoy, tMeta)

    -- Initial update if not skipped
    if not (bSkipFirstUpdate) then
        tActual.update()
    end

    return tDecoy
end
