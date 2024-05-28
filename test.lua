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

local function writeToFile(content)
    -- Get the path to the "Documents" directory
    local documentsPath = os.getenv("USERPROFILE") .. "\\Sync\\Projects\\GitHub\\LuaEx\\"

    -- Full path to the target file
    --local filePath = documentsPath .. "modules.lua"

    --TODO only for struct testing
    local filePath = documentsPath .. "struct.lua"

    -- Open the file in write mode
    local file = io.open(filePath, "w")

    -- Check if the file was opened successfully
    if file then
        -- Write the content to the file
        file:write(content)
        -- Close the file
        file:close()
        print("Content written to " .. filePath)
    else
        -- Print an error message if the file could not be opened
        print("Error: Could not open file " .. filePath)
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
local oLuaExDox = doxLua();
for k in oLuaExDox.blocktaggroups() do

    for f in k.blocktags() do
        --print(k.getname().." | "..f.getdisplay())
    end

end

--TODO create tests for each thing and use them as examples
local pFile = sPath.."\\LuaEx\\class\\class.lua";

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
local tModules, tBlocks = oLuaExDox.importstring(readFile(pFile));

--for k, v in pairs(tBlocks) do
    ---print(k.." = "..serialize.table(v))
--end
local tpot = potentiometer(1, 20, 1, 1, POT_CONTINUITY_REVOLVE);
tpot.adjust(20)
--print(tpot.getPos())


local P1 = point(-6, -6);
local P2 = point(12, 12);
local P3 = point(12, -12);
local oLine1 = line(P1, P2);
local oCircle = circle();

--print(math.huge / math.huge == math.huge * math.huge)
--print(8 / 0 == math.huge)
--print(math.nan == math.inf)
--print(type(math.nan), type(math.inf))
--print(oCircle.getArea())
--print(math.allrealnumbers == math.allrealnumbers)
--print(math.isabstract(math.huge / 0))
--local oPolygon = polygon(array({[1] = P1, [2] = P2, [3] = P3}));
local tDataTest = {
    a = "Bloog!",
    --b = function() print("A function has arrived!") end,
    x = 45,
    y = 31,
    z = 42,
};

--local sDataTest = class.serialize("MyClassOfPower", tDataTest);
--print(sDataTest);
--local k = class.deserialize(sDataTest);
--print(type(k))

local a = {
    [1] = point(1, 5),
};

--a[a] = a -- self-reference with a table as key and value
--local str = class.serialize(point(1, 5));
--print(str) -- full serialization
--local oRevived = class.deserialize(str);
--print(oRevived)



--print(serpent.line(a)) -- single line, no self-ref section
--print(serpent.block(a)) -- multi-line indented, no self-ref section

--local fun, err = loadstring(str)
--if err then error(err) end
--local t = fun();
--print(t["y"])
--if err then error(err) endzzzzzzzzzzz
--local copy = fun()

-- or using serpent.load:
--local ok, copy = serpent.load(serpent.dump(a))
--print(ok and copy[3] == a[3])

local k = 99;
local tTest;

function buildit()
tTest = {
    [1] = 45,
    [2] = {
        ["cat"] = "animal",
        boot    = "footwear",
    },
    [3] = "Hello",
    power = "power",
    string = "stringtest",
    [96] = false,
    [4] = {
        anothertable = {
            morepower = "yay!",
            y = 77,
            z = "\0"
        },
        x = 44,
    },
    wert = null,
    [k] = 3234,
};

--tTest[tTest] = tTest; --TODO test self-referential tables
end
--[[
-- Example usage
local code = "return 42"
local result, err = safeLoad(code)
if result then
    print("Result:", result)
else
    print("Error:", err)
end
]]
buildit();
--print(tTest.string:gsub("string", "boolean"))
--print(type('\0'), serialize(tTest))

local aPets = array({"bug", "frog", "cat", "mouse", "chicken", "duck"})
--print(aPets)

local p = function() print("234234") end

local tBullet = {
    speed = 30,
    direction = null,
    damage = 41,
    __readsOnly = 44,
};

local xBullet = structfactory("bullet", tBullet, false);
--print(xBullet.__name)
local oBullet1 = xBullet({speed = 10, direction = "north"})
--print(oBullet1.direction);
--local oBullet2 = load(();
--local oBullet2 = rBullet({speed = 12, direction = "west"})
print(oBullet1)
--for x = 1, 1000000 do
--    rfBullet({speed = 10, direction = "north"})
--end

--local sBullet = serialize(oBullet1);
--local oNewBullet = deserialize(sBullet);




function readFile(path)
    local file = io.open(path, "r") -- Open the file in read mode
    if not file then
        return nil, "Failed to open file" -- Return nil and an error message if file opening fails
    end

    local content = file:read("*a") -- Read the entire content of the file
    file:close() -- Close the file

    return content -- Return the content of the file
end

local documentsPath = os.getenv("USERPROFILE") .. "\\Sync\\Projects\\GitHub\\LuaEx\\"
local filePath = documentsPath .. "struct.lua"

function savetofile()
    local tBullet = {
        speed = 30,
        direction = null,
        damage = 41,
    };

    local bulletfactory = structfactory("bulletfactory", tBullet, false);

    writeToFile(serialize(bulletfactory));
end

function loadfromfile()
    --local k = serializer.unpackData("ewogICAgWyJuYW1lIl0gPSAiYnVsbGV0ZmFjdG9yeSIsCiAgICBbImNvbnN0cmFpbnRzIl0gPSB7CiAgICBbInNwZWVkIl0gPSAzMCwKICAgIFsiZGlyZWN0aW9uIl0gPSBudWxsLAogICAgWyJkYW1hZ2UiXSA9IDQxLAp9LAogICAgWyJyZWFkT25seSJdID0gZmFsc2UsCn0=")
    --print(serialize(k) == readFile(filePath), '\n', serialize(k), '\n\n', readFile(filePath))
    local bulletfactory = deserialize(readFile(filePath));
    --print(readFile(filePath))
    --print((bulletfactory))
end

--savetofile()
--loadfromfile()

--print(subtype(ert()))


--rBullet2.direction = "north"
--print(1, rBullet.speed, rBullet.direction)
--print(2, rBullet2.speed, rBullet2.direction)
--rBullet2.direction = "11";
--print(1, rBullet.speed, rBullet.direction)
--print(2, rBullet2.speed, rBullet2.direction, rBullet2.damage)
--rBullet2[{}] = 5
--rBullet.speed = 14
--print(rBullet2.direction)

local tPets = {
    [1] = aPets,
    [2] = function() print("hello "..base64.enc("hello ")) end,
    [3] = class,
    [4] = array,
    [5] = struct,
    [6] = point,
    [7] = rBullet,
    --[8] = oBullet,
};

local sPets = serialize(tPets);
--print(sPets);

--local tNewPets = deserialize(sPets);
--print(tNewPets[1])

local upvaluert = 10

local function myFunction(x)
    --local as = tPets[1];
    local ty = array({"bug", "frog", "cat", "mouse", "chicken", "ducky"})
    --local k = aPets;
    --k[4] = "monkey"
    --print("upvaluert + x")
    print(ty)
end
--[[
local serialized = serialize(tPets)
--local serialized = serialize(myFunction)
print(tostring(serialized))  -- Output: binary representation of the function
local deserialized = deserialize(serialized)
print(type(deserialized[5]))
--local tLo = deserialized[4]({"moo", "mew", "ruff"});
--print(type(tLo))  -- Output: 15
--print(deserialized)  -- Output: 15
print(deserialized[7])
]]
