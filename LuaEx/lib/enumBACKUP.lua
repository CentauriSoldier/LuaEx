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
local tKeyWords = {"and", "break", "do", "else", "elseif", "end",
				   "false", "for", "function", "goto", "if", "in",
				   "local", "nil", "not", "or", "repeat", "return",
				   "then", "true", "until", "while",
				   --LuaEx keywords
				   "constant","enum"
			   };
local nKeywords = #tKeyWords;

local function isvariablecompliant(sInput, bSkipKeywordCheck)
	local bRet = false;
	local bIsKeyWord = false;

	--make certain it's not a keyword
	if (not bSkipKeywordCheck) then
		for x = 1, nKeywords do

			if sInput == tKeyWords[x] then
				bIsKeyWord = true;
				break;
			end

		end

	end

	if (not bIsKeyWord) then
		bRet =	(sInput ~= "")	 			and
				(not sInput:match("^%d")) 	and
				(not sInput:gsub("_", ""):match("[%W]"));
	end

	return bRet;
end

--TODO hasA is not working properly
local function formatName(sName)
	local sRet = "";
	local tString = sName:gsub("_", "_|"):totable("|");

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
	"__hasa",
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

local tReservedEnumItemIndices = {"enum", "id", "isa", "isSibling", "previous", "next", "name", "value", "value"};

local nReservedEnumItemIndices = #tReservedEnumItemIndices;

local function checkForReservedItemIndex(sInput)

	for x = 1, nReservedEnumItemIndices do

		if (sInput == tReservedEnumItemIndices[x]) then
			error("Error creating enum item. Cannot use '"..sInput.."' as an index; it is reserved.");
		end

	end

end

local function namesAreValid(tInput)
	local bRet 		= true;
	local nCount 	= 0;

	if (type(tInput) == "table") then
		--iterate through each name in the table
		for k, v in pairs(tInput) do
			nCount = nCount + 1;
			local bIsValid = type(k) == "number" and k == nCount and type(v) == "string" and isvariablecompliant(v, true);

			--check the entry
			if (not bIsValid) then
				bRet = false;
				break;
			end

			--make sure no reserved indices were input
			checkForReservedIndex(v);
		end

	end

	return (bRet and nCount > 0), nCount;
end

--TODO be sure to check the number of values against the number of name...this will require a number input to this function
local function validateValues(tValues)
	local sValuesType	= type(tValues);
	local bRet 		 	= true;
	local tRet			= tValues;

	if (sValuesType == "table") then
		local nIndexChecker = 0;

		for vIndex, vItem in pairs(tValues) do
			nIndexChecker = nIndexChecker + 1;

			if (type(vIndex) ~= "number") then
				bRet = false;
				tRet = {};
				break;
			end

			if (vIndex ~= nIndexChecker) then
				bRet = false;
				tRet = {};
				break;
			end

			local sItemType = type(vItem);

			if (sItemType == "nil") then
			--if (sItemType ~= "string"  	and sItemType ~= "number") then
			--and sItemType ~= "table" 	and sItemType ~= "function") then
				bRet = false;
				tRet = {};
				break;
			end

		end

	end

	return tRet;
end



--[[
███████╗███╗░░██╗██╗░░░██╗███╗░░░███╗
██╔════╝████╗░██║██║░░░██║████╗░████║
█████╗░░██╔██╗██║██║░░░██║██╔████╔██║
██╔══╝░░██║╚████║██║░░░██║██║╚██╔╝██║
███████╗██║░╚███║╚██████╔╝██║░╚═╝░██║
╚══════╝╚═╝░░╚══╝░╚═════╝░╚═╝░░░░░╚═╝
]]
local function enum(sName, tNames, tValues, bPrivate)
	sName 		= type(sName) 		== "string" 	and sName 		or "";
	tNames 		= type(tNames) 		== "table" 		and tNames 		or nil;
	tValues		= type(tValues) 	== "table" 		and tValues 	or {};
	bPrivate 	= type(bPrivate) 	== "boolean" 	and bPrivate 	or false;


	--[[█░█ ▄▀█ █▀█ █ ▄▀█ █▄▄ █░░ █▀▀   █▀▀ █░█ █▀▀ █▀▀ █▄▀   ▄▀█ █▄░█ █▀▄   █▀ █▀▀ ▀█▀ █░█ █▀█
		▀▄▀ █▀█ █▀▄ █ █▀█ █▄█ █▄▄ ██▄   █▄▄ █▀█ ██▄ █▄▄ █░█   █▀█ █░▀█ █▄▀   ▄█ ██▄ ░█░ █▄█ █▀▀]]
	local tLuaEX = _G.__LUAEX__;

	--insure the name input is a string
	assert(sName:gsub("%s", "") ~= "", "Enum name must be of type string and be non-blank;")--input value is '"..tostring(sName).."' of type "..type(sName));

	--check the name
	if (not bPrivate) then
		--check that the name string can be a valid variable
		assert(isvariablecompliant(sName), "Enum name must be a string whose text is compliant with lua variable rules; input string is '"..sName.."'");
		--make sure the variable doesn't already exist
		assert(type(_G[sName]) == "nil" and type(tLuaEX[sName] == "nil"), "Variable "..sName.." has already been assigned a non-nil value. Enum cannot overwrite existing variable.");
	end


	--check the names table
	local bNamesAreValid, nItemCount = namesAreValid(tNames);
	assert(bNamesAreValid, "Enum input must be a numerically-indexed table whose indices are implicit and whose values are strings.");

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
	tEnumData.__hasa = function(oItem)
		return type(oItem) == sName;
	end;
	tEnumData.__name 	= sName;

	--allows for quick determination of items' value
	local tCheckedValues = validateValues(tValues);

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
		__len		= nItemCount,
		__type		= "enum",
	});

	--[[█▀▀ █▄░█ █░█ █▀▄▀█   █ ▀█▀ █▀▀ █▀▄▀█ █▀
		██▄ █░▀█ █▄█ █░▀░█   █ ░█░ ██▄ █░▀░█ ▄█]]

	--process each enum item
	for nID, sItem in ipairs(tNames) do--ipairs preserves the enum items' input order
		local tItemShadow = {};

		--create the item's formatted name
		local sFormattedName = formatName(sItem);

		--keep track of the items by their ordinals
		tItemsByOrdinal[nID] = sItem;

		--get the value to be set
		local vValue;

		if (rawtype(tCheckedValues[nID]) == "nil") then
			vValue = nID;
		else
			vValue = tCheckedValues[nID];
		end

		local sValueType = type(vValue);

		--check if this is an enum
		local bValueIsEnum = sValueType == "enum";

		--create the item data table
		local tItemData = {
			enum		= tEnum,
			id			= nID,
			isa 		= function(tEnumItem, tEnumObject)
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
			valueType 	= bValueIsEnum and sItem or sValueType,
		};

		if (bValueIsEnum) then

			for _, oSubItem in vValue() do
				checkForReservedItemIndex(oSubItem.name);--TODO not working
				tItemData[oSubItem.name] = oSubItem;
			end

		end


		--create the item object
		local tItemObject = setmetatable(tItemShadow,
			{
				__index 	= function(tTable, vKey)

					if tItemData[vKey] == nil then
						error("The enum property or method '"..tostring(vKey).."' does not exist in item '"..sItem.."' in enum '"..sName.."'.");
					else
						return tItemData[vKey];
				 	end
				end,
				__newindex 	= modifyError;
				__tostring 	= function() return sFormattedName; end,
				__type		= sName,
			}
		);

		--make it visible to the enum's data table (both by name and ordinal)
		tEnumData[sItem] 	= tItemObject;
		tEnumData[nID] 		= tItemObject;
	end

	if (not bPrivate) then
		--put the enum into the global environment
		tLuaEX[sName] = tEnum;
	end

	return tEnum;
end

return enum;
