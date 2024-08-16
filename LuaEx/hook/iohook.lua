local string    = string;
local table     = table;
local execute   = os.execute;
local io        = io;

-- Define the os type
local _     = package.config:sub(1, 1);
local __    = _ == "/" and "\\" or "/";
local _sOSType = _ == "\\" and "windows" or (_ == "/" and "unix" or "unknown");

-- Determine the operating system type
local _bOSIsWindows     = _sOSType == "windows";
local _bOSIsUnix        = _sOSType == "unix";
local _bOSIsUnknown     = _sOSType == "unknown";
local _sParent          = "..";
local _pRoot            = ".";


local function splitpath(sPath)--TODO fix
    local tRet = {
        directory   = "",
        drive       = "",
        extension   = "",
        filename    = "",
    }


    -- Extract drive letter if present (Windows only)
    local sDrive, path;
    if (_bOSIsWindows) then
        sDrive, path = sPath:match("^([A-Za-z]:)[/\\]?(.*)")
        if drive then
            tRet.drive = sDrive
        else
            path = sPath
        end
    else
        path = sPath
    end

    -- Remove trailing slash if present
    if path:sub(-1) == _ then
        path = path:sub(1, -2)
    end

    -- Extract directory and filename
    local directory, filename = path:match("^(.*)[" .. _ .. "]([^" .. _ .. "]+)$")
    if directory then
        tRet.directory = directory
        tRet.filename = filename
    else
        tRet.filename = path
    end

    -- Extract extension without the dot
    local extension = tRet.filename:match("%.([^.]+)$")
    if extension then
        tRet.extension = extension
        tRet.filename = tRet.filename:sub(1, -(#extension + 2)) -- +2 to remove the dot as well
    end

    return tRet
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.listdirs
    @desc Lists all directories in a given path (optionally recursively).
    @param string sPath The path which to search for directories.
    @param boolean|nil bRecursive Whether to recurse through subdirectories.
    @param function|nil fCallback The function to call when a directory is found.
    <br>This function must accept a string as its first argument which will be the full path to the directory found.
    @ret table tDirectories A numerically-indexed table whose values are full paths of the found directories.
    @ex
    local function printdir(pDir)
        print(pDir);
    end

    local tDirectories = io.listdirs("C:\\Windows\\System32\\Speech", true, printdir);

    --\[\[ Output->
    C:\Windows\System32\Speech\Common
    C:\Windows\System32\Speech\Engines
    C:\Windows\System32\Speech\SpeechUX
    C:\Windows\System32\Speech\Common\en-US
    C:\Windows\System32\Speech\Engines\SR
    C:\Windows\System32\Speech\Engines\TTS
    C:\Windows\System32\Speech\Engines\SR\en-US
    C:\Windows\System32\Speech\SpeechUX\en-US
    \]\]
!]]
function listdirs(sPath, bRecursive, fCallback)
    local tRet = {};
    local sCommand;
    local bHasCallback = type(fCallback) == "function";
    local sRecurse = '';

    if _bOSIsWindows then
         sRecurse = bRecursive and '/s' or '';
        sCommand = 'dir "'..sPath..'" /b /ad '..sRecurse..' 2>nul';
    elseif _bOSIsUnix then
        sRecurse = bRecursive and '' or ' -maxdepth 1';
        sCommand = 'find "'..sPath..'" -type d'..sRecurse..' 2>/dev/null';
    else
        error("Error getting list of directories. Unsupported operating system.");
    end

    local uOutput = io.popen(sCommand);

    if (uOutput) then

        for sLine in uOutput:lines() do
        -- Normalize path separators for Windows
        local pDir = _bOSIsWindows and sLine:gsub(__, _) or sLine;
        -- Remove the trailing path separator if present
        pDir = pDir:gsub("[/\\]+$", "");
        pDir = bRecursive and pDir or sPath.._..pDir;
        -- Store the directory
        table.insert(tRet, pDir)

            -- Invoke the callback function if provided
            if (bHasCallback) then
                fCallback(pDir, false); --adding false for io.list callback
            end

        end

    end

    return tRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.listfiles
    @desc Lists all files in a given path (optionally recursively).
    @param string sPath The path which to search for directories.
    @param boolean|nil bRecursive Whether to recurse through subdirectories.
    @param function|nil fCallback The function to call when a file is found.
    <br>This function must accept a string as its first argument which will be the full path to the file found.
    @ret table tDirectories A numerically-indexed table whose values are full paths of the found directories.
    @ex
    local function printfile(pFile)
        print(pFile);
    end

    local tDirectories = io.listfiles("C:\\Windows\\System32", false, printfile, "exe");
    --\[\[ Output->
    C:\Windows\System32\agentactivationruntimestarter.exe
    C:\Windows\System32\AgentService.exe
    C:\Windows\System32\AggregatorHost.exe
    C:\Windows\System32\aitstatic.exe
    ...
    \]\]
!]]
function listfiles(sPath, bRecursive, fCallback, ...)
    local tRet          = {};
    local sCommand      = '';
    local tTypes        = {...} or arg;
    local bCheckTypes   = #tTypes > 0;
    local bHasCallback  = type(fCallback) == "function";
    local sRecursion    = '';

    if _bOSIsWindows then
        --sCommand = 'dir "'..sPath..'" /b /a-d 2>nul'
        sRecursion = bRecursive and ' /s' or ''
        sCommand = 'dir "'..sPath..'" /b /a-d' .. sRecursion .. ' 2>nul'
    elseif _bOSIsUnix then
        --sCommand = 'find "'..sPath..'" -maxdepth 1 -type f 2>/dev/null'
        sRecursion = bRecursive and '' or ' -maxdepth 1'
        sCommand = 'find "'..sPath..'"' .. sRecursion .. ' -type f 2>/dev/null'
    else
        error("Error getting list of files. Unsupported operating system.");
    end

    local uOutput = io.popen(sCommand);

    if (uOutput) then

        for sLine in uOutput:lines() do
            local pFile = (_bOSIsWindows and not bRecursive) and sPath.._..sLine:gsub(__, _) or sLine;
            local bInclude = not bCheckTypes;

            if not (bInclude) then
                local sFiletype = splitpath(pFile).extension:lower();

                for nArg, sArg in ipairs(tTypes) do
                    local sArgLower = sArg:lower();

                    if (sArgLower == sFiletype) then
                        bInclude = true;
                        break;
                    end

                end

            end

            if (bInclude) then

                if (bHasCallback) then
                    fCallback(pFile, true); --adding true for io.list callback
                end

                table.insert(tRet, pFile);
            end

        end

    end

    return tRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.list
    @desc Lists all files and directories in a given path (optionally recursively).
    @param string sPath The path which to search for files and directories.
    @param boolean|nil bRecursive Whether to recurse through subdirectories.
    @param function|nil fCallback The function to call when a file or directory is found.
    <br>This function must accept a string as its first argument which will be the full path to the item found.
    <br>This function must accept a boolean as its second argument which indicates whether the item found is a file (true if a file) or a directory (false if a directory).
    @ret table tItems A table whose keys are strings (directories, files) whose values are numerically-indexed table whose values are full paths of the found files and directories.
    @ex
    local function printitem(pFile, bIsFile)
        print("Is File: "..tostring(bIsFile), pFile);
    end

    local tItems = io.list("C:\\Windows\\System32", true, printitem, "exe");
    --\[\[ Output->
    Is File: false	C:\Windows\System32\0409
    Is File: false	C:\Windows\System32\AdvancedInstallers
    Is File: false	C:\Windows\System32\am-et
    Is File: false	C:\Windows\System32\AppLocker
    ...
    Is File: true	C:\Windows\System32\agentactivationruntimestarter.exe
    Is File: true	C:\Windows\System32\AgentService.exe
    Is File: true	C:\Windows\System32\AggregatorHost.exe
    Is File: true	C:\Windows\System32\aitstatic.exe
    ...
    \]\]
!]]
function io.list(sPath, bRecursive, fCallback, ...)
    return {
        directories = listdirs(sPath, bRecursive, fCallback),
        files       = listfiles(sPath, bRecursive, fCallback, ...),
    };
end





























-- Determine the operating system type
--TODO remove this if the other works fine
local function iolistold(sPath, bRecursive, nType, tFileTypes)
    local sCommand;
    local tFilters;
    local bFilters          = false;
    local nItemType         = 3;
    local tFullPaths        = {};
    local tRelativePaths    = {};
    local sEnd              = " 2>/dev/null";

    if type(nType) == "number" then
        nItemType = nType;
    end

    if type(tFileTypes) == "table" then
        local nTypeCount = 0;
        tFilters = {};

        for _, sType in pairs(tFileTypes) do
            if type(sType) == "string" and sType:gsub("%s+", "") ~= "" and sType:find("^[^.]+$") and not sType:find("[^%w._-]") then
                nTypeCount = nTypeCount + 1;
                tFilters[nTypeCount] = sType:lower();
                bFilters = true;
            end
        end
    end

    if _bOSIsWindows then
        local sRecurse = bRecursive and ' /s' or '';

        if nItemType == 0 then
            sCommand = 'dir "'..sPath..'\\*.*" /b /a-d'..sRecurse..sEnd
        elseif nItemType == 1 then
            sCommand = 'dir "'..sPath..'\\*.*" /b /ad'..sRecurse..sEnd
        else
            sCommand = 'dir "'..sPath..'\\*.*" /b'..sRecurse..sEnd
        end

    elseif _bOSIsUnix then
        local sMaxDepth = bRecursive and '' or ' -maxdepth 1';
        local sEnd      = " 2>/dev/null";
        local sType     = (nItemType == 0) and  " -type f"  or
                         ((nItemType == 1) and ' -type d'   or '');

        sCommand = 'find "'..sPath..'"'..sType..sMaxDepth..sEnd;
    else
        error("Unsupported operating system")
    end

    local sOutput = io.popen(sCommand):read("*a")

    local pBase = sPath:gsub("[/\\]$", "")
    pBase = _bOSIsWindows and pBase:gsub("/", "\\") or pBase:gsub("\\", "/")

    local nLineCount = 0
    for sLine in sOutput:gmatch("[^\r\n]+") do
        nLineCount = nLineCount + 1

        local pFull = _bOSIsWindows and sLine:gsub("/", "\\") or sLine:gsub("\\", "/")

        if not sLine:match("^"..pBase) then
            pFull = pBase .. (_bOSIsWindows and "\\" or "/") .. pFull
        end

        local bIncludeItem  = false
        local tPathParts    = splitpath(pFull)
        local sExtension    = tPathParts.extension:lower()

        if sExtension == "" and nItemType ~= 0 then
            bIncludeItem = true
        else
            if nType ~= 1 then
                bIncludeItem = not bFilters
                if bFilters then
                    for _, sType in ipairs(tFilters) do
                        if sExtension == sType then
                            bIncludeItem = true
                            break
                        end
                    end
                end
            end
        end

        if nItemType == 0 and tFilters and #tFilters > 0 then
            for _, sType in ipairs(tFilters) do
                if sExtension == sType then
                    bIncludeItem = true
                    break
                end
            end
        end

        if bIncludeItem then
            tFullPaths[nLineCount] = pFull

            local pRelative = pFull:gsub("^"..pBase.."[\\/]*", "")
            tRelativePaths[nLineCount] = pRelative
        end
    end

    return tFullPaths, tRelativePaths
end





function io.normalizepath(path)
    -- Split the path into components
    local parts = {}
    local driveLetter = nil

    for part in path:gmatch("[^/\\]+") do
        if _bOSIsWindows and not driveLetter then
            -- Extract the drive letter if present
            driveLetter = part:match("^[A-Za-z]:$")
            if driveLetter then
                parts[#parts + 1] = driveLetter
            else
                -- If no drive letter, add the part
                if part == ".." then
                    if #parts > 0 and parts[#parts] ~= driveLetter then
                        table.remove(parts)
                    end
                elseif part ~= "." then
                    parts[#parts + 1] = part
                end
            end
        else
            if part == ".." then
                if #parts > 0 and parts[#parts] ~= driveLetter then
                    table.remove(parts)
                end
            elseif part ~= "." then
                parts[#parts + 1] = part
            end
        end
    end

    -- Join the parts back into a normalized path
    local separator = _bOSIsWindows and "\\" or "/"
    local normalizedPath = table.concat(parts, separator)

    -- Handle Windows drive letters
    if _bOSIsWindows and driveLetter then
        normalizedPath = driveLetter .. "\\" .. table.concat(parts, separator, 2)
    elseif _bOSIsWindows then
        normalizedPath = "\\" .. normalizedPath
    else
        if path:sub(1, 1) == "/" then
            normalizedPath = "/" .. normalizedPath
        end
    end

    return normalizedPath
end



function io.fileFind(path)
    local command = (_ == "\\") and ('dir "'..path..'\\*.*" /b /a-d 2>nul'):gsub("\\\\", "\\") or ('find "'..path..'" -maxdepth 1 ! -type d 2>/dev/null'):gsub("//", "/")
    return execute(command)
end

-- File Searching
function io.findAll(str, path)
    if path then
        return execute('findstr "'..str..'" "'..path..'"')
    else
        return execute('findstr "'..str..'"')
    end
end

function io.findstr(str, path)
    if path then
        return execute('findstr "'..str..'" "'..path..'"')
    else
        return execute('findstr "'..str..'"')
    end
end

function io.grep(pattern, path)
    if path then
        return execute('grep "'..pattern..'" "'..path..'"')
    else
        return execute('grep "'..pattern..'"')
    end
end

-- Define the functions for file information

-- File Information
function io.type(filename)
    return io.open(filename):read("*a");
end

-- Define the function for file permission (Windows-specific)

-- File Permission (Windows-specific)
function io.chmod(permission, path)
    return execute('icacls "'..path..'" /grant:r ' .. permission)
end


function io.getuserdir()
    local home = os.getenv("HOME")
    if not home then
        home = os.getenv("USERPROFILE")
    end
    return home
end

-- File Compression
function io.zip(files, destination)
    return execute('zip "'..destination..'" "'..table.concat(files, '" "')..'"')
end

function io.unzip(archive, destination)
    return execute('unzip "'..archive..'" -d "'..destination..'"')
end

-- File Manipulation
function io.copy(source, destination)
    return execute('copy "'..source..'" "'..destination..'"')
end

function io.delete(path)
    return execute('del "'..path..'"')
end

function io.move(source, destination)
    return execute('move "'..source..'" "'..destination..'"')
end

function io.mkdir(path)
    return execute('mkdir "'..path..'"')
end

function io.rmdir(path)
    return execute('rmdir "'..path..'"')
end

-- Alias creation
io.splitpath    = splitpath;
io.listfiles    = listfiles;
io.listdirs     = listdirs;
--io.dir      = io.list
--io.ls       = io.list
--io.dir          = io.listfiles;
--io.ls           = traverse_directory;

return io;
