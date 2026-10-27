--TODO add tostring/ser/des methods
--TODO localization
-- Function to compare keys for sorting
local function defaultSorter(a, b)
    return a < b;
end

--[[!
    @fqxn LuaEx.Classes.SortedDictionary.Helpers.storeItem
    @scope local
    @desc Adds or replaces a string-keyed entry. New keys are sorted in temporary
    storage so a comparator error cannot leave a ghost key or corrupt key order.
    Explicit nil values retain their key until remove is called.
    @param SortedDictionary this Dictionary receiving the entry.
    @param table cdat Instance class data.
    @param string sKey Entry key.
    @param any vValue Entry value, including nil.
    @ret SortedDictionary this The same dictionary for chaining.
!]]
local function storeItem(this, cdat, sKey, vValue)
    if (type(sKey) ~= "string") then
        error("Error adding item to SortedDictionary. Key must be a string.", 3);
    end

    local pri = cdat.pri;
    local bExists = false;

    for _, sExisting in ipairs(pri.keys) do
        if (sExisting == sKey) then
            bExists = true;
            break;
        end
    end

    if (not bExists) then
        local tKeys = {};

        -- Commit the new ordered list only after the comparator succeeds.
        for nIndex, sExisting in ipairs(pri.keys) do
            tKeys[nIndex] = sExisting;
        end

        tKeys[#tKeys + 1] = sKey;
        table.sort(tKeys, pri.sorter);
        pri.keys = tKeys;
    end

    pri.actual[sKey] = vValue;
    return this;
end

return class("SortedDictionary",
{--METAMETHODS
    __clone = function(this, cdat)
        local pri     = cdat.pri;
        local oNew    = SortedDictionary();
        local newcdat = cdat.ins[oNew];
        local newpri  = newcdat.pri;

        cloner.registerCopy(this, oNew);
        newpri.actual  = clone(pri.actual);
        newpri.keys    = clone(pri.keys);
        newpri.sorter  = pri.sorter; --don't clone the sorter function

        return oNew;
    end,
    __call = function(this, cdat) --NOTE: 5.1 compat
        local nIndex    = 0;
        local tActual   = cdat.pri.actual;
        local tKeys     = cdat.pri.keys;

        local function fIterator()
            nIndex = nIndex + 1

            if tKeys[nIndex] then
                return tKeys[nIndex], tActual[tKeys[nIndex]];
            end

        end

        -- The iterator state is the public object, never its private storage.
        return fIterator, this, nil;
    end,
    __pairs = function(this, cdat)
        -- Use the same ordered iterator as direct calls.
        return this();
    end,
},
{--STATIC PUBLIC

},
{--PRIVATE
    actual  = {}, --where the dictionary data is stored
    keys    = {}, --used to sort the dictionary's keys
    sorter  = null,
},
{--PROTECTED

},
{--PUBLIC
    SortedDictionary = function(this, cdat)--TODO allow initial input
        cdat.pri.sorter = defaultSorter;
    end,
    --[[!
        @fqxn LuaEx.Classes.SortedDictionary.Methods.add
        @desc Adds or replaces a string-keyed entry without duplicating its key.
        @param string sKey Entry key.
        @param any vValue Entry value.
        @ret SortedDictionary this The same dictionary.
    !]]
    add = function(this, cdat, sKey, vValue)
        return storeItem(this, cdat, sKey, vValue);
    end,
    containsKey = function(this, cdat, vKey)
        local bRet = false;

        local sTypeKey = type(vKey);

        if (sTypeKey ~= "string") then
            error("Error ascertaining existence of key in SortedDictionary.\nKey type expected: string. Type given: "..sTypeKey..'.', 2);
        end

        for _, sExistingKey in ipairs(cdat.pri.keys) do

            if (vKey == sExistingKey) then
                bRet = true;
                break;
            end

        end

        return bRet;
    end,
    --[[!
        @fqxn LuaEx.Classes.SortedDictionary.Methods.containsValue
        @desc Tests stored entries with Lua equality. Explicit nil-valued entries
        count as present; an empty dictionary contains no values.
        @param any vValue Value to find.
        @ret boolean bContains Whether an ordered entry has this value.
    !]]
    containsValue = function(this, cdat, vValue)
        for _, sKey in ipairs(cdat.pri.keys) do
            if (cdat.pri.actual[sKey] == vValue) then
                return true;
            end
        end

        return false;
    end,
    get = function(this, cdat, vKey)
        local sTypeKey = type(vKey);

        if (sTypeKey ~= "string") then
            error("Error getting value from SortedDictionary.\nKey type expected: string. Type given: "..sTypeKey..'.', 2);
        end

        local bKeyExists = false;
        for k, v in ipairs(cdat.pri.keys) do

            if (v == vKey) then
                bKeyExists = true;
                break;
            end

        end

        if not (bKeyExists) then
            error("Error getting value from SortedDictionary.\nNo such key exists: '"..vKey.."'.", 2);
        end

        return cdat.pri.actual[vKey];
    end,
    remove = function(this, cdat, vKey)
        local pri       = cdat.pri;
        local tKeys     = pri.keys;
        local sTypeKey  = type(vKey);

        if (sTypeKey ~= "string") then
            error("Error removing item from SortedDictionary.\nKey type expected: string. Type given: "..sTypeKey..'.', 2);
        end

        local bKeyExists = false;
        local nIndex = -1;
        for _, v in ipairs(tKeys) do

            if (v == vKey) then
                bKeyExists = true;
                nIndex = _;
                break;
            end

        end

        if not (bKeyExists) then
            error("Error removing item from SortedDictionary.\nNo such key exists: '"..vKey.."'.", 2);
        end

        table.remove(tKeys, nIndex);
        -- Removing one key preserves the order established by the current comparator.
        pri.actual[vKey] = nil;
    end,
    --[[!
        @fqxn LuaEx.Classes.SortedDictionary.Methods.set
        @desc Replaces an entry or inserts a new string key in sorted order.
        @param string sKey Entry key.
        @param any vValue Entry value.
        @ret SortedDictionary this The same dictionary.
    !]]
    set = function(this, cdat, sKey, vValue)
        return storeItem(this, cdat, sKey, vValue);
    end,
    --[[!
        @fqxn LuaEx.Classes.SortedDictionary.Methods.setSortFunction
        @desc Sorts a temporary key list before committing the comparator and
        order. Nil restores ascending order; failed comparators preserve state.
        @param function|nil fSorter Comparator receiving two string keys.
        @ret SortedDictionary this The same dictionary.
    !]]
    setSortFunction = function(this, cdat, fSorter)
        if (fSorter ~= nil and type(fSorter) ~= "function") then
            error("Error setting sort method for SortedDictionary. Expected a function or nil.", 2);
        end

        local fNextSorter = fSorter or defaultSorter;
        local tKeys = {};

        for nIndex, sKey in ipairs(cdat.pri.keys) do
            tKeys[nIndex] = sKey;
        end

        -- An error leaves both the existing order and its comparator untouched.
        table.sort(tKeys, fNextSorter);
        cdat.pri.keys = tKeys;
        cdat.pri.sorter = fNextSorter;

        return this;
    end,
    size = function(this, cdat)
        return #cdat.pri.keys;
    end,
},
nil,        --extending class
false,      --if the class is final
iCloneable  --interface(s) (either nil, or interface(s))
);
