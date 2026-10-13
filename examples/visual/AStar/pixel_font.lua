-- Original 5x7 glyphs. Keeps labels visible in Budo Windows builds whose Skia
-- backend has no font manager. No downloaded fonts or system dependency.
local glyphs = {
    A={14,17,17,31,17,17,17}, B={30,17,17,30,17,17,30},
    C={14,17,16,16,16,17,14}, D={30,17,17,17,17,17,30},
    E={31,16,16,30,16,16,31}, F={31,16,16,30,16,16,16},
    G={14,17,16,23,17,17,15}, H={17,17,17,31,17,17,17},
    I={14,4,4,4,4,4,14}, J={7,2,2,2,2,18,12},
    K={17,18,20,24,20,18,17}, L={16,16,16,16,16,16,31},
    M={17,27,21,21,17,17,17}, N={17,25,21,19,17,17,17},
    O={14,17,17,17,17,17,14}, P={30,17,17,30,16,16,16},
    Q={14,17,17,17,21,18,13}, R={30,17,17,30,20,18,17},
    S={15,16,16,14,1,1,30}, T={31,4,4,4,4,4,4},
    U={17,17,17,17,17,17,14}, V={17,17,17,17,17,10,4},
    W={17,17,17,21,21,21,10}, X={17,17,10,4,10,17,17},
    Y={17,17,10,4,4,4,4}, Z={31,1,2,4,8,16,31},
    ["0"]={14,17,19,21,25,17,14}, ["1"]={4,12,4,4,4,4,14},
    ["2"]={14,17,1,2,4,8,31}, ["3"]={30,1,1,14,1,1,30},
    ["4"]={2,6,10,18,31,2,2}, ["5"]={31,16,16,30,1,1,30},
    ["6"]={14,16,16,30,17,17,14}, ["7"]={31,1,2,4,8,8,8},
    ["8"]={14,17,17,14,17,17,14}, ["9"]={14,17,17,15,1,1,14},
    [" "]={0,0,0,0,0,0,0}, ["."]={0,0,0,0,0,4,4},
    [":"]={0,4,4,0,4,4,0}, ["/"]={1,1,2,4,8,16,16},
    ["-"]={0,0,0,31,0,0,0}, ["+"]={0,4,4,31,4,4,0},
    ["="]={0,0,31,0,31,0,0}, ["|"]={4,4,4,4,4,4,4},
    ["("]={2,4,8,8,8,4,2}, [")"]={8,4,2,2,2,4,8},
    [","]={0,0,0,0,4,4,8}, ["?"]={14,17,1,2,4,0,4},
    ["_"]={0,0,0,0,0,0,31}, ["'"]={4,4,8,0,0,0,0},
}
local runs = {}
for character, rows in pairs(glyphs) do
    local segments = {}
    for row, bits in ipairs(rows) do
        local column = 0
        while column < 5 do
            if bits & (1 << (4 - column)) ~= 0 then
                local start = column
                repeat column = column + 1 until column == 5 or bits & (1 << (4 - column)) == 0
                segments[#segments + 1] = {start, row - 1, column - start}
            else column = column + 1 end
        end
    end
    runs[character] = segments
end
return function(canvas, value, x, baseline, size)
    local pixel = size / 9
    for character in value:upper():gmatch(".") do
        for _, run in ipairs(runs[character] or runs["?"]) do
            canvas.drawRect(x + run[1] * pixel, baseline - 7 * pixel + run[2] * pixel,
                run[3] * pixel, pixel)
        end
        x = x + 6 * pixel
    end
end
