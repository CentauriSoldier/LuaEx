local assert        = assert;
local class         = class;
local pairs         = pairs;
local rawtype       = rawtype;
local table         = table;
local sOtherError   = "Error in set class, method, ${method}. Attempt to operate on non-set value of type ";

--[[!
    @module set
    @func additem
    @scope static private
    @desc Adds an item to the set.
    @param set oSet The set upon which to operate.
    @param table cdat The instance class data table.
    @param any vItem The item to add to the set.
    @ret boolean True if the item was added successfully, false otherwise.
!]]
additem = function(cdat, vItem)
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
    @func removeitem
    @scope static private
    @desc Removes an item from the set.
    @param set oSet The set upon which to operate.
    @param table cdat The instance class data table.
    @param any vItem The item to remove from the set.
    @ret boolean True if the item was removed successfully, false otherwise.
!]]
removeitem = function(cdat, vItem)
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

return class("set",
{--metamethods
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
    @desc Constructs a new set object.
    !]]
	set = function(this, cdat) end,


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
		additem(cdat, vItem);
        return this;
	end,


    --[[!
    @module set
    @func set.addSet
    @scope public
    @desc Adds all items from another set to this set.
    @param set oOther The other set containing items to add.
    @ret set The set object after adding the item.
    !]]
	addset = function(this, cdat, other)
        assert(type(other) == "set", sOtherError % {method = "addset"}..type(other)..'.');
        local othercdat = cdat.ins[other];

        for nIndex, vItem in ipairs(othercdat.pri.indexed) do
            additem(cdat, vItem);
		end

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
    @func set.complement
    @scope public
    @desc Returns the complement of this set with another set.
    @param set other The other set with which to find the complement.
    @ret set A new set containting values that are the complement of this set and the other set.
    !]]
	complement = function(this, cdat, other)--TODO use cdat
        assert(type(other) == "set", sOtherError % {method = "complement"}..type(other)..'.');
        local oRet      = set();
        local newcdat   = cdat.ins[oRet];
        local othercdat = cdat.ins[other];

        --iterate over the other set to find complement items
        for nIndex, vItem in pairs(othercdat.pri.indexed) do

            if not (cdat.pri.set[vItem]) then
                additem(newcdat, vItem);
            end

		end

		return oRet;
	end,


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
    @module set
    @func set.equals
    @scope public
    @desc Checks if this set is equal to another set.
    @param set other The other set to compare with.
    @ret boolean Returns true if the sets are equal, false otherwise.
    !]]
	equals = function(this, cdat, other)--TODO use cdat
        assert(type(other) == "set", sOtherError % {method = "equals"}..type(other)..'.');
		local bRet = tSets[this]:size() == other:size();

		if (bRet) then

			for item in other() do

				if not (this:contains(item)) then
					bRet = false;
					break;
				end

			end

		end

		return bRet;
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
				additem(newcdat, vItem);
			end

		end

		return oRet;
	end,


    --[[!
    @module set
    @func set.isempty
    @scope public
    @desc Checks if the set is empty.
    @ret boolean Returns true if the set is empty, false otherwise.
    !]]
	isempty = function(this, cdat)
		return cdat.pri.size < 1;
	end,


    --[[!
    @module set
    @func set.issubset
    @scope public
    @desc Checks if the input set a subset of this set.
    @param set other The other set to detemine subsetness.
    @ret boolean Returns true if the other set is a subset of this set, false otherwise.
    !]]
	issubset = function(this, cdat, other)--TODO use cdat
        assert(type(other) == "set", sOtherError % {method = "issubset"}..type(other)..'.');
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
		removeitem(cdat, vItem);
        return this;
	end,


    --[[!
    @module set
    @func set.removeset
    @scope public
    @desc Removes all items from this set that are present in another set.
    @param set other The other set containing items to remove.
    @ret set The set object after removing items.
    !]]
	removeset = function(this, cdat, other)
        assert(type(other) == "set", sOtherError % {method = "removeset"}..type(other)..'.');
        local othercdat = cdat.ins[other];
        local indexedCopy = {table.unpack(cdat.pri.indexed)}

		for nIndex, vItem in pairs(indexedCopy) do

            if (othercdat.pri.set[vItem]) then
				removeitem(cdat, vItem);
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
    @desc Returns the number of items in the set.
    @ret number The number of items in the set.
    !]]
	size = function(this, cdat)
		return cdat.pri.size;
	end,


    --[[!
    @module set
    @func set.union
    @scope public
    @desc Returns the union of this set with another set.
    @param set other The other set with which to form the union.
    @ret set A new set containing items that are the union of this set and the other.
    !]]
	union = function(this, cdat, other)--TODO use cdat
        assert(type(other) == "set", sOtherError % {method = "union"}..type(other)..'.');
		local oRet      = set();
        local newcdat   = cdat.ins[oRet];
        local othercdat = cdat.ins[other];

        --add this set's items to the new set
		for nIndex, vItem in pairs(cdat.pri.indexed) do
			additem(newcdat, vItem);
		end

        --add the other set items to the new set
        for nIndex, vItem in pairs(othercdat.pri.indexed) do
			additem(newcdat, vItem);
		end

		return oRet;
	end,


}, nil, nil, false);
