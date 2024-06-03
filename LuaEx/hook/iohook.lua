local string = string;
local table = table;
local execute = os.execute;

-- Define the os type
local _ = package.config:sub(1,1)
local sOSType = _ == "\\" and "windows" or (_ == "/" and "unix" or "unknown");

-- Determine the operating system type
local bIsWindows    = sOSType == "windows";
local bIsUnix       = sOSType == "unix";
local bIsUnknown    = sOSType == "unknown";


local function splitpath(sPath)
    local pathTable = {
        filename = "",
        extension = "",
        drive = "",
        directory = ""
    }

    -- Define the path separator based on the OS type
    local pathSeparator = sOSType == "windows" and "\\" or "/"

    -- Extract drive letter if present (Windows only)
    local drive, path
    if sOSType == "windows" then
        drive, path = sPath:match("^([A-Za-z]:)[/\\]?(.*)")
        if drive then
            pathTable.drive = drive
        else
            path = sPath
        end
    else
        path = sPath
    end

    -- Remove trailing slash if present
    if path:sub(-1) == pathSeparator then
        path = path:sub(1, -2)
    end

    -- Extract directory and filename
    local directory, filename = path:match("^(.*)[" .. pathSeparator .. "]([^" .. pathSeparator .. "]+)$")
    if directory then
        pathTable.directory = directory
        pathTable.filename = filename
    else
        pathTable.filename = path
    end

    -- Extract extension without the dot
    local extension = pathTable.filename:match("%.([^.]+)$")
    if extension then
        pathTable.extension = extension
        pathTable.filename = pathTable.filename:sub(1, -(#extension + 2)) -- +2 to remove the dot as well
    end

    return pathTable
end

io.splitpath = splitpath;


-- File Compression
function io.zip(files, destination)
    return execute('zip "'..destination..'" "'..table.concat(files, '" "')..'"')
end

function io.unzip(archive, destination)
    return execute('unzip "'..archive..'" -d "'..destination..'"')
end

-- Determine the operating system type



--TODO BUG FIX nil items are getting added to the return
--TODO trim trailing directory separator before processing path
-- Function to list files and directories
function io.list(sPath, bRecursive, nType, tFileTypes)
    local sCommand;
    local tFilters;
    local bFilters       = false;
    local nItemType      = 3;
    local tFullPaths     = {};
    local tRelativePaths = {};

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

    if bIsWindows then

        if nItemType == 0 then
            sCommand = 'dir "'..sPath..'\\*.*" /b /a-d'..(bRecursive and ' /s' or '')..' 2>nul'
        elseif nItemType == 1 then
            sCommand = 'dir "'..sPath..'\\*.*" /b /ad'..(bRecursive and ' /s' or '')..' 2>nul'
        else
            sCommand = 'dir "'..sPath..'\\*.*" /b'..(bRecursive and ' /s' or '')..' 2>nul'
        end

    elseif bIsUnix then

        if nItemType == 0 then
            sCommand = 'find "'..sPath..'" -type f'..(bRecursive and '' or ' -maxdepth 1')..' 2>/dev/null'
        elseif nItemType == 1 then
            sCommand = 'find "'..sPath..'" -type d'..(bRecursive and '' or ' -maxdepth 1')..' 2>/dev/null'
        else
            sCommand = 'find "'..sPath..'"'..(bRecursive and '' or ' -maxdepth 1')..' 2>/dev/null'
        end

    else
        error("Unsupported operating system")
    end

    local sOutput = io.popen(sCommand):read("*a")

    local pBase;

    if bIsWindows then
        pBase = sPath:gsub("[/\\]$", ""):gsub("/", "\\") -- Ensure consistent use of backslashes for Windows
    else
        pBase = sPath:gsub("[/\\]$", ""):gsub("\\", "/") -- Ensure consistent use of forward slashes for Unix
    end

    local nLineCount = 0
    for sLine in sOutput:gmatch("[^\r\n]+") do
        nLineCount = nLineCount + 1

        local pFull = sLine:gsub("\\", "/") -- Replace backslashes with forward slashes for consistency

        if bIsWindows then
            pFull = sLine:gsub("/", "\\") -- Replace forward slashes with backslashes for Windows
        end

        if not sLine:match("^"..pBase) then--QUESTION this should also check for OS type? If so, it should pick the correct separator
            pFull = pBase .. "\\" .. pFull; -- Using "\\" for Windows paths
        end

        local bIncludeItem  = false;
        local tPathParts    = splitpath(pFull);
        local sExtension    = tPathParts.extension:lower();

        if (sExtension == "" and nItemType ~= 0) then --directory
            bIncludeItem = true;
        else --file

            if (nType ~= 1) then
                bIncludeItem = -bFilters;

                if (bFilters) then

                    for _, sType in ipairs(tFilters) do

                        if (sExtension == sType) then
                            bIncludeItem = true;
                            break;
                        end

                    end

                end

            end

        end

        if nItemType == 0 and tFilters and #tFilters > 0 then

            for _, sType in ipairs(tFilters) do

                if (sExtension == sType) then
                    bIncludeItem = true
                    break
                end

            end

        end

        if (bIncludeItem) then
            tFullPaths[nLineCount] = pFull;

            local pRelative = pFull:gsub("^"..pBase.."[\\/]*", "");
            tRelativePaths[nLineCount] = pRelative;
        end
    end

    return tFullPaths, tRelativePaths;
end




function io.normalizepath(path)
    local isWindows = package.config:sub(1, 1) == '\\'

    -- Split the path into components
    local parts = {}
    local driveLetter = nil

    for part in path:gmatch("[^/\\]+") do
        if isWindows and not driveLetter then
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
    local separator = isWindows and "\\" or "/"
    local normalizedPath = table.concat(parts, separator)

    -- Handle Windows drive letters
    if isWindows and driveLetter then
        normalizedPath = driveLetter .. "\\" .. table.concat(parts, separator, 2)
    elseif isWindows then
        normalizedPath = "\\" .. normalizedPath
    else
        if path:sub(1, 1) == "/" then
            normalizedPath = "/" .. normalizedPath
        end
    end

    return normalizedPath
end

--[[OLD WORKING

function io.list(sPath, bRecursive, nType, tFileTypes)
    local sCommand;
    local nItemType  = 3;
    local tFileTypes;

    if (rawtype(nTypeRestriction) == "number") then
        nItemType = nType;
    end

    if (rawtype(tFileTypes) == "table") then
        local nTypeCount = 0;
        tFileTypes = {};

        for _, sType in pairs(tFileTypes) do

            if (type(sType) == "string"         and
                sType:gsub("%s+", "") ~= ""     and    -- Check if the string is not blank
                sType:find("^[^.]+$") ~= nil    and   -- Check if the string doesn't contain only periods
                not sType:find("[^%w._-]") )  then
                nTypeCount = nTypeCount + 1;
                tFileTypes[nTypeCount] = sType;
            end

        end

    end

    if bIsWindows then

        if nItemType == 0 then
            sCommand = 'dir "'..sPath..'\\*.*" /b /a-d'..(bRecursive and ' /s' or '')..' 2>nul';
        elseif nItemType == 1 then
            sCommand = 'dir "'..sPath..'\\*.*" /b /ad'..(bRecursive and ' /s' or '')..' 2>nul';
        else
            sCommand = 'dir "'..sPath..'\\*.*" /b'..(bRecursive and ' /s' or '')..' 2>nul';
        end

    elseif bIsUnix then

        if nItemType == 0 then
            sCommand = 'find "'..sPath..'" -type f'..(bRecursive and '' or ' -maxdepth 1')..' 2>/dev/null';
        elseif nItemType == 1 then
            sCommand = 'find "'..sPath..'" -type d'..(bRecursive and '' or ' -maxdepth 1')..' 2>/dev/null';
        else
            sCommand = 'find "'..sPath..'"'..(bRecursive and '' or ' -maxdepth 1')..' 2>/dev/null';
        end

    else
        error("Unsupported operating system");
    end

    local sOutput = io.popen(sCommand):read("*a")
    local tFullPaths = {}
    local tRelativePaths = {}
    local pBase

    if bIsWindows then
        pBase = sPath:gsub("[/\\]$", ""):gsub("/", "\\"); -- Ensure consistent use of backslashes for Windows
    else
        pBase = sPath:gsub("[/\\]$", ""):gsub("\\", "/"); -- Ensure consistent use of forward slashes for Unix
    end

    local nLineCount = 0;
    for sLine in sOutput:gmatch("[^\r\n]+") do
        nLineCount = nLineCount + 1;

        local pFull = sLine:gsub("\\", "/"); -- Replace backslashes with forward slashes for consistency

        if bIsWindows then
            pFull = sLine:gsub("/", "\\"); -- Replace forward slashes with backslashes for Windows
        end

        if not sLine:match("^"..pBase) then
            pFull = pBase .. "\\" .. pFull;  -- Using "\\" for Windows paths
        end

        tFullPaths[nLineCount] = pFull;

        local pRelative = pFull:gsub("^"..pBase.."[\\/]*", "");
        tRelativePaths[nLineCount] = pRelative;
    end

    return tFullPaths, tRelativePaths
end


]]













-- Alias creation
io.dir = io.list
io.ls = io.list



function io.fileFind(path)
    local command = (_ == "\\") and ('dir "'..path..'\\*.*" /b /a-d 2>nul'):gsub("\\\\", "\\") or ('find "'..path..'" -maxdepth 1 ! -type d 2>/dev/null'):gsub("//", "/")
    return execute(command)
end

function io.fileList(path)
    local command = (_ == "\\") and ('dir "'..path..'\\*.*" /b /a-d 2>nul'):gsub("\\\\", "\\") or ('find "'..path..'" -maxdepth 1 ! -type d 2>/dev/null'):gsub("//", "/")
    return execute(command)
end



-- Define the functions for file manipulation

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

-- Define the functions for file searching

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
    return io.open(filename):read("*a")
end

-- Define the function for file permission (Windows-specific)

-- File Permission (Windows-specific)
function io.chmod(permission, path)
    return execute('icacls "'..path..'" /grant:r ' .. permission)
end

-- Alias creation
io.dirFind = io.dirList
io.fileFind = io.fileList

return io;
