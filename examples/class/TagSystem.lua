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
    {x = 0,     y = 0},
    {x = 0,     y = 10},
    {x = 10,    y = 10},
    {x = 10,     y = 0},
}

local oPoly = polygon(tRect);
--oPoly.edges[2].start.y = 44;
--print(oPoly.edges[2].start.y);
--oPoly.vertices[3].x = 44;
--print(oPoly.vertices[3].x);
--print(oPoly.perimeter)
--oPoly.autoUpdate = 12
oPoly.vertices[2].y = 26;
for k, v in pairs(oPoly.vertices) do
    print(k, v.x, v.y)
end

for k, v in pairs(oPoly.edges) do
    print(k, "start", v.start.x, v.start.y)
    print(k, "start", v.stop.x, v.stop.y)
end

print(oPoly.perimeter);
print(oPoly.area);
