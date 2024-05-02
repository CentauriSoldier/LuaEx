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

--localization
local MET = CLASS_ACCESS_INDEX_METATABLES;
local PRI = CLASS_ACCESS_INDEX_PRIVATE;
local PRO = CLASS_ACCESS_INDEX_PROTECTED;
local PUB = CLASS_ACCESS_INDEX_PUBLIC;
local INS = CLASS_ACCESS_INDEX_INSTANCES;

Creature = class("Creature",
{ --metamethods

},
{ --static public

},
{ --private
    HP      = 80,
    HPMax   = 100,
},
{ --protected

},
{ --public
    Creature = function(this, cdat, sName, nMaxHP)
        cdat[PRO].HPMax = nMaxHP;
        print(cdat[PRO].HPMax)
    end,
    GetHP = function(this, cdat)
        --print(cdat[PRO].HP)
        return cdat[PRI].HP;
    end,
    SetHP = function(this, cdat, nVal)
        --print(cdat[PRO].HP)
        cdat[PRI].HP = nVal;
        return this;
    end,
    k = 4,
    Hits = 44,
}, NO_PARENT, NO_INTERFACES, false);

local Dragon = Creature("Dragon", 2000);
---print(Dragon.GetHP());

--print(type(Dragon.k))
Human = class("Human",
{ --metamethods

},
{ --static public

},
{ --private
    test = 567,
},
{ --protected
    Test = null,
},
{ --public
    Human = function(this, cdat, sName, nMaxHP)
        cdat[PRO].HPMax = nMaxHP;
        print(cdat[PRO].HPMax)
    end,
    --Hits = 55,
}, Creature, NO_INTERFACES, false);



local Kaleb = Human("Kaleb", 120);
--Kaleb.Test = 4;

--print(Kaleb.SetHP(33).GetHP());
Kaleb.Hits = -34;
Kaleb.Hits = "sdad";
print(Kaleb.Hits)
--print(tostring(os.getenv("string")))

--print(math.rgbtolong( 	0, 	255, 	0))
--print(math.longtorgb(math.rgbtolong(255, 255, 255)))
--local tLuaEX = _G.__LUAEX__;
--print(serialize.table(tLuaEX.__KEYWORDS__));

--print(tLuaEX.__KEYWORDS__[1]);
--print(string.iskeyword("nil"));
--test:pop()
