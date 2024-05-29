--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
if not (LUAEX_INIT) then
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
    local sPath = getsourcepath();

    --update the package.path (use the main directory to prevent namespace issues)
    package.path = package.path..";"..sPath.."\\..\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================


--[[NOTE:

]]


local oItems = Set();
oItems.add(34)
oItems.add(44)
oItems.add(54)
oItems.add("cat")
oItems.add("moose")
oItems.add("frog")
oItems.add("bug")
oItems.add({})
oItems.add(true)
oItems.add(false)
oItems.add(nil)
oItems.add(null)

--RemoveME = set().importset(oItems).remove("bug");
--print(oItems.issubset(RemoveME))
--oItems.removeset(RemoveME);

--print(oItems.contains("ASdasd"));

local oOthers = Set();
--oOthers.add(tShared)
oOthers.add(34)
oOthers.add(44)
oOthers.add(700)
oOthers.add({})
oOthers.add("bunny")
oOthers.add("frog")
oOthers.add(false)
oOthers.add("bat")

--print(oOthers.contains("frog"))


print(oOthers.size())

for vItem in oOthers() do
    print(vItem)
end


A = Set();
B = Set();

for x = 1, 5 do
    --A.add(x)
end

for x = 3, 6 do
    --B.add(x)
end

--print(A)
---print(B)
--print(A - B)
--print(B - A)
--print(A + B)
--print(#true)
--print(Items - Others)
--print(fh())

S = Set().add("alex").add("casey").add("drew").add("hunter");
T = Set().add("casey").add("drew").add("jade");

S2 = Set({"alex", "hunter", "drew", "casey"});


V = Set().add("drew").add("glen").add("jade");
