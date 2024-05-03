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

},
{ --protected
    HP      = 80,
    HPMax   = 100,
},
{ --public
    Creature = function(this, cdat, sName, nMaxHP)
        cdat[PRO].HPMax = nMaxHP;
        print(cdat[PRO].HPMax)
    end,
    GetHP = function(this, cdat)
        --print(cdat[PRO].HP)
        return cdat[PRO].HP;
    end,
    SetHP = function(this, cdat, nVal)
        --print(cdat[PRO].HP)
        cdat[PRO].HP = nVal;
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
    --HP = 33,
},
{ --public
    Human = function(this, cdat, sName, nMaxHP)
        cdat[PRO].HPMax = nMaxHP;
        print(cdat[PRO].HPMax)
    end,
    Jump = function(this, cdat)
        print("Human")
        --cdat[PRO] = 6; --TODO make this throw an error
        --print(setmetatable(cdat, {}))
        --cdat[PRI].test = "asd";
        --print(cdat.ieur)
        --cdat.test = 34;
    end,
    Boop = function(this, cdat)
        print("Boop! It's a human.")
    end,
    loerwer = 90354
    --Hits = 55,
}, Creature, NO_INTERFACES, false);

Soldier = class("Soldier",
{ --metamethods
    __add = function(this, other, cdat)
        --print(this.GetHP(), other.GetHP(), cdat[PRI].test)--, other.GetHP())
        --print(type(this), type(other), type(cdat), type(t4))
    end,
    __len = function(this, cdat)
        return cdat[PRI].test;
    end,
},
{ --static public

},
{ --private
    test = 567,
},
{ --protected
    --Test = null,
    --HP = 33,
},
{ --public
    Soldier = function(this, cdat, sName, nMaxHP)
        cdat[PRO].HPMax = nMaxHP;
        print(cdat[PRO].HPMax)
    end,
    Jump = function(this, cdat)
        print("Soldier")
        --cdat[PRO] = 6; --TODO make this throw an error
        --print(setmetatable(cdat, {}))
        --cdat[PRI].test = "asd";
        --print(cdat.ieur)
        --cdat.test = 34;
    end,
    Boop = function(this, cdat)
        print("Boop! It's a soldier.")
    end,
    --Hits = 55,
}, Human, NO_INTERFACES, false);

local Kaleb = Soldier("Kaleb", 120);
local Bob   = Soldier("Bob", 39);
local j = Kaleb + Bob
print(#Kaleb)
--Kaleb.Test = 4;

--print(Kaleb.SetHP(33).GetHP());
--Kaleb.SetHP(65);
--print(Kaleb.GetHP())
--Kaleb.Jump()
Kaleb.Boop()
--Kaleb.Hits = "sdad";
--print(Kaleb.Hits)
