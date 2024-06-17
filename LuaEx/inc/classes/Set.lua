local assert        = assert;
local class         = class;
local pairs         = pairs;
local rawtype       = rawtype;
local table         = table;

return class("Set",
{--metamethods


    --[[!
    @module Set
    @func __add
    @scope public
    @desc Returns the union of this Set with another Set (A + B).
    @param Set other The other Set with which to form the union.
    @ret Set A new Set containing items that are the union of this Set and the other.
    !]]
    __add = function(left, right, cdat)
        local sOtherError   = "Error in Set class, method, ${method}. Attempt to operate on non-Set value of type ";
        assert(type(left)   == "Set", sOtherError % {method = "__add"}..type(left)..'.');
        assert(type(right)  == "Set", sOtherError % {method = "__add"}..type(right)..'.');--TODO these should be isa assertions so subclasses can use them

        local oRet      = Set();--TODO also this...?
        local newcdat   = cdat.ins[oRet];
        local leftcdat  = cdat.ins[left];
        local rightcdat = cdat.ins[right];

        --add this Set's items to the new Set
        for nIndex, vItem in pairs(leftcdat.pro.indexed) do
            newcdat.pro.addItem(vItem);
        end

        --add the other Set items to the new Set
        for nIndex, vItem in pairs(rightcdat.pro.indexed) do
            newcdat.pro.addItem(vItem);
        end

        return oRet;
    end,


    --[[!
    @module Set
    @func __call
    @scope global
    @desc Creates an iterator function to iterate over the elements of the Set.
    @ret function An iterator function that returns each element of the Set.
    !]]
    __call = function(this, cdat)
        local nIndex = 0;
           local nMax = cdat.pro.size;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return cdat.pro.indexed[nIndex];
            end

        end

   end,

   --TODO docs
   __clone = function(this, cdat)
       error("Cloner for set not yet implemented.")
   end,

   --[[!
   @module Set
   @func __eq
   @scope global
   @desc Determines of the two Sets are equal.
   @ret boolean True if the two Sets are equal, false otherwise.
   !]]
   __eq = function(left, right, cdat)
       local sOtherError   = "Error in Set class, method, ${method}. Attempt to operate on non-Set value of type ";
       assert(type(left)   == "Set", sOtherError % {method = "__eq"}..type(left)..'.');
       assert(type(right)  == "Set", sOtherError % {method = "__eq"}..type(right)..'.');
       local leftcdat  = cdat.ins[left];
       local rightcdat = cdat.ins[right];

       --start by checking their size
       local bRet = leftcdat.pro.size == rightcdat.pro.size;

       --check each value for existence in the other Set
       for nIndex, vItem in pairs(leftcdat.pro.indexed) do

           if (rawtype(rightcdat.pro.set[vItem]) == "nil") then
               bRet = false;
               break;
           end

       end

       return bRet;
   end,


   --[[!
   @module Set
   @func __len
   @scope global
   @desc Returns the number of elements currently in the Set.
   @ret number The number of elements in the Set.
   !]]
   __len = function(this, cdat)
      return cdat.pro.size;
    end,


   --[[!
   @module Set
   @func __sub
   @scope public
   @desc Returns the relative complement of this Set with repeect to another Set (A - B).
   @param Set other The other Set with which to find the relative complement.
   @ret Set A new Set containting values that are in this Set but not in the other Set.
   !]]
   __sub = function(left, right, cdat)
       local sOtherError   = "Error in Set class, method, ${method}. Attempt to operate on non-Set value of type ";
       assert(type(left)    == "Set", sOtherError % {method = "__sub"}..type(left)..'.');
       assert(type(right)   == "Set", sOtherError % {method = "__sub"}..type(right)..'.');

       local oRet      = Set();
       local newcdat   = cdat.ins[oRet];
       local leftcdat  = cdat.ins[left];
       local rightcdat = cdat.ins[right];

       --iterate over the left Set
       for nIndex, vItem in pairs(leftcdat.pro.indexed) do

           if not (rightcdat.pro.set[vItem]) then
               newcdat.pro.addItem(vItem);
           end

       end

       return oRet;
   end,

   __serialize = function()
       error("Serializer for Set has not been completed.", 2);
   end,
    --[[!
    @module Set
    @func __tostring
    @scope global
    @desc Converts the Set into a string representation.
    @ret string A string representation of the Set.
    !]]
    __tostring = function(this, cdat)--TODO allow table serialization
        local sRet = "{";

        for nIndex, vItem in pairs(cdat.pro.indexed) do
            sRet = sRet..tostring(vItem)..", ";
        end

        return sRet:sub(1, #sRet - 2).."}";
    end,
},
{--static public
    --[[!
    @mod Set
    @func Set.deserialize
    @scope static public
    @desc Deserializes the Set object from a string.
    !]]
    deserialize = function(this, cdat)
        return "ERROR: Set.deserialize method still in development.";
    end,
},
{},--private
{--protected
    indexed = {},
    set		= {},
    size 	= 0,
    --[[!
        @module Set
        @func addItem
        @scope protected
        @desc Adds an item to the Set.
        @param Set oSet The Set upon which to operate.
        @param table cdat The instance class data table.
        @param any vItem The item to add to the Set.
        @ret boolean True if the item was added successfully, false otherwise.
    !]]
    addItem = function(this, cdat, vItem)
        local bRet = false;

        if (rawtype(vItem) == "nil") then
            error("Error adding item to Set. Nil value given.", 3);
        end

        if (not cdat.pro.set[vItem]) then
            cdat.pro.set[vItem] 		    = true;
            cdat.pro.size 				    = cdat.pro.size + 1;
            cdat.pro.indexed[cdat.pro.size] = vItem;

            bRet = true;
        end


        return bRet;
    end,
    --[[!
        @module Set
        @func removeItem
        @scope protected
        @desc Removes an item from the Set.
        @param Set oSet The Set upon which to operate.
        @param table cdat The instance class data table.
        @param any vItem The item to remove from the Set.
        @ret boolean True if the item was removed successfully, false otherwise.
    !]]
    removeItem = function(this, cdat, vItem)
        local bRet = false;

        if (rawtype(vItem) == "nil") then
            error("Error removing item from Set. Nil value given.", 3);
        end

        if (cdat.pro.set[vItem] ~= nil) then
            cdat.pro.set[vItem] = nil;

            for x = 1, cdat.pro.size do

                if (cdat.pro.indexed[x] == vItem) then
                    table.remove(cdat.pro.indexed, x);
                    break;
                end

            end

            cdat.pro.size = cdat.pro.size - 1;

            bRet = true;
        end

        return bRet;
    end,
},
{--public
    --[[!
    @module Set
    @func Set
    @scope public
    @param table|nil A table of items to add to the Set (optional).
    @desc Constructs a new Set object.
    !]]
    Set = function(this, cdat, tItems)

        if (type(tItems) == "table") then

            for _, vItem in pairs(tItems) do
                cdat.pro.addItem(vItem);
            end

        end

    end,


    --[[!
    @module Set
    @desc Provides a Set data structure implementation in Lua.
    @func Set.add
    @scope public
    @desc Adds an item to the Set.
    @param any vItem The item to add to the Set.
    @ret Set The Set object after adding the item.
    !]]
    add = function(this, cdat, vItem)
        cdat.pro.addItem(vItem);
        return this;
    end,


    --[[!
    @module Set
    @func Set.clear
    @scope public
    @desc Removes all items from the Set.
    @ret Set The Set object after adding the item.
    !]]
    clear = function(this, cdat)
        cdat.pro.indexed = {};
        cdat.pro.set 	 = {};
        cdat.pro.size 	 = 0;

        return this;
    end,


    --[[!
    @module Set
    @func Set.contains
    @scope public
    @desc Checks if the Set contains a specific item.
    @param any vItem The item to check for.
    @ret boolean Returns true if the Set contains the item, false otherwise.
    !]]
    contains = function(this, cdat, vItem)
        return cdat.pro.set[vItem] ~= nil;
    end,


    --[[!
    @module Set
    @func Set.importSet
    @scope public
    @desc Adds all items from another Set to this Set.
    @param Set oOther The other Set containing items to add.
    @ret Set This Set object after adding the items found in the other Set.
    !]]
    importSet = function(this, cdat, other)
        local sOtherError   = "Error in Set class, method, ${method}. Attempt to operate on non-Set value of type ";
        assert(type(other) == "Set", sOtherError % {method = "addSet"}..type(other)..'.');
        local othercdat = cdat.ins[other];

        for nIndex, vItem in ipairs(othercdat.pro.indexed) do
            cdat.pro.addItem(vItem);
        end

        return this;
    end,


    --[[!
    @module Set
    @func Set.intersection
    @scope public
    @desc Returns the intersection of this Set with another Set.
    @param Set other The other Set with which to find the intersection.
    @ret Set A new Set containting values that intersect with this Set and the other Set.
    !]]
    intersection = function(this, cdat, other)
        local sOtherError   = "Error in Set class, method, ${method}. Attempt to operate on non-Set value of type ";
        assert(type(other) == "Set", sOtherError % {method = "intersection"}..type(other)..'.');
        local oRet      = Set();
        local newcdat   = cdat.ins[oRet];
        local othercdat = cdat.ins[other];

        for nIndex, vItem in pairs(cdat.pro.indexed) do

            if (rawtype(othercdat.pro.set[vItem]) ~= "nil") then
                newcdat.pro.addItem(vItem);
            end

        end

        return oRet;
    end,


    --[[!
    @module Set
    @func Set.isEmpty
    @scope public
    @desc Checks if the Set is empty.
    @ret boolean Returns true if the Set is empty, false otherwise.
    !]]
    isEmpty = function(this, cdat)
        return cdat.pro.size < 1;
    end,


    --[[!
    @module Set
    @func Set.isSubset
    @scope public
    @desc Checks if the input Set a subset of this Set.
    @param Set other The other Set to detemine subsetness.
    @ret boolean Returns true if the other Set is a subset of this Set, false otherwise.
    !]]
    isSubSet = function(this, cdat, other)--TODO use cdat
        local sOtherError   = "Error in Set class, method, ${method}. Attempt to operate on non-Set value of type ";
        assert(type(other) == "Set", sOtherError % {method = "isSubset"}..type(other)..'.');--TODO make this work children
        local bRet = true;
        local othercdat = cdat.ins[other];

        for nIndex, vItem in pairs(cdat.pro.indexed) do

            if (rawtype(othercdat.pro.set[vItem]) == "nil") then
                bRet = false;
                break;
            end

        end

        return bRet;
    end,


    --[[!
    @module Set
    @func Set.remove
    @scope public
    @desc Removes an item from the Set if it exists.
    @param any vItem The item to remove from the Set.
    @ret Set Returns the Set object after removing the item.
    !]]
    remove = function(this, cdat, vItem)
        removeItem(cdat, vItem);
        return this;
    end,


    --[[!
    @module Set
    @func Set.purgeSet
    @scope public
    @desc Removes all items from this Set that are present in another Set.
    @param Set other The other Set containing items to remove.
    @ret Set This Set object after removing items found in the other Set.
    !]]
    purgeSet = function(this, cdat, other)
        local sOtherError   = "Error in Set class, method, ${method}. Attempt to operate on non-Set value of type ";
        assert(type(other) == "Set", sOtherError % {method = "removeSet"}..type(other)..'.');
        local othercdat = cdat.ins[other];
        local indexedCopy = {table.unpack(cdat.pro.indexed)}

        for nIndex, vItem in pairs(indexedCopy) do

            if (othercdat.pro.set[vItem]) then
                removeItem(cdat, vItem);
            end

        end

        return this;
    end,


    --[[!
    @mod Set
    @func Set.serialize
    @scope public
    @desc Serializes the Set object to a string.
    @ret string A string representing the Set object which can be stored and later deserialized.
    !]]
    serialize = function(this, cdat)
        return "ERROR: Set.serialize method still in development.";
    end,


    --[[!
    @module Set
    @func Set.size
    @scope public
    @desc Returns the number of items in the Set (Same as #MySet).
    @ret number The number of items in the Set.
    !]]
    size = function(this, cdat)
        return cdat.pro.size;
    end,
},
nil,
false,
nil);
