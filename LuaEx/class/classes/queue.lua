--localization
local assert 		= assert;
local class 		= class;
local deserialize	= deserialize;
local rawtype		= rawtype;
local serialize		= serialize;
local table			= table;
local type 			= type;

return class("queue",
{--metamethods
	__len = function(this, cdat)
		return cdat.pri.count;
	end,

    __unm = function(this, cdat)
        cdat.pri.count  = 0;
        cdat.pri.values = {};
    end,

    __bnot = function(this, cdat) --TODO make this reverse the order of things

    end,
},
{},--static public
{--private
	count  = 0,
	values = {},
},
{},--protected
{--public
	queue = function(this, cdat)
		--local pri = args[nPri];

		--cdat.pri.count 	= 0;
		--cdat.pri.values = {};
   end,

	enqueue = function(this, cdat, vValue)

		if (rawtype(vValue) ~= "nil") then
			table.insert(cdat.pri.values, #cdat.pri.values + 1, vValue);
			cdat.pri.count = cdat.pri.count + 1;
			return vValue;
		end

	end,

	--[[destroy = function(this)
		tQueues[this] = nil;
		this = nil;
	end,]]

	dequeue = function(this, cdat)
		local vRet = nil;

		if (cdat.pri.count > 0) then
			vRet = table.remove(cdat.pri.values, 1);
			cdat.pri.count = cdat.pri.count - 1;
		end

		return vRet;
	end,

	size = function(this, cdat)
		return cdat.pri.count;
	end,

	values = function(this, cdat)
		local tRet = {};

		for nIndex = 1, cdat.pri.count do
			tRet[nIndex] = cdat.pri.values[nIndex];
		end

		return tRet;
	end,
},
nil, nil, false);
