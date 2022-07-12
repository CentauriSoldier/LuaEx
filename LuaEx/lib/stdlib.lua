local tLuaEx = _G.__LUAEX__;






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
