--[[!
    @fqxn LuaEx.Libraries.constant
    @desc Creates a constant in the LuaEx library. This function validates the constant name and value
          to ensure that the name is a valid Lua variable and that the value is not nil. It checks for
          existing variables to prevent overwriting and enforces compliance with naming rules.
          The binding is protected from ordinary reassignment; table values retain mutable contents.
    @param string sName The name of the constant. Must be a non-blank string that complies with Lua
          variable naming rules.
    @param any vVal The value to assign to the constant. Must not be nil.
    @ex
    -- Define a constant for the maximum number of players
    constant("MAX_PLAYERS", 10)

    -- Use the constant in your code
    print("The maximum number of players allowed is: " .. tostring(MAX_PLAYERS))
    @return None. The constant is added to the LuaEx library.
!]]
--    @error Throws an error if the name is invalid, if the constant already exists, or if the value is nil.
local _tLuaEx = rawget(_G, "luaex");

local assert                = assert;
local rawset                = rawset;
local rawtype               = rawtype;
local tostring              = tostring;

local function isvariablecompliant(sInput, bSkipKeywordCheck)
    local bRet = false;
    local bIsKeyWord = false;

    --make certain it's not a keyword
    if (not bSkipKeywordCheck) then
        for x = 1, _tLuaEx.__keywords__count__ do

            if sInput == _tLuaEx.__keywords__[x] then
                bIsKeyWord = true;
                break;
            end

        end

    end

    if (not bIsKeyWord) then
        bRet = (sInput ~= "")                                  and
               (not sInput:match("^%d"))                        and
               (not sInput:gsub("_", ""):match("[%W]"));
    end

    return bRet;
end

local function constant(sName, vVal)

    --ensure the name input is a string
    assert(rawtype(sName) == "string" and sName:gsub("%s", "") ~= "", "Constant name must be of type string and be non-blank; input value is '"..tostring(sName).."', of type "..type(sName));

    --check that the name string can be a valid variable
    assert(isvariablecompliant(sName), "Constant name must be a string whose text is compliant with lua variable rules; input string is '"..sName.."'");

    --make sure the variable doesn't already exist
    assert(rawtype(_G[sName]) == "nil" and rawtype(_tLuaEx[sName]) == "nil", "Variable "..sName.." has already been assigned a non-nil value. Cannot overwrite existing item.");

    --make sure the constant is not nil
    assert(rawtype(vVal) ~= "nil", "Cannot create constant; value cannot be nil.");

    --put the const into the global environment (via the luaex protected table)
    rawset(_tLuaEx, sName, vVal);
end

return constant;
