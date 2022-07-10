local tLuaEx = _G.__LUAEX__;
local __type__ = type;
local tLuaExTypes = {
	class 				= true,
	constant			= true,
	enum 				= true,
	null 				= true,
	struct				= true,
	factory_constructor = true,
};

--since LuaEx hooks the type function, this is an alias to preserve the original
rawtype = __type__;
--isnull this is declared in the null module

function isnull(v)
	return v == null;
end

function isnil(v)
	return rawtype(v) == "nil";
end

function sealmetatable(tInput)
	local bRet = false;

	if (__type__(tInput) == "table") then
		local tMeta 	= getmetatable(tInput);
		local sMetaType = __type__(tInput);
		local bIsNil 	= sMetaType == "nil";

		if (sMetaType == "table" or bIsNil) then
			tMeta = bIsNil and {} or tMeta;
			tMeta.__metatable = false;
			setmetatable(tInput, tMeta);
		end

	end

	return bRet;
end


function xtype(vObject)
	local sType = __type__(vObject);

	if (sType == "table") then
		local tMeta = getmetatable(vObject);

		if (__type__(tMeta) == "table") then

			if (__type__(tMeta.__type) == "string") then

				if (tLuaExTypes[tMeta.__type] or tMeta.__type:find("struct ") or tMeta.__type:find(" struct") or tMeta.__is_luaex_class) then
					sType = tMeta.__type;
				end

			end

		end

	end

	return sType;
end


function type(vObject)
	local sType = __type__(vObject);

	if (sType == "table") then
		local tMeta = getmetatable(vObject);

		if (__type__(tMeta) == "table" and __type__(tMeta.__type) == "string") then
			sType = tMeta.__type;
		end

	end

	return sType;
end


function subtype(vObject)
	local sType = "nil";

	if (__type__(vObject) == "table") then
		local tMeta = getmetatable(vObject);

		if (__type__(tMeta) == "table" and __type__(tMeta.__subtype) == "string") then
			sType = tMeta.__subtype;
		end

	end

	return sType;
end


function fulltype(vObject)
	local sType = __type__(vObject);
	local sSpace = "";

	if (sType == "table") then
		local tMeta = getmetatable(vObject);

		if (__type__(tMeta) == "table") then

			if (__type__(tMeta.__type) == "string") then
				sType = tMeta.__type;
				sSpace = " ";
			end

			if (__type__(tMeta.__subtype) == "string") then
				sType = tMeta.__subtype..sSpace..(sType ~= "table" and sType or "");
			end

		end

	end

	return sType;
end


function protect(sReference)
	local sReferenceType 	= __type__(sReference);
	local sInputType		= __type__(_G[sReference]);
	assert(sReferenceType == "string" and sInputType ~= "nil", "Reference must be a string which is a key in _G. Input given is '"..tostring(sReference).."' of type "..sReferenceType..".");
	assert(__type__(tLuaEx[sReference]) == "nil", "Cannot protect item '"..sReference.."'; already protected.")
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
