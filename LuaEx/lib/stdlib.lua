local tLuaEx = _G.__LUAEX__;
local __type__ = type;

rawtype = __type__;

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


function type(vObject)
	local sType = rawtype(vObject);

	if (sType == "table") then
		local tMeta = getmetatable(vObject);

		if (rawtype(tMeta) == "table" and rawtype(tMeta.__type) == "string") then
			sType = tMeta.__type;
		end

	end

	return sType;
end


function subtype(vObject)
	local sType = "nil";

	if (rawtype(vObject) == "table") then
		local tMeta = getmetatable(vObject);

		if (rawtype(tMeta) == "table" and rawtype(tMeta.__subtype) == "string") then
			sType = tMeta.__subtype;
		end

	end

	return sType;
end


function protect(sReference)
	local sReferenceType 	= rawtype(sReference);
	local sInputType		= rawtype(_G[sReference]);
	assert(sReferenceType == "string" and sInputType ~= "nil", "Reference must be a string which is a key in _G. Input given is '"..tostring(sReference).."' of type "..sReferenceType..".");
	assert(rawtype(tLuaEx[sReference]) == "nil", "Cannot protect item '"..sReference.."'; already protected.")
	local vInput 			= _G[sReference];

	local vProtected = vInput;

	--process the table (if needed)
	if (sInputType == "table") then--TODO check if the table is locked
		--clone the table
		vProtected = table.clone(vInput);
		--purge it
		table.purge(vInput);
		--forward the old reference to the new table
		vInput = setmetatable(vInput, {
			__index 	= vProtected,
			__newindex 	= vProtected,
		});
	end

	--protect the item
	tLuaEx[sReference] = vProtected;
	--clear the original entry from the global table
	_G[sReference] = nil;
end
