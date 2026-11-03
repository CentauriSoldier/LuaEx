-- Character-sheet values come from real Proteans; presets aggregate modifiers.
local definitions={{key="strength",name="Strength",base=20},{key="agility",name="Agility",base=25},{key="intellect",name="Intellect",base=40},{key="vitality",name="Vitality",base=30}}
local categories={base=Protean.VALUE_BASE,baseBonus=Protean.BASE_BONUS,basePenalty=Protean.BASE_PENALTY,multBonus=Protean.MULTIPLICATIVE_BONUS,multPenalty=Protean.MULTIPLICATIVE_PENALTY,addBonus=Protean.ADDATIVE_BONUS,addPenalty=Protean.ADDATIVE_PENALTY,min=Protean.LIMIT_MIN,max=Protean.LIMIT_MAX}
local modifierNames={"baseBonus","basePenalty","multBonus","multPenalty","addBonus","addPenalty"}
local presets={{key="curse",name="Withering curse",description="−3 before multiplication; 50% multiplicative penalty",values={basePenalty=3,multPenalty=.5}},
 {key="blessing",name="Hero's blessing",description="+5 before multiplication; 25% multiplicative bonus",values={baseBonus=5,multBonus=.25}},
 {key="equipment",name="Enchanted equipment",description="+8 after multiplication",values={addBonus=8}},
 {key="fatigue",name="Exhaustion",description="−4 after multiplication",values={addPenalty=4}},
 {key="training",name="Training",description="+2 before multiplication; 10% multiplicative bonus",values={baseBonus=2,multBonus=.1}}}
local stats,events,selected,inspection={}, {},"strength",nil
local function log(text) events[#events+1]=text;if #events>50 then table.remove(events,1) end end
local function finite(n) assert(type(n)=="number" and n==n and math.abs(n)<=1000000,"Use finite values between -1000000 and 1000000");return n end
local function fresh(d)
 local s={key=d.key,name=d.name,original=d.base,manual={},effects={},limitMin=false,limitMax=false}
 s.p=Protean(d.base,0,0,0,0,0,0,0,100)
 s.p.setLimitMin(false);s.p.setLimitMax(false)
 s.p.setCallback(function(object,category,old,new,final)
  local name="category "..category;for key,id in pairs(categories) do if id==category then name=key end end
  log((object==s.p and s.name or s.name.." clone (shared callback)")..": "..name.." "..old.." → "..new.."; final "..final)
 end)
 for _,name in ipairs(modifierNames) do s.manual[name]=0 end
 return s
end
local function totals(s)
 local values=clone(s.manual)
 for _,preset in ipairs(presets) do if s.effects[preset.key] then for key,value in pairs(preset.values) do values[key]=values[key]+value end end end
 return values
end
local function applyModifiers(s)
 for key,value in pairs(totals(s)) do s.p.setValue(categories[key],value) end
end
local function reset()
 for _,s in pairs(stats) do s.p.setLinker() end
 stats={};for _,d in ipairs(definitions) do stats[d.key]=fresh(d) end;events={};selected="strength";inspection=nil
 log("Sheet reset: original bases, no effects/modifiers, no links, auto calculation and callbacks enabled, limiters disabled.")
end
local function view(message)
 local state={visual="protean",selected=selected,stats={},presets=clone(presets),events=clone(events),message=message or "Ready",inspection=inspection}
 for _,d in ipairs(definitions) do
  local s=stats[d.key];local p=s.p;local values={};for key,category in pairs(categories) do values[key]=p.getValue(category) end
  local before=values.base+values.baseBonus-values.basePenalty;local factor=1+values.multBonus-values.multPenalty;local raw=before*factor+values.addBonus-values.addPenalty
  local expected=raw;if s.limitMin then expected=math.max(expected,values.min) end;if s.limitMax then expected=math.min(expected,values.max) end
  state.stats[#state.stats+1]={key=s.key,name=s.name,base=values.base,final=p.getValue(),values=values,manual=clone(s.manual),effects=clone(s.effects),before=before,factor=factor,raw=raw,pending=not p.isAutoCalculated() and expected~=p.getValue(),auto=p.isAutoCalculated(),callback=p.isCallbackActive(),callbackLocked=p.isCallbackLocked(),toggleLocked=p.isCallbackToggleLocked(),linked=p.isLinked(),linker=p.getLinkerID(),limitMin=s.limitMin,limitMax=s.limitMax,original=s.original}
 end
 return state
end
function workbench_action(action,data)
 data=data or {};local ok,err=pcall(function()
  if action=="view" then return end
  if action=="resetSheet" then reset();return end
  if action=="select" then assert(stats[data.key],"Unknown stat");selected=data.key;inspection=nil;return end
  local s=stats[selected];local p=s.p
  if action=="effect" then
   local found=false;for _,preset in ipairs(presets) do if preset.key==data.key then found=true end end;assert(found,"Unknown effect")
   s.effects[data.key]=data.enabled==true;applyModifiers(s)
  elseif action=="configure" then
   local v=data.values;for key in pairs(categories) do finite(v[key]) end;assert(v.min<=v.max,"Minimum limit must not exceed maximum limit")
   assert(not p.isCallbackToggleLocked() or data.callback==p.isCallbackActive(),"Callback toggling is locked; reset this stat to unlock")
   p.setCallbackActive(data.callback==true);p.setAutoCalculate(false)
   for _,name in ipairs(modifierNames) do s.manual[name]=v[name] end
   p.setValue(Protean.LIMIT_MAX,v.max);p.setValue(Protean.LIMIT_MIN,v.min)
   s.limitMin=data.limitMin==true;s.limitMax=data.limitMax==true;p.setLimitMin(s.limitMin);p.setLimitMax(s.limitMax)
   applyModifiers(s);p.setValue(v.base);p.setAutoCalculate(data.auto==true)
   log(s.name.." settings applied. Manual values and active effects combine.")
  elseif action=="calculate" then p.calculateFinalValue();log(s.name.." explicitly recalculated to "..p.getValue())
  elseif action=="adjust" then assert(categories[data.category],"Unknown category");local amount=finite(data.amount)
   if data.category=="base" then p.adjustValue(amount)
   elseif s.manual[data.category]~=nil then s.manual[data.category]=s.manual[data.category]+amount;applyModifiers(s)
   else p.adjustValue(categories[data.category],amount) end
  elseif action=="clearEffects" then s.effects={};applyModifiers(s)
  elseif action=="resetModifiers" then s.effects={};for _,name in ipairs(modifierNames) do s.manual[name]=0 end;applyModifiers(s);log("Modifiers cleared; base, limits, links, calculation mode and callback locks preserved.")
  elseif action=="resetStat" then p.setLinker();for _,d in ipairs(definitions) do if d.key==selected then stats[selected]=fresh(d) end end;inspection=nil;log("Selected stat recreated with original base and default flags.")
  elseif action=="link" then
   local target=assert(stats[data.target],"Choose a different stat");assert(target~=s,"Cannot link to self")
   if not target.p.isLinked() then target.p.setLinker(0) end;p.setLinker(target.p.getLinkerID());log("Linked bases: "..s.name.." adopts "..target.name.." base. Modifiers remain individual.")
  elseif action=="unlink" then p.setLinker();log(s.name.." unlinked; current base preserved.")
  elseif action=="lockCallback" then p.lockCallback();log("Callback replacement locked until this stat is recreated.")
  elseif action=="replaceCallback" then p.setCallback(function(object,category,old,new,final) log("Alternate callback "..s.name..(object==p and "" or " clone")..": category "..category..", "..old.." → "..new.."; final "..final) end);log("Installed an alternate callback; callback activation is enabled by setCallback.")
  elseif action=="lockToggle" then p.lockCallbackToggle();log("Callback activation locked until this stat is recreated.")
  elseif action=="copy" or action=="snapshot" then
   local copy=action=="copy" and clone(p) or deserialize(serialize(p));local initial=copy.getValue(Protean.VALUE_BASE);copy.setValue(initial+5)
   inspection={operation=action=="copy" and "Clone" or "Serialize → deserialize",base=copy.getValue(Protean.VALUE_BASE),final=copy.getValue(),originalBase=p.getValue(Protean.VALUE_BASE),linked=copy.isLinked(),callback=copy.isCallbackActive(),locked=copy.isCallbackLocked(),toggleLocked=copy.isCallbackToggleLocked(),auto=copy.isAutoCalculated()}
   log(inspection.operation..": changed only copy base by +5. Clone retains callbacks; serialized copies omit callbacks and links. Cached finals remain stale when auto calculation is disabled.")
  elseif action=="rejectFinal" then p.setValue(Protean.VALUE_FINAL,999)
  else error("Unknown Protean action") end
 end)
 return view(ok and "Updated" or "Rejected: "..tostring(err):gsub("^.-:%d+: ",""))
end
reset();print("Protean character sheet: Final = (Base + Base bonus − Base penalty) × (1 + Mult bonus − Mult penalty) + Addative bonus − Addative penalty, then enabled limits.")
print("Effects aggregate per category. Percent bonuses/penalties add within the multiplier, not compound. Final is calculated and cannot be set directly.")
return view()
