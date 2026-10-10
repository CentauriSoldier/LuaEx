--[[!
    @fqxn LuaEx.Libraries.struct
    @desc Fixed-field records built by named factories. Field types are fixed;
    a null default acquires its type on the first non-null assignment.
    Read-only records protect field bindings, not the contents of referenced objects.
    Defaults are copied for each instance; supplied values retain their identity.
    Instances compare by identity and support pairs, cloning and serialization.
    @ex
    require("LuaEx.init");

    -- Define the fields once, then create as many records as needed.
    local BulletFactory = structfactory("DoxBullet", {
        speed = 5,
        damage = 10,
        caliber = "9mm",
        enabled = false,
    });

    local oStandard = BulletFactory();
    local oHeavy = BulletFactory({damage = 25, caliber = ".45"});
    oHeavy.speed = 3;

    assert(oStandard.damage == 10);
    assert(oHeavy.damage == 25 and oHeavy.speed == 3);
    assert(oHeavy.enabled == false); -- false is a value, not a missing field.

    -- Only declared fields exist, and their types cannot change.
    assert(not pcall(function() oHeavy.damage = "high"; end));
    assert(not pcall(function() oHeavy.weight = 20; end));
    assert(not pcall(function() return oHeavy.weight; end));

    local tFields = {};
    for sKey, vValue in pairs(oHeavy) do
        tFields[sKey] = vValue;
    end
    assert(tFields.caliber == ".45" and tFields.enabled == false);
!]]
local _tFactories = {};
local _tFactoryObjects = setmetatable({}, {__mode = "k"});
local _tInstances = setmetatable({}, {__mode = "k"});
local _tReserved = {__name = true, __readOnly = true, deserialize = true};

local buildInstance;
local buildFactory;
local deserializeInstance;

local function fail(sMessage)
    error("Struct: "..sMessage, 3);
end

local function plainTable(vInput, sLabel)
    assert(type(vInput) == "table", "Struct: "..sLabel.." must be a plain table.");
end

--[[!
    @fqxn LuaEx.Libraries.struct.EnumKeys
    @desc Enum members may be field keys. Use the member itself when constructing,
    reading and assigning; its name string is a different key.
    @ex
    require("LuaEx.init");

    local Stat = enum("DoxStructStat", {"HEALTH", "ARMOR"}, nil, true);
    local StatsFactory = structfactory("DoxStats", {
        [Stat.HEALTH] = 100,
        [Stat.ARMOR] = 0,
    });

    local oStats = StatsFactory({[Stat.ARMOR] = 15});
    oStats[Stat.HEALTH] = 75;

    assert(oStats[Stat.HEALTH] == 75 and oStats[Stat.ARMOR] == 15);
    assert(not pcall(function() return oStats.HEALTH; end));
!]]
local function validKey(vKey)
    local bRet = rawtype(vKey) == "string" or require("LuaEx.lib.enum").isitem(vKey);
    return bRet;
end

-- Preserve public type metadata without exposing lifecycle hooks or mutable metadata.
-- Struct loads before table hooks, so this facade has no dependency on table.readonly.
local function protect(oDecoy, tMeta)
    local tInfo = {__type = tMeta.__type, __subtype = tMeta.__subtype, __name = tMeta.__name};
    local MetaDecoy = {};

    rawsetmetatable(MetaDecoy, {
        __index = tInfo,
        __newindex = function() fail("metadata is read-only."); end,
        __metatable = false,
    });

    tMeta.__metatable = MetaDecoy;
    rawsetmetatable(oDecoy, tMeta);
end

local function validateFields(tValues, tTypes)
    plainTable(tValues, "field values");

    for vKey, vValue in pairs(tValues) do
        local sExpected = tTypes[vKey];
        assert(sExpected ~= nil, "Struct: unknown field '"..tostring(vKey).."'.");
        local sGiven = type(vValue);
        assert(sGiven ~= "nil", "Struct: fields cannot be nil.");
        assert(sExpected == "null" or sGiven == sExpected or sGiven == "null",
               "Struct: field '"..tostring(vKey).."' expects "..sExpected..", got "..sGiven..".");
    end
end

local function copyTypes(tTypes)
    local tRet = {};

    for vKey, sType in pairs(tTypes) do
        tRet[vKey] = sType;
    end

    return tRet;
end

-- Allocate before copying values so the cloner can reconnect circular private state.
--[[!
    @fqxn LuaEx.Libraries.struct.CloningAndOwnership
    @desc Defaults are captured when the factory is defined and independently copied
    for each instance. Explicit overrides retain their supplied identity. Cloning
    copies current values and preserves aliases/cycles within the copied record.
    @ex
    require("LuaEx.init");

    local tDefault = {quantity = 1};
    local InventoryFactory = structfactory("DoxInventory", {stock = tDefault});
    tDefault.quantity = 99; -- The factory already owns a snapshot of this default.

    local oFirst = InventoryFactory();
    local oSecond = InventoryFactory();
    oFirst.stock.quantity = 5;
    assert(oSecond.stock.quantity == 1);

    local tSupplied = {quantity = 8};
    local oThird = InventoryFactory({stock = tSupplied});
    assert(rawequal(oThird.stock, tSupplied));

    local oCopy = clone(oThird);
    assert(oCopy.stock.quantity == 8 and not rawequal(oCopy.stock, tSupplied));
    oCopy.stock.quantity = 12;
    assert(oThird.stock.quantity == 8);
    assert(rawequal(clone(InventoryFactory), InventoryFactory));
!]]
local function newInstance(tFactory, tValues, tTypes)
    local InstanceDecoy = {};
    local tData = {factory = tFactory, values = tValues, types = tTypes};
    _tInstances[InstanceDecoy] = tData;

    protect(InstanceDecoy, {
        __type = "struct",
        __subtype = tFactory.name,
        __name = tFactory.name.." struct",

        __index = function(_, vKey)
            local vRet;

            if (vKey == "__name") then
                vRet = tFactory.name;
            elseif (vKey == "__readOnly") then
                vRet = tFactory.readOnly;
            else
                assert(tTypes[vKey] ~= nil, "Struct: unknown field '"..tostring(vKey).."'.");
                vRet = tData.values[vKey];
            end

            return vRet;
        end,

        __newindex = function(_, vKey, vValue)
            assert(not tFactory.readOnly, "Struct: cannot modify read-only '"..tFactory.name.."'.");
            assert(tTypes[vKey] ~= nil, "Struct: unknown field '"..tostring(vKey).."'.");
            assert(vValue ~= nil, "Struct: fields cannot be nil.");
            local sGiven = type(vValue);
            local sExpected = tTypes[vKey];
            assert(sExpected == "null" or sGiven == sExpected or sGiven == "null",
                   "Struct: field '"..tostring(vKey).."' expects "..sExpected..", got "..sGiven..".");

            if (sExpected == "null" and sGiven ~= "null") then
                tTypes[vKey] = sGiven;
            end

            tData.values[vKey] = vValue;
        end,

        __pairs = function()
            -- Do not expose the private values table as the iterator's state.
            return function(_, vKey)
                return next(tData.values, vKey);
            end, nil, nil;
        end,

        __clone = function(oSource)
            local CopyDecoy = newInstance(tFactory, {}, copyTypes(tTypes));
            cloner.registerCopy(oSource, CopyDecoy);
            _tInstances[CopyDecoy].values = clone(tData.values);

            return CopyDecoy;
        end,

        __serialize = function()
            return {factory = tFactory.decoy, readOnly = tFactory.readOnly,
                    values = tData.values, types = copyTypes(tTypes)};
        end,

        __tostring = function()
            return "'"..tFactory.name.."' struct (read-only: "..tostring(tFactory.readOnly)..")";
        end,
    });

    return InstanceDecoy;
end

buildInstance = function(tFactory, tInput)
    assert(tInput == nil or type(tInput) == "table", "Struct: initializer must be a plain table or nil.");

    if (tInput ~= nil) then
        validateFields(tInput, tFactory.types);
    end

    -- Copy all defaults together to preserve aliases within one instance, while
    -- starting an independent traversal for defaults owned by another instance.
    local tValues = cloner.cloneIndependent(tFactory.defaults);
    local tTypes = copyTypes(tFactory.types);

    for vKey, vValue in pairs(tInput or {}) do
        assert(not tFactory.readOnly or type(vValue) ~= "null", "Struct: read-only fields cannot be null.");
        tValues[vKey] = vValue;

        if (tTypes[vKey] == "null" and type(vValue) ~= "null") then
            tTypes[vKey] = type(vValue);
        end
    end

    return newInstance(tFactory, tValues, tTypes);
end

--[[!
    @fqxn LuaEx.Libraries.struct.deserialize
    @pulsarlua function struct.deserialize
    @desc Restores a record snapshot. Accepts current factory references and legacy
    factory names. Chosen null-field types and read-only policy are validated before allocation.
    @param table tData The snapshot returned by the instance serialization hook.
    @ret struct The restored record.
    @ex
    require("LuaEx.init");

    local ProfileFactory = structfactory("DoxProfile", {score = 0, owner = null});
    local oProfile = ProfileFactory({score = 42});
    oProfile.owner = "James"; -- First non-null value binds this field to string.
    oProfile.owner = null; -- Clearing it does not forget that binding.
    assert(not pcall(function() oProfile.owner = 123; end));

    -- Global persistence reconstructs the factory dependency and current fields.
    local sSave = serialize(oProfile);
    local oRestored = deserialize(sSave);
    assert(oRestored.score == 42 and oRestored.owner == null);
    assert(not pcall(function() oRestored.owner = false; end));
    oRestored.owner = "Kaeley";
    assert(oProfile.owner == null);

    -- Explicit restoration takes a snapshot table, not the serialized string.
    -- Omit types only for legacy snapshots without historical null-field bindings.
    local oExplicit = ProfileFactory.deserialize({
        factory = ProfileFactory,
        readOnly = false,
        values = {score = 7, owner = "Alex"},
        types = {score = "number", owner = "string"},
    });
    assert(oExplicit.score == 7 and oExplicit.owner == "Alex");
!]]
deserializeInstance = function(tData)
    plainTable(tData, "snapshot");
    local tFactory = rawtype(tData.factory) == "string" and _tFactories[tData.factory]
                     or _tFactoryObjects[tData.factory];
    assert(tFactory, "Struct: snapshot factory is not registered.");
    assert(tData.readOnly == nil or tData.readOnly == tFactory.readOnly,
           "Struct: snapshot read-only policy conflicts with its factory.");
    validateFields(tData.values, tFactory.types);
    local tTypes = copyTypes(tFactory.types);

    if (tData.types ~= nil) then
        plainTable(tData.types, "snapshot types");

        for vKey, sType in pairs(tData.types) do
            assert(tTypes[vKey] ~= nil and rawtype(sType) == "string" and sType ~= "nil" and sType ~= "",
                   "Struct: invalid snapshot field type.");
            assert(tTypes[vKey] == "null" or tTypes[vKey] == sType, "Struct: snapshot changes a declared field type.");
            tTypes[vKey] = sType;
        end
    end

    for vKey in pairs(tTypes) do
        assert(tData.values[vKey] ~= nil, "Struct: snapshot is missing field '"..tostring(vKey).."'.");
        assert(tData.types == nil or tData.types[vKey] ~= nil, "Struct: snapshot is missing a field type.");
        assert(not tFactory.readOnly or type(tData.values[vKey]) ~= "null", "Struct: read-only fields cannot be null.");

        if (tTypes[vKey] == "null" and type(tData.values[vKey]) ~= "null") then
            tTypes[vKey] = type(tData.values[vKey]);
        end
    end

    validateFields(tData.values, tTypes);
    -- Decoder-provided values already form an owned graph; keep their aliases.
    return newInstance(tFactory, tData.values, tTypes);
end

--[[!
    @fqxn LuaEx.Libraries.structfactory.__call
    @pulsarlua function structfactory
    @desc Defines a named fixed-field factory. Keys may be strings or enum members;
    metadata names are reserved. Defaults are captured independently. A read-only
    factory cannot have null defaults. Calling the returned factory accepts optional field overrides.
    @param string sName Unique non-blank factory name.
    @param table tDefaults Nonempty field defaults.
    @param boolean bReadOnly Optional; defaults to false.
    @ret structfactory The record factory.
    @ex
    require("LuaEx.init");

    local SettingsFactory = structfactory("DoxFrozenSettings", {
        enabled = false,
        options = {volume = 50},
    }, true);
    local oSettings = SettingsFactory({enabled = true});

    assert(oSettings.__name == "DoxFrozenSettings" and oSettings.__readOnly);
    assert(not pcall(function() oSettings.enabled = false; end));
    assert(not pcall(function() oSettings.options = {}; end));

    -- Read-only protects bindings; a referenced table's contents are still mutable.
    oSettings.options.volume = 25;
    assert(oSettings.options.volume == 25);

    local oRestored = deserialize(serialize(oSettings));
    assert(oRestored.enabled and oRestored.options.volume == 25);
    assert(not pcall(function() oRestored.enabled = false; end));
    assert(not pcall(structfactory, "DoxInvalidFrozen", {owner = null}, true));
!]]
buildFactory = function(sName, tDefaults, bReadOnly)
    assert(rawtype(sName) == "string" and sName:find("%S"), "Struct: name must be a non-blank string.");
    assert(_tFactories[sName] == nil, "Struct: factory '"..sName.."' already exists.");
    assert(bReadOnly == nil or rawtype(bReadOnly) == "boolean", "Struct: read-only flag must be boolean.");
    plainTable(tDefaults, "defaults");
    local tTypes = {};
    local nCount = 0;

    for vKey, vValue in pairs(tDefaults) do
        assert(validKey(vKey) and not _tReserved[vKey], "Struct: invalid or reserved field '"..tostring(vKey).."'.");
        assert(not bReadOnly or type(vValue) ~= "null", "Struct: read-only defaults cannot be null.");
        tTypes[vKey] = type(vValue);
        nCount = nCount + 1;
    end

    assert(nCount > 0, "Struct: defaults cannot be empty.");
    local tFactory = {name = sName, readOnly = bReadOnly == true, types = tTypes,
                      defaults = cloner.cloneIndependent(tDefaults), decoy = {}};

    protect(tFactory.decoy, {
        __type = "structfactory",
        __subtype = sName,
        __name = sName.." struct factory",
        __call = function(_, tInput, ...)
            assert(select("#", ...) == 0, "Struct: expected at most one initializer.");
            return buildInstance(tFactory, tInput);
        end,
        __index = function(_, vKey)
            local vRet;

            if (vKey == "__name") then
                vRet = sName;
            elseif (vKey == "__readOnly") then
                vRet = tFactory.readOnly;
            elseif (vKey == "deserialize") then
                vRet = function(tData)
                    local oRet = deserializeInstance(tData);
                    assert(_tInstances[oRet].factory == tFactory, "Struct: snapshot belongs to another factory.");
                    return oRet;
                end;
            else
                fail("unknown factory member '"..tostring(vKey).."'.");
            end

            return vRet;
        end,
        __newindex = function() fail("factory is read-only."); end,
        __clone = function() return tFactory.decoy; end,
        __serialize = function()
            return {name = sName, readOnly = tFactory.readOnly, constraints = tFactory.defaults};
        end,
        __tostring = function()
            return "'"..sName.."' struct factory (read-only: "..tostring(tFactory.readOnly)..")";
        end,
    });

    -- Publish only after validation, copying and metatable construction succeed.
    _tFactories[sName] = tFactory;
    _tFactoryObjects[tFactory.decoy] = tFactory;

    return tFactory.decoy;
end

--[[!
    @fqxn LuaEx.Libraries.structfactory.deserialize
    @pulsarlua function structfactory.deserialize
    @desc Restores a factory definition. An existing name is reused only when its
    field names/types and read-only policy agree. Existing defaults remain authoritative.
    @param table tData Factory snapshot with name, constraints and readOnly.
    @ret structfactory The restored or existing factory.
    @ex
    require("LuaEx.init");

    -- A definition snapshot can create a factory that does not exist yet.
    local PointFactory = structfactory.deserialize({
        name = "DoxStructPoint",
        readOnly = false,
        constraints = {x = 0, y = 0},
    });
    local oPoint = PointFactory({x = 3, y = 4});
    assert(oPoint.x == 3 and oPoint.y == 4);

    -- A saved existing factory resolves to the same registered factory identity.
    local RestoredFactory = deserialize(serialize(PointFactory));
    assert(rawequal(RestoredFactory, PointFactory));

    -- An existing name cannot silently acquire a different field schema.
    assert(not pcall(structfactory.deserialize, {
        name = "DoxStructPoint",
        readOnly = false,
        constraints = {x = "wrong", y = 0},
    }));
!]]
local function deserializeFactory(tData)
    plainTable(tData, "factory snapshot");
    assert(rawtype(tData.name) == "string" and tData.name:find("%S"), "Struct: invalid snapshot factory name.");
    local bReadOnly = tData.readOnly;
    if (bReadOnly == nil) then bReadOnly = tData.isReadOnly; end
    assert(bReadOnly == nil or rawtype(bReadOnly) == "boolean", "Struct: invalid snapshot read-only flag.");
    plainTable(tData.constraints, "factory snapshot defaults");
    local tExisting = _tFactories[tData.name];
    local Factory;

    if (tExisting) then
        assert(tExisting.readOnly == (bReadOnly == true), "Struct: factory read-only policy conflict.");
        local nCount = 0;

        for vKey, vValue in pairs(tData.constraints) do
            assert(tExisting.types[vKey] == type(vValue), "Struct: factory schema conflict.");
            nCount = nCount + 1;
        end

        for vKey in pairs(tExisting.types) do
            assert(tData.constraints[vKey] ~= nil, "Struct: factory schema is missing a field.");
        end

        assert(nCount > 0, "Struct: factory defaults cannot be empty.");
        Factory = tExisting.decoy;
    else
        Factory = buildFactory(tData.name, tData.constraints, bReadOnly);
    end

    return Factory;
end

local StructDecoy = {};
local StructFactoryDecoy = {};

--[[!
    @fqxn LuaEx.Libraries.struct.__call
    @pulsarlua function struct
    @desc Defines a factory and returns its default instance. Use structfactory
    when multiple instances of the same named record are needed.
    @param string sName Unique non-blank factory name.
    @param table tDefaults Nonempty field defaults.
    @param boolean bReadOnly Optional; defaults to false.
    @ret struct The default record.
    @ex
    require("LuaEx.init");

    -- For a single record, define its factory and create its default instance together.
    local oWindow = struct("DoxWindowSize", {width = 800, height = 600});
    oWindow.width = 1024;
    assert(oWindow.width == 1024 and oWindow.height == 600);

    local oCopy = clone(oWindow);
    oCopy.height = 768;
    assert(oWindow.height == 600 and oCopy.height == 768);

    -- Names identify factory definitions; use a factory for repeated construction.
    assert(not pcall(struct, "DoxWindowSize", {width = 1, height = 1}));
!]]
protect(StructDecoy, {
    __type = "structfactory",
    __call = function(_, sName, tDefaults, bReadOnly, ...)
        assert(select("#", ...) == 0, "Struct: too many constructor arguments.");
        local Factory = buildFactory(sName, tDefaults, bReadOnly);
        return Factory();
    end,
    __index = {deserialize = deserializeInstance},
    __newindex = function() fail("struct constructor is read-only."); end,
    __clone = function() return StructDecoy; end,
    __serialize = function() return "struct"; end,
    __tostring = function() return "struct"; end,
});

protect(StructFactoryDecoy, {
    __type = "structfactorybuilder",
    __call = function(_, sName, tDefaults, bReadOnly, ...)
        assert(select("#", ...) == 0, "Struct: too many constructor arguments.");
        return buildFactory(sName, tDefaults, bReadOnly);
    end,
    __index = {deserialize = deserializeFactory},
    __newindex = function() fail("struct factory constructor is read-only."); end,
    __clone = function() return StructFactoryDecoy; end,
    __serialize = function() return "structfactory"; end,
    __tostring = function() return "structfactory"; end,
});

local _cSerializer = require("LuaEx.lib.serializer");
_cSerializer.registerFactory(StructDecoy, {name = "struct", types = {"struct"}});
_cSerializer.registerFactory(StructFactoryDecoy, {name = "structfactory", types = {"structfactory"}});

return {struct = StructDecoy, structfactory = StructFactoryDecoy};
