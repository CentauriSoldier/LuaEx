--NOTE: DONT LOCALIZE null. Strange things happen...
local type 			= type;
local setmetatable 	= setmetatable;

local function dummy() end

local function eq(l, r)
	return type(l) == type(r)
end


local function index(t, k)
	return null;
end


local function le(l, r)
	local sLType = type(l);
	local sRType = type(r);
	return (sLType == "null" and sRType ~= "nil") or (sLType == sRType);
end


local function len()
	return 0;
end


local function lt(l, r)
	local sRType = type(r);
	return type(l) == "null" and sRType ~= "null" and sRType ~= "nil";
end


local function nullval() return null; end


local function tostr()
	return "null";
end

return setmetatable({
	serialize = function()
		return "null";
	end,
},
{
	__add 		= nullval,
	__band 		= nullval,
	__bor 		= nullval,
	__bnot 		= nullval,
	__bxor 		= nullval,
	__call 		= dummy,
	__close 	= false,
	__concat	= nullval,
	__div		= nullval,
	__eq 		= eq,
	__gc		= false,
	__idiv		= nullval,
	__index 	= index,
	__ipairs	= nullval,
	__le		= le,
	__len 		= len,
	__lt		= lt,
	__mod		= nullval,
	--__mode,
	--__metatable	= nil,
	__mul		= nullval,
	__name		= "null",
	__newindex 	= dummy,
	__pairs		= nullval,
	__pow		= nullval,
	__shl  		= nullval,
	__shr  		= nullval,
	__sub		= nullval,
	__subtype	= "null",
	__tostring	= tostr,
	__type		= "null",
	__unm		= nullval,
});
