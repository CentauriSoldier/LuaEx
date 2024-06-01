local string = string;

local execute = os.execute;

-- Define the os type
local _ = package.config:sub(1,1)
local sOSType = _ == "\\" and "windows" or (_ == "/" and "unix" or "unknown");

-- Determine the operating system type
local bIsWindows = sOSType == "windows";
local bIsLinux   = sOSType == "unix";
local bIsUnknown = sOSType == "unknown";








-- File Compression
function io.zip(files, destination)
    return execute('zip "'..destination..'" "'..table.concat(files, '" "')..'"')
end

function io.unzip(archive, destination)
    return execute('unzip "'..archive..'" -d "'..destination..'"')
end






















-- Define the functions for file listing
-- Define the function for directory listing
function io.dirList(path, recursive, relativePaths)
    local command
    if bIsWindows then
        command = 'dir "'..path..'\\*.*" /b /ad'..(recursive and '/s' or '')..' 2>nul'
    elseif bIsLinux then
        command = "ls -a -d '"..path.."'/"..(recursive and '**' or '*').." 2>/dev/null"
    else
        error("Unsupported operating system")
    end
    local output = execute(command:gsub("//", "/"))
    if relativePaths and not bIsWindows then
        local basePath = path:gsub("/$", "") -- Remove trailing slash if present
        local relativePaths = {}
        for line in output:gmatch("[^\n]+") do
            table.insert(relativePaths, line:gsub("^"..basePath.."/?", ""))
        end
        return relativePaths
    else
        return output
    end
end

-- File Listing

-- Directory Listing
function io.list(path)
    if sOSType == "windows" then
        if path then
            return execute('dir "'..path..'" /b')
        else
            return execute('dir /b')
        end
    elseif sOSType == "unix" then
        if path then
            return execute('ls "'..path..'"')
        else
            return execute('ls')
        end
    else
        print("Unsupported operating system")
    end
end

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
