local sqrt      = math.sqrt
local atan2     = math.atan2
local pi        = math.pi
local abs       = math.abs
local type      = type;
local rawtype   = rawtype;

local EPSILON = 1e-10

return function(vX1, vY1, vX2, vY2, bSkipFirstUpdate)

    if  type(vX1) == "primitive" and subtype(vX1) == "point" and
        type(vY1) == "primitive" and subtype(vY1) == "point" then

        local pStart = vX1
        local pStop  = vY1

        bSkipFirstUpdate = rawtype(vX2) == "boolean" and vX2 or false;

        vX1, vY1 = pStart.x, pStart.y
        vX2, vY2 = pStop.x,  pStop.y
    end

    local tActual = {
        autoUpdate = true,
        start = { x = nX1, y = nY1 },
        stop  = { x = nX2, y = nY2 },
        midpoint = { x = 0, y = 0 },

        -- derived values
        a = nil,
        b = nil,
        c = nil,
        deltaX = 0,
        deltaY = 0,
        length = 0,
        slope = nil,
        slopeIsUndefined = false,
        isHorizontal = false,
        isVertical = false,
        theta = 0,
        yIntercept = nil,
        yInterceptIsUndefined = false,
        xIntercept = nil,
        xInterceptIsUndefined = false,
    }

    local autoUpdate = true

    -- Centralized recompute logic
    local function recompute()

        local sx, sy = tActual.start.x, tActual.start.y
        local ex, ey = tActual.stop.x,  tActual.stop.y

        local dx = ex - sx
        local dy = ey - sy

        tActual.deltaX = dx
        tActual.deltaY = dy
        tActual.length = sqrt(dx*dx + dy*dy)
        tActual.midpoint.x = (sx + ex) * 0.5
        tActual.midpoint.y = (sy + ey) * 0.5

        local vertical = abs(dx) < EPSILON
        local horizontal = abs(dy) < EPSILON

        tActual.isVertical = vertical
        tActual.isHorizontal = horizontal

        if vertical then
            tActual.slope = nil
            tActual.slopeIsUndefined = true
            tActual.a = nil
            tActual.b = nil
            tActual.c = nil

            tActual.yIntercept = nil
            tActual.yInterceptIsUndefined = true

            tActual.xIntercept = sx
            tActual.xInterceptIsUndefined = false

            tActual.theta = pi * 0.5
        else
            local slope = dy / dx

            tActual.slope = slope
            tActual.slopeIsUndefined = false
            tActual.a = slope

            local b = sy - slope * sx
            tActual.b = b
            tActual.c = -(slope * sx + b)

            tActual.yIntercept = b
            tActual.yInterceptIsUndefined = false

            if horizontal then
                tActual.xIntercept = nil
                tActual.xInterceptIsUndefined = true
            else
                tActual.xIntercept = -b / slope
                tActual.xInterceptIsUndefined = false
            end

            tActual.theta = atan2(dy, dx)
        end
    end

    -- Reactive proxy for endpoints
    local function makePointProxy(point)

        return setmetatable({}, {
            __index = point,
            __newindex = function(_, k, v)
                if k == "x" or k == "y" then
                    point[k] = v
                    if autoUpdate then
                        recompute()
                    end
                end
            end
        })
    end

    tActual.start = makePointProxy(tActual.start)
    tActual.stop  = makePointProxy(tActual.stop)

    tActual.update = recompute

    local tPublic = setmetatable({}, {
        __index = tActual,
        __newindex = function(_, k, v)
            if k == "autoUpdate" and type(v) == "boolean" then
                autoUpdate = v
                tActual.autoUpdate = v
            end
        end,
        __tostring = function()
            return string.format("Line(start: (%.2f, %.2f), stop: (%.2f, %.2f), length: %.2f, slope: %.2f, theta: %.2f)",
            tActual.start.x, tActual.start.y,
            tActual.stop.x, tActual.stop.y,
            tActual.length, tActual.slope or 0, tActual.theta);
        end
    })

    if not bSkipFirstUpdate then
        recompute();
    end

    return tPublic
end
