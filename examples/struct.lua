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
    package.path = package.path..";"..sSourcePath.."\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================


--[[NOTE:
    You can try to do disllowed things like adding fields, accesing nonexistent
    fields, changing value types, deserializing an object from string without an
    existing factory for that subtype, changing a read-only struct, creating
    read-only structs with null values, etc. to see error messages for those
    activities.



--create a mutable bullet struct table
local bImmutable = false; --set this to true to disallow value changes
local tBullet = {
    speed   = 5,
    damage  = 10,
    caliber = "9mm",
    owner   = null, --this type can be set later by each bullet created
};

--create the struct factory
xBullet = structfactory("bullet", tBullet, bImmutable);

--print the details of the struct factory
print("Bullet factory:\n", xBullet);

--print the factory's type and subtype
print("Factory's Type - Subtype :\n", type(xBullet), " - ",subtype(xBullet));

--make a bullet with the default values
local oBullet1 = xBullet();

--print the first bullet
print("\n\nBullet #1:\n", oBullet1);

--print the bullet's type and subtype
print("Bullet #1's Type - Subtype :\n", type(oBullet1), " - ",subtype(oBullet1));

--let's make another but with some custom initial values
local oBullet2 = xBullet({damage = 25, caliber = ".30-06"});

--print the second bullet
print("\n\nBullet #2:\n", oBullet2);

--clone oBullet1
local oBullet1Clone = clone(oBullet1);

--print the clone's details
print("\n\nBullet #1 Cloned:\n", oBullet1Clone);

--make some changes to oBullet1
oBullet1.speed = 35;
--print the bullet's caliber and speed
print("\n\nBullet #1 Caliber: ", oBullet1.caliber);
print("\n\nBullet #1's New Speed: ", oBullet1.speed);

--serialize oBullet1 and print it
local zBullet1 = serialize(oBullet1);
print("\n\nBullet #1 Serialized:\n", zBullet1);

--deserialize it (creating a new struct object) and show it's type and details
local oBullet1Deserialized = deserialize(zBullet1);
print("\n\nBullet #1 Deserialized:\n", "type: "..type(oBullet1Deserialized).."\n", oBullet1Deserialized);
]]

local XP = XPSystem(XPSystem.TYPE.LINEAR, 100, 10, 150, 3);

--XP.setType(XPSystem.TYPE.STEP);

for k, v in XP.XPBoundsIterator() do
    --print(k, v)
end

XP.setCallback(function(this, nOldLevel, nNewLevel, nFinalXP)
    print("New Level! -> "..this.getLevel(), nOldLevel, nNewLevel, nFinalXP)
end)

--print("XP: -> "..XP.getXPProtean().setValue(240).getValue())
--XP.getXPProtean().setValue(500)
print(XP.getLevel())
XP.setLevel(10);
print(XP.getLevel())
print(XP.getXPProtean().getValue())

--print("Level: -> "..XP.getLevel())

--for k, v in XP.XPBoundsIterator() do
--print(k, v)
--end

--XP.getXPProtean().setValue(950)
--print(XP.getXPRequired(3))
