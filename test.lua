package.path = package.path..";LuaEx\\?.lua;..\\?.lua;?.lua";
require("init");
local p = print;

enum("SIM", {"CAM", "TV", "PC"});
p(SIM.CAM.name);
print(tostring(SIM.CAM))

print(type(p))
