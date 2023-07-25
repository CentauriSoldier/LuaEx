--local tQueues = {};

--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class("queue",
--metamethods
{
	__len = function(this)--doesn't work in < Lua v5.2
		return tQueues[this].count;
	end,
},
{},--static protected
{},--static public
{
	count 	= 0,
	values 	= {},
},--private
{},--protected
--public
{
	queue = function(this, spro, pri, pro, pub)

   end,

	enqueue = function(this, spro, pri, pro, pub, vValue)

		if (rawtype(vValue) ~= "nil") then
			local tFields = pri;
			table.insert(tFields.values, #tFields.values + 1, vValue);
			tFields.count = tFields.count + 1;
			return vValue;
		end

	end,


	--[[destroy = function(this)
		tQueues[this] = nil;
		this = nil;
	end,]]


	dequeue = function(this, spro, pri, pro, pub)
		local vRet = nil;
		local tFields = pri;

		if (pri.count > 0) then
			vRet = table.remove(pri.values, 1);
			pri.count = pri.count - 1;
		end

		return vRet;
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
