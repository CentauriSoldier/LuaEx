--TODO add tostring/ser/des methods
--TODO localization
-- Function to compare keys for sorting
local function defaultSorter(a, b)
    return a < b;
end

local function addOLD(this, cdat, vKey, vValue)
    local pri           = cdat.pri;
    local fSorter       = pri.sorter;
    local tActual       = pri.actual;
    local tKeys         = pri.keys;
    local sTypeKey      = type(vKey);

    if (sTypeKey ~= "string") then
        error("Error adding item to SortedDictionary.\nKey type expected: string. Type given: "..sTypeKey..'.', 2);
    end
    --TODO check for self-reference so we don't trigger a death loop

    local bAddToKeys = true;
    for _, sExistingKey in ipairs(tKeys) do

        if (vKey == sExistingKey) then
            bAddToKeys = false;
            break;
        end

    end

    if (bAddToKeys) then
        tKeys[#tKeys + 1] = vKey;
    end

    table.sort(tKeys, fSorter);
    tActual[vKey] = vValue;

    return this;
end

return class("SortedDictionary",
{--METAMETHODS
    __clone = function(this, cdat)
        local pri     = cdat.pri;
        local oNew    = SortedDictionary();
        local newcdat = cdat.ins[oNew];
        local newpri  = newcdat.pri;

        newpri.actual  = clone(pri.actual);
        newpri.keys    = clone(pri.keys);
        newpri.sorter  = pri.sorter; --don't clone the sorter function

        return oNew;
    end,
    __call = function(this, cdat) --NOTE: 5.1 compat
        local nIndex    = 0;
        local tActual   = cdat.pri.actual;
        local tKeys     = cdat.pri.keys;

        local function iterator()
            nIndex = nIndex + 1

            if tKeys[nIndex] then
                return tKeys[nIndex], tActual[tKeys[nIndex]];
            end

        end

        return iterator, tActual, nil;
    end,
    __pairs = function(this, cdat)
        return cdat.met.__call();
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
    add = function(this, cdat, vKey, vValue)
        local pri           = cdat.pri;
        local fSorter       = pri.sorter;
        local tActual       = pri.actual;
        local tKeys         = pri.keys;
        local sTypeKey      = type(vKey);
        local sValueType    = type(vValue);

        if (sTypeKey ~= "string") then
            error("Error adding item to SortedDictionary.\nKey type expected: string. Type given: "..sTypeKey..'.', 2);
        end
        --TODO check for self-reference so we don't trigger a death loop

        local bAddToKeys = true;
        for _, sExistingKey in ipairs(tKeys) do

            if (vKey == sExistingKey) then
                bAddToKeys = false;
                break;
            end

        end

        if (bAddToKeys) then
            tKeys[#tKeys + 1] = vKey;
        end

        table.sort(tKeys, fSorter);
        tActual[vKey] = vValue;

        return this;
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
    containsValue = function()
        --TODO FINISH
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
        table.sort(tKeys, fSorter);
        pri.actual[vKey] = nil;
    end,
    set = function(this, cdat, vKey, vValue)
        local pri           = cdat.pri;
        local fSorter       = pri.sorter;
        local tActual       = pri.actual;
        local tKeys         = pri.keys;
        local sTypeKey      = type(vKey);
        local sValueType    = type(vValue);

        if (sTypeKey ~= "string") then
            error("Error adding item to SortedDictionary.\nKey type expected: string. Type given: "..sTypeKey..'.', 2);
        end
        --TODO check for self-reference so we don't trigger a death loop

        local bAddToKeys = true;
        for _, sExistingKey in ipairs(tKeys) do

            if (vKey == sExistingKey) then
                bAddToKeys = false;
                break;
            end

        end

        if (bAddToKeys) then
            tKeys[#tKeys + 1] = vKey;
        end

        table.sort(tKeys, fSorter);
        tActual[vKey] = vValue;

        return this;
    end,
    setSortFunction = function(this, cdat, fSorter)
        local sSorterType = type(fSorter);

        if (sSorterType == "function") then
            --set the new sorter function
            cdat.pri.sorter = fSorter;
        else

            if (sSorterType == "nil") then
                --set the sorter back to default
                cdat.pri.sorter = defaultSorter;
            else
                error("Error setting sort method for SortedDictionary. Type given: "..type(fSorter)..'.', 2);
            end

        end

        --sort the object
        local bSuccess, sError = pcall(
            function()
                table.sort(cdat.pri.keys, fSorter)
            end
        );

        if not (bSuccess) then
            error("Error setting sort method for SortedDictionary.\n"..sError, 2);
        end

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
