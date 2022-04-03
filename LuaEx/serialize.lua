local serialize = {};

--TODO Move these to util
local tEscapeChars = {
	[1] 	= "\\",
	[2] 	= "\a",
	[3] 	= "\b",
	[4] 	= "\f",
	[5] 	= "\n",
	[6] 	= "\r",
	[7] 	= "\t",
	[8] 	= "\v",
	[9] 	= "\"",
	[10] 	= "\'",
};
local nEscapeChars = #tEscapeChars;

local tEscapeCharsConverted = {
	[1] 	= "\\\\",
	[2] 	= "\\a",
	[3] 	= "\\b",
	[4] 	= "\\f",
	[5] 	= "\\n",
	[6] 	= "\\r",
	[7] 	= "\\t",
	[8] 	= "\\v",
	[9] 	= "\\\"",
	[10] 	= "\\'",
};

local tMagicChars = {
	[1] 	= "%%%%",
	[2] 	= "%%%(",
	[3] 	= "%%%)",
	[4] 	= "%%%.",
	[5] 	= "%%%+",
	[6] 	= "%%%-",
	[7] 	= "%%%*",
	[8] 	= "%%%?",
	[9] 	= "%%%[",
	[10] 	= "%%%]",
	[11] 	= "%%%^",
	[12] 	= "%%%$",
};
local nMagicChars = #tMagicChars;

local tMagicCharsConverted = {
	[1] 	= "%%%%%%%%",
	[2] 	= "%%%%%%%(",
	[3] 	= "%%%%%%%)",
	[4] 	= "%%%%%%%.",
	[5] 	= "%%%%%%%+",
	[6] 	= "%%%%%%%-",
	[7] 	= "%%%%%%%*",
	[8] 	= "%%%%%%%?",
	[9] 	= "%%%%%%%[",
	[10] 	= "%%%%%%%]",
	[11] 	= "%%%%%%%^",
	[12] 	= "%%%%%%%$",
};



local function serializeRestrictedChars(sInput)
end

function serialize.boolean(bFlag)
	return (type(bFlag) == "boolean") and tostring(bFlag) or "false";
end

function serialize.number(nNumber)
	return (type(nNumber) == "number") and nNumber or 0;
end

--TODO make this do all resitricted charas too
function serialize.string(sString)
	local sRet = "";

	if (type(sString) == "string") then
		sRet = sString;

		--look for escape characters
		for x = 1, nEscapeChars do
			sRet = sRet:gsub(tEscapeChars[x], tEscapeCharsConverted[x]);
		end

		--look for magic characters
		for x = 1, nMagicChars do
			sRet = sRet:gsub(tMagicChars[x], tMagicCharsConverted[x]);
		end

		sRet = "\""..sRet.."\"";
	end

	return sRet;
end

local str = serialize.string;

--TODO serialize metatable (if possible)???
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
				sRet = sRet..sIndex.." = "..str(vItem)..",";

			elseif (sType == "number") then
				sRet = sRet..sIndex.." = "..vItem..",";

			elseif (sType == "boolean") then
				sRet = sRet..sIndex.." = "..tostring(vItem)..",";

			elseif (sType == "table") then
				sRet = sRet..sIndex.." = "..serialize.table(vItem, nTabCount + 1)..",";

			else
				--if this has a (S)serializtion function or method, call it TODO does this need to a class in order to use the ":" operator?
				if (type(vItem.serialize) == "function") then
					sRet = sRet..sIndex.." = \""..vItem:serialize().."\",";
				elseif (type(vItem.Serialize) == "function") then
					sRet = sRet..sIndex.." = \""..vItem:Serialize().."\",";
				end

			end

		end

	end

	return sRet.."\r\n"..sTab:sub(1, -2).."}";
end

return serialize;
