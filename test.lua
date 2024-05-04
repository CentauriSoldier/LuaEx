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
    __unm = function(this, cdat)
        cdat.pro.HP = 0;
        return this;
    end,
},
{ --static public
    Desc = function()
        print("Creatures are good, they do stuff.")
    end,
    Count = 0,
},
{ --private
    DonkeyPoints = 667,
},
{ --protected
    HP      = 80,
    HPMax   = 45,
    super   = function(...)
        --constr
    end,
},
{ --public
    Creature = function(this, cdat, sName, nMaxHP)

        --print("Creature", type(this), type(cdat), type(sName), type(nMaxHP))
        cdat.pro.HPMax = nMaxHP;
        print("HPMAX SET: "..cdat.pro.HPMax)
        --cdat[PRO].HPMax = nMaxHP;
        --print(cdat[PRO].HPMax)
    end,
    GetHP = function(this, cdat)
        --print(cdat[PRO].HP)
        return cdat[PRO].HP;
    end,
    GetHPMax = function(this, cdat)
        --print(cdat[PRO].HP)
        return cdat.pro.HPMax;
    end,
    SetHP = function(this, cdat, nVal)
        --print(cdat[PRO].HP)
        cdat[PRO].HP = nVal;
        return this;
    end,
    IsDead = function(this, cdat)
        return cdat[PRO].HP <= 0;
    end,
    k = 4,
    Hits = 44,
    SayHello = function()
        print("hello, I'm a creature.")
    end
}, NO_PARENT, NO_INTERFACES, false);

--print(type(Dragon.k))
Human = class("Human",
{ --metamethods
    --__unm = function(this, cdat)
    --    return cdat[PRI].test;
    --end,
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
        --print("Human", type(this), type(cdat), type(sName), type(nMaxHP))
        Creature(sName, nMaxHP);
        --cdat[PRO].HPMax = nMaxHP;
        --print(cdat[PRO].HPMax)
    end,
    Jump = function(this, cdat)
        --cdat[PRO] = 6; --TODO make this throw an error
        --print(setmetatable(cdat, {}))
        --cdat[PRI].test = "asd";
        --print(cdat.ieur)
        --cdat.test = 34;
    end,
    Boop = function(this, cdat)
        print("Boop! It's a human.")
    end,
    Attack = function(this, cdat)
        print("I'm attacking.")
    end,
    loerwer = 90354
    --Hits = 55,
}, Creature, NO_INTERFACES, false);

Soldier = class("Soldier",
{ --metamethods
    __add = function(this, other, cdat)
        print(this.GetHP())
        print(other.GetHP())
        --print(this.GetHP(), other.GetHP(), cdat[PRI].test)--, other.GetHP())
        --print(type(this), type(other), type(cdat), type(t4))
    end,

},
{ --static public

},
{ --private
    test = 400,
},
{ --protected
    --Test = null,
    --HP = 33,
},
{ --public
    Soldier = function(this, cdat, sName, nMaxHP)
        --print("Soldier", type(this), type(cdat), type(sName), type(nMaxHP))
        Human(sName, nMaxHP);
        --cdat[PRO].HPMax = nMaxHP;
        --print(cdat.pro.HPMax);
        --print(cdat.pri.DonkeyPoints)
    end,
    Jump = function(this, cdat)
        --cdat[PRO] = 6; --TODO make this throw an error
        --print(setmetatable(cdat, {}))
        --cdat[PRI].test = "asd";
        --print(cdat.ieur)
        --cdat.test = 34;
    end,
    Boost = function(this, cdat)
        cdat.pro.HP = cdat.pro.HP * 2;
    end,
    Boop = function(this, cdat)
        print(cdat.pri.test)
    end,
    --Hits = 55,
}, Human, NO_INTERFACES, false);


--local Dragon = Creature("Dragon", 2000);
--print(Dragon.GetHPMax());
local Kaleb = Soldier("Kaleb", 120);
print(Kaleb.GetHPMax());
--local Bob   = Soldier("Bob", 39);
--local j = Kaleb + Bob
--print(-Kaleb)
--local meta = setmetatable(Kaleb, {});
--print(table.serialize(meta))
--meta.__type = "donky";
--Kaleb.Boost();
--Creature.Desc = function()end
--Creature.Desc();
--Creature.iut = 9;
--Creature.Count = 9;
--print(Creature.Count);
--Creature.Desc = 5;
--print(bVal)
--print(Kaleb.IsDead())
--Kaleb = -Kaleb
--print(Kaleb.GetHP())
--print(Kaleb.IsDead())
--Kaleb.Test = 4;
--Creature.SayHello()

--Soldier.rty = 98

--print(Kaleb.SetHP(33).GetHP());
--Kaleb.SetHP(65);
--print(Kaleb.GetHP())
--Kaleb.Jump()

--Kaleb.Hits = "sdad";
--print(Kaleb.Hits)
