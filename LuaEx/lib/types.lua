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


--since LuaEx hooks the type function,
--this is an alias to preserve the original
rawtype = type;
local __type__ = rawtype;

--'immutable' table of stock LuaEx types
local tLuaExTypes = {
	class 				= true,
	constant			= true,
	enum 				= true,
	null 				= true,
	struct				= true,
	factory_constructor = true,
};

--user can add/remove the items in this table
local tUserTypes = {};


function fulltype(vObject)
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
				sType = tMeta.__subtype..sSpace..(sType ~= "table" and sType or "");
			end

		end

	end

	return sType;
end


function subtype(vObject)
	local sType = "nil";

	if (__type__(vObject) == "table") then
		local tMeta = getmetatable(vObject);

		if (__type__(tMeta) == "table" and __type__(tMeta.__subtype) == "string") then
			sType = tMeta.__subtype;
		end

	end

	return sType;
end


function type(vObject)
	local sType = __type__(vObject);

	--if (sType == "table") then
		local tMeta = getmetatable(vObject);

		if (__type__(tMeta) == "table" and __type__(tMeta.__type) == "string") then
			sType = tMeta.__type;
		end

	--end

	return sType;
end



function xtype(vObject)
	local sType = __type__(vObject);

	if (sType == "table") then
		local tMeta = getmetatable(vObject);

		if (__type__(tMeta) == "table") then

			if (__type__(tMeta.__type) == "string") then

				if (tLuaExTypes[tMeta.__type] or tMeta.__type:find("struct ") or tMeta.__type:find(" struct") or tMeta.__is_luaex_class) then
					sType = tMeta.__type;
				end

			end

		end

	end

	return sType;
end


function gettypes()
	local tRet 	= {};

	for sType, _ in pairs(tLuaExTypes) do
		tRet[#tRet + 1] = sType;
	end

	for sType, _ in pairs(tUserTypes) do
		tRet[#tRet + 1] = sType;
	end

	table.sort(tRet);
	return tRet;
end


function getluaextypes()
	local tRet 	= {};

	for sType, _ in pairs(tLuaExTypes) do
		tRet[#tRet + 1] = sType;
	end

	table.sort(tRet);
	return tRet;
end


function getusertypes()
	local tRet 	= {};

	for sType, _ in pairs(tUserTypes) do
		tRet[#tRet + 1] = sType;
	end

	table.sort(tRet);
	return tRet;
end

--[[
function addtype(sType)

	if (__type__(sType) == "string") then
		tUserTypes[sType] = true;
	end

end


function removetype(sType)

	if (__type__(sType) == "string") then
		tUserTypes[sType] = nil;
	end

end
WHAT's the purpose of user types declared here?

]]

--function isenum(v)
--	return type(v) == "";
--end

--function isstruct(v)
--	return rawtype(v) == "";
--end
--function
--thread
--TODO create a repo of types (allow additions/ removals) then create these functions as the types are add (delete function on removal)
function isboolean(v)
	return type(v) == "boolean";
end

function isnil(v)
	return type(v) == "nil";
end

function isnull(v)
	return v == null;
end

function isnumber(v)
	return type(v) == "number";
end

function isstring(v)
	return rawtype(v) == "string";
end

function istable(v)
	return type(v) == "table";
end

function isuserdata(v)
	return type(v) == "userdata";
end
