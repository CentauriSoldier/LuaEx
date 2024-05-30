--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class("Stack",
{--metamethods

    --[[!
    @module Stack
    @func __call
    @scope public
    @desc Creates an iterator function to iterate over the elements of the Stack.
    @ret function An iterator function that returns each element of the Stack.
    !]]
    __call = function(this, cdat)
        local nIndex = 0
        local nCount = cdat.pri.count

        return function()
            nIndex = nIndex + 1

            if nIndex <= nCount then
                return cdat.pri.values[nIndex]
            end

        end

    end,


    --[[!
    @module Stack
    @func __len
    @scope public
    @desc Returns the number of elements currently in the Stack.
    @ret number The number of elements in the Stack.
    !]]
     __len = function(this, cdat)
        return cdat.pri.count;
    end,


    --[[!
    @module Stack
    @func __tostring
    @scope public
    @desc Returns a string representing the items in the Stack.
    @ret string A string representing the items in the Stack.
    !]]
    __tostring = function(this, cdat)--TODO clean up in Stack, set and queue
        local sRet = "";

        for _, vItem in ipairs(cdat.pri.values) do
            sRet = sRet..tostring(vItem)..", ";
        end

        return "{"..sRet:sub(1, #sRet - 2).."}";
    end,
},
{},--static public
{--private
    count  = 0,
    values = {},
},
{},--protected
{--public
    --[[!
    @mod Stack
    @func Stack
    @scope public
    @desc Constructs a new Stack object.
    @param table|nil A numerically-indexed table of items to push onto the Stack (optional).
    @ret Stack A new Stack object.
    !]]
    Stack = function(this, cdat, tItems)

        if (type(tItems) == "table") then

            for nIndex, vItem in ipairs(tItems) do

                if (rawtype(vItem) ~= "nil") then
                    table.insert(cdat.pri.values, 1, vItem);
                    cdat.pri.count = cdat.pri.count + 1;
                end

            end

        end

    end,


    --[[!
    @mod Stack
    @func Stack.clear
    @scope public
    @desc Removes all elements from the Stack.
    @ret Stack The Stack object after clearing all items.
    !]]
    clear = function(this, cdat)
       cdat.pri.count  = 0;
       cdat.pri.values = {};

       return this;
    end,


    --[[
    clone = function(this, cdat)
        local oRet  = Stack();
        local ncdat = cdat.ins[oRet];

        ncdat.values    = table.clone(cdat.values);
        ncdat.count     = #ncdat.values;

        return oRet;
    end,
    ]]


    --[[!
    @mod Stack
    @func Stack.deserialize
    @scope public
    @desc Deserializes the Stack object from a string.
    !]]
    --TODO complete serialization
    deserialize = function(this, cdat)
        error("ERROR: Stack.deserialize method still in development.");
    end,


    --[[!
    @module Stack
    @func Stack.peek
    @scope public
    @param table cdat The class data table.
    @desc Retrieves the next-in-line element from the Stack without removing it.
    @ret any The next-in-line element in the Stack, or nil if the Stack is empty.
    !]]
    peek = function(this, cdat)
        return cdat.pri.values[1] or nil;
    end,


    --[[!
    @mod Stack
    @func Stack.pop
    @scope public
    @desc Removes and returns the top element of the Stack.
    @ret any The removed element from the Stack.
    !]]
    pop = function(this, cdat)

        if (rawtype(cdat.pri.values[1]) ~= "nil") then
            vRet = table.remove(cdat.pri.values, 1);
            cdat.pri.count = cdat.pri.count - 1;
        end

        return vRet;
    end,


    --[[!
    @mod Stack
    @func Stack.push
    @scope public
    @desc Adds a new element to the top of the Stack.
    @param any vValue The value to be added to the Stack.
    @ret Stack The Stack object after pushing the value.
    !]]
    push = function(this, cdat, vValue)

        if (rawtype(vValue) ~= "nil") then
            table.insert(cdat.pri.values, 1, vValue);
            cdat.pri.count = cdat.pri.count + 1;
        end

        return this;
    end,


    --[[!
    @mod Stack
    @func Stack.reverse
    @scope public
    @desc Reverses the order of elements in the Stack.
    @ret Stack The Stack object after reversing the elements.
    !]]
    reverse = function(this, cdat)
        local values    = cdat.pri.values
        local count     = cdat.pri.count

        for x = 1, math.floor(count / 2) do
            values[x], values[count - x + 1] = values[count - x + 1], values[x];
        end

        return this;
    end,


    --[[!
    @mod Stack
    @func Stack.serialize
    @scope public
    @desc Serializes the Stack object to a string.
    @ret string A string representing the Stack object which can be stored and later deserialized.
    !]]
    serialize = function(this, cdat) --TODO complete this
        return "ERROR: Stack.serialize method still in development.";
    end,


    --[[!
    @mod Stack
    @func Stack.size
    @scope public
    @desc Returns the number of elements in the Stack.
    @ret number The number of elements in the Stack.
    !]]
    size = function(this, cdat)
        return cdat.pri.count;
    end,

}, nil, false);
--}, nil, false, iClonable); --TODO add interface reference when interfaces are reimplemented in the class system (do for set and queue too)
