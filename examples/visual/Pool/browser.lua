-- UI sends actions; actual values, reservations, clamping and events are LuaEx.
local pools,log,tick={}, {},0
local keys={"health","mana","stamina"}
local names={health="Health",mana="Mana",stamina="Stamina"}
local A,M=Pool.ASPECT,Pool.MODIFIER
local function record(text) log[#log+1]=text;if #log>35 then table.remove(log,1) end end
local function callbacks(key,pool)
 for _,pair in ipairs({{Pool.EVENT.ON_INCREASE,"increase"},{Pool.EVENT.ON_DECREASE,"decrease"},{Pool.EVENT.ON_EMPTY,"empty"},{Pool.EVENT.ON_FULL,"full"},{Pool.EVENT.ON_RESERVE,"reserve"},{Pool.EVENT.ON_UNRESERVE,"unreserve"},{Pool.EVENT.ON_LOW,"low"},{Pool.EVENT.ON_HIGH,"high"},{Pool.EVENT.ON_CYCLE,"cycle"}}) do
  local event,name=pair[1],pair[2]
  pool.setEventCallback(event,function(p) record(names[key].." / "..name..": "..string.format("%.2f",p.get())) end)
 end
end
local function reset()
 tick=0;log={}
 for i,key in ipairs(keys) do
  local p=Pool(i==1 and 120 or 100,i==1 and 90 or i==2 and 60 or 80)
  p.set(i==1 and 2 or i==2 and 5 or 8,A.CYCLE_FLAT)
  p.setLowMarker(.25);p.setHighMarker(.8);callbacks(key,p);pools[key]=p
 end
 record("Ready. Spend resources, reserve capacity or advance regeneration cycles.")
end
local function view(message)
 local state={visual="pool",resources={},events=clone(log),tick=tick,message=message or "Ready"}
 for _,key in ipairs(keys) do
  local p=pools[key]
  state.resources[#state.resources+1]={key=key,name=names[key],current=p.get(),maximum=p.get(A.MAX),available=p.get(A.AVAILABLE),reserved=p.get(A.RESERVED),cycle=p.get(A.CYCLE),empty=p.isEmpty(),full=p.isFull(),low=p.isLow(),high=p.isHigh(),
   config={maximum=p.get(A.MAX,M.BASE),current=p.get(),flat=p.get(A.RESERVED_FLAT),percent=p.get(A.RESERVED_PERCENT)*100,regen=p.get(A.CYCLE_FLAT),regenPercent=p.get(A.CYCLE_PERCENT)*100,bonus=p.get(A.MAX,M.BASE_BONUS),multiplier=p.get(A.MAX,M.MULTIPLICATIVE_BONUS)*100,low=p.getLowMarker()*100,high=p.getHighMarker()*100}}
 end
 return state
end
local function number(value,name,min,max)
 assert(type(value)=="number" and value==value and value~=math.huge and value~=-math.huge,"Enter a finite number for "..name)
 assert(value>=min and value<=max,name.." is outside "..min..".."..max);return value
end
local function configure(key,config)
 local values={}
 for _,name in ipairs({"maximum","current","flat","percent","regen","regenPercent","bonus","multiplier","low","high"}) do
  local min=(name=="regen" or name=="regenPercent") and -10000 or 0
  values[name]=number(config[name],name,min,name=="current" and 100000000 or (name=="percent" or name=="low" or name=="high") and 100 or 10000)
 end
 assert(values.maximum>0,"Base maximum must be greater than zero")
 assert(values.low<=values.high,"Low marker must not exceed high marker")
 -- Validate on a copy; a rejected reservation never partly changes the live Pool.
 local p=clone(pools[key]);p.set(0,A.RESERVED_FLAT);p.set(0,A.RESERVED_PERCENT)
 local function set(value,aspect,modifier)
  -- CURRENT's boolean reports an actual change, including after clamping.
  -- Applying a reservation can already clamp it before this final setter.
  if aspect==A.CURRENT then
   p.set(value,aspect)
   assert(p.get()==math.max(0,math.min(value,p.get(A.AVAILABLE))),"Current did not clamp to available capacity")
   return
  end
  local _,accepted,overage=p.set(value,aspect,modifier)
  assert(accepted,"Rejected "..aspect.name.." change"..(overage>0 and ("; over limit by "..string.format("%.8g",overage)) or "; check this value and the available capacity"))
 end
 set(values.maximum,A.MAX);set(values.bonus,A.MAX,M.BASE_BONUS);set(values.multiplier/100,A.MAX,M.MULTIPLICATIVE_BONUS)
 set(values.flat,A.RESERVED_FLAT);set(values.percent/100,A.RESERVED_PERCENT)
 set(values.regen,A.CYCLE_FLAT);set(values.regenPercent/100,A.CYCLE_PERCENT)
 p.setLowMarker(values.low/100);p.setHighMarker(values.high/100);set(values.current,A.CURRENT)
 callbacks(key,p);pools[key]=p
 record(names[key].." settings applied. Current "..string.format("%.2f",p.get()).."; available "..string.format("%.2f",p.get(A.AVAILABLE)))
end
function workbench_action(action,payload)
 payload=payload or {}
 local ok,message=pcall(function()
  if action=="reset" then reset();return end
  if action=="cycle" then
   local multiplier=number(payload.multiplier or 1,"Cycle multiplier",0,100)
   for _,key in ipairs(keys) do pools[key].cycle(multiplier) end
   tick=tick+multiplier;record("Advanced "..multiplier.." cycle(s)");return
  end
  if action=="view" then return end
  local key=payload.key;local p=assert(pools[key],"Unknown resource")
  if action=="configure" then configure(key,payload.config)
  elseif action=="spend" or action=="restore" then
   local amount=number(payload.amount,"Amount",0,10000)
   p.adjust(action=="spend" and -amount or amount)
  elseif action=="fill" then p.setFull()
  elseif action=="empty" then p.setEmpty()
  elseif action=="current" then p.set(number(payload.value,"Current",0,100000000))
  else error("Unknown Pool action") end
 end)
 if not ok then local reason=tostring(message):gsub("^.-:%d+: ","");record("REJECTED: "..reason);return view("Rejected: "..reason) end
 return view(action=="configure" and "Settings applied; current clamps to available capacity." or "Updated")
end
reset()
print("Pool resource laboratory: real LuaEx Health, Mana and Stamina Pools.")
print("Reserved = flat + maximum × percent. Available = maximum − reserved.")
print("Regeneration = flat + maximum × cycle percent; Full fills available capacity.")
return view()
