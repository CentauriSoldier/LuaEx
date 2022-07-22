function getsourcepath()
	--determine the call location
	local sPath = debug.getinfo(1, "S").source;
	--remove the calling filename
	local sFilenameRAW = sPath:match("^.+"..package.config:sub(1,1).."(.+)$");
	--make a pattern to account for case
	local sFilename = "";
	for x = 1, #sFilenameRAW do
		local sChar = sFilenameRAW:sub(x, x);

		if (sChar:find("[%a]")) then
			sFilename = sFilename.."["..sChar:upper()..sChar:lower().."]";
		else
			sFilename = sFilename..sChar;
		end

	end
	sPath = sPath:gsub("@", ""):gsub(sFilename, "");
	--remove the "/" at the end
	sPath = sPath:sub(1, sPath:len() - 1);

	return sPath;
end

--determine the call location
local sPath = getsourcepath();

--update the package.path (use the main directory to prevent namespace issues)
package.path = package.path..";"..sPath.."\\..\\?.lua;";

--load LuaEx
require("LuaEx.init");
--============= TEST CODE BELOW =============


local tLuaEX = rawget(_G, "__LUAEX__");

constant("BLARG", 32);

--print(tostring(os.getenv("string")))

--print(math.rgbtolong( 	0, 	255, 	0))
--print(math.longtorgb(math.rgbtolong(255, 255, 255)))
--local tLuaEX = _G.__LUAEX__;
--print(serialize.table(tLuaEX.__KEYWORDS__));

--print(tLuaEX.__KEYWORDS__[1]);
--print(string.iskeyword("nil"));
--test:pop()
