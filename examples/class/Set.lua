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

local oA = Set();
oA.add(34);
oA.add(44);
oA.add(54);
oA.add("cat");
oA.add("moose");
oA.add("frog");
oA.add("bug");
oA.add({});
oA.add(true);
oA.add(false);
oA.add(nil);
oA.add(null);

--RemoveME = set().importset(oA).remove("bug");
--print(oA.issubset(RemoveME))
--oA.removeset(RemoveME);

--print(oA.contains("ASdasd"));

local oB = Set();
--oB.add(tShared)
oB.add(34);
oB.add(44);
oB.add(700);
oB.add({});
oB.add("bunny");
oB.add("frog");
oB.add(false);
oB.add("bat");

--print(oB.contains("frog"))


print(oB.size())

for vItem in oB() do
    print(vItem)
end


A = oA;
B = oB;

for x = 1, 5 do
    --A.add(x)
end

for x = 3, 6 do
    --B.add(x)
end

print("A -> "..tostring(A))
print("B -> "..tostring(B))
print("A-B -> "..tostring(A - B))
print("B-A -> "..tostring(B - A))
print("A+B -> "..tostring(A + B))
--print(#true)
--print(oA - oB)
--print(fh())

S = Set().add("alex").add("casey").add("drew").add("hunter");
T = Set().add("casey").add("drew").add("jade");

S2 = Set({"alex", "hunter", "drew", "casey"});


V = Set().add("drew").add("glen").add("jade");
