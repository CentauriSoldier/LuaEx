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
    package.path = package.path..";"..sSourcePath.."\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================


local function runExample(sExample)
    local pExample = getsourcepath().."\\..\\..\\examples\\"..sExample..".lua";
    return dofile(pExample)
end
--runExample("struct");
--runExample("class\\Set");
--tF, tR = io.list("C:", true)
--tF, tR = io.list(sSourcePath.."\\LuaEx", true, nil, {".txt"});

--for x = 1, #tF do
--    print(tF[x], tR[x])
--end
local tFiles, tRel = io.dir(sSourcePath.."\\LuaEx", false, 0, {"lua"})

--local tParts = io.splitpath(sSourcePath.."\\LuaEx\\test.ext")

for k, v in pairs(tFiles) do
    --print(v)
end
local myt = {};
setmetatable(myt, {
    __newindex = function(t, k, v)
        print(t, k, v)
    end

});

myt[4] = "asd";
myt[2] = nil
