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
local null = null;

--create a table
local tMice = {"Brown", "Black", "White", "Grey"};

--create a string and interpolate variables into it
local sCats = "Cats are nice. My favorite type of cat is a ${bluecat}.\nBut even better are ${othercat}.\nI have ${catcount} cats." % {bluecat="blue and red cat", othercat="calicos", catcount=22};

--print the string
print(sCats);--[[
					Cats are nice. My favorite type of cat is a blue and red cat.

					But even better are calicos.

					I have 22 cats.
				]]
