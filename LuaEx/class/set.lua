local pairs = pairs;
local table = table;

return class("set",
{--metamethods
	__call = function(this, spro, pri, pro, pub)
	   local nIndex = 0
	   local nMax = pri.size;

	   return function ()
	      nIndex = nIndex + 1;

	      if (nIndex <= nMax) then
	         return pri.indexed[nIndex];
	      end

	   end

   end,

	__tostring = function(this, spro, pri, pro, pub)
		local sRet = "{";

		--for item in this() do
		--	sRet = sRet..tostring(item)..", ";
		--end

		return sRet:sub(1, #sRet - 2).."}";
	end
},
{},--static protected
{},--static public
{--private
	indexed = {},
	set		= {},
	size 	= 0,

	addItem = function(this, spro, pri, pro, pub, vItem)
		local bRet = false;

		if (pri.set[vItem] == nil) then
			pri.set[vItem] 			= true;
			pri.size 				= pri.size + 1;
			pri.indexed[pri.size] 	= vItem;

			bRet = true;
		end

		return bRet;
	end,

	removeItem = function(this, spro, pri, pro, pub, vItem)
		local bRet = false;

		if (pri.set[vItem] ~= nil) then
			pri.set[vItem] = nil;

			for x = 1, pri.size do

				if (pri.indexed[x] == vItem) then
					table.remove(pri.indexed, x);
					break;
				end

			end

			pri.size = pri.size - 1;

			bRet = true;
		end

		return bRet;
	end,

},
{},--protected
{--public
	set = function(this, spro, pri, pro, pub)
		pri.indexed = {};
		pri.set		= {};
		pri.size 	= 0;
	end,

	add = function(this, spro, pri, pro, pub, vItem)
		return pri.addItem(vItem);
	end,

	addSet = function(this, spro, pri, pro, pub, oOther)

		for item in oOther() do
			pri.addItem(item);
		end

	end,

	clear = function(this, spro, pri, pro, pub)
		pri.indexed = {};
		pri.set 	= {};
		pri.size 	= 0;

	end,

	complement = function(this, spro, pri, pro, pub, oOther)
		local oRet = set();

		for item in oOther() do

			if not (this:contains(item)) then
				oRet:add(item);
			end

		end

		return oRet;
	end,

	contains = function(this, spro, pri, pro, pub, vItem)
		return pri.set[vItem] ~= nil;
	end,

	equals = function(this, spro, pri, pro, pub, oOther)
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

	intersection = function(this, spro, pri, pro, pub, oOther)
		local oRet = set();

		for item in this() do

			if (oOther:contains(item)) then
				oRet:add(item)
			end

		end

		return oRet;
	end,

	isempty = function(this, spro, pri, pro, pub)
		return tSets[this].size < 1;
	end,

	issubset = function(this, spro, pri, pro, pub, oOther)
		local bRet = true;

		for item in this() do

			if not (oOther:contains(item)) then
				bRet = false;
				break;
			end

		end

		return bRet;
	end,

	remove = function(this, spro, pri, pro, pub, vItem)
		return pri.removeItem(vItem);
	end,

	removeset = function(this, spro, pri, pro, pub, oOther)

		for item in oOther() do
			pri.removeItem(item);
		end

		return this;
	end,

	size = function(this, spro, pri, pro, pub)
		return pri.size;
	end,

	totable = function(this, spro, pri, pro, pub)--do i need this one?

	end,

	union = function(this, spro, pri, pro, pub, oOther)
		local oRet = set();

		for item in this do
			oRet:add(item);
		end

		for item in oOther do
			oRet:add(item);
		end

		return oRet;
	end,
});
