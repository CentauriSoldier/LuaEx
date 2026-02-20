return function(x, y)

    local tActual = {
        x = x or 0,
        y = y or 0,
    }

    return setmetatable({}, {
        __index = tActual,
        __newindex = function(_, k, v)

            if not (k == "x" or k == "y") then
                error("Point: cannot set field '" .. tostring(k) .. "'.", 2);
            end

            if type(v) ~= "number" then
                error("Point: '" .. k .. "' must be a number.", 2);
            end

            tActual[k] = v;
        end,
        __type      = "primitive",
        __subtype   = "point",
    })
end
