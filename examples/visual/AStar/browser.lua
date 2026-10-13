-- Browser entrypoint: all simulation and terrain costs come from LuaEx.
-- JavaScript draws only this plain-data view and forwards user actions.
local Model = require("examples.visual.AStar.model")
local demo = Model.new()
local D=require("examples.support.tutorial").new("AStar laboratory","Paint terrain, compare rover costs, preview routes and advance turns.")
demo.speed.setPos(D.input("playback_speed",4))
D.section("Terrain", "Grassland costs ten points. Creature affinities and aversions change marsh, sand, mountain and forest costs.")
D.section("Route preview", "Green cells are reachable this turn; future turns appear in gold. Planning spends no points.")
D.section("Movement", "Step advances both rovers together. Next turn replenishes their movement Pools.")
D.section("Your map", "Choose a terrain tool and drag cells. Cursor goal previews routes live. Paired caves permit goblin-only parties.")
D.section("Playback", "Choose playback speed, then Run, or change the speed slider while playing.")
D.section("Save and restore", "Save map keeps a snapshot in this page. Restore map reinstates that snapshot.")
local tool = "WALL"

local function view()
    local rover = demo.position()
    local path=demo.path
    local state = {
        width = demo.width, height = demo.height, cells = clone(demo.cells),
        start = clone(demo.start), goal = clone(demo.goal),
        rover = {x = rover.getX(), y = rover.getY()}, route = {}, trail = {},
        status = demo.status, tool = tool, turn = demo.turn, moves = demo.moves,
        soldier = demo.soldier and demo.soldier.getMovePoints() or 0, scout = demo.scout and demo.scout.getMovePoints() or 0,
        nodes = path and path.getNodeCount() or 0, turns = path and path.getCycleCount() or 0,
        speed = demo.speed.getPos(), hasPath = path and path.hasPath() or false,
        complete = not path or path.getNextNode() == nil,
        groups={},members={},profiles={},caves={},activeGroup=demo.activeID,autoPath=demo.auto,dirty=demo.dirty,
    }
    for index, node in ipairs(path and path.getNodes() or {}) do
        state.route[index] = {x = node.getX(), y = node.getY(), cycle = path.getCycleForNode(index)}
    end
    for kind,profile in pairs(Model.Profiles) do
        state.profiles[#state.profiles+1]={kind=kind,name=profile.name,icon=profile.icon,color=profile.color,affinities=clone(profile.affinities),aversions=clone(profile.aversions),abhors=clone(profile.abhors),retain=profile.retain}
    end
    for _,g in ipairs(demo.groups) do
        state.groups[#state.groups+1]={id=g.id,name=g.name,count=#g.members,x=g.position.x,y=g.position.y}
        if g.id==demo.activeID then for _,member in ipairs(g.members) do
            local r=member.rover;local p=Model.Profiles[member.kind]
            state.members[#state.members+1]={id=member.id,kind=member.kind,name=p.name,icon=p.icon,color=p.color,points=r.getMovePoints(),capacity=40,cost=path and path.getCost(r) or 0}
        end end
    end
    for i,link in ipairs(demo.links) do
        state.caves[#state.caves+1]={pair=i,from={x=link[1].getX(),y=link[1].getY()},to={x=link[2].getX(),y=link[2].getY()},allowed=#demo.group>0 and link[1].canUsePort(link[2],demo.group)}
    end
    for node in pairs(demo.trail) do state.trail[#state.trail + 1] = {x = node.getX(), y = node.getY()} end
    return state
end

function workbench_action(action, payload)
    if action == "tool" then
        assert(Model.Terrain[payload.tool] or payload.tool == "START" or payload.tool == "GOAL", "Unknown tool")
        tool = payload.tool
    elseif action == "paint" or action=="target" then
        assert(payload.x % 1 == 0 and payload.y % 1 == 0 and payload.x >= 1 and payload.x <= demo.width
            and payload.y >= 1 and payload.y <= demo.height, "Cell outside grid")
        if action=="target" then demo.target(payload.x,payload.y) else demo.edit(payload.x, payload.y, payload.erase and "GROUND" or tool) end
    elseif action=="addCreature" then demo.add(payload.kind)
    elseif action=="removeCreature" then demo.remove(payload.id)
    elseif action=="clearGroup" then demo.clear()
    elseif action=="newGroup" then demo.newGroup()
    elseif action=="selectGroup" then demo.selectGroup(payload.id)
    elseif action=="deleteGroup" then demo.deleteGroup()
    elseif action=="autoPath" then demo.auto=payload.enabled;if demo.auto then demo.plan() end
    elseif action=="replan" then demo.plan()
    elseif action == "step" then demo.step()
    elseif action == "turn" then demo.cycle()
    elseif action == "reset" then demo.reset(false)
    elseif action == "random" then demo.reset(true)
    elseif action == "speed" then demo.speed.setPos(payload.speed)
    elseif action == "save" then return {snapshot = demo.snapshot(), view = view()}
    elseif action == "load" then demo.restore(payload.snapshot)
    elseif action ~= "view" then error("Unknown action: " .. tostring(action)) end
    return view()
end
return view()
