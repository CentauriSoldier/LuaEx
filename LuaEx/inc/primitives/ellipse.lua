local math = math
local sqrt = math.sqrt
local pi = math.pi

-- Ellipse Primitive
return function(centerX, centerY, majorAxis, minorAxis, bSkipFirstUpdate)
    local tActual, tDecoy, tMeta, tCenterActual, tCenterDecoy, tCenterMeta

    local bAutoUpdate = true

    tActual = {
        autoUpdate   = true,
        majorAxis    = majorAxis,
        minorAxis    = minorAxis,
        center       = {x = centerX, y = centerY},
        circumference = 0,
        area         = 0,
        update = function()
            local a = tActual.majorAxis
            local b = tActual.minorAxis

            tActual.circumference = pi * (3 * (a + b) - sqrt((3 * a + b) * (a + 3 * b)))
            tActual.area = pi * a * b
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
            elseif (k == "majorAxis" or k == "minorAxis") then
                tActual[k] = v
                if (bAutoUpdate) then
                    tActual.update()
                end
            end
        end,
        __type = "primitive",
        __subtype = "ellipse",
    }
    rawsetmetatable(tDecoy, tMeta)

    -- Initial update if not skipped
    if not (bSkipFirstUpdate) then
        tActual.update()
    end

    return tDecoy
end
