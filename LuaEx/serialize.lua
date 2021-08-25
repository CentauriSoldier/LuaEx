local serialize = {};

--TODO make this do all resitricted charas too
function serialize.string(sString)
	return (type(sString) == "string") and "\""..sString.."\"" or "\"\"";
end

function serialize.number(nNumber)
	return (type(nNumber) == "number") and nNumber or 0;
end

function serialize.boolean(bFlag)
	return (type(bFlag) == "boolean") and tostring(bFlag) or "false";
end

function serialize.table(tTable, nTabCount)
	nTabCount = (type(nTabCount) == "number" and nTabCount > 0) and nTabCount or 0;
	local sTab = "\t";

	for x = 1, nTabCount do
		sTab = sTab.."\t";
	end

	local sRet = "{";

	if (type(tTable) == "table") then


		for vIndex, vItem in pairs(tTable) do
			local sType = type(vItem);
			local sIndex = tostring(vIndex);

			--create the index
			if (type(vIndex) == "number") then
				sIndex = "\r\n"..sTab.."["..sIndex.."]";
			else
				sIndex = "\r\n"..sTab.."[\""..sIndex.."\"]";
			end

			--process the item
			if (sType == "string") then
				sRet = sRet..sIndex.." = \""..vItem.."\",";

			elseif (sType == "number") then
				sRet = sRet..sIndex.." = "..vItem..",";

			elseif (sType == "boolean") then
				sRet = sRet..sIndex.." = "..tostring(vItem)..",";

			elseif (sType == "table") then
				sRet = sRet..sIndex.." = "..serialize.table(vItem, nTabCount + 1)..",";

			else
				--if this has a serializtion function or method, call it
				if (type(vItem.Serialize) == "function") then
					sRet = sRet..sIndex.." = \""..vItem:Serialize().."\",";
				end

			end

		end

	end

	return sRet.."\r\n"..sTab:sub(1, -2).."}";
end

return serialize;
