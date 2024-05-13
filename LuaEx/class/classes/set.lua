local pairs = pairs;
local table = table;

return class("set",
{--metamethods
	__call = function(this, cdat)
        local nIndex = 0;
	   	local nMax = cdat.pri.size;

		return function ()
	    	nIndex = nIndex + 1;

			if (nIndex <= nMax) then
				return cdat.pri.indexed[nIndex];
			end

		end

   end,

	__tostring = function(this, cdat)
		local sRet = "{";

		for item in this() do
			sRet = sRet..tostring(item)..", ";
		end

		return sRet:sub(1, #sRet - 2).."}";
	end,

    __len = function(this, cdat)
       return cdat.pri.size;
   end,

   __unm = function(this, cdat)
       cdat.pri.indexed = {};
   	   cdat.pri.set		= {};
   	   cdat.pri.size 	= 0;
   end,
},
{},--static public
{--private
	indexed = {},
	set		= {},
	size 	= 0,

	addItem = function(this, cdat, vItem)
		local bRet = false;

		if (cdat.pri.set[vItem] == nil) then
			cdat.pri.set[vItem] 		       = true;
			cdat.pri.size 				       = cdat.pri.size + 1;
			cdat.pri.indexed[cdat.pri.size] = vItem;

			bRet = true;
		end

		return bRet;
	end,

	removeItem = function(this, cdat, vItem)
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
	end,

},
{},--protected
{--public
	set = function(this, cdat)

	end,

	add = function(this, cdat, vItem)
		return cdat.pri.addItem(vItem);
	end,

	addSet = function(this, args, oOther)

        for item in oOther() do
			cdat.pri.addItem(item);
		end

	end,

	clear = function(this, cdat)
		cdat.pri.indexed = {};
		cdat.pri.set 	 = {};
		cdat.pri.size 	 = 0;
	end,

	complement = function(this, cdat, oOther)
		local oRet = set();

		for item in oOther() do

			if not (this:contains(item)) then
				oRet:add(item);
			end

		end

		return oRet;
	end,

	contains = function(this, cdat, vItem)
		return cdat.pri.set[vItem] ~= nil;
	end,

	equals = function(this, cdat, oOther)
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

	isempty = function(this, cdat)
		return cdatpri.pri.size < 1;
	end,

	issubset = function(this, cdat, oOther)
		local bRet = true;

		for item in this() do

			if not (oOther:contains(item)) then
				bRet = false;
				break;
			end

		end

		return bRet;
	end,

	remove = function(this, cdat, vItem)
		return cdat.pri.removeItem(vItem);
	end,

	removeset = function(this, cdat, oOther)

		for item in oOther() do
			cdat.pri.removeItem(item);
		end

		return this;
	end,

	size = function(this, cdat)
		return cdat.pri.size;
	end,

	totable = function(this, cdat)--do i need this one?

	end,

	union = function(this, cdat, oOther)
		local oRet = set();

		for item in this do
			oRet:add(item);
		end

		for item in oOther do
			oRet:add(item);
		end

		return oRet;
	end,
}, nil, nil, false);
