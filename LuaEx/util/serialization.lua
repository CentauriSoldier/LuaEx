--TODO serialize metatable (if possible)???

--LOCALIZATION TODO more localization
local rawtype       = rawtype;
local setmetatable  = setmetatable;
local string        = string;
local table         = table;
local tonumber      = tonumber;


--DECLARATIONS
local serializer, serializerPrimitives, deserializer, tTypePrefixes;


--LOCAL VARIABLES & CONSTANTS SECTION
local _sTabChars                = "    ";
local _sCRPrefix                = "(((LXCRT";
local _sCRSuffix                = "LXCRT)))";
local _sCircularReference       = _sCRPrefix.."78a70e790106425d903e0f9614c1ed30".._sCRSuffix;

local _sTypePrefixStart         = "|LXTS-|";
local _nTypePrefixStartLength   = #_sTypePrefixStart;
local _sTypePrefixEnd           = "|-LXTE|";
local _nTypePrefixEndLength     = #_sTypePrefixEnd;
local _nTypePrefixLength        = _nTypePrefixStartLength + _nTypePrefixEndLength;

local _sDataStart                = "|LXDS-|";
local _sDataStartLength          = #_sDataStart;
local _sDataEnd                  = "|-LXDE|";
local _sDataEndLength            = #_sDataEnd;

--WARNING Prepend only those items which are already initialized in init.lua.
tTypePrefixes = {--TODO what about constants?
    ["array"]       = array,
    ["clausum"]     = clausum,
    ["enum"]        = enum,
    ["struct"]      = struct,
    --[""] = ,
};


--LOCAL UTILITY FUNCTIONS
local function unimplemented(sType)
    error("Serializtion for type "..type(sType).." has not been implemented.");
end


local function packSerialData(sType, sData)
    return _sTypePrefixStart..sType.._sTypePrefixEnd.._sDataStart..sData.._sDataEnd;
end


local function serializerRegisterType(sType, oType)
    assert(rawtype(sType) == "string" and sType:isvariablecompliant(), "Error registering type with serializer.\nType name must be a variable-compliant string.");
    assert(rawtype(oType) == "table", "Error registering type with serializer.\nObject must be of type table and have a __call metamethod capable of creating the (equivilant) object instance."); --TODO better messages, more  details
    --TODO assert item doesn't already exist
    --TODO allow setting of serialize/deserialize functions
    tTypePrefixes[sType] = oType;
end


local function runTypeDeserialize(sType, dataString)--TODO proper variable naming
    -- Load the data string as a Lua table
    local fData, sDataError = load("return "..dataString);

    if not fData then
        error("Failed to load data: " .. sDataError);
    end

    local vData = fData();

    -- Load the type string as a callable type
    local fType, sTypeError = load("return "..sType);

    if not fType then
        error("Failed to load type: " .. sTypeError);
    end

    local oObject = fType();

    if not (oObject.deserialize) then
        error("Error deserializing type, "..sType..".\nNo public static deserialize method exists.");
    end

    -- Call the type's deserialize method with the data
    return oObject.deserialize(vData);
end


local function unpackSerialData(sInput)
    local sType, sData;

    -- Check if the string starts with the type prefix
    if sInput:sub(1, _nTypePrefixStartLength) == _sTypePrefixStart then
        -- Find the position of the type end prefix
        local typeEndPos = sInput:find(_sTypePrefixEnd, _nTypePrefixStartLength + 1, true);

        if typeEndPos then
            -- Extract the type string
            sType = sInput:sub(_nTypePrefixStartLength + 1, typeEndPos - 1);

            -- Find the position of the data start prefix
            local dataStartPos = sInput:find(_sDataStart, typeEndPos + _nTypePrefixEndLength, true);
            if dataStartPos then
                -- Find the position of the data end prefix
                local dataEndPos = sInput:find(_sDataEnd, dataStartPos + _sDataStartLength, true);
                if dataEndPos then
                    -- Extract the data string
                    sData = sInput:sub(dataStartPos + _sDataStartLength, dataEndPos - 1);
                else
                    print("Error: Data end prefix not found.")
                end
            else
                print("Error: Data start prefix not found.")
            end
        else
            print("Error: Type end prefix not found.")
        end
    else
        print("Error: String does not start with type prefix.")
    end
    return sType, sData;
end




--INCOMPLETE
serializer = {--the serialize FUNCTIONS table
    ["array"]                   = function(aItem)
        return getmetatable(aItem).__serialize();
    end,
    ["arrayfactory"]            = unimplemented,
    ["class"]                   = unimplemented,
    ["classfactory"]            = unimplemented,
    ["clausum"]                 = unimplemented,
    ["enum"]                    = unimplemented,
    ["struct"]                  = unimplemented,
    ["structfactory"]           = unimplemented,
    ["structfactorybuilder"]    = unimplemented,
};

--INCOMPLETE
serializerPrimitives = {--the serializerPrimitives FUNCTIONS table
    ["boolean"]                 = function(bValue)
        return tostring(bValue);
    end,
    ["function"]                = function(fValue)
        return string.dump(fValue);
    end,
    ["nil"]                     = function()
        return "nil";
    end,
    ["null"]                    = function(fValue)
        return "null";
    end,
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


local function serialize(vInput, tSavedTables, tTabCount)
    local sRet = "";
    local sType = type(vInput);

    --first, check if this is a primitive type
    if (serializerPrimitives[sType]) then
        sRet = serializerPrimitives[sType](vInput);
        
    ---check if the non-primitive type is registered
    elseif (serializer[sType]) then
        local fSerialize = serializer[sType];
        local vData = fSerialize(vInput, tSavedTables, tTabCount);

        if (type(vData) ~= "string") then
            --print(vData)
            vData = serialize(vData, tSavedTables, tTabCount);
            --print(#(vData))
        end

        sRet = packSerialData(sType, vData);

    --look for a serialize metamethod in unregistered type
    elseif(rawtype(vInput) == "table") then
        local tMeta = getmetatable(vInput);

        if (tMeta and tMeta.__serialize) then
            local vData = tMeta.__serialize(vInput, tSavedTables, tTabCount);

            if (type(vData) ~= "string") then
                vData = serialize(vData, tSavedTables, tTabCount);
            end

            sRet = packSerialData(sType, vData);
        else
            error("Unregisted type, '${type}', cannot be serialized;\nIt does not have a __serialize metamethod." % {type = sType});
        end

    --throw an error for an unregistered type without a __serialize metamethod
    else
        --TODO THROW ERROR can this ever fire?


    end

    return sRet;
end


local function deserialize(sRawData, tSavedTables, tTabCount)
    local vRet;
    --TODO assert raw data
    local sType, sData = unpackSerialData(sRawData);

    if (sType and sData) then
        vRet = runTypeDeserialize(sType, sData);
    else
        vRet = load(sRawData);
    end

    return vRet;
end

return {
        [1] = serializerRegisterType,
        [2] = serialize,
        [3] = deserialize,
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
