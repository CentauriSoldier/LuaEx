--[[
Planned features
AutoGetter/Setter functions


I've written a class system from scratch. It has inheritence, encapsulation, private, protected, public and static fields and methods. While a couple features are still in-progress, it's almost entirely complete. It also comes with interfaces allowing classes to imlpement 0 to many interfaces. Class may be extended by default or may be set to final and disallowed from being extented.

Can you think of any features it could use?
Even more importantly, can you think of ways it can be simplified, optimized or made moer readable? What do y'all think?

Download here.
]]

--[[
	Takes the input tables from a call the class modules and stores the fields
	& methods for later class construction TODO full description
]]
--local tClassBuilder		= {};
--[[
	Keeps track of created class objects and their names.
	The table is indexed by class objects whose value
	is a table containing the name of the class and a
	boolean indicating if the class is extendable.
	Items are put into the table when a class is created
	and referenced when extending a class at the start of
	class creation.
]]

--localization

-- __index and __newindex are special cases, handled separately
local tMetaNames = {__add 		= true,	__band 		= true,	__bnot 	= true,	__bor 		= true,
					__bxor 		= true,	__call 		= true,	__close = true, __concat 	= true,
					__div 		= true,	__eq		= true,	__gc 	= true,	__idiv		= true,
					__le 		= true,	__len 		= true,	__lt	= true,	__mod 		= true,
					__mode 		= true,	__mul 		= true,	__name 	= true,	__pow 		= true,
					__shl 		= true,	__shr 		= true,	__sub 	= true,	__tostring	= true,
					__unm 		= true};

local assert        = assert;
local getmetatable  = getmetatable;
local rawget 		= rawget;
local rawset		= rawset;
local pairs         = pairs;
local setmetatable  = setmetatable;
local string        = string;
local table         = table;
local type          = type;

--this is the class.args table
local tMasterArgsActual = {};
--[[these relate t0 the index of the specific table
	in the container (args) table passed into class
	methods]]
local tVisibilityIndices = {
	staticprotected = 1,--the class's static protected table
	private 		= 2,--the instance's private table
	protected		= 3,--the instance's protected table
	public 			= 4, --the instance's public table
	instances		= 5, --a table containing all the instances
};

setmetatable(tMasterArgsActual,
{
	__index = function(t, k)
		return tVisibilityIndices[k] or nil;
	end,
	__newindex = function(t, k, v) end,
});

local class, kit;

class = {
	repo = {
		byname = {},
	},
	build = function(sName, ...)
		local oClass = {};
		local tKit = kit.get(sName);
		--local class.buildinstancecall(tKit);

		--process the parents
		local tParents = {};
		--this will be called by the instance using this.super
		local fParentConstructor = nil;

		--create the tParents table with top-most classes in descending order
		if (bExtend) then
			local tParent = getparent(tClasses[cExtendor].name);
			--store this as a child of the parent ????TODO CHECK THIS
			tParent.children[sName] = tClassBuilder[sName];

			while tParent ~= nil do
				--store the parent
				table.insert(tParents, 1, tParent);
				--find the next parent
				tParent = getparent(tParent.name);
			end

			--store the lowest parent constructor
			local tFirstParent = tParents[#tParents];
			fParentConstructor = tFirstParent.public[tFirstParent.name];
		end




		--ready the args table (this gets passed to all wrapped methods)
		local tVI = tVisibilityIndices;
		local tClassArgs = {
			[tVI.staticprotected]	= tClassBuilder[sName].staticprotected,
			[tVI.private]			= tShadow.private,
			[tVI.protected]			= tShadow.protected,
			[tVI.public]			= tShadow.public,
			[tVI.instances] 		= tClassIntanceRepo,--this exists so all instances and their fields & methods can be accessed from inside the class module
		};

		local bConstructorFound = false;
		local fConstructor 		= nil;
		local tInstance 		= {}; 	--actual
		local tShadow 			= { 	--shadow
			metamethods				= {},
			private					= {},
			protected 				= setmetatable({}, {}),
			public      			= {},
		};
		local tInstanceMeta = {
			__type = sName,
			__is_luaex_class = true,
		};

		local tUserArgs = arg or {...};--5.1/5.4 compatibility


		return oClass;

		setmetatable(oClass, {
			__tostring = sName,
			__type 	= "class",
	        __call  = function(t, ...)
				local bConstructorFound = false;
				local fConstructor 		= nil;
				local tInstance 		= {}; 	--actual
				local tShadow 			= { 	--shadow
					metamethods				= {},
					private					= {},
					protected 				= {},
					public      			= {},
				};
				local tInstanceMeta = {
					__type = sName,
					__is_luaex_class = true,
				};



				--store this instance and it's args for later use from inside the class module
				tClassIntanceRepo[tInstance] = tArgs;

				--import the instance members
				for sVisibility, tVisibility in pairs(tShadow) do

					for k, v in pairs(tClass[sVisibility]) do

						local sTypeV 	= type(v);
						local sRawTypeV = rawtype(v);

						if (type(v) == "function") then

							if (not bConstructorFound and k == sName) then
								--here, we save the constructor for later but don't place it into the instance table
								fConstructor 			= v;
								bConstructorFound 		= true;
							else

								if (sVisibility == "metamethods") then

									if (tMetaNames[k]) then
										tShadow[sVisibility][k] = function(...) return v(tArgs, ...) end;
									end

								else
									tShadow[sVisibility][k] = function(...) return v(tInstance, tArgs, ...); end;
								end

							end

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

				--setup the instance metamethods
				for k, v in pairs(tShadow.metamethods) do
					tInstanceMeta[k] = v;
				end


				tInstanceMeta.__index = function(t, k)
					local vRet = rawget(tShadow.public, k);

					if (vRet) then
						return vRet;
					elseif (type(k) == "string" and k == "super") then --parent constructor
						assert(type(fParentConstructor) == "function", "Error calling parent constructor in class, ${name}. Prent constructor does not exist." % {name = sName})
						return fParentConstructor;
					else
						error("Index '${index}' not found in class, ${class}." % {index = tostring(k), class = sName});
					end

				end

				tInstanceMeta.__newindex = function(t, k, v);

				end

				--set the instance's metatable
				tInstance = setmetatable(tInstance, tInstanceMeta);

				--run the constructor
				fConstructor(tInstance, tArgs, ...);

				--[[TODO determine if the above-constructor
					called the parent's constructor and, if
					not, call it here.]]


				return tInstance;
	        end,

			__index = function(t, k)--TODO use to get static values
				local vRet = rawget(tClass.staticpublic, k);

				if (vRet == nil) then
					error("Key '${key}' not found in class, ${class}." % {class = sName, key = tostring(k)});
				end

				return vRet;
			end,

			__newindex = function(t, k, v)--TODO use to set static values
				error("Attempt to set or assign read-only static, property (${key} = ${value}) in class, ${class}." % {class = sName, key = tostring(k), value = tostring(v)});
			end,
	    });

		--keep track of the total number of classes
		nClassCount = nClassCount + 1;
		--store the class oject so it can be used for (potentially) extending
		tClasses[oClass] = {
			name 		= sName,
			instances	= tClassIntanceRepo;
			isFinal		= type(bIsFinal) == "boolean" and bIsFinal or false,
		};
		tClassesByName[name] = {
			instances	= tClassIntanceRepo;
			isFinal		= type(bIsFinal) == "boolean" and bIsFinal or false,
			object 		= oClass,
		};
	end,
	buildinstancecall = function(tKit, ...)
		return function(_ignored_, tKit, ...)


		end

	end,
};

kit = {
	--trackers, repo & other properties
	count = 0, --keep track of the total number of class kits
	repo = { --stores all class kits for later use
		byname 		= {}, --updated on kit.build()
		byobject 	= {}, --updated when a class object is created
	},
	--functions
	build = function(sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic, cExtendor, vImplements, bIsFinal)
		--check the input
		kit.validatename(sName);
		kit.validatetables(tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic);
		kit.validateinterfaces(vImplements);

		--build the kit
		local tKit = {
			--properties
			children		= {
				byname 		= {}, --updated on build (here)
				byobject 	= {}, --updated when a class object is created
			},
			instances		= {},
			isfinal			= type(bIsFinal) == "boolean" and bIsFinal or false,
			name 			= sName,
			parent			= kit.extends(cExtendor) and cExtendor or nil,
			--tables
			metamethods 	= table.clone(tMetamethods, 	false),
			staticprotected = table.clone(tStaticProtected, false),
			staticpublic 	= table.clone(tStaticPublic, 	false),
			private			= table.clone(tPrivate, 		false),
			protected 		= table.clone(tProtected, 		false),
			public      	= table.clone(tPublic, 			false),
		};

		--increment the class kit count
		kit.count = kit.count + 1;

		--store the class kit in the kit repo
		kit.repo.byname[sName] = tKit;

		--if this has a parent, update the parent kit
		if (tKit.parent) then
			local tKitRepo 	= tKit.repo.byobject;
			local tChildren = tKitRepo[tKit.parent];

			tChildren.byname[sName] = tKit;
		end

		--build and return class
		return class.build(sName);
	end,
	cloneitem = function(vItem)
		local vRet;

		if (type(vItem) == "table") then
			vRet = table.clone(vItem);

		elseif (rawtype(vItem) == "table") then
			local tMeta = getmetatable(vItem);

			if (tMeta and tMeta.__is_luaex_class) then
				vRet = vItem.clone();

			else
				vRet = table.clone(vItem);

			end

		else
			vRet = vItem;

		end

		return vRet;
	end,
	exists = function(vName)
		local tRepo	= type(vName) == "class" and kit.repo.byobject or kit.repo.byname;
		return type(tRepo[vName] ~= "nil");
	end,
	extends = function(sName, cExtendor)
		local bRet = false;

		--check that the extending class exists
		if (type(cExtendor) == "class") then
			assert(type(kit.repo.byobject[cExtendor]) == "table", "Error extending class, ${class}. Parent class, ${item}, does not exist. Got (${type}) ${item}."	% {class = sName, type = type(cExtendor), item = tostring(cExtendor)});
			assert(kit.repo.byobject[cExtendor].isfinal == false, "Error extending class, ${class}. Parent class ${parent} is final and cannot be extended."	% {class = sName, parent = tClassObjects[cExtendor].name})

			bRet = true;
		end

		return bRet;
	end,
	get = function(vName)
		local tRepo	= type(vName) == "class" and kit.repo.byobject or kit.repo.byname;
		assert(type(tRepo[vName] ~= "nil"), "Error getting class kit, ${name}. Class does not exist." % {name = tostring(vName)});
		return tRepo[vName];
	end,
	getparent = function(vName)
		local tRet 	= nil;
		local tKit 	= kit.get(vName);

		if (type(tKit.parent) ~= "nil") then
			tRet = kit.get(tKit.parent);
		end

		return tRet;
	end,
	validatename = function(sName)
		assert(type(sName) 					== "string", 	"Error creating class. Name must be a string.\r\nGot: (${type}) ${item}." 								% {					type = type(sName), 			item = tostring(sName)});
		assert(sName:isvariablecompliant(),					"Error creating class, ${class}. Name must be a variable-compliant string.\r\nGot: (${type}) ${item}."	% {class = sName,	type = type(sName), 			item = tostring(sName)});
		assert(type(kit.repo.byname[sName])	== "nil", 		"Error creating class, ${class}. Class already exists."													% {class = sName});
	end,
	validatetables = function(tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic)

		assert(type(tMetamethods)			== "table", 	"Error creating class, ${class}. Metamethods values table expected.\r\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tMetamethods),		item = tostring(tMetamethods)});
		assert(type(tStaticProtected)		== "table", 	"Error creating class, ${class}. Static protected values table expected.\r\nGot: (${type}) ${item}." 	% {class = sName, 	type = type(tStaticProtected),	item = tostring(tStaticProtected)});
		assert(type(tStaticPublic)			== "table", 	"Error creating class, ${class}. Static public values table expected.\r\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tStaticPublic),		item = tostring(tStaticPublic)});
		assert(type(tPrivate) 				== "table", 	"Error creating class, ${class}. Private values table expected.\r\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tPrivate), 			item = tostring(tPrivate)});
		assert(type(tProtected) 			== "table", 	"Error creating class, ${class}. Protected values table expected.\r\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tProtected), 		item = tostring(tProtected)});
		assert(type(tPublic) 				== "table", 	"Error creating class, ${class}. Static values table expected.\r\nGot: (${type}) ${item}." 				% {class = sName, 	type = type(tPublic), 			item = tostring(tPublic)});

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
				if (sTable == "public" and k == sName and type(v) == "function") then

					--make sure there's not already a constructor
					assert(not bIsConstructor, "Error creating class, ${class}. Redundant constructor detected in '${table}' table." % {class = sName, table = sTable});

					--make sure it's in the public table
					--assert(sTable == "public", "Error creating class, ${class}. Constructor must be declared in the 'public' table. Currently declared in the '${table}' table." % {class = sName, table = sTable});

					bIsConstructor = true;
				end

			end

		end

		assert(bIsConstructor, "Error creating class, ${class}. No constructor provided." % {class = sName});
	end,
	validateinterfaces = function(vImplements, tKit)--TODO complete thie!!!
		local sImplementsType = type(vImplements);

		if (sImplementsType == "table") then

			for _, iInterface in pairs(vImplements) do

				if (type(iInterface) == "interface") then
					iInterface(tKit);
				end

			end

		elseif (sImplementsType == "interface") then
			vImplements(tKit);
		end

	end,
};


--TODO assertions on input TODO allow the choice of local
--or global class (use "local" and "global" subtables in
--tClassBuilder to accomodate)
local function class(	_IGNORE_, sName,
						tMetamethods, tStaticProtected, tStaticPublic,
						tPrivate, tProtected, tPublic,
						cExtendor, vImplements, bIsFinal)

	--build the class kit
	kit.build(sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic, cExtendor, vImplements, bIsFinal);

	--build the class
	return kit.toclass(sName);
end





























--[[TODO
static protected/public items may not be overriden by child classes

]]
local function class(_IGNORE_, sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic, cExtendor, vImplements, bIsFinal)--TODO assertions on input TODO allow the choice of local or global class (use "local" and "global" subtables in tClassBuilder to accomodate)
	--make sure the input is good
	checkinput(sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic);

	--this is the table returned (class object)
	local oClass = {};
	--this table tracks every instance created by the class along with its actual shadow table for use inside the class module
	local tClassIntanceRepo = {};

	--this is table containing the class items that
	--are referenced by calls to the oClass
	local tClass 		= {
		children		= {},
		parent			= bExtend and cExtendor or nil,
		name 			= sName,
		metamethods 	= {},
		staticprotected = {},
		staticpublic 	= {},
		private			= {},
		protected 		= {},
		public      	= {},
	};

	local bExtend 		= extends(sName, cExtendor);

	--a key table for matching visibility type with input tables
	local tVisibilites = {
		metamethods 	= tMetamethods,
		staticprotected = tStaticProtected,
		staticpublic 	= tStaticPublic,
		private    		= tPrivate,
		protected  		= tProtected,
		public     		= tPublic,
	};

	--[[If there's a parent, use it's static protected table.
		Note: we use the tClassBuilder table instead of the
		oClass table becuase it's static and instead of the
		tClass table because it's protected. So, this table
		is shared statically across all class decendants.
	]]
	if (bExtend) then
		local cParent = tClassBuilder[sName].parent;
		local sParent = tClassObjects[cParent].name;

		tClassBuilder[sName].staticprotected = tClassBuilder[sParent].staticprotected;
	end

	--process the class items and store them in the appropriate table
	for sVisibility, tInputMembers in pairs(tVisibilites) do

		for k, v in pairs(tInputMembers) do
			--ensure k is both a string and it's variable compliant
			assert(type(k) == "string", "Error creating class '${class}'. Member name must be a non-blank, variable-complaint string. Got type ${type}" % {class = sName, type = type(k)}); --TODO should I allow non-string items (such as enums)?
			assert(k:isvariablecompliant(), "Error creating class '${class}'. Member name must be a non-blank, variable-complaint string. Got type ${str}" % {class = sName, str = k});
			tClassBuilder[sName][sVisibility][k] = v;
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
	--this will be called by the instance using this.super
	local fParentConstructor = nil;

	--create the tParents table with top-most classes in descending order
	if (bExtend) then
		local tParent = getparent(tClasses[cExtendor].name);
		--store this as a child of the parent ????TODO CHECK THIS
		tParent.children[sName] = tClassBuilder[sName];

		while tParent ~= nil do
			--store the parent
			table.insert(tParents, 1, tParent);
			--find the next parent
			tParent = getparent(tParent.name);
		end

		--store the lowest parent constructor
		local tFirstParent = tParents[#tParents];
		fParentConstructor = tFirstParent.public[tFirstParent.name];
	end


	--[[TODO how this should go...
	Parent constructors are setup
	protected items are transferred to a common table
	parent metamethods, protected functions and public functions are enclosed using the parent tables
	These are set aside
	...
	Class functions are enclosed using class tables
	Finalized parent items are imported
	Finalized class items are imported


	Okay, each parent needs an instance made
	then, protected metatable calls should check the class, then each ascending parent
]]

	--import all the parents' protected and public members
	for _, tParent in ipairs(tParents) do
		--import the metamethods
		--importclassitems(tParent, "metamethods");

		--import the protected items
		--importclassitems(tParent, "protected");

		--import the public items
		--importclassitems(tParent, "public");

	end

	--import all the class members
	--importclassitems(tClassBuilder[sName], "metamethods");
	--importclassitems(tClassBuilder[sName], "staticpublic");
	--importclassitems(tClassBuilder[sName], "staticprotected");
	--importclassitems(tClassBuilder[sName], "private");
	--importclassitems(tClassBuilder[sName], "protected");
	--importclassitems(tClassBuilder[sName], "public");

	--name is stored here redundantly for the interface module
	tClass.name = sName;

	--import class details and create isA and hasA methods TODO complete this
	tClass.staticpublic.name = sName;
	tClass.staticpublic.isa = function(oClass)
		--check is self
		print(oClass.name);
	end
	tClass.staticpublic.hasa = function(oClass)

	end

	--check interfaces
	local sImplementsType = type(vImplements);
	if (sImplementsType == "table") then

		for _, iInterface in pairs(vImplements) do

			if (type(iInterface) == "interface") then
				iInterface(tClass);
			end

		end
	elseif (sImplementsType == "interface") then
		vImplements(tClass);
	end

	--import class objects (possibly overriding parent functions and protected values)TODO should I enforce value type? Probably!
	--TODO class items may NOT override parent static values --use a metatable and shadow table to prevent additions and changes to the static tables
	--TODO check for construct and check for clone methods

    setmetatable(oClass, {
		__tostring = sName,
		__type 	= "class",
        __call  = function(t, ...)
			local bConstructorFound = false;
			local fConstructor 		= nil;
			local tInstance 		= {}; 	--actual
			local tShadow 			= { 	--shadow
				metamethods				= {},
				private					= {},
				protected 				= {},
				public      			= {},
			};
			local tInstanceMeta = {
				__type = sName,
				__is_luaex_class = true,
			};

			--ready the args table (this gets passed to all wrapped methods)
			local tArgs = {
				[tVisibilityIndices.staticprotected]	= tClassBuilder[sName].staticprotected,
				[tVisibilityIndices.private]			= tShadow.private,
				[tVisibilityIndices.protected]		= tShadow.protected,
				[tVisibilityIndices.public]			= tShadow.public,
				[tVisibilityIndices.instances] 		= tClassIntanceRepo,--this exists so all instances and their fields & methods can be accessed from inside the class module
			};

			--store this instance and it's args for later use from inside the class module
			tClassIntanceRepo[tInstance] = tArgs;

			--import the instance members
			for sVisibility, tVisibility in pairs(tShadow) do

				for k, v in pairs(tClass[sVisibility]) do

					local sTypeV 	= type(v);
					local sRawTypeV = rawtype(v);

					if (type(v) == "function") then

						if (not bConstructorFound and k == sName) then
							--here, we save the constructor for later but don't place it into the instance table
							fConstructor 			= v;
							bConstructorFound 		= true;
						else

							if (sVisibility == "metamethods") then

								if (tMetaNames[k]) then
									tShadow[sVisibility][k] = function(...) return v(tArgs, ...) end;
								end

							else
								tShadow[sVisibility][k] = function(...) return v(tInstance, tArgs, ...); end;
							end

						end

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

			--setup the instance metamethods
			for k, v in pairs(tShadow.metamethods) do
				tInstanceMeta[k] = v;
			end


			tInstanceMeta.__index = function(t, k)
				local vRet = rawget(tShadow.public, k);

				if (vRet) then
					return vRet;
				elseif (type(k) == "string" and k == "super") then --parent constructor
					assert(type(fParentConstructor) == "function", "Error calling parent constructor in class, ${name}. Prent constructor does not exist." % {name = sName})
					return fParentConstructor;
				else
					error("Index '${index}' not found in class, ${class}." % {index = tostring(k), class = sName});
				end

			end

			tInstanceMeta.__newindex = function(t, k, v);

			end

			--set the instance's metatable
			tInstance = setmetatable(tInstance, tInstanceMeta);

			--run the constructor
			fConstructor(tInstance, tArgs, ...);

			--[[TODO determine if the above-constructor
				called the parent's constructor and, if
				not, call it here.]]


			return tInstance;
        end,

		__index = function(t, k)--TODO use to get static values
			local vRet = rawget(tClass.staticpublic, k);

			if (vRet == nil) then
				error("Key '${key}' not found in class, ${class}." % {class = sName, key = tostring(k)});
			end

			return vRet;
		end,

		__newindex = function(t, k, v)--TODO use to set static values
			error("Attempt to set or assign read-only static, property (${key} = ${value}) in class, ${class}." % {class = sName, key = tostring(k), value = tostring(v)});
		end,
    });

	--keep track of the total number of classes
	nClassCount = nClassCount + 1;
	--store the class oject so it can be used for (potentially) extending
	tClasses[oClass] = {
		name 		= sName,
		instances	= tClassIntanceRepo;
		isFinal		= type(bIsFinal) == "boolean" and bIsFinal or false,
	};
	tClassesByName[name] = {
		instances	= tClassIntanceRepo;
		isFinal		= type(bIsFinal) == "boolean" and bIsFinal or false,
		object 		= oClass,
	};

	return oClass;
end

local tMasterShadow = { --this is the shadow table for the final returned value
	args = tMasterArgsActual,
};

return setmetatable(
{

},
{
	__call 		= kit.build,
	__len 		= function() return kit.count end,
	__index 	= function(t, k)
		return tMasterShadow[k] or nil;
	end,
	__newindex 	= function(t, k, v) end,
});
