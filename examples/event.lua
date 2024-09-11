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
local WEAPON_EVENT = enum("WEAPON_EVENT", {"ON_ATTACK", "ON_HIT", "ON_MISS"}, nil, true);

local function doDamage(...)

    for k, v in ipairs({...}) do
        print("Damaging "..v);
    end
    print("\n")
    return {"Blarg!", "Marg!", "Arg!"}
end

local function heal(...)

    for k, v in ipairs({...}) do
        print("Healing "..v);
    end
    print("\n")
    return {"Yoop!", "Doop!", "Moop!"}
end

local jOnAttack = event(WEAPON_EVENT.ON_ATTACK);
jOnAttack.addHook(doDamage);
jOnAttack.addHook(heal);

local tFirst    = jOnAttack.fire({44, 43, 22, 11, 55, 99}, {1.1, 2.2, 3.3, 9.9, 5.5, 8.8});
local tSecond   = jOnAttack.fire(nil, {1.1, 2.2, 3.3, 9.9, 5.5, 8.8});

for k, v in ipairs(tFirst) do

    for kk, vv in ipairs(v.output) do
        print(vv)
    end
end

for k, v in ipairs(tSecond) do

    for kk, vv in ipairs(v.output) do
        print(vv)
    end
end
