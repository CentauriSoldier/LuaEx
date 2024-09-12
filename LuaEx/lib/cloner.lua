local loader = load or loadstring;

local function returnPure(vItem)
    return vItem;
end

local function unimplemented(vType)
    error("Cloning for type "..type(vType).." has not been implemented.");
end

local tPure = {
    ["boolean"]  = returnPure,
    ["function"] = returnPure,
    ["functionOLD"] = function(fItem)
        local sFunction = string.dump(fItem);
        return loader(sFunction);
    end,
    ["functionTEST"] = function(fItem)
        local dump = string.dump(fItem)  -- Serialize the function into bytecode

        local function loadWithUpvalues(dump, upvalues)
            local clonedFunc = load(dump)  -- Load the bytecode into a function

            -- Check if we need to set upvalues
            if upvalues and type(upvalues) == "table" then
                local i = 1
                local name, value = debug.getupvalue(fItem, i)
                while name do
                    -- Set the upvalue in the cloned function
                    debug.setupvalue(clonedFunc, i, upvalues[name])
                    i = i + 1
                    name, value = debug.getupvalue(fItem, i)
                end
            end

            return clonedFunc
        end

        -- Get the upvalues of the original function
        local upvalues = {}
        local i = 1
        local name, value = debug.getupvalue(fItem, i)
        while name do
            upvalues[name] = value
            i = i + 1
            name, value = debug.getupvalue(fItem, i)
        end

        -- Return a function that can load the bytecode with upvalues
        return function()
            return loadWithUpvalues(dump, upvalues)
        end
    end,
    ["nil"]      = returnPure,
    ["number"]   = returnPure,
    ["string"]   = returnPure,
    ["tableTEST"]    = function (tItem, bIgnoreMetaTable, tSeen)
        tSeen = tSeen or {}

        -- If we've already seen this table, return the already cloned version to handle self-references
        if tSeen[tItem] then
            return tSeen[tItem]
        end

        local tRet = {}
        tSeen[tItem] = tRet

        for vIndex, vItem in pairs(tItem) do
            -- Recursively clone nested tables
            if type(vItem) == "table" then
                tRet[vIndex] = clone(vItem, bIgnoreMetaTable, tSeen)
            else
                tRet[vIndex] = clone(vItem);
            end
        end

        -- Clone the metatable if not ignored
        if not bIgnoreMetaTable then
            local tMeta = getmetatable(tItem)
            if tMeta then
                setmetatable(tRet, tMeta)
            end
        end

        return tRet
    end,
    ["table"]    = function (tItem, bIgnoreMetaTable)
        local tRet = {};
        --clone each item in the table
        --if (type(tItem) == "table") then

            for vIndex, vItem in pairs(tItem) do
--TODO what about indices? those should probably not be cloned
                if (type(vItem) == "table") then --TODO account for self references

                    if  (tItem == vItem) then --self reference
                        rawset(tRet, vIndex, vItem);
                        --tRet[vIndex] = vItem;
                    else
                        rawset(tRet, vIndex, clone(vItem, bIgnoreMetaTable));
                        --tRet[vIndex] = clone(vItem, bIgnoreMetaTable);
                    end

                else
                    --rawset(tRet, vIndex, clone(vItem)); --TODO LEFT OFF HERE... This has to get fixed!
                    rawset(tRet, vIndex, clone(vItem, bIgnoreMetaTable));
                    --tRet[vIndex] = clone(vItem, bIgnoreMetaTable);
                end

            end

            --clone the metatable
            if (not bIgnoreMetaTable) then
                local tMeta = getmetatable(tItem);

                if (type(tMeta) == "table") then
                    setmetatable(tRet, tMeta);
                end

            end

        --end

        return tRet;
    end,
    ["thread"]   = unimplemented,
    ["userdata"] = unimplemented,
};

local tSynth = {
    ["array"]                   = function(aItem) return rawgetmetatable(aItem).__clone(aItem) end,
    ["class"]                   = function(cItem)--TODO is this ever called? We don't actually want to clone class objects (such as Point)
                                    --local tMeta = rawgetmetatable(cItem);
                                    --print(serialize(tMeta))
                                    --if (rawtype(tMeta.__clone) ~= "function") then
                                        --TODO get the class name and FIX this error ...make sure it works
                                    --    error("Class, '"..tostring(cItem).."', is not clonable.\n", 2);
                                    --end
                                    --no need to infuse cItem since it's already injected by the class
                                    --return rawgetmetatable(cItem).__clone(); --TODO FIX since we can't use the method above to validate clonability, we must do an xpcall!
                                    --return rawgetmetatable(cItem).__name;--QUESTION is this right? Is the name what should be returned or the __call metamethod?
                                    return cItem;
                                end,
    --["enum"]                    = function(eItem) return rawgetmetatable(eItem).__clone(eItem) end,
    ["null"]                    = returnPure,
    ["struct"]                  = function(rItem) return rawgetmetatable(rItem).__clone(rItem) end,
};

local function registerType(sType, oType) --TODO  do i need to require type string? Get this using type (do same for serializer 'registerType' function)
    local sErrorPrefix = "Error registering object type with cloner.\n";

    assert(rawtype(oType) == "table", sErrorPrefix.."Object must be of rawtype table.", 2);

    local tMeta = getmetatable(oType);

    assert(type(tMeta)                      == "table", sErrorPrefix.."Object of type '"..sType.."' does not have an accessible metatable.", 2);
    assert(type(sType)                      == "string" and sType:isvariablecompliant(true), sErrorPrefix.."Object must have a __type metatable index whose value is a unique, variable-compliant string.", 2);
    assert(type(tMeta.__clone)               == "function", sErrorPrefix.."Object ("..sType..") must have a __clone metamethod capable of creating the (equivilant) object instance.")
    assert(not tSynth[sType], sErrorPrefix.."Object of type "..sType.." already exists.");
    --assert(type(oType.clone)                == "function", sErrorPrefix.."Object must have a clone method capable of creating the (equivilant) object instance.", 2)

        tSynth[sType] = oType;
end


local function registerFactory(xFactory)
    local sType = type(xFactory);

    --make sure the type is valid
    if (sType == "table" or rawtype(xFactory) ~= "table") then
        error("Error registering factory with cloner.\nType, ${type} (of rawtype, ${rawtype}), is not a factory." % {type = sType, rawtype = rawtype(xFactory)}, 2);
    end

    --make sure it has a call metamethod
    local tMeta = rawgetmetatable(xFactory);

    if (tMeta and rawtype(tMeta.__call) == "function") then

        tSynth[sType] = function()
            return xFactory;
        end

    else
        error("Error registering factory with cloner.\nType, ${type}, is not a factory; does not have an accessible __call metamethod or type function." % {type = sType}, 2);
    end

end



local function clone(vItem, bIgnoreMetaTable)
    local sType = type(vItem);
    local vRet;
    local bFoundCloner = false;

    if (tPure[sType]) then
        vRet = tPure[sType](vItem, bIgnoreMetaTable);
        bFoundCloner = true;

    elseif (tSynth[sType]) then
        vRet = tSynth[sType](vItem);
        bFoundCloner = true;

    elseif(rawtype(vItem) == "table") then
        local tMeta = getmetatable(vItem);

        if (tMeta and rawtype(tMeta.__clone) == "function") then
            vRet = tMeta.__clone(vItem);
            bFoundCloner = true;
        end

    end

    if not (bFoundCloner) then
        --error(  "Error cloning item. Cloner not found for item of type ${type}:\n'${item}'." %
        --        {item = tostring(vItem), type = sType}, 2);
        error(  "Error cloning item. Cloner not found for item of type '${type}'." %
                {type = sType}, 2);
    end

    return vRet;
end


local tClonerActual = {
    clone           = clone,
    registerFactory = registerFactory,
    --registerType = registerType,
};
local tClonerDecoy  = {};
local tClonerMeta   = {
    __index = function(t, k)

        if (rawtype(tClonerActual[k]) ~= "nil") then
            return tClonerActual[k];
        end

    end,
    __newindex = function(t, k, v)
        error("Error: attempting to modify read-only cloner at index ${index} with ${value} (${type})." % {index = tostring(k), value = tostring(v), type = type(v)}, 2);
    end,--TODO remove the tostring as it sometimes fails if the item is a table without a __tostring metamethod
};

setmetatable(tClonerDecoy, tClonerMeta);
return tClonerDecoy;
