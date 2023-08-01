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

return class("stack",
{--metamethods
	 __len = function(args, this)--doesn't work in < Lua v5.2
		return args[nPri].count;
	end,
},
{},--static protected
{bug = "JKAHSDUIYIQWUHEDIUY(@#*#)"},--static public
{--private
	count,
	values,
},
{},--protected
{--public
	stack = function(this, args)
			local pri = args[nPri];
			pri.count 	= 0;
			pri.values	= {};
   end,

	--TODO complete serialization
	deserialize = function(this, args)

	end,


--[[	destroy = function(this, spro, pri, pro, pub)
		tQueues[this] = nil;
		this = nil;
	end,
]]

	pop = function(this, args)
		local pri = args[nPri];

		if (rawtype(pri.values[1]) ~= "nil") then
			vRet = table.remove(pri.values, 1);
			pri.count = pri.count - 1;
		end

		return vRet;
	end,


	push = function(this, args, vValue)
		local pri = args[nPri];

		if (rawtype(vValue) ~= "nil") then
			table.insert(pri.values, 1, vValue);
			pri.count = pri.count + 1;
		end

		return this;
	end,


	size = function(this, args)
		local pri = args[nPri];
		return pri.count;
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
