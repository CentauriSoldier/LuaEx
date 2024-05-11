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
    HP      = 20,
    HPMax   = 45,
},
{ --public
    Creature = function(this, cdat, sName, nMaxHP)
        --print("[In Creature] "..type(this).." constructor firing and calling parent constructor  ("..tostring(super)..") .")
        --print(type(this).." here we are.")
        --print("Creature", type(this), type(cdat), type(sName), type(nMaxHP))
        --cdat.pro.HPMax = nMaxHP;
        --print("HPMAX SET: "..cdat.pro.HPMax)
        --cdat[PRO].HPMax = nMaxHP;

        --print("HPMAX SET: "..cdat[PRO].HPMax)
        --cdat[PRO].HPMax = nMaxHP;
        --print(cdat.pro.HPMax)
    end,
    GetHP_FNL = function(this, cdat)
        --print(cdat[PRO].HP)
        return cdat.pro.HP;
    end,
    GetHPMax_FNL = function(this, cdat)
        --print(cdat[PRO].HP)
        --print("I am of type..."..type(this), cdat.pro.HPMax)

        return cdat.pro.HPMax;
    end,
    SetHP = function(this, cdat, nVal)
        --print(cdat[PRO].HP)
        cdat.pro.HP = nVal;
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
    Human = function(this, cdat, super, sName, nMaxHP)
        --print("[In Human] "..type(this).." constructor firing and calling parent constructor  ("..tostring(super)..") .")
        super(sName, nMaxHP);
        --print(rawtype(this).."->"..sName)
        --print("from "..type(this)..": super is -> "..tostring(super))
        --print("Human", type(this), type(cdat), type(sName), type(nMaxHP))
        --cdat[PRO].HPMax = nMaxHP;
        --print(type(this).." Constructor: HPMax set to "..cdat[PRO].HPMax..". Also my cdat table id is "..tostring(cdat))
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
        print("I'm attacking from "..type(type).." and my cdat table id is "..tostring(cdat))

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
    Soldier = function(this, cdat, super, sName, nMaxHP)
        --print("[In Soldier] "..type(this).." constructor firing and calling parent constructor  ("..tostring(super)..") .")
        super(sName, nMaxHP)
        --super(sName, nMaxHP)
        --print(type(super))
        --print("Soldier", type(this), type(cdat), type(sName), type(nMaxHP))
        --print("from "..type(this)..": super is -> "..tostring(super))
        --super(sName, nMaxHP);
        --print(cdat[PRO].HPMax)
        cdat.pro.HPMax = nMaxHP;
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
        cdat.pro.HP = cdat[PRO].HP * 2;
    end,
    Boop = function(this, cdat)
        return(cdat.pro.HPMax)
    end,
    --Hits = 55,
}, Human, NO_INTERFACES, false);








Specialist = class("Specialist",
{},
{},
{},
{},
{
    Specialist = function(this, cdat, super)
        super("asd", 76);
    end,
},
Soldier, NO_INTERFACES, false);







local Bob = Specialist("Bob", 999);
--local y = loadstring(string.dump(Kaleb.GetHPMax))();

--writeToFile(string.dump(Kaleb.GetHPMax))

--print(fh())
--print(Kaleb.GetHPMax());
--Kaleb.Attack();

--print(Soldier == Creature)


--Creature.Count = null;
--Creature.Count = "aasdasd";
--print(Creature.Count)




--Creature.Desc = null
--print("Boop: "..Kaleb.Boop())
--print(table.serialize(Kaleb))
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




function writeToFile(text)
    local file = io.open("C:\\Users\\CS\\output.txt", "w")  -- Open file for writing
    if file then
        file:write(text)  -- Write text to file
        file:close()  -- Close the file
        print("Text written to file successfully.")
    else
        print("Error: Unable to open file for writing.")
    end
end

-- Example usage:
local k = 4;
local function test()
    print("hello "..k)
end


--https://leafo.net/guides/function-cloning-in-lua.html
local function clone_function(fn)
  local dumped = string.dump(fn)
  local cloned = loadstring(dumped)
  local i = 1
  while true do
    local name = debug.getupvalue(fn, i)
    if not name then
      break
    end
    debug.upvaluejoin(cloned, i, fn, i)
    i = i + 1
  end
  return cloned
end

local fh = clone_function(test)
