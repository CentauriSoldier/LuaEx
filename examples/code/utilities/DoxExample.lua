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

local D=require("examples.support.tutorial").new("Documentation generation","Generate HTML from real source comments, inspect output and preserve the generated artifact in memory.")

D.section("Your document", "A title is a string; imported comments provide the documentation structure.")
local title=("LuaEx null documentation" --[[ Edit title here ]])
local dox=DoxLua(title)
D.section("Import source", "Import a known source file directly without native directory enumeration.")
local source=sRepositoryPath.."/LuaEx/lib/null.lua"
local file=assert(io.open(source,"r"));local text=file:read("*a");file:close()
D.show("Source bytes",#text);D.check("Source contains documentation",text:find("@fqxn",1,true)~=nil)
dox.importFile(source,true)
D.section("Introduction", "Escape user text before placing it into HTML markup.")
local escaped=title:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub('"',"&quot;")
dox.setIntro("<h1>"..escaped.."</h1><p>Generated from the real LuaEx null source.</p>")
D.show("Escaped title",escaped)
D.section("Build and export", "The HTML builder writes into the example resources directory.")
dox.refresh();dox.setOutputPath(sRepositoryPath.."/examples/resources")
local destination=dox.export("DoxExample");D.show("Destination",destination)
D.section("Inspect generated data", "A complete document is a nonempty HTML string, not a class instance.")
local output=dox.getOutput();D.equal("Output type",type(output),"string")
D.check("Nonempty output",#output>0);D.show("HTML bytes",#output)
D.check("Contains your intro",output:find(escaped,1,true)~=nil)
D.section("Verify artifact", "Read back the exact generated HTML from the memory filesystem.")
local generated=assert(io.open(sRepositoryPath.."/examples/resources/DoxExample.html","wb"));generated:write(output);generated:close()
local saved=assert(io.open(sRepositoryPath.."/examples/resources/DoxExample.html","rb"));local restored=saved:read("*a");saved:close()
D.equal("Artifact bytes",#restored,#output);D.check("Artifact matches output",restored==output)

D.finish()
