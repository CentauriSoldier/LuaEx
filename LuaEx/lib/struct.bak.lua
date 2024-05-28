local rawtype 		= rawtype;
local pairs 		= pairs;
local setmetatable 	= setmetatable;
local type 			= type;
--TODO force null values to be set before allow retrieval
local function dummy() end --INCOMPLETE TODO change this to use an actrual table for newindex, and index

local function errbit()
	error("Attempt to perform bitwise operation on struct factory constructor.", 3);
end

local function errmath()
	error("Attempt to perform mathmatical operation on struct factory constructor.", 3);
end

local function errlen()
	error("Attempt to get length of struct factory constructor.", 3);
end

local function erriterate()
	error("Attempt to iterate over struct factory constructor.", 3);
end

local function errbitinstance()
	error("Attempt to perform bitwise operation on struct factory.", 3);
end

local function errmathinstance()
	error("Attempt to perform mathmatical operation on struct factory.", 3);
end

local function errleninstance()
	error("Attempt to get length of struct factory.", 3);
end

local function erriterateinstance()
	error("Attempt to improperly iterate over struct factory using ipairs.\nOnly pairs is supported.", 3);
end

--metadata of factory factories
local tMetaData = {
	count = 0,
	--[[private = {
		count 		= 0,
		factories 	= {},
	},
	public 	= {
		count 		= 0,
		factories 	= {},
	},]]
};

local function propertiestableisvalid(tProperties)
	local bRet = false;
	local nKeyCount = 0;

	if (type(tProperties) == "table") then

		for vKey, _ in pairs(tProperties) do

			if (rawtype(vKey) == "string") then
				nKeyCount = nKeyCount + 1;
			else
				bRet = false;
				break;
			end

		end

		bRet = nKeyCount > 0;
	end

	return bRet;
end

--TODO make sure the subtype name does not exist (because it could be an enum, class, etc.)
--TODO go through this to make sure all the values are accessing the correct tbales (tfactory, tFactory, etc.)
local function createfactory(__IGNORE__, sSubType, tProperties, bReadOnlyCheck)--, bPrivate)
	--[[
	███████╗░█████╗░░█████╗░████████╗░█████╗░██████╗░██╗░░░██╗
	██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗╚██╗░██╔╝
	█████╗░░███████║██║░░╚═╝░░░██║░░░██║░░██║██████╔╝░╚████╔╝░
	██╔══╝░░██╔══██║██║░░██╗░░░██║░░░██║░░██║██╔══██╗░░╚██╔╝░░
	██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝██║░░██║░░░██║░░░
	╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░

	░█████╗░░█████╗░███╗░░██╗░██████╗████████╗██████╗░██╗░░░██╗░█████╗░████████╗░█████╗░██████╗░
	██╔══██╗██╔══██╗████╗░██║██╔════╝╚══██╔══╝██╔══██╗██║░░░██║██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗
	██║░░╚═╝██║░░██║██╔██╗██║╚█████╗░░░░██║░░░██████╔╝██║░░░██║██║░░╚═╝░░░██║░░░██║░░██║██████╔╝
	██║░░██╗██║░░██║██║╚████║░╚═══██╗░░░██║░░░██╔══██╗██║░░░██║██║░░██╗░░░██║░░░██║░░██║██╔══██╗
	╚█████╔╝╚█████╔╝██║░╚███║██████╔╝░░░██║░░░██║░░██║╚██████╔╝╚█████╔╝░░░██║░░░╚█████╔╝██║░░██║
	░╚════╝░░╚════╝░╚═╝░░╚══╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░╚═════╝░░╚════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝
	--creates the factory object
	]]

    local bReadOnly = rawtype(bReadOnlyCheck) == "boolean" and bReadOnlyCheck or false;
    local tConstraint = {};

    assert(rawtype(sSubType) == "string" and sSubType:gsub("[%s]", "") ~= "", "Error creating struct factory. Argument 1 (Subtype) must be a non-blank string.", 3);
	assert(rawtype(tMetaData[sSubType]) == "nil", "Error creating struct factory. Factory of subtype '"..sSubType.."' already exists; Cannot overwrite.", 3);
	assert(propertiestableisvalid(tProperties), "Error creating struct factory. Argument 2 (Properies Input Table) must be of type table and have at least one key.", 3);

	for sKey, vValue in pairs(tProperties) do
	    local sValType = type(vValue);

        if (bReadOnly and sValType == "null") then
            error("Error creating read-only struct factory, '"..sSubType.."'. Value at key '"..sKey.."' is null.", 3)
        end

		tConstraint[sKey] = {
			type 			= sValType,
			defaultvalue 	= vValue,
		};
	end

	--[[
	███████╗░█████╗░░█████╗░████████╗░█████╗░██████╗░██╗░░░██╗
	██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗╚██╗░██╔╝
	█████╗░░███████║██║░░╚═╝░░░██║░░░██║░░██║██████╔╝░╚████╔╝░
	██╔══╝░░██╔══██║██║░░██╗░░░██║░░░██║░░██║██╔══██╗░░╚██╔╝░░
	██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝██║░░██║░░░██║░░░
	╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░
	this is the factory which creates the factory instance objects
	]]
    local tFactoryActual = {isReadOnly = bReadOnly};
	local tFactoryDecoy = setmetatable(tFactoryActual,
	{
		__add 		= errmath,--TODO perhaps add the ability to combine them...maybe thruogh concat though, not add
		__band 		= errbit,
		__bor 		= errbit,
		__bnot 		= errbit,
		__bxor 		= errbit,
		--[[

		]]
		__call 		= function(this, tInputArgs)
			local tArgs		    = type(tInputArgs) == "table" and tInputArgs or nil;
			local tStructActual = {};--TODO create __factory and __isReadOnly values and deserizlize;
            local tStructDecoy  = {};

			--setup the default values first
			for sKey, tVals in pairs(tConstraint) do
				tStructActual[sKey] = {
					type 	= tVals.type,
					value 	= tVals.defaultvalue,--FIX if this is a table or object, it will shared...this is bad; clone it
				};
			end

			--next, try to process any valid input
			if (tArgs) then

				for sKey, vValue in pairs(tArgs) do
                    local sValType 		= type(vValue);
                    local bValueIsNull	= sValType == "null";

					--make certain the key exists in the tConstraint table
					if (rawtype(tConstraint[sKey]) == "nil") then
                        error("Error setting key in struct factory, '"..sSubType.."'.\nKey, '"..sKey.."', does not exist.", 3);
                    end

            		--handle cases of default tConstraint value types being null
					if (tStructActual[sKey].type == "null" and not bValueIsNull) then
                        tStructActual[sKey].type  = sValType;
                    end

                    --be sure the value type is correct
                    if (sValType ~= tStructActual[sKey].type) then
                        error(  "Error setting value at key, '${key}', in struct factory, '${subtype}'.\nType expected: ${expected}. Type given: ${given}." %
                                {subtype = sSubType, key= sKey, expected = tStructActual[sKey].type, given = sValType}, 3);
                    end

                    tStructActual[sKey].value = vValue;--TODO clone this too;
				end

			end

            --register the struct subtype with the serializer
            serializer.registerType(sSubType, tStructDecoy);

			--[[
			██╗███╗░░██╗░██████╗████████╗░█████╗░███╗░░██╗░█████╗░███████╗
			██║████╗░██║██╔════╝╚══██╔══╝██╔══██╗████╗░██║██╔══██╗██╔════╝
			██║██╔██╗██║╚█████╗░░░░██║░░░███████║██╔██╗██║██║░░╚═╝█████╗░░
			██║██║╚████║░╚═══██╗░░░██║░░░██╔══██║██║╚████║██║░░██╗██╔══╝░░
			██║██║░╚███║██████╔╝░░░██║░░░██║░░██║██║░╚███║╚█████╔╝███████╗
			╚═╝╚═╝░░╚══╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
			--factory instance object created by a call to the factory
			]]
			setmetatable(tStructDecoy,
            {
				__close 	= false,
				__concat	= errmathinstance,
				__div		= errmathinstance,
				__eq 		= eq,--TODO finish
				__gc		= false,
				__idiv		= errmathinstance,
				--__ipairs	= erriterateinstance,
				__le		= le,--TODO finish
				__len 		= errleninstance,
				__lt		= lt,--TODO finish
				__mod		= errmathinstance,
				__call 		= nil,
				__index 	= function(t, k)
                    local tIndex = tStructActual[k] or nil;

                    if not (tIndex) then
                        --TODO THROW ERROR
                    end

                    return tStructActual[k].value;
				end,
				__lt = function(l, r)
					return false;
				end,
				__mul		= errmathinstance,
				__name		= sSubType.."struct",
				__newindex 	= function(t, k, v)
                    local sIndexType = type(k);
                    local sValType 	 = type(v);

                    --check for immutability
                    if (bReadOnly) then
                        error("Attempt to modify read-only struct, '"..sSubType.."'.", 3);
                    end

                    if (sIndexType ~= "string") then
                        error("Attempt to index non-string key, '${key}' (${type}), in struct, '${struct}'." %
                        {key = tostring(k), type = sIndexType, struct = sSubType}, 3);
                    end

					--make certain the key exists in the table
					if (rawtype(tStructActual[k]) == "nil") then
                        error("Attempt to index nonexistent key, '${key}', in struct, '${struct}'." %
                        {key = k, struct = sSubType}, 3);
                    end

                    if (sValType == "nil") then
                        error("Attempt to set key, '${key}' (${type}), in struct, '${struct}' to nil." %
                        {key = tostring(k), type = sIndexType, struct = sSubType}, 3);
                    end

					--handle cases of default value types being null
					if (tStructActual[k].type == "null") then
						tStructActual[k].type = sValType;
					end

                    --be sure the value type is correct
                    if (sValType ~= tStructActual[k].type) then
                        error(  "Error setting value at key, '${key}', in struct, '${subtype}'.\nType expected: ${expected}. Type given: ${given}." %
                                {subtype = sSubType, key = tostring(k), expected = tStructActual[k].type, given = sValType}, 3);
                    end

                    --if nothing has gone awry, set the value
                    tStructActual[k].value = v;
				end,
                __pairs = function(t)
                    return function(_, k)
                        local v;
                        k, v = next(tStructActual, k)

                        if k then
                            return k, v.value
                        end

                    end, t, nil
                end,
				__pow		= errmathinstance,
                __serialize = function()--LEFT OFF HERE
                    --FINISH
                end,
				__shl  		= errbitinstance,
				__shr  		= errbitinstance,
				__sub		= errbitinstance,
				__subtype	= sSubType,
				__tostring	= tostr,--FINISH
				__type		= "struct",
				__unm		= errmathinstance,
			});

            return tStructDecoy;
		end,
		__close 	= false,
		__concat	= errmath,
		--__count 	= factoryscount,
		__div		= errmath,
		__eq 		= eq,
		__gc		= false,
		__idiv		= errmath,
		__index 	= dummy,
		__ipairs	= erriterate,
		__le		= le,--FINISH
		__len 		= errlen,
		__lt		= lt,--FINISH
		__mod		= errmath,
		--__mode,
		--__metatable	= nil,
		__mul		= errmath,
		__name		= "struct",
		__newindex 	= dummy,
		__pairs		= erriterate,
		__pow		= errmath,
		__shl  		= errbit,
		__shr  		= errbit,
        __serialize = function()
            return {
                constraint  = tConstraint,
                isReadOnly  = bReadOnly,
                name        = sSubType,
            };
        end,
		__sub		= errbit,
		__subtype	= sSubType,
		__tostring	= function()--TODO finish
			return "'"..sSubType.."' truct factory\nread only: "..tostring(bReadOnly)..'\n'..serialize(tConstraint);
		end,
		__type		= "struct",--NOTE these also need is functions if they don't have them already!!
		__unm		= errmath,
	});

	--save the metadata
	--local sMetaKey = bPrivate and "private" or "public";
	--tMetaData[sMetaKey].count = tMetaData[sMetaKey].count + 1;
	--tMetaData[sMetaKey].factories[sSubType] = {
	--	factory = tFactory,
	--	name 	= sSubType,
	--};
	tMetaData.count = tMetaData.count + 1;

	return tFactoryDecoy;
end
--[[
local function factorycount()
	--return tMetaData.public.count;
	return tMetaData.count;
end

local function getfactory(t, k)
	local tRet = nil;

	if (tMetaData.public.factories[k]) then
		tRet = tMetaData.public.factories[k].factory;
	end

	return tRet;
end]]
local tStructFactoryDecoy = {
    deserialize = function(tData)
        return struct(tData.name, tData.constraint, tData.isReadOnly);
    end,
};
return setmetatable(tStructFactoryDecoy,
{
	__call 		= createfactory,
	__index 	= function(t, k, v)
        return tStructFactoryDecoy[k] or nil;
    end,
	__len 	 	= factorycount,
	__newindex 	= dummy,
    __serialize = function()
        return "struct";
    end,
    __tostring = function()
        return "structfactory" --TODO do the abov emetatables need these too?
    end,
	__type 		= "structfactory",
});
