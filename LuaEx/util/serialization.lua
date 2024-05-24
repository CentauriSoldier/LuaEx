--TODO serialize metatable (if possible)???
--localization
local rawtype       = rawtype;
local string        = string;
local table         = table;
local setmetatable  = setmetatable;

local _sTabChars            = "    ";
local _sCRPrefix            = "(((LUAEXCRT";
local _sCRSuffix            = "LUAEXCRT)))";
local _sCircularReference   = _sCRPrefix.."78a70e790106425d903e0f9614c1ed30".._sCRSuffix;

local function unimplemented(sType)
    error("Serializtion for type "..type(sType).." has not been implemented.");
end

local serializer = {--the serialize table
    ["array"]                   = function(aItem)
        return getmetatable(aItem).__serialize();
    end,
    ["boolean"]                 = unimplemented,
    ["arrayfactory"]            = unimplemented,
    ["class"]                   = unimplemented,
    ["classfactory"]            = unimplemented,
    ["clausum"]                 = unimplemented,
    ["enum"]                    = unimplemented,
    ["function"]                = unimplemented,
    ["nil"]                     = unimplemented,
    ["null"]                    = unimplemented,
    ["number"]                  = function(nValue)--TODO check for nan, inf and undefined (or do I even need to given the __tostring metamethods of those items?)
        return ""..nValue.."";
    end,
    ["string"]                  = function(sInput)
        -- Escape backslashes first to avoid double-escaping
        sInput = sInput:gsub("\\", "\\\\");

        -- Escape double quotes
        sInput = sInput:gsub("\"", "\\\"");

        -- Escape single quotes if needed
        sInput = sInput:gsub("\'", "\\'");

        -- Escape common control characters
        sInput = sInput:gsub("\a", "\\a");
        sInput = sInput:gsub("\b", "\\b");
        sInput = sInput:gsub("\f", "\\f");
        sInput = sInput:gsub("\n", "\\n");
        sInput = sInput:gsub("\r", "\\r");
        sInput = sInput:gsub("\t", "\\t");
        sInput = sInput:gsub("\v", "\\v");

        -- Escape null character
        sInput = sInput:gsub("\0", "\\0");

        -- Escape Lua pattern magic characters without doubling them
        return "\""..sInput:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%1").."\"";
    end,
    ["struct"]                  = unimplemented,
    ["structfactory"]           = unimplemented,
    ["structfactorybuilder"]    = unimplemented,
    ["table"]                   = function(tInput, tSavedTables, tTabCount)
        local sRet = "{";
        tSavedTables = tSavedTables or {}
        tTabCount = type(tTabCount) == "table" and tTabCount or {count = 0};

        if tSavedTables[tInput] then
           return _sCircularReference;
        end

        tSavedTables[tInput] = true
        --TODO metatables
        tTabCount.count = tTabCount.count + 1;

        local sTab = _sTabChars:rep(tTabCount.count);

        for k, v in pairs(tInput) do
            local sKey      = "[".. serialize(k, tSavedTables, tTabCount) .."]";
            local sValue    =       serialize(v, tSavedTables, tTabCount);
            sRet = sRet.."\n"..sTab..sKey.." = "..sValue..',';
        end

        tTabCount.count = tTabCount.count - 1;
        sTab = _sTabChars:rep(tTabCount.count);

        return sRet.."\n"..sTab.."}";
    end,
    ["thread"]                  = unimplemented,
    ["userdata"]                = unimplemented,
};



return {
        [1] =
function(vInput, tSavedTables, tTabCount) --serialize
    local sRet = "";
    local sType = type(vInput);

    if (serializer[sType]) then
        sRet = serializer[sType](vInput, tSavedTables, tTabCount);
    end


    local sRawType = rawtype(vInputd);

    return sRet;
end,
        [2] =
function(vInput, tSavedTables, tTabCount) --deserialize
    local sRet = "";
    local sType = type(vInput);

    if (serializer[sType]) then
        sRet = serializer[sType](vInput, tSavedTables, tTabCount);
    end


    local sRawType = rawtype(vInputd);

    return sRet;
end
};
--[[ARCHIVE
["tableold"] = function(tTable, nTabCount)
    nTabCount = (rawtype(nTabCount) == "number" and nTabCount > 0) and nTabCount or 0;
    local sTab = "\t";

    for x = 1, nTabCount do
        sTab = sTab.."\t";
    end

    local sRet = "{";

    if (rawtype(tTable) == "table") then

        for vIndex, vItem in pairs(tTable) do
            local sType = rawtype(vItem);
            local sIndex = tostring(vIndex);

            --create the index
            if (rawtype(vIndex) == "number") then
                sIndex = "\r\n"..sTab.."["..sIndex.."]";
            else
                sIndex = "\r\n"..sTab.."[\""..sIndex.."\"]";
            end

            --process the item
            if (sType == "string") then
                sRet = sRet..sIndex.." = "..ser.string(vItem)..",";

            elseif (sType == "number") then
                sRet = sRet..sIndex.." = "..vItem..",";

            elseif (sType == "boolean") then
                sRet = sRet..sIndex.." = "..tostring(vItem)..",";

            elseif (sType == "table") then

                --if this has a (S)serializtion function or method, call it TODO does this need to a class in order to use the ":" operator?
                local mt = getmetatable(vItem)
                if mt and rawtype(mt.__tostring) == "function" then
                    sRet = sRet..sIndex.." = "..tostring(vItem)..",";
                elseif (rawtype(vItem.serialize) == "function") then
                    sRet = sRet..sIndex.." = "..vItem.serialize()..",";
                elseif (rawtype(vItem.Serialize) == "function") then
                    sRet = sRet..sIndex.." = "..vItem.Serialize()..",";
                else
                    sRet = sRet..sIndex.." = "..serialize.table(vItem, nTabCount + 1)..",";
                end

            else


            end

        end

    end

    return sRet.."\r\n"..sTab:sub(1, -2).."}";
end,

]]
