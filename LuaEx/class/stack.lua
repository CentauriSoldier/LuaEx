--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class("stack",
{--metamethods
	 __len = function(this, spro, pri, pro, pub)--doesn't work in < Lua v5.2
		return pri.count;
	end,
},
{},--static protected
{bug = 5},--static public
{
	count,
	values,
},--private
{},--protected
{--public
	stack = function(this, spro, pri, pro, pub)
		   pri.count 	= 0;
		   pri.values	= {};
   end,

	--TODO complete serialization
	deserialize = function(this, spro, pri, pro, pub)

	end,


--[[	destroy = function(this, spro, pri, pro, pub)
		tQueues[this] = nil;
		this = nil;
	end,
]]

	pop = function(this, spro, pri, pro, pub)

		if (rawtype(pri.values[1]) ~= "nil") then
			vRet = table.remove(pri.values, 1);
			pri.count = pri.count - 1;
		end

		return vRet;
	end,


	push = function(this, spro, pri, pro, pub, vValue)

		if (rawtype(vValue) ~= "nil") then
			table.insert(pri.values, 1, vValue);
			pri.count = pri.count + 1;
		end

		return this;
	end,


	size = function(this, spro, pri, pro, pub)
		return pri.count;
	end,


	values = function(this, spro, pri, pro, pub)
		local tRet = {};

		for nIndex = 1, pri.count do
			tRet[nIndex] = pri.values[nIndex];
		end

		return tRet;
	end,
});
