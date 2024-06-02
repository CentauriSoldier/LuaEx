local assert = assert; ---TODO localize all called functions

--										🆃🆈🅿🅴 🅼🅴🆃🅰🆃🅰🅱🅻🅴🆂

--<<  🅱🅾🅾🅻🅴🅰🅽  >>
-- Retrieve the existing metatable for booleans, or create a new one if it doesn't exist
local tBooleanMeta = getmetatable(true) or {}

-- Define custom metamethods for boolean operations
local tNewBooleanMetamethods = {
    -- Logical OR (already defined)
    __add = function(bLeft, bRight)
        return bLeft or bRight;
    end,

    -- Concatenation to string
    __concat = function(vLeft, vRight)
        if type(vLeft) == "boolean" then
            return tostring(vLeft) .. vRight;
        else
            return vLeft .. tostring(vRight);
        end
    end,

    -- Length operation
    __len = function(bVal)
        return bVal and 1 or 0;
    end,

    -- Logical AND (already defined)
    __mul = function(bLeft, bRight)
        return bLeft and bRight;
    end,

    -- Convert boolean to string
    __tostring = function(bVal)
        return bVal and "true" or "false";
    end,

    -- Negation
    __unm = function(bVal)
        return not bVal;
    end,

    -- Logical XOR
    __bxor = function(bLeft, bRight)
        return (bLeft and not bRight) or (not bLeft and bRight);
    end,

    -- Logical NAND
    __band = function(bLeft, bRight)
        return not (bLeft and bRight);
    end,

    -- Logical NOR
    __bor = function(bLeft, bRight)
        return not (bLeft or bRight);
    end,

    -- Logical XNOR (equivalence)
    __eq = function(bLeft, bRight);
        return bLeft == bRight
    end,

    -- Implication (if bLeft then bRight)
    __imp = function(bLeft, bRight)
        return (not bLeft) or bRight;
    end
}

-- Assign the custom metamethods to the boolean metatable
for k, v in pairs(tNewBooleanMetamethods) do
    tBooleanMeta[k] = v;
end

-- Set the updated metatable for booleans
debug.setmetatable(true, tBooleanMeta)


--[[local tBooleanMeta = getmetatable(true) or true;

debug.setmetatable(tBooleanMeta, {
    __add = function(bLeft, bRight)
        return bLeft or bRight;
    end,
    __concat = function(vLeft, vRight)

        if (type(vLeft) == "boolean") then
            return tostring(vLeft)..vRight;
        else
            return vLeft..tostring(vRight);
        end

    end,
    __len = function(bVal)
        return bVal and 1 or 0;
    end,
    __mul = function(bLeft, bRight)
        return bLeft and bRight;
    end,
    __tostring = function(bVal)
        return (bVal and "true" or "false");
    end,
    __unm = function(bVal)
        return not bVal;
    end,
});
]]




--[[Example usage of the enhanced boolean operations

]]

--<<  🅽🆄🅼🅱🅴🆁  >>
local tNumberMeta = getmetatable(0) or 0;
local sBlank = "";

debug.setmetatable(tNumberMeta, {
    __len = function(nVal)
        local bRet = nil;

        if (nVal == 0) then
            bRet = false;
        elseif (nVal == 1) then
            bRet = true;
        end

        return bRet;
    end,
    __tostring = function(nVal)
        return sBlank..(nVal)..sBlank;
    end,
    __round = function(t)
        print(t)
    end
});


--<< 🆂🆃🆁🅸🅽🅶 >>
--TODO CAN THIS BE OPTIIMIZE BY MAKING THE RETURNED FUNCTION LOCAL?
--http://lua-users.org/wiki/StringInterpolation
local tStringMeta = getmetatable("");
tStringMeta.__mod = function(s, tab) return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end)) end;


--										🆃🆈🅿🅴
local tLuaTypes = {
    ["boolean"]		= true,
    ["function"]	= true,
    ["nil"] 		= true,
    ["number"] 		= true,
    ["string"] 		= true,
    ["table"] 		= true,
    ["thread"] 		= true,
    ["userdata"] 	= true,
};

--'immutable' table of stock LuaEx types
local tLuaExTypes = {
    array                   = true,
    arrayfactory            = true,
    class                   = true,
    classfactory            = true,
    clausum                 = true,
    constant                = true,
    enum 				    = true,
    enumfactory 			= true,
    interface               = true,
    null 				    = true,
    struct				    = true,
    structfactory           = true,
    structfactorybuilder    = true,
    trait                   = true,--TODO MAKE THIS INTERFACE FOR STRUCTS WHEN THEY'RE READY TO USE THEM
};
--TODO add class and truct types here somwhere (when instances are created)
--user can add/remove the items in this table
local tUserTypes = {};

--store the original type funcion
local __type__ = type;
type = nil;

local type = {
    assert = {
        custom = function(vInput, sType)--TODO custom message
            assert(type(vInput) == sType, "Error in parameter input.\nExpected type is ${expected}. Type given: ${given}." % {expected = sType, given = type(vInput)});
        end,
        number = function (vInput, bErrorNegative, bErrorZero, bErrorPositive, bErrorFloat, bErrorInteger, nMin, nMax)
            local sType  = rawtype(vInput);
            local sError = "Error in parameter input.";
            local bError = false;

            if (sType == "number") then

                --check number line position
                if (bErrorNegative and vInput < 0) then
                    sError = sError.."\nNumber must be positive.";
                    bError = true;
                elseif (bErrorPositive and vInput > 0) then
                    sError = sError.."\nNumber must be negative.";
                    bError = true;
                elseif (bErrorZero and vInput == 0) then
                    sError = sError.."\nNumber must not be zero.";
                    bError = true;
                end

                --check integer value
                local bIsInteger = vInput == math.floor(vInput);

                if (bErrorInteger and bIsInteger) then
                    sError = sError.."\nNumber must be a non-integer.";
                    bError = true;
                elseif (bErrorFloat and not bIsInteger) then
                    sError = sError.."\nNumber must be an integer.";
                    bError = true;
                end

                --check range
                if (nMin and vInput < nMin) then
                    sError = sError.."\nNumber must greater than or equal to "..nMin..".";
                    bError = true;
                end

                if (nMax and vInput > nMax) then
                    sError = sError.."\nNumber must less than or equal to "..nMax..".";
                    bError = true;
                end

            else
                error("Expected type is number. Type given: ${given}." % {given = sType});
            end


            if (bError) then
                error(sError.."\nValue given: "..vInput);
            end

        end,
        string = function(vInput, sPattern, sMessage)--TODO finish adding optional message and create other functions
            local bConditionMet = false;
            local sType = type(vInput);
            local bGoodType = sType == "string";
            local sError = "Error in parameter input.";

            if bGoodType then

                if sPattern then

                    if vInput:match(sPattern) then
                        bConditionMet = true;
                    else
                        sError = sError.."\nString does not match the required pattern (\""..sPattern.."\").";
                    end
                else
                    bConditionMet = true; -- If no pattern is provided, any string is considered valid.
                end
            else
                sError = sError.."\nExpected type is string. Type given: "..sType..'.';
            end

            assert(bConditionMet, sError..(rawtype(sMessage) == "string" and "\n"..sMessage or ""));
        end,
        table = function(vInput, vIndexType, vValueType, vMinItems, nMaxItems)
            local bConditionMet = rawtype(vInput) == "table";
            local sError        = "Error in parameter input.";
            local sIndexType    = rawtype(vIndexType)   == "string"   and vIndexType or false;
            local sValueType    = rawtype(vValueType)   == "string"   and vValueType or false;
            local nMinItems     = rawtype(vMinItems)    == "number"   and vMinItems  or false;
            local nMaxItems     = rawtype(vMinItems)    == "number"   and vMinItems  or false;
            local nItems        = 0;

            if (bConditionMet) then

                for k, v in pairs(vInput) do
                    nItems = nItems + 1;

                    --check the index type
                    if (sIndexType and rawtype(k) ~= sIndexType) then
                        sError = sError.."\nIndices must be of type "..sIndexType..". Type given: "..rawtype(k)..".";
                        bConditionMet = false;
                    end

                    --check the value type
                    if (sValueType and rawtype(v) ~= sValueType) then
                        sError = sError.."\nValues must be of type "..sIndexType..". Type given: "..rawtype(v)..".";
                        bConditionMet = false;
                    end

                end

                local sItems = nItems < 2 and "item" or "items";

                --min items
                if (nMinItems and nItems < nMinItems) then
                    sError = sError.."\nTable must contain no fewer than "..nMinItems.." "..sItems..". Item count: "..nItems..'.';
                    bConditionMet = false;
                end

                --max items
                if (nMaxItems and nItems > nMaxItems) then
                    sError = sError.."\nTable must contain no more than "..nMinItems.." "..sItems..". Item count: "..nItems..'.';
                    bConditionMet = false;
                end

            else
                sError = sError.."\nInput must be of type table. Type given: "..rawtype(vInput)..'.';
            end

            assert(bConditionMet, sError..(rawtype(sMessage) == "string" and "\n"..sMessage or ""));
        end,
    },
    mathchesonlyleft = function(sLeftType, sRightType, sTypeInQuestion)--TODO check these...do they work and for what?
        return (sLeftType == sObjType and sRightType ~= sTypeInQuestion);
    end,
    mathchesonlyright = function(sLeftType, sRightType, sTypeInQuestion)
        return (sLeftType ~= sObjType and sRightType == sTypeInQuestion);
    end,
    mathchesboth = function(sLeftType, sRightType, sTypeInQuestion)
        return (sLeftType == sObjType and sRightType == sTypeInQuestion);
    end,
    ex = function(vObject)
        local sType = __type__(vObject);

        if (sType == "table") then
            local tMeta = getmetatable(vObject);

            if (__type__(tMeta) == "table") then

                if (__type__(tMeta.__type) == "string") then

                    if (tLuaExTypes[tMeta.__type] 		or 									--luaex type
                        tMeta.__type:find("struct ") 	or tMeta.__type:find(" struct") or 	--custom struct
                        tMeta.__is_luaex_class			or 									--custom class
                        vObject["enum"]) then --custom enum
                        sType = tMeta.__type;
                    end

                end

            end

        end

        return sType;
    end,
    full = function(vObject)
        local sType = __type__(vObject);
        local sSpace = "";

        if (sType == "table") then
            local tMeta = getmetatable(vObject);

            if (__type__(tMeta) == "table") then

                if (__type__(tMeta.__type) == "string") then
                    sType = tMeta.__type;
                    sSpace = " ";
                end

                if (__type__(tMeta.__subtype) == "string") then
                    sType = (sType ~= "table" and sType or "")..sSpace..tMeta.__subtype;
                end

            end

        end

        return sType;
    end,
    getall = function()
        local tRet 	= {};

        for sType, _ in pairs(tLuaTypes) do
            tRet[#tRet + 1] = sType;
        end

        for sType, _ in pairs(tLuaExTypes) do
            tRet[#tRet + 1] = sType;
        end

        for sType, _ in pairs(tUserTypes) do
            tRet[#tRet + 1] = sType;
        end

        table.sort(tRet);
        return tRet;
    end,
    getlua = function()
        local tRet 	= {};

        for sType, _ in pairs(tLuaTypes) do
            tRet[#tRet + 1] = sType;
        end

        table.sort(tRet);
        return tRet;
    end,
    getluaex = function()
        local tRet 	= {};

        for sType, _ in pairs(tLuaExTypes) do
            tRet[#tRet + 1] = sType;
        end

        table.sort(tRet);
        return tRet;
    end,
    getuser = function()
        local tRet 	= {};

        for sType, _ in pairs(tUserTypes) do
            tRet[#tRet + 1] = sType;
        end

        table.sort(tRet);
        return tRet;
    end,
    raw = __type__,
    set = function(tInput, sType)--TODO check that this is not a luex class

        if (rawtype(tInput) == "table" and type(sType) == "string")then
            --look for an existing meta table and get its type
            local tMeta 	= getmetatable(tInput);
            local sMetaType = rawtype(tMeta);
            local bIsTable 	= sMetaType == "table";

            if (bIsTable or sMetaType == "nil") then
                tMeta = bIsTable and tMeta or {};
                tMeta.__type = sType;
                setmetatable(tInput, tMeta);
                --record the new type
                type[sType] = true;--TODO create is function
                return tInput;
            end

            return tInput;
        end

    end,
    setsub = function(tInput, sType)

        if (rawtype(tInput) == "table" and type(sSubType) == "string")then --TODO check that this is not a luex class
            --look for an existing meta table and get its type
            local tMeta 	= getmetatable(tInput);
            local sMetaType = rawtype(tMeta);
            local bIsTable = sMetaType == "table";

            if (bIsTable or sMetaType == "nil") then
                tMeta = bIsTable and tMeta or {};
                tMeta.__subtype = sSubType;
                setmetatable(tInput, tMeta);--TODO is function
                return tInput;
            end

            return tInput;
        end

    end,
    sub = function(vObject)
        local sType = "nil";

        if (__type__(vObject) == "table") then
            local tMeta = getmetatable(vObject);

            if (__type__(tMeta) == "table" and __type__(tMeta.__subtype) == "string") then
                sType = tMeta.__subtype;
            end

        end

        return sType;
    end,
};

local function newindex(t, k, v)

    if (__type__(k) == "string") then

        --add the new type
        if (v) then
            tUserTypes[k] = true;

            rawset(type, "is"..k, function(vVal)
                return type(vVal) == k;
            end);

        --remove the type
        else

            if (tUserTypes[k]) then
                tUserTypes[k] = nil;
                rawset(type, "is"..k, nil);
            end

        end

    end

end

--aliases for ease-of use TODO these should be removed and localized as needed
rawtype 	= type.raw;
xtype 		= type.ex;
fulltype	= type.full;
subtype 	= type.sub;
settype		= type.set;
setsubtype	= type.setsub;

--setup the 'is' functions for all types
for sType, _ in pairs(tLuaTypes) do
    rawset(type, "is"..sType, function(vVal)
        return __type__(vVal) == sType;
    end);
end

for sType, _ in pairs(tLuaExTypes) do
    rawset(type, "is"..sType, function(vVal)
        return type(vVal) == sType;
    end);
end

--TODO consider removing this...is there really a need for it and would it follow POLA?
for sType, _ in pairs(tUserTypes) do
    rawset(type, "is"..sType, function(vVal)
        return type(vVal) == sType;
    end);
end

--rework the type system
setmetatable(type,
{
    __call = function(t, vObject)
        local sType = __type__(vObject);

        local tMeta = getmetatable(vObject);

        if (__type__(tMeta) == "table" and __type__(tMeta.__type) == "string") then
            sType = tMeta.__type;
        end

        return sType;
    end,
    __type = "function",
    --[[__index = function()
        error("Attempt to index a function value.", 2);
    end,]]
    __newindex = newindex,
});

return type;
