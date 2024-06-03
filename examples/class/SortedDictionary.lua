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

--create a new SortedDictionary
local oDictionary = SortedDictionary()
local function printMe()--TODO add tostring/ser/des methods
    for k, v in pairs(oDictionary) do
        print(k, v);
    end
end


--add some items
oDictionary.add("OR", "Oregon");
oDictionary.add("KS", "Kanas");
oDictionary.add("CA", "California");
oDictionary.add("ND", "North Dakota");
oDictionary.add("WA", "Washington");
oDictionary.add("TX", "Texas");
oDictionary.add("AK", "Arkansas");

--print the dictionary
print("Sort normally (a < b) :")
printMe();

--set an item to nil
oDictionary.set("WA", nil);

--print the dictionary again
print("\nSet a value to nil: ")
printMe();

--set the previously-set nil value to something else
print("\nSet the nil value to something else: ")
oDictionary.set("WA", "New Washington");
printMe();

--set a new sorter function and print the results
print("\nSet a new sorter function.")
oDictionary.setSortFunction(function (a, b)
    return a > b;
    --return a.foo < b.bar --Uncomment to see an error for bad sorter function
end)
printMe();

print("\nSet the sorter function back to default.");
oDictionary.setSortFunction();
printMe();

--chain and print
print("\nChain some actions together.");
oDictionary.set("TX", "New Texas").set("TX", "Newer Texas").set("TX", "Newest Texas");
print(oDictionary.get("TX"));

--remove a key and print
print("\nRemove California.");
oDictionary.remove("CA");
printMe();
