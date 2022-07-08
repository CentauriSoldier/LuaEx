--package.path = package.path..";LuaEx\\?.lua;..\\?.lua;?.lua";
package.path = package.path..";LuaEx\\?.lua";
require("init");

local pIni = "C:\\Users\\CS\\Sync\\Projects\\GitHub\\LuaEx\\initest.ini";

local test = ini(pIni, true, true);

--local  k = serialize.table(tIni);

test:setvalue("Settings", "margin", 0)

print(test);
