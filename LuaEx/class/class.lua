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

--constants
constant("CLASS_ACCESS_INDEX_METATABLES",  0);
constant("CLASS_ACCESS_INDEX_PRIVATE",     1);
constant("CLASS_ACCESS_INDEX_PROTECTED",   2);
constant("CLASS_ACCESS_INDEX_PUBLIC",      3);
constant("CLASS_ACCESS_INDEX_INSTANCES",   4);

--localization
local CAI_MET = CLASS_ACCESS_INDEX_METATABLES;
local CAI_PRI = CLASS_ACCESS_INDEX_PRIVATE;
local CAI_PRO = CLASS_ACCESS_INDEX_PROTECTED;
local CAI_PUB = CLASS_ACCESS_INDEX_PUBLIC;
local CAI_INS = CLASS_ACCESS_INDEX_INSTANCES;

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
local pairs         = pairs;
local rawget 		= rawget;
local rawset		= rawset;
local setmetatable  = setmetatable;
local string        = string;
local table         = table;
local type          = type;

--this is the class.args table
local tMasterArgsActual = {};
--[[these relate to the index of the specific table
	in the container (args) table passed into class
	methods]]
local tVisibilityIndices = {
	private 		= CAI_PRI,--the instance's private table
	protected		= CAI_PRO,--the instance's protected table
	public 			= CAI_PUB, --the instance's public table
	instances		= CAI_INS, --a table containing all the instances
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
        bykit     = {},
		byname    = {},
        objects   = {},
	},
	build = function(sName, ...)
		local oClass = {};
		local tKit = kit.get(sName);
		--local class.buildinstancecall(tKit);

		--process the parents ()
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
			[tVI.private]			= tShadow.private,
			[tVI.protected]			= tShadow.protected,
			[tVI.public]			= tShadow.public,
			[tVI.instances] 		= tClassIntanceRepo,--this exists so all instances and their fields & methods can be accessed from inside the class module TODO doesn't this need to be declared somewhere?
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


		--return oClass;

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
						assert(type(fParentConstructor) == "function", "Error calling parent constructor in class, '${name}'. Prent constructor does not exist." % {name = sName})--TODO this should never happen as a constructor is ALWAYS required during class creation. THis section in not needed
						return fParentConstructor;
					else
						error("Index, '${index}', not found in class, '${class}'." % {index = tostring(k), class = sName});
					end

				end

				tInstanceMeta.__newindex = function(t, k, v);--deadcall

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
					error("Key, '${key}', not found in class, '${class}'." % {class = sName, key = tostring(k)});
				end

				return vRet;
			end,

			__newindex = function(t, k, v)--TODO use to set static values
				error("Attempt to set or assign read-only static, property (${key} = ${value}) in class, '${class}'." % {class = sName, key = tostring(k), value = tostring(v)});
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
	end,--TODO where is the class object returned?
	buildinstancecall = function(tKit, ...)
		return function(_ignored_, tKit, ...)


		end

	end,
};

kit = {
	--trackers, repo & other properties
	count = 0, --keep track of the total number of class kits
	repo = { --stores all class kits for later use
		byname 		= {}, --updated on kit.import()
		byobject 	= {}, --updated when a class object is created
	},
	--functions
    --[[!
    @module class
    @func kit.build
    @param table tKit The kit that is to be built.
    @scope local
    @desc dfsdf
    !]]
    build = function(tKit)
        local oClass    = {}; --this is the class object that gets returned
        --shorthand
        local tVIs      = tVisibilityIndices;
        local sName     = tKit.name;

        --this is the actual, hidden class table referenced by the returned class object
        local tClass            = table.clone(tKit.staticpublic);   --create the static public members
        --tClass[tVIs.private]    = table.clone(tKit.private);        --create the private members
        --tClass[tVIs.protected]  = table.clone(tKit.protected);      ---etc.
        --tClass[tVIs.public]     = table.clone(tKit.public);
        --tClass[tVIs.instances]  = table.clone(tKit.instances);
--[[
        local tClassArgs = { --this gets passed to the appropriate class methods TODO does this get done on instantiation?  NO, that would be very inefficient
            [tVIs.private]     = tClass[tVIs.private],
            [tVIs.protected]   = tClass[tVIs.protected],
            [tVIs.public]      = tClass[tVIs.public],
            [tVIs.instances]   = tClass[tVIs.instances],
        };]]
--TODO create/modify instances table
        --check for and process parents
        --local tParent   = tKit.parent;
        --local tParents  = {};

        --while (tParent) do
            --table.insert(tParents, 1, tParent); --top-most parent is first in line
            --tParent = tParent.parent;
        --end

        --tMetaNames

        local tClassMeta = { --the decoy (returned class object) meta table
            __call      = function(t, ...) --instantiate the class
                local oInstance, tInstance = kit.instantiate(tKit, false); --this is the returned instance

                --TODO SHOULD I INSTNTIATE EACH OBJECT THEN LOOP OVER THEM TO CREATE/MODIFY METATABLES?
                --HERE IT IS...instatiate self | check for parent and if exists, instantiate that (recursively) | ammend metatables for parent loopup Now, what about protected items? Lookup those too?
                --TODO create parent instances recursively on top of already-created self instance
                --if (#tParents) > 0 then

                --end
--TODO add instance to instances table
                --apply metamethods

                --wrap the class methods

                return oInstance;
            end,
            __index     = function(t, k)
                return tClass[k] or nil;
            end,
            __newindex  = function(t, k, v) --TODO create a param option to silence this (globally and per class object)
                error("Attempt to modify class object, '${class},' using value, '${value}.'" % {value = tostring(v), class = sName});
            end,
            __type = "class",
            __name = sName,
        };

        setmetatable(oClass, tClassMeta);

        --update the repos
        kit.repo.byobject[oClass]       = tKit;
        class.repo.bykit[tKit]          = oClass;
        class.repo.byname[tKit.name]    = oClass;
        class.repo.objects[oClass]      = tKit.name;

        return oClass;
    end,
	cloneitem = function(vItem)
		local vRet;

		if (type(vItem) == "table") then
			vRet = table.clone(vItem);

		elseif (rawtype(vItem) == "table") then
			local tMeta = getmetatable(vItem);

			if (tMeta and tMeta.__is_luaex_class) then
				vRet = vItem.clone();--TODO what is this?

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
	get = function(vName)
		local tRepo	= type(vName) == "class" and kit.repo.byobject or kit.repo.byname;
		assert(type(tRepo[vName] ~= "nil"), "Error getting class kit, '${name}'. Class does not exist." % {name = tostring(vName)});
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
    import = function(_IGNORE_, sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic, cExtendor, vImplements, bIsFinal)

        --validate the input TODO remove any existing metatable from input tables or throw error if can't
		kit.validatename(sName);
        kit.validatetables(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic);
		kit.validateinterfaces(vImplements);

		--import/create the elements which will comprise the class kit
		local tKit = {
			--properties
			children		= {
				byname 		= {}, --updated on import (here)
				byobject 	= {}, --updated when a class object is created
			},
			instances		= {},
			isfinal			= type(bIsFinal) == "boolean" and bIsFinal or false,
			name 			= sName,
			parent			= kit.mayextend(sName, cExtendor) and kit.repo.byobject[cExtendor] or nil, --note the parent kit
			--tables
			metamethods 	= table.clone(tMetamethods, 	true),--TODO this was recently changed to TRUE since (I think) user-defined metatables should be ignored from input
			staticpublic 	= table.clone(tStaticPublic, 	true),
			private			= table.clone(tPrivate, 		true),
			protected 		= table.clone(tProtected, 		true),
			public      	= table.clone(tPublic, 			true),
		};

		--increment the class kit count
		kit.count = kit.count + 1;

		--store the class kit in the kit repo
		kit.repo.byname[sName] = tKit;

		--if this has a parent, update the parent kit
		if (tKit.parent) then
            tKit.parent.children.byname[sName] = tKit;
		end

        --check for public/protected shadowing
        kit.shadowcheck(tKit);

		--now that this class kit has been validated, imported & stored, build and return the class object
		return kit.build(tKit);
	end,
    instantiate = function(tKit, bIsRecursionCall)
        local oInstance     = {};   --this is the decoy instance object that gets returned
        local tInstance     = {     --this is the actual, hidden instance table referenced by the returned decoy, instance object
            [CAI_PRI] = table.clone(tKit.private),    --create the private members
            [CAI_PRO] = table.clone(tKit.protected),  ---etc.
            [CAI_PUB] = table.clone(tKit.public),--TODO should I use clone item or wil this do for cloning custom class types? Shoudl I also force a clone method for this in classes? I could also have attributes in classes that could ask if cloneable...
            [CAI_INS] = tKit.instances,               --TODO should this go here? I think so.....\
            children            = {},--TODO move to class level or to here? Is there any use for it here?
            decoy               = oInstance,                    -- for internal reference if I need to reach the decoy of a given actual
            metadata            = {},                           --info about the instance
            kit                 = tKit,
            --super               = nil, --the decoy parent (if one exists)
            parent              = nil, --the actual parent (if one exists)
        };

        --log the class kit in the instance metadata field
        tInstance.metadata.kit = tKit;

        --shorthand TODO these need more metatables or reviewed metatables
        local tPrivate      = tInstance[CAI_PRI];
        local tProtected    = tInstance[CAI_PRO];
        local tPublic       = tInstance[CAI_PUB];
        local tInstances    = tInstance[CAI_INS];

        --this gets pushed through the wrapped methods
        local tClassData     = {
            [CAI_PRI] = tPrivate,
            [CAI_PRO] = tProtected,
            [CAI_PUB] = tPublic,
            [CAI_INS] = tInstances,
            --parent    = nil,
        };
        --TODO we need to introduce a meta table for lookup.
        local tClassDataMeta = {};

                    --TODO instance metatables (use a record-keeping system to determine which meta methods came from which parent so they can call the correct function with one call instead of many)
--TODO wrap these too
        --[[┌────────────────────────────────────────────┐
            │             🅼🅴🆃🅰🅼🅴🆃🅷🅾🅳🆂            │
            └────────────────────────────────────────────┘]]

            --TODO make AI table values strongly typed


        --preform the method wrapping (private, protected and public methods)
        for _, nCAI in ipairs({CAI_PRI, CAI_PRO, CAI_PUB}) do --export this to a local table so we don't have to make new table every time
            local tActive = tInstance[nCAI];

            for k, v in pairs(tInstance[nCAI]) do

                if (rawtype(v) == "function") then

                    rawset(tInstance[nCAI], k, function(...)
                        return v(oInstance, tClassData, ...);
                    end);

                end

            end

            if (nCAI == CAI_PRO or nCAI == CAI_PUB) then
                setmetatable(tInstance[nCAI], {
                    __index = function(t, k)
                        local vRet          = rawget(tInstance[nCAI], k);
                        local zRet          = rawtype(vRet);
                        local tNextParent   = tInstance.parent or nil;

                        --if there's no such public key in the instance, check each parent
                        while (zRet == "nil" and tNextParent) do
                            vRet        = rawget(tNextParent[nCAI], k);
                            zRet        = rawtype(vRet);
                            tNextParent = tNextParent.parent;
                        end

                        --if none exists, throw an error
                        if (rawtype(vRet) == "nil") then
                            error("Error in class, '${name}'. Attempt to access public member, '${member}', a nil value." % {
                                name = tKit.name, member = tostring(k)});
                        end

                        return vRet;
                    end,
                    __newindex = function(t, k, v)
                        print(t, k, v)
                        local tTarget       = tInstance[nCAI];
                        local vVal          = rawget(tTarget, k);
                        local zVal          = rawtype(vVal);
                        local tNextParent   = tInstance.parent or nil;

                        --if there's no such public key in the instance, check each parent
                        while (zVal == "nil" and tNextParent) do
                            tTarget     = tNextParent[nCAI];
                            vVal        = rawget(tTarget, k);
                            zVal        = rawtype(vVal);
                            tNextParent = tNextParent.parent;
                        end

                        --if none exists, throw an error
                        if (rawtype(vVal) == "nil") then
                            error("Error in class, '${name}'. Attempt to modify public member, '${member}', a nil value." % {
                                name = tKit.name, member = tostring(k)});
                        end

                        local sTypeCurrent  = type(tTarget[k]);
                        local sTypeNew      = type(v);
                        print(tostring(sTypeCurrent), tostring(sTypeNew))
                        if (sTypeNew == "nil") then
                            error("Error in class, '${name}'. Cannot set public member, '${member}', to nil." % {
                                name = tKit.name, member = tostring(k)});
                        end

                        if (sTypeCurrent == "function") then
                            error("Error in class, '${name}'. Attempt to override public class method, '${member}', outside of a subclass context." % {
                                name = tKit.name, member = tostring(k)});
                        end

                        if (sTypeCurrent ~= "null" and sTypeCurrent ~= sTypeNew) then--TODO allow for null values (and keep track of previous type)
                            error("Error in class, '${name}'. Attempt to change type for member, '${member}', from ${typecurrent} to ${typenew}." % {
                                name = tKit.name, member = tostring(k), typecurrent = sTypeCurrent, typenew = sTypeNew});
                        end

                        rawset(tTarget, k, v);
                        --return oInstance;
                    end,
                });

            end

        end

        --create and set the instance metatable
        kit.setinstancemetatable(tKit, oInstance, tInstance);

        --create parents (if any)
        if (tKit.parent) then
            --instantiate the parent
            local oParent, tParent = kit.instantiate(tKit.parent, true);
            --log the parent info for later use
            tInstance.parent = tParent;
                                            --TODO I need to update the children field of each parent (OR do I?)
        end

        --🅿🆄🅱🅻🅸🅲  | setup inheritence for public members


            --TODO check for public and protected members in each class and handle them
            --ensure there are no public value overrights



            --[[┌────────────────────────────────────────────┐
                │               🅿🆁🅾🆃🅴🅲🆃🅴🅳             │
                └────────────────────────────────────────────┘]]


--TODO prevent public static items form being overwritten as public ones are (and no oew ones should be allowwed to be added after class creation).



        --TODO contructors  (also static initializers for altering static fields ONCE at runtime)


        if not (bIsRecursionCall) then
            tKit.instances[oInstance] = tInstance; --store the instance reference (but not its recursively-created, parent instances)
        end

        return oInstance, tInstance;
    end,
    mayextend = function(sName, cExtendor) --TODO this is allow the extending of final classes...fix this (it may be that the class is not being added to the repo in import yet)
		local bRet = false;

		--check that the extending class exists
		if (type(cExtendor) == "class") then
			assert(type(kit.repo.byobject[cExtendor]) == "table", "Error extending class, '${class}'. Parent class, '${item}', does not exist. Got (${type}) '${item}'."	% {class = sName, type = type(cExtendor), item = tostring(cExtendor)});
			assert(kit.repo.byobject[cExtendor].isfinal == false, "Error extending class, '${class}'. Parent class '${parent}' is final and cannot be extended."	% {class = sName, parent = kit.repo.byobject[cExtendor].name})

			bRet = true;
		end

		return bRet;
	end,
    setinstancemetatable = function(tKit, oInstance, tInstance)
        local tPublic = tInstance[CLASS_ACCESS_INDEX_PUBLIC];

        --TODO add user metatable stuff here

        setmetatable(
            oInstance,
            { --this is the instance metatable
                __index     = function(t, k)
                    return tPublic[k] or nil;
                end,
                __newindex  = function(t, k, v)
                    tPublic[k] = v;

                    --if (rawtype(tPublic[k]) ~= "nil") then
                    --    tPublic[k] = v; --DO NOT use rawset and rawget here because this needs to rely on the tPublic metatable for lookup (to account for parents)
                    --end

                    --return tPublic[k] or nil; --the tPublic metatable returns the instance object
                end,
                __type = tKit.name,
            }
        );
    end,
    shadowcheck = function(tKit) --checks for public/protected shadowing
        local tParent   = tKit.parent;

        local tCheckIndices  = {
            [CAI_PRO] = "protected",
            [CAI_PUB] = "public",
        };

        while (tParent) do

            --iterate over each visibility level
            for nVisibility, sVisibility in ipairs(tCheckIndices) do

                --shadow check each member of the class
                for sKey, vChildValue in pairs(tKit[nVisibility]) do
                    local zParentValue  = rawtype(tParent[nVisibility][sKey]);
                    local zChildValue   = rawtype(vChildValue);

                    --the same key found in any parent is allowed in the child class only if it's a function override, otherwise throw a shadowing error
                    if (zParentValue ~= "nil" and not (zParentValue == "function" and zChildValue == "function")) then
                        error(  "Error in class, '${name}'. Attempt to shadow existing ${visibility} member, '${member}', in parent class, '${parent}'." % {
                                name = tKit.name, visibility = sVisibility, member = tostring(vChildValue), parent = tParent.name});
                    end

                end

            end

            --check the next parent above this level (if any)
            tParent = tParent.parent;
        end

    end,--TODO edit errors adding commas and, class names, quotes, etc. Pretty pretty
	validatename = function(sName)
		assert(type(sName) 					== "string", 	"Error creating class. Name must be a string.\r\nGot: (${type}) ${item}." 								% {					type = type(sName), 			item = tostring(sName)});
		assert(sName:isvariablecompliant(),					"Error creating class, ${class}. Name must be a variable-compliant string.\r\nGot: (${type}) ${item}."	% {class = sName,	type = type(sName), 			item = tostring(sName)});
		assert(type(kit.repo.byname[sName])	== "nil", 		"Error creating class, ${class}. Class already exists."													% {class = sName});
	end,
    validatetables = function(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic)
		assert(type(tMetamethods)			== "table", 	"Error creating class, ${class}. Metamethods values table expected.\r\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tMetamethods),		item = tostring(tMetamethods)});
		assert(type(tStaticPublic)			== "table", 	"Error creating class, ${class}. Static public values table expected.\r\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tStaticPublic),		item = tostring(tStaticPublic)});
		assert(type(tPrivate) 				== "table", 	"Error creating class, ${class}. Private values table expected.\r\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tPrivate), 			item = tostring(tPrivate)});
		assert(type(tProtected) 			== "table", 	"Error creating class, ${class}. Protected values table expected.\r\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tProtected), 		item = tostring(tProtected)});
		assert(type(tPublic) 				== "table", 	"Error creating class, ${class}. Static values table expected.\r\nGot: (${type}) ${item}." 				% {class = sName, 	type = type(tPublic), 			item = tostring(tPublic)});

		local bIsConstructor = false;
		local tTables = {
			metamethods 	= tMetamethods,
			staticpublic 	= tStaticPublic,
			private 		= tPrivate,
			protected		= tProtected,
			public 			= tPublic,
		};

		--check that each item is named using a string!
		for sTable, tTable in pairs(tTables) do

			for k, v in pairs(tTable) do
				assert(rawtype(k) == "string", "Error creating class, ${class}. All table indices must be of type string. Got: (${type}) ${item} in table '${table}'" % {class = sName, type = type(k), item = tostring(v), table = sTable});
--TODO consider what visibility constructors must have (no need for private consttructors since static classes are not really needed in Lua?)
				--ensure there's a constructor
				if (sTable == "public" and k == sName and rawtype(v) == "function") then

					--make sure there's not already a constructor
					assert(not bIsConstructor, "Error creating class, ${class}. Redundant constructor detected in '${table}' table." % {class = sName, table = sTable});

					--make sure it's in the public table
					--assert(sTable == "public", "Error creating class, ${class}. Constructor must be declared in the 'public' table. Currently declared in the '${table}' table." % {class = sName, table = sTable});

					bIsConstructor = true;
				end

			end

		end

        --TODO import metamethods ONLY if they are legit metanames
		assert(bIsConstructor, "Error creating class, '${class}'. No constructor provided." % {class = sName});
	end,
	validateinterfaces = function(vImplements, tKit)--TODO complete this!!!
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


local tMasterShadow = { --this is the shadow table for the final returned value TODO do i even need this anymore?
	args = tMasterArgsActual,
};

return setmetatable(
{

},
{
	__call 		= kit.import,
	__len 		= function() return kit.count end,
	__index 	= function(t, k)
		return tMasterShadow[k] or nil;
	end,
	__newindex 	= function(t, k, v) end,--deadcall function to prevent adding external entries to the class module
});
