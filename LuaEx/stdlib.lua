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
