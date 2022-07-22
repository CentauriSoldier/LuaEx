local tStacks = {};

--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class "stack" {

	 __construct = function(this)
		tStacks[this] = {
			count 	= 0,
			values	= {},
		};
	end,


	__len = function(this)--doesn't work in < Lua v5.2
		return tStacks[this].count;
	end,

	--TODO complete serialization
	deserialize = function()

	end,


	destroy = function(this)
		tQueues[this] = nil;
		this = nil;
	end,


	pop = function(this)
		local vRet = nil;
		local tFields = tStacks[this];

		if (rawtype(tFields.values[1]) ~= "nil") then
			vRet = table.remove(tFields.values, 1);
			tFields.count = tFields.count - 1;
		end

		return vRet;
	end,


	push = function(this, vValue)

		if (rawtype(vValue) ~= "nil") then
			local tFields = tStacks[this];
			table.insert(tFields.values, 1, vValue);
			tFields.count = tFields.count + 1;
		end

		return this;
	end,


	size = function(this)
		return tStacks[this].count;
	end,


	values = function(this)
		local tRet = {};

		for nIndex = 1, tStacks[this].count do
			tRet[nIndex] = tStacks[this].values[nIndex];
		end

		return tRet;
	end,
};
