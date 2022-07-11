--package.path = package.path..";LuaEx\\?.lua;..\\?.lua;?.lua";
package.path = package.path..";LuaEx\\?.lua";
require("init");

local pIni = "C:\\Users\\CS\\Sync\\Projects\\GitHub\\LuaEx\\initest.ini";

local test = ini(pIni, true, true);

--local  k = serialize.table(tIni);

test:setvalue("Settings", "margin", 98)

--print(serialize.table(test:getsectionnames()));


local s = 0;

print(-#1 * -#0);
--print(serialize.table(debug.getregistry()));

--print("A test ${here}" % {here="BLARG"})
