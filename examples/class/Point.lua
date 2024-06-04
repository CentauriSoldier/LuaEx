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

--create new points and print them
local oP1 = Point(-5, -8);
local oP2 = Point(0, 7);
local oP3 = Point(-10, 16);
local oP4 = Point(6, -12);

print("P1: ", oP1);
print("P2: ", oP2);
print("P3: ", oP3);
print("P4: ", oP4);

--serialize P1
local sP1 = serialize(oP1);
print("\n\nP1 Serialized: "..sP1);
--deserialize P1
local oP1_1 = deserialize(sP1);
print("\nP1 Deserialized: ", oP1_1);

--get the points' cartesian position
print("\nP1 Position: ",    oP1.getQuadrant());
print("P2 Position: ",      oP2.getQuadrant());
print("P3 Position: ",      oP3.getQuadrant());
print("P4 Position: ",      oP4.getQuadrant());

--change points' values
print("\nChanging values...")
oP1.setX(0);
oP2.setY(0);
oP3.set(4, 20);
oP4.setY(0);

print("P1: ", oP1);
print("P2: ", oP2);
print("P3: ", oP3);
print("P4: ", oP4);

print("\nP1 Position: ",    oP1.getQuadrant());
print("P2 Position: ",      oP2.getQuadrant());
print("P3 Position: ",      oP3.getQuadrant());
print("P4 Position: ",      oP4.getQuadrant());

--negatation
print("\nNegation");
print("P1: ", -oP1);
print("P2: ", -oP2);
print("P3: ", -oP3);
print("P4: ", -oP4);

--cloning and other things
local oP1Clone = clone(oP1);
print("\nP1 Cloned: ", oP1Clone);
--test equality of the original to the clone
print("P1 == oP1Clone: ", oP1 == oP1Clone);
--create a new point by adding two points
local oP5 = oP1 + oP3;
print("\nP1 + P3 = P5:\n(", oP1, ") + (", oP3, ") = (", oP5, ')');
--create another new point by adding two points
local oP6 = oP1 - oP3;
print("\nP1 - P3 = P6:\n(", oP1, ") - (", oP3, ") = (", oP6, ')');
