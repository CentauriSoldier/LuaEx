-- Locate the repository from this example (native Lua and browser virtual files).
local sExampleSource = debug.getinfo(1, "S").source:gsub("^@", "")
local sSourcePath = sExampleSource:match("^(.*)[/\\]") or "."
local sRepositoryPath = sSourcePath
for _ = 1, 8 do
    local file = io.open(sRepositoryPath .. "/LuaEx/init.lua", "r")
    if file then file:close(); break end
    sRepositoryPath = sRepositoryPath .. "/.."
end
package.path = sRepositoryPath .. "/?.lua;" .. package.path
if not LUAEX_INIT then require("LuaEx.init") end

local D=require("examples.support.tutorial").new("Eventrix","Ordered callbacks, mixed return values, activation and error isolation.")

D.section("Your event", "Enum items identify events; payloads can be numbers, strings or records.")
local amount=D.input("damage",15)
local Events=enum("TutorialEvents",{"ATTACK","HEAL","MESSAGE"},nil,true)
local bus=eventrix();local health=100;local order={}
local function damage(value) order[#order+1]="damage";health=health-value;return health end
local function log(value) order[#order+1]="log";return "recorded "..value end
bus.addHook(Events.ATTACK,damage);bus.addHook(Events.ATTACK,log)
D.equal("Registered callbacks",bus.getHookCount(Events.ATTACK),2)
D.section("Order and returns", "Callbacks execute in registration order; each return has its own slot.")
local results=bus.fire(Events.ATTACK,amount)
D.equal("Damage applies once",health,100-amount)
D.equal("First return is numeric",results[1],100-amount)
D.equal("Second return is text",results[2],"recorded "..amount)
D.equal("Observed order",table.concat(order,","),"damage,log")
D.section("Disable one hook", "Other hooks still run when the damage hook is paused.")
bus.setHookActive(Events.ATTACK,damage,false);bus.fire(Events.ATTACK,20)
D.equal("Health unchanged",health,100-amount)
bus.setHookActive(Events.ATTACK,damage,true);bus.fire(Events.ATTACK,5)
D.equal("Reactivated hook",health,95-amount)
D.section("Pause the entire event", "An inactive event executes no callbacks and returns an empty result list.")
bus.setEventActive(Events.ATTACK,false)
D.equal("No returns while paused",#bus.fire(Events.ATTACK,100),0)
D.equal("No paused damage",health,95-amount)
D.section("Records and booleans", "A different event can accept a structured payload and return false without becoming nil.")
bus.addHook(Events.MESSAGE,function(record) D.show("Message record",record);return false end)
D.equal("False result preserved",bus.fire(Events.MESSAGE,{text="hello",urgent=true,count=2})[1],false)
D.section("Independent event state", "Pausing ATTACK does not pause HEAL or another Eventrix instance.")
bus.addHook(Events.HEAL,function(value) health=health+value;return health end)
D.equal("Healing remains active",bus.fire(Events.HEAL,5)[1],100-amount)
local other=eventrix();D.equal("Unregistered event uses sentinel -1",other.getHookCount(Events.ATTACK),-1)

D.finish()
