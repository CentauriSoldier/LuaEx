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
--    print(sTag, bEnabled)
end
--print(#oTags)
--StatusSystem.test = 44
--print(StatusSystem.EFFECT.ENRAGED);
local oCircle = Circle(Point(5, 9), 10);
-- Example block of code to measure
local start = os.clock()  -- Record the start time

for i = 1, 10000 do
    -- Some computation here
    local x = oCircle.setRadius(34);
end

local delta = os.clock() - start  -- Calculate the delta time
--print("Elapsed time:", delta, "seconds")
local t = {x = 4, y =0}

if (rawtype(t["x"]) ~= "number" or rawtype(t["y"]) ~= "number") then
    print("Bad stuff!")
end





-- Example usage
local pCircle = circle(20, 40, 35);
pCircle.autoCalculate = false;
--line.start.x = 58;

for x = 1, 10000000 do
    pCircle.radius = x;
end

--pCircle.update()
print(pCircle.center.y);
