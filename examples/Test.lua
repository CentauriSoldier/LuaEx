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
    package.path = package.path.."C:\\Testing\\?.lua;"
    --load LuaEx
    require("LuaEx.init");
    require("Globals");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================
local oCat = Creature(Creature.TYPE.HERO, "Erchie", 0);
print(oCat.getAgility().getValue())
oCat.getXPSystem().setLevel(56);
print(oCat.getAgility().getValue())
print(oCat.getAbilitySystem().getCount())
