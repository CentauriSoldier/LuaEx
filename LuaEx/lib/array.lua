local math          = math;
local rawtype       = rawtype;
local string        = string;
local type          = type;

--[[
TODO
Array.Sort
Array.Resize
Array.Copy
Array.IndexOf
LastIndexOf

Clone(): Method that creates a shallow copy of the array.

CopyTo(Array array, int index): Method that copies the elements of the array to another array, starting at a specified index.
]]

local tArrayActual = {}; --array factory actual table

return setmetatable(tArrayActual,
{
    __call = function(__IGNORE__, vInput)--create the array object
        local tItems        = {};   --the actual array data
        local sArrayType    = null; --the type the array stores
        local tActual;              --this is where the array methods and properties live
        tActual             = {
            length = 0,             --the length of the array
            clear = function()

                for x = 1, tActual.length do
                    tItems[x] = null;
                end

            end,
        };

        --validate and process the input the input
        local sInputType = type(vInput);

        --process number input
        if (sInputType == "number") then

            if (math.floor(vInput) ~= vInput or vInput < 1) then --don't alow zero or non-integer input
                error("Error creating array. Input number must be a whole positive, integer.");
            end

            tActual.length = vInput;

            for x = 1, vInput do
                tItems[x] = null;
            end

        --process table input
        elseif (sInputType == "table") then
            local nArrayIndex   = 0; --accounts for malformed input table

            --don't alow zero input
            if (#vInput < 1) then
                error("Error creating array. No valid item entries in input table.");
            end

            --process the input table items
            for nIndex, vItem in ipairs(vInput) do
                local sItemType = type(vItem);
                nArrayIndex = nArrayIndex + 1;

                --log the item type if it's the first
                if (nIndex == 1) then

                    --throw an error on null value
                    if (vItem == null) then
                        error("Error creating array. Array item type cannot be null.");
                    end

                    sArrayType = sItemType;
                end

                --enforce 'like items only' policy
                if (sItemType ~= sArrayType) then
                    error("Error creating array.\nArray items must all be of the same type (${type}). Type input is ${typeinput}." % {type = sArrayType, typeinput = sItemType});
                end

                tItems[nArrayIndex] = vItem;
            end

            tActual.length = nArrayIndex;


        else --bad input
            error("Error creating array. Input must be a number or a numerically-indexed table containing like items.");
        end

        local tArrayMeta = { --the returned object's metatable
            __call = function(t)
                local x     = 0;
                local nMax  = tActual.length;

                return function()
                    x = x + 1;

                    if (x <= nMax) then
                        return x, tItems[x];
                    end

                end

            end,
            __index = function(t, k)
                local vRet = nil;

                --process number and string access attempts
                local sType = type(k);
                if (sType == "number") then

                    if not (k > 0 and k <= tActual.length) then
                        error("Error retrieving value from array. Index is out of bounds.\nMax value: ${maxval}. Value given: ${givenval}" % {maxval = tActual.length, givenval = k});
                    end

                    vRet = rawget(tItems, k) or nil;

                elseif (sType == "string") then
                    vRet = tActual[k] or error("Error accessing array method or property, '${method}'. No such method or property exists." % {method = k});

                else --TODO error here

                end

                return vRet;
            end,
            __newindex = function(t, k, v)
                local sType = type(v);

                if (sType == "nil") then
                    error("Error assigning value to array. Item cannot be nil.");
                end

                if (sType == "null") then
                    error("Error assigning value to array. Item cannot be null.");
                end

                if (type(k) ~= "number") then
                    error("Error assigning value to array. Index must be a positve, whole integer.\nInput is '${input}' of type ${type}." % {input = tostring(k), type = type(k)});
                end

                if (math.floor(k) ~= k) then
                    error("Error assigning value to array. Index must be a positve, whole integer.\nInput is '${input}' of type ${type}." % {input = tostring(k), type = type(k)});
                end

                if not (k > 0 and k <= tActual.length) then
                    error("Error assigning value to array. Index is out of bounds.\nMax value: ${maxval}. Value given: ${givenval}" % {maxval = tActual.length, givenval = k});
                end

                if (sArrayType == null) then
                    sArrayType = sType;
                end

                if (sType ~= sArrayType) then
                    error("Error assigning value to array. Item must be of type ${expectedtype}.\nInput is '${input}' of type ${type}." % {expectedtype = tostring(sArrayType), input = tostring(v), type = type(v)});
                end

                tItems[k] = v;
            end,
            __tostring = function()
                local sRet = "";

                for nIndex, vItem in ipairs(tItems) do
                    sRet = sRet..", "..tostring(vItem);
                end

                return '{'..sRet:sub(3)..'}';
            end,
            __type = "array",

        };

        return setmetatable({}, tArrayMeta);
    end,

    __index = function(t, k)
        return rawget(tArray, k) or nil;
    end,

    --deadcall function to prevent modifying the array factory
    __newindex = function(t, k, v)

    end,

    __tostring = function()
        return "arrayfactory"
    end,

    __type      = "arrayfactory",
});














--[[

-- Array class definition
return class("array",
    { -- Metamethods

    },
    { -- Static public

    },
    { -- Private
        data    = {},
        length  = 0,  -- Represents the current number of elements in the array
        type    = null;
    },
    { -- Protected

    },
    { -- Public
        -- Constructor
        array = function(this, cdat, sType)
            --TODO allow for table input
            --TODO check that this type is valid
            assert(type(type) == "string", "Array type must be a string");
            cdat.pri.type = sType;
        end,

        -- Add item to the array
        --WARNING this should not allow changing the array size; it's possible this method should not exist
        add = function(this, cdat, vItem)
            local bRet = false;

            if (rawtype(vItem) ~= "nil") then
                -- Check if the item type matches the array type
                if rawtype(vItem) == cdat.pri.type then
                    table.insert(cdat.pri.data, vItem);
                    cdat.pri.length = cdat.pri.length + 1;
                    bRet = true;
                else
                    error("Attempt to add item of incorrect type to array");
                end
            end

            return bRet;
        end,

        -- Get item from the array by index
        get = function(this, cdat, nIndex)
            assert(type(nIndex) == "number" and nIndex >= 1 and nIndex <= cdat.pri.length,
                "Error in class, array. Invalid index or index out of bounds.");
            return cdat.pri.data[nIndex];
        end,

        -- Set item in the array by index
        set = function(this, cdat, nIndex, vItem)
            assert(type(nIndex) == "number" and nIndex >= 1 and nIndex <= cdat.pri.length,
                "Error in class, array. Invalid index or index out of bounds.");
            -- Check if the item type matches the array type
            if rawtype(vItem) == cdat.pub.type then
                cdat.pri.data[nIndex] = vItem;
            else
                error("Attempt to set item of incorrect type in array");
            end
        end,

        -- Get the current length of the array
        length = function(this, cdat)
            return cdat.pri.length;
        end,
    },
    nil,    -- Extending class
    nil,    -- Interface(s)
    false   -- If the class is final
);
]]
