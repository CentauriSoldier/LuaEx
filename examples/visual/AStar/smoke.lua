local source = debug.getinfo(1, "S").source:gsub("^@", "")
local directory = source:match("^(.*)[/\\]") or "."
package.path = directory .. "/../../../?.lua;" .. package.path
local demo = require("examples.visual.AStar.model").new()
assert(demo.path.hasPath())
local snapshot = demo.snapshot()
local initialCost = demo.path.getCost(demo.soldier)
local steps, turns = 0, 0
while demo.path.getNextNode() do
    if demo.step() then steps = steps + 1 else demo.cycle(); turns = turns + 1 end
    assert(turns < 100, "Route stalled")
end
assert(steps > 0 and turns > 0 and demo.moves == steps)
assert(demo.soldier.getOwner() == demo.map.getNode("ground", demo.goal.x, demo.goal.y))
demo.restore(snapshot)
assert(demo.moves == 0 and demo.path.getCost(demo.soldier) == initialCost)
demo.speed.increase(100); assert(demo.speed.getPos() == 10)
demo.speed.decrease(100); assert(demo.speed.getPos() == 1)
demo.edit(3, 7, "WALL"); assert(not demo.map.getNode("ground", 3, 7).isPassable())
demo.edit(3, 7, "GROUND"); assert(demo.map.getNode("ground", 3, 7).isPassable())
for y = 1, demo.height do demo.edit(10, y, "WALL") end
assert(not demo.path.hasPath())
demo.reset(false); demo.edit(demo.start.x, demo.start.y, "GOAL")
assert(demo.path.hasPath() and demo.path.getNodeCount() == 1 and not demo.step())
demo.reset(true); assert(demo.tags.contains("RNG"))
print("PASS visual AStar: routes, movement, turns, group callbacks, terrain, snapshot, speed, no-route and same-node cases; " .. _VERSION)

-- Fantasy integration: roster changes and cursor previews must preserve state.
local Model=require("examples.visual.AStar.model")
demo=Model.new()
local owner=demo.position();local budget=demo.soldier.getMovePoints()
for x=3,18 do demo.target(x,2);assert(demo.position()==owner and demo.soldier.getMovePoints()==budget) end
assert(demo.moves==0)
demo.auto=false;demo.target(19,3);assert(demo.dirty and demo.path==nil)
demo.plan();assert(not demo.dirty and demo.path~=nil)
demo.auto=true
demo.clear();assert(#demo.active().members==0 and demo.path==nil and not demo.step())
demo.add("GOBLIN");assert(#demo.active().members==1)
demo.edit(8,4,"START");demo.target(8,3);assert(demo.step());demo.target(15,11)
assert(demo.links[1][1].canUsePort(demo.links[1][2],demo.group))
assert(demo.path.hasPath() and demo.path.getNodeCount()==2,"Goblin cave shortcut missing")
local caveCost=demo.path.getCost(demo.group[1]);assert(caveCost==10)
demo.add("ELF")
assert(not demo.links[1][1].canUsePort(demo.links[1][2],demo.group),"Elf admitted to goblin port")
assert(demo.path.getNodeCount()>2,"Mixed party used goblin shortcut")
demo.remove(demo.active().members[2].id);assert(demo.path.getNodeCount()==2)
assert(demo.step() and demo.position()==demo.map.getNode("ground",15,11))
-- Real entry costs, including a hard refusal, are tested against LuaEx nodes.
demo.reset(false);demo.clear();demo.add("GOBLIN");demo.add("ELF");demo.add("HUMAN");demo.add("DWARF")
local mountain=demo.map.getNode("ground",14,5);local marsh=demo.map.getNode("ground",5,6)
local roster=demo.active().members
assert(mountain.getEntryCost(roster[1].rover)==5)
assert(marsh.getEntryCost(roster[2].rover)==5)
assert(not mountain.isPassable(roster[3].rover))
assert(marsh.getEntryCost(roster[4].rover)==17.5)
local firstParty=demo.activeID;demo.newGroup();local secondParty=demo.activeID
assert(secondParty~=firstParty and #demo.groups==2 and demo.path==nil)
demo.add("ELF");demo.selectGroup(firstParty);assert(#demo.active().members==4)
local saved=demo.snapshot();demo.clear();demo.restore(saved)
assert(#demo.groups==2 and #demo.active().members==4)
demo.selectGroup(secondParty);assert(#demo.active().members==1);demo.deleteGroup();assert(#demo.groups==1)
for seed=1,8 do
 math.randomseed(seed);demo.reset(true);assert(demo.path.hasPath(),"Trade road disconnected")
 local counts={};for y=1,14 do for x=1,20 do local t=demo.cells[y][x];counts[t]=(counts[t] or 0)+1 end end
 assert(counts[Model.Terrain.FOREST.value]>10 and counts[Model.Terrain.SAND.value]>10 and counts[Model.Terrain.MARSH.value]>10)
 for x=2,19 do assert(demo.cells[12][x]==Model.Terrain.GROUND.value) end
end
print("PASS fantasy parties: live previews, manual planning, empty roster, goblin-only cave shortcuts, terrain costs, independent parties, snapshots and eight coherent random maps")
