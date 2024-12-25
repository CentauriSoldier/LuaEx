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
local tSchema = {
    forbiiden   = {
        craft = true,
    },
    permitted   = {
        onEquip     = {"function"},
        onUnequip   = {"function"},
    },
    required    = {
        image       = {"string"},
        description = {"string"},
        weight      = {"number"},
    },
};

local sID = "ANI-RNG-0001";
local tBP = {
    class = "asd",
    id = sID,
    name = "asdasd",
    onEquip = function()
        print("The item has been equipped.");
    end,
    onUnequip = function()
        print("The item has been unequipped.");
    end,
    image = "myimage.png",
    description = "A powerful item!",
    weight = 12,
};

local g = CoG();
local b = g.getBlueprintium();
b.setSchema(tSchema);

--print("Is ID ("..sID..") valid? "..Blueprintium.idIsValid(sID))
--print(serialize(b.getSchema()));
local bValid, sMessage = b.isValid(tBP);
print(bValid, type(sMessage), sMessage);
