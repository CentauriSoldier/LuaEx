-- All movement, affinities, group passage and planning use the real LuaEx API.
local Model={}
Model.Terrain=enum("AStarDemoTerrain",{"GROUND","WALL","MARSH","ROCK","SAND","FOREST","CAVE"})
Model.Profiles={
 HUMAN={name="Human",icon="human",color="#805b34",affinities={},aversions={marsh=.5,sand=.25},abhors={rock=true},retain=true},
 ELF={name="Elf",icon="elf",color="#397b5c",affinities={forest=.5,marsh=.5},aversions={rock=.5},abhors={},retain=false},
 GOBLIN={name="Goblin",icon="goblin",color="#857c2c",affinities={rock=.5},aversions={marsh=.25,sand=.5},abhors={},retain=true},
 DWARF={name="Dwarf",icon="dwarf",color="#765683",affinities={rock=.5,sand=.25},aversions={marsh=.75,forest=.25},abhors={},retain=true},
}
local aspects={MARSH="marsh",ROCK="rock",SAND="sand",FOREST="forest"}
local T=Model.Terrain
function Model.new()
 local demo={width=20,height=14,turn=0,moves=0,cells={},groups={},activeID=1,nextGroupID=2,nextMemberID=1,links={},trail={},auto=true,dirty=false}
 demo.speed=Potentiometer(1,10,4,1);demo.tags=TagSystem();demo.tags.addMultiple({"ASTAR","GROUP","TERRAIN","POOL","PROTEAN","RNG","ENUM","SERIALIZER"})
 function demo.active() for _,g in ipairs(demo.groups) do if g.id==demo.activeID then return g end end end
 function demo.position() local g=demo.active();return #g.members>0 and g.members[1].rover.getOwner() or demo.map.getNode("ground",g.position.x,g.position.y) end
 function demo.configureNode(x,y)
  local node=demo.map.getNode("ground",x,y);local terrain=demo.cells[y][x]
  node.setPassable(terrain~=T.WALL.value)
  for key,aspect in pairs(aspects) do node.getAspect(aspect).getImpactor().setValue(terrain==T[key].value and 1 or 0) end
 end
 function demo.connectCaves()
  for _,link in ipairs(demo.links) do link[1].removePort(link[2]) end
  demo.links={};local caves={}
  for y=1,demo.height do for x=1,demo.width do if demo.cells[y][x]==T.CAVE.value then caves[#caves+1]=demo.map.getNode("ground",x,y) end end end
  -- Entrances are paired in reading order; an odd final entrance is unlinked.
  for i=1,#caves-1,2 do
   local a,b=caves[i],caves[i+1];a.addPort(b)
   a.setPortPassageRule(b,function(rover)return rover.isType("goblin") end,true)
   demo.links[#demo.links+1]={a,b}
  end
 end
 function demo.rover(kind,node)
  local profile=assert(Model.Profiles[kind],"Unknown creature")
  local rover=node.createRover(profile.retain);rover.addType(kind:lower())
  for aspect,value in pairs(profile.affinities) do rover.getAffinity(aspect).setValue(value) end
  for aspect,value in pairs(profile.aversions) do rover.getAversion(aspect).setValue(value) end
  for aspect in pairs(profile.abhors) do rover.setAbhors(aspect,true) end
  local pool=rover.getMovePointPool();pool.set(40,Pool.ASPECT.MAX);pool.set(25);pool.set(20,Pool.ASPECT.CYCLE_FLAT)
  local member={id=demo.nextMemberID,kind=kind,rover=rover};demo.nextMemberID=demo.nextMemberID+1;return member
 end
 function demo.plan()
  demo.dirty=false
  local g=demo.active();demo.group={};for _,m in ipairs(g.members) do demo.group[#demo.group+1]=m.rover end
  demo.soldier=demo.group[1];demo.scout=demo.group[2] or demo.group[1]
  if #demo.group==0 then demo.path=nil;demo.status="Empty group: add a creature to plan a route";return end
  local points={};for i,r in ipairs(demo.group) do points[i]=r.getMovePoints() end
  demo.path=AStar.Path(demo.position(),demo.map.getNode("ground",demo.goal.x,demo.goal.y),demo.group)
  for i,r in ipairs(demo.group) do assert(r.getMovePoints()==points[i],"Planning spent points") end
  demo.path.setOnStepCallback(function(_,_,_,_,node)
   demo.moves=demo.moves+1;demo.trail[node]=true;g.position={x=node.getX(),y=node.getY()}
   for _,r in ipairs(demo.group) do assert(r.getOwner()==node,"Group split") end
  end)
  demo.status=demo.path.hasPath() and "Best route ready for "..g.name or "No route for this group: check terrain restrictions"
 end
 function demo.replan()
  if demo.auto then demo.plan() else demo.path=nil;demo.dirty=true;demo.status="Map or goal changed: press Update path" end
 end
 function demo.target(x,y)
  if x==demo.goal.x and y==demo.goal.y then return end
  demo.goal={x=x,y=y};demo.replan() -- Goal preview preserves all positions and budgets.
 end
 function demo.step()
  if not demo.path or not demo.path.hasPath() then demo.status="No route for this group";return false end
  if not demo.path.getNextNode() then demo.status="Destination reached";return false end
  local moved=demo.path.step();demo.status=moved and "Party moved; individual costs paid" or "Not enough movement: advance the turn";return moved
 end
 function demo.cycle()
  for _,g in ipairs(demo.groups) do for _,m in ipairs(g.members) do m.rover.cycle() end end
  demo.turn=demo.turn+1;if demo.path then demo.path.refreshPreview() end;demo.status="Turn "..demo.turn..": all parties regenerated"
 end
 function demo.add(kind)
  local g=demo.active();assert(#g.members<8,"A party may contain at most eight creatures")
  g.members[#g.members+1]=demo.rover(kind,demo.position());demo.plan()
 end
 function demo.remove(id)
  local g=demo.active();for i,m in ipairs(g.members) do if m.id==id then table.remove(g.members,i);break end end;demo.plan()
 end
 function demo.clear() demo.active().members={};demo.plan() end
 function demo.newGroup(name)
  assert(#demo.groups<6,"At most six parties")
  local node=demo.position();local g={id=demo.nextGroupID,name=name or ("Party "..demo.nextGroupID),members={},position={x=node.getX(),y=node.getY()}}
  demo.nextGroupID=demo.nextGroupID+1;demo.groups[#demo.groups+1]=g;demo.activeID=g.id;demo.plan()
 end
 function demo.selectGroup(id)
  for _,g in ipairs(demo.groups) do if g.id==id then demo.activeID=id;demo.plan();return end end;error("Unknown party")
 end
 function demo.deleteGroup()
  assert(#demo.groups>1,"Keep at least one party; clear its creatures instead")
  for i,g in ipairs(demo.groups) do if g.id==demo.activeID then table.remove(demo.groups,i);break end end
  demo.activeID=demo.groups[1].id;demo.plan()
 end
 function demo.build(cells,start,goal,records)
  demo.system=AStar("marsh","rock","sand","forest")
  demo.map=demo.system.newMap("fantasy",AStar.MAP_TYPE_SQUARE,{AStar.LayerConfig("ground","marsh","rock","sand","forest")},demo.width,demo.height)
  demo.cells=cells;demo.start=start or {x=2,y=7};demo.goal=goal or {x=19,y=7};demo.turn,demo.moves,demo.trail,demo.links=0,0,{},{}
  for y=1,demo.height do for x=1,demo.width do demo.configureNode(x,y) end end;demo.connectCaves()
  demo.groups={}
  records=records or {{id=1,name="Wayfarers",position=demo.start,kinds={"HUMAN","ELF"}}}
  for _,record in ipairs(records) do
   local g={id=record.id,name=record.name,position=clone(record.position),members={}};demo.groups[#demo.groups+1]=g
   for _,kind in ipairs(record.kinds) do g.members[#g.members+1]=demo.rover(kind,demo.map.getNode("ground",g.position.x,g.position.y)) end
  end
  if not demo.active() then demo.activeID=demo.groups[1].id end;demo.plan()
 end
 function demo.records(reset)
  local records={};for _,g in ipairs(demo.groups) do
   local kinds={};for _,m in ipairs(g.members) do kinds[#kinds+1]=m.kind end
   records[#records+1]={id=g.id,name=g.name,position=reset and clone(demo.start) or clone(g.position),kinds=kinds}
  end;return records
 end
 function demo.reset(random)
  local cells={};local phase=math.random(0,100)/10
  for y=1,demo.height do cells[y]={};for x=1,demo.width do
   local value=T.GROUND.value
   if random then
    -- Connected biomes: elliptical forest and wetland, a desert basin and a
    -- winding mountain ridge. No independent per-cell noise or scattered walls.
    local ridge=12+2*math.sin(y*.32+phase)
    if ((x-5)/3.6)^2+((y-(5+math.sin(phase)))/3)^2<1 then value=T.FOREST.value end
    if ((x-7)/3)^2+((y-10)/2.7)^2<1 then value=T.MARSH.value end
    if ((x-17)/4)^2+((y-5)/3.5)^2<1 then value=T.SAND.value end
    if math.abs(x-ridge)<1.3 and y>2 and y<12 then value=T.ROCK.value end
   else
    if x>=4 and x<=8 and y>=5 and y<=9 then value=T.MARSH.value end
    if x==10 and y>2 and y<12 then value=T.WALL.value end
    if x>=13 and x<=15 and y>=3 and y<=9 then value=T.ROCK.value end
    if x>=3 and x<=7 and y>=2 and y<=3 then value=T.FOREST.value end
    if x>=16 and x<=19 and y>=9 and y<=12 then value=T.SAND.value end
   end
   cells[y][x]=value
  end end
  if random then -- A traversable southern trade road joins both endpoints.
   for x=2,19 do cells[12][x]=T.GROUND.value end
   for y=7,12 do cells[y][2]=T.GROUND.value;cells[y][19]=T.GROUND.value end
  end
  cells[3][8]=T.CAVE.value;cells[11][15]=T.CAVE.value
  cells[7][2]=T.GROUND.value;cells[7][19]=T.GROUND.value
  local records=#demo.groups>0 and demo.records(true) or nil
  if records then for _,r in ipairs(records) do r.position={x=2,y=7} end end
  demo.build(cells,nil,nil,records)
 end
 function demo.edit(x,y,tool)
  if tool=="GOAL" then demo.target(x,y);return end
  if tool=="START" then
   local node=demo.map.getNode("ground",x,y)
   if demo.cells[y][x]~=T.GROUND.value then demo.status="Place a party on grassland";return end
   local g=demo.active();local kinds={};for _,m in ipairs(g.members) do kinds[#kinds+1]=m.kind end
   g.members={};g.position={x=x,y=y};for _,kind in ipairs(kinds) do g.members[#g.members+1]=demo.rover(kind,node) end
   demo.start={x=x,y=y};demo.plan();return
  end
  for _,g in ipairs(demo.groups) do if g.position.x==x and g.position.y==y then demo.status="Move the party before painting its cell";return end end
  demo.cells[y][x]=assert(T[tool],"Unknown terrain").value;demo.configureNode(x,y);demo.connectCaves();demo.replan()
 end
 function demo.snapshot() return serialize({cells=demo.cells,start=demo.start,goal=demo.goal,groups=demo.records(),activeID=demo.activeID,nextGroupID=demo.nextGroupID}) end
 function demo.restore(text)
  local s=deserialize(text);assert(type(s)=="table" and type(s.cells)=="table","Invalid snapshot")
  for y=1,demo.height do assert(type(s.cells[y])=="table","Missing row");for x=1,demo.width do local n=s.cells[y][x];assert(type(n)=="number" and n%1==0 and n>=1 and n<=7,"Invalid terrain") end end
  local function position(p)assert(type(p)=="table" and type(p.x)=="number" and type(p.y)=="number" and p.x%1==0 and p.y%1==0 and p.x>=1 and p.x<=20 and p.y>=1 and p.y<=14,"Invalid position")end
  position(s.start);position(s.goal);assert(type(s.groups)=="table" and #s.groups>=1 and #s.groups<=6,"Invalid parties")
  for _,g in ipairs(s.groups) do position(g.position);assert(type(g.kinds)=="table" and #g.kinds<=8,"Invalid members");for _,kind in ipairs(g.kinds) do assert(Model.Profiles[kind],"Invalid creature") end end
  local ids={};local active=false;local largest=0
  for _,g in ipairs(s.groups) do
   assert(type(g.id)=="number" and g.id%1==0 and g.id>0 and not ids[g.id],"Invalid party identifier")
   assert(type(g.name)=="string" and #g.name<=80,"Invalid party name")
   ids[g.id]=true;largest=math.max(largest,g.id);if g.id==s.activeID then active=true end
  end
  assert(active,"Missing active party")
  assert(type(s.nextGroupID)=="number" and s.nextGroupID%1==0 and s.nextGroupID>largest,"Invalid next party identifier")
  demo.activeID=s.activeID;demo.nextGroupID=s.nextGroupID;demo.build(s.cells,s.start,s.goal,s.groups)
 end
 demo.reset(false);return demo
end
return Model
