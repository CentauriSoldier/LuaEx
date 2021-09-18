local tLuaEx = _G.__LUAEX__;
local __type__ = type;

rawtype = __type__;

function type(vObject)
	local sType = __type__(vObject);

	if (sType == "table") then
		local tMeta = getmetatable(vObject);

		if (rawtype(tMeta) == "table" and rawtype(tMeta.__type) == "string") then
			sType = tMeta.__type;
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
