--[[
Planned features
AutoGetter/Setter functions
]]

local tClasses 			= {};

--create a class system with inheritence, polymorphism and encapsulation
-- __index and __newindex are special cases, handled separately
local tMetaNames = {__add = true, __band = true, __bnot = true, __bor = true, __bxor = true, __close	= true,	__concat = true, __div = true, __eq	= true,	__gc = true, __idiv	= true,	__index = true,	__le = true, __len = true, __lt	= true,	__mod = true, __mode = true, __mul = true, __name = true, __newindex = true, __pow = true, __shl = true, __shr = true, __sub = true, __tostring	= true, __unm = true};

--localization
local assert        = assert;
local getmetatable  = getmetatable;
local rawget 		= rawget;
local rawset		= rawset;
local pairs         = pairs;
local setmetatable  = setmetatable;
local string        = string;
local table         = table;
local type          = type;

local function checkinput(sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic, sExtendor, tImplements)

	assert(type(sName) 				== "string", 	"Error creating class. Name must be a string.\r\nGot: (${type}) ${item}." 								% {					type = type(sName), 			item = tostring(sName)});
	assert(sName:isvariablecompliant(),				"Error creating class, ${class}. Name must be a variable-compliant string.\r\nGot: (${type}) ${item}."	% {class = sName,	type = type(sName), 			item = tostring(sName)});
	assert(type(tClasses[sName]) 	== "nil", 		"Error creating class, ${class}. Class already exists."													% {class = sName});
	assert(type(tMetamethods)		== "table", 	"Error creating class, ${class}. Metamethods values table expected.\r\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tMetamethods),		item = tostring(tMetamethods)});
	assert(type(tStaticProtected)	== "table", 	"Error creating class, ${class}. Static protected values table expected.\r\nGot: (${type}) ${item}." 	% {class = sName, 	type = type(tStaticProtected),	item = tostring(tStaticProtected)});
	assert(type(tStaticPublic)		== "table", 	"Error creating class, ${class}. Static public values table expected.\r\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tStaticPublic),		item = tostring(tStaticPublic)});
	assert(type(tPrivate) 			== "table", 	"Error creating class, ${class}. Private values table expected.\r\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tPrivate), 			item = tostring(tPrivate)});
	assert(type(tProtected) 		== "table", 	"Error creating class, ${class}. Protected values table expected.\r\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tProtected), 		item = tostring(tProtected)});
	assert(type(tPublic) 			== "table", 	"Error creating class, ${class}. Static values table expected.\r\nGot: (${type}) ${item}." 				% {class = sName, 	type = type(tPublic), 			item = tostring(tPublic)});

	local bIsConstructor = false;
	local tTables = {
		metamethods 	= tMetamethods,
		staticprotected = tStaticProtected,
		staticpublic 	= tStaticPublic,
		private 		= tPrivate,
		protected		= tProtected,
		public 			= tPublic,
	};

	--check that each item is named using a string!
	for sTable, tTable in pairs(tTables) do

		for k, v in pairs(tTable) do
			assert(type(k) == "string", "Error creating class, ${class}. All table indices must be of type string. Got: (${type}) ${item} in table '${table}'" % {class = sName, type = type(k), item = tostring(v), table = sTable});

			--ensure there's a constructor
			if (k == sName) then
				--make sure there's not already a constructor
				assert(not bIsConstructor, "Error creating class, ${class}. Redundant constructor detected in '${table}' table." % {class = sName, table = sTable});

				--make sure it's in either the private or public table
				assert(sTable == "private" or sTable == "public", "Error creating class, ${class}. Constructor must be declared in either the 'private' or 'public' table. Currently declared in the '${table}' table." % {class = sName, table = sTable});

				bIsConstructor = true;
			end

		end

	end



	--TODO ensure there's a clone method???

	assert(bIsConstructor, "Error creating class, ${class}. No constructor provided." % {class = sName});
end


local function extends(sName, sExtendor)
	local bRet = false;

	--check that the extending class exists
	if (type(sExtendor) == "string") then
		assert(type(tClasses[sExtendor]) ~= "nil", "Error extending class, ${class}. Parent class, ${item}, does not exists. Got (${type}) ${item}."	% {class = sName, 	type = type(sExtendor), 	item = tostring(sExtendor)});
		--TODO made sure it's not already a child of this parent!@
		bRet = true;
	end

	return bRet;
end

local function getparent(sName)
	local tRet 		= nil;
	local tClass 	= tClasses[sName];

	if (type(tClass.parent) ~= "nil" and tClasses[tClass.parent]) then
		tRet = tClasses[tClass.parent];
	end

	return tRet;
end

local function fieldindex(t, k)
	error("Item ${field} is not present in class '${class}'." % {field = tostring(k), class = sName});
end

local function fieldnewindex(t, k, v)
	error("Cannot add item to sealed class '${class}'." % {field = tostring(k), class = sName});
end


--[[TODO
static protected/public items may not be overriden by child classes

]]
local function class(sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic, sExtendor, tImplements)--TODO assertions on input TODO allow the choice of local or global class (use "local" and "global" subtables in tClasses to accomodate)
	--make sure the input is good
	checkinput(sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic, sExtendor, tImplements);

	local class_meta   	= { __type = sName, __is_luaex_class = true, __parent = nil };
    local tClass 		= {
		metamethods 	= {},
		staticprotected = {},
		staticpublic 	= {},
		private			= {},
		protected 		= {},
		public      	= {},
	};
	local bExtend 		= extends(sName, sExtendor);

--[[██████╗ ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ███╗██████╗ ██╗██╗     ███████╗
	██╔══██╗██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║██║     ██╔════╝
	██████╔╝██████╔╝█████╗  ██║     ██║   ██║██╔████╔██║██████╔╝██║██║     █████╗
	██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║██║     ██╔══╝
	██║     ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ██║███████╗███████╗
	╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝
	Items get stored for later use in building other classes.
	The original, input data is not modified but, rather,
	preserved to be used in building a class object
	(including the current one).]]

	--a key table for matching visibility type with input tables
	local tVisibilites = {
		metamethods 	= tMetamethods,
		staticprotected = tStaticProtected,
		staticpublic 	= tStaticPublic,
		private    		= tPrivate,
		protected  		= tProtected,
		public     		= tPublic,
	};

	--create the class table
	tClasses[sName] = {
		children		= {},
		parent			= bExtend and tClasses[sExtendor] or nil,
		name 			= sName,
		metamethods 	= {},
		staticprotected = {},
		staticpublic 	= {},
		private			= {},
		protected 		= {},
		public      	= {},
	};

	--process the class items and store them in the appropriate table
	for sVisibility, tInputMembers in pairs(tVisibilites) do

		for k, v in pairs(tInputMembers) do
			--ensure k is both a string and it's variable compliant
			assert(type(k) == "string", "Error creating class '${class}'. Member name must be a non-blank, variable-complaint string. Got type ${type}" % {class = sName, type = type(k)}); --TODO should I allow non-string items (such as enums)?
			assert(k:isvariablecompliant(), "Error creating class '${class}'. Member name must be a non-blank, variable-complaint string. Got type ${str}" % {class = sName, str = k});
			tClasses[sName][sVisibility][k] = v;
		end

	end


--[[██████╗ ██╗   ██╗██╗██╗     ██████╗      ██████╗██╗      █████╗ ███████╗███████╗
	██╔══██╗██║   ██║██║██║     ██╔══██╗    ██╔════╝██║     ██╔══██╗██╔════╝██╔════╝
	██████╔╝██║   ██║██║██║     ██║  ██║    ██║     ██║     ███████║███████╗███████╗
	██╔══██╗██║   ██║██║██║     ██║  ██║    ██║     ██║     ██╔══██║╚════██║╚════██║
	██████╔╝╚██████╔╝██║███████╗██████╔╝    ╚██████╗███████╗██║  ██║███████║███████║
	╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═════╝      ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝
	This is where the class is built. The parent classes are sorted in descending
	order and each of their protected and public items added to the class. Then,
	the provided, input items are added to the class, potentially overriding parent
	items including methods and fields.]]

	local function importclassitems(tImportFrom, sTableName)

		--import the members
		for k, v in pairs(tImportFrom[sTableName]) do
			tClass[sTableName][k] = v;
		end

	end

	--process the parents
	local tParents = {};

	--create the tParents table with top-most classes in descending order
	if (bExtend) then
		local tParent = getparent(sExtendor);
		tParent.children[sName] = tClasses[sName];

		while tParent ~= nil do
			table.insert(tParents, 1, tParent);
			tParent = getparent(tParent.name);
		end

	end

	--import all the parents' protected and public members
	for _, tParent in ipairs(tParents) do
		--import the metamethods
		importclassitems(tParent, "metamethods");

		--import the protected items
		importclassitems(tParent, "protected");

		--import the public items
		importclassitems(tParent, "public");
	end

	--import all the class members
	importclassitems(tClasses[sName], "metamethods");
	importclassitems(tClasses[sName], "private");
	importclassitems(tClasses[sName], "protected");
	importclassitems(tClasses[sName], "public");

	--determine if there are parents
	--setup parent functions
	--import parent functions from top-most to lowest
	--import class objects (possibly overriding parent functions and protected values)TODO should i enforce value type? Probably!
	--TODO class items may NOT override parent static values --use a metatable and shadow table to prevent additions and changes to the static tables
	--TODO check for construct and check for clone methods

    local oClass = setmetatable(tClass, {--TODO seal metatable upon return
		__type 	= "class",
        __call  = function(tClass, ...)
			local tInstance 	= {}; --actual
			local tShadow 		= { --shadow
				metamethods 		= {},
				private				= {},
				protected 			= {},
				public      		= {},
			};
			local tInstanceMeta = {
				__type = sName,
				__blarg = "asdasd",
			};
--TODO pull out the contructor --Adjust for priavte or public constructor
			--import the instance members
			for sVisibility, tVisibility in pairs(tShadow) do

				for k, v in pairs(tClass[sVisibility]) do
					local sTypeV 	= type(v);
					local sRawTypeV = rawtype(v);

					if (type(v) == "function") then
						tShadow[sVisibility][k] = function(...) return v(tInstance, tClass.staticprotected, tShadow.private, tShadow.protected, tShadow.public, ...); end;

					elseif (sTypeV == "table") then
						tShadow[sVisibility][k] = table.clone(v);

					elseif (sRawTypeV == "table") then
						local tMeta = getmetatable(v);

						if (tMeta and tMeta.__is_luaex_class) then
							tShadow[sVisibility][k] = v.clone();

						else
							tShadow[sVisibility][k] = table.clone(v);

						end

					else
						tShadow[sVisibility][k] = v;

					end

				end

			end

			--setup the instance metatable
			for k, v in pairs(tShadow.metamethods) do

				if (tMetaNames[k] and k ~= "__index" and k ~= "__newindex" and k ~= "__type" and type(v) == "function") then
					--TODO create each function indidually,...
					tInstanceMeta[k] = v;
				end

			end

			tInstanceMeta.__index = function(t, k)
				local vRet = rawget(tShadow.public, k);

				if (vRet) then
					return vRet;
				else
					error("Index '${index}' not found in class, ${class}." % {index = tostring(k), class = sName});
				end

			end

			tInstanceMeta.__newindex = function(t, k, v)

			end

			--seal the intance's metatable
			--tInstanceMeta.__metatable = error("Attempt to access sealed metatable in class instance, ${class}" % {class = sName});

			--set the intance's metatable
			tInstance = setmetatable(tInstance, tInstanceMeta);

			--run the constructor
			--TODO remove the constructor from the public or private table and store somewhere else...run it here

			return tInstance;
        end,
		__index = function(t, k)--TODO use to get static values

		end,
		__newindex = function(t, k, v)--TODO use to set static values

		end,
    });

	rawset(_G, sName, oClass);
end

--[[
class("Creature",
--metamethods
{
	__add = function(this, pri, pro, pub, left, right)
		return pro.HP + right;
	end,
},
--private
{

},
--protected
{
	HP = 0,
},
--public
{
	Creature = function(this, pri, pro, pub)

	end,

	GetHP = function(this, pri, pro, pub)
		return pro.HP;
	end,

	SetHP = function(this, pri, pro, pub, nValue)
		pro.HP = nValue;
	end,


});
]]
--local Boo = Creature();
--local Hu = Creature();

--print(type(Boo))
--print(serialize.table(getmetatable(Boo)))
--Boo.Draft = 556;
--Boo.SetHP(45);
--Hu.SetHP(20);
--print(Boo + Hu)
--Creature.Test = 45;
--print(getmetatable(Creature))

return class;
