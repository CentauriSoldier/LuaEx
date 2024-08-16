local tLuaEX = rawget(_G, "luaex");

local math      = math;
local pairs		= pairs;
local rawtype	= rawtype;
local string 	= string;
local table     = table;

local _sUUIDLength 	= 16;
local _sUUIDBlocks	= 5;


--[[!
    @fqxn LuaEx.Lua Hooks.string.cap
    @desc Capatalizes the first letter of the input. If the second argument is true, it also lowers all letters after the first (string).
    @param string sInput The string to capatalize.
    @param boolean|nil bLowerRemaining Whether to forcibly lower everything after the first letter (false by default, left as-is).
    @ret string sModifiedInput Returns the modified input string.
    @ex
    local sTest1 = "washinGton";
    local sTest2 = "waShingToN";
    print("sTest1: "..sTest1:cap());     --> sTest1: WashinGton
    print("sTest2: "..sTest2:cap(true)); --> sTest2: Washington
!]]
function string.cap(sInput, bLowerRemaining)
    local sRet = "";

    if sInput:len(sInput) > 1 then
        local sFirstLetter = sInput:sub(1, 1);
        local sRightSide = sInput:sub(2, sInput:len()); --DO i need the 2nd arg?
        sRet = sFirstLetter:upper();

            if bLowerRemaining then
                sRet = sRet..sRightSide:lower();
            else
                sRet = sRet..sRightSide;
            end

    else
        sRet = sInput:upper();
    end

    return sRet
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.capall
    @desc Capatalizes the first letter of each word in a sentence.
    @param string sInput The string to capatalize.
    @param string|nil sDelimiter The delmiter between words (a blank space by default).
    @ret string sModifiedInput Returns the modified input string.
    @ret number nWords The total number of words capatalized.
    @ret table sadasd s
    @ex
    TODO FINISH
!]]
function string.capall(sInput, sDelimiter)
    local sRet = "";
    local tWords = nil;
    local nWords = nil;
    local totable = string.totable;
    sDelimiter = rawtype(sDelimiter) == "string" and sDelimiter or " ";

    if (sInput:gsub("%s", "") ~= "") then
        tWords = totable(sInput, sDelimiter);--TODO could this use %s to find any space character?
        nWords = #tWords;

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

    return sRet, nWords, tWords;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isempty
    @desc Determines whether a string is empty (blank or space-only characters).
    @param string sInput The string to capatalize.
    @ret boolean Returns true if empty, false otherwise.
    @ex
    local sTest1 = "     ";
    local sTest2 = " a    ";
    print("sTest1 is blank: "..sTest1:isempty()); --> sTest1 is blank: true
    print("sTest2 is blank: "..sTest2:isempty()); --> sTest2 is blank: false
!]]
function string.isempty(sInput)
    return sInput:find("[%S]+") == nil;
end


--[[!TODO FINISH
    @fqxn LuaEx.Lua Hooks.string.iskeyword
    @desc Determines whether a string is keyword.
    @param string sInput The string to capatalize.
    @ret boolean Returns true if empty, false otherwise.
    @ex
    local sTest1 = "     ";
    local sTest2 = " a    ";
    print("sTest1 is keyword: "..sTest1:isempty()); --> sTest1 is blank: true
    print("sTest2 is keyword: "..sTest2:isempty()); --> sTest2 is blank: false
!]]
function string.iskeyword(sInput)
    local bRet = false;

    for x = 1, tLuaEX.__KEYWORDS_COUNT__ do

        if sInput == tLuaEX.__KEYWORDS__[x] then
            bRet = true;
            break;
        end

    end

    return bRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isnumeric
    @desc Determines whether a string is a numeric string.
    @param string sInput The string to check.
    @ex
    local sTest1 = "1a2sASd";
    local sTest2 = "234.67";
    print("sTest1 is numeric: "..sTest1:isnumeric()); --> sTest1 is numeric: false
    print("sTest2 is numeric: "..sTest2:isnumeric()); --> sTest2 is numeric: true
!]]
function string.isnumeric(sInput)
    return type(sInput) == "string" and sInput:gsub("[%d%.]", "") == "";
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isvariablecompliant
    @desc Determines whether a string is a valid, variable-compliant string.
    @param string sInput The string to check.
    @param boolean|nil bSkipKeywordCheck Whether to skip LuaEx keyword checks.
    @ret boolean bIsVariableCompliant True if the string is variable-compliant, false otherwise.
    @ex
    local sTest1 = "1MyVar";
    local sTest2 = "_MyVar";
    local sTest3 = "end";
    local sTest4 = "enum";

    print("sTest1 is variable compliant: "..sTest1:isvariablecompliant()); --> sTest1 is variable compliant: false
    print("sTest2 is variable compliant: "..sTest2:isvariablecompliant()); --> sTest2 is variable compliant: true
    print("sTest3 is variable compliant: "..sTest3:isvariablecompliant()); --> sTest3 is variable compliant: false
    print("sTest4 is variable compliant: "..sTest4:isvariablecompliant()); --> sTest4 is variable compliant: false
    print("sTest4 is variable compliant (skipping keywords): "..sTest4:isvariablecompliant(true)); --> sTest4 is variable compliant (skipping keywords): true
!]]
function string.isvariablecompliant(sInput, bSkipKeywordCheck)
    local bRet = false;
    local bIsKeyWord = false;

    --make certain it's not a keyword
    if (not bSkipKeywordCheck) then
        for x = 1, tLuaEX.__KEYWORDS_COUNT__ do

            if sInput == tLuaEX.__KEYWORDS__[x] then
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


--[[!
    @fqxn LuaEx.Lua Hooks.string.totable
    @desc Creates a table based on a demilited string.
    @param string sInput The string from which to create a table.
    @param string|nil sDelimiter The delimter.
    @param bAllowBlank boolean|nil Whether blank items should be included (if true) or skipped (if false or nil)
    @ret table The delimted, numerically-indexed table.
    @ex
    local sTest = "one,two,three,,four";

    for k, v in pairs(sTest:totable(',', true)) do
        print(k, v);
    end

    --\[\[
    1	one
    2	two
    3	three
    4
    5	four
    \]\]
!]]
function string.totable(sInput, sDelimiter, bAllowBlank)
    local tRet = {}
    local pattern = "([^"..(sDelimiter or "]+").."]+)"
    if bAllowBlank then
        pattern = "([^"..(sDelimiter or "]+").."]*)"
    end

    for w in sInput:gmatch(pattern) do
        table.insert(tRet, w);
    end

    return tRet
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.trim
    @desc Trims blank space from the beginning and end of a string.
    @param string sInput The string to trim.
    @ret string The trimmed string.
    @ex
    local sTest = "     |Inner String|      ";
    print(sTest:trim()); -->|Inner String|
    @www Code by <a href="https://snippets.bentasker.co.uk">https://snippets.bentasker.co.uk</a>
!]]
function string.trim(sInput)
  return sInput:match'^()%s*$' and '' or sInput:match'^%s*(.*%S)';
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.trimleft
    @desc Trims blank space from the beginning of a string.
    @param string sInput The string to trim.
    @ret string The trimmed string.
    @ex
    local sTest = "     |Inner String|      ";
    print(sTest:trimleft()); -->|Inner String|      <--string ends here
    @www Code by <a href="https://snippets.bentasker.co.uk">https://snippets.bentasker.co.uk</a>
!]]
function string.trimleft(sInput)
  return sInput:match'^%s*(.*)';
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.trimright
    @desc Trims blank space from the beginning of a string.
    @param string sInput The string to trim.
    @ret string The trimmed string.
    @ex
    local sTest = "     |Inner String|      ";
    print(sTest:trimright()); -->     |Inner String|
    @www Code by <a href="https://snippets.bentasker.co.uk">https://snippets.bentasker.co.uk</a>
!]]
function string.trimright(sInput)
  return sInput:match'^(.*%S)%s*$';
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.uuid
    @desc Creates a Universally Unique Identifier in the following format:
    <br><b>6430425f-dfe0-d7c8-cf55-dc0f133e07ef</b>
    @param boolean|nil bUppercase Whether to make the string uppcase (lowercase by default).
    @ret string sUUID A Universally Unique Identifier in the following format:
    <br><b>6430425f-dfe0-d7c8-cf55-dc0f133e07ef</b>
    @ex
    print(string.uuid()) --> 6430425f-dfe0-d7c8-cf55-dc0f133e07ef (a string in this format)
!]]
local tUUIDSequence = {8, 4, 4, 4, 12};
function string.uuid(bUppercase)
    local sRet 			= "";
    local tCharsLower	= {"7","f","1","e","3","c","6","b","5","9","a","4","8","d","0","2"};--must be equal to _sUUIDLength
    local tCharsUpper	= {"7","F","1","E","3","C","6","B","5","9","A","4","8","D","0","2"};
    local tChars = bUppercase and tCharsUpper or tCharsLower;

    for nBlock, nBlockCharCount in pairs(tUUIDSequence) do
        local sDash = nBlock < _sUUIDBlocks and "-" or "";

        for x = 1, nBlockCharCount do
            sRet = sRet..tChars[math.random(1, _sUUIDLength)];
        end

        sRet = sRet..sDash;
    end

    return sRet
end


return string;
