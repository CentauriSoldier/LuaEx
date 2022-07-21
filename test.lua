local _ = package.config:sub(1,1);
local bIsLinux = _ == "/";

local sFilenameMatch = "^.+".._.."(.+)$";

function GetFileName(url)
  return url:match(sFilenameMatch);
end

function GetFileExtension(url)
  return url:match("^.+(%..+)$");
end

function getscriptpath()
    --get the full path
    local sRet = debug.getinfo(1, "S").source;

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

    sRet = sRet:gsub("@", ""):gsub(sFilename, "");
    return sRet;
end

function getscriptfilename()

end

scriptpath = "";

--determine the call location
local sPath = debug.getinfo(1, "S").source;
--remove the calling filename
--sPath = sPath:gsub("@", ""):gsub("[Tt][Ee][Ss][Tt].[Ll][Uu][Aa]", "");
--remove the "/" at the end
--sPath = sPath:sub(1, sPath:len() - 1);
--update the package.path (use the main directory to prevent namespace issues)
--package.path = package.path..";"..sPath.."\\..\\?.lua;"..sPath.."\\LuaEx\\?.lua";

--require("init");
print(getscriptpath(sPath));
--local pIni = "C:\\Users\\CS\\Sync\\Projects\\GitHub\\LuaEx\\initest.ini";

---local test = ini(pIni, true, true);

--local  k = serialize.tablusere(tIni);

--test:setvalue("Settings", "margin", 98)

--print(serialize.table(test:getsectionnames()));

--print(true);
--type.poog = true;

--local t = {}
--setmetatable(t, {__type="poog"})

--print(type.ispoog(t));
--local null = null;

--print(null - {})
