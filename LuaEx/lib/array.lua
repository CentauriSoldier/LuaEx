local math          = math;
local rawtype       = rawtype;
local string        = string;
local type          = type;
local _tStates      = setmetatable({}, {__mode = "k"});

--[[!
    @fqxn LuaEx.Libraries.array
    @desc A fixed-length, one-based container whose occupied slots share one LuaEx type. Construct from a finite nonnegative integer length or a dense list; zero length and empty lists are valid. Slots may contain null, which means unoccupied. The first non-null value establishes the type, and clear() retains that type. Assigning nil, a different type, or an invalid index raises an error. Numeric reads require an integer within bounds. Both length and # report the fixed capacity. Iterate with array() or pairs(array).
    @ex local aValues = array({3, null, 1});
        aValues.sort(); -- {1, 3, null}
        print(#aValues, aValues.length);
!]]

local function validateLength(nLength)
    type.assert.number(nLength);
    assert(nLength >= 0 and nLength < math.huge and nLength % 1 == 0,
           "Array length must be a finite nonnegative integer.");
end

--[[
Future range-copy API notes (not implemented):

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
-- Item types are established by the first occupied slot.
local tArrayActual = {
    --[[!
        @fqxn LuaEx.Libraries.array.Functions.deserialize
        @desc Restores a validated array state containing length, type, and a dense items list. Null slots and the established type are retained, even when every slot is empty. Normally invoked through the global deserialize function.
        @param table tData The serialized array state.
        @ret array aRet The restored independent array container.
    !]]
    deserialize = function(tData)
        type.assert.table(tData);
        validateLength(tData.length);
        type.assert.table(tData.items);
        assert(tData.type == null or type(tData.type) == "string",
               "Array state must contain its item type or null.");

        local aRet = array(tData.length);
        local tState = _tStates[aRet];

        for k in pairs(tData.items) do
            assert(type(k) == "number" and k % 1 == 0 and k >= 1 and k <= tData.length,
                   "Array state contains an invalid item index.");
        end

        for x = 1, tData.length do
            local vItem = tData.items[x];
            assert(vItem ~= nil, "Array state is missing an item.");
            assert(vItem == null or type(vItem) == tData.type,
                   "Array state item does not match its stored type.");
            tState.items[x] = vItem;
        end

        tState.settype(tData.type);
        return aRet;
    end,
}; --array factory actual table

local ArrayFactoryDecoy = setmetatable({},
{
    --[[
    @module array
    @func array
    @scope public
    @desc Creates an array object.
    @param vInput The input for creating the array, either a number or a numerically-indexed table of like items.
    @ret array The created array object.
    ]]
    __call = function(__IGNORE__, vInput)--create the array object
        local tItems        = {};   --the actual array data
        local sArrayType    = null; --the type the array stores
        local tActual;              --this is where the array methods and properties live
        local tArrayDecoy   = {};   --the returned array object
        local bSorting     = false;
        tActual             = {
            length = 0,             --the length of the array
            --[[!
                @fqxn LuaEx.Libraries.array.Methods.clear
                @desc Clears every slot to null without changing capacity or the established item type.
            !]]
            clear = function()
                assert(not bSorting, "Cannot modify an array from its sort comparator.");

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
            --[[!
                @fqxn LuaEx.Libraries.array.Methods.sort
                @desc Sorts occupied values using Lua's normal ordering or a supplied comparator and moves null slots to the end. Commits only after success; comparator errors leave slot order unchanged. Comparators cannot assign, clear, or recursively sort this array. Sorting is not stable. Mutations inside contained objects are outside the slot transaction.
                @param function|nil fSorter Optional comparator returning whether its first value comes before its second.
            !]]
            sort = function(fSorter)
                assert(not bSorting, "Cannot recursively sort an array from its comparator.");
                assert(fSorter == nil or type(fSorter) == "function", "Array sorter must be a function or nil.");
                local tSorted = {};

                -- Sort occupied slots on a copy. Empty slots follow the sorted
                -- values, and comparator failures leave the original untouched.
                for x = 1, tActual.length do
                    if (tItems[x] ~= null) then
                        tSorted[#tSorted + 1] = tItems[x];
                    end
                end

                bSorting = true;
                local bSuccess, vError = pcall(table.sort, tSorted, fSorter);
                bSorting = false;

                if (not bSuccess) then
                    error(vError, 0);
                end

                for x = 1, tActual.length do
                    local vItem = tSorted[x];
                    tItems[x] = vItem == nil and null or vItem;
                end
            end,
        };

        -- Validate the complete list, including keys outside its dense portion.
        local sInputType = type(vInput);

        --process number input
        if (sInputType == "number") then

            validateLength(vInput);

            tActual.length = vInput;

            for x = 1, vInput do
                tItems[x]       = null;
            end

        --process table input
        elseif (sInputType == "table") then
            local nArrayIndex = 0;

            for k in pairs(vInput) do
                assert(type(k) == "number" and k >= 1 and k < math.huge and k % 1 == 0,
                       "Array input must have contiguous positive integer indices.");
                nArrayIndex = nArrayIndex + 1;
            end

            --process the input table items
            for nIndex = 1, nArrayIndex do
                local vItem = vInput[nIndex];
                assert(vItem ~= nil, "Array input must not contain holes.");
                local sItemType = type(vItem);

                --log the item type if it's the first
                if (sArrayType == null and vItem ~= null) then
                    sArrayType = sItemType;
                end

                --enforce 'like items only' policy
                if (vItem ~= null and sItemType ~= sArrayType) then
                    error("Error creating array.\nArray items must all be of the same type (${type}). Type input is ${typeinput}." % {type = sArrayType, typeinput = sItemType}, 2);
                end

                tItems[nIndex] = vItem;
            end

            tActual.length = nArrayIndex;


        else --bad input
            error("Error creating array. Input must be a number or a numerically-indexed table containing like items.", 2);
        end

        local tArrayMeta = { --the returned object's metatable
            --[[
            @module array
            @func __call
            @scope public
            @desc Creates an iterator function to iterate over the elements of the array.
            @param array The array object.
            @ret function An iterator function that returns each index and element of the array respectively.
            ]]
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
            -- Cloning delegates occupied values to LuaEx clone, retains nulls,
            -- and reconnects direct self references to the new array.
            __clone = function(aInput)
                local aRet = array(tActual.length);
                -- Register before descending so indirect array cycles reconnect too.
                cloner.registerCopy(aInput, aRet);
                local tState = _tStates[aRet];
                tState.settype(sArrayType);

                for k, v in ipairs(tItems) do

                    if (v == null) then
                        tState.items[k] = null;
                    elseif (v ~= tArrayDecoy) then
                        tState.items[k] = clone(v);
                    else
                        tState.items[k] = aRet;
                    end

                end

                return aRet;
            end,
            --[[
            @module array
            @func __index
            @scope public
            @desc Retrieves an element from the array by index or a method/property by name.
            @param number|string vIndex The numeric array index or string name of method/property to retrieve.
            @ret any The value at the specified index or the method/property.
            ]]
            __index = function(t, k)
                local vRet = nil;

                --process number and string access attempts
                local sType = type(k);
                if (sType == "number") then

                    if not (k % 1 == 0 and k > 0 and k <= tActual.length) then
                        error("Error retrieving value from array. Index is out of bounds.\nMax value: ${maxval}. Value given: ${givenval}" % {maxval = tActual.length, givenval = k}, 2);
                    end

                    vRet = rawget(tItems, k);

                elseif (sType == "string") then
                    vRet = tActual[k] or error("Error accessing array method or property, '${method}'. No such method or property exists." % {method = k}, 2);

                else
                    error("Array index must be an integer or a method/property name.", 2);
                end

                return vRet;
            end,


            --[[
            @module array
            @func __newindex
            @scope public
            @desc Assigns a value to the array at a specific index.
            @param number nIndex The index to assign.
            @param any vVal A value of the established type, or null to clear the slot.
            ]]
            __newindex = function(t, k, v)
                assert(not bSorting, "Cannot modify an array from its sort comparator.");
                local sType = type(v);

                if (sType == "nil") then
                    error("Error assigning value to array. Item cannot be nil.", 2);
                end

                if (type(k) ~= "number") then
                    error("Error assigning value to array. Index must be a positve, whole integer.\nInput is '${input}' of type ${type}." % {input = tostring(k), type = type(k)}, 2);
                end

                if (math.floor(k) ~= k) then
                    error("Error assigning value to array. Index must be a positve, whole integer.\nInput is '${input}' of type ${type}." % {input = tostring(k), type = type(k)}, 2);
                end

                if not (k > 0 and k <= tActual.length) then
                    error("Error assigning value to array. Index is out of bounds.\nMax value: ${maxval}. Value given: ${givenval}" % {maxval = tActual.length, givenval = k}, 2);
                end

                if (sArrayType == null and v ~= null) then
                    sArrayType = sType;
                end

                if (v ~= null and sType ~= sArrayType) then
                    error("Error assigning value to array. Item must be of type ${expectedtype}.\nInput is '${input}' of type ${type}." % {expectedtype = tostring(sArrayType), input = tostring(v), type = type(v)}, 2);
                end

                tItems[k]   = v;
            end,

            -- Preserve capacity, established type, and every slot for restoration.
            __serialize = function()
                local tRet = {
                    length  = tActual.length,
                    type    = sArrayType,
                    items   = {},
                };

                for nIndex, vItem in ipairs(tItems) do

                    tRet.items[nIndex] = vItem;
                end

                return tRet;
            end,
            --[[
                @module array
                @func __tostring
                @scope public
                @desc Converts the array object to a string representation.
                @ret string The string representation of the array.
            ]]
            __tostring = function()
                local sRet = "";

                for nIndex, vItem in ipairs(tItems) do

                    if (vItem ~= tArrayDecoy) then
                        sRet = sRet..", "..tostring(vItem);
                    else
                        sRet = sRet..", <_SELF_REFERENCE_>";
                    end

                end

                return '{'..sRet:sub(3)..'}';
            end,
            __type = "array",
            __len = function()
                return tActual.length;
            end,
            __pairs = function()
                return function(_, nIndex)
                    nIndex = (nIndex or 0) + 1;
                    if (nIndex <= tActual.length) then
                        return nIndex, tItems[nIndex];
                    end
                end, tArrayDecoy, nil;
            end,

        };

        _tStates[tArrayDecoy] = {
            items = tItems,
            settype = function(sType) sArrayType = sType; end,
        };

        -- The public metatable view exposes lifecycle hooks needed by LuaEx,
        -- while keeping the actual index/write rules protected from replacement.
        tArrayMeta.__metatable = {
            __type = "array",
            __clone = tArrayMeta.__clone,
            __serialize = tArrayMeta.__serialize,
        };

        return setmetatable(tArrayDecoy, tArrayMeta);
    end,


    --[[
    @module array
    @func __index
    @scope public
    @desc Retrieves a method or property from the array factory.
    @param string sName The name of the method or property to retrieve.
    @ret any The method or property.
    ]]
    __index = function(t, k)
        return rawget(tArrayActual, k) or nil;
    end,


    --[[
    @module arrayfactory
    @func __newindex
    @scope public
    @desc An error method to prevent modification of the array factory.
    ]]
    __newindex = function(t, k, v)
        error("Error: attempting to modify read-only array factory at index ${index} with ${value} (${type})." % {index = tostring(k), value = tostring(v), type = type(v)});
    end,

    __serialize = function()
        return "array";
    end,

    __tostring = function()
        return "arrayfactory"
    end,

    __type      = "arrayfactory",
    __metatable = {
        __type = "arrayfactory",
        __call = function(_, ...) return array(...); end,
        __serialize = function() return "array"; end,
    },
});

require("LuaEx.lib.serializer").registerFactory(ArrayFactoryDecoy, {name = "array", types = {"array"}});
return ArrayFactoryDecoy;
