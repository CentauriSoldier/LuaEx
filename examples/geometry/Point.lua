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
local D = require("examples.support.tutorial").new("Point","Coordinates, all quadrants and axes, arithmetic, mutation and snapshots.")

D.section("Your coordinate", "Positive, negative, zero and fractional coordinates are valid numbers.")
local x=D.input("x",-3.5);local y=D.input("y",4)
local point=Point(x,y);D.show("Point",point);D.show("Region",point.getQuadrant())
local actualX,actualY=point.get();D.equal("X",actualX,x);D.equal("Y",actualY,y)
D.section("All quadrants and axis cases", "The origin and each signed axis have their own labels.")
for _,case in ipairs({{1,1,"I"},{-1,1,"II"},{-1,-1,"III"},{1,-1,"IV"},{0,0,"O"},{1,0,"X"},{-1,0,"-X"},{0,1,"Y"},{0,-1,"-Y"}}) do
    D.equal("Point("..case[1]..","..case[2]..")",Point(case[1],case[2]).getQuadrant(),case[3])
end
D.section("Vector arithmetic", "Addition/subtraction produce new Points. Negate a clone when the original must remain unchanged.")
local offset=Point(2,-1);local sum=point+offset;local difference=point-offset
D.show("Offset",offset);D.show("Sum",sum);D.show("Difference",difference);D.show("Negated independent clone",-clone(point))
D.equal("Sum X",sum.getX(),x+2);D.equal("Difference Y",difference.getY(),y+1)
D.equal("Original X is unchanged",point.getX(),x)
D.note("Unary minus currently mutates its receiver in place; this is why the tutorial negates clone(point).")
D.section("Mutation", "setX/setY/set update the same instance. Current set ignores nonnumeric components.")
point.setX(0).setY(-2);D.equal("Now on negative Y axis",point.getQuadrant(),"-Y")
point.set("ignored",5);D.equal("Nonnumeric X leaves X alone",point.getX(),0);D.equal("Numeric Y is applied",point.getY(),5)
D.section("Equality and ownership", "Coordinate equality does not imply shared mutable state.")
local copy=clone(point);D.check("Equal coordinates",copy==point);D.check("Distinct instances",not rawequal(copy,point))
copy.setX(100);D.equal("Original still independent",point.getX(),0)
D.section("Serialization and defaults", "Restoration returns a Point with its coordinates; omitted construction uses the origin.")
local restored=deserialize(serialize(Point(x,y)));D.equal("Restored X",restored.getX(),x);D.equal("Restored Y",restored.getY(),y)
D.equal("Default region",Point().getQuadrant(),"O")
D.note("Ordering operators are implementation-specific coordinate comparisons, not a spatial distance metric.")
D.finish()
