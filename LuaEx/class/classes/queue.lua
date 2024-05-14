--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class("queue",
{--metamethods
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


    __len = function(this, cdat)
		return cdat.pri.count;
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
    @mod queue
    @func queue
    @scope public
    @desc Constructs a new queue object.
    @ret queue A new queue object.
    !]]
	queue = function(this, cdat) end,


    --[[!
    @module queue
    @func queue.enqueue
    @scope public
    @desc Adds an element to the end of the queue.
    @param any vValue The value to enqueue.
    @ret any The queue object after enqueueing the item.
    !]]
	enqueue = function(this, cdat, vValue)

		if (rawtype(vValue) ~= "nil") then
			table.insert(cdat.pri.values, #cdat.pri.values + 1, vValue);
			cdat.pri.count = cdat.pri.count + 1;
		end

        return this;
	end,


    --[[!
    @module queue
    @func queue.dequeue
    @scope public
    @desc Adds an element to the end of the queue.
    @param any vValue The value to dequeue.
    @ret any The value dequeue.
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
    @mod queue
    @func queue.deserialize
    @scope public
    @desc Deserializes the queue object from a string.
    !]]
    deserialize = function(this, cdat)
        error("ERROR: queue.deserialize mmethod still in development.");
    end,


    --[[!
    @module queue
    @func queue.peek
    @scope public
    @param table cdat The class data table.
    @desc Retrieves the next-in-line element from the queue without removing it.
    @ret any The next-in-line element in the queue, or nil if the queue is empty.
    !]]
    peek = function(this, cdat)
        return cdat.pri.values[1] or nil;
    end,


    --TODO reverse method


    --[[!
    @mod queue
    @func queue.serialize
    @scope public
    @desc Serializes the queue object to a string.
    @ret string A string representing the queue object which can be stored and later deserialized.
    !]]
    serialize = function(this, cdat)
        return "ERROR: queue.serialize mmethod still in development.";
    end,

    --[[!
    @module queue
    @func queue.size
    @scope public
    @desc Returns the number of elements currently in the queue.
    @ret number The number of elements in the queue.
    !]]
	size = function(this, cdat)
		return cdat.pri.count;
	end,
},
nil, nil, false);
