-- Locate the shared bootstrap relative to this tutorial, regardless of cwd.
local pSource = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local pExamples = assert(pSource:match("^(.*)/[^/]+/[^/]+%.lua$"));
local tPaths = dofile(pExamples.."/support/bootstrap.lua");
local pDocs = tPaths.docs;

local D=require("examples.support.tutorial").new("INI","Parse text, convert typed values, edit configuration and demonstrate malformed input.")

D.section("Your configuration", "INI stores text; numeric and boolean accessors convert it explicitly.")
local name=D.input("name","Skystrike");local version=D.input("version",1);local enabled=D.input("enabled",true)
local text="# Tutorial configuration\n[General]\nName = "..name.."\nVersion = "..version.."\nEnabled = "..tostring(enabled).."\n\n[Style]\nSize = 18\n"
local ini=Ini(text);D.show("Input text",text)
D.equal("Name string",ini.GetValue("General","Name"),name)
D.section("Typed conversion", "Numbers and booleans differ from the original string values.")
D.equal("Raw version",ini.GetValue("General","Version"),tostring(version))
D.equal("Numeric version",ini.GetValueNumber("General","Version"),version)
D.equal("Boolean enabled",ini.GetValueBoolean("General","Enabled"),enabled)
D.section("Edit values", "SetValue accepts textual data and updates existing sections.")
ini.SetValue("General","Name",name.." updated")
D.equal("Edited name",ini.GetValue("General","Name"),name.." updated")
ini.SetValue("Style","Size","24");D.equal("Edited number",ini.GetValueNumber("Style","Size"),24)
D.section("Text round trip", "The formatted configuration can be reparsed with the same values.")
local output=tostring(ini);print("FORMATTED CONFIGURATION:\n"..output)
local restored=Ini(output);D.equal("Reparsed name",restored.GetValue("General","Name"),name.." updated")
D.equal("Reparsed flag",restored.GetValueBoolean("General","Enabled"),enabled)
D.section("Delete a value", "Deletion removes the key while preserving other values.")
ini.DeleteValue("Style","Size")
D.show("Missing value after deletion",ini.GetValue("Style","Size"))
D.equal("Unrelated name preserved",ini.GetValue("General","Name"),name.." updated")
D.section("Malformed text", "Expected parser errors are separate from successful checks.")
D.reject("Duplicate section",function() Ini("[General]\nName=A\n[General]\nName=B\n") end)
D.reject("Duplicate key",function() Ini("[General]\nName=A\nName=B\n") end)
D.reject("Missing equals",function() Ini("[General]\nThisIsBad\n") end)

D.finish()
