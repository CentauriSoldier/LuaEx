local tLuaEX = rawget(_G, "luaex");
local rawtype 	= rawtype;
local getmetatable = getmetatable;
local setmetatable = setmetatable;

function sealmetatable(tInput)
    local bRet = false;

    if (rawtype(tInput) == "table") then
        local tMeta 	= getmetatable(tInput);
        local sMetaType = rawtype(tInput);
        local bIsNil 	= sMetaType == "nil";

        if (sMetaType == "table" or bIsNil) then
            tMeta = bIsNil and {} or tMeta;
            tMeta.__metatable = false;
            rawsetmetatable(tInput, tMeta);
        end

    end

    return bRet;
end

rawgetmetatable = getmetatable;
--FIX this needs to address structs and enums too

function getmetatable(tInput)
    local vRet  = nil;
    local tMeta = rawgetmetatable(tInput);

    if (tMeta) then
        vRet = tMeta;

        for _, sName in pairs(tLuaEx.__metaguard) do

            if (rawtype(tMeta["__metaguard"] == "boolean") and tMeta["__metaguard"]) then
                vRet = {
                    __type      = tMeta.__type      or nil,
                    __subtype   = tMeta.__subtype   or nil,
                    __name      = tMeta.__name      or nil,
                };
            end

        end

    end

    return vRet;
end

rawsetmetatable = setmetatable;

function setmetatable(tInput, tMeta)
    local vRet          = nil;
    local tInputMeta  = rawgetmetatable(tInput);

    if (tInputMeta) then

        for _, sName in pairs(tLuaEx.__metaguard) do
            local bMetaGuard =  rawtype(tInputMeta["__metaguard"]) == "boolean" and
                                tInputMeta["__metaguard"]          or false;

            if (bMetaGuard) then
                local bNameMatch =  rawtype(tInputMeta["__type"])   == "boolean" and
                                    (tInputMeta["__type"] == sName) or false;

                if (bNameMatch) then
                    error("Error in object, '${object}.' Attempt to modify object metatable." % {object = tInputMeta.__type});
                end

            end

        end

    end

    return rawsetmetatable(tInput, tMeta);
end
