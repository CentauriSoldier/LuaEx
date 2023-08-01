local pairs = pairs;
local table = table;
local nSpro	= class.args.staticprotected;
local nPri 	= class.args.private;
local nPro 	= class.args.protected;
local nPub 	= class.args.public;
local nIns	= class.args.instances;

return class("set",
{--metamethods
	__call = function(args, this)
		local pri = args[nPri];
	   	local nIndex = 0;
	   	local nMax = pri.size;

		return function ()
	    	nIndex = nIndex + 1;

			if (nIndex <= nMax) then
				return pri.indexed[nIndex];
			end

		end

   end,

	__tostring = function(args, this)
		local sRet = "{";
		local pri = args[nPri];

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

	addItem = function(this, args, vItem)
		local bRet = false;
		local pri = args[nPri];

		if (pri.set[vItem] == nil) then
			pri.set[vItem] 			= true;
			pri.size 				= pri.size + 1;
			pri.indexed[pri.size] 	= vItem;

			bRet = true;
		end

		return bRet;
	end,

	removeItem = function(this, args, vItem)
		local bRet = false;
		local pri = args[nPri];

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
	set = function(this, args)
		local pri = args[nPri];

		pri.indexed = {};
		pri.set		= {};
		pri.size 	= 0;
	end,

	add = function(this, args, vItem)
		local pri = args[nPri];
		return pri.addItem(vItem);
	end,

	addSet = function(this, args, oOther)
		local pri = args[nPri];

		for item in oOther() do
			pri.addItem(item);
		end

	end,

	clear = function(this, args)
		local pri = args[nPri];

		pri.indexed = {};
		pri.set 	= {};
		pri.size 	= 0;

	end,

	complement = function(this, args, oOther)
		local oRet = set();

		for item in oOther() do

			if not (this:contains(item)) then
				oRet:add(item);
			end

		end

		return oRet;
	end,

	contains = function(this, args, vItem)
		return pri.set[vItem] ~= nil;
	end,

	equals = function(this, args, oOther)
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

	intersection = function(this, args, oOther)
		local oRet = set();

		for item in this() do

			if (oOther:contains(item)) then
				oRet:add(item)
			end

		end

		return oRet;
	end,

	isempty = function(this, args)
		return tSets[this].size < 1;
	end,

	issubset = function(this, args, oOther)
		local bRet = true;

		for item in this() do

			if not (oOther:contains(item)) then
				bRet = false;
				break;
			end

		end

		return bRet;
	end,

	remove = function(this, args, vItem)
		return pri.removeItem(vItem);
	end,

	removeset = function(this, args, oOther)

		for item in oOther() do
			pri.removeItem(item);
		end

		return this;
	end,

	size = function(this, args)
		return pri.size;
	end,

	totable = function(this, args)--do i need this one?

	end,

	union = function(this, args, oOther)
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
