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

local Creature = class("Creature",
{--metamethods
},
{--public static members
},
{--private members
    TESTING = 88,
},
{--protected members
    HP__AUTO__      = 10,
    HPMax__AUTO__   = 100,
    Damage__AUTO__  = 5,
    AC__AUTO__      = 0,
    Armour__AUTO__  = 0,
    Move = function(this, cdat)

    end,
    functionTest = null,
},
{--public members
    Creature = function(this, cdat, super, nHP, nHPMax)
        super();
        --print(type(cdat.pro["HPMax"]))
        --print("Creature", nHP, nHPMax)
        cdat.pro.HP     = nHP < 1 and 1 or nHP;
        cdat.pro.HP     = nHP > nHPMax and nHPMax or nHP;
        cdat.pro.HPMax  = nHPMax;
        --print("I am a "..class.getname(class.of(this)))
        functionTestLocal = function()
            print("hgello")
        end
        cdat.pro.functionTest = functionTestLocal;
    end,
    isDead = function(this, cdat)
        --print(this, cdat)
        print(cdat.pro.functionTest())
        return cdat.pro.HP <= 0;
    end,
    getTesting = function(this, cdat)
        return cdat.pri.TESTING;
    end,
},
CoG, false, NO_INTERFACES);

local HP_MAX = 120; -- this is an example of a private static field
local s = sAuthCode;
local Human = class("Human",
{--metamethods
},
{--public static members
    Human = function(cHuman, sAuthCode)

    end,
},
{--private members
    Name__auto__ = "",
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
Creature, false, NO_INTERFACES);

Soldier = class("Soldier",
{--metamethods
},
{--public static members
    Soldier = function(cSoldier, sAuthCode)
        local fSchema = schema.Record {
            name        = schema.String,
            id          = Factorium.SCHEMA_ID,
            --usertype  = s.OneOf("admin", "moderator", "user"),
            --nicknames = s.Collection(s.String),
            --rights    = s.Tuple(rights, rights, rights)
        }


        local function fromBlueprint(sID, tBP, ...)
            local oRet, sMessage;
            local tArgs = {...};

            local oSoldier = cSoldier(tArgs[1], tArgs[2]);

            return oSoldier, sMessage;
        end

        local bSuccess, sMesssage = Factorium.registerFactory(cSoldier, sAuthCode, fSchema, fromBlueprint);

        if not (bSuccess) then
            print(sMesssage);
        end

    end,
    --deserialize = function(tData)
    --    print(tData)
    --end,
},
{--private members
    --Name__AUTO__ = "",
},
{--protected members
},
{--public members
    Soldier = function(this, cdat, super, sName, nHP)
        --print("human", sName, nHP, HP_MAX)
        super(sName, nHP);
    end,
},
Human, false, NO_INTERFACES);




--Huil = Human("Huil", 50);
--print(class.getbase(class.of(Huil)))
--Bob = Soldier("Bob", 56)

local tSoldierBP = {
    name = "Bobby",
    id   = "SOL-BAS-0001",
};

local bSuccess, sMesssage = Factorium.addBlueprint(Soldier, tSoldierBP);

if not (bSuccess) then
    print(sMesssage);
end

local oSoldier, sError = Factorium.fromBlueprint("SOL-BAS-0001", "Noob", 87);

if not (oSoldier) then
    print(sError);
end

print(oSoldier.getName())
print(oSoldier.GetHP())
oSoldier.SetArmour(12);
local sSerialized = serialize(oSoldier);
--print(sSerialized);
local oNew = deserialize(sSerialized);
--print(sSerialized)
print(oNew.getName())
print(oNew.GetHP())
print(oNew.GetArmour())
print(oNew.isDead())
