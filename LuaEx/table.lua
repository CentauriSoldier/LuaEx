function table.clone(tTable)
	local tRet = {};

	if (type(tTable) == "table") then

		for vIndex, vItem in pairs(tTable) do

			if (type(vItem) == "table") then
				tRet[vIndex] = table.clone(vItem);
			else
				tRet[vIndex] = vItem;
			end

		end

	end

	return tRet;
end
