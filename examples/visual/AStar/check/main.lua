local source = debug.getinfo(1, "S").source:gsub("^@", "")
local directory = source:match("^(.*)[/\\]") or "."
dofile(directory .. "/../smoke.lua")
-- Exercise the real renderer and UI event handlers with deterministic input.
local requestFrame = sys.animation.requestFrame
local getInput = sys.input.get
local keyPressed = sys.input.isKeyPressed
local frameNumber = 0
local clicks = {
    {140, 98}, -- wall tool
    {116, 180}, -- paint cell
    {32, 138}, -- play
    {120, 138}, -- step
    {202, 138}, -- turn
    {294, 138}, -- reset
    {456, 138}, -- save
    {370, 138}, -- random
    {542, 138}, -- load
    {630, 138}, -- slow
    {710, 138}, -- fast
}
sys.input.isKeyPressed = function() return false end
sys.input.get = function()
    local input = getInput()
    local click = clicks[frameNumber]
    input.focused = true
    input.totalTime = frameNumber
    local scale = math.min(sys.window.getWidth() / 1120, sys.window.getHeight() / 800)
    input.mouse.x = click and click[1] * scale or 0
    input.mouse.y = click and click[2] * scale or 0
    input.mouse.leftPressed = click ~= nil
    input.mouse.left = click ~= nil
    input.mouse.right = false
    return input
end
sys.animation.requestFrame = function(callback)
    requestFrame(function()
        frameNumber = frameNumber + 1
        local ok, message = pcall(callback)
        if not ok then print("FAIL render: " .. tostring(message)); sys.exit(1); return end
        if frameNumber == #clicks + 1 then
            local saved = sys.files.readText("files/map.luaex")
            assert(saved and #saved > 0, "UI save did not create a snapshot")
            local Model = require("examples.visual.AStar.model")
            Model.new().restore(saved)
            if os.getenv("LUAEX_ASTAR_CAPTURE") then
                local image = sys.canvas.readPixels()
                print("CAPTURE", type(image), type(image.pixels), image.width, image.height)
                if type(image.pixels) == "string" then
                    local output = assert(io.open(os.getenv("LUAEX_ASTAR_CAPTURE"), "wb"))
                    output:write(string.pack("<c2I4I2I2I4I4i4i4I2I2I4I4i4i4I4I4",
                        "BM", 54 + #image.pixels, 0, 0, 54, 40, image.width, -image.height,
                        1, 32, 0, #image.pixels, 2835, 2835, 0, 0))
                    output:write((image.pixels:gsub("(.)(.)(.)(.)", "%3%2%1%4")))
                    output:close()
                end
            end
            print("PASS Budo rendering and UI: paint, play, step, turn, reset, random, save/load, speed")
            sys.exit(0)
        end
    end)
end
dofile(directory .. "/../main.lua")
