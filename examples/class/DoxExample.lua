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
To make this example work, you'll need to delete dox ingore files in the LuaEx folders.
]]

--ignore files cause dox to ignore files/folders where the files are found
local sDoxIgnoreFile 	= ".doxignore";    --ignores all files in current directory
local sDoxIgnoreSubFile = ".doxignoresub"; --ignores all files in sub directories
local sDoxIgnoreAllFile = ".doxignoreall"; --ignores all files current and subdirectories


local function writeToFile(path, content)
    -- Get the path to the "Documents" directory
    local path = os.getenv("USERPROFILE") .. path;

    -- Full path to the target file
    --local filePath = documentsPath .. "modules.lua"

    -- Open the file in write mode
    local file = io.open(path, "w")

    -- Check if the file was opened successfully
    if file then
        -- Write the content to the file
        file:write(content)
        -- Close the file
        file:close()
        print("Content written to " .. path)
    else
        -- Print an error message if the file could not be opened
        print("Error: Could not open file " .. path)
    end
end



--print(serialize(fFindFiles(pLuaEx)))


local oLuaExDox = LuaDox();
--oLuaExDox.importDirectory(io.normalizepath(sSourcePath.."\\..\\..\\LuaEx"), true);
oLuaExDox.importFile(io.normalizepath(sSourcePath.."\\..\\..\\LuaEx\\lib\\class.lua"), true);
--TODO create tests for each thing and use them as examples






--print(readFile(pFile))
--local tModules, tBlocks = oLuaExDox.importString(readFile(pFile));
--local tModules, tBlocks = oLuaExDox.importstring(k);

--for k, v in pairs(tBlocks or {}) do
    --print(k.." = "..serialize(v));
--end
