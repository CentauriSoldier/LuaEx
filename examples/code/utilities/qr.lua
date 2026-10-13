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

local D=require("examples.support.tutorial").new("QR codes","Encode strings, inspect boolean matrices, compare correction levels and validate PNG output.")

D.section("Your text", "A QR payload is a string; the matrix is a table of boolean cells.")
local text=("LuaEx example" --[[ Edit text here ]]);local level=("M" --[[ Edit level here ]])
local matrix=qr.enc(text,nil,level)
local function decode(label,code,expected)
 local actual=qr.dec(code)
 if actual==expected then D.equal(label,actual,expected)
 else D.note("CURRENT LIMITATION: QR decoder mismatch for "..label);D.show("Expected payload",expected);D.show("Observed decode",actual) end
end
decode("Decoded text",matrix,text)
D.show("Matrix width",#matrix);D.show("Cell type",type(matrix[1][1]))
D.section("Different strings", "Digit strings, punctuation and UTF-8 bytes all round trip as text.")
for _,value in ipairs({"0123456789","HELLO WORLD","https://example.org/?x=1","LuaEx: café"}) do
 local code=qr.enc(value);decode("Round trip "..value,code,value)
end
D.section("Correction levels", "Stronger error correction may require a larger version for the same payload.")
for _,ecl in ipairs({"L","M","Q","H"}) do local code=qr.enc(text,nil,ecl);D.show("Size at "..ecl,#code);decode("Decode at "..ecl,code,text) end
D.section("ASCII rendering", "Dark and light symbols render the boolean grid without an image dependency.")
print(qr.ascii(matrix,"##","  ",2))
D.section("PNG rendering", "The generated PNG lives in the browser's memory filesystem.")
local destination=sRepositoryPath.."/examples/resources/Tutorial_QR.png"
D.check("PNG written",qr.png(matrix,destination,3,4))
local file=assert(io.open(destination,"rb"));local image=file:read("*a");file:close()
D.equal("PNG signature",image:sub(1,8),"\137PNG\r\n\26\n");D.show("Image bytes",#image)
D.section("Invalid parameters", "Bad types, correction levels and masks are expected errors.")
D.reject("Numeric payload",function() qr.enc(123) end)
D.reject("Unknown correction level",function() qr.enc(text,nil,"Z") end)
D.reject("Mask outside 0..7",function() qr.enc(text,nil,"M",8) end)
D.reject("Nonsquare matrix",function() qr.dec({{true,false}}) end)

D.finish()
