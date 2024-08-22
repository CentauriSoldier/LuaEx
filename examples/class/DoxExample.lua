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
]]

--ignore files cause dox to ignore files/folders where the files are found
local sDoxIgnoreFile 	= ".doxignore";    --ignores all files in current directory
local sDoxIgnoreSubFile = ".doxignoresub"; --ignores all files in sub directories
local sDoxIgnoreAllFile = ".doxignoreall"; --ignores all files current and subdirectories

local oDoxLua = DoxLua("LuaEx");
local pImport = io.normalizepath(sSourcePath.."\\..\\..\\LuaEx");

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

oDoxLua.refresh();
oDoxLua.setOutputPath(pHTML);
oDoxLua.export("index");
