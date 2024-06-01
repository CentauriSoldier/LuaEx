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

local nMinFileLength = 5; --some character plus a dot then the file extension (e.g., t.lua)

--get directory spacer
local _ = package.config:sub(1,1);
--get the os type
local sOSType = _ == "\\" and "windows" or (_ == "/" and "unix" or "unknown");

local tFileFindMethods = {
	["unix"] = {
		fileFind = function(sDir, sFile, bRecursive)
			local sRecurs = bRecursive and "" or " -maxdepth 1 ";
			return 'find "'..sDir..'"'..sRecurs..'-name "'..sFile..'"'
		end,
	},
	["windows"] = {
		fileFind = function(sDir, sFile, bRecursive)
			local sRecurs = bRecursive and " /s" or "";
			return 'dir "'..sDir.."\\"..sFile..'" /b'..sRecurs;
		end,
	},
};

function getProcessList(sDir, bRecurse, tInputFiles)
	local tRet = type(tInputFiles) == "table" and tInputFiles or {};

	--setup the commands
	--local sGetFilesCommand 	= (_ == "\\") and	('dir "'..sDir..'\\*.*" /b /a-d'):gsub("\\\\", "\\") 	or ('find '..sDir.."/"..'-maxdepth 1 ! –type d'):gsub("//", "/");
	--local sGetDirsCommand 	= (_ == "\\") and	('dir "'..sDir..'\\*.*" /b /d'):gsub("\\\\", "\\") 		or ("ls -a -d /*"):gsub("//", "/");
    --local sGetFilesCommand      = (_ == "\\") and ('dir "'..sDir..'\\*.*" /b /a-d 2>nul'):gsub("\\\\", "\\")    or ('find '..sDir.."/"..'-maxdepth 1 ! –type d'):gsub("//", "/");
    --local sGetDirsCommand       = (_ == "\\") and ('dir "'..sDir..'\\*.*" /b /ad 2>nul'):gsub("\\\\", "\\")     or ("ls -a -d /* 2>/dev/null"):gsub("//", "/");
    local sGetFilesCommand      = (_ == "\\") and ('dir "'..sDir..'\\*.*" /b /a-d 2>nul'):gsub("\\\\", "\\")    or ('find "'..sDir..'" -maxdepth 1 ! -type d 2>/dev/null'):gsub("//", "/");
    local sGetDirsCommand       = (_ == "\\") and ('dir "'..sDir..'\\*.*" /b /ad 2>nul'):gsub("\\\\", "\\")     or ("ls -a -d '"..sDir.."'/* 2>/dev/null"):gsub("//", "/");

	local hFiles 	= io.popen(sGetFilesCommand);

	--process files and folders
	if (hFiles) then
		local bIgnore 		= false;
		local bIgnoreSub	= false;
		local bIgnoreAll 	= false;
		local tFiles 		= {};

		--look for ignore files
		for sFile in hFiles:lines() do

			if (sFile == sDoxIgnoreAllFile) then
				bIgnoreAll = true;
				break; --no need to continue at this point
			end

			if (sFile == sDoxIgnoreSubFile) then
				bIgnoreSub = true;
			end

			if (sFile == sDoxIgnoreFile) then
				bIgnore = true;
			end

			if not (bIgnoreAll or bIgnore) then
				tFiles[#tFiles + 1] = sFile;
			end

		end

		--only process items if the .doxignoreall file was NOT found
		if not (bIgnoreAll) then

			--add (any) files that exist to the return table
			for nIndex, sFile in pairs(tFiles) do

				--check that the file type is valid --TODO chance this since it can use other languages
				if (sFile:len() >= nMinFileLength and sFile:reverse():sub(1, 4):lower() == "aul.") then
					--add the file to the list
					tRet[#tRet + 1] = sDir.._..sFile;
                    print("file found: "..sDir.._..sFile);
				end

			end

			--process subdirectories
			if not (bIgnoreSub) then
				local hDirs	= io.popen(sGetDirsCommand);

				if (hDirs) then

					for sDirectory in hDirs:lines() do
						getProcessList(sDir.._..sDirectory, bRecurse, tRet);
					end

				end

			end

		end

	end

	return tRet;
end




local pLuaEx = getsourcepath().."\\..\\..\\";
getProcessList(sSourcePath.."\\..\\..\\LuaEx", true);






local function readFile(pFile)
    local sContent;
    local sError;

    local hFile = io.open(pFile, "r");

    if not (hFile) then
        sError = "Could not open file: "..pFile;
    else
        local content = hFile:read("*all");
        hFile:close();
    end

    return sContent, sError;
end


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





local oLuaExDox = DoxLua();
for k in oLuaExDox.blockTagGroups() do

    for f in k.blockTags() do
        --print(k.getName().." | "..f.getDisplay())
    end

end

--TODO create tests for each thing and use them as examples


--print(readFile(pFile))
--local tModules, tBlocks = oLuaExDox.importString(readFile(pFile));
--local tModules, tBlocks = oLuaExDox.importstring(k);

for k, v in pairs(tBlocks or {}) do
    --print(k.." = "..serialize(v));
end
