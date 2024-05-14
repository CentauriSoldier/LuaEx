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
print("PATH "..sPath)
--load LuaEx
require("LuaEx.init");
--============= TEST CODE BELOW =============


Creature = class("Creature",
{--metamethods
},
{--public static members
},
{--private members

},
{--protected members
    HP_AUTO     = 10,
    HPMax_AUTO  = 100,
    Damage_AUTO = 5,
    AC_AUTO     = 0,
    Armour_AUTO = 0,
    Move = function(this, cdat)

    end
},
{--public members
    Creature = function(this, cdat, nHP, nHPMax)
        cdat.pro.HP     = nHP < 1 and 1 or nHP;
        cdat.pro.HP     = nHP > nHPMax and nHPMax or nHP;
        cdat.pro.HPMax  = nHPMax;
    end,
    isdead = function(this, cdat)
        return cdat.pro.HP <= 0;
    end,
},
NO_PARENT, NO_INTERFACES, false);



local HP_MAX = 120; -- this is an example of a private static field

Human = class("Human",
{--metamethods
},
{--public static members
},
{--private members
    Name_AUTO = "",
},
{--protected members
},
{--public members
    Human = function(this, cdat, super, sName, nHP)
        --print("human", sName, nHP, HP_MAX)
        super(nHP, HP_MAX);
        cdat.pri.Name = sName;
    end,
},
Creature, NO_INTERFACES, false);



Soldier = class("Soldier",
{--metamethods
    __add = function(left, right, cdat)

    end,
},
{--public static members
    RANK = enum("RANK",
    {"Private", "PrivateSecondClass",   "PrivateFirstClass",    "Specialist", "Corporal", "Sergeant", "StaffSergeant",  "SergeantFirstClass",   "MasterSergeant",   "FirstSergeant",    "SergeantMajor",    "CommandSergeantMajor",     "SergeantMajoroftheArmy"},
    {"Private", "Private Second Class", "Private First Class",  "Specialist", "Corporal", "Sergeant", "Staff Sergeant", "Sergeant First Class", "Master Sergeant",  "First Sergeant",   "Sergeant Major",   "Command Sergeant Major",   "Sergeant Major of the Army"}, true);
},
{--private members
    Rank = null--Soldier.RANK,
},
{--protected members
},
{--public members
    Soldier = function(this, cdat, super, sName, nHP, eRank)
        --print("Soldier", sName, nHP)
        super(sName, nHP);
        --cdat.pri.Rank = eRank;
    end,
    serialize = function(this, cdat)
        return "Name: ${name}\r\nMax HP: ${hpmax}\r\nHP: ${hp}\t\nDamage: ${damage}\r\nAmour: ${armour}" % {
            name = this.GetName(), hpmax = cdat.pro.HPMax, hp = cdat.pro.HP, damage = cdat.pro.Damage, armour = cdat.pro.Armour
        };
    end,
    TVal = null,
},
Human, iCombator, false);





--Wheeler = Soldier("Wheeler",    50);
--Ellis   = Soldier("Ellis",      85);

local tShared = {};

local Items = set();
Items.add(34)
Items.add(44)
Items.add(54)
Items.add("cat")
Items.add("moose")
Items.add("frog")
Items.add("bug")
Items.add({})
Items.add(true)
Items.add(false)
Items.add(nil)
Items.add(null)

RemoveME = set().addset(Items).remove("bug");
--print(Items.issubset(RemoveME))
--Items.removeset(RemoveME);

--print(Items.contains("ASdasd"));

local Others = set();
--Others.add(tShared)
Others.add(34)
Others.add(44)
Others.add(700)
Others.add({})
Others.add("bunny")
Others.add("frog")
Others.add(false)
Others.add("bat")

local oCpmp = Others.complement(Items);

for k in oCpmp() do
    print(k)
end

--print(Others.size())
--for k in Others() do
    --print(k)
--end

local tPlates = stack();
tPlates.push(1)
tPlates.push(2)
tPlates.push(3)
tPlates.push(4)
tPlates.push(5)
tPlates.push(6)
tPlates.push(7)

local oLine = queue();
oLine.enqueue(1);
oLine.enqueue(2);
oLine.enqueue(3);
oLine.enqueue(4);
oLine.enqueue(5);
oLine.enqueue(6);
--print(Plates.pop())
--print(Plates.pop())
--print(Plates.pop())
--Plates.reverse();
--Plates.clear()return
local oInterset = Items.intersection(Others);
--local oClone = oInterset.clone();
--print(Others.peek())
for k in oInterset() do
    --print(k)
end

--print(fh())

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



--[[
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

--local fh = clone_function(test)
]]
