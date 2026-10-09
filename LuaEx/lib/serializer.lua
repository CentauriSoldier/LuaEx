--[[!
    @fqxn LuaEx.Libraries.serializer
    @desc Serializes LuaEx values as Lua expressions and restores them in the
    current LuaEx environment. Tables and Lua closures use a graph representation
    to preserve shared references, table keys, cycles, and captured upvalue cells.
    Object hooks define saved state; their matching factories restore it. Plain
    table metatables are omitted. Data is executable Lua and must be trusted.
    Bytecode requires a compatible Lua runtime. Threads/userdata and cycles through
    object hooks are rejected explicitly; objects need a staged restoration API
    before their cyclic private state can be reconstructed safely.
!]]
local _tRegistrations = {};
local _tSessions = setmetatable({}, {__mode = "k"});
local _tReadEnvironments = setmetatable({}, {__mode = "k"});
local _tNamedFactories = {};
local _tFactoryReferences = setmetatable({}, {__mode = "k"});

local encodeValue;
local serialize;
local registerFactory;

local function quote(sValue)
    return string.format("%q", sValue);
end

local function numberLiteral(nValue)
    local sValue;

    if (nValue ~= nValue) then sValue = "(0/0)";
    elseif (nValue == math.huge) then sValue = "math.huge";
    elseif (nValue == -math.huge) then sValue = "-math.huge";
    elseif (nValue == 0 and 1 / nValue == -math.huge) then sValue = "-0.0";
    elseif (math.type and math.type(nValue) == "integer") then
        sValue = nValue == math.mininteger and "math.mininteger" or tostring(nValue);
    else
        sValue = string.format("%.17g", nValue):gsub(",", ".");
        if (not sValue:find("[%.eE]")) then sValue = sValue..".0"; end
    end

    return sValue;
end

local function primitiveLiteral(vValue)
    local sType = rawtype(vValue);
    local sResult;

    if (sType == "string") then sResult = quote(vValue);
    elseif (sType == "number") then sResult = numberLiteral(vValue);
    elseif (sType == "nil") then sResult = "nil";
    elseif (sType == "boolean") then sResult = vValue and "true" or "false";
    else error("Expected a primitive serialized value.", 2); end

    return sResult;
end

-- Resolve names by lookup rather than treating type names as executable code.
local function lookup(sPath)
    assert(rawtype(sPath) == "string" and sPath:match("^[%a_][%w_%.]*$") and
           not sPath:find("%.%.") and sPath:sub(-1) ~= ".", "Invalid serialized reference path.");
    local vValue = _G;

    if (_tNamedFactories[sPath]) then vValue = _tNamedFactories[sPath];
    else

        for sPart in sPath:gmatch("[^%.]+") do
            assert(rawtype(vValue) == "table", "Serialized reference is not available: "..sPath);
            vValue = vValue[sPart];
        end
    end

    assert(vValue ~= nil, "Serialized reference is not available: "..sPath);
    return vValue;
end

local function deserializerFor(sType)
    local tRegistered = _tRegistrations[sType];
    local fRestore, bContext;

    if (tRegistered and tRegistered.restore) then
        fRestore, bContext = tRegistered.restore, true;
    else
        local oFactory = tRegistered and tRegistered.factory or lookup(sType);
        local bOK;
        bOK, fRestore = pcall(function() return oFactory.deserialize; end);
        assert(bOK and rawtype(fRestore) == "function", "Type '"..sType.."' has no deserialize function.");
    end

    return fRestore, bContext;
end

local function descriptorExpression(tValue)
    local sResult;

    if (tValue.node) then sResult = "__lx["..tValue.node.."]";
    elseif (tValue.reference) then sResult = tValue.reference;
    elseif (tValue.global) then sResult = "_G";
    else sResult = primitiveLiteral(tValue.value); end

    return sResult;
end

local function encodeFunction(fValue, tSession, tNode)
    local bOK, sBytecode = pcall(string.dump, fValue);
    assert(bOK, "Native C functions cannot be serialized as Lua bytecode.");
    tNode.kind = "function";
    tNode.bytecode = base64.enc(sBytecode);
    tNode.upvalues = {};

    local nIndex = 1;
    local sName, vValue = debug.getupvalue(fValue, nIndex);

    while (sName) do
        local oCell = debug.upvalueid(fValue, nIndex);
        local nCell = tSession.cells[oCell];

        if (not nCell) then
            nCell = tSession.cellCount + 1;
            tSession.cellCount = nCell;
            tSession.cells[oCell] = nCell;
        end

        -- The global environment is a runtime binding, not a snapshot of every global.
        local tValue = sName == "_ENV" and rawequal(vValue, _G) and {global = true} or encodeValue(vValue, tSession);
        tNode.upvalues[#tNode.upvalues + 1] = {index = nIndex, cell = nCell, value = tValue};
        nIndex = nIndex + 1;
        sName, vValue = debug.getupvalue(fValue, nIndex);
    end
end

local function encodeObject(vValue, tSession, tNode, sType, tMeta)
    tNode.kind = "object";
    tNode.type = sType;
    tNode.dependencies = {};
    tSession.active[vValue] = true;
    local tPrevious = tSession.hook;
    tSession.hook = tNode;

    local vState = tMeta.__serialize(vValue);
    local tRegistered = _tRegistrations[sType];
    local bReference, oReferenced;
    if (rawtype(vState) == "string") then bReference, oReferenced = pcall(lookup, vState); end

    if (bReference and rawequal(oReferenced, vValue)) then
        -- Existing class factories already declare their own symbolic name through
        -- __serialize. Honor that generic protocol without editing class files.
        assert(rawtype(tMeta.__call) == "function", "A self-declared factory must be callable.");
        registerFactory(vValue, {name = vState});
        tNode.kind, tNode.path = "reference", vState;
    elseif (sType == "table" or (tRegistered and tRegistered.direct)) then
        if (tRegistered and tRegistered.direct) then
            assert(rawtype(vState) == "string", "Direct serialization hook must return a Lua expression string.");
        end
        tNode.kind = "expression";
        if (rawtype(vState) == "string") then tNode.expression = vState;
        else tNode.state = encodeValue(vState, tSession); end
    else
        deserializerFor(sType);

        if (rawtype(vState) == "string") then
            tNode.expression = vState;
        else
            tNode.state = encodeValue(vState, tSession);
        end
    end

    tSession.hook = tPrevious;
    tSession.active[vValue] = nil;
end

encodeValue = function(vValue, tSession)
    local sRawType = rawtype(vValue);
    local sType = type(vValue);
    local tResult;

    if (sRawType == "nil" or sRawType == "number" or sRawType == "string" or sRawType == "boolean") then
        tResult = {value = vValue};
    elseif (sType == "null") then
        tResult = {reference = "null"};
    elseif (sRawType == "table" or sRawType == "function") then
        local nID = tSession.seen[vValue];

        if (nID) then
            assert(not tSession.active[vValue], "Circular state through a serialization hook for type '"..sType.."' is not supported.");
        else
            nID = #tSession.nodes + 1;
            local tNode = {};
            tSession.nodes[nID] = tNode;
            tSession.sources[nID] = vValue;
            tSession.seen[vValue] = nID;

            if (sRawType == "function") then
                encodeFunction(vValue, tSession, tNode);
            else
                local sReference = _tFactoryReferences[vValue];

                local tMeta = debug.getmetatable(vValue);
                if (sType == "table" and tMeta and rawtype(tMeta.__type) == "string") then
                    sType = tMeta.__type;
                end
                if (tMeta and tMeta.__serialtype) then sType = tMeta.__serialtype; end

                if (not sReference and tMeta and rawtype(tMeta.__serialref) == "function") then
                    local sPath = tMeta.__serialref(vValue);
                    local bOK, oExisting = pcall(lookup, sPath);
                    if (bOK and rawequal(oExisting, vValue)) then sReference = sPath; end
                end

                if (sReference) then
                    tNode.kind, tNode.path = "reference", sReference;
                elseif (tMeta and rawtype(tMeta.__serialize) == "function") then
                    encodeObject(vValue, tSession, tNode, sType, tMeta);
                elseif (sType == "table") then
                    tNode.kind, tNode.entries = "table", {};

                    for k, v in pairs(vValue) do
                        tNode.entries[#tNode.entries + 1] = {key = encodeValue(k, tSession), value = encodeValue(v, tSession)};
                    end
                else
                    error("Type '"..sType.."' has no serialization hook.", 2);
                end
            end
        end

        tResult = {node = nID};
    else
        error("Serialization for type '"..sRawType.."' has not been implemented.", 2);
    end

    return tResult;
end;

-- The wire description itself contains no cyclic tables, only numeric node references.
local function formatData(vValue, nIndent)
    local sResult;

    if (rawtype(vValue) == "table") then
        local tParts = {"{"};
        local sPad = string.rep("    ", nIndent + 1);

        for k, v in pairs(vValue) do
            tParts[#tParts + 1] = sPad.."["..primitiveLiteral(k).."] = "..formatData(v, nIndent + 1)..",";
        end

        tParts[#tParts + 1] = string.rep("    ", nIndent).."}";
        sResult = table.concat(tParts, "\n");
    else
        sResult = primitiveLiteral(vValue);
    end

    return sResult;
end

-- A strongly connected component may contain tables/closures, but object hooks
-- cannot allocate shells before validation. Reject mixed cycles before emitting
-- a save, including back-edges hidden behind an already-seen plain table.
local function validateGraph(tGraph)
    type.assert.table(tGraph);
    assert(tGraph.version == 1 and rawtype(tGraph.nodes) == "table" and rawtype(tGraph.root) == "table", "Unsupported or malformed serialized graph.");
    local nCount = 0;

    for k, tNode in pairs(tGraph.nodes) do
        assert(rawtype(k) == "number" and k >= 1 and k % 1 == 0 and rawtype(tNode) == "table", "Malformed graph node list.");
        nCount = nCount + 1;
    end

    local tEdges = {};

    local function listLength(tList)
        assert(rawtype(tList) == "table", "Expected a dense graph list.");
        local nLength = 0;

        for k in pairs(tList) do
            assert(rawtype(k) == "number" and k >= 1 and k % 1 == 0, "Malformed graph list index.");
            nLength = nLength + 1;
        end

        for nIndex = 1, nLength do assert(rawget(tList, nIndex) ~= nil, "Graph list must be dense."); end
        return nLength;
    end

    local function addValue(tValue, tList)
        assert(rawtype(tValue) == "table", "Malformed graph value.");
        local nVariants = 0;
        for k in pairs(tValue) do
            assert(k == "node" or k == "value" or k == "reference" or k == "global", "Unknown graph value field.");
            nVariants = nVariants + 1;
        end
        assert(nVariants <= 1, "Graph value has conflicting representations.");

        if (tValue.node ~= nil) then
            local nID = tValue.node;
            assert(rawtype(nID) == "number" and nID >= 1 and nID % 1 == 0 and nID <= nCount, "Invalid graph node reference.");
            tList[#tList + 1] = nID;
        elseif (tValue.reference ~= nil) then
            assert(rawtype(tValue.reference) == "string", "Malformed graph reference name.");
        elseif (tValue.global ~= nil) then
            assert(tValue.global == true, "Malformed global environment reference.");
        else
            local sType = rawtype(tValue.value);
            assert(sType == "nil" or sType == "string" or sType == "boolean" or sType == "number", "Graph primitive value must be a native primitive.");
        end
    end

    addValue(tGraph.root, {});

    for nID = 1, nCount do
        local tNode = tGraph.nodes[nID];
        assert(tNode, "Graph node list must be dense.");
        local tList = {};
        tEdges[nID] = tList;

        if (tNode.kind == "table") then
            assert(rawtype(tNode.entries) == "table", "Malformed table node.");
            listLength(tNode.entries);
            for _, tEntry in ipairs(tNode.entries) do addValue(tEntry.key, tList); addValue(tEntry.value, tList); end
        elseif (tNode.kind == "function") then
            assert(rawtype(tNode.bytecode) == "string" and rawtype(tNode.upvalues) == "table", "Malformed function node.");
            listLength(tNode.upvalues);
            for nIndex, tUpvalue in ipairs(tNode.upvalues) do
                assert(tUpvalue.index == nIndex and rawtype(tUpvalue.cell) == "number" and tUpvalue.cell >= 1 and tUpvalue.cell % 1 == 0, "Malformed captured upvalue.");
                addValue(tUpvalue.value, tList);
            end
        elseif (tNode.kind == "object" or tNode.kind == "expression") then
            if (tNode.state) then addValue(tNode.state, tList); end
            if (tNode.expression) then assert(rawtype(tNode.expression) == "string", "Malformed object state expression."); end
            listLength(tNode.dependencies or {});
            for _, tDependency in ipairs(tNode.dependencies or {}) do addValue(tDependency, tList); end
        else
            assert(tNode.kind == "reference", "Unknown serialized node kind.");
        end
    end

    local tIndices, tLow, tStack, tOnStack = {}, {}, {}, {};
    local nNext = 0;
    local visit;

    visit = function(nID)
        nNext = nNext + 1;
        tIndices[nID], tLow[nID] = nNext, nNext;
        tStack[#tStack + 1], tOnStack[nID] = nID, true;

        for _, nOther in ipairs(tEdges[nID]) do
            if (not tIndices[nOther]) then
                visit(nOther);
                tLow[nID] = math.min(tLow[nID], tLow[nOther]);
            elseif (tOnStack[nOther]) then
                tLow[nID] = math.min(tLow[nID], tIndices[nOther]);
            end
        end

        if (tLow[nID] == tIndices[nID]) then
            local nSize, bObject, bSelf = 0, false, false;
            local nMember;

            repeat
                nMember = table.remove(tStack);
                tOnStack[nMember] = nil;
                nSize = nSize + 1;
                local sKind = tGraph.nodes[nMember].kind;
                bObject = bObject or (sKind ~= "table" and sKind ~= "function");
                for _, nOther in ipairs(tEdges[nMember]) do bSelf = bSelf or nOther == nMember; end
            until nMember == nID;

            assert(not (bObject and (nSize > 1 or bSelf)), "Circular state through object hooks requires staged restoration and cannot be serialized.");
        end
    end;

    for nID = 1, nCount do if (not tIndices[nID]) then visit(nID); end end
end

--[[!
    @fqxn LuaEx.Libraries.serializer.deserialize
    @desc Evaluates one trusted serialized Lua expression in the current global
    environment. Accepts current graph saves and earlier LuaEx packed expressions.
    Malformed expressions and restoration errors raise errors. Also global deserialize.
    @param string sData Serialized Lua expression.
    @ret any The restored value.
    @ex local tValue = deserialize(serialize({value = false}));
!]]
local function deserialize(sData)
    type.assert.string(sData);
    local tEnvironment = _tReadEnvironments[coroutine.running()] or _G;
    local fChunk, sError = load("return "..sData, "LuaEx serialized data", "t", tEnvironment);
    assert(fChunk, "Malformed serialized data: "..tostring(sError));

    return fChunk();
end

--[[!
    @fqxn LuaEx.Libraries.serializer.loadFunction
    @desc Restores compatible Lua bytecode used by the graph format. Upvalues are
    assigned separately by restoreGraph. Not a portable function interchange format.
    @param string sEncoded Canonical Base64 bytecode.
    @ret function The restored Lua function.
    @ex local fValue = serializer.loadFunction(base64.enc(string.dump(function() return 3; end)));
!]]
local function loadFunction(sEncoded)
    type.assert.string(sEncoded);
    local sBytecode = base64.dec(sEncoded);
    assert(base64.enc(sBytecode) == sEncoded, "Malformed Base64 function data.");
    local fValue, sError = load(sBytecode, "LuaEx saved function", "b", _G);
    assert(fValue, "Invalid or incompatible Lua bytecode: "..tostring(sError));

    return fValue;
end

--[[!
    @fqxn LuaEx.Libraries.serializer.registerType
    @desc Registers a restoration factory for a named object type. Instances still
    supply __serialize. With direct=true the hook returns a complete Lua expression
    instead of state; otherwise factory.deserialize(state) restores each object.
    Identical repeated registration is harmless; conflicting registration rejects.
    @param string sType The identifier or dotted type name.
    @param table oFactory The restoration factory.
    @param boolean bDirect Optional; defaults to false.
    @ex serializer.registerType("RegisteredExample", {deserialize = function(tState) return tState; end});
!]]
local function registerType(sType, oFactory, bDirect)
    type.assert.string(sType);
    assert(sType:match("^[%a_][%w_%.]*$") and not sType:find("%.%.") and sType:sub(-1) ~= ".", "Invalid registered type name.");
    assert(rawtype(oFactory) == "table", "Restoration factory must be a table or object.");
    assert(bDirect == nil or rawtype(bDirect) == "boolean", "Direct option must be a boolean.");
    local bBound, oBound = pcall(lookup, sType);
    assert(not bBound or rawequal(oBound, oFactory), "Registered type conflicts with an existing global binding: "..sType);

    if (not bDirect) then
        local bOK, fRestore = pcall(function() return oFactory.deserialize; end);
        assert(bOK and rawtype(fRestore) == "function", "Restoration factory requires deserialize.");
    end

    local tExisting = _tRegistrations[sType];
    assert(not tExisting or (rawequal(tExisting.factory, oFactory) and (tExisting.direct == true) == (bDirect == true) and tExisting.restore == nil), "Type is already registered differently: "..sType);
    _tRegistrations[sType] = {factory = oFactory, direct = bDirect == true};
end

--[[!
    @fqxn LuaEx.Libraries.serializer.registerFactory
    @desc Registers a callable factory's own declaration. name is its stable saved
    reference; optional types lists the object-state types it restores. An optional
    restore(state, context) function overrides factory.deserialize for those types.
    context is an opaque per-restoration ownership token. Factories call
    this in their defining modules; the serializer contains no built-in factory list.
    The factory module must be loaded in the restoring process. Identical repeated
    declarations are harmless; conflicting names, types, or callbacks reject.
    @param table oFactory The callable factory declaring its persistence contract.
    @param table tDeclaration The declaration {name, types, restore}.
    @ex local Factory = setmetatable({deserialize = function(tState) return tState; end}, {__call = function() return {}; end}); serializer.registerFactory(Factory, {name = "FactoryDoxReference", types = {"FactoryDoxState"}});
!]]
registerFactory = function(oFactory, tDeclaration)
    assert(rawtype(oFactory) == "table" and rawtype(tDeclaration) == "table", "Expected a factory and declaration table.");
    local tMeta = debug.getmetatable(oFactory);
    assert(tMeta and rawtype(tMeta.__call) == "function", "Registered factory must be callable.");
    local sName = tDeclaration.name;
    assert(rawtype(sName) == "string" and sName:match("^[%a_][%w_%.]*$") and not sName:find("%.%.") and sName:sub(-1) ~= ".", "Invalid factory reference name.");
    local tTypes = tDeclaration.types or {};
    assert(rawtype(tTypes) == "table", "Factory types must be a list.");
    local fRestore = tDeclaration.restore;
    assert(fRestore == nil or rawtype(fRestore) == "function", "Factory restore callback must be a function.");
    if (not fRestore and next(tTypes)) then
        local bOK, fMethod = pcall(function() return oFactory.deserialize; end);
        assert(bOK and rawtype(fMethod) == "function", "Registered object factory needs deserialize or a restore callback.");
    end

    local bBound, oBound = pcall(lookup, sName);
    assert(not bBound or rawequal(oBound, oFactory), "Factory name is already bound differently: "..sName);
    assert(not _tFactoryReferences[oFactory] or _tFactoryReferences[oFactory] == sName, "Factory already declares a different name.");

    local nCount, tSeen = 0, {};

    for k, sType in pairs(tTypes) do
        assert(rawtype(k) == "number" and k >= 1 and k % 1 == 0, "Factory types must be a dense list.");
        assert(rawtype(sType) == "string" and sType:match("^[%a_][%w_%.]*$") and not sType:find("%.%.") and sType:sub(-1) ~= ".", "Invalid factory object type.");
        assert(not tSeen[sType], "Duplicate factory object type.");
        tSeen[sType], nCount = true, nCount + 1;
        local tExisting = _tRegistrations[sType];
        assert(not tExisting or (rawequal(tExisting.factory, oFactory) and tExisting.restore == fRestore and not tExisting.direct), "Object type already has a different restoration contract: "..sType);
        local bAliasBound, oAliasBound = pcall(lookup, sType);
        assert(not bAliasBound or rawequal(oAliasBound, oFactory), "Factory object type conflicts with an existing binding: "..sType);
    end

    for nIndex = 1, nCount do assert(tTypes[nIndex] ~= nil, "Factory types must be a dense list."); end

    -- Commit only after every alias validates, so failed declarations do not
    -- partially replace another factory's restoration behavior.
    _tNamedFactories[sName], _tFactoryReferences[oFactory] = oFactory, sName;
    for _, sType in ipairs(tTypes) do _tRegistrations[sType] = {factory = oFactory, restore = fRestore}; end
end;

--[[!
    @fqxn LuaEx.Libraries.serializer.restoreGraph
    @desc Restores version-one graph data emitted by serialize. Allocates plain
    tables and functions first, then restores dependencies before object factories
    validate their state. Plain table metatables are not persisted. Shared upvalue
    cells are rejoined after their values are restored; _ENV binds to current _G.
    @param table tGraph The encoded graph description.
    @ret any The graph's root value.
    @ex local bValue = serializer.restoreGraph({version = 1, root = {value = false}, nodes = {}});
!]]
local function restoreGraph(tGraph)
    validateGraph(tGraph);
    local tValues, tStatus, tCells = {}, {}, {};
    local tOwnership = {};
    local resolve;
    local restoreNode;
    local tEnvironment = setmetatable({__lx = tValues}, {__index = _G});

    for nID, tNode in ipairs(tGraph.nodes) do
        if (tNode.kind == "table") then tValues[nID] = {};
        elseif (tNode.kind == "function") then
            tValues[nID] = loadFunction(tNode.bytecode);
            assert(debug.getinfo(tValues[nID], "u").nups == #tNode.upvalues, "Saved upvalues do not match bytecode.");
        end
    end

    local function evaluate(sExpression)
        local fChunk, sError = load("return "..sExpression, "LuaEx object state", "t", tEnvironment);
        assert(fChunk, "Malformed object state: "..tostring(sError));
        -- Legacy hooks can pack nested serialize results. Their unpackData call
        -- must see this graph's references without exposing them as global variables.
        local oThread = coroutine.running();
        local tPrevious = _tReadEnvironments[oThread];
        _tReadEnvironments[oThread] = tEnvironment;
        local bOK, vValue = pcall(fChunk);
        _tReadEnvironments[oThread] = tPrevious;
        if (not bOK) then error(vValue, 0); end

        return vValue;
    end

    restoreNode = function(nID)
        assert(rawtype(nID) == "number" and nID >= 1 and nID % 1 == 0 and tGraph.nodes[nID], "Invalid graph node reference.");
        local tNode = tGraph.nodes[nID];

        if (tStatus[nID] ~= "done") then
            if (tStatus[nID] == "active") then
                assert(tNode.kind == "table" or tNode.kind == "function", "Circular object restoration requires staged object allocation.");
            else
                tStatus[nID] = "active";

                if (tNode.kind == "table") then
                    for _, tEntry in ipairs(tNode.entries) do
                        local vKey = resolve(tEntry.key);
                        local vValue = resolve(tEntry.value);
                        assert(vKey ~= nil and not (rawtype(vKey) == "number" and vKey ~= vKey), "Invalid restored table key.");
                        rawset(tValues[nID], vKey, vValue);
                    end
                elseif (tNode.kind == "function") then
                    for _, tUpvalue in ipairs(tNode.upvalues) do
                        assert(debug.setupvalue(tValues[nID], tUpvalue.index, resolve(tUpvalue.value)), "Saved upvalue index does not match the bytecode.");
                        local tCell = tCells[tUpvalue.cell];

                        if (tCell) then
                            debug.upvaluejoin(tValues[nID], tUpvalue.index, tCell.func, tCell.index);
                        else
                            tCells[tUpvalue.cell] = {func = tValues[nID], index = tUpvalue.index};
                        end
                    end
                elseif (tNode.kind == "reference") then
                    tValues[nID] = lookup(tNode.path);
                elseif (tNode.kind == "object" or tNode.kind == "expression") then
                    for _, tDependency in ipairs(tNode.dependencies or {}) do resolve(tDependency); end
                    local vState;
                    if (tNode.state) then vState = resolve(tNode.state); end
                    if (tNode.expression) then vState = evaluate(tNode.expression); end

                    if (tNode.kind == "object") then
                        local fRestore, bContext = deserializerFor(tNode.type);
                        if (bContext) then vState = fRestore(vState, tOwnership);
                        else vState = fRestore(vState); end
                    end
                    tValues[nID] = vState;
                else
                    error("Unknown serialized node kind: "..tostring(tNode.kind));
                end

                tStatus[nID] = "done";
            end
        end

        return tValues[nID];
    end;

    resolve = function(tValue)
        assert(rawtype(tValue) == "table", "Malformed graph value.");
        local vValue;

        if (tValue.node) then vValue = restoreNode(tValue.node);
        elseif (tValue.reference) then vValue = lookup(tValue.reference);
        elseif (tValue.global) then vValue = _G;
        else vValue = tValue.value; end

        return vValue;
    end;

    local vResult = resolve(tGraph.root);

    -- A hook may emit a literal expression while its dependencies contain extra
    -- closures. Finish every emitted node so all captured cells are initialized.
    for nID in ipairs(tGraph.nodes) do restoreNode(nID); end

    return vResult;
end

--[[!
    @fqxn LuaEx.Libraries.serializer.serialize
    @desc Saves a value, including arbitrary binary strings, precise native numbers,
    graph tables, Lua closures, enums, and objects with __serialize/deserialize.
    Class persistence remains autogenerated. Nested hook calls join the current
    graph, preserving repeated object references across hook state boundaries.
    Cycles through object state fail explicitly rather than producing broken saves.
    Hook strings are Lua state expressions; hook tables are state values. An
    ordinary table's custom hook restores its supplied state without a factory.
    Optional metatable __serialtype selects a registered state type independently
    of __type. Optional __serialref returns a symbolic path; an identity-matching
    binding is saved by reference, otherwise the object's state hook is used.
    Also available globally as serialize.
    @param any vValue The value to save.
    @ret string A trusted Lua expression that restores the value.
    @ex local tSource = {}; tSource.self = tSource; local sSave = serialize(tSource);
!]]
serialize = function(vValue)
    local oThread = coroutine.running();
    local tSession = _tSessions[oThread];
    local bRoot = tSession == nil;

    if (bRoot) then
        tSession = {nodes = {}, sources = {}, seen = {}, active = {}, cells = {}, cellCount = 0};
        _tSessions[oThread] = tSession;
    end

    local nCheckpoint = #tSession.nodes;
    local nCellCheckpoint = tSession.cellCount;
    local tPreviousHook = tSession.hook;
    local bOK, tRoot = pcall(encodeValue, vValue, tSession);
    local sResult;

    if (bRoot) then _tSessions[oThread] = nil; end
    if (not bOK) then
        -- A hook can catch a failed nested save. Remove its unfinished graph nodes
        -- and restore the outer hook rather than poisoning the remaining traversal.
        for nID = #tSession.nodes, nCheckpoint + 1, -1 do
            local vSource = tSession.sources[nID];
            tSession.seen[vSource], tSession.active[vSource] = nil, nil;
            tSession.nodes[nID], tSession.sources[nID] = nil, nil;
        end

        for oCell, nID in pairs(tSession.cells) do
            if (nID > nCellCheckpoint) then tSession.cells[oCell] = nil; end
        end

        tSession.cellCount = nCellCheckpoint;
        tSession.hook = tPreviousHook;
        error(tRoot, 0);
    end

    if (not bRoot) then
        if (tSession.hook) then
            tSession.hook.dependencies[#tSession.hook.dependencies + 1] = tRoot;
        end
        sResult = descriptorExpression(tRoot);
    elseif (#tSession.nodes == 0) then
        sResult = tRoot.reference or primitiveLiteral(tRoot.value);
    else
        local tGraph = {version = 1, root = tRoot, nodes = tSession.nodes};
        validateGraph(tGraph);
        sResult = "serializer.restoreGraph("..formatData(tGraph, 0)..")";
    end

    return sResult;
end;

--[[!
    @fqxn LuaEx.Libraries.serializer.unpackData
    @desc Decodes and evaluates canonical Base64 state from older packed saves.
    Retained for compatibility with Type.deserialize(serializer.unpackData(...)).
    @param string sEncoded The Base64 serialized expression.
    @ret any The restored state value.
    @ex local vValue = serializer.unpackData(base64.enc("false"));
!]]
local function unpackData(sEncoded)
    type.assert.string(sEncoded);
    local sData = base64.dec(sEncoded);
    assert(base64.enc(sData) == sEncoded, "Malformed Base64 serialized state.");

    return deserialize(sData);
end

local SerializerActual = {
    deserialize = deserialize,
    loadFunction = loadFunction,
    registerFactory = registerFactory,
    registerType = registerType,
    restoreGraph = restoreGraph,
    serialize = serialize,
    unpackData = unpackData,
};
local SerializerDecoy = {};
local SerializerMeta = {
    __index = SerializerActual,
    __newindex = function() error("Attempt to modify the read-only serializer.", 2); end,
    __metatable = false,
};
setmetatable(SerializerDecoy, SerializerMeta);
return SerializerDecoy;
