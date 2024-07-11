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
local oProtean1 = Protean();
local oProtean2 = Protean();
local oProtean3 = Protean();

oProtean1.setLinker(1);
oProtean2.setLinker(1);
oProtean3.setLinker(1);

oProtean2.setValue(10);
oProtean2.setLinker();
oProtean1.setValue(20);
--write a for loop from 1 to 20

oProtean1.setValue(Protean.MULTIPLICATIVE_PENALTY, 0.46);
local a  = Actor();

--print(n.getHealthPool().get())
--print(Boots == Pool)
local oFeet     = ItemSlot("Feet", {Boots});
--for x = 1, 40000 do
--local k = Boots();
local i = ItemSlotManager();


--end
--oFeet.setLocked(true)
--oFeet.setItem(k)
--oFeet.removeItem();
--print(oFeet.isOccupied())
--print(oFeet.isLocked())
--print(oFeet.getName())
--print(class.isinlineage(CoG, CoG))
--class.isinlineage(CoG, CoG)
--print(class.ischildorself(Boots, Boots))
--print(class.isparentorself(Boots, Boots))
