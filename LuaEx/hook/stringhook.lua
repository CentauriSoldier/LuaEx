local tLuaEX = rawget(_G, "luaex");

local math      = math;
local pairs		= pairs;
local rawtype	= rawtype;
local string 	= string;
local table     = table;

--UUID values
local _tCharsLower	 = {"7","f","1","e","3","c","6","b","5","9","a","4","8","d","0","2"};
local _tCharsUpper	 = {"7","F","1","E","3","C","6","B","5","9","A","4","8","D","0","2"};
local _sUUIDLength 	 = #_tCharsLower;
local _tUUIDSequence = {8, 4, 4, 4, 12};
local _sUUIDBlocks	 = #_tUUIDSequence;


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
    @ret number nItems The total number of items capatalized (or attempted to be capatalized).
    @ret table tItems A numerically-indexed table whose values are the items found.
    @ex
    local sTest = "the way and the word - a tale of a wizard's malice";
    local sNewTest, nItems, tItems = sTest:capall();
    print(sNewTest); --> The Way And The Word - A Tale Of A Wizard's Malice
    print("Item count: "..nItems); --Item count: 12
!]]
function string.capall(sInput, sDelimiter)
    local sRet = "";
    local tItems = nil;
    local nItems = nil;
    sDelimiter = rawtype(sDelimiter) == "string" and sDelimiter or " ";

    if (sInput:gsub("%s", "") ~= "") then
        tItems = string.totable(sInput, sDelimiter);
        nItems = #tItems;

        for nIndex, sWord in pairs(tItems) do
            local sSpace = (nIndex == nItems) and "" or ' ';
            local sFirstLetter = (string.sub(sWord, 1, 1)):upper();
            local sRightSide = string.sub(sWord, 2);
            sRet = sRet..sFirstLetter..sRightSide..sSpace;
        end

    end

    return sRet, nItems, tItems;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isempty
    @desc Determines whether a string is empty (blank or space-only characters).
    @param string sInput The string to capatalize.
    @ret boolean Returns true if empty, false otherwise.
    @ex
    local sTest1 = "     ";
    local sTest2 = " a    ";
    print("sTest1 is empty: "..tostring(sTest1:isempty())); --> sTest1 is empty: true
    print("sTest2 is empty: "..tostring(sTest2:isempty())); --> sTest2 is empty: false
!]]
function string.isempty(sInput)
    return sInput:find("[%S]+") == nil;
end






--TODO clean this up and write docs (also allow the user to tell which OS to check)
--TODO if it's blank
function string.isfilesafe(name)
    -- Define invalid characters for Windows and Linux
    local invalid_chars_windows = '[<>:"/\\|?*%c]'
    local invalid_chars_linux = '[/%c]'

    -- Determine the platform based on the directory separator
    local dir_separator = package.config:sub(1, 1)
    local invalid_chars

    if dir_separator == '\\' then
        -- Windows
        invalid_chars = invalid_chars_windows
    else
        -- Linux/Unix
        invalid_chars = invalid_chars_linux
    end

    -- Check for invalid characters
    if name:match(invalid_chars) then
        return false, "Name contains invalid characters"
    end

    -- Check for reserved filenames on Windows
    if dir_separator == '\\' then
        local reserved_names = {
            "CON", "PRN", "AUX", "NUL",
            "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
            "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
        }

        for _, reserved in ipairs(reserved_names) do
            if name:upper() == reserved then
                return false, "Name is a reserved word on Windows"
            end
        end
    end

    -- Check for names that are too long (Windows limit is 255 characters)
    if #name > 255 then
        return false, "Name is too long"
    end

    -- Check for empty names
    if name == "" then
        return false, "Name is empty"
    end

    -- If all checks pass, the name is safe
    return true, "Name is filesafe"
end







--[[!
    @fqxn LuaEx.Lua Hooks.string.iskeyword
    @desc Determines whether a string is keyword.
    @param string sInput The string to capatalize.
    @ret boolean Returns true if empty, false otherwise.
    @ex
    local sTest1 = "end";
    local sTest2 = "class";
    local sTest3 = "classes";
    print("sTest1 is keyword: "..tostring(sTest1:iskeyword())); --> sTest1 is keyword: true
    print("sTest2 is keyword: "..tostring(sTest2:iskeyword())); --> sTest2 is keyword: true
    print("sTest3 is keyword: "..tostring(sTest3:iskeyword())); --> sTest3 is keyword: false
!]]
function string.iskeyword(sInput)
    local bRet = false;

    for x = 1, tLuaEX.__keywords__count__ do

        if sInput == tLuaEX.__keywords__[x] then
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
    print("sTest1 is numeric: "..tostring(sTest1:isnumeric())); --> sTest1 is numeric: false
    print("sTest2 is numeric: "..tostring(sTest2:isnumeric())); --> sTest2 is numeric: true
!]]
function string.isnumeric(sInput)
    return type(sInput) == "string" and sInput:gsub("[%d%.]", "") == "";
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isuuid
    @desc Determin wether a string is a uuid (as created by <a href="#LuaEx.Lua Hooks.string.uuid">string.uuid</a>).</b>
    @param string sInput The string to check.
    @ret boolean bIsUUID True if it's a UUID, false otherwise.
    @ex
    print("Is UUID: "..tostring(string.isuuid("6430425f-dfe0-d7c8-cf55-dc0f133e07ef"))); --> true
    print("Is UUID: "..tostring(string.isuuid("6430425f-Adfe0-d7c8-cf55-dc0f133e07ef"))); --> false
    print("Is UUID: "..tostring(string.isuuid("z430425f-dfe0-d7c8-cf55-dc0f133e07ef"))); --> false
!]]
function string.isuuid(sInput)
    -- UUID pattern based on _tUUIDSequence
    local sPattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$";
    -- Check if the input matches the pattern
    return sInput:match(sPattern) ~= nil;
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

    print("sTest1 is variable compliant: "..tostring(sTest1:isvariablecompliant())); --> sTest1 is variable compliant: false
    print("sTest2 is variable compliant: "..tostring(sTest2:isvariablecompliant())); --> sTest2 is variable compliant: true
    print("sTest3 is variable compliant: "..tostring(sTest3:isvariablecompliant())); --> sTest3 is variable compliant: false
    print("sTest4 is variable compliant: "..tostring(sTest4:isvariablecompliant())); --> sTest4 is variable compliant: false
    print("sTest4 is variable compliant (skipping keywords): "..sTest4:isvariablecompliant(true)); --> sTest4 is variable compliant (skipping keywords): true
!]]
function string.isvariablecompliant(sInput, bSkipKeywordCheck)
    local bRet = false;
    local bIsKeyWord = false;

    --make certain it's not a keyword
    if (not bSkipKeywordCheck) then
        for x = 1, tLuaEX.__keywords__count__ do

            if sInput == tLuaEX.__keywords__[x] then
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
    @ret string sUUID A Universally Unique Identifier in the following format:
    <br><b>6430425f-dfe0-d7c8-cf55-dc0f133e07ef</b>
    @ex
    print(string.uuid()) --> 6430425f-dfe0-d7c8-cf55-dc0f133e07ef (a string in this format)
!]]
function string.uuid(bUppercase)
    local sRet 			= "";
    local tChars = bUppercase and _tCharsUpper or _tCharsLower;

    for nBlock, nBlockCharCount in pairs(_tUUIDSequence) do
        local sDash = nBlock < _sUUIDBlocks and "-" or "";

        for x = 1, nBlockCharCount do
            sRet = sRet..tChars[math.random(1, _sUUIDLength)];
        end

        sRet = sRet..sDash;
    end

    return sRet
end


return string;
