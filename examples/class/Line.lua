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
print("Interection: ", oLine1.getPointOfIntersection(oLine2));
print(oLine1.getR())
print(oLine1.getTheta())
--TODO FINISH
