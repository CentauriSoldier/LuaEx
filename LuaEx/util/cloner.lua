local function returnPure(vItem)
    return vItem;
end

local function unimplemented(vType)
    error("Cloning for type "..type(vType).." has not been implemented.");
end

local tPure = {
    ["boolean"]  = returnPure,
    ["function"] = function(fItem) return load("return "..string.dump(fItem)) end,
    ["nil"]      = returnPure,
    ["number"]   = returnPure,
    ["string"]   = returnPure,
    ["table"]    = function (tItem, bIgnoreMetaTable)
    	local tRet = {};

    	--clone each item in the table
    	if (type(tItem) == "table") then

    		for vIndex, vItem in pairs(tItem) do

    			if (type(vItem) == "table" and tItem ~= vItem) then --TODO account for self references
    				rawset(tRet, vIndex, clone(vItem));
    			else
    				rawset(tRet, vIndex, vItem);
    			end

    		end

    		--clone the metatable
    		if (not bIgnoreMetaTable) then
    			local tMeta = getmetatable(tItem);

    			if (type(tMeta) == "table") then
    				setmetatable(tRet, tMeta);
    			end

    		end

    	end

    	return tRet;
    end,
    ["thread"]   = unimplemented,
    ["userdata"] = unimplemented,
};

local tSynth = {
    ["array"]                   = function(aItem) return aItem.clone(aItem) end,
    ["arrayfactory"]            = function() return array end,
    ["class"]                   = function(cItem)

                                    if (rawtype(cItem.clone) ~= "function") then
                                        --TODO get the class name
                                        error("Class is not clonable.", 2);
                                    end

                                    return cItem.clone()
                                end,
    --["clausum"]                 = unimplemented,
    ["enum"]                    = function(eItem) return eItem.clone(eItem) end,
    ["null"]                    = returnPure,
    ["struct"]                  = function(rItem) return rItem.clone(rItem) end,
    ["structfactory"]           = function(xItem) return xItem.clone(xItem) end,
    ["structfactorybuilder"]    = function() return structfactory end,
};

local function registerType(sType, oType) --TODO  do i need to require type string? Get this using type (do same for serializer 'registerType' function)
    local sErrorPrefix = "Error registering object type with cloner.\n";

    assert(rawtype(oType) == "table", sErrorPrefix.."Object must be of rawtype table.", 2);

    local tMeta = getmetatable(oType);

    assert(type(tMeta)                      == "table", sErrorPrefix.."Object of type '"..sType.."' does not have an accessible metatable.", 2);
    assert(type(sType)                      == "string" and sType:isvariablecompliant(true), sErrorPrefix.."Object must have a __type metatable index whose value is a unique, variable-compliant string.", 2);
    --assert(not tPackables[sType] and not tNonPackables[sType], sErrorPrefix.."Object already exists.");
    assert(type(oType.clone)                == "function", sErrorPrefix.."Object must have a clone method capable of creating the (equivilant) object instance.", 2)

        tSynth[sType] = oType;
end






local function clone(vItem, bIgnoreMetaTable)
    local sType = type(vItem);
    local vRet;

    if (tPure[sType]) then
        vRet = tPure[sType](vItem, bIgnoreMetaTable);
    elseif (tSynth[sType]) then
        vRet = tSynth[sType](vItem);
    elseif (rawtype(vItem) == "table") then
        local fClone = rawget(vItem, "clone");

        if (rawtype(fClone) == "function") then
            vRet = fClone(vItem);
        end

    else
        --THROW ERROR
    end

    return vRet;
end


local tClonerActual = {
    clone = clone,
    registerType = registerType,
};
local tClonerDecoy  = {};
local tClonerMeta   = {
    __index = function(t, k)

        if (rawtype(tClonerActual[k]) ~= "nil") then
            return tClonerActual[k];
        end

    end,
    __newindex = function(t, k, v)
        error("Error: attempting to modify read-only cloner at index ${index} with ${value} ${(type)}." % {index = tostring(k), value = tostring(v), type = type(v)}, 2);
    end,
};

setmetatable(tClonerDecoy, tClonerMeta);
return tClonerDecoy;
