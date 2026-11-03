local sets={
 enum("EnumDemoRarity",{"COMMON","RARE","LEGENDARY"},{10,25,50}),
 enum("EnumDemoState",{"IDLE","MOVING","ATTACKING"}),
 enum("EnumDemoTwins",{"FIRST","SECOND","THIRD"},{7,7,9}),
 enum("EnumDemoMixed",{"TEXT","FLAG","RECORD"},{"ready",false,{enabled=true,count=3}}),
}
local active,index,counter=1,1,0
local message="Choose an item to inspect its identity and payload."
local function format(value)if type(value)=="string" then return string.format("%q",value) end;if type(value)=="table" then return serialize(value) end;return tostring(value) end
local function view()
 local current=sets[active];local items={};for ordinal,item in current() do items[#items+1]={index=ordinal,name=tostring(item),payload=format(item.value),kind=type(item.value)} end
 local options={};for i,set in ipairs(sets) do options[#options+1]={id=i,name=tostring(set)} end
 return {visual="enum",sets=options,active=active,index=index,items=items,count=#current,message=message}
end
function workbench_action(action,data)
 data=data or {};local ok,errorText=pcall(function()
  local current=sets[active];local item=current[index]
  if action=="view" then return end
  if action=="set" then assert(sets[data.id],"Unknown enum");active=data.id;index=1;message="Selected "..tostring(sets[active]);return end
  if action=="select" then assert(current[data.index],"Unknown item");index=data.index;message="Selected "..tostring(current[index]);return end
  if action=="next" or action=="previous" then
   local result=item[action](data.wrap==true)
   if result then for ordinal,candidate in current() do if candidate==result then index=ordinal end end;message="Navigation returned "..tostring(result)
   else message="Boundary: "..action.." returned nil. Selection stays unchanged." end
  elseif action=="compare" then
   local other=assert(current[data.index],"Unknown comparison item")
   message="Item identity equal: "..tostring(item==other).." · Payload equal: "..tostring(item.value==other.value).." · Siblings: "..tostring(item.isSibling(other)).." · Belongs to this enum: "..tostring(item.isa(current))
  elseif action=="sum" then message="Real enum arithmetic result: "..tostring(item+assert(current[data.index]))
  elseif action=="clone" then message="Clone retains item identity: "..tostring(clone(item)==item)
  elseif action=="snapshot" then local text=serialize(item);local restored=deserialize(text);message="Serialized: "..text.." · Restored canonical identity: "..tostring(restored==item)
  elseif action=="mutate" then current[index].value=999
  elseif action=="build" then
   local names={};for name in tostring(data.names):gmatch("[^,]+") do names[#names+1]=name:match("^%s*(.-)%s*$") end
   assert(#names==3,"Supply exactly three comma-separated names")
   local values={};for i=1,3 do local n=tonumber(data['value'..i]);assert(n and n==n and math.abs(n)<=1000000,"Enter three finite numbers");values[i]=n end
   counter=counter+1;local created=enum("EnumDemoCustom"..counter,names,values)
   sets[5]=created;active=5;index=1;message="Created a new enum. Existing enum definitions were not changed."
  else error("Unknown enum action") end
 end)
 if not ok then message="Expected validation/operation rejection: "..tostring(errorText):gsub("^.-:%d+: ","") end
 return view()
end
print("Enums are named, protected items with identity and payloads. Equal payloads do not imply equal items.")
return view()
