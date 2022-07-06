local tSets = {};

local pairs = pairs;
local table = table;

local function addItem(this, vItem)
	local bRet = false;
	local oSet = tSets[this];

	if (oSet.set[vItem] == nil) then
		oSet.set[vItem] 		= true;
		oSet.size 				= oSet.size + 1;
		oSet.indexed[oSet.size] = vItem;

		bRet = true;
	end

	return bRet;
end

local function removeItem(this, vItem)
	local bRet = false;
	local oSet = tSets[this];

	if (oSet.set[vItem] ~= nil) then
		oSet.set[vItem] = nil;

		for x = 1, oSet.size do

			if (oSet.indexed[x] == vItem) then
				table.remove(oSet.indexed, x);
				break;
			end

		end

		oSet.size = oSet.size - 1;

		bRet = true;
	end

	return bRet;
end

function iterator (this)
   local nIndex = 0
   local nMax = tSets[this].size;

   return function ()
      nIndex = nIndex + 1

      if (nIndex <= nMax) then
         return tSets[this].indexed[nIndex];
      end

   end

end

local set = class "set" {

	__construct = function(this)
		tSets[this] = {
			indexed = {},
			set		= {},
			size 	= 0,
		};

		--create/reference the iterator function
		local tMeta = getmetatable(this);
		tMeta.__call = iterator;
		tMeta.__tostring = function(this)
			local sRet = "{";

			for item in this() do
				sRet = sRet..tostring(item)..", ";
			end

			return sRet:sub(1, #sRet - 2).."}";
		end
		--TODO create operator overrides for union, removal etc
	end,


	add = function(this, vItem)
		return addItem(this, vItem);
	end,

	addSet = function(this, oOther)

		for item in oOther() do
			addItem(this, item);
		end

	end,

	clear = function(this)
		tSets[this] = {
			indexed = {},
			set 	= {},
			size 	= 0,
		};
	end,

	complement = function(this, oOther)
		local oRet = set();

		for item in oOther() do

			if not (this:contains(item)) then
				oRet:add(item);
			end

		end

		return oRet;
	end,

	contains = function(this, vItem)
		return tSets[this].set[vItem] ~= nil;
	end,

	equals = function(this, oOther)
		local bRet = tSets[this]:size() == oOther:size();

		if (bRet) then

			for item in oOther() do

				if not (this:contains(item)) then
					bRet = false;
					break;
				end

			end

		end

		return bRet;
	end,

	intersection = function(this, oOther)
		local oRet = set();

		for item in this() do

			if (oOther:contains(item)) then
				oRet:add(item)
			end

		end

		return oRet;
	end,

	isempty = function(this)
		return tSets[this].size < 1;
	end,

	issubset = function(this, oOther)
		local bRet = true;

		for item in this() do

			if not (oOther:contains(item)) then
				bRet = false;
				break;
			end

		end

		return bRet;
	end,

	remove = function(this, vItem)
		return removeItem(this, vItem);
	end,

	removeset = function(this, oOther)

		for item in oOther() do
			removeItem(this, item);
		end

		return this;
	end,

	size = function(this)
		return tSets[this].size;
	end,

	totable = function(this)--do i need this one?

	end,

	union = function(this, oOther)
		local oRet = set();

		for item in this do
			oRet:add(item);
		end

		for item in oOther do
			oRet:add(item);
		end

		return oRet;
	end,
};

return set;
