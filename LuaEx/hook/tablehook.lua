local assert 		= assert;
local getmetatable 	= getmetatable
local pairs			= pairs;
local rawtype 		= rawtype;
local setmetatable 	= setmetatable
local table 		= table;

--stores references to locked tables and their clones
local tLockedTableClones = {};


function table.clone(tInput, bIgnoreMetaTable)
	local tRet = {};

	--clone each item in the table
	if (rawtype(tInput) == "table") then

		for vIndex, vItem in pairs(tInput) do

			if (rawtype(vItem) == "table") then
				rawset(tRet, vIndex, table.clone(vItem));
			else
				rawset(tRet, vIndex, vItem);
			end

		end

		--clone the metatable
		if (not bIgnoreMetaTable) then
			local tMeta = getmetatable(tInput);

			if (type(tMeta) == "table") then
				setmetatable(tRet, tMeta);
			end

		end

	end

	return tRet;
end


function table.getindex(tTable, vElement)
	local nRet;

	for x, vExistingElement in pairs(tTable) do

		if (vElement == vExistingElement) then
			nRet = x;
			break;
		end

	end

	return nRet;
end


function table.lock(tInput)

	if (rawtype(tInput) == "table") then
		local tMeta 		= getmetatable(tInput);
		local sMetaType 	= rawtype(tMeta);
		local bMetaIsTable 	= sMetaType == "table";

		--throw an error if the table has a proteced metatable
		if (not (bMetaIsTable or sMetaType == "nil")) then
			error("Cannot lock a table which has a protected metatable.");
		end

		--check if this is an enum
		local bIsEnum = type(tInput) == "enum";

		--clone the original table before purging it
		local tData = table.clone(tInput);

		--store a reference to the clone (used for table.unlock)
		tLockedTableClones[tInput] = tData;

		--purge the original table
		table.purge(tInput);

		--now, check each entry in the input table for a table value
		for vKey, vValue in pairs(tData) do

			--be sure every other sub-table is locked as well
			if (rawtype(vValue) == "table") then
				table.lock(vValue);
			end

		end

		--clone the meta table or create a new one if not present
		if (not bIsEnum) then--do not modify enum subtable TODO do this for classes as well--also, allow a table of strings (types to be ignored) be input by the user
			local tNewMeta = bMetaIsTable and table.clone(tMeta) or {};

			--remove the old meta table if present
			if (bMetaIsTable) then
				table.purge(tMeta);
				setmetatable(tInput, nil);
			end

			--set the values for the new metatable
			tNewMeta.__newindex = function(t, k, v)
				error("Attempt to write to locked (read-only) table; Key: '"..tostring(k).."' ("..type(k)..") | Value: "..tostring(v).." ("..type(v)..").");
			end;
			tNewMeta.__LUAEX_OLD_METATABLE_STORAGE = tMeta; --store the table's old metatable
			tNewMeta.__index = bIsEnum and tNewMeta.__index or tData; --keep the __index metamethod if this is an enum

			--set the original (now-purged) table's meta table
			setmetatable(tInput, tNewMeta);

		end

		return tInput;
	end

end


function table.purge(tInput, bIgnoreMetaTable)

	if (rawtype(tInput) == "table") then

		--delete all the keys in the table
		for vKey, vValue in pairs(tInput) do

			--claer any subtables recursively
			if (rawtype(vValue) == "table") then
				table.purge(vValue);
			end

			--clear the item
			rawset(tInput ,vKey, nil);
		end

		--remove the metatable
		if (not bIgnoreMetaTable) then
			local tMeta = getmetatable(tInput);

			if (rawtype(tMeta) == "table") then
				table.purge(tMeta);
				setmetatable(tInput, nil);
			end

		end
		tInput = nil;
		return tInput;
	end

end


table.settype = type.set;
table.setsubtype = type.setsub;

--[[
function table.shuffle(tInput)
	assert(rawtype(tInput), "Input must be of type table.\nGot type "..rawtype(tInput)..".");
	local remove 		= table.remove;
	local tShuffle 		= {};
	local tIndexPool 	= {};

	--store the k, v pairs and create the index pool (tIndexPool)
	for k, v in pairs(tInput) do
		local nIndex = #tShuffle + 1;

		--keep track of the actual data
		tShuffle[nIndex] = {
			key 	= k,
			value 	= v,
		};

		--track the numeric index where the data is located
		tIndexPool[nIndex] = nIndex;
	end

	--clear the tInput table
	tInput = {};

	--count how many entries there are to shuffle
	local nPoolIndices = #tIndexPool;

	while nPoolIndices > 0 do
		--get the pool index to use
		local nPoolIndex 	= math.random(1, nPoolIndices);
		--get the actual data index
		local nDataIndex	= tIndexPool[nPoolIndex];
		--get the data
		local tData			= tShuffle[nDataIndex];
		--determine the data key
		--local vDataKey 		= rawtype(tData.key) ~= "number" and tData.key or #tInput + 1;
		--store the data
		rawset(tInput, tData.key, tData.value);
		--remove the index from the index pool
		remove(tIndexPool, nPoolIndex);
		--decrement the index pool count
		nPoolIndices = #tIndexPool;
	end

	--destroy the tShuffle and tIndexPool tables
	tShuffle	= nil;
	tIndexPool	= nil;

	return tInput;
end]]


function table.unlock(tInput)

	if (rawtype(tInput) == "table" and rawtype(tLockedTableClones[tInput]) == "table") then
		local bIsEnum = type(tInput) == "enum";

		--check each entry in the data table for a table value
		for vKey, vValue in pairs(tLockedTableClones[tInput]) do
			--store the key and value since they'll get wiped out if the value is a table
			local k = vKey;
			local v = vValue;

			--be sure every other sub-table is unlocked as well
			if (rawtype(vValue) == "table") then
				table.unlock(vValue);
			end

			--reset the item in the input table
			rawset(tInput, k, v);

			--delete the item in the clone table
			rawset(tLockedTableClones, tInput, nil);
		end

		if (not bIsEnum) then--do not modify enum subtable TODO do this for classes as well--also, allow a table of strings (types to be ignored) be input by the user

			--reset the table's metatable (if needed)
			local tMeta = getmetatable(tInput);
			--TODO do i really need to check for the existence of a metatable? Doesn't every cloned table have a meta table to prevent modifications?
			-- I think checking for the the __LUAEX_OLD_METATABLE_STORAGE value would be safe...
			if (rawtype(tMeta) == "table" and rawtype(tMeta.__LUAEX_OLD_METATABLE_STORAGE == "table")) then
				setmetatable(tInput, tMeta.__LUAEX_OLD_METATABLE_STORAGE);
			end

		end

		--delete the local references to the clone table (it's only reference)
		tLockedTableClones[tInput] = nil;

		return tInput;
	end

end

--TODO finish this.
function table.merge(tMergeInto, tToMergeFrom)

	if (rawtype(tMergeInto) == "table" and rawtype(tToMergeFrom) == "table") then

		for k, v in pairs(tToMergeFrom) do
			tMergeInto[k] = v;
		end

	end

	return tMergeInto;
end

--[[
--http://lua-users.org/wiki/SortedIteration
local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

]]

return table;
