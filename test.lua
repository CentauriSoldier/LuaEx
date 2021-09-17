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
--p(SCREEN_WIDTH);
--SCREEN_WIDTH = {};
--p(_G["enum"])
--local t = {
--	f = enum("SIM", {"CAM", "TV", "PC"})--, nil, true);
	--p(f)
--};
--enum = 44
--print(tostring(SIM))
--print(tostring(t.f))
--k = 56;
--SIM = 45;
--p(SIM);
--p(SIM.__count)
--.TV.value = 5
--SIM = 4;
--p(SIM);
--k = 5
--k =7
--p(_G["SIM"]);
--SIM = 5
--you can also create non-global enums
--local tMyTable = {
--	MY_COOL_ENUM 		= enum("MU_ENUM", 			{"STUFF", "THINGS", "ITEMS"}, nil, 			true),
--	MY_OTHER_COOL_ENUM 	= enum("MU__OTHER_ENUM", 	{"STUFF", "THINGS", "ITEMS"}, {1, 7, 99}, 	true),
--};

--p(tMyTable.MY_COOL_ENUM)
--_G.__LUAEX_PROTECTED__.SIM = 45;
--_G.__LUAEX_PROTECTED__.constant = 12;


local tPot = {
	CONTINUITY = enum("CONTINUITY", {"NONE", "REVOLVE", "ALT"}, {0, 1, 2}, true),
};
local tShadow = {};
constant("POT", tShadow);



setmetatable(tShadow, {
	__newindex = function(t, k, v)

		if (tPot[k]) then
			error("Attempt to overwrite protected value in constant 'POT' key '"..tostring(k).."' ("..type(k)..") with value "..tostring(v).." ("..type(v)..") .");
		end

	end,
	__index = tPot,
});







--enum("CONTINUITY", {"NONE", "REVOLVE", "ALT"});

--POT.CONTINUITY = 56;
--p(POT.CONTINUITY);
--p(CONTINUITY.NONE.value);
--POT.CONTINUITY = 00;
print(type(POT.CONTINUITY))
