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
package.path = package.path..";"..sPath.."\\?.lua;";

--load LuaEx
require("LuaEx.init");
--============= TEST CODE BELOW =============


Creature = class("Creature",
{--metamethods
},
{--public static members
},
{--private members
    DeathCount = 0,
    Allies = {},
},
{--protected members
    HP_AUTO     = 10,
    HPMax_AUTO  = 100,
    Damage_AUTO = 5,
    AC_AUTO     = 0,
    Armour_AUTO = 0,
},
{--public members
    Creature = function(this, cdat, nHP, nHPMax)
        cdat.pro.HP     = nHP < 1 and 1 or nHP;
        cdat.pro.HP     = nHP > nHPMax and nHPMax or nHP;
        cdat.pro.HPMax  = nHPMax;
    end,
    isDead = function(this, cdat)
        return cdat.pro.HP <= 0;
    end,
    kill = function(this, cdat)
        cdat.pro.HP = 0;
    end,
    move = function(this, cdat)

    end
},
NO_PARENT, NO_INTERFACES, false);



local HP_MAX = 120; -- this is an example of a private static field

Human = class("Human",
{--metamethods
    __tostring = function(left, right, cdat)
        return "human"
    end,
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

--local Dan = Human("Dan", 45);
--print("Name: "..Dan.getName());                         --> "Name: Dan"
--print("HP: "..Dan.getHP());                             --> "HP: 45:"
--print("Type: "..type(Dan));                             --> "Type: Human"
--print("Is Dead? "..Dan.isDead());                       --> "Is Dead? false"
--print("Kill Dan ):!"); Dan.kill();                      --> "Kill Dan ):!"
--print("Is Dead? "..Dan.isDead());                       --> "Is Dead? true"
--print("Set Name: Dead Dan"); Dan.setName("Dead Dan");   --> "Set Name: Dead Dan"
--print("Name: "..Dan.getName());                         --> "Name: Dead Dan"

--print(null < 1);    --> true
--print(null < "");   --> true
--print(null < nil);  --> false
--local k = null;
--print(k)            --> null

Soldier = class("Soldier",
{--metamethods
    __tostring = function(left, right, cdat)
        return "soldier"
    end,
    --__unm = function(this, cdat)
    --    print("soldier")
    --end,
    __add = function(left, right, cdat)
        print(type.matachesonlyleft(right))
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
            name = this.getName(), hpmax = cdat.pro.HPMax, hp = cdat.pro.HP, damage = cdat.pro.Damage, armour = cdat.pro.Armour
        };
    end,
    TVal = null,
},
Human, iCombator, false);




Wheeler = Soldier("Wheeler",    50);
Ellis   = Human("Ellis",      85);
--print(Wheeler)

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

RemoveME = set().importset(Items).remove("bug");
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

--print(Others.contains("frog"))


--print(Others.size())
--for k in Others() do
    --print(k)
--end

local Plates = stack();
Plates.push(1)
Plates.push(2)
Plates.push(3)
Plates.push(4)
Plates.push(5)
Plates.push(6)
Plates.push(7)
Plates.push(8)
--print(Plates)
--print(Plates.reverse())

local oLine = queue();
oLine.enqueue(1);
oLine.enqueue(2);
oLine.enqueue(3);
oLine.enqueue(4);
oLine.enqueue(queue({"cat", "mouse", "ant"}));
oLine.enqueue(6);
--print(oLine)
--print(oLine.reverse())
--print(Plates.pop())
--print(Plates.pop())
--Plates.reverse();
--Plates.clear()return
--local oInterset = Items.intersection(Others);
--local oClone = oInterset.clone();
--print(Others.peek())
--for k in oInterset() do
    --print(k)
--end

A = set();
B = set();

for x = 1, 5 do
    --A.add(x)
end

for x = 3, 6 do
    --B.add(x)
end

--print(A)
---print(B)
--print(A - B)
--print(B - A)
--print(A + B)
--print(#true)
--print(Items - Others)
--print(fh())

S = set().add("alex").add("casey").add("drew").add("hunter");
T = set().add("casey").add("drew").add("jade");

S2 = set({"alex", "hunter", "drew", "casey"});


V = set().add("drew").add("glen").add("jade");
-- Example of eliminating if-then statement using a table
local x = "98"

-- Define a table mapping conditions to actions
local conditionActions = {
    [type(x) ~= "number"] = function() print("invalid input") end,
    [type(x) == "number" and x == 0] =function() print("x is 0") end,
    [type(x) == "number" and x  > 0] = function() print("x is positive") end,
    [type(x) == "number" and x  < 0] = function() print("x is not positive") end,
}
local action = conditionActions[true]  -- Retrieve the action based on the condition
if action then
    --action()  -- Execute the action if it exists
end
--local k = {}
--settype(k, "Doggie")
--print(isDoggie(kl))
function checkme(vVal, sExpected)
    return type(vVal) == sExpected;
end
--print(isCreature(Wheeler))
--print(isSoldier(Wheeler))
local isCreature = type.isCreature;
--print(isCreature(Wheeler))

--local aPets = array({12, 34, 65, 89});
local aPets = array({34, 5, 89});
local aPets = array(6);

aPets[1] = 23423434;
aPets[2] = 2e54;
aPets[3] = 1234;
aPets[4] = 4534;
aPets[5] = 66;
aPets[6] = 323464;

aPets.sort()
--print(array)
--print(aPets.length)
--print(aPets[2]);
for k, v in aPets() do
    print(k, v)
end
--aPets.clear()
--print(aPets[4], aPets[5], aPets.length)
--print(aPets.indexof("bat"))
print(aPets.indexof("bat"))
--aPets[4] = 67
--print(aPets[4]);
--print(aPets.length);
--isSoldier(Wheeler)
--print(serialize.table(type.getall()))
--dox.processDir(sPathToMyLuaFiles, sPathToTheOutputDirectory);
--print(S)
--print(T)
--print(V)
--print(S - T);
