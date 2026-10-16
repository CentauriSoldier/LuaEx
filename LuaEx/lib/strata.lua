--LOCALIZATION
local assert       = assert;
local error        = error;
local ipairs       = ipairs;
local next         = next;
local rawget       = rawget;
local rawtype      = rawtype;
local require      = require;
local setmetatable = setmetatable;
local string       = string;
local table        = table;

local lower = string.lower;
local match = string.match;
local sort  = table.sort;

local _tSerializer = require("LuaEx.lib.serializer");
local _tRoots      = {};
local _tNodes      = setmetatable({}, {__mode = "k"});
local _xStrata     = {};

--[[!
    @fqxn LuaEx.Libraries.strata
    @desc Immutable hierarchies of named identifiers. Declared spelling is
    preserved; root registration and child lookup are case-insensitive using
    Lua's string.lower. Unknown children return nil. Top-level names are cached
    locally for this module's lifetime and cannot be recreated, even identically.
    tostring gives the full path; unary minus gives the local name. Calling a
    node returns its parent, or nil for a root. Length counts immediate children.
    pairs yields declared names and child nodes in sorted name order. Cloning
    retains identity. Deserialization resolves an already-created matching tree.
    Ordinary writes and public metatable changes are rejected; explicit rawset
    and debug bypasses are outside this table-proxy contract.
    @ex
    local mVehicle = strata("vehicle", {land = {car = {}}});
    assert(mVehicle.land.car == mVehicle.LAND.CAR);
    assert(tostring(mVehicle.LAND.CAR) == "vehicle.land.car");
!]]

--[[!
    @fqxn LuaEx.Libraries.strata.Helpers.modifyError
    @scope local
    @desc Rejects changes to nodes, the factory and public metadata views.
!]]
local function modifyError()
    error("Strata are read-only and cannot be modified once created.", 2);
end

--[[!
    @fqxn LuaEx.Libraries.strata.Helpers.validateName
    @scope local
    @desc Requires a nonblank string without changing its declared spelling.
    @param string sName The root or child name to validate.
!]]
local function validateName(sName)
    assert(rawtype(sName) == "string" and match(sName, "%S"),
           "Strata names must be nonblank strings.");
end

--[[!
    @fqxn LuaEx.Libraries.strata.Helpers.copyDefinition
    @scope local
    @desc Validates and copies a definition before registering its root. Rejects
    invalid branches, names, case-only sibling duplicates and cycles. Shared input
    branches are copied independently. Reads raw entries, ignoring input metamethods.
    @param table tInput The branch definition; {} denotes a leaf.
    @param table tActive Tables on the current recursion path.
    @ret table tDefinition The independent, validated definition.
!]]
local function copyDefinition(tInput, tActive)
    assert(rawtype(tInput) == "table", "Every Strata branch must be a table; use {} for a leaf.");
    assert(not tActive[tInput], "Strata definitions cannot contain cycles.");

    local tDefinition = {};
    local tSeen       = {};

    tActive[tInput] = true;

    for sName, tBranch in next, tInput do
        validateName(sName);

        local sKey = lower(sName);

        assert(not tSeen[sKey], "Duplicate case-insensitive Strata child name: "..sName);

        tSeen[sKey]        = true;
        tDefinition[sName] = copyDefinition(tBranch, tActive);
    end

    tActive[tInput] = nil;

    return tDefinition;
end

--[[!
    @fqxn LuaEx.Libraries.strata.Helpers.sameDefinition
    @scope local
    @desc Compares validated definitions, including their declared spelling.
    @param table tLeft The first definition.
    @param table tRight The second definition.
    @ret boolean bSame Whether both complete definitions match.
!]]
local function sameDefinition(tLeft, tRight)
    for sName, tBranch in next, tLeft do
        local tOther = tRight[sName];

        if (not tOther or not sameDefinition(tBranch, tOther)) then
            return false;
        end
    end

    for sName in next, tRight do

        if (not tLeft[sName]) then
            return false;
        end

    end

    return true;
end

--[[!
    @fqxn LuaEx.Libraries.strata.Helpers.publicMeta
    @scope local
    @desc Exposes read-only type identity without exposing implementation closures
    or child storage. The native metatable lock prevents public replacement.
    @param table tMeta The implementation metatable.
    @ret table tView The public metadata proxy.
!]]
local function publicMeta(tMeta)
    local tIdentity = {
        __type    = tMeta.__type,
        __subtype = tMeta.__subtype,
    };

    return setmetatable({}, {
        __index     = tIdentity,
        __newindex  = modifyError,
        __metatable = false,
    });
end

--[[!
    @fqxn LuaEx.Libraries.strata.Helpers.savedState
    @scope local
    @desc Saves a root definition and declared child path. Separate path segments
    remain unambiguous even when a name contains a dot. Copies the definition
    so even direct hook results cannot expose mutable private storage.
    @param table mNode A node owned by this factory.
    @ret table tState The identity reference and matching definition.
!]]
local function savedState(mNode)
    local tNode = _tNodes[mNode];
    local tPath = {};

    while (tNode.parent) do
        tPath[#tPath + 1] = tNode.name;
        tNode = _tNodes[tNode.parent];
    end

    -- The upward traversal is reversed for descent during restoration.
    local tOrdered = {};

    for nIndex = #tPath, 1, -1 do
        tOrdered[#tOrdered + 1] = tPath[nIndex];
    end

    return {
        root       = tNode.name,
        definition = copyDefinition(tNode.definition, {}),
        path       = tOrdered,
    };
end

--[[!
    @fqxn LuaEx.Libraries.strata.Helpers.buildNode
    @scope local
    @desc Builds a node with private child storage. Public nodes remain empty,
    so replacement, deletion and insertion all reach the write rejection.
    @param string sName The declared local name.
    @param table tDefinition The validated branch definition.
    @param table|nil mParent The parent node, or nil for a root.
    @ret table mNode The immutable node.
!]]
local function buildNode(sName, tDefinition, mParent)
    local mNode     = {};
    local tChildren = {};
    local tNames    = {};
    local sPath     = mParent and _tNodes[mParent].path.."."..sName or sName;

    _tNodes[mNode] = {
        name       = sName,
        path       = sPath,
        parent     = mParent,
        children   = tChildren,
        definition = tDefinition,
    };

    for sChild in next, tDefinition do
        tNames[#tNames + 1] = sChild;
    end

    sort(tNames);

    for _, sChild in ipairs(tNames) do
        tChildren[lower(sChild)] = buildNode(sChild, tDefinition[sChild], mNode);
    end

    local tMeta = {
        __call = function()
            return mParent;
        end,
        __index = function(_, vKey)

            if (rawtype(vKey) == "string") then
                return tChildren[lower(vKey)];
            end

        end,
        __len = function()
            return #tNames;
        end,
        __unm = function()
            return sName;
        end,
        __tostring = function()
            return sPath;
        end,
        __pairs = function()
            local nIndex = 0;

            --[[!
                @fqxn LuaEx.Libraries.strata.Helpers.buildNode.iterator
                @scope local
                @desc Advances this traversal without exposing private child storage.
                @ret string|nil sChild The next declared name, or nil at the end.
                @ret strata|nil mChild The corresponding child node.
            !]]
            local function fIterator()
                nIndex = nIndex + 1;

                local sChild = tNames[nIndex];

                if (sChild) then
                    return sChild, tChildren[lower(sChild)];
                end
            end

            return fIterator, nil, nil;
        end,
        __clone = function()
            return mNode;
        end,
        __serialize = function()
            return savedState(mNode);
        end,
        __newindex   = modifyError,
        __type       = mParent and _tNodes[mParent].path or "strata",
        __subtype    = mParent and "strata" or nil,
        __serialtype = "strata",
    };

    tMeta.__metatable = publicMeta(tMeta);
    setmetatable(mNode, tMeta);

    return mNode;
end

--[[!
    @fqxn LuaEx.Libraries.strata.__call
    @pulsarlua function strata
    @desc Creates a hierarchy once per case-insensitive top-level name. Validation
    and construction finish before registration; failures do not reserve the name.
    Input tables are copied, so later input edits cannot change the hierarchy.
    @param string sName The declared top-level name.
    @param table tInput Child names mapped to branch tables; {} denotes a leaf.
    @ret strata mRoot The root node.
    @throws Invalid input, cycles, sibling name collisions or a cached root name.
!]]
local function buildStrata(_, sName, tInput)
    validateName(sName);

    local sKey = lower(sName);

    assert(not _tRoots[sKey], "Strata top-level name is already registered: "..sName);

    local tDefinition = copyDefinition(tInput, {});
    local mRoot       = buildNode(sName, tDefinition, nil);

    _tRoots[sKey] = mRoot;

    return mRoot;
end

--[[!
    @fqxn LuaEx.Libraries.strata.Helpers.deserialize
    @scope local
    @desc Resolves saved identity against a cached hierarchy with the same complete
    definition and spelling. The hierarchy must already exist in this Lua session.
    Missing or changed hierarchies, malformed state and unknown paths raise errors.
    No hierarchy is created; the existing root or descendant is returned unchanged.
    @param table tState The saved {root, definition, path} state.
    @ret strata mNode The existing root or descendant.
!]]
local function deserialize(tState)
    assert(rawtype(tState) == "table", "Saved Strata state must be a table.");

    for sField in next, tState do
        assert(sField == "root" or sField == "definition" or sField == "path", "Unknown saved Strata field.");
    end

    -- Read actual state fields; input metamethods cannot supply missing entries.
    local sRootName        = rawget(tState, "root");
    local tSavedDefinition = rawget(tState, "definition");
    local tPath            = rawget(tState, "path");

    validateName(sRootName);
    assert(rawtype(tPath) == "table", "Saved Strata path must be a dense list.");

    local mNode = _tRoots[lower(sRootName)];

    assert(mNode, "Saved Strata hierarchy is not registered: "..sRootName);

    local tRoot       = _tNodes[mNode];
    local tDefinition = copyDefinition(tSavedDefinition, {});

    assert(tRoot.name == sRootName and sameDefinition(tRoot.definition, tDefinition),
           "Saved Strata hierarchy differs from the registered definition.");

    local nCount = 0;

    for nIndex, sName in next, tPath do
        assert(rawtype(nIndex) == "number" and nIndex >= 1 and nIndex % 1 == 0,
               "Saved Strata path must be a dense list.");
        validateName(sName);

        nCount = nCount + 1;
    end

    for nIndex = 1, nCount do
        local sName = rawget(tPath, nIndex);

        assert(sName ~= nil, "Saved Strata path must be a dense list.");

        local mChild = _tNodes[mNode].children[lower(sName)];

        assert(mChild and _tNodes[mChild].name == sName, "Saved Strata child does not exist with the declared spelling.");

        mNode = mChild;
    end

    return mNode;
end

local _tFactoryMeta = {
    __call = buildStrata,
    __clone = function()
        return _xStrata;
    end,
    __type     = "stratafactory",
    __newindex = modifyError,
};

_tFactoryMeta.__metatable = publicMeta(_tFactoryMeta);
setmetatable(_xStrata, _tFactoryMeta);

-- Register the codec here; the serializer needs no Strata-specific changes.
_tSerializer.registerFactory(_xStrata, {
    name    = "strata",
    types   = {"strata"},
    restore = deserialize,
});

return _xStrata;
