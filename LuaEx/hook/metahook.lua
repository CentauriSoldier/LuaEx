local tLuaEX = rawget(_G, "luaex");
local rawtype 	= rawtype;

function sealmetatable(tInput)
	local bRet = false;

	if (rawtype(tInput) == "table") then
		local tMeta 	= getmetatable(tInput);
		local sMetaType = rawtype(tInput);
		local bIsNil 	= sMetaType == "nil";

		if (sMetaType == "table" or bIsNil) then
			tMeta = bIsNil and {} or tMeta;
			tMeta.__metatable = false;
			setmetatable(tInput, tMeta);
		end

	end

	return bRet;
end

rawgetmetatable = getmetatable;

function getmetatable(tInput)
    local vRet  = nil;
    local tMeta = rawgetmetatable(tInput);

    if (tMeta) then
        vRet = tMeta;

        if (rawtype(tMeta["__is_luaex_class"]) ~= "nil") then
            vRet = {
                __is_luaex_class = tMeta.__is_luaex_class,
                __type = tMeta.__type,
            };
        end

    end

    return vRet;
end

rawsetmetatable = setmetatable;

function setmetatable(tInput, tMeta)
    local vRet          = nil;
    local tCurrentMeta  = rawgetmetatable(tInput);

    if (tCurrentMeta) then

        if (rawtype(tCurrentMeta["__is_luaex_class"]) ~= "nil" and tCurrentMeta.__is_luaex_class) then
            error("Error in class, '${}.' Attempt to modify class metatable.")
        end

    end

    return rawsetmetatable(tInput, tMeta);
end
