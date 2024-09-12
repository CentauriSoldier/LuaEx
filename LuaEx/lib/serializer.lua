--TODO serialize metatable (if possible)???
--TODO account for self references in tables

--LOCALIZATION INCOMPLETE TODO more localization
local assert            = assert;
local error             = error;
local rawtype           = rawtype;
local rawgetmetatable   = rawgetmetatable;
local setmetatable      = setmetatable;
local string            = string;
local table             = table;
local type              = type;
local tonumber          = tonumber;
local tostring          = tostring;

--DECLARATIONS
local serializer, serializerDoNotPack, deserializer, tTypePrefixes;


--LOCAL VARIABLES & CONSTANTS SECTION
local _sTabChars                = "    ";
local _sCRPrefix                = "(((LXCRT";
local _sCRSuffix                = "LXCRT)))";
local _sCircularReference       = _sCRPrefix.."78a70e790106425d903e0f9614c1ed30".._sCRSuffix;

--WARNING Prepend only those items which are already initialized in init.lua.
tTypePrefixes = {--TODO what about constants?
    ["array"]       = array,
    ["clausum"]     = clausum,
    ["enum"]        = enum,
    ["struct"]      = struct,
    --[""] = ,
};


--LOCAL UTILITY FUNCTIONS

--for storing functions with upvalues BUG
--[[function deserializeFunction(sByteCode, sUpValues)
    local data = {
        bytecode = base64.dec(sByteCode),
        upvalues = deserialize(base64.dec(sUpValues)),
    };

    local func, err = load(data.bytecode)
    if not func then
        error("Failed to load function: " .. err)
    end

    for name, value in pairs(data.upvalues or {}) do
        local i = 1
        while true do
            local uname, uvalue = debug.getupvalue(func, i)
            if not uname then break end
            if uname == name then
                if type(value) == "table" and value.bytecode and value.upvalues then
                    -- If the upvalue is a function with upvalues, recursively deserialize it
                    uvalue = deserializeFunction(value)
                else
                    uvalue = value
                end
                debug.setupvalue(func, i, uvalue)
                break
            end
            i = i + 1
        end
    end

    return func
end]]


local function packSerialData(sType, sData)
    return sType..".deserialize(serializer.unpackData(\""..base64.enc(sData).."\"))";
end


local function registerType(sType, oType, bDoNotPack)
    local sErrorPrefix = "Error registering object type with serializer.\n";

    assert(rawtype(oType) == "table", sErrorPrefix.."Object must be of rawtype table.");

    local tMeta = getmetatable(oType);

    assert(type(tMeta)                      == "table", sErrorPrefix.."Object of type '"..sType.."' does not have an accessible metatable.");
    assert(type(sType)                      == "string" and sType:isvariablecompliant(true), sErrorPrefix.."Object must have a __type metatable index whose value is a unique, variable-compliant string.");
    assert(not tPackables[sType] and not tNonPackables[sType], sErrorPrefix.."Object of type "..sType.." is already registered.");
    assert(type(tMeta.__call)               == "function", sErrorPrefix.."Object ("..sType..") must have a __call metamethod capable of creating the (equivilant) object instance.")

    if (bDoNotPack) then
        tNonPackables[sType] = oType;
    else
        tPackables[sType] = oType;
    end
end


local function unpackSerialData(sEncodedData)
    local sData = base64.dec(sEncodedData);
    local fItem, sError = load("return "..sData);

    if not (fItem) then
        error("Error in serializer while unpacking data. Data is malformed.");
    end

    return fItem();
end


local function unimplemented(sType)
    error("Serializtion for type "..type(sType).." has not been implemented.");
end


--INCOMPLETE
tPackables = {--the tPackables FUNCTIONS table
    ["array"]                   = function(aItem)
        return getmetatable(aItem).__serialize();
    end,
    --["clausum"]                 = unimplemented,
    ["enum"]                    = unimplemented,
    ["struct"]                  = function(aItem)
        return getmetatable(aItem).__serialize();
    end,
    ["structfactory"]           = function(aItem)
        return getmetatable(aItem).__serialize();
    end,

};

--INCOMPLETE
tNonPackables = {--the tNonPackables FUNCTIONS table
    ["arrayfactory"]            = function(aItem)
        return getmetatable(aItem).__serialize();
    end,
    ["boolean"]                 = function(bValue)
        return tostring(bValue);
    end,
    ["class"]                   = function(aItem)
        return getmetatable(aItem).__serialize();--TODO should I cache these since they're known types?
    end,
    ["classfactory"]            = function(aItem)
        return getmetatable(aItem).__serialize();--TODO should I cache these since they're known types?
    end,
    ["function"]                = function(fValue)
        return "load(base64.dec(\""..base64.enc(string.dump(fValue)).."\"))";
    end,
    --[[["function"]                = function(fValue)---TODO account for _G
        local bytecode = string.dump(fValue)
        local tUpValues = {}

        local i = 1
        while true do
            local sName, value = debug.getupvalue(fValue, i)
            if not sName then break end
            --if sName ~= "_ENV" then -- Exclude _ENV upvalue
                if type(value) == "function" and value ~= fValue then
                    -- Recursively serialize nested functions with tUpValues
                    value = serializerDoNotPack["function"] (value)
                end
                tUpValues[sName] = value
            --end
            i = i + 1
        end

        local sByteCodeEnc = base64.enc(bytecode)
        local sUpValuesEnc = base64.enc(serialize(tUpValues));

        return "serializer.deserializeFunction(\""..sByteCodeEnc.."\", \""..sUpValuesEnc.."\")";

    end,]]
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
    ["structfactorybuilder"] = function(aItem)
        return getmetatable(aItem).__serialize();
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
--TODO set the flow like the cloner as it with the error at the end
    --first, check if this is a primitive type
    if (tNonPackables[sType]) then
        sRet = tNonPackables[sType](vInput);

    ---check if the non-primitive type is registered
    elseif (tPackables[sType]) then
        local fSerialize = tPackables[sType];
        local vData = fSerialize(vInput, tSavedTables, tTabCount);
        print(sType)
        if (type(vData) ~= "string") then
            vData = serialize(vData, tSavedTables, tTabCount);
        end

        sRet = packSerialData(sType, vData);

    --look for a serialize metamethod in unregistered type
    elseif(rawtype(vInput) == "table") then--QUESTION should I allow a second input from serializer that would tell whether to pack the data?

        local tMeta = getmetatable(vInput);

        if (tMeta and tMeta.__serialize) then
            local vData = tMeta.__serialize(vInput, tSavedTables, tTabCount);

            if (type(vData) ~= "string") then
                vData = serialize(vData, tSavedTables, tTabCount);--TODO should the table info be passed here? test this on mmbrdded tables
            end

            sRet = packSerialData(sType, vData);
        else
            error("Unregisted type, '${type}', cannot be serialized;\nIt does not have a __serialize metamethod." % {type = sType}, 2);
        end

    --throw an error for an unregistered type without a __serialize metamethod
    else
        --TODO THROW ERROR can this ever fire?


    end

    return sRet;
end


local function deserialize(sRawData, tSavedTables, tTabCount)

    if (rawtype(sRawData) ~= "string") then
        error("Error in deserializer. Expected string in argument 1. Type given: "..rawtype(sRawData));
    end

    local fItem, sError = load("return "..sRawData);

    if not (fItem) then
        error("Error deserializing data. Data is malformed.\n"..sRawData);
    end

    return fItem();
end

--[[
local function deserialize(sRawData, tSavedTables, tTabCount)
    -- Check if the serialized data represents a function
    if string.match(sRawData, "^function") then
        -- Deserialize the function using deserializeFunctionWithUpvalues
        return deserializeFunctionWithUpvalues(sRawData)
    else
        -- Otherwise, return the deserialized item as is
        return fItem()
    end
end]]


local tSerializerActual = {
    deserialize         = deserialize,
    --registerType        = registerType,
    serialize           = serialize,
    --deserializeFunction = deserializeFunction,
    unpackData          = unpackSerialData,
};


return setmetatable({}, {
    __index = function(t, k)
        return tSerializerActual[k] or nil;
    end,
    __newindex = function(t, k, v)
        error("Error: attempting to modify read-only serializer at index ${index} with ${value} (${type})." % {index = tostring(k), value = tostring(v), type = type(v)});
    end,
});
