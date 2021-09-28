--[[*
@authors Bas Groothedde at Imagine Programming
@copyright Public Domain
@description
	<h2>class</h2>
	<p></p>
@license <p>The Unlicense<br>
<br>
@moduleid class
@version 1.0
@versionhistory
<ul>
	<li>
		<b>1.0</b>
		<br>
		<p>Created the module.</p>
	</li>
</ul>
@website https://github.com/imagine-programming
*]]

-- quick and dirty print, but better
local oldPrint = print;
function print(...)
	local t = {};
	for _, v in ipairs { ... } do
		t[#t + 1] = tostring(v);
	end

	oldPrint(table.concat(t, "\t").."\r\n");
end;

local setmetatable	= setmetatable;
local getmetatable 	= getmetatable;
local assert 		= assert;

-- names of metamethods, should be treated as such
local metanames = {
	__add 		= true,
	__band		= true,
	__bnot		= true,
	__bor		= true,
	__bxor		= true,
	__close 	= true,
	__concat 	= true,
	__div 		= true,
	__eq 		= true,
	__gc 		= true,
	__idiv		= true,
	__index 	= true, -- special case, handled separately
	__le 		= true,
	__len		= true,
	__lt 		= true,
	__mod 		= true,
	__mode 		= true,
	__mul 		= true,
	__name 		= true,
	__newindex 	= true, -- special case, handled separately
	__pow 		= true,
	__shl 		= true,
	__shr 		= true,
	__sub 		= true,
	__tostring 	= true,
	__unm 		= true,
};

-- the generic class constructor, which also invokes your __construct method if it exists
local function class_ctor(class, ...)
	assert(type(class) == "class", "cannot construct, invalid class");
	local instance = setmetatable({}, getmetatable(class).__instance_mt);

	if (type(class.__construct) == "function") then
		class.__construct(instance, ...);
	end

	return instance;
end

-- class extender, i.e. when you do `class "test" : extends(other) {}`
local function class_extends(class, other)
	assert(type(class) == "iclass", "cannot extend, invalid class (needs to be intermediate): `" .. type(class) .. "`");
	assert(type(other) == "class",  "cannot extend, extension is not a class: `" .. type(other) .. "`");

	local mt = getmetatable(class);

	assert(not mt.__parent, "cannot extend twice in this current implementation");
	mt.__parent = other;

	for name, member in pairs(other) do
		class[name] = member;
	end

	return class;
end;


iTest = {
	MyFunction,
}
--todo implement children detection for this to work
local function class_implements(class, interface)



end

-- is_object returns true if `instance` is an object of a class
function is_object(instance)
	local mt = getmetatable(instance);
	return mt and type(mt.__class) == "class";
end

-- is_derived returns true if `class` is a derived class (a child) of `base`
function is_derived(class, base)
	if (class == base) then
		return true;
	end

	local mt = getmetatable(class)
	if (mt.__parent) then
		return is_derived(mt.__parent, base);
	end

	return false;
end

-- is_instance_of returns true if `object` is an instance of `base` or any of its derived classes.
-- It also returns true if `object` is in fact a class and it is derived from `base` (basically, is_derived)
function is_instance_of(object, base)
	assert(is_object(object) or type(object) == "class", "cannot determine base class of `" .. type(object) .. "`");

	if (type(object) == "class") then
		return is_derived(object, base);
	end

	local mt = getmetatable(object);
	if (mt and type(mt.__class) == "class") then
		return is_derived(mt.__class, base);
	end

	return false;
end

function get_base(class_object)
	local ret = class_object;

	local parent = getmetatable(class_object).__parent;

	while (parent) do
		ret = parent;
		parent = getmetatable(parent).__parent;
	end

	return ret;
end


function is_base(class_object)
	return getmetatable(class_object).__parent == nil;
end




-- define a new class
local function class(name)
	local class_meta   = { __type = name, __parent = nil };
	local class_object 	= {};

	--if (type(tLuaEx[name]) ~= "nil") then
	--	error("Attempt to overwrite protected item '"..tostring(name).."' ("..type(tLuaEx[name])..") with '"..tostring(name).."' ("..type(name)..").");
	--end

	-- first return an intermediate class, on which you still need to call
	-- with the method table. i.e. this is the stage that handles `class "name"`
	-- the returned object allows for `class "name" : extends(other)`
	return setmetatable(class_object, {
		__index = { extends = class_extends, implements = class_implements };
		__type  = "iclass"; 						-- intermediate class
		__call  = function(class_object, members)	-- the actual definer, this puts the class in _G and adds the methods (no longer puts it in _G...has been localized)
			-- add all methods to the class, possibly overloading members that were copied by `extends`
			for member_name, member in pairs(members) do
				class_object[member_name] = member;
			end

			-- for each present member in the class, see if we need to handle metamethods.
			-- these need to be placed in the class metatable
			for member_name, member in pairs(class_object) do
				if (metanames[member_name] and member_name ~= "__index" and member_name ~= "__newindex") then
					class_meta[member_name] = member;
				end
			end

			-- each class has a super method, which allows you to invoke the parent constructor
			-- i.e. in your __construct(this): `this:super(a, b, c)`
			class_object.super = function(instance, ...)
				local parent = getmetatable(class_object).__parent;
				if (parent and type(parent.__construct) == "function") then
					local current_mt = getmetatable(instance);
					parent.__construct(setmetatable(instance, getmetatable(parent).__instance_mt), ...);
					setmetatable(instance, current_mt);
					return;
				end
			end;

			-- keep track of the class object in its own metatable, this helps
			-- us with is_instance_of for example.
			class_meta.__class = class_object;

			--[[
				handle the __index metamethod separately, it is prioritized from high (1) to low (n)
				1. does the key exist in the class definition, return that
				2. does the class have an __index metamethod, invoke that

				if this does not occur, there is nothing to be found.
				this function is only called if [key] does not already exist in the object, so
				properties are already handled.
			]]
			class_meta.__index = function(object, key)
				local inclass = rawget(class_object, key);
				if (inclass) then
					return inclass;
				end

				local __index = rawget(class_object, "__index");
				if (type(__index) == "function") then
					return __index(object, key);
				end
			end;

			--[[
				similar to __index, __newindex is handled separately. It is also prioritized, in the same order.
				In this case, however, the property needs to be set to the object in the last case;

				1. does the key exist in the class definition, error; you cannot shadow method names
				2. does the class have a __newindex metamethod, invoke that and return
				3. set the value to the instance/object using [key] as its index
			]]
			class_meta.__newindex = function(object, key, value)
				local inclass = rawget(class_object, key);
				if (inclass) then
					error("setting the key `" .. tostring(key) .. "` would overwrite a method", 2);
				end

				local __newindex = rawget(class_object, "__newindex");
				if(type(__newindex) == "function")then
					__newindex(object, key, value);
					return;
				end

				rawset(object, key, value);
			end;

			-- export the class to global scope with a new metatable, now with the type "class".
			-- when called, you construct a new object of this class.
			return setmetatable(class_object, { __type = "class", __call = class_ctor, __instance_mt = class_meta, __parent = getmetatable(class_object).__parent });
		end;
	});
end

--util functions for object type checking
function leftOnlyObject(...)
	local sLeftType 	= select(1, ...);
	local sRightType	= select(2, ...);
	local sObjType 		= select(3, ...);
	return (sLeftType == sObjType and sRightType ~= sObjType);
end

function rightOnlyObject(...)
	local sLeftType 	= select(1, ...);
	local sRightType	= select(2, ...);
	local sObjType 		= select(3, ...);
	return (sLeftType ~= sObjType and sRightType == sObjType);
end

function bothObjects(...)
	local sLeftType 	= select(1, ...);
	local sRightType	= select(2, ...);
	local sObjType 		= select(3, ...);
	return (sLeftType == sObjType and sRightType == sObjType);
end

return class, interface;
