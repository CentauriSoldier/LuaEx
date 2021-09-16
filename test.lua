--package.path = package.path..";LuaEx\\?.lua;..\\?.lua;?.lua";
package.path = package.path..";LuaEx\\?.lua";
require("init");
local p = function(v)
	print(tostring(v).. " ("..type(v)..")")
end

--p(_VERSION)
--p(enum)
--enum = 6;
constant("SCREEN_WIDTH", 563);
p(SCREEN_WIDTH);
--SCREEN_WIDTH = {};
--p(_G["enum"])
enum("SIM", {"CAM", "TV", "PC"});
--enum = 44
--print(tostring(SIM))

--p(SIM);
p(SIM.TV.value)
SIM.TV.value = 5
--SIM = 4;
--p(SIM);
--k = 5
--k =7
--p(_G["SIM"]);
--SIM = 5
