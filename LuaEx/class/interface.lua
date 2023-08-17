local tInterfaceBuilder = {};
local tInterfaceObjects = {};

local assert = assert;
local pairs = pairs;
local type = type;

local tVisibilityToErrorString = {
	metamethods 	= "meta",
	staticprotected = "static protected ",
	staticpublic 	= "static public ",
	private 		= "private ",
	protected 		= "protected ",
	public			= "public ",
}

local function callerror(sName, tClass, sChecking)
	return "Error creating class, ${name}. Input item is not a class table. Got ${item} (${type}) while checking ${checking}." % {name = tostring(sName), item = tostring(tClass), type = type(tClass), checking = sChecking};
end

local function visibilitytablehasfunction(tTable, sFunction)
	local bRet = false;

	for k, v in pairs(tTable) do

		if (type(v) == "function" and k == sFunction) then
			bRet = true;
			break;
		end

	end

	return bRet;
end

local function validatevisibilitytable(sClass, sInterface, tClass, tInterface, sVisibility)

	for sFunction, _ in pairs(tInterface[sVisibility]) do

		assert(visibilitytablehasfunction(	tClass[sVisibility], sFunction),
											"Error creating class, ${class}. Class impliments interface, ${interface}, but is missing ${visibility} method, ${method}."
											% {class = sClass, interface = sInterface, method = sFunction, visibility = tVisibilityToErrorString[sVisibility]});
	end

end


local function checkinput(tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic)

end;

--TODO LEFT OFF HERE Need isA and hasA functions for interfaces and classes

local function extends(sName, iExtendor)
	local bRet = false;

	if (type(iExtendor) == "interface") then
		assert(type(tInterfaceObjects[iExtendor]) == "table", "Error extending interface, ${interface}. Parent interface, ${item}, does not exist. Got (${type}) ${item}."	% {interface = sName, type = type(iExtendor), item = tostring(iExtendor)});
		bRet = true;
	end

	return bRet;
end


local function getparent(sName)
	local tRet 			= nil;
	local tInterface 	= tInterfaceBuilder[sName];

	if (type(tInterface.parent) ~= "nil" and tInterfaceBuilder[tInterface.parent]) then
		tRet = tInterfaceBuilder[tInterface.parent];
	end

	return tRet;
end



local function interface(sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic, iExtendor)

	--this is the table returned (interface object)
	local oInterface = {};

	--this is table containing the interface items that
	--are referenced by calls to the oInterface
	local tInterface = {
		metamethods 	= {},
		staticprotected = {},
		staticpublic 	= {},
		private			= {},
		protected 		= {},
		public      	= {},
	};

	assert(type(sName) == "string" and sName:isvariablecompliant(), "Error creating interface. Name must be a variable-compliant string. Got ${name} (${type})." % {name = tostring(sName), type(sName)});
	assert(type(tInterfaceBuilder[sName]) == "nil", "Error creating interface, ${sName}. Interface already exists.");

	local bExtend = extends(sName, iExtendor);

	tInterfaceBuilder[sName] = {
		children		= {},
		parent 			= bExtend and iExtendor or nil,
		name 			= sName,
		metamethods 	= {},
		staticprotected = {},
		staticpublic 	= {},
		private			= {},
		protected		= {},
		public			= {},
	};

	local tVisibilties = {
		metamethods 	= tMetamethods,
		staticprotected = tStaticProtected,
		staticpublic 	= tStaticPublic,
		private			= tPrivate,
		protected		= tProtected,
		public			= tPublic,
	};

	--store names in the builder
	for sVisibility, tFunctionNames in pairs(tVisibilties) do

		for _, sFunction in pairs(tFunctionNames) do
			--assert string names here
            assert(type(sFunction) == "string" and sFunction:isvariablecompliant(),
									"Error creating interface ${interface}. Method names must be variable compliant strings. Got ${func} (${type})."
									% {interface = sName, func = tostring(sFunction), type = type(sFunction)});

			tInterfaceBuilder[sName][sVisibility][sFunction] = true;
		end

	end

	local function importinterfaceitems(tImportFrom, sTableName)

		--import the members
		for sFunction, _ in pairs(tImportFrom[sTableName]) do
			tInterface[sTableName][sFunction] = true;
		end

	end

	--process the parents
	local tParents = {};

	--create the tParents table with top-most classes in descending order
	if (bExtend) then
		local tParent = getparent(tInterfaceObjects[iExtendor].name);
		tParent.children[sName] = tInterfaceBuilder[sName];

		while tParent ~= nil do
			table.insert(tParents, 1, tParent);
			tParent = getparent(tParent.name);
		end

	end

	--import all the parents' items
	for _, tParent in ipairs(tParents) do
		importinterfaceitems(tParent, "metamethods");
		importinterfaceitems(tParent, "staticprotected");
		importinterfaceitems(tParent, "staticpublic");
		importinterfaceitems(tParent, "private");
		importinterfaceitems(tParent, "protected");
		importinterfaceitems(tParent, "public");
	end

	--import all the interface items
	importinterfaceitems(tInterfaceBuilder[sName], "metamethods");
	importinterfaceitems(tInterfaceBuilder[sName], "staticpublic");
	importinterfaceitems(tInterfaceBuilder[sName], "staticprotected");
	importinterfaceitems(tInterfaceBuilder[sName], "private");
	importinterfaceitems(tInterfaceBuilder[sName], "protected");
	importinterfaceitems(tInterfaceBuilder[sName], "public");

	setmetatable(oInterface, {
		__type 	= "interface",
		__call = function(t, tClass)--TODO LEFT OFF HERE
			assert(type(tClass) 				== "table", 	callerror(tostring(tClass.name), tClass, "main table"));
			assert(type(tClass.name) 			== "string", 	callerror(tostring(tClass.name), tClass, "name"));
			assert(type(tClass.metamethods) 	== "table", 	callerror(tostring(tClass.name), tClass, "metamethods table"));
			assert(type(tClass.staticprotected) == "table", 	callerror(tostring(tClass.name), tClass, "staticprotected table"));
			assert(type(tClass.staticpublic) 	== "table", 	callerror(tostring(tClass.name), tClass, "staticpublic table"));
			assert(type(tClass.private) 		== "table", 	callerror(tostring(tClass.name), tClass, "private table"));
			assert(type(tClass.protected) 		== "table", 	callerror(tostring(tClass.name), tClass, "protected table"));
			assert(type(tClass.public) 			== "table", 	callerror(tostring(tClass.name), tClass, "public table"));

			validatevisibilitytable(tClass.name, sName, tClass, tInterface, "metamethods");
			validatevisibilitytable(tClass.name, sName, tClass, tInterface, "staticprotected");
			validatevisibilitytable(tClass.name, sName, tClass, tInterface, "staticpublic");
			validatevisibilitytable(tClass.name, sName, tClass, tInterface, "private");
			validatevisibilitytable(tClass.name, sName, tClass, tInterface, "protected");
			validatevisibilitytable(tClass.name, sName, tClass, tInterface, "public");
	   end,
	});

	return oInterface;
end

return interface;
