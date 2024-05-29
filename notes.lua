--[[
NEW LUAEX FUNCTIONS
]]


--[[
function writeToFile(path, text)
    local file = io.open(path, "w")  -- Open file for writing
    if file then
        file:write(text)  -- Write text to file
        file:close()  -- Close the file
        print("Text written to file successfully.")
    else
        print("Error: Unable to open file for writing.")
    end
end

-- Example usage:
local k = 4;
local function test()
    print("hello "..k)
end


--https://leafo.net/guides/function-cloning-in-lua.html
local function clone_function(fn)
  local dumped = string.dump(fn)
  local cloned = loadstring(dumped)
  local i = 1
  while true do
    local name = debug.getupvalue(fn, i)
    if not name then
      break
    end
    debug.upvaluejoin(cloned, i, fn, i)
    i = i + 1
  end
  return cloned
end

--local fh = clone_function(test)
]]


getmetatable("").__bor = string.delimitedtotable;

--TODO add __unm using a defualt demilimter (and create an accessor/mutator function for the delimter)

--[[
determines if a string, delimted by .'s is useable as table indices
]]
function string.istableindex(sVal)
    local bRet 			= false;
    local dstt			= string.delimitedtotable;
    local iscompliant 	= string.isvariablecompliant;

    if (rawtype(sVal) == "string") then
        local tIndices 	= dstt(sVal, ".");

        if (rawtype(tIndices) == "table") then
            bRet = true;

            for _, sIndex in pairs(tIndices) do

                if not (iscompliant(sIndex)) then

                    bRet = false;
                    break;
                end

            end

        end

    end

    return bRet;
end

--[[
creates a table using a period-delimited string where each item is a sub-table index of the previous
e.g., mytable.subtable1.subtable2 would be {subtable = {subtable2 = {}}}
]]
function table.fromindexedstring(sPaths, bForceTableReturn)
    local tRet 			= bForceTableReturn and {} or nil;
    local dstt			= string.delimitedtotable;
    local iscompliant 	= string.isvariablecompliant;
    local tIndices 		= dstt(sPaths, ".");


    if (rawtype(tIndices) == "table") then
        tRet = {};
        local tLast = tRet;

        for _, sIndex in pairs(tIndices) do

            if (iscompliant(sIndex)) then
                tLast[sIndex] 	= {};
                tLast 			= tLast[sIndex];
            end

        end

    end

    return tRet;
end



function string.tomoney(sInput)
    return sInput:isnumeric(sInput) and string.format("%.2f", sInput) or "0";
end

function string.todate(sInput)
    local sRet = sInput;

    if (type(sRet) == "string" and #sRet == 8) then
        sRet = sRet:sub(1, 2).."/"..sRet:sub(3, 4).."/"..sRet:sub(5);
    end

    return sRet;
end


--by  @james2doyle  https://gist.github.com/james2doyle/67846afd05335822c149
function validemail(str)
  if str == nil or str:len() == 0 then return nil end
  if (type(str) ~= 'string') then
    --error("Expected string")
    return nil
  end
  local lastAt = str:find("[^%@]+$")
  local localPart = str:sub(1, (lastAt - 2)) -- Returns the substring before '@' symbol
  local domainPart = str:sub(lastAt, #str) -- Returns the substring after '@' symbol
  -- we werent able to split the email properly
  if localPart == nil then
    return nil, "Local name is invalid"
  end
--ExitCode (number 1 == good, 0 bad), StdError (string), StdOut (string)
  if domainPart == nil or not domainPart:find("%.") then
    return nil, "Domain is invalid"
  end
  if string.sub(domainPart, 1, 1) == "." then
    return nil, "First character in domain cannot be a dot"
  end
  -- local part is maxed at 64 characters
  if #localPart > 64 then
    return nil, "Local name must be less than 64 characters"
  end
  -- domains are maxed at 253 characters
  if #domainPart > 253 then
    return nil, "Domain must be less than 253 characters"
  end
  -- somthing is wrong
  if lastAt >= 65 then
    return nil, "Invalid @ symbol usage"
  end
  -- quotes are only allowed at the beginning of a the local name
  local quotes = localPart:find("[\"]")
  if type(quotes) == 'number' and quotes > 1 then
    return nil, "Invalid usage of quotes"
  end
  -- no @ symbols allowed outside quotes
  if localPart:find("%@+") and quotes == nil then
    return nil, "Invalid @ symbol usage in local part"
  end
  -- no dot found in domain name
  if not domainPart:find("%.") then
    return nil, "No TLD found in domain"
  end
  -- only 1 period in succession allowed
  if domainPart:find("%.%.") then
    return nil, "Too many periods in domain"
  end
  if localPart:find("%.%.") then
    return nil, "Too many periods in local part"
  end
  -- just a general match
  if not str:match('[%w]*[%p]*%@+[%w]*[%.]?[%w]*') then
    return nil, "Email pattern test failed"
  end
  -- all our tests passed, so we are ok
  return true
end



ser/des aliases
rawset in protect function
add documentation for ini.lua



for AMS TODO allow, ...
function p(v1, v2)
    local bOneArg 	= v2 == nil;
    local sTitle 	= bOneArg and type(v1) 		or tostring(v1);
    local sMessage 	= bOneArg and tostring(v1) 	or tostring(v2);
    Dialog.Message(sTitle, sMessage);
end
