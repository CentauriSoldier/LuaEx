local tLuaEX = _G.__LUAEX__;

local tKeyWords = {"and", "break", "do", "else", "elseif", "end",
				   "false", "for", "function", "if", "in", "local",
				   "nil", "not", "or", "repeat", "return", "then",
				   "true", "until", "while",
				   --LuaEx keywords
				   "constant","enum"
			   };
local nKeywords = #tKeyWords;

local function isKeyword(sInput)
	local bRet = false;

	for x = 1, nKeywords do

		if sInput == tKeyWords[x] then
			bRet = true;
			break;
		end

	end

	return bRet;
end

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

local function constant(sName, vVal)

	--insure the name input is a string
	assert(type(sName) == "string" and sName:gsub("%s", "") ~= "", "Constant name must be of type string and be non-blank; input value is '"..tostring(sName).."' of type "..type(sName));
	--check that the name string can be a valid variable
	assert(isvariablecompliant(sName), "Constant name must be a string whose text is compliant with lua variable rules; input string is '"..sName.."'");
	--make sure the variable doesn't alreay exist
	assert(type(_G[sName]) == "nil" and type(tLuaEX[sName] == "nil"), "Variable "..sName.." has already been assigned a non-nil value. Cannot overwrite existing item.");
	--make sure the constant is not nil
	assert(type(vVal) ~= "nil", "Cannot create constant; value cannot be nil.");
	--make sure the value doesn't alreay exist
	assert(type(_G[sName]) == "nil", "Variable "..sName.." has already been assigned a non-nil value. Cannot overwrite existing variable.")

	--put the const into the global environment (via the luaex protected table)
	tLuaEX[sName] = vVal;
end

return constant;
