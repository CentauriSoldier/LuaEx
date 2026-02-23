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
local function listdirs(sPath, bRecursive, fCallback)
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
local function listfiles(sPath, bRecursive, fCallback, ...)
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


local function splitpath(sPath)
    local tRet = {
        directory = "",
        drive     = "",
        extension = "",
        filename  = "",
    }

    if (type(sPath) ~= "string") or (sPath == "") then
        return tRet
    end

    local path = sPath
    local sDrive = ""

    -- Extract drive letter if present (Windows)
    if (_bOSIsWindows) then
        sDrive, path = path:match("^([A-Za-z]:)[/\\]?(.*)$")
        if (sDrive) then
            tRet.drive = sDrive
            path = path or ""
        else
            path = sPath
        end
    end

    -- Remove trailing separators (handle both kinds, not just native)
    path = path:gsub("[/\\]+$", "")

    -- If path is now empty (e.g., "C:\" or "/" or "////"), return what we have
    if (path == "") then
        return tRet
    end

    -- Extract directory + filename using last separator (either / or \)
    local directory, filename = path:match("^(.*)[/\\]([^/\\]+)$")
    if (directory) then
        tRet.directory = directory
        tRet.filename  = filename
    else
        tRet.filename = path
    end

    -- Extract extension (no dot). Only if there's a stem before it (avoids ".gitignore" => extension "gitignore")
    local stem, ext = tRet.filename:match("^(.*)%.([^.]+)$")
    if (stem and stem ~= "") then
        tRet.filename  = stem
        tRet.extension = ext or ""
    end

    return tRet
end

local function normalizepath(path)
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
