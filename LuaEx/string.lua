local tKeyWords = {"and", "break", "do", "else", "elseif", "end",
				   "false", "for", "function", "if", "in", "local",
				   "nil", "not", "or", "repeat", "return", "then",
				   "true", "until", "while",
				   --LuaEx keywords
				   "const","enum"
			   };
local nKeywords = #tKeyWords;

--credit for this function (https://www.codegrepper.com/code-examples/lua/lua+split+string+into+table)
function string.delmitedtotable(sInput, sDelimiter)
    local tRet = {};
    for sMatch in (sInput..sDelimiter):gmatch("(.-)"..sDelimiter) do
        table.insert(tRet, sMatch);
    end
    return tRet;
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
