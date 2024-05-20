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

local function writeToFile(content)
    -- Get the path to the "Documents" directory
    local documentsPath = os.getenv("USERPROFILE") .. "\\Sync\\Projects\\GitHub\\LuaEx\\"

    -- Full path to the target file
    local filePath = documentsPath .. "modules.lua"

    -- Open the file in write mode
    local file = io.open(filePath, "w")

    -- Check if the file was opened successfully
    if file then
        -- Write the content to the file
        file:write(content)
        -- Close the file
        file:close()
        print("Content written to " .. filePath)
    else
        -- Print an error message if the file could not be opened
        print("Error: Could not open file " .. filePath)
    end
end

--run dox (or not)
if (false) then
    local pDox = sPath.."\\..\\Dox2\\dox\\doxold.lua";
    local fDox = loadfile(pDox);

    if (fDox) then
        local pSource = sPath.."\\LuaEx";
        local pWrite  = sPath.."\\dox";
        fDox();

        dox.onProcess = function(tModules)
            --print(serialize.table(tModules))
        end

        --dox.processDir(pSource, pWrite);
        local tModules = dox.getModules(pSource, pWrite);
        --sort and purge the modules
        dox.parse.sortModules();


        --writeToFile(serialize.table(tModules));

        function getHead()
            return [[
            <head>
                <meta charset="utf-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
                <meta name="description" content="" />
                <meta name="author" content="" />
                <title>Dox Viewer</title>
                <!-- Favicon-->
                <link rel="icon" type="image/x-icon" href="assets/favicon.ico" />
                <!-- Core theme CSS (includes Bootstrap)-->
                <link href="css/styles.css" rel="stylesheet" />
            </head>
            ]];
        end


        function getModulesSidebar()
            local sSidebar = [[
            <!--Modules Sidebar-->
            <div class="border-end bg-white" id="sidebar-wrapper">
                <div class="sidebar-heading border-bottom bg-light">Modules</div>
                <div class="list-group list-group-flush">]];

            local tMeta = getmetatable(tModules);
            for nIndex, sModule in pairs(tMeta.ProcessOrder) do --NOTE this is for multiple files....
                local tModule = tModules[sModule];
                sSidebar = sSidebar..[[

                    <a class="list-group-item list-group-item-action list-group-item-light p-3" href="#!">${module}</a>]] % {module = sModule};
            end

            sSidebar = sSidebar..[[

                </div>
            </div>]]

            print(sSidebar);
            return sSidebar;
        end





        --TextFile.WriteFromString(_ExeFolder.."\\modules.lua", serialize.table(tModules), false);
        --process the modules
            for nIndex, sModule in pairs(tMeta.ProcessOrder) do --NOTE this is for multiple files....
                --local tModule = tModules[sModule];

                --write the module file
                --local hModuleFile = io.open(pDir.."/modules/"..sModule..".html", "w");

                if hModuleFile then
                    --hModuleFile:write(dox.html.buildModule(sModule));
                    --hModuleFile:close();
                end

            end


        --getModulesSidebar()

    end

end
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
aPets[2] = 66;
aPets[3] = 1234;
aPets[4] = 4534;
aPets[5] = 66;
aPets[6] = 323464;

--aPets.sort()
--print(array)
--print(aPets.length)
--print(aPets[2]);
--for k, v in aPets() do
    --print(k, v)
--end
--aPets[5] = 34
--aPets.clear()
--print(aPets[4], aPets[5], aPets.length)
--print(aPets.indexof("bat"))
--print(aPets[5])
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







--for index, item in dox.MIME() do
    --print(item.name)
--end

local k = [=[
w34-=0-=ytph[]f;h'
fg
w-4or-03w94r-0iowkfes
poewiF)(*WE)(RUIWIJEFSIOJDf)
3-4=t0=-eworfpsldf
--[[f!
@module class
@func instance.build
@param table tKit The kit from which the instance is to be built.
@param table tParentActual The (actual) parent instance table (if any).
@scope local
@desc Builds an instance of an object given the name of the kit.
@ret object|table oInstance|tInstance The instance object (decoy) and the instance table (actual).
!f]]
-03489t-ieoksd;folksd;kf
34-50983-904tri-i45po34krfers
4598yt0r9tg-094t0-=34itjelkrmgdfg
34-0t9ipa;sda[siodwoih4fvhjsdkvjhwe9ir-348rwoeihfsldjf-0w49irowef
39048r39084750237eq9whdlashfd9isdyf98uw43roij23r0f7sudoifiol34jtr
w4890r79823u4rhjfwefus07ur23ohr9asd8yfsoij
]=]
--local oLuaExDox = doxlua();
--dl.importstring("Function", k);
