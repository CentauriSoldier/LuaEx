--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class("Queue",
{--metamethods


    --[[!
    @module Queue
    @func __call
    @scope public
    @desc Creates an iterator function to iterate over the elements of the Queue.
    @ret function An iterator function that returns each element of the Queue.
    !]]
    __call = function(this, cdat)
        local index = 0
        local count = cdat.pri.count

        return function ()
            index = index + 1

            if index <= count then
                return cdat.pri.values[index]
            end
        end
    end,


    --[[!
    @module Queue
    @func __len
    @scope public
    @desc Returns the number of elements currently in the Queue.
    @ret number The number of elements in the Queue.
    !]]
    __len = function(this, cdat)
        return cdat.pri.count;
    end,


    --[[!
    @module Queue
    @func __tostring
    @scope public
    @desc Returns a string representing the items in the Queue.
    @ret string A string representing the items in the Queue.
    !]]
    __tostring = function(this, cdat)
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
    @mod Queue
    @func Queue
    @scope public
    @desc Constructs a new Queue object.
    @param table|nil A numerically-indexed table of items to add to enQueue (optional).
    @ret Queue A new Queue object.
    !]]
    Queue = function(this, cdat, tItems)

        if (type(tItems) == "table") then

            for _, vItem in ipairs(tItems) do

                if (rawtype(vItem) ~= "nil") then
                    table.insert(cdat.pri.values, #cdat.pri.values + 1, vItem);
                    cdat.pri.count = cdat.pri.count + 1;
                end

            end

        end

    end,


    --[[!
    @module Queue
    @func Queue.clear
    @scope public
    @desc Removes all items from the Queue.
    ret Queue The Queue object after clearing all items.
    !]]
    clear = function(this, cdat)
       cdat.pri.count  = 0;
       cdat.pri.values = {};

       return this;
    end,


    --[[!
    @module Queue
    @func Queue.enqueue
    @scope public
    @desc Adds an element to the end of the Queue.
    @param any vValue The value to enQueue.
    @ret any The Queue object after enQueueing the item.
    !]]
    enqueue = function(this, cdat, vValue)

        if (rawtype(vValue) ~= "nil") then
            table.insert(cdat.pri.values, #cdat.pri.values + 1, vValue);
            cdat.pri.count = cdat.pri.count + 1;
        end

        return this;
    end,


    --[[!
    @module Queue
    @func Queue.dequeue
    @scope public
    @desc Adds an element to the end of the Queue.
    @param any vValue The value to deQueue.
    @ret any The value deQueue.
    !]]
    dequeue = function(this, cdat)
        local vRet = nil;

        if (cdat.pri.count > 0) then
            vRet = table.remove(cdat.pri.values, 1);
            cdat.pri.count = cdat.pri.count - 1;
        end

        return vRet;
    end,


    --[[!
    @mod Queue
    @func Queue.deserialize
    @scope public
    @desc Deserializes the Queue object from a string.
    !]]
    deserialize = function(this, cdat)
        error("ERROR: Queue.deserialize method still in development.");
    end,


    --[[!
    @module Queue
    @func Queue.peek
    @scope public
    @param table cdat The class data table.
    @desc Retrieves the next-in-line element from the Queue without removing it.
    @ret any The next-in-line element in the Queue, or nil if the Queue is empty.
    !]]
    peek = function(this, cdat)
        return cdat.pri.values[1] or nil;
    end,


    --[[!
    @mod Queue
    @func Queue.reverse
    @scope public
    @desc Reverses the order of elements in the Queue.
    @ret Queue The Queue object after reversing the elements.
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
    @mod Queue
    @func Queue.serialize
    @scope public
    @desc Serializes the Queue object to a string.
    @ret string A string representing the Queue object which can be stored and later deserialized.
    !]]
    serialize = function(this, cdat)
        return "ERROR: Queue.serialize method still in development.";
    end,


    --[[!
    @module Queue
    @func Queue.size
    @scope public
    @desc Returns the number of elements currently in the Queue.
    @ret number The number of elements in the Queue.
    !]]
    size = function(this, cdat)
        return cdat.pri.count;
    end,
},
nil, false);
