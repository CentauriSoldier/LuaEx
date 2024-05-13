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
    --__call TODO make iterator
	 __len = function(this, cdat)
		return cdat.pri.count;
	end,

    __unm = function(this, cdat)
        cdat.pri.count  = 0;
        cdat.pri.values = {};
    end,

    __bnot = function(this, cdat) --TODO make this reverse the order of things

    end,

    __shl = function(this, other, cdat) --same as push

        if (rawtype(other) ~= "nil") then
			table.insert(cdat.pri.values, 1, other);
			cdat.pri.count = cdat.pri.count + 1;
		end

    end,

    __shr = function(this, other, cdat) --same as pop

        if (rawtype(cdat.pri.values[1]) ~= "nil") then
			vRet = table.remove(cdat.pri.values, 1);
			cdat.pri.count = cdat.pri.count - 1;
		end

		return vRet;
    end,
},
{bugs = 45,},--"JKAHSDUIYIQWUHEDIUY(@#*#)"},--static public TODO static public is not working
{--private
	count  = 0,
	values = {},
},
{},--protected
{--public
	stack = function(this, cdat)

   end,

	--TODO complete serialization
	deserialize = function(this, cdat)

	end,


--[[	destroy = function(this, spro, pri, pro, pub)
		tQueues[this] = nil;
		this = nil;
	end,
]]

	pop = function(this, cdat)

		if (rawtype(cdat.pri.values[1]) ~= "nil") then
			vRet = table.remove(cdat.pri.values, 1);
			cdat.pri.count = cdat.pri.count - 1;
		end

		return vRet;
	end,


	push = function(this, cdat, vValue)

		if (rawtype(vValue) ~= "nil") then
			table.insert(cdat.pri.values, 1, vValue);
			cdat.pri.count = cdat.pri.count + 1;
		end

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
}, nil, nil, false);
