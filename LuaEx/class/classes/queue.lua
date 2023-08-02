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
	__len = function(args, this)--doesn't work in < Lua v5.2
		return args[nPri].count;
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
	queue = function(this, args)
		local pri = args[nPri];

		pri.count 	= 0;
		pri.values 	= {};
   end,

	enqueue = function(this, args)
		local pri = args[nPri];

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


	dequeue = function(this, args)
		local vRet = nil;
		local pri = args[nPri];

		if (pri.count > 0) then
			vRet = table.remove(pri.values, 1);
			pri.count = pri.count - 1;
		end

		return vRet;
	end,


	size = function(this, args)
		return args[nPri].count;
	end,


	values = function(this, args)
		local tRet = {};
		local pri = args[nPri];

		for nIndex = 1, pri.count do
			tRet[nIndex] = pri.values[nIndex];
		end

		return tRet;
	end,
});
