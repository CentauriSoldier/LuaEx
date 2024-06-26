--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
local sSourcePath = "";
if not (LUAEX_INIT) then
    --sSourccePath = "";

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
     sSourcePath = getsourcepath();

    --update the package.path (use the main directory to prevent namespace issues)
    package.path = package.path..";"..sSourcePath.."\\..\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================
--[[    Line 1: From (1, 1) to (4, 4)
    Line 2: From (1, 4) to (4, 1)

The intersection point of these two lines is (2.5, 2.5).]]
--create a couple lines
local oLine1 = Line(Point(1, 1), Point(4, 4));
local oLine2 = Line(Point(1, 4), Point(4, 1));
--print("oLine1\n", oLine1);
--print("\noLine2\n", oLine2);

--test the lines' interactions
--print("Interection: ", oLine1.getPointOfIntersection(oLine2));
--print(oLine1.getR())
--print(oLine1.getTheta())


--[[
local Creature = class("Creature",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Creature = function(stapub) end,
},
{--PRIVATE
    _name = "",
    _health = 100,
    _energy = 100,
},
{--PROTECTED

},
{--PUBLIC
    Creature = function(this, cdat, name)

        cdat.pri._name = name or "Unnamed Creature"
    end,

    getName = function(this, cdat)
        return cdat.pri._name
    end,

    getHealth = function(this, cdat)
        return cdat.pri._health
    end,

    getEnergy = function(this, cdat)
        return cdat.pri._energy
    end,

    setHealth = function(this, cdat, newHealth)
        cdat.pri._health = newHealth
    end,

    setEnergy = function(this, cdat, newEnergy)
        cdat.pri._energy = newEnergy
    end,

    rest = function(this, cdat)
        cdat.pri._energy = cdat.pri._energy + 10
        if cdat.pri._energy > 100 then cdat.pri._energy = 100 end
    end
},
nil,   -- extending class
false, -- if the class is final
nil    -- interface(s) (either nil, or interface(s))
);

local Human = class("Human",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Human = function(stapub) end,
},
{--PRIVATE
    _gender = ""
},
{--PROTECTED

},
{--PUBLIC
    Human = function(this, cdat, super, name, gender)

        super(name)
        --super(name)
        --super(name)
        cdat.pri._gender = gender or "Unknown"
    end,

    getGender = function(this, cdat)
        return cdat.pri._gender
    end,

    speak = function(this, cdat, message)
        print(this.getName() .. " says: " .. message)
    end
},
Creature,   -- extending class
false, -- if the class is final
nil    -- interface(s) (either nil, or interface(s))
);

local Soldier = class("Soldier",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Soldier = function(stapub) end,
},
{--PRIVATE
    _rank = "",

},
{--PROTECTED

},
{--PUBLIC
    Soldier = function(this, cdat, super, name, gender, rank)

        --super(name, gender)

        super(name, gender)
        cdat.pri._rank = rank or "Private"
    end,

    getRank = function(this, cdat)
        return cdat.pri._rank
    end,

    salute = function(this, cdat)
        print(this.getName() .. " salutes!")
    end
},
Human,   -- extending class
false, -- if the class is final
nil    -- interface(s) (either nil, or interface(s))
);

local Infantry = class("Infantry",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Infantry = function(stapub) end,
},
{--PRIVATE
_squad ="''"
},
{--PROTECTED

},
{--PUBLIC
    Infantry = function(this, cdat, super, name, gender, rank, squad)
        super(name, gender, rank)
        --super(name, gender, rank)
        cdat.pri._squad = squad or "Alpha"
    end,

    getSquad = function(this, cdat)
        return cdat.pri._squad
    end,

    advance = function(this, cdat)
        print(this.getName() .. " advances forward!")
    end
},
Soldier,   -- extending class
false, -- if the class is final
nil    -- interface(s) (either nil, or interface(s))
);


local mySoldier = Soldier("John Doe", "Male", "Corporal")
local myInfantry = Infantry("Jane Smith", "Female", "Sergeant", "Bravo")

local myInfantry1 = Infantry("Amy Johnson", "Female", "Sergeant", "Charlie")
local myInfantry2 = Infantry("Mark Smith", "Male", "Lieutenant", "Delta")
local myInfantry3 = Infantry("Emily Davis", "Female", "Private", "Echo")

print("Soldier's Name:", mySoldier.getName())
print("Soldier's Gender:", mySoldier.getGender())
print("Soldier's Rank:", mySoldier.getRank())
mySoldier.salute()

print("\nInfantry's Name:", myInfantry.getName())
print("Infantry's Gender:", myInfantry.getGender())
print("Infantry's Rank:", myInfantry.getRank())
print("Infantry's Squad:", myInfantry.getSquad())
myInfantry.advance()

print("\n\nInfantry 1's Name:", myInfantry1.getName())
print("Infantry 1's Gender:", myInfantry1.getGender())
print("Infantry 1's Rank:", myInfantry1.getRank())
print("Infantry 1's Squad:", myInfantry1.getSquad())
myInfantry1.advance()

print("\nInfantry 2's Name:", myInfantry2.getName())
print("Infantry 2's Gender:", myInfantry2.getGender())
print("Infantry 2's Rank:", myInfantry2.getRank())
print("Infantry 2's Squad:", myInfantry2.getSquad())
myInfantry2.advance()

print("\nInfantry 3's Name:", myInfantry3.getName())
print("Infantry 3's Gender:", myInfantry3.getGender())
print("Infantry 3's Rank:", myInfantry3.getRank())
print("Infantry 3's Squad:", myInfantry3.getSquad())
myInfantry3.advance()
]]
--[[
-- Example usage
local tAutoVisibility = {
    stapub = {
        err__FNL = function()end,
    },
    pri = {
        --health__AUTO__FNL = function() end,
        --armor__AUTORO = function() end,
        --weapon__AUTOWO = function() end,
        --stamina__RO = 100,
        --mana__WO = 200
    },
    pro = {
        Health__autog__RO = 5,
        --speed__AUTORO = function() end,
        --power__AUTOWO = function() end,
        --defense__RO = 50,
        --agility__WO = 75
    },
    pub = {
        energy__RO = 300
    }
}

for _, sCAI in pairs({"pri", "pro", "pub", "stapub"}) do
    for sName, vItem in pairs(tAutoVisibility[sCAI]) do
        local sBaseName, bFinal, bReadOnly, sGetter, sSetter = getDirectiveInfo(tKit, sCAI, sName, vItem)
        print("Base Name:", sBaseName)
        print("Final:", bFinal)
        print("Read Only:", bReadOnly)
        print("Write Only:", bWriteOnly)
        print("Getter:", sGetter)
        print("Setter:", sSetter)
        print()
    end
end
]]
