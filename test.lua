--package.path = package.path..";LuaEx\\?.lua;..\\?.lua;?.lua";
package.path = package.path..";LuaEx\\?.lua";
require("init");

local pIni = "C:\\Users\\CS\\Sync\\Projects\\GitHub\\LuaEx\\initest.ini";

local test = ini(pIni, true, true);

--local  k = serialize.tablusere(tIni);

test:setvalue("Settings", "margin", 98)

--print(serialize.table(test:getsectionnames()));

--print(true);
type.poog = true;

local t = {}
setmetatable(t, {__type="poog"})

--print(type.ispoog(t));

--create a table
local tMice = {"Brown", "Black", "White", "Grey"};
--add a type and subtype
table.settype(tMice, "Mouse");
table.setsubtype(tMice, "Colors");
--get and print the sub type
print(type.sub(tMice));
