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

]]

--initialized with a size, but no type.
local aPet = array(5);

--show some info on the aPet array
print("aPets is an "..type(aPet).." made by the "..type(array)..'.');

--print the value at index 5 (null)
print("aPet[3] -> "..tostring(aPet[3]));

--initialized with a size and type.
local aNoPet = array({"Aligator", "T-Rex", "Rino", "Leech", "Dragon"});

--print the aNoPet array
print("aNoPet (Don't pet these things! Stop it, no pet!) -> ", aNoPet);

--add some items to the aPet array (and set the type with the first assignment)
aPet[1] = "Cat";
aPet[2] = "Frog";
aPet[3] = "Doggo";
aPet[4] = "Lizard";
--aPet[4] = 45; --this will throw an error for trying to set a different type
aPet[5] = "Bunny";

--print the aPet array
print("aPet (It's okay, you can pet these ones.) -> ", aPet);

--index some items by index
print("Don't pet the "..aNoPet[3]..'! But, you can pet the '..aPet[1]..'.');

--iterate over one of the arrays using the built-in iterator
for nIndex, sValue in aNoPet() do
    print("No pet the "..sValue..'!');
end

--show the legth of an array
print("There are "..aPet.length.." animals you can pet.");

--sort and print the arrays
aPet.sort();
aNoPet.sort()

print("\naPet Sorted: -> "..tostring(aPet));
print("aNoPet Sorted: -> "..tostring(aNoPet));

--reverse sort the aNoPet array and print the results
aNoPet.sort(function(a, b) return a > b end)
print("aNoPet Reverse Sorted: -> "..tostring(aNoPet));

print("\n")

--you can create arrays of any single type (including functions)
local aMethods = array(3);
aMethods[1] = function()
    print("You can make an array of functions/methods.");
end
aMethods[2] = function(...)
    local sOutput = "You can referene the aMethods "..type(aMethods)..".\n";
    sOutput = sOutput.."\nThen, you can do whatever else you want even setting the other items."

    if (type(aMethods[3]) == "null") then
        aMethods[3] = function()
            print("Calling aMethods[2] will print this very boring message.");
        end

    end

    print(sOutput);
end

aMethods[1]();
aMethods[2]();
aMethods[3]();

--TODO clone and copy examples
local aCloned = clone(aNoPet);
print(aCloned)
