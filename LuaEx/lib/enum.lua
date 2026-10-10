--[[!
    @fqxn LuaEx.Libraries.enum
    @pulsarlua table enum
    @desc Immutable named collections with one-based ordinal lookup, ordered
    iteration, optional values, and nested enums. Missing values use their ordinal.
    Public enums register in LuaEx; private enums do not register globally.
    Entries compare by identity; compare their value fields to compare payloads.
    Payload objects remain references and are not recursively made immutable.
    clone retains immutable collection/member/factory identity. Public metadata
    views and ordinary writes are protected. Nested collections own their wrappers.
!]]
local _tLuaEx    = rawget(_G, "luaex");
local _tEnums    = setmetatable({}, {__mode = "k"});
local _tItems    = setmetatable({}, {__mode = "k"});
local _tBuilders = setmetatable({}, {__mode = "k"});
local _tReserved = {
    __count = true, __hasa = true, __name = true, deserialize = true, id = true, isa = true,
    isSibling = true, name = true, next = true, parent = true, previous = true,
    random = true, serialize = true, totable = true, value = true, valueType = true,
};

constant("ENUM_DEFAULT_VALUE", "|___ENUM_DEFAULT_VALUE___|");

local buildEnum;
local snapshot;

local function modifyError()
    error("Enums are read-only and cannot be modified once created.", 2);
end

local function publicMeta(tMeta)
    -- Enum loads before tablehook. Keep this small metadata view self-contained.
    local tFields = {
        __type = tMeta.__type,
        __subtype = tMeta.__subtype,
        __call = tMeta.__call,
        __clone = tMeta.__clone,
        __serialize = tMeta.__serialize,
        __serialtype = tMeta.__serialtype,
        __serialref = tMeta.__serialref,
    };
    return setmetatable({}, {__index = tFields, __newindex = modifyError, __metatable = false});
end

local function identifierIsValid(sName, bSkipKeywords)
    local bValid = rawtype(sName) == "string" and sName:match("^[%a_][%w_]*$") ~= nil;

    -- Use LuaEx's authoritative keyword list, which exists before stringhook.
    if (bValid and not bSkipKeywords) then
        for nIndex = 1, _tLuaEx.__keywords__count__ do
            if (sName == _tLuaEx.__keywords__[nIndex]) then bValid = false; break; end
        end
    end

    return bValid;
end

local function validateName(sName, bPrivate)
    type.assert.string(sName);
    assert(sName:match("%S"), "Enum name must be nonblank.");

    if (not bPrivate) then
        assert(identifierIsValid(sName), "Public enum name must be a valid non-keyword identifier.");
        assert(_G[sName] == nil, "Enum cannot overwrite an existing global or LuaEx name.");
    end
end

local function validateInputs(sName, tNames, tValues, bPrivate)
    validateName(sName, bPrivate);
    type.assert.table(tNames);
    type.assert.table(tValues);

    local nCount = 0;
    local tSeen = {};

    for k, sItem in pairs(tNames) do
        assert(rawtype(k) == "number" and k >= 1 and k % 1 == 0, "Enum names must form a dense one-based list.");
        type.assert.string(sItem);
        assert(identifierIsValid(sItem, true), "Enum member name must be a valid identifier.");
        assert(not _tReserved[sItem] and not tSeen[sItem], "Enum member name is reserved or duplicated: "..sItem);
        tSeen[sItem] = true;
        nCount = nCount + 1;
    end

    assert(nCount > 0, "An enum must contain at least one member.");

    for nIndex = 1, nCount do
        assert(tNames[nIndex] ~= nil, "Enum names must form a dense one-based list.");
    end

    -- Values may omit entries to request ordinal defaults, but cannot add members.
    for k in pairs(tValues) do
        assert(rawtype(k) == "number" and k % 1 == 0 and k >= 1 and k <= nCount, "Enum value index is outside the names list.");
    end

    return nCount;
end

local function itemPath(tState)
    local sPath = tState.name;

    if (tState.parent) then
        sPath = itemPath(_tEnums[tState.parent]).."."..tState.itemName;
    end

    return sPath;
end

local function enumIterator(oEnum, nIndex)
    local tState = _tEnums[oEnum];
    local oItem = tState.items[nIndex + 1];

    if (oItem) then
        return nIndex + 1, oItem;
    end
end

local function itemMethods(oItem, tState, tActual)
    --[[!
        @fqxn LuaEx.Libraries.enum.item.Fields
        @desc id is the one-based ordinal; name is the parent's member key;
        parent is the exact owning enum; value is the supplied/default payload;
        valueType is its LuaEx type (the member key for an embedded collection).
        Embedded collections expose these member fields and their own enum API.
    !]]
    tActual.id        = tState.id;
    tActual.name      = tState.itemName;
    tActual.parent    = tState.parent;
    tActual.value     = tState.value;
    tActual.valueType = _tEnums[oItem] and tState.itemName or type(tState.value);

    --[[!
        @fqxn LuaEx.Libraries.enum.item.isa
        @pulsarlua function enumitem.isa
        @desc Tests exact membership in the given parent enum.
        @param enum oEnum The proposed parent.
        @ret boolean Whether this item's parent is oEnum.
        @ex local bMember = TIER.I.isa(TIER);
    !]]
    tActual.isa = function(oEnum)
        return rawequal(tState.parent, oEnum);
    end;

    --[[!
        @fqxn LuaEx.Libraries.enum.item.isSibling
        @pulsarlua function enumitem.isSibling
        @desc Tests that another entry is distinct and has the same parent enum.
        @param enumitem other The proposed sibling.
        @ret boolean Whether the entries are distinct siblings.
        @ex local bSibling = TIER.I.isSibling(TIER.II);
    !]]
    tActual.isSibling = function(other)
        local tOther = _tItems[other];
        return tOther ~= nil and not rawequal(oItem, other) and rawequal(tOther.parent, tState.parent);
    end;

    local function neighbor(nOffset, bWrap)
        assert(bWrap == nil or rawtype(bWrap) == "boolean", "Wrap option must be a boolean.");
        local tParent = _tEnums[tState.parent];
        local nIndex = tState.id + nOffset;

        if (bWrap) then
            nIndex = (nIndex - 1) % #tParent.items + 1;
        end

        return tParent.items[nIndex];
    end

    --[[!
        @fqxn LuaEx.Libraries.enum.item.next
        @pulsarlua function enumitem.next
        @desc Gets the next sibling; nil past the end unless wrapping is requested.
        @param boolean bWrap Optional; defaults to false.
        @ret enumitem|nil The next sibling.
        @ex local oNext = TIER.I.next();
    !]]
    tActual.next = function(bWrap) return neighbor(1, bWrap); end;

    --[[!
        @fqxn LuaEx.Libraries.enum.item.previous
        @pulsarlua function enumitem.previous
        @desc Gets the previous sibling; nil before the start unless wrapping is requested.
        @param boolean bWrap Optional; defaults to false.
        @ret enumitem|nil The previous sibling.
        @ex local oPrevious = TIER.I.previous(true);
    !]]
    tActual.previous = function(bWrap) return neighbor(-1, bWrap); end;

    --[[!
        @fqxn LuaEx.Libraries.enum.item.serialize
        @pulsarlua function enumitem.serialize
        @desc Returns the complete symbolic path, including nested parent keys.
        This is a reference only when the root is globally accessible. Use global
        serialize to persist private enum items as well.
        @ret string The symbolic path.
        @ex local sPath = TIER.I.serialize();
    !]]
    tActual.serialize = function()
        return itemPath(_tEnums[tState.parent]).."."..tState.itemName;
    end;
end

local function itemMeta(oItem, tState, tActual)
    local ItemMeta = {
        __index = function(_, k)
            local vValue = tActual[k];
            assert(vValue ~= nil, "Enum item has no property '"..tostring(k).."'.");
            return vValue;
        end,
        __newindex = modifyError,
        __clone = function() return oItem; end,
        __serialize = function() return {parent = tState.parent, name = tState.itemName}; end,
        __serialtype = "enumitem",
        __serialref = function() return tActual.serialize(); end,
        __tostring = function() return tState.itemName; end,
        __type = _tEnums[tState.parent].name,
        __subtype = "enumitem",
    };

    --[[!
        @fqxn LuaEx.Libraries.enum.item.Operators
        @desc Addition, subtraction, multiplication, division, modulo, and power
        operate on numeric payloads and accept numeric scalar operands too.
        Ordering compares payloads of siblings from the same parent. Equality
        uses member identity, including members with equal payloads.
    !]]
    local function numberValue(vOperand)
        local tItem = _tItems[vOperand];
        local vValue = vOperand;
        if (tItem) then vValue = tItem.value; end
        assert(rawtype(vValue) == "number", "Enum arithmetic requires numeric values.");
        return vValue;
    end

    local tOperations = {
        __add = function(a, b) return a + b; end,
        __div = function(a, b) return a / b; end,
        __mod = function(a, b) return a % b; end,
        __mul = function(a, b) return a * b; end,
        __pow = function(a, b) return a ^ b; end,
        __sub = function(a, b) return a - b; end,
    };

    for sName, fOperation in pairs(tOperations) do
        ItemMeta[sName] = function(left, right)
            return fOperation(numberValue(left), numberValue(right));
        end;
    end

    local function compare(left, right, bEqual)
        local tLeft, tRight = _tItems[left], _tItems[right];
        assert(tLeft and tRight and rawequal(tLeft.parent, tRight.parent), "Enum ordering requires siblings in the same enum.");
        local bResult;

        if (bEqual) then bResult = tLeft.value <= tRight.value;
        else bResult = tLeft.value < tRight.value; end

        return bResult;
    end

    ItemMeta.__le = function(a, b) return compare(a, b, true); end;
    ItemMeta.__lt = function(a, b) return compare(a, b, false); end;

    return ItemMeta;
end

buildEnum = function(sName, tNames, tValues, bPrivate, oParent, nID, sItemName, tOwner)
    local nCount = validateInputs(sName, tNames, tValues, bPrivate);
    local EnumDecoy = {};
    local tActual = {};
    local tState = {name = sName, items = {}, values = {}, parent = oParent, id = nID, itemName = sItemName, actual = tActual, private = bPrivate};
    _tEnums[EnumDecoy] = tState;

    for nIndex = 1, nCount do
        local sItem = tNames[nIndex];
        local vValue = tValues[nIndex];

        if (vValue == nil or vValue == ENUM_DEFAULT_VALUE) then vValue = nIndex; end

        local ItemDecoy, ItemMeta;
        local tItemActual = {};
        local tItemState = {id = nIndex, itemName = sItem, parent = EnumDecoy, value = vValue};

        if (_tEnums[vValue]) then
            if (tOwner) then
                -- The codec owns these freshly restored children. Adopting them
                -- preserves graph references to their members instead of copying twice.
                local tChild = _tEnums[vValue];
                assert(tChild.private and not tChild.parent and rawequal(tChild.owner, tOwner), "Restored nested enum must belong to this decoding operation.");
                ItemDecoy = vValue;
                tChild.parent, tChild.id, tChild.itemName = EnumDecoy, nIndex, sItem;
                tChild.owner = nil;
                tChild.value = ItemDecoy;
                _tItems[ItemDecoy] = tChild;
                itemMethods(ItemDecoy, tChild, tChild.actual);
                local tMeta = debug.getmetatable(ItemDecoy);
                tMeta.__type, tMeta.__subtype = sName, "enumitem";
                tMeta.__metatable = publicMeta(tMeta);
            else
                -- Embed an independent wrapper; do not mutate supplied live enums.
                local tChild = snapshot(vValue);
                ItemDecoy = buildEnum(tChild.name, tChild.names, tChild.values, true, EnumDecoy, nIndex, sItem);
            end

            tItemState = _tEnums[ItemDecoy];
        else
            ItemDecoy = {};
            _tItems[ItemDecoy] = tItemState;
            itemMethods(ItemDecoy, tItemState, tItemActual);
            ItemMeta = itemMeta(ItemDecoy, tItemState, tItemActual);
            ItemMeta.__metatable = publicMeta(ItemMeta);
            setmetatable(ItemDecoy, ItemMeta);
        end

        tState.items[nIndex] = ItemDecoy;
        tState.values[nIndex] = _tEnums[ItemDecoy] and ItemDecoy or vValue;
        tActual[nIndex], tActual[sItem] = ItemDecoy, ItemDecoy;
    end

    tActual.__count = nCount;
    tActual.__name = sName;
    tActual.__hasa = function(oItem)
        local tItem = _tItems[oItem];
        return tItem ~= nil and rawequal(tItem.parent, EnumDecoy);
    end;

    --[[!
        @fqxn LuaEx.Libraries.enum.deserializeMember
        @desc Compatibility entry on each collection for older packed member saves,
        such as TIER.deserialize(serializer.unpackData(...)). The unpacked value
        must already be a member of this exact collection; its identity is retained.
        New persistence uses the enum factory's registered restoration contract.
        @param enumitem oMember The already resolved member.
        @ret enumitem The same validated member.
        @ex local oMember = TIER.deserialize(TIER.I);
    !]]
    tActual.deserialize = function(oMember)
        local tMember = _tItems[oMember];
        assert(tMember and rawequal(tMember.parent, EnumDecoy), "Saved member belongs to a different enum.");
        return oMember;
    end;

    --[[!
        @fqxn LuaEx.Libraries.enum.random
        @pulsarlua function enum.random
        @desc Selects a uniformly random member using the shared math.random stream.
        @ret enumitem A member of this enum.
        @ex local oTier = TIER.random();
    !]]
    tActual.random = function() return tState.items[math.random(nCount)]; end;

    --[[!
        @fqxn LuaEx.Libraries.enum.totable
        @pulsarlua function enum.totable
        @desc Returns a new table keyed by member objects. Values are each member's
        payload unless an override is supplied; false is a valid override.
        @param any vOverride Optional value for every member key.
        @ret table The new mapping.
        @ex local tEnabled = TIER.totable(false);
    !]]
    tActual.totable = function(vOverride)
        local tResult = {};

        for nIndex, oItem in ipairs(tState.items) do
            local vValue = vOverride;
            if (vValue == nil) then vValue = tState.values[nIndex]; end
            tResult[oItem] = vValue;
        end

        return tResult;
    end;

    local EnumMeta = {
        __index = function(_, k)
            local vValue = tActual[k];
            if (rawtype(k) ~= "number") then assert(vValue ~= nil, "Enum has no property '"..tostring(k).."'."); end
            return vValue;
        end,
        __newindex = modifyError,
        __call = function() return enumIterator, EnumDecoy, 0; end,
        __pairs = function() return enumIterator, EnumDecoy, 0; end,
        __len = function() return nCount; end,
        __clone = function() return EnumDecoy; end,
        __serialize = function() return snapshot(EnumDecoy); end,
        __serialtype = "enum",
        __serialref = function() return itemPath(tState); end,
        __tostring = function() return sName; end,
        __type = "enum",
    };

    if (oParent) then
        _tItems[EnumDecoy] = tState;
        tState.value = EnumDecoy;
        itemMethods(EnumDecoy, tState, tActual);
        EnumMeta.__type = _tEnums[oParent].name;
        EnumMeta.__subtype = "enumitem";
    end

    EnumMeta.__metatable = publicMeta(EnumMeta);
    setmetatable(EnumDecoy, EnumMeta);

    if (not bPrivate) then _tLuaEx[sName] = EnumDecoy; end
    tState.owner = tOwner;

    return EnumDecoy;
end;

--[[!
    @fqxn LuaEx.Libraries.enum.snapshot
    @pulsarlua function enum.snapshot
    @desc Returns a fresh definition table for an enum, including private/nested
    enums. Payload objects are retained; member names and value lists are copied.
    @param enum oEnum The enum to describe.
    @ret table The definition {name, names, values}.
    @ex local tDefinition = enum.snapshot(TIER);
!]]
snapshot = function(oEnum)
    local tState = _tEnums[oEnum];
    assert(tState, "Expected an enum collection.");
    local tResult = {name = tState.name, names = {}, values = {}};

    for nIndex, oItem in ipairs(tState.items) do
        tResult.names[nIndex] = _tItems[oItem].itemName;
        tResult.values[nIndex] = _tEnums[oItem] and oItem or tState.values[nIndex];
    end

    return tResult;
end;

--[[!
    @fqxn LuaEx.Libraries.enum.deserialize
    @pulsarlua function enum.deserialize
    @desc Restores a definition table as a private enum without overwriting global
    bindings. A symbolic path string resolves an existing enum or member without
    executing Lua code; unknown paths and malformed definitions raise errors.
    @param table|string vData A snapshot or symbolic path.
    @ret enum|enumitem The restored or referenced value.
    @ex local oTier = enum.deserialize("TIER.I");
!]]
local function deserialize(vData)
    local oResult;

    if (rawtype(vData) == "string") then
        assert(vData:match("^[%a_][%w_%.]*$") and not vData:find("%.%.") and vData:sub(-1) ~= ".", "Invalid enum path.");
        local vValue = _G;

        for sPart in vData:gmatch("[^%.]+") do
            assert(rawtype(vValue) == "table", "Unknown enum path.");
            vValue = vValue[sPart];
        end

        assert(_tEnums[vValue] or _tItems[vValue], "Path does not identify an enum or enum member.");
        oResult = vValue;
    else
        type.assert.table(vData);
        oResult = buildEnum(vData.name, vData.names, vData.values, true);
    end

    return oResult;
end

--[[!
    @fqxn LuaEx.Libraries.enum.prep
    @pulsarlua function enum.prep
    @desc Builds a definition in assignment order. Assign named values, including
    false or ENUM_DEFAULT_VALUE, then call the builder to create the enum. Reassigning
    a name updates its value while retaining its position; nil assignments reject.
    Nested builders are resolved as private enums when their parent is built.
    @param string sName The enum's name.
    @param boolean bPrivate Optional; defaults to false.
    @ret table A callable mutable definition builder.
    @ex local Builder = enum.prep("PreparedExample", true); Builder.FIRST = ENUM_DEFAULT_VALUE; local oEnum = Builder();
!]]
local function prep(sName, bPrivate)
    assert(bPrivate == nil or rawtype(bPrivate) == "boolean", "Private option must be a boolean.");
    validateName(sName, bPrivate == true);
    local tNames, tValues, tPositions = {}, {}, {};
    local BuilderDecoy = {};
    local bBuilding = false;

    _tBuilders[BuilderDecoy] = function(bNested)
        assert(not bBuilding, "Circular enum definition builder.");
        bBuilding = true;
        local bOK, oEnum = pcall(function()
            local tResolved = {};

            for nIndex, vValue in ipairs(tValues) do
                tResolved[nIndex] = _tBuilders[vValue] and _tBuilders[vValue](true) or vValue;
            end

            return buildEnum(sName, tNames, tResolved, bNested or bPrivate == true);
        end);

        bBuilding = false;
        if (not bOK) then error(oEnum, 0); end

        return oEnum;
    end;

    setmetatable(BuilderDecoy, {
        __call = function() return _tBuilders[BuilderDecoy](false); end,
        __index = function(_, k)
            local nIndex = tPositions[k];
            return nIndex and tValues[nIndex];
        end,
        __newindex = function(_, k, v)
            assert(identifierIsValid(k, true) and not _tReserved[k], "Invalid or reserved enum member name.");
            assert(v ~= nil, "Enum builder values cannot be nil; use ENUM_DEFAULT_VALUE.");
            local nIndex = tPositions[k];

            if (not nIndex) then
                nIndex = #tNames + 1;
                tPositions[k], tNames[nIndex] = nIndex, k;
            end

            tValues[nIndex] = v;
        end,
        __type = "enumdefinition",
        __metatable = false,
    });

    return BuilderDecoy;
end

--[[!
    @fqxn LuaEx.Libraries.enum.isenum
    @pulsarlua function enum.isenum
    @desc Tests an actual enum collection, including one embedded as a parent member.
    @param any vValue The value to inspect.
    @ret boolean Whether it is a collection made by this factory.
    @ex local bEnum = enum.isenum(TIER);
!]]
local function isenum(vValue) return _tEnums[vValue] ~= nil; end

--[[!
    @fqxn LuaEx.Libraries.enum.isitem
    @pulsarlua function enum.isitem
    @desc Tests an actual enum member, including an embedded collection with a parent.
    @param any vValue The value to inspect.
    @ret boolean Whether it is a member made by this factory.
    @ex local bItem = enum.isitem(TIER.I);
!]]
local function isitem(vValue) return _tItems[vValue] ~= nil; end

--[[!
    @fqxn LuaEx.Libraries.enum.restore
    @pulsarlua function enum.restore
    @desc Codec restoration step. Adopts freshly decoded private child collections
    to preserve references to nested members. Children must be unparented and
    privately owned by the same decoding token. Member state {parent, name}
    resolves a member of its restored parent. Use deserialize for snapshots of live enums,
    which instead creates independent child wrappers.
    @param table tData An owned decoded definition {name, names, values}.
    @param table tOwner The codec's opaque ownership token.
    @ret enum A restored private enum.
    @ex local oDecoded = enum.restore({name = "DecodedExample", names = {"FIRST"}, values = {false}}, {});
!]]
local function restore(tData, tOwner)
    type.assert.table(tData);
    assert(rawtype(tOwner) == "table", "Enum codec restoration requires an ownership token.");
    local oResult;

    if (tData.parent) then
        assert(_tEnums[tData.parent] and rawtype(tData.name) == "string", "Malformed saved enum member.");
        local oMember = tData.parent[tData.name];
        assert(_tItems[oMember], "Saved enum member does not exist.");
        oResult = oMember;
    else
        -- Validate adoption as a batch before changing any decoded child's parent.
        local tSeen = {};
        type.assert.table(tData.values);

        for _, oChild in pairs(tData.values) do
            local tChild = _tEnums[oChild];

            if (tChild) then
                assert(tChild.private and not tChild.parent and rawequal(tChild.owner, tOwner) and not tSeen[oChild], "Decoded enum children must be distinct collections owned by this restoration.");
                tSeen[oChild] = true;
            end
        end

        oResult = buildEnum(tData.name, tData.names, tData.values, true, nil, nil, nil, tOwner);
    end

    return oResult;
end

local EnumFactoryActual = {
    deserialize = deserialize,
    isenum = isenum,
    isitem = isitem,
    prep = prep,
    restore = restore,
    snapshot = snapshot,
};
local EnumFactoryDecoy = {};
--[[!
    @fqxn LuaEx.Libraries.enum.__call
    @pulsarlua function enum
    @desc Creates enum(name, names, values, private). Names are a nonempty dense
    list of unique identifiers. Optional values use matching ordinal indices;
    missing values or ENUM_DEFAULT_VALUE use the ordinal. False remains false.
    Call a completed enum, or use pairs/ipairs, to iterate members in order.
    __count and # return its size, __name returns its declared name, and __hasa
    tests exact parent membership. Dot/string and one-based numeric lookup agree.
    @param string sName The declared name.
    @param table tNames The member-name list.
    @param table tValues Optional payloads; defaults to an empty table.
    @param boolean bPrivate Optional; defaults to false.
    @ret enum The new enum collection.
    @ex local oEnum = enum("PrivateExample", {"FIRST", "SECOND"}, {false}, true);
!]]
local EnumFactoryMeta = {
    __call = function(_, sName, tNames, tValues, bPrivate)
        assert(bPrivate == nil or rawtype(bPrivate) == "boolean", "Private option must be a boolean.");
        return buildEnum(sName, tNames, tValues == nil and {} or tValues, bPrivate == true);
    end,
    __index = EnumFactoryActual,
    __newindex = modifyError,
    __clone = function() return EnumFactoryDecoy; end,
    __serialize = function() return "enum"; end,
    __tostring = function() return "enumfactory"; end,
    __type = "enumfactory",
};
EnumFactoryMeta.__metatable = publicMeta(EnumFactoryMeta);
setmetatable(EnumFactoryDecoy, EnumFactoryMeta);
require("LuaEx.lib.serializer").registerFactory(EnumFactoryDecoy, {
    name = "enum",
    types = {"enum", "enumitem"},
    restore = restore,
});
return EnumFactoryDecoy;
