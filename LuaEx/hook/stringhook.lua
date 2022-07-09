local string = string;

local tKeyWords = {"and", 		"break", 	"do", 		"else", 	"elseif", 	"end",
				   "false", 	"for", 		"function", "if", 		"in", 		"local",
				   "nil", 		"not", 		"or", 		"repeat", 	"return", 	"then",
				   "true", 		"until", 	"while",
				   --LuaEx keywords
				   "constant", 	"enum", 	"struct",	"null"
			   };
local nKeywords = #tKeyWords;

local UUID_LENGTH 	= 16;
local UUID_BLOCKS	= 5;

function string.cap(sInput, bLowerRemaining)
local sRet = "";

	if string.len(sInput) > 1 then
	local sFirstLetter = string.sub(sInput, 1, 1);
	local sRightSide = string.sub(sInput, 2, string.len(sInput));
	sRet = string.upper(sFirstLetter);

		if bLowerRemaining then
		sRet = sRet..string.lower(sRightSide);

		else
		sRet = sRet..sRightSide;

		end


	else
	sRet = string.upper(sInput);
	end

return sRet
end


function string.capall(sInput)
local sRet = "";

	if not string.isblank(sInput) then
	local tWords = string.totable(sInput, " ");--TODO could this use %s to find any space character?
	local nWords = #tWords;

		for nIndex, sWord in pairs(tWords) do
		local sSpace = " ";

			if nIndex == nWords then
			sSpace = "";
			end

		local sFirstLetter = string.upper(string.sub(sWord, 1, 1));
		local sRightSide = string.sub(sWord, 2);
		sRet = sRet..sFirstLetter..sRightSide..sSpace;
		end

	end

return sRet, nWords, tWords
end

--https://www.codegrepper.com/code-examples/lua/lua+split+string+into+table  AND
--https://stackoverflow.com/questions/40149617/split-string-with-specified-delimiter-in-lua
function string.totable(sInput, sDelimiter)
    local tRet = {};
	for w in sInput:gmatch("([^"..(sDelimiter or "|").."]+),?") do
        table.insert(tRet, w);
    end
    return tRet;
end

--TODO put in lua ex CAN THIS BE OPTIIMIZE BY MAING THE RETURNED FUNCTION LOCAL?
--http://lua-users.org/wiki/StringInterpolation
getmetatable("").__mod = function(s, tab) return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end)) end;



function string.getfuncname(fFunc) --TODO figure out how to make this simpler and recursive with a safety

	if type(fFunc) == "function" then

		for vIndex, vItem in pairs(getfenv(fFunc)) do

			if vIndex ~= "_G" then
			local sItemType = type(vItem);

				if sItemType == "function" then

					if vItem == fFunc then
					return vIndex
					end

				elseif sItemType == "table" then

					for vIndex2, vItem2 in pairs(vItem)	do
					local sItemType2 = type(vItem2);

						if sItemType2 == "function" then

							if vItem2 == fFunc then
							return vIndex.."."..vIndex2
							end

						elseif sItemType2 == "table" then

							for vIndex3, vItem3 in pairs(vItem2) do
							local sItemType3 = type(vItem3);

								if sItemType3 == "function" then

									if vItem3 == fFunc then
									return vIndex.."."..vIndex2.."."..vIndex3
									end

								elseif sItemType3 == "table" then

									for vIndex4, vItem4 in pairs(vItem3) do
									local sItemType4 = type(vItem4);

										if sItemType4 == "function" then

											if vItem4 == fFunc then
											return vIndex.."."..vIndex2.."."..vIndex3.."."..vIndex4
											end

										end

									end

								end

							end

						end

					end

				end

			end

		end

	end

return ""
end


function string.iskeyword(sInput)
	local bRet = false;

	for x = 1, nKeywords do

		if sInput == tKeyWords[x] then
			bRet = true;
			break;
		end

	end

	return bRet;
end


function string.isnumeric(sInput)
	return type(sInput) == "string" and sInput:gsub("[%d%.]", "") == "";
end


function string.isvariablecompliant(sInput, bSkipKeywordCheck)
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


--https://snippets.bentasker.co.uk
function string.trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)';
end


--https://snippets.bentasker.co.uk
function string.trimleft(s)
  return s:match'^%s*(.*)';
end


--https://snippets.bentasker.co.uk
function string.trimright(s)
  return s:match'^(.*%S)%s*$';
end


function string.uuid()
	local sRet 			= "";
	local tChars 		= {"7","f","1","e","3","c","6","b","5","9","a","4","8","d","0","2"};--must be equal to UUID_LENGTH
	local sDelimiter 	= "-";
	local sPrefix 		= rawtype(sInputPrefix) == "string" and sInputPrefix or "";
	local tSequence 	= {8, 4, 4, 4, 12};

	for nBlock, nBlockCharCount in pairs(tSequence) do
		local sDash = nBlock < UUID_BLOCKS and "-" or "";

		for x = 1, nBlockCharCount do
			sRet = sRet..tChars[math.random(1, UUID_LENGTH)];
		end

		sRet = sRet..sDash;
	end

	return sRet
end

return string;
