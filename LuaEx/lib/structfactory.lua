local rawtype 		= rawtype;
local pairs 		= pairs;
local setmetatable 	= setmetatable;
local type 			= type;


--[[
██╗      ██████╗  ██████╗ █████╗ ██╗
██║     ██╔═══██╗██╔════╝██╔══██╗██║
██║     ██║   ██║██║     ███████║██║
██║     ██║   ██║██║     ██╔══██║██║
███████╗╚██████╔╝╚██████╗██║  ██║███████╗
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝]]

local factory = {
    restrictedKeys = {},
    repo = {
        byName   = {},
        byObject = {},
    },
};
local struct = {
    restrictedKeys = {__readOnly = true, serialize = true},
    repo = {
        byName = {},
    },
};


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

local function validateName(sName)
    local bIsValidString = rawtype(sName) == "string" and sName:gsub("[%s]", "") ~= "";
    --TODO also check for class and enum names FIX tthese all need regsitered with the luaex table

    if not (bIsValidString) then
        error("Error creating struct factory. Argument 1 (name) must be a non-blank string.\nType given: "..type(sName)..'.', 3);
    end

    local bNameExists = rawtype(factory.repo.byName[sName]) ~= "nil";

    if (bNameExists) then
        error("Error creating struct factory. Factory of type '"..sName.."' already exists; Cannot overwrite.", 3);
    end

end

local function processPropertiesTable(sName, tProperties, tConstraint, bReadOnly)
    local tRet = {};

	if (type(tProperties) ~= "table") then
        error("Error creating read-only struct factory, '"..sName.."'.\nArgument 2 (Properies Input Table) must be of type table and have at least one key.", 3);
    end

    local bHasAtLeastOneKey = false;

	for vKey, vValue in pairs(tProperties) do

        --ensure all keys are valid strings
		if (rawtype(vKey) ~= "string") then
            error("Error creating struct factory, '"..sName.."' at key "..tostring(vKey)..".\nKey type expected: string. Type given: "..type(vKey), 3);
        end

        local sValType = type(vValue);

        --make sure this is not a restricted keys
        if (struct.restrictedKeys[vKey]) then
            error("Error creating struct factory, '"..sName.."' with key "..tostring(vKey)..".\nKey is restricted.", 3);
        end

        --check for null values if this is read-only
        if (bReadOnly and sValType == "null") then
            error("Error creating read-only struct factory, '"..sName.."'.\nValue at key '"..vKey.."' is null.", 3);
        end

		tRet[vKey] = {
			type 			= sValType,
			defaultvalue 	= vValue, --FIX if this is a table or object, it will shared...this is bad; clone it
		};

        --log the string key if it exists
        bHasAtLeastOneKey = true;
	end

	if not (bHasAtLeastOneKey) then
        error("Error creating read-only struct factory, '"..sName.."'.\nArgument 2 (Properies Input Table) must be of type table and have at least one key.", 3);
    end

    return tRet;
end

--TODO make sure the subtype name does not exist (because it could be an enum, class, etc.)
--TODO go through this to make sure all the values are accessing the correct tbales (tfactory, tFactory, etc.)




--[[
███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
█████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝
██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝
██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║
╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ]]


function factory.build(__IGNORE__, sName, tProperties, bReadOnlyCheck)
    validateName(sName);
    local bReadOnly     = rawtype(bReadOnlyCheck) == "boolean" and bReadOnlyCheck or false;
	local tConstraints  = processPropertiesTable(sName, tProperties, bReadOnly);

    local tFactoryData = {
        actual      = {
            __readOnly  = bReadOnly,
            __name      = sName,
            deserialize = function()--FINISH

            end,
        },
        constraints = tConstraints,
        decoy       = {}, --this is the returned factory object
        name        = sName, --TODO is this ever used"? Maybe for checks involving only the object type?
        readOnly    = bReadOnly,
    };

    --store the factory in the repo
    factory.repo.byName[sName]                = tFactoryData;
    factory.repo.byObject[tFactoryData.decoy] = tFactoryData;

    --set the metatable
    factory.setMetatable(sName);

    return tFactoryData.decoy;
end


function factory.setMetatable(sName)
    local tFactory = factory.repo.byName[sName]

    local tMeta = {
        __add 		= errmath,
        __band 		= errbit,
        __bor 		= errbit,
        __bnot 		= errbit,
        __bxor 		= errbit,
        __call 		= function (this, ...)
            return struct.build(sName, ...);
        end,
        __close 	= false,
        __concat	= errmath,
        --__count 	= factoryscount,
        __div		= errmath,
        __eq 		= eq,
        __gc		= false,
        __idiv		= errmath,
        __index 	= function(t, k)
            local vRet;

            if (rawtype(tFactory.actual[k]) == "nil") then
                error("Attempt to index nonexistent key, '${key}', in struct, '${structobject}'." % {key = tostring(k), structobject = sName}, 3);
            end


            return tFactory.actual[k];
        end,
        __ipairs	= erriterate,
        __le		= le,--FINISH
        __len 		= errlen,
        __lt		= lt,--FINISH
        __mod		= errmath,
        --__mode,
        __metaguard = true,
        --__metatable	= nil,
        __mul		= errmath,
        __name		= "struct",
        __newindex 	= function(t, k, v)
            error("Attempt to modify struct factory, '"..sName.."'");
        end,
        __pairs		= erriterate,
        __pow		= errmath,
        __shl  		= errbit,
        __shr  		= errbit,
        __serialize = function()
            local tRet = {
                constraints = {},
                name        = sName,
                readOnly    = tFactory.actual.__readOnly,
            };

            for k, v in pairs(tFactory.constraints) do
                tRet.constraints[k] = v.defaultvalue;
            end

            return tRet;
        end,
        __sub		= errbit,
        __subtype	= sName,
        __tostring	= function()--TODO finish
            return "'"..sName.."' struct factory\nread-only: "..tostring(tFactory.actual.__readOnly)..'\n'..serialize(tFactory.constraints);
        end,
        __type		= "structfactory",--NOTE these also need is functions if they don't have them already!!
        __unm		= errmath,
    };

    rawsetmetatable(tFactory.decoy, tMeta);
end


--[[
███████╗████████╗██████╗ ██╗   ██╗ ██████╗████████╗
██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝
███████╗   ██║   ██████╔╝██║   ██║██║        ██║
╚════██║   ██║   ██╔══██╗██║   ██║██║        ██║
███████║   ██║   ██║  ██║╚██████╔╝╚██████╗   ██║
╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝   ]]


function struct.build(sName, tInputArgs)
    local tArgs		    = type(tInputArgs) == "table" and tInputArgs or nil;
    local tFactory      = factory.repo.byName[sName];
    local tConstraints  = tFactory.constraints;
    local tStructActual = {};
    local tStructInfo   = {};
    local tStructDecoy  = {};

    --setup the default values first
    for sKey, tVals in pairs(tConstraints) do
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

            --make certain the key exists in the tConstraints table
            if (rawtype(tConstraints[sKey]) == "nil") then
                error("Error setting key in struct factory, '"..sName.."'.\nKey, '"..sKey.."', does not exist.", 3);
            end

            --handle cases of default tConstraints value types being null
            if (tStructActual[sKey].type == "null" and not bValueIsNull) then
                tStructActual[sKey].type  = sValType;
            end

            --be sure the value type is correct
            if (sValType ~= tStructActual[sKey].type) then
                error(  "Error setting value at key, '${key}', in struct factory, '${subtype}'.\nType expected: ${expected}. Type given: ${given}." %
                        {subtype = sName, key= sKey, expected = tStructActual[sKey].type, given = sValType}, 3);
            end

            tStructActual[sKey].value = vValue;--TODO clone this too;
        end

    end

    --set the reserved properties
    tStructInfo.__readOnly = tFactory.actual.__readOnly;
    tStructInfo.__factory  = tFactory.decoy;

    --set the reserved methods
    tStructActual.clone = function() --TODO FINISH

    end

    --set this struct's metatable
    struct.setMetatable(sName, tStructInfo, tStructActual, tStructDecoy);

    --register the struct type with the serializer
    --serializer.registerType(sName, tStructDecoy);

    return tStructDecoy;
end


function struct.setMetatable(sName, tStructInfo, tStructActual, tStructDecoy)
    local tMeta = {
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
            local vRet;
            local sActualType = rawtype(tStructActual[k]);
            local sInfoType;

            if (sActualType == "nil") then
                sInfoType = rawtype(tStructInfo[k]);

                if (sInfoType == "nil") then
                    error("Attempt to index nonexistent key, '${key}', in struct, '${structobject}'." % {key = tostring(k), structobject = sName}, 3);

                else
                    vRet = tStructInfo[k];
                end

            else
                vRet = tStructActual[k].value;
            end

            return vRet;
        end,
        __lt = function(l, r)
            return false;
        end,
        __mul		= errmathinstance,
        __name		= sName.." struct",
        __newindex 	= function(t, k, v)
            local sIndexType = type(k);
            local sValType 	 = type(v);

            --check for immutability
            if (bReadOnly) then
                error("Attempt to modify read-only struct, '"..sName.."'.", 3);
            end

            if (sIndexType ~= "string") then
                error("Attempt to index non-string key, '${key}' (${type}), in struct, '${struct}'." %
                {key = tostring(k), type = sIndexType, struct = sName}, 3);
            end

            --make certain the key exists in the table
            if (rawtype(tStructActual[k]) == "nil") then
                error("Attempt to index nonexistent key, '${key}', in struct, '${struct}'." %
                {key = k, struct = sName}, 3);
            end

            if (sValType == "nil") then
                error("Attempt to set key, '${key}' (${type}), in struct, '${struct}' to nil." %
                {key = tostring(k), type = sIndexType, struct = sName}, 3);
            end

            --handle cases of default value types being null
            if (tStructActual[k].type == "null") then
                tStructActual[k].type = sValType;
            end

            --be sure the value type is correct
            if (sValType ~= tStructActual[k].type) then
                error(  "Error setting value at key, '${key}', in struct, '${subtype}'.\nType expected: ${expected}. Type given: ${given}." %
                        {subtype = sName, key = tostring(k), expected = tStructActual[k].type, given = sValType}, 3);
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
            local tData = {
                factory  = sName,
                readOnly = tStructInfo.__readOnly,
                values   = {},
            };


            return tData;
        end,
        __shl  		= errbitinstance,
        __shr  		= errbitinstance,
        __sub		= errbitinstance,
        __subtype	= sName,
        __tostring	= function()
            return sName..'\nread-only: '..tStructInfo.__readOnly..'\n'..serialize(tStructActual);
        end,
        __type		= "struct",
        __unm		= errmathinstance,
    };

    rawsetmetatable(tStructDecoy, tMeta);
end





--[[
██████╗ ███████╗████████╗██╗   ██╗██████╗ ███╗   ██╗
██╔══██╗██╔════╝╚══██╔══╝██║   ██║██╔══██╗████╗  ██║
██████╔╝█████╗     ██║   ██║   ██║██████╔╝██╔██╗ ██║
██╔══██╗██╔══╝     ██║   ██║   ██║██╔══██╗██║╚██╗██║
██║  ██║███████╗   ██║   ╚██████╔╝██║  ██║██║ ╚████║
╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝]]


local tStructFactoryDecoy = {
    deserialize = function(tData)
        local  sName = tData.name;
        return factory.repo.byName[sName]       and
               factory.repo.byName[sName].decoy or
               factory.build(__IGNORE__, sName,
                             tData.constraints,
                             tData.isReadOnly);
    end,
};


return setmetatable(tStructFactoryDecoy,
{
	__call 		= factory.build,
	__index 	= function(t, k, v)
        return tStructFactoryDecoy[k] or nil;
    end,
	__len 	 	= factorycount,
	__newindex 	= dummy,--THROW ERROR HERE
    __serialize = function()
        return "structfactory";
    end,
    __tostring = function()
        return "structfactorybuilder";
    end,
	__type 		= "structfactorybuilder",
});
