local error			= error;
local getmetatable	= getmetatable;
local ipairs 		= ipairs;
local pairs 		= pairs;
local rawget		= rawget;
local rawset		= rawset;
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

--keys are enum decoy tables and values are actual. This is used to embed enums.
local tEnumDecoyActualRepo = {};

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
local function formatName(sEnumName)
	local sRet = "";
	local tString = sEnumName:gsub("_", "_|"):totable("|");

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
	"serialize",
};

local nReservedIndices = #tReservedIndices;

local function checkForReservedIndex(sInput)

	for x = 1, nReservedIndices do

		if (sInput == tReservedIndices[x]) then
			error("Error creating enum. Cannot use '"..sInput.."' as an index; it is reserved.");
		end

	end

end

local tReservedEnumItemIndices = {"id", "isa", "isSibling", "previous", "next", "name", "parent", "serialize", "value", "valueType"};

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

local function processEnumItems(sEnumName, tEnumActual, tEnumDecoy, tItemsByOrdinal, tCheckedValues, tNames, nItemCount)

	--process each enum item
	for nID, sItem in ipairs(tNames) do--ipairs preserves the enum items' input order
		local tItemDecoy = {};

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
		local tItemActual = bValueIsEnum and tEnumDecoyActualRepo[vValue] or {};

		--create the item object
		local tItemMeta = {};

		--check if this is an embedded enum
		if (bValueIsEnum) then

			for _, oSubItem in vValue() do
				checkForReservedItemIndex(oSubItem.name);--TODO not working
				rawset(tItemActual, oSubItem.name, oSubItem);
			end

			--pull the meta table from the embedded enum
			tItemMeta = getmetatable(vValue);

		else

			tItemMeta.__newindex 	= modifyError;
			tItemMeta.__tostring 	= function() return sFormattedName; end;
		end

		--item(s) that must be put into the item metatable in either case (if it's an item or embdded enum)
		tItemMeta.__type 		= sEnumName;
		tItemMeta.__index 		= function(tTable, vKey)
			if (rawget(tItemActual, vKey) == nil) then
				error("The enum property or method '"..tostring(vKey).."' does not exist in item '"..sItem.."' in enum '"..sEnumName.."'.");
			end

			return rawget(tItemActual, vKey);
		end

		--set the item's metatable
		setmetatable(tItemDecoy, tItemMeta);

		--set the item's properties (use rawset in case it's an enum item)
		rawset(tItemActual, "parent", 		tEnumDecoy);
		rawset(tItemActual, "id", 			nID);
		rawset(tItemActual, "isa", 			function(oEnum)
			return (tItemActual.parent == oEnum);--type(tEnumObject) == "enum" and tItemActual.enum == tEnumObject);
		end)
		rawset(tItemActual, "isSibling",	function(oOther) --TODO if the sEnumName variable must be unique in the global env, must I check for enum equality as well?
			return tItemActual ~= oOther and (type(oOther) == sEnumName) and tItemActual.parent == oOther.parent;
		end)
		rawset(tItemActual, "previous",		function(bWrapAround)
			local nIndex = tItemActual.id - 1;
			local oRet = nil;
			if  (type(tItemsByOrdinal[nIndex]) ~= nil) then

				if (tEnumActual[tItemsByOrdinal[nIndex]]) then
					oRet = tEnumActual[tItemsByOrdinal[nIndex]];

				elseif (bWrapAround) then
					oRet = tEnumActual[tItemsByOrdinal[nItemCount]];
				end

			end

			return oRet;
		end)
		rawset(tItemActual, "next",			function(bWrapAround)
			local nIndex = tItemActual.id + 1;
			local oRet = nil;
			if  (type(tItemsByOrdinal[nIndex]) ~= nil) then

				if (tEnumActual[tItemsByOrdinal[nIndex]]) then
					oRet = tEnumActual[tItemsByOrdinal[nIndex]];

				elseif (bWrapAround) then
					oRet = tEnumActual[tItemsByOrdinal[1]];
				end

			end

			return oRet;
		end)
		rawset(tItemActual, "serialize",	function()--note: this overrides the enum function if this item is an embedded enum
			local sRet = "";
			local oParent = tItemActual.parent;

			while (oParent) do
				sRet = oParent.__name..'.'..sRet;
				oParent = rawget(tEnumDecoyActualRepo[oParent], "parent") or nil;
			end

			return sRet..sItem;
		end)
		rawset(tItemActual, "name",			sItem)
		rawset(tItemActual, "value", 		vValue);
		rawset(tItemActual, "valueType", 	bValueIsEnum and sItem or sValueType);

		--make the item visible to the enum's data table (both by name and ordinal)
		tEnumActual[sItem] 	= tItemDecoy;
		tEnumActual[nID] 	= tItemDecoy;
	end

end

local function configureEnum(sEnumName, tEnumActual, tEnumDecoy, tItemsByOrdinal, tCheckedValues, nItemCount)
	--prep all reserved items for the enum object
	for x = 1, nReservedIndices do
		tEnumActual[tReservedIndices[x]] = true;
	end;

	--set all reserved item values for the enum object
	tEnumActual.__count	= nItemCount;
	tEnumActual.__hasa = function(oItem)
		return type(oItem) == sEnumName;
	end
	tEnumActual.__name 	= sEnumName;
	tEnumActual.serialize = function()
		return sEnumName;
	end

	--used to iterate over each item in the enum
	local function itemsIterator(tTheEnum, nTheIndex)

		if (nTheIndex < #tItemsByOrdinal) then --todo use count value
			nTheIndex = nTheIndex + 1;
			return nTheIndex, tEnumActual[tItemsByOrdinal[nTheIndex]];
		end

	end

	--the iterator setup function for the __call metamethod in the enum object
	local function items(tTheEnum)
		return itemsIterator, tTheEnum, 0;
	end

	local sFormattedEnumName = formatName(sEnumName);

	-- the enum object's metatable
	setmetatable(tEnumDecoy, {
		__index 	= function(tTable, vKey)
			return tEnumActual[vKey] or error("The enum type or method '"..tostring(vKey).."' does not exist in enum '"..sEnumName.."'.");
		end,
		__newindex 	= modifyError,
		__call 		= items,
		__tostring 	= function() return sFormattedEnumName; end,
		__len		= function() return  nItemCount end,
		__type		= "enum",
	});

	--store the enum for later in case it gets embedded
	tEnumDecoyActualRepo[tEnumDecoy] = tEnumActual;
end

--[[
███████╗███╗░░██╗██╗░░░██╗███╗░░░███╗
██╔════╝████╗░██║██║░░░██║████╗░████║
█████╗░░██╔██╗██║██║░░░██║██╔████╔██║
██╔══╝░░██║╚████║██║░░░██║██║╚██╔╝██║
███████╗██║░╚███║╚██████╔╝██║░╚═╝░██║
╚══════╝╚═╝░░╚══╝░╚═════╝░╚═╝░░░░░╚═╝
]]
local function enum(sEnumName, tNames, tValues, bPrivate)
	sEnumName 	= type(sEnumName) 	== "string" and sEnumName	or "";
	tNames 		= type(tNames) 		== "table" 		and tNames 		or nil;
	tValues		= type(tValues) 	== "table" 		and tValues 	or {};
	bPrivate 	= type(bPrivate) 	== "boolean" 	and bPrivate 	or false;

	--[[█░█ ▄▀█ █▀█ █ ▄▀█ █▄▄ █░░ █▀▀   █▀▀ █░█ █▀▀ █▀▀ █▄▀   ▄▀█ █▄░█ █▀▄   █▀ █▀▀ ▀█▀ █░█ █▀█
		▀▄▀ █▀█ █▀▄ █ █▀█ █▄█ █▄▄ ██▄   █▄▄ █▀█ ██▄ █▄▄ █░█   █▀█ █░▀█ █▄▀   ▄█ ██▄ ░█░ █▄█ █▀▀]]
	local tLuaEX = _G.__LUAEX__;

	--insure the name input is a string
	assert(sEnumName:gsub("%s", "") ~= "", "Enum name must be of type string and be non-blank;")--input value is '"..tostring(sEnumName).."' of type "..type(sEnumName));

	--check the name
	if (not bPrivate) then
		--check that the name string can be a valid variable
		assert(isvariablecompliant(sEnumName), "Enum name must be a string whose text is compliant with lua variable rules; input string is '"..sEnumName.."'");
		--make sure the variable doesn't already exist
		assert(type(_G[sEnumName]) == "nil" and type(tLuaEX[sEnumName] == "nil"), "Variable "..sEnumName.." has already been assigned a non-nil value. Enum cannot overwrite existing variable.");
	end

	--check the names table
	local bNamesAreValid, nItemCount = namesAreValid(tNames);
	assert(bNamesAreValid, "Enum input must be a numerically-indexed table whose indices are implicit and whose values are strings.");

	--keeps track of items by their id for simpler and quicker access
	local tItemsByOrdinal	= {};
	--setup the actual table
	local tEnumActual		= {};
	--setup the decoy table
	local tEnumDecoy		= {};
	--allows for quick determination of items' value
	local tCheckedValues = validateValues(tValues);

	configureEnum(sEnumName, tEnumActual, tEnumDecoy, tItemsByOrdinal, tCheckedValues, nItemCount);
	processEnumItems(sEnumName, tEnumActual, tEnumDecoy, tItemsByOrdinal, tCheckedValues, tNames, nItemCount);

	if (not bPrivate) then
		--put the enum into the global environment
		tLuaEX[sEnumName] = tEnumDecoy;
	end

	return tEnumDecoy;
end

return enum;
