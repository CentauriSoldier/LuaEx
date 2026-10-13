local stack=Stack();local events={};local result="Ready"
local function describe(value)
 local kind=type(value)
 if kind=="string" then return string.format("%q",value),kind end
 if kind=="table" then return serialize(value),kind end
 return tostring(value),kind
end
local function view()
 local items={};for value in stack() do local text,kind=describe(value);items[#items+1]={index=#items+1,text=text,kind=kind} end
 return {visual="stack",items=items,size=stack.size(),message=result,events=clone(events)}
end
local function log(text)result=text;events[#events+1]=text;if #events>30 then table.remove(events,1) end end
local function reset()stack=Stack();events={};stack.push("Open document").push("Edit text").push("Save document");log("Three commands pushed: Save document is now on top.") end
function workbench_action(action,data)
 data=data or {};local ok,err=pcall(function()
  if action=="view" then return end
  if action=="reset" then reset();return end
  if action=="push" then
   assert(stack.size()<30,"Limit is 30 items; pop or clear before adding more")
   local value
   if data.kind=="string" then value=data.value
   elseif data.kind=="number" then value=tonumber(data.value);assert(value and value==value and math.abs(value)<=1000000,"Enter a finite number between -1000000 and 1000000")
   elseif data.kind=="true" then value=true
   elseif data.kind=="false" then value=false
   elseif data.kind=="null" then value=null
   elseif data.kind=="record" then value={command=data.value,enabled=true}
   elseif data.kind=="nil" then value=nil
   else error("Unknown value type") end
   stack.push(value);local text,kind=describe(value);log("Push "..text.." ["..kind.."]"..(value==nil and " — nil ignored by Stack" or ""))
  elseif action=="pop" then
   if stack.size()==0 then log("Empty stack: no item to pop. The visual guards the current empty-pop API limitation.");return end
   local text,kind=describe(stack.pop());log("Popped "..text.." ["..kind.."] — removed the top item")
  elseif action=="peek" then
   if stack.size()==0 then log("Empty stack: no top item");return end
   local top;for value in stack() do top=value;break end
   local text,kind=describe(top);log("Top is "..text.." ["..kind.."] — stack unchanged"..(top==false and "; read through iteration because current Stack.peek masks false" or ""))
  elseif action=="reverse" then stack.reverse();log("Reversed the stack; bottom becomes top")
  elseif action=="clear" then stack.clear();log("Cleared all items")
  elseif action=="drain" then
   if stack.size()==0 then log("Already empty");return end
   local values={};while stack.size()>0 do values[#values+1]=(describe(stack.pop())) end
   log("Popped top to bottom: "..table.concat(values," → "))
  else error("Unknown Stack action") end
 end)
 if not ok then log("Rejected: "..tostring(err):gsub("^.-:%d+: ","")) end
 return view()
end
reset();print("Stack visual: last in, first out. Mixed types retain their identities. The top is shown first.")
return view()
