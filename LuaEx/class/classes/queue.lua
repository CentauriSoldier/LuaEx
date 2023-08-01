--local tQueues = {};

--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;
local nSpro			= class.args.staticprotected;
local nPri 			= class.args.private;
local nPro 			= class.args.protected;
local nPub 			= class.args.public;
local nIns			= class.args.instances;

return class("queue",
{--metamethods
	__len = function(spro, pri, pro, pub, this)--doesn't work in < Lua v5.2
		return pri.count;
	end,
},
{},--static protected
{},--static public
{--private
	count,
	values,
},
{},--protected
{--public
	queue = function(this, spro, pri, pro, pub)
		pri.count 	= 0;
		pri.values 	= {};
   end,

	enqueue = function(this, spro, pri, pro, pub, vValue)

		if (rawtype(vValue) ~= "nil") then
			table.insert(pri.values, #pri.values + 1, vValue);
			pri.count = pri.count + 1;
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
