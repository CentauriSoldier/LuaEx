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
local D = require("examples.support.tutorial").new("Line","Lengths, slopes, intersection, special orientations and endpoint ownership.")
-- Local compatibility adapter for the legacy Line implementation on Lua 5.4.
if math.atan2==nil then math.atan2=function(y,x)return math.atan(y,x) end end
D.note("Line calls the older atan2 name; this tutorial supplies the equivalent Lua 5.4 math.atan(y,x) adapter.")

D.section("Your line", "Two Points define a line. Length is Euclidean distance and midpoint is the coordinate average.")
local x=D.input("end_x",3);local y=D.input("end_y",4)
local start,stop=Point(0,0),Point(x,y);local line=Line(start,stop)
D.show("Start",line.getStart());D.show("End",line.getEnd());D.equal("Length",line.getLength(),math.sqrt(x*x+y*y))
D.equal("Delta X",line.getDeltaX(),x);D.show("Current stored delta Y",line.getDeltaY());D.show("Mathematical delta Y",y)
D.note("The current Line update uses end X when computing delta Y. Slope and distance interpolation therefore need comparison with the mathematical reference below.")
D.equal("Midpoint X",line.getMidPoint().getX(),x/2);D.equal("Midpoint Y",line.getMidPoint().getY(),y/2)
D.section("Horizontal and vertical", "A vertical slope is undefined; ask slopeIsDefined before interpreting its stored slope.")
local horizontal=Line(Point(-2,3),Point(4,3));local vertical=Line(Point(2,-3),Point(2,5))
D.equal("Horizontal length",horizontal.getLength(),6);D.show("Current horizontal slope",horizontal.getSlope());D.show("Mathematical horizontal slope",0)
D.check("Vertical slope undefined",not vertical.slopeIsDefined());D.equal("Vertical length",vertical.getLength(),8)
D.section("Crossing lines", "The intersection helper solves the infinite supporting lines; do not assume segment clipping.")
local rising=Line(Point(0,0),Point(4,4));local falling=Line(Point(0,4),Point(4,0))
local cross=rising.getPointOfIntersection(falling)
D.show("Intersection",cross);D.equal("Intersection X",cross.getX(),2);D.equal("Intersection Y",cross.getY(),2)
local parallel=Line(Point(0,1),Point(4,5));D.equal("Parallel supporting lines have no unique intersection",rising.getPointOfIntersection(parallel),nil)
D.section("Point at a distance", "For a nonzero line, distance scales the unit direction vector and can extrapolate past the end.")
local standard=Line(Point(0,0),Point(3,4));local halfway=standard.getPointAtDistance(2.5)
D.equal("Halfway X",halfway.getX(),1.5);D.show("Current halfway Y",halfway.getY());D.show("Mathematical halfway Y",2)
D.show("Beyond endpoint at distance 10",standard.getPointAtDistance(10))
D.section("Endpoint ownership and updates", "The constructor copies the supplied Points; setters recalculate cached values.")
stop.set(99,99);D.equal("Original endpoint input is independent",line.getEnd().getX(),x)
line.setEnd(Point(6,8));D.equal("Recalculated length",line.getLength(),10)
D.section("Degenerate lines and current limits", "A zero-length line has no direction; avoid requesting a point at distance from it.")
local zero=Line(Point(1,1),Point(1,1));D.equal("Zero length",zero.getLength(),0)
D.observe("Current Line clone support",function()return clone(standard) end)
D.note("Line deserialization and several relation methods are unfinished in this version. Use plain endpoint snapshots rather than claiming those APIs work.")
D.finish()
