--										🆃🆈🅿🅴 🅼🅴🆃🅰🆃🅰🅱🅻🅴🆂

--<<  🅱🅾🅾🅻🅴🅰🅽  >>
local tBooleanMeta = getmetatable(true) or true;

debug.setmetatable(tBooleanMeta, {
	__add = function(bLeft, bRight)
		return bLeft or bRight;
	end,
	__concat = function(vLeft, vRight)

		if (type(vLeft) == "boolean") then
			return tostring(vLeft)..vRight;
		else
			return vLeft..tostring(vRight);
		end

	end,
	__len = function(s)
		return s and 1 or 0;
	end,
	__mul = function(bLeft, bRight)
		return bLeft and bRight;
	end,
	__tostring = function(bVal)
		return (bVal and "true" or "false");
	end,
	__unm = function(bVal)
		return not bVal;
	end,
});


--<<  🅽🆄🅼🅱🅴🆁  >>
local tNumberMeta = getmetatable(0) or 0;
local sBlank = "";

debug.setmetatable(tNumberMeta, {
	__len = function(nVal)
		local bRet = nil;

		if (nVal == 1) then
			bRet = true;
		elseif (nVal == 0) then
			bRet = false;
		end

		return bRet;
	end,
	__tostring = function(bVal)
		return sBlank..(bVal)..sBlank;
	end,
});


--<< 🆂🆃🆁🅸🅽🅶 >>
--TODO CAN THIS BE OPTIIMIZE BY MAKING THE RETURNED FUNCTION LOCAL?
--http://lua-users.org/wiki/StringInterpolation
local tStringMeta = getmetatable("");
tStringMeta.__mod = function(s, tab) return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end)) end;


--										🆃🆈🅿🅴
local tLuaTypes = {
	["boolean"]		= true,
	["function"]	= true,
	["nil"] 		= true,
	["number"] 		= true,
	["string"] 		= true,
	["table"] 		= true,
	["thread"] 		= true,
	["userdata"] 	= true,
};

--'immutable' table of stock LuaEx types
local tLuaExTypes = {
	class 				= true,
	clausum				= true,
	constant			= true,
	enum 				= true,
	null 				= true,
	struct				= true,
	factory_constructor = true,
};

--user can add/remove the items in this table
local tUserTypes = {};

--store the original type funcion
local __type__ = type;
type = nil;

local type = {
	mathchesonlyleft = function(sLeftType, sRightType, sTypeInQuestion)
		return (sLeftType == sObjType and sRightType ~= sTypeInQuestion);
	end,
	mathchesonlyright = function(sLeftType, sRightType, sTypeInQuestion)
		return (sLeftType ~= sObjType and sRightType == sTypeInQuestion);
	end,
	mathchesboth = function(sLeftType, sRightType, sTypeInQuestion)
		return (sLeftType == sObjType and sRightType == sTypeInQuestion);
	end,
	full = function(vObject)
		local sType = __type__(vObject);
		local sSpace = "";

		if (sType == "table") then
			local tMeta = getmetatable(vObject);

			if (__type__(tMeta) == "table") then

				if (__type__(tMeta.__type) == "string") then
					sType = tMeta.__type;
					sSpace = " ";
				end

				if (__type__(tMeta.__subtype) == "string") then
					sType = (sType ~= "table" and sType or "")..sSpace..tMeta.__subtype;
				end

			end

		end

		return sType;
	end,
	getall = function()
		local tRet 	= {};

		for sType, _ in pairs(tLuaTypes) do
			tRet[#tRet + 1] = sType;
		end

		for sType, _ in pairs(tLuaExTypes) do
			tRet[#tRet + 1] = sType;
		end

		for sType, _ in pairs(tUserTypes) do
			tRet[#tRet + 1] = sType;
		end

		table.sort(tRet);
		return tRet;
	end,
	getlua = function()
		local tRet 	= {};

		for sType, _ in pairs(tLuaTypes) do
			tRet[#tRet + 1] = sType;
		end

		table.sort(tRet);
		return tRet;
	end,
	getluaex = function()
		local tRet 	= {};

		for sType, _ in pairs(tLuaExTypes) do
			tRet[#tRet + 1] = sType;
		end

		table.sort(tRet);
		return tRet;
	end,
	getuser = function()
		local tRet 	= {};

		for sType, _ in pairs(tUserTypes) do
			tRet[#tRet + 1] = sType;
		end

		table.sort(tRet);
		return tRet;
	end,
	raw = __type__,
	set = function(tInput, sType)

		if (rawtype(tInput) == "table" and type(sType) == "string")then
			--look for an existing meta table and get its type
			local tMeta 	= getmetatable(tInput);
			local sMetaType = rawtype(tMeta);
			local bIsTable 	= sMetaType == "table";

			if (bIsTable or sMetaType == "nil") then
				tMeta = bIsTable and tMeta or {};
				tMeta.__type = sType;
				setmetatable(tInput, tMeta);
				--record the new type
				type[sType] = true;
				return tInput;
			end

			return tInput;
		end

	end,
	setsub = function(tInput, sType)

		if (rawtype(tInput) == "table" and type(sSubType) == "string")then
			--look for an existing meta table and get its type
			local tMeta 	= getmetatable(tInput);
			local sMetaType = rawtype(tMeta);
			local bIsTable = sMetaType == "table";

			if (bIsTable or sMetaType == "nil") then
				tMeta = bIsTable and tMeta or {};
				tMeta.__subtype = sSubType;
				setmetatable(tInput, tMeta);
				return tInput;
			end

			return tInput;
		end

	end,
	sub = function(vObject)
		local sType = "nil";

		if (__type__(vObject) == "table") then
			local tMeta = getmetatable(vObject);

			if (__type__(tMeta) == "table" and __type__(tMeta.__subtype) == "string") then
				sType = tMeta.__subtype;
			end

		end

		return sType;
	end,
	x = function(vObject)
		local sType = __type__(vObject);

		if (sType == "table") then
			local tMeta = getmetatable(vObject);

			if (__type__(tMeta) == "table") then

				if (__type__(tMeta.__type) == "string") then

					if (tLuaExTypes[tMeta.__type] 		or 									--luaex type
						tMeta.__type:find("struct ") 	or tMeta.__type:find(" struct") or 	--custom struct
						tMeta.__is_luaex_class			or 									--custom class
						vObject["enum"]) then --custom enum
						sType = tMeta.__type;
					end

				end

			end

		end

		return sType;
	end,
};

local function newindex(t, k, v)

	if (__type__(k) == "string") then

		--add the new type
		if (v) then
			tUserTypes[k] = true;

			rawset(type, "is"..k, function(vVal)
				return type(vVal) == k;
			end);

		--remove the type
		else

			if (tUserTypes[k]) then
				tUserTypes[k] = nil;
				rawset(type, "is"..k, nil);
			end

		end

	end

end

--aliases for ease-of use
rawtype 	= type.raw;
xtype 		= type.x;
fulltype	= type.full;
subtype 	= type.sub;
settype		= type.set;
setsubtype	= type.setsub;

--setup the 'is' functions for all types
for sType, _ in pairs(tLuaTypes) do
	rawset(type, "is"..sType, function(vVal)
		return __type__(vVal) == sType;
	end);
end

for sType, _ in pairs(tLuaExTypes) do
	rawset(type, "is"..sType, function(vVal)
		return type(vVal) == sType;
	end);
end

for sType, _ in pairs(tUserTypes) do
	rawset(type, "is"..sType, function(vVal)
		return type(vVal) == sType;
	end);
end

--rework the type system
setmetatable(type,
{
	__call = function(t, vObject)
		local sType = __type__(vObject);

		local tMeta = getmetatable(vObject);

		if (__type__(tMeta) == "table" and __type__(tMeta.__type) == "string") then
			sType = tMeta.__type;
		end

		return sType;
	end,
	__type = "function",
	--[[__index = function()
		error("Attempt to index a function value.", 2);
	end,]]
	__newindex = newindex,
});

return type;
