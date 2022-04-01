local tStacks = {};

assert(type(class) == "function", "Error loading the rectangle class. It depends on class.");
assert(type(serialize) 		== "table", 	"Error loading the pot class. It depends on serialize.");
assert(type(deserialize)	== "table", 	"Error loading the pot class. It depends on deserialize.");

--localization
local assert 		= assert;
local class 		= class;
local serialize		= serialize;
local deserialize	= deserialize;
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

		if (tStacks[this][1]) then
			vRet = table.remove(tStacks[this].values, 1);
			tStacks[this].count = tStacks[this].count - 1;
		end

		return vRet;
	end,

	push = function(this, vValue)
		assert(type(vValue) ~= "nil", "Error pushing item.\r\nValue cannot be nil.");
		table.insert(tStacks[this].values, 1, vValue);
		tStacks[this].count = tStacks[this].count + 1;
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
