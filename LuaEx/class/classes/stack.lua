--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class("stack",
{--metamethods

    --[[!
    @module stack
    @func __call
    @scope public
    @desc Creates an iterator function to iterate over the elements of the stack.
    @ret function An iterator function that returns each element of the stack.
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
    @module stack
    @func __len
    @scope public
    @desc Returns the number of elements currently in the stack.
    @ret number The number of elements in the stack.
    !]]
	 __len = function(this, cdat)
		return cdat.pri.count;
	end,
},
{bugs = 45,},--"JKAHSDUIYIQWUHEDIUY(@#*#)"},--static public TODO static public is not working
{--private
	count  = 0,
	values = {},
},
{},--protected
{--public
    --[[!
    @mod stack
    @func stack
    @scope public
    @desc Constructs a new stack object.
    @ret stack A new stack object.
    !]]
    stack = function(this, cdat) end,


    --[[!
    @mod stack
    @func stack.clear
    @scope public
    @desc Removes all elements from the stack.
    @ret stack The stack object after clearing.
    !]]
    clear = function(this, cdat)
       cdat.pri.count  = 0;
       cdat.pri.values = {};

       return this;
    end,


    --[[
    clone = function(this, cdat)
        local oRet  = stack();
        local ncdat = cdat.ins[oRet];

        ncdat.values    = table.clone(cdat.values);
        ncdat.count     = #ncdat.values;

        return oRet;
    end,
    ]]


    --[[!
    @mod stack
    @func stack.deserialize
    @scope public
    @desc Deserializes the stack object from a string.
    !]]
    --TODO complete serialization
    deserialize = function(this, cdat)
        error("ERROR: stack.deserialize mmethod still in development.");
    end,


    --[[!
    @module stack
    @func stack.peek
    @scope public
    @param table cdat The class data table.
    @desc Retrieves the next-in-line element from the stack without removing it.
    @ret any The next-in-line element in the stack, or nil if the stack is empty.
    !]]
    peek = function(this, cdat)
        return cdat.pri.values[1] or nil;
    end,


    --[[!
    @mod stack
    @func stack.pop
    @scope public
    @desc Removes and returns the top element of the stack.
    @ret any The removed element from the stack.
    !]]
    pop = function(this, cdat)

    	if (rawtype(cdat.pri.values[1]) ~= "nil") then
    		vRet = table.remove(cdat.pri.values, 1);
    		cdat.pri.count = cdat.pri.count - 1;
    	end

    	return vRet;
    end,


    --[[!
    @mod stack
    @func stack.push
    @scope public
    @desc Adds a new element to the top of the stack.
    @param any vValue The value to be added to the stack.
    @ret stack The stack object after pushing the value.
    !]]
    push = function(this, cdat, vValue)

    	if (rawtype(vValue) ~= "nil") then
    		table.insert(cdat.pri.values, 1, vValue);
    		cdat.pri.count = cdat.pri.count + 1;
    	end

        return this;
    end,


    --[[!
    @mod stack
    @func stack.reverse
    @scope public
    @desc Reverses the order of elements in the stack.
    @ret stack The stack object after reversing the elements.
    !]]
    reverse = function(this, cdat)
        local values = cdat.pri.values
        local count = cdat.pri.count

        for x = 1, math.floor(count / 2) do
            values[x], values[count - x + 1] = values[count - x + 1], values[x];
        end

        return this;
    end,


    --[[!
    @mod stack
    @func stack.serialize
    @scope public
    @desc Serializes the stack object to a string.
    @ret string A string representing the stack object which can be stored and later deserialized.
    !]]
    serialize = function(this, cdat) --TODO complete this
        return "ERROR: stack.serialize mmethod still in development.";
    end,


    --[[!
    @mod stack
    @func stack.size
    @scope public
    @desc Returns the number of elements in the stack.
    @ret number The number of elements in the stack.
    !]]
    size = function(this, cdat)
    	return cdat.pri.count;
    end,

}, nil, nil, false);
--}, nil, iClonable, false); --TODO add interface reference when interfaces are reimplemented in the class system (do for set and queue too)
