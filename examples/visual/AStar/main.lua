local source = debug.getinfo(1, "S").source:gsub("^@", "")
local directory = source:match("^(.*)[/\\]") or "."
package.path = directory .. "/../../../?.lua;" .. package.path
local Model = require("examples.visual.AStar.model")
local demo = Model.new()
local canvas = sys.canvas
local drawText = dofile(directory .. "/pixel_font.lua")
local tool, playing, nextStep, painted = "WALL", false, 0, nil
local colors = {"#28394A", "#111923", "#75633D", "#655775", "#D4BB77", "#4D7855", "#997652"}
local buttons = {}
local function text(value, x, y, size, color)
    canvas.setFillColor(color or "#DCE6F0")
    drawText(canvas, tostring(value), x, y, size or 15)
end
local function rect(x, y, w, h, color)
    canvas.setFillColor(color); canvas.drawRect(x, y, w, h)
end
local function action(name)
    if name == "PLAY" then playing = not playing
    elseif name == "STEP" then playing = false; demo.step()
    elseif name == "TURN" then demo.cycle()
    elseif name == "RESET" then playing = false; demo.reset(false)
    elseif name == "RANDOM" then playing = false; demo.reset(true)
    elseif name == "SAVE" then
        assert(sys.files.writeText("files/map.luaex", demo.snapshot()), sys.files.getError())
        demo.status = "Saved map.luaex (terrain and endpoints)"
    elseif name == "LOAD" then
        local saved = sys.files.readText("files/map.luaex")
        assert(saved, "Save a map first")
        playing = false; demo.restore(saved); demo.status = "Map restored; movement reset"
    elseif name == "SLOW" then demo.speed.decrease()
    elseif name == "FAST" then demo.speed.increase()
    else playing = false; tool = name end
end
local function safeAction(name)
    local ok, message = pcall(action, name)
    if not ok then demo.status = "Error: " .. tostring(message); playing = false end
end
local function frame()
    local input = sys.input.get()
    local width, height = sys.window.getWidth(), sys.window.getHeight()
    local scale = math.min(width / 1120, height / 800)
    if scale <= 0 then sys.animation.requestFrame(frame); return end
    local mx, my = input.mouse.x / scale, input.mouse.y / scale
    if input.mouse.leftPressed then
        for _, button in ipairs(buttons) do
            if mx >= button.x and mx < button.x + button.w and my >= button.y and my < button.y + 32 then
                safeAction(button.name); break
            end
        end
    end
    local x, y = math.floor((mx - 24) / 37) + 1, math.floor((my - 164) / 37) + 1
    if input.focused and (input.mouse.left or input.mouse.right) and x >= 1 and x <= demo.width and y >= 1 and y <= demo.height then
        local key = x .. ":" .. y .. ":" .. tool
        if key ~= painted then
            playing = false
            demo.edit(x, y, input.mouse.right and "GROUND" or tool)
            painted = key
        end
    else painted = nil end
    if sys.input.isKeyPressed(44) then safeAction("PLAY") end -- Space
    if sys.input.isKeyPressed(17) then safeAction("STEP") end -- N
    if sys.input.isKeyPressed(23) then safeAction("TURN") end -- T
    if playing and input.focused and input.totalTime >= nextStep then
        nextStep = input.totalTime + 1 / demo.speed.getPos()
        if not demo.step() then playing = false end
    end
    canvas.clear("#101923")
    canvas.save(); canvas.scale(scale, scale)
    text("LuaEx / AStar laboratory", 24, 38, 27, "#FFFFFF")
    text("Paint terrain, plan a group route, then spend movement points one step at a time.", 24, 65)
    buttons = {}
    local function button(name, label, bx, by, bw, selected)
        buttons[#buttons + 1] = {name = name, x = bx, y = by, w = bw}
        rect(bx, by, bw, 32, selected and "#287C83" or "#243547")
        text(label, bx + 9, by + 22, 14)
    end
    local tools = {"GROUND", "WALL", "MARSH", "ROCK", "START", "GOAL"}
    for index, name in ipairs(tools) do button(name, name, 24 + (index - 1) * 100, 82, 92, tool == name) end
    local controls = {"PLAY", "STEP", "TURN", "RESET", "RANDOM", "SAVE", "LOAD", "SLOW", "FAST"}
    for index, name in ipairs(controls) do
        button(name, name == "PLAY" and (playing and "PAUSE" or "PLAY") or name,
            24 + (index - 1) * 84, 122, 77, name == "PLAY" and playing)
    end
    local route = {}
    for index, node in ipairs(demo.path.getNodes()) do route[node] = demo.path.getCycleForNode(index) end
    for cy = 1, demo.height do
        for cx = 1, demo.width do
            local node = demo.map.getNode("ground", cx, cy)
            local px, py = 24 + (cx - 1) * 37, 164 + (cy - 1) * 37
            rect(px, py, 35, 35, colors[demo.cells[cy][cx]])
            if demo.trail[node] then rect(px + 3, py + 3, 29, 29, "#36536D") end
            if route[node] ~= nil then
                local cycle = route[node]
                rect(px + 7, py + 7, 21, 21, cycle == 0 and "#43BBA1" or "#CFAB57")
                if not (cx == demo.goal.x and cy == demo.goal.y) and node ~= demo.soldier.getOwner() then
                    text(cycle, px + 13, py + 23, 12, "#10221E")
                end
            end
            if cx == demo.start.x and cy == demo.start.y and node ~= demo.soldier.getOwner() then
                text("S", px + 11, py + 24, 19, "#FFFFFF")
            end
            if cx == demo.goal.x and cy == demo.goal.y then text("G", px + 11, py + 24, 19, "#FFFFFF") end
            if node == demo.soldier.getOwner() then
                canvas.setFillColor("#FFFFFF"); canvas.drawCircle(px + 11, py + 17, 5)
                canvas.setFillColor("#80BFFF"); canvas.drawCircle(px + 24, py + 17, 5)
            end
        end
    end
    local sx = 793
    text("GROUP TELEMETRY", sx, 191, 18, "#FFFFFF")
    text("Soldier + scout move together", sx, 218)
    text("Turn " .. demo.turn .. "    Steps " .. demo.moves, sx, 246)
    text("Soldier MP: " .. demo.soldier.getMovePoints() .. " / 40", sx, 283)
    text("Scout MP:   " .. demo.scout.getMovePoints() .. " / 40", sx, 310)
    text("Regeneration: 20 per turn", sx, 337)
    text("Scout discards turn leftovers", sx, 364)
    text("Route nodes: " .. demo.path.getNodeCount(), sx, 404)
    text("Soldier cost: " .. demo.path.getCost(demo.soldier), sx, 431)
    text("Scout cost: " .. demo.path.getCost(demo.scout), sx, 458)
    text("Future turns: " .. tostring(demo.path.getCycleCount()), sx, 485)
    text("Playback: " .. demo.speed.getPos() .. " steps/sec", sx, 522)
    text("Marsh: soldier 15 / scout 5", sx, 559)
    text("Rock: soldier refuses passage", sx, 586)
    text("Wall: blocks everyone", sx, 613)
    text("Green = reachable this turn", sx, 650, 14, "#43BBA1")
    text("Gold = later turn (number)", sx, 674, 14, "#CFAB57")
    text(demo.status:sub(1, 105), 24, 719, 17, "#FFFFFF")
    text("Left drag: paint | Right drag: erase | Space: play/pause | N: step | T: next turn", 24, 747, 14)
    text("Editing restarts the group. SAVE/LOAD stores terrain and endpoints. RNG randomizes maps.", 24, 772, 13, "#91A7BB")
    canvas.restore()
    sys.animation.requestFrame(frame)
end
sys.animation.requestFrame(frame)
