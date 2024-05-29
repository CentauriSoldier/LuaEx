local assert        = assert;
local class         = class;
local pairs         = pairs;
local rawtype       = rawtype;
local table         = table;
local sOtherError   = "Error in set class, method, ${method}. Attempt to operate on non-set value of type ";

--[[!
    @module set
    @func addItem
    @scope static private
    @desc Adds an item to the set.
    @param set oSet The set upon which to operate.
    @param table cdat The instance class data table.
    @param any vItem The item to add to the set.
    @ret boolean True if the item was added successfully, false otherwise.
!]]
addItem = function(cdat, vItem)
    local bRet = false;

    if (rawtype(vItem) ~= "nil") then

        if (not cdat.pri.set[vItem]) then
            cdat.pri.set[vItem] 		    = true;
            cdat.pri.size 				    = cdat.pri.size + 1;
            cdat.pri.indexed[cdat.pri.size] = vItem;

            bRet = true;
        end

    end

    return bRet;
end


--[[!
    @module set
    @func removeItem
    @scope static private
    @desc Removes an item from the set.
    @param set oSet The set upon which to operate.
    @param table cdat The instance class data table.
    @param any vItem The item to remove from the set.
    @ret boolean True if the item was removed successfully, false otherwise.
!]]
removeItem = function(cdat, vItem)
    local bRet = false;

    if (cdat.pri.set[vItem] ~= nil) then
        cdat.pri.set[vItem] = nil;

        for x = 1, cdat.pri.size do

            if (cdat.pri.indexed[x] == vItem) then
                table.remove(cdat.pri.indexed, x);
                break;
            end

        end

        cdat.pri.size = cdat.pri.size - 1;

        bRet = true;
    end

    return bRet;
end


return class("Set",
{--metamethods


    --[[!
    @module set
    @func __add
    @scope public
    @desc Returns the union of this set with another set (A + B).
    @param set other The other set with which to form the union.
    @ret set A new set containing items that are the union of this set and the other.
    !]]
    __add = function(left, right, cdat)
        assert(type(left)   == "set", sOtherError % {method = "__add"}..type(left)..'.');
        assert(type(right)  == "set", sOtherError % {method = "__add"}..type(right)..'.');

		local oRet      = set();
        local newcdat   = cdat.ins[oRet];
        local leftcdat  = cdat.ins[left];
        local rightcdat = cdat.ins[right];

        --add this set's items to the new set
		for nIndex, vItem in pairs(leftcdat.pri.indexed) do
			addItem(newcdat, vItem);
		end

        --add the other set items to the new set
        for nIndex, vItem in pairs(rightcdat.pri.indexed) do
			addItem(newcdat, vItem);
		end

		return oRet;
    end,


    --[[!
    @module set
    @func __call
    @scope global
    @desc Creates an iterator function to iterate over the elements of the set.
    @ret function An iterator function that returns each element of the set.
    !]]
	__call = function(this, cdat)
        local nIndex = 0;
	   	local nMax = cdat.pri.size;

		return function()
	    	nIndex = nIndex + 1;

			if (nIndex <= nMax) then
				return cdat.pri.indexed[nIndex];
			end

		end

   end,


   --[[!
   @module set
   @func __eq
   @scope global
   @desc Determines of the two sets are equal.
   @ret boolean True if the two sets are equal, false otherwise.
   !]]
   __eq = function(left, right, cdat)
       assert(type(left)   == "set", sOtherError % {method = "__eq"}..type(left)..'.');
       assert(type(right)  == "set", sOtherError % {method = "__eq"}..type(right)..'.');
       local leftcdat  = cdat.ins[left];
       local rightcdat = cdat.ins[right];

       --start by checking their size
       local bRet = leftcdat.pri.size == rightcdat.pri.size;

       --check each value for existence in the other set
       for nIndex, vItem in pairs(leftcdat.pri.indexed) do

           if (rawtype(rightcdat.pri.set[vItem]) == "nil") then
               bRet = false;
               break;
           end

       end

       return bRet;
   end,


   --[[!
   @module set
   @func __len
   @scope global
   @desc Returns the number of elements currently in the set.
   @ret number The number of elements in the set.
   !]]
   __len = function(this, cdat)
      return cdat.pri.size;
    end,


   --[[!
   @module set
   @func __sub
   @scope public
   @desc Returns the relative complement of this set with repeect to another set (A - B).
   @param set other The other set with which to find the relative complement.
   @ret set A new set containting values that are in this set but not in the other set.
   !]]
   __sub = function(left, right, cdat)
       assert(type(left)    == "set", sOtherError % {method = "__sub"}..type(left)..'.');
       assert(type(right)   == "set", sOtherError % {method = "__sub"}..type(right)..'.');

       local oRet      = set();
       local newcdat   = cdat.ins[oRet];
       local leftcdat  = cdat.ins[left];
       local rightcdat = cdat.ins[right];

       --iterate over the left set
       for nIndex, vItem in pairs(leftcdat.pri.indexed) do

           if not (rightcdat.pri.set[vItem]) then
               addItem(newcdat, vItem);
           end

       end

       return oRet;
   end,


    --[[!
    @module set
    @func __tostring
    @scope global
    @desc Converts the set into a string representation.
    @ret string A string representation of the set.
    !]]
	__tostring = function(this, cdat)--TODO allow table serialization
		local sRet = "{";

		for nIndex, vItem in pairs(cdat.pri.indexed) do
            sRet = sRet..tostring(vItem)..", ";
		end

		return sRet:sub(1, #sRet - 2).."}";
	end,
},
{},--static public
{--private
	indexed = {},
	set		= {},
	size 	= 0,
},
{},--protected
{--public
    --[[!
    @module set
    @func set
    @scope public
    @param table|nil A table of items to add to the set (optional).
    @desc Constructs a new set object.
    !]]
	Set = function(cdat, cdat, tItems)

        if (type(tItems) == "table") then

            for _, vItem in pairs(tItems) do
                addItem(cdat, vItem);
            end

        end

    end,


    --[[!
    @module set
    @desc Provides a set data structure implementation in Lua.
    @func set.add
    @scope public
    @desc Adds an item to the set.
    @param any vItem The item to add to the set.
    @ret set The set object after adding the item.
    !]]
	add = function(this, cdat, vItem)
		addItem(cdat, vItem);
        return this;
	end,


    --[[!
    @module set
    @func set.clear
    @scope public
    @desc Removes all items from the set.
    @ret set The set object after adding the item.
    !]]
	clear = function(this, cdat)
		cdat.pri.indexed = {};
		cdat.pri.set 	 = {};
		cdat.pri.size 	 = 0;

        return this;
	end,


    --[[
    clone = function(this, cdat)

    end,
    ]]


    --[[!
    @module set
    @func set.contains
    @scope public
    @desc Checks if the set contains a specific item.
    @param any vItem The item to check for.
    @ret boolean Returns true if the set contains the item, false otherwise.
    !]]
	contains = function(this, cdat, vItem)
		return cdat.pri.set[vItem] ~= nil;
	end,


    --[[!
    @mod set
    @func set.deserialize
    @scope public
    @desc Deserializes the set object from a string.
    !]]
    deserialize = function(this, cdat)
        return "ERROR: set.deserialize mmethod still in development.";
    end,


    --[[!
    @module set
    @func set.importSet
    @scope public
    @desc Adds all items from another set to this set.
    @param set oOther The other set containing items to add.
    @ret set This set object after adding the items found in the other set.
    !]]
	importSet = function(this, cdat, other)
        assert(type(other) == "set", sOtherError % {method = "addset"}..type(other)..'.');
        local othercdat = cdat.ins[other];

        for nIndex, vItem in ipairs(othercdat.pri.indexed) do
            addItem(cdat, vItem);
		end

        return this;
	end,


    --[[!
    @module set
    @func set.intersection
    @scope public
    @desc Returns the intersection of this set with another set.
    @param set other The other set with which to find the intersection.
    @ret set A new set containting values that intersect with this set and the other set.
    !]]
	intersection = function(this, cdat, other)
        assert(type(other) == "set", sOtherError % {method = "intersection"}..type(other)..'.');
        local oRet      = set();
        local newcdat   = cdat.ins[oRet];
        local othercdat = cdat.ins[other];

		for nIndex, vItem in pairs(cdat.pri.indexed) do

            if (rawtype(othercdat.pri.set[vItem]) ~= "nil") then
				addItem(newcdat, vItem);
			end

		end

		return oRet;
	end,


    --[[!
    @module set
    @func set.isEmpty
    @scope public
    @desc Checks if the set is empty.
    @ret boolean Returns true if the set is empty, false otherwise.
    !]]
	isEmpty = function(this, cdat)
		return cdat.pri.size < 1;
	end,


    --[[!
    @module set
    @func set.isSubset
    @scope public
    @desc Checks if the input set a subset of this set.
    @param set other The other set to detemine subsetness.
    @ret boolean Returns true if the other set is a subset of this set, false otherwise.
    !]]
	isSubset = function(this, cdat, other)--TODO use cdat
        assert(type(other) == "set", sOtherError % {method = "isSubset"}..type(other)..'.');
        local bRet = true;
        local othercdat = cdat.ins[other];

		for nIndex, vItem in pairs(cdat.pri.indexed) do

            if (rawtype(othercdat.pri.set[vItem]) == "nil") then
				bRet = false;
                break;
			end

		end

		return bRet;
	end,


    --[[!
    @module set
    @func set.remove
    @scope public
    @desc Removes an item from the set if it exists.
    @param any vItem The item to remove from the set.
    @ret set Returns the set object after removing the item.
    !]]
	remove = function(this, cdat, vItem)
		removeItem(cdat, vItem);
        return this;
	end,


    --[[!
    @module set
    @func set.purgeSet
    @scope public
    @desc Removes all items from this set that are present in another set.
    @param set other The other set containing items to remove.
    @ret set This set object after removing items found in the other set.
    !]]
	purgeSet = function(this, cdat, other)
        assert(type(other) == "set", sOtherError % {method = "removeset"}..type(other)..'.');
        local othercdat = cdat.ins[other];
        local indexedCopy = {table.unpack(cdat.pri.indexed)}

		for nIndex, vItem in pairs(indexedCopy) do

            if (othercdat.pri.set[vItem]) then
				removeItem(cdat, vItem);
			end

		end

		return this;
	end,


    --[[!
    @mod set
    @func set.serialize
    @scope public
    @desc Serializes the set object to a string.
    @ret string A string representing the set object which can be stored and later deserialized.
    !]]
    serialize = function(this, cdat)
        return "ERROR: set.serialize mmethod still in development.";
    end,


    --[[!
    @module set
    @func set.size
    @scope public
    @desc Returns the number of items in the set (Same as #MySet).
    @ret number The number of items in the set.
    !]]
	size = function(this, cdat)
		return cdat.pri.size;
	end,
}, nil, false);
