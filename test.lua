--package.path = package.path..";LuaEx\\?.lua;..\\?.lua;?.lua";
package.path = package.path..";LuaEx\\?.lua";
require("init");
local p = function(v)
	print(tostring(v).. " ("..type(v)..")")
end
