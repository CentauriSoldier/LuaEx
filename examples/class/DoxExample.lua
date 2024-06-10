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


local function simple_hash256(input_string)
    local hash = {0, 0, 0, 0, 0, 0, 0, 0}
    local prime = 31

    for i = 1, #input_string do
        local char = string.byte(input_string, i)
        for j = 1, #hash do
            hash[j] = (hash[j] * prime + char) % 2^32
        end
        prime = prime + 2  -- Change the prime for each character to introduce more variability
    end

    local hash_string = ""
    for i = 1, #hash do
        hash_string = hash_string .. string.format("%08x", hash[i])
    end

    return hash_string
end

local function test_collision_rate256(num_samples, string_length)
    local hash_table = {}
    local collisions = 0

    for i = 1, num_samples do
        local input = ""
        for j = 1, string_length do
            input = input .. string.char(math.random(32, 126))  -- Generate a random string of given length
        end
        local hash = simple_hash256(input)
        if hash_table[hash] then
            collisions = collisions + 1
        else
            hash_table[hash] = true
        end
    end

    return collisions, num_samples
end

-- Run the collision test for the 256-bit hash function
math.randomseed(os.time())
local num_samples = 1000000  -- 1 million samples
local string_length = 40      -- Length of each random string
--local collisions, total_samples = test_collision_rate256(num_samples, string_length)

--print("Total samples: " .. total_samples)
--print("Collisions: " .. collisions)
--print("Collision rate: " .. (collisions / total_samples))

local oLuaExDox = LuaDox();
--oLuaExDox.importDirectory(io.normalizepath(sSourcePath.."\\..\\..\\LuaEx"), true);
oLuaExDox.importFile(io.normalizepath(sSourcePath.."\\..\\..\\LuaEx\\lib\\class.lua"));

local pHTML = os.getenv("USERPROFILE").."\\Sync\\Projects\\GitHub\\DoxTest.html"
oLuaExDox.setOutputPath(pHTML);
oLuaExDox.output(Dox.OUTPUT.HTML);
--oLuaExDox.export();
--TODO create tests for each thing and use them as examples

--print(readFile(pFile))
--local tModules, tBlocks = oLuaExDox.importString(readFile(pFile));
--local tModules, tBlocks = oLuaExDox.importstring(k);

--for k, v in pairs(tBlocks or {}) do
    --print(k.." = "..serialize(v));
--end
