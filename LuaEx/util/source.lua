local _ = package.config:sub(1,1);
local sFilenameMatch = "^.+".._.."(.+)$";

--[[
    Copy/paste and use this function in any file
    where the source path is needed before LuaEx
    has been loaded.
]]
function getsourcepathOLD()
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

function getsourcepathOld2()
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

function getsourcepathOld3()
    -- Determine the call location
    local sPath = debug.getinfo(1, "S").source
    -- Remove the "@" at the beginning
    sPath = sPath:sub(2)

    -- Get the current working directory
    local current_dir = io.popen("cd"):read("*l")

    -- Concatenate the current directory with the relative path
    sPath = current_dir .. "\\" .. sPath

    -- Remove the filename from the path
    sPath = sPath:match("(.+[\\/])")

    return sPath
end

function getsourcepath()
    -- Determine the call location
    local sPath = debug.getinfo(1, "S").source
    -- Remove the "@" at the beginning
    sPath = sPath:sub(2)

    -- Get the current working directory
    local current_dir = io.popen("cd"):read("*l")

    -- Concatenate the current directory with the relative path
    sPath = current_dir .. "\\" .. sPath

    -- Remove the filename from the path
    sPath = sPath:match("(.+[\\/])")

    -- Remove occurrences of ".\" in the path
    sPath = sPath:gsub("\\%.[\\/]", "\\")

    return sPath
end


return {
    addtopackagepath = function(...)
        local tArgs = arg or {...};
        --TODO incorporate any subdirectories into path

        --get the full path
        local sPath = debug.getinfo(2, "S").source;

        --get the filename
        local sFilenameRAW = sPath:match(sFilenameMatch);

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
        --trim off the @ symbol
        sPath = sPath:gsub("@", ""):gsub(sFilename, "");
        --TODO check for semicolon on end first
        --add the new path to the package path
        package.path = package.path..";"..sPath.._.."\\?.lua";

        return package.path;
    end,
    getextension = function()
        --get the full path
        local pSource = debug.getinfo(2, "S").source;
        --get the filename
        local sFilename = pSource:match(sFilenameMatch);
        --return the extension
        return sFilename:match("^.+(%..+)$");
    end,
    getfilename = function()
        --get the full path
        local pSource = debug.getinfo(2, "S").source;
        --get the filename
        local sFullFilename = pSource:match(sFilenameMatch);
        --get the extension
        local sExtension = sFullFilename:match("^.+(%..+)$");
        --return the filenmame
        local sRet, _ = sFullFilename:gsub(sExtension, "");
        return sRet;
    end,
    getfullfilename = function()
        --get the full path
        local pSource = debug.getinfo(2, "S").source;
        --return the full filename
        return pSource:match(sFilenameMatch);
    end,
    getpathOLD = function()
        --get the full path
        local sRet = debug.getinfo(2, "S").source;

        --get the filename
        local sFilenameRAW = sRet:match(sFilenameMatch);

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
        --trim off the @ symbol
        sRet = sRet:gsub("@", ""):gsub(sFilename, "");

        --trim the trailing slash
        sRet = sRet:sub(1, sRet:len() - 1);

        return sRet;
  end,
  getpath = getsourcepath,
};
