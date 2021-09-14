local error			= error;
local getmetatable	= getmetatable;
local ipairs 		= ipairs;
local pairs 		= pairs;
local string		= string;
local setmetatable 	= setmetatable;
local tostring 		= tostring;
local type 			= type;

--[[
██╗░░░░░░█████╗░░█████╗░░█████╗░██╗░░░░░  ███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
██║░░░░░██╔══██╗██╔══██╗██╔══██╗██║░░░░░  ██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
██║░░░░░██║░░██║██║░░╚═╝███████║██║░░░░░  █████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
██║░░░░░██║░░██║██║░░██╗██╔══██║██║░░░░░  ██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
███████╗╚█████╔╝╚█████╔╝██║░░██║███████╗  ██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚══════╝  ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░
]]

local __type__ = type;

function type(vObject)
	local sType = __type__(vObject);

	if (sType == "table") then
		local tMeta = getmetatable(vObject);

		if (tMeta and tMeta.__type) then
			sType = tMeta.__type;
		end

	end

	return sType;
end

local function formatName(sName)
	local sRet = "";
	local tString = sName:gsub("_", "_|"):delmitedtotable("|");

	--go through each string in the table
	for x = 1, #tString do
		local sSubString = tString[x];

		--go through each character in the string
		for y = 1, #sSubString do

			--get the character
			local sChar = sSubString:sub(y, y);

			--lower or upper the char based on whether or not it's the first one of this substring
			sRet = sRet..((y == 1) and sChar:upper() or sChar:lower());
		end

	end

	return sRet:gsub("_", " ");
end

local function modifyError()
	error("Enums are read-only and cannot be modified once created.");
end

local tReservedIndices = {
	"__count",
	"__hasA",
	"__name",
};
local nReservedIndices = #tReservedIndices;

local function checkForReservedIndex(sInput)

	for x = 1, nReservedIndices do

		if (sInput == tReservedIndices[x]) then
			error("Error creating enum. Cannot use '"..sInput.."' as an index; it is reserved.");
		end

	end

end

local function namesAreValid(tInput)
	local bRet = true;
	local nCount = 0;

	--iterate through each name in the table
	for k, v in pairs(tInput) do
		nCount = nCount + 1;
		local bIsValid = type(k) == "number" and k == nCount and type(v) == "string" and v:isvariablecompliant(true);

		--check the entry
		if (not bIsValid) then
			bRet = false;
			break;
		end

		--make sure no reserved indices were input
		checkForReservedIndex(v);
	end

	return (bRet and nCount > 0), nCount;
end

local function valuesAreValid(tValues)
	local sValuesType = type(tValues);
	local bRet = sValuesType == "table";

	if (sValuesType == "table") then
		local nIndexChecker = 0;

		for vIndex, vItem in pairs(tValues) do
			nIndexChecker = nIndexChecker + 1;

			if (type(vIndex) ~= "number") then
				bRet = false;
				break;
			end

			if (vIndex ~= nIndexChecker) then
				bRet = false;
				break;
			end

			local sItemType = type(vItem);

			if (sItemType ~= "string"  	and sItemType ~= "number") then
			--and sItemType ~= "table" 	and sItemType ~= "function") then
				bRet = false;
				break;
			end

		end

	end

	return bRet;
end



--[[
███████╗███╗░░██╗██╗░░░██╗███╗░░░███╗
██╔════╝████╗░██║██║░░░██║████╗░████║
█████╗░░██╔██╗██║██║░░░██║██╔████╔██║
██╔══╝░░██║╚████║██║░░░██║██║╚██╔╝██║
███████╗██║░╚███║╚██████╔╝██║░╚═╝░██║
╚══════╝╚═╝░░╚══╝░╚═════╝░╚═╝░░░░░╚═╝
]]
local function enum(sName, tInput, tValues)

	--[[█░█ ▄▀█ █▀█ █ ▄▀█ █▄▄ █░░ █▀▀   █▀▀ █░█ █▀▀ █▀▀ █▄▀   ▄▀█ █▄░█ █▀▄   █▀ █▀▀ ▀█▀ █░█ █▀█
		▀▄▀ █▀█ █▀▄ █ █▀█ █▄█ █▄▄ ██▄   █▄▄ █▀█ ██▄ █▄▄ █░█   █▀█ █░▀█ █▄▀   ▄█ ██▄ ░█░ █▄█ █▀▀]]

	--insure the name input is a string
	assert(type(sName) == "string" and sName:gsub("%s", "") ~= "", "Enum name must be of type string and be non-blank; input value is '"..tostring(sName).."' of type "..type(sName));
	--check that the name string can be a valid variable
	assert(sName:isvariablecompliant(), "Enum name must be a string whose text is compliant with lua variable rules; input string is '"..sName.."'");
	--make sure the variable doesn't alreay exist
	assert(type(_G[sName]) == "nil", "Variable "..sName.." has already been assigned a non-nil value. Enum cannot overwrite existing variable.")
	--check the names table
	local bNamesAreValid, nItemCount = namesAreValid(tInput);
	assert(type(tInput) == "table" and bNamesAreValid, "Enum input must be a numerically-indexed table whose indices are implicit and whose values are strings.");

	--keeps track of items by their id for simpler and quicker access
	local tItemsByOrdinal	= {};
	local tShadow			= {};

	--setup the tEnumData table for the enum object
	local tEnumData			= {};

	--prep all reserved items for the enum object
	for x = 1, nReservedIndices do
		tEnumData[tReservedIndices[x]] = true;
	end;

	--[[█▀▀ █▄░█ █░█ █▀▄▀█   █▀█ █▄▄ ░░█ █▀▀ █▀▀ ▀█▀   █▀ █▀▀ ▀█▀ █░█ █▀█
		██▄ █░▀█ █▄█ █░▀░█   █▄█ █▄█ █▄█ ██▄ █▄▄ ░█░   ▄█ ██▄ ░█░ █▄█ █▀▀]]


	--set all reserved item values for the enum object
	tEnumData.__count	= nItemCount;
	tEnumData.__hasA = function(oItem)
		return type(oItem) == sName;
	end;
	tEnumData.__name 	= sName;

	--allows for quick determination of items' value
	local tCheckedValues		= valuesAreValid(tValues) and tValues or {};

	--used to iterate over each item in the enum
	local function itemsIterator(tTheEnum, nTheIndex)

		if (nTheIndex < #tItemsByOrdinal) then --todo use count value
			nTheIndex = nTheIndex + 1;
			return nTheIndex, tShadow[tItemsByOrdinal[nTheIndex]];
		end

	end

	--the iterator setup function for the __call metamethod in the enum object
	local function items(tTheEnum)
		return itemsIterator, tTheEnum, 0;
	end

	local sFormattedEnumName = formatName(sName);

	--create the enum object
	local tEnum	= setmetatable(tShadow, {
		__index 	= function(tTable, vKey)
			return tEnumData[vKey] or error("The enum type or method '"..tostring(vKey).."' does not exist in enum '"..sName.."'.");
		end,
		__newindex 	= modifyError,
		__call 		= items,
		__tostring 	= function() return sFormattedEnumName; end,
		__len		= nItemCount;
		__type		= "enum",
	});

	--[[█▀▀ █▄░█ █░█ █▀▄▀█   █ ▀█▀ █▀▀ █▀▄▀█ █▀
		██▄ █░▀█ █▄█ █░▀░█   █ ░█░ ██▄ █░▀░█ ▄█]]

	--process each enum item
	for nID, sItem in ipairs(tInput) do--ipairs preserves the enum items' input order
		local tItemShadow = {};

		--create the item's formatted name
		local sFormattedName = formatName(sItem);

		--keep track of the items by their ordinals
		tItemsByOrdinal[nID] = sItem;

		--get the value to be set
		local vValue = tCheckedValues[nID] or nID;
		local sValueType = type(vValue);

		--create the item data table
		local tItemData = {
			enum		= tEnum,
			id			= nID,
			isA 		= function(tEnumItem, tEnumObject)
				return (type(tEnumItem) == sName and type(tEnumObject) == "enum" and tEnumItem.enum == tEnumObject);
			end,
			isSibling	= function(oItem, oOther) --TODO if the sName variable must be unique in the global env, must I check for enum equality as well?
				return (type(oItem) == sName and type(oOther) == sName) and oItem.enum == oOther.enum;
			end,
			previous 	= function(oItem)
				local nIndex = oItem.id - 1;
				return type(tItemsByOrdinal[nIndex]) ~= nil and tShadow[tItemsByOrdinal[nIndex]] or nil;
			end,
			next 		= function(oItem)
				local nIndex = oItem.id + 1;
				return type(tItemsByOrdinal[nIndex]) ~= nil and tShadow[tItemsByOrdinal[nIndex]] or nil;
			end,
			name 		= sItem,
			value 		= vValue,
			valueType 	= sValueType,
		};

		--create the item object
		local tItemObject = setmetatable(tItemShadow,
			{
				__index 	= function(tTable, vKey)
					return tItemData[vKey] or error("The enum property or method '"..tostring(vKey).."' does not exist in item '"..sItem.."' in enum '"..sName.."'.");
				end,
				__newindex 	= modifyError;
				__tostring 	= function() return sFormattedName; end,
				__type		= sName,
				--__add
				--__sub
			}
		);

		--make it visible to the enum's data table (both by name and ordinal)
		tEnumData[sItem] = tItemObject;
		tEnumData[nID] = tItemObject;
	end

	--put the enum into the global environment
	_G[sName] = tEnum;
end

return enum;
