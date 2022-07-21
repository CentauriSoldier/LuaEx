local tQueues = {};

--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class "queue" {

	 __construct = function(this, protected)
		tQueues[this] = {
			count 	= 0,
			values 	= {},
		};
	end,


	__len = function(this)--doesn't work in < Lua v5.2
		return tQueues[this].count;
	end,


	enqueue = function(this, vValue)

		if (rawtype(vValue) ~= "nil") then
			local tFields = tQueues[this];
			table.insert(tFields.values, #tFields.values + 1, vValue);
			tFields.count = tFields.count + 1;
			return vValue;
		end

	end,


	destroy = function(this)
		tQueues[this] = nil;
		this = nil;
	end,


	dequeue = function(this)
		local vRet = nil;

		if (tQueues[this].count > 0) then
			vRet = table.remove(tQueues[this].values, 1);
			tQueues[this].count = tQueues[this].count - 1;
		end

		return vRet;
	end,


	size = function(this)
		return tQueues[this].count;
	end,


	values = function(this)
		local tRet = {};

		for nIndex = 1, tQueues[this].count do
			tRet[nIndex] = tQueues[this].values[nIndex];
		end

		return tRet;
	end,
};
