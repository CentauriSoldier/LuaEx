-- Independent code tutorial. Edit the values below, then Run code.
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

local D=require("examples.support.tutorial").new("CSV","Import small tables, distinguish textual cells from numbers, edit values and export results.")

local CSV=require("examples.support.CSV")
D.section("Your row", "CSV cells are strings; numeric parameters are converted explicitly.")
local quantity=(3 --[[ Edit quantity here ]]);local label=("Boots" --[[ Edit label here ]])
assert(not label:find("[,\r\n\\]"),"Use a label without delimiter, newline or escape characters")
local input=sRepositoryPath.."/examples/resources/Tutorial_Input.csv"
local file=assert(io.open(input,"w"));file:write("Name,Quantity,Enabled\n"..label..","..quantity..",true\nPack,2,false\n");file:close()
local data=CSV();data.import(input,false)
D.equal("Two rows",data.getRowCount(),2);D.equal("Three columns",data.getColumnCount(),3)
D.section("Index and name lookup", "Column names retain the imported header spelling.")
D.equal("First label",data.getCell(1,1),label)
D.equal("Named lookup",data.getCell(1,"Name"),label)
D.show("Column names",data.getColumnNames())
D.section("Types and conversion", "The text '3' is not numeric 3; boolean text also needs explicit conversion.")
D.equal("Quantity is text",type(data.getCell(1,2)),"string")
D.equal("Numeric conversion",tonumber(data.getCell(1,2)),quantity)
D.equal("Boolean conversion",data.getCell(1,3)=="true",true)
D.section("Iteration", "Print coordinates, header and content for every cell.")
local cells=0;for row,column,name,value in data.eachCell() do cells=cells+1;D.show("Row "..row..", column "..column.." ("..name..")",value) end
D.equal("Six cells visited",cells,6)
D.section("Mutation and export", "setCell coerces the new value to text; export writes the edited table.")
data.setCell(1,2,quantity+1);D.equal("Edited quantity",data.getCell(1,2),tostring(quantity+1))
local output=sRepositoryPath.."/examples/resources/Tutorial_Output.csv";data.export(output,false)
local exported=assert(io.open(output,"r"));local content=exported:read("*a");exported:close()
print("EXPORTED CSV:\n"..content);D.check("Edited quantity in output",content:find(tostring(quantity+1),1,true)~=nil)
D.section("Validation and limits", "Unknown columns are errors; this class uses backslash escaping rather than RFC 4180 quoting.")
D.reject("Unknown column",function() data.getCell(1,"Unknown") end)
D.reject("Unimplemented sorting",function() data.sortByColumn(1) end)

D.finish()
