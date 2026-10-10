--[[!
    @fqxn LuaEx.cloner
    @pulsarlua table cloner
    @desc Read-only copying service. Public operations are clone, cloneIndependent,
    registerCopy, and registerFactory. Hooks define domain-specific copies;
    ordinary table values are copied recursively using one traversal record.
!]]

-- Each coroutine owns its traversal, so a yielding hook cannot mix two copies.
local _tContexts  = setmetatable({}, {__mode = "k"});
local _tFactories = {};

local function getContext()
    local oThread = coroutine.running();
    return _tContexts[oThread], oThread;
end

--[[!
    @fqxn LuaEx.cloner.registerCopy
    @pulsarlua function cloner.registerCopy
    @desc Records a hook's newly allocated object before its contents are copied.
    Call from __clone to reconnect circular references through private object state.
    Nested clone calls share the current traversal. Existing hooks need no change
    unless their state can lead back to an object whose hook is still running.
    @param table oSource The source currently being copied by its __clone hook.
    @param table oCopy The new object allocated by that hook.
    @ex cloner.registerCopy(this, oCopy);
!]]
local function registerCopy(oSource, oCopy)
    local tContext = getContext();

    assert(tContext and tContext.active[oSource], "registerCopy must be called inside the source object's clone hook.");
    assert(rawtype(oCopy) == "table", "The registered copy must be an object or table.");
    assert(tContext.seen[oSource] == nil or rawequal(tContext.seen[oSource], oCopy), "A different copy has already been registered.");

    tContext.seen[oSource] = oCopy;
end

local copyValue;

local function copyTable(tSource, bIgnoreMetaTable, tContext, tMeta)
    local tCopy = {};
    tContext.seen[tSource] = tCopy;

    -- Keys retain identity: tables used as lookup keys remain usable by callers.
    -- Allocate before descent so values can refer to any earlier copied table.
    for vKey, vValue in pairs(tSource) do
        rawset(tCopy, vKey, copyValue(vValue, bIgnoreMetaTable, tContext));
    end

    if (not bIgnoreMetaTable and tMeta) then
        rawsetmetatable(tCopy, tMeta);
    end

    return tCopy;
end

copyValue = function(vItem, bIgnoreMetaTable, tContext)
    local sRawType = rawtype(vItem);
    local sType    = type(vItem);
    local vCopy;

    if (sRawType == "table" and tContext.seen[vItem] == nil and
        not tContext.done[vItem] and not tContext.active[vItem]) then
        tContext.order[#tContext.order + 1] = vItem;
    end

    if (sRawType ~= "table") then
        assert(sRawType ~= "thread" and sRawType ~= "userdata", "Cloning for type '"..sRawType.."' has not been implemented.");
        vCopy = vItem;

    elseif (tContext.seen[vItem] ~= nil or tContext.done[vItem]) then
        vCopy = tContext.seen[vItem];

    elseif (sType == "class" or sType == "null" or rawequal(_tFactories[sType], vItem)) then
        vCopy = vItem;
        tContext.seen[vItem] = vCopy;

    else
        -- Internal copying needs the actual metatable, not a protected public facade.
        -- It is shared rather than copied, preserving behavior and protection.
        local tMeta = debug.getmetatable(vItem);
        local fClone = tMeta and tMeta.__clone;

        if (rawtype(fClone) == "function") then
            assert(not tContext.active[vItem], "Circular clone hook for type '"..sType.."': register the new object with cloner.registerCopy before copying its contents.");
            tContext.active[vItem] = true;

            vCopy = fClone(vItem);

            assert(tContext.seen[vItem] == nil or rawequal(tContext.seen[vItem], vCopy), "Clone hook returned a different object than its registered copy.");

            tContext.active[vItem] = nil;
            tContext.seen[vItem] = vCopy;
            tContext.done[vItem] = true;

        elseif (sType == "table") then
            vCopy = copyTable(vItem, bIgnoreMetaTable, tContext, tMeta);

        else
            error("Cloner not found for item of type '"..sType.."'.", 2);
        end
    end

    return vCopy;
end;

--[[!
    @fqxn LuaEx.cloner.clone
    @pulsarlua function cloner.clone
    @desc Copies tables and cloneable objects while preserving repeated references
    and circular plain-table values. Explicit __clone hooks take precedence over
    table copying. Hooks own their object's contents and may use registerCopy for
    circular state. Table keys and metatables retain identity. Functions retain
    identity and captured variables; class factories, registered factories, and
    null retain identity. Class instances and other typed objects require __clone.
    Threads and userdata are unsupported. Also exposed globally as clone.
    Hook return values are retained as supplied, including false and nil.
    @param any vItem The value to copy.
    @param boolean bIgnoreMetaTable Optional; defaults to false. Omits metatables
    from ordinary copied tables at every depth; does not disable __clone hooks.
    @ret any The copied value.
    @ex local tCopy = clone({value = 1});
!]]
local function clone(vItem, bIgnoreMetaTable)
    assert(bIgnoreMetaTable == nil or rawtype(bIgnoreMetaTable) == "boolean", "Ignore-metatable option must be a boolean.");

    local tContext, oThread = getContext();
    local bRoot = tContext == nil;

    if (bRoot) then
        tContext = {seen = {}, active = {}, done = {}, order = {}};
        _tContexts[oThread] = tContext;
    end

    -- Cleanup also runs after hook errors. Nested failures roll back their records
    -- if caught by a hook, leaving the enclosing traversal usable.
    local nCheckpoint = #tContext.order;
    local bOK, vCopy = pcall(copyValue, vItem, bIgnoreMetaTable == true, tContext);

    if (bRoot) then
        _tContexts[oThread] = nil;
    elseif (not bOK) then
        for nIndex = #tContext.order, nCheckpoint + 1, -1 do
            local oSource = tContext.order[nIndex];

            tContext.seen[oSource]   = nil;
            tContext.active[oSource] = nil;
            tContext.done[oSource]   = nil;
            tContext.order[nIndex]   = nil;
        end
    end

    if (not bOK) then
        error(vCopy, 0);
    end

    return vCopy;
end

--[[!
    @fqxn LuaEx.cloner.cloneIndependent
    @pulsarlua function cloner.cloneIndependent
    @desc Starts a separate copy traversal even inside an active clone hook.
    Class construction uses this for defaults: each new instance owns its own
    defaults rather than reusing copies made for another newly constructed instance.
    @param any vItem The value to copy.
    @param boolean bIgnoreMetaTable Optional; same meaning as clone.
    @ret any The independently copied value.
    @ex local tDefaults = cloner.cloneIndependent({value = 1});
!]]
local function cloneIndependent(vItem, bIgnoreMetaTable)
    local tOuter, oThread = getContext();
    _tContexts[oThread] = nil;

    local bOK, vCopy = pcall(clone, vItem, bIgnoreMetaTable);
    _tContexts[oThread] = tOuter;

    if (not bOK) then
        error(vCopy, 0);
    end

    return vCopy;
end

--[[!
    @fqxn LuaEx.cloner.registerFactory
    @pulsarlua function cloner.registerFactory
    @desc Registers a callable typed factory whose identity is retained by clone.
    Re-registering the same factory is harmless; a different factory using that
    type name is rejected. Registration never changes instance clone behavior.
    @param table xFactory A typed table with a callable metatable.
    @ex cloner.registerFactory(array);
!]]
local function registerFactory(xFactory)
    local sType = type(xFactory);
    local tMeta = rawtype(xFactory) == "table" and debug.getmetatable(xFactory);

    assert(rawtype(xFactory) == "table" and sType ~= "table" and tMeta and rawtype(tMeta.__call) == "function", "Expected a callable typed factory.");
    assert(_tFactories[sType] == nil or rawequal(_tFactories[sType], xFactory), "A different factory is already registered for type '"..sType.."'.");

    _tFactories[sType] = xFactory;
end

local _tClonerActual = {
    clone            = clone,
    cloneIndependent = cloneIndependent,
    registerCopy     = registerCopy,
    registerFactory  = registerFactory,
};

local ClonerDecoy = {};
local ClonerMeta = {
    __index = _tClonerActual,
    __newindex = function()
        error("Attempt to modify the read-only cloner.", 2);
    end,
    __metatable = false,
};

setmetatable(ClonerDecoy, ClonerMeta);
return ClonerDecoy;
