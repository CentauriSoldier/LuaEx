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
local sPath = getsourcepath();

--update the package.path (use the main directory to prevent namespace issues)
package.path = package.path..";"..sPath.."\\?.lua;";


--load LuaEx
require("LuaEx.init");


local function runExample(sExample)
    local pExample = sPath.."\\examples\\"..sExample..".lua";
    return dofile(pExample)
end

--runExample("struct");


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


--for index, item in dox.MIME() do
    --print(item.name)
--end

local k = [=[
w34-=0-=ytph[]f;h'
fg
w-4or-03w94r-0iowkfes
poewiF)(*WE)(RUIWIJEFSIOJDf)
3-4=t0=-eworfpsldf
--[[f!
@module class
@func instance.build
@param table tKit The kit f\@rom which the instance is to be built.
@param table tParentActu\@al The (actual) parent instance table (if any).
@scope local
@desc Builds an in\@stance of an object given the name of the kit.
@ret object|table oInstance|tInsta\@nce The instance object (decoy) and the instance table (actual).
!f]]
-03489t-ieoksd;folksd;kf
34-50983-904tri-i45po34krfers
4598yt0r9tg-094t0-=34itjelkrmgdfg
34-0t9ipa;sda[siodwoih4fvhjsdkvjhwe9ir-348rwoeihfsldjf-0w49irowef
39048r39084750237eq9whdlashfd9isdyf98uw43roij23r0f7sudoifiol34jtr
w4890r79823u4rhjfwefus07ur23ohr9asd8yfsoij
]=]
local oLuaExDox = DoxLua();
for k in oLuaExDox.blockTagGroups() do

    for f in k.blockTags() do
        --print(k.getname().." | "..f.getdisplay())
    end

end

--TODO create tests for each thing and use them as examples
local pFile = sPath.."\\LuaEx\\lib\\class.lua";

local function readFile(filePath)
    local file = io.open(filePath, "r") -- Open the file in read mode

    if not file then
        return nil, "Could not open file: " .. filePath -- Return nil and an error message if the file cannot be opened
    end

    local content = file:read("*all") -- Read the entire file content
    file:close() -- Close the file

    return content
end

--print(readFile(pFile))
local tModules, tBlocks = oLuaExDox.importString(readFile(pFile));
--local tModules, tBlocks = oLuaExDox.importstring(k);

for k, v in pairs(tBlocks) do
    --print(k.." = "..serialize(v));
end

--print(Ini)



--[[
local oOS = OrderedSet();
oOS.add("0");
oOS.add(1);
oOS.add(2);
oOS.add(3);
oOS.add(4);
oOS.add("5");
oOS.add("Six");
oOS.add(7);
oOS.add("8");
oOS.add("Nine");
]]

--print(math.huge / math.huge == math.huge * math.huge)
--print(8 / 0 == math.huge)
--print(math.nan == math.inf)
--print(type(math.nan), type(math.inf))
-- Example usage
local str = [[

# config.ini file
# Application settings

# http settings



[http]
port=8033
username=httpuser

# https settings
[https]
port=8077
username=httpsuser

# ftp settings
# ftp settings
;asdasdasd
[FTP]
port=8043
username=ftpuser

[database]
driverclass   = com.mysql.jdbc.Driver
dbName        = mydatabase
port          = 3306
username      = root
password      = secure # not recommended to store secure information

# feature settings
[settings]
enable_ssl = true
enable_2mf =  true]]


local oSettings = Ini(str);
print(oSettings)

--local tTop, tSections, tSectionOrder = import(str);
--print(export(tTop, tSections, tSectionOrder));
writeToFile("\\Sync\\Projects\\GitHub\\LuaEx\\test.ini", tostring(oSettings));
--print(sRawData, "\n\n\n", sSections, "\n\n\n", sMap);
--local parsedIni = generateIniStructure(tRawData, tSections, tMap)
--local serializedIni = serialize(parsedIni)
--print(serializedIni)
