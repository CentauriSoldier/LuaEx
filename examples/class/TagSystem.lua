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
local oTags = TagSystem();
local tTags = {"Massive", "Solder", "Rich", "DEmOn", "Baleful"};
--oTags.addMultiple(tTags);
--oTags.setMultipleEnabled(tTags);
--oTags.setMultipleEnabled({"Massive", "Solder"}, true);
for sTag, bEnabled in oTags.iterator() do
    --print(sTag, bEnabled)
end

local tRect = {
    {x = 0, y = 0},
    {x = 0, y = 3},
    {x = 5, y = 3},
    {x = 5, y = 0},
}

local oPoly = polygon(tRect);
oPoly.edges[2].start.y = 33;
print(oPoly.edges[2].start.y);
