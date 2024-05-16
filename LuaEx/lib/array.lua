local math          = math;
local rawtype       = rawtype;
local string        = string;
local type          = type;

--[[
TODO
Clone(): Method that creates a shallow copy of the array.

Array.Copy
ourceArray: The array from which to copy elements.
sourceIndex: The zero-based index in the source array from which copying begins.
destinationArray: The array to which to copy elements.
destinationIndex: The zero-based index in the destination array at which copying begins.
length: The number of elements to copy.
CopyTo(Array array, int index): Method that copies the elements of the array to another array, starting at a specified index.

In C#, Array.Copy and Array.CopyTo are both used to copy elements from one array to another, but they have different usage patterns and behaviors:

    Array.Copy:
        Array.Copy is a static method of the Array class.
        It allows you to copy a range of elements from one array to another.
        You have full control over the starting index in both the source and destination arrays.
        It does not require the destination array to be pre-allocated.
        It can copy elements between arrays of different lengths.
        It does not resize the destination array; it only copies elements up to the specified length or until the end of the source array, whichever comes first.
        It does not return a new array; it modifies the destination array in place.

    Array.CopyTo:
        Array.CopyTo is an instance method of the Array class.
        It copies the entire contents of one array to another array.
        It is used when you want to copy all elements of the source array to the destination array.
        The destination array must be pre-allocated with enough space to accommodate all elements of the source array.
        It does not provide options for specifying starting indices or lengths; it copies all elements from the beginning of the source array.
        It throws an ArgumentException if the destination array is not large enough to hold all elements of the source array.
        It does not return a new array; it modifies the destination array in place.

In summary, Array.Copy offers more flexibility for copying specific ranges of elements between arrays, while Array.CopyTo is simpler to use when you want to copy all elements of one array to another.

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
                    tItems[x]       = null;
                end

            end,
            indexof = function(vItem)
                local nIndex = -1;

                for x = 1, tActual.length do

                    if (tItems[x] == vItem) then
                        nIndex = x;
                        break;
                    end

                end

                return nIndex;
            end,
            lastindexof = function(vItem)
                local nIndex = -1;

                for x = tActual.length, 1, -1 do

                    if (tItems[x] == vItem) then
                        nIndex = x;
                        break;
                    end

                end

                return nIndex;
            end,
            sort = function(bSorter)
                table.sort(tItems, bSorter);
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
                tItems[x]       = null;
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

                tItems[k]   = v;
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
