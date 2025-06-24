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
--[[NOTE
To make this example work, you'll need to delete/rename dox ingore files in the LuaEx folders or change the input path to your own
documented code files.
Make it work for linux and windows
]]

--ignore files cause dox to ignore files/folders where the files are found
local sDoxIgnoreFile 	= ".doxignore";    --ignores all files in current directory
local sDoxIgnoreSubFile = ".doxignoresub"; --ignores all files in sub directories
local sDoxIgnoreAllFile = ".doxignoreall"; --ignores all files current and subdirectories

local oDoxLua = DoxLua("LuaEx");
local pImport = io.normalizepath(sSourcePath.."\\..\\..\\LuaEx");

oDoxLua.importFile(io.normalizepath(sSourcePath.."\\..\\..\\LuaEx\\init.lua"), true);

local pHTML = os.getenv("USERPROFILE").."\\Sync\\Projects\\Github\\LuaEx\\docs";


local function printfile(pFile)
    --print(pFile)
end

local function importFiles(pDir)

    for _, pFile in pairs(io.listfiles(pDir, false, printfile, "lua")) do
        oDoxLua.importFile(pFile, true);
        --print(pFile);
    end

end

local tFolders = io.listdirs(pImport, true, importFiles);

local pIntro = io.normalizepath(sSourcePath.."\\..\\..\\docs\\intro.lua");

local fIntro = loadfile(pIntro);

if (type(fIntro) ~= "function") then
    error("Error reading Luax intro file.");--QUESTION DID I mean LuaEx?
end

local sContent = fIntro();

--load LuaEx's intro message
oDoxLua.setIntro(sContent);
--refresh the dox content
oDoxLua.refresh();
oDoxLua.setOutputPath(pHTML);
oDoxLua.export("index");

--for v in oDoxLua.eachBlockTag() do

--end

--print(("    <b>  Hello!  </b>"):htmltomd())

--oDoxLua.setBuilder(Dox.BUILDER.PULSAR_LUA);
oDoxLua.refresh();
oDoxLua.export("");

--[[!
    @fqxn CoG.ItemSystem.BaseItem
    @desc STUFF HERE
!]]
test = class("test",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = BaseItem(); --TODO FINISH
        --print(type(oNew))
        return oNew;
    end,
},
{--STATIC PUBLIC
    --BaseItem = function(stapub)
    --end,
    --enum("Item.ACTION", {"DISCARD"}, nil, true),
},
{--PRIVATE
},
{--PROTECTED
    Cat__autoRF        = "stuff here",

},
{--PUBLIC
    k__RO = 54,
    test = function(this, cdat)
        local pro = cdat.pro;

    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);


test2 = class("test2",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = BaseItem(); --TODO FINISH
        --print(type(oNew))
        return oNew;
    end,
},
{--STATIC PUBLIC
    --BaseItem = function(stapub)
    --end,
    --enum("Item.ACTION", {"DISCARD"}, nil, true),
},
{--PRIVATE
},
{--PROTECTED
    --Cat__autoRA        = "stuff here 2",

},
{--PUBLIC
    test2 = function(this, cdat,super)
        local pro = cdat.pro;
        --pro.Cat = "XDS";
        super(0);
    end,
    setCat = function(this, cdat)
        --cdat.pro.Cat ="AWWEQ#E"
    end,
},
test,  --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);

--local t2 = test2();
--t2.setCat()
--print(t2.getCat())

--print(BaseObject.RARITY.COMMON)
--print(t2.k)

--print(Rarity.MIN_PREFIX.LEGENDARY.value)
--print(Rarity.COLOR.COMMON)
--print(type(Rarity.COLOR.COMMON))
--print(type(Rarity.LEVEL.COMMON))
--print(Rarity.getMaxAffixTier(Rarity.LEVEL.RARE) - --Rarity.getMinAffixTier(Rarity.LEVEL.COMMON))

local kSys = eventrix(...);

local k = 0;

local function phello(...)
    k = k + 1
    --print("hello "..k.." "..(select(1, ...) or ""));
    return 34;
end
local function pdog(...)
    --print("I'm a dog "..(select(1, ...) or ""));
    --return "YAY!"
end
enum("EVENT", {"BARK"});
local eBark = EVENT.BARK;
kSys.addHook(eBark, phello)
kSys.addHook(eBark, pdog)
--kSys.fire(eBark);

--kSys.setHookActive(eBark, phello, true);
--kSys.setEventActive(eBark, false);
local i = kSys.fire(eBark, "mucho doggy!");
--kSys.removeHook(eBark, phello);
--print(kSys.getHookOrdinal(eBark, pdog))

for k, v in pairs(i) do
    if v == EVENTRIX_NIL then
    --print(k, v)
end
end
