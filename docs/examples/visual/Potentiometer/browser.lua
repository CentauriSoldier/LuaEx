local modes={clamp=POT_CONTINUITY_NONE,wrap=POT_CONTINUITY_REVOLVE,bounce=POT_CONTINUITY_ALT}
local pots,history,steps={}, {},0
local function reset() pots={};history={};steps=0;for name,mode in pairs(modes) do pots[name]=Potentiometer(0,10,5,2,mode) end end
local function finite(n) assert(type(n)=="number" and n==n and math.abs(n)<=1000000,"Use a finite number between -1000000 and 1000000");return n end
local function view(message)
 local state={visual="potentiometer",items={},history=clone(history),steps=steps,message=message or "Ready"}
 for _,name in ipairs({"clamp","wrap","bounce"}) do local p=pots[name];state.items[#state.items+1]={key=name,min=p.getMin(),max=p.getMax(),position=p.getPos(),rate=p.getRate(),direction=p.isAscending() and "Ascending" or p.isDescending() and "Descending" or "Clamped",atStart=p.isAtStart(),atEnd=p.isAtEnd()} end
 return state
end
function workbench_action(action,data)
 data=data or {};local ok,err=pcall(function()
  if action=="reset" then reset();return end
  if action=="view" then return end
  if action=="configure" then
   local min,max,pos,rate=finite(data.min),finite(data.max),finite(data.position),finite(data.rate)
   assert(max>min,"Maximum must exceed minimum")
   for name,mode in pairs(modes) do pots[name]=Potentiometer(min,max,pos,rate,mode) end
   history={};steps=0;return
  end
  if action=="position" then for _,p in pairs(pots) do p.setPos(finite(data.value)) end;return end
  local amount=finite(data.amount or 1)
  assert(action=="increase" or action=="decrease" or action=="adjust","Unknown action")
  for _,name in ipairs({"clamp","wrap","bounce"}) do local p=pots[name];local before=p.getPos();p[action](amount);history[#history+1]=string.format("%s: %.4g → %.4g (%s)",name,before,p.getPos(),p.isDescending() and "descending" or p.isAscending() and "ascending" or "clamped") end
  while #history>30 do table.remove(history,1) end;steps=steps+1
 end)
 return view(ok and "Updated" or "Rejected: "..tostring(err):gsub("^.-:%d+: ",""))
end
reset();print("Compare clamping, inclusive wrapping and bouncing with identical bounds and movement.")
print("Increase/decrease multiply the rate. Adjust adds a signed amount independent of direction.")
return view()
