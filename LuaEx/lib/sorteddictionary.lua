--TODO localization
local rawsetmetatable   = rawsetmetatable;
local rawtype           = rawtype;
local table             = table;
local type              = type;
local xpcall            = xpcall;

-- Function to compare keys for sorting
local function defaultSorter(a, b)
    return a < b;
end

local tSDActual = {
    deserialize = deserialize,
};

return rawsetmetatable(tSDActual, {
    __call = function(__IGNORE__)--TODO allow table input
        local fSort       = defaultSorter;
        local tDecoy      = {};
        local tSortedDict = {};
        local tSortedKeys = {};

        local tMeta = {
            __call = function(this, fNewSorter)

                if (rawtype(fNewSorter) ~= "function") then
                    error("Error setting sort method for sorteddictionary. Type given: "..rawtype(fNewSorter)..'.', 2);
                end

                --set the new sorter function
                fSort = fNewSorter;

                --sort the object
                local bSuccess, sError = xpcall(table.sort, function() return fSort end, tSortedKeys)

                if not (bSuccess) then
                    error("Error setting sort method for sorteddictionary.\n"..sError, 2);
                end

                return tSortedDict;
            end,
            __index = function(t, k)
                local vRet = nil;

                --try to get the value
                local sType = type(k);
                if (sType == "string") then
                    local vValue = rawget(tSortedDict, k);

                    if not (vValue) then
                        error("Error retrieving value from sorteddictionary.\nNo such index, '${index}', exists." % {index = k}, 2);
                    end

                    vRet = rawget(tSortedDict, k) or nil;
                else
                    error("Error retrieving value from sorteddictionary.\nIndex must be of type string. Type given: "..rawtype(k)..'.', 2);
                end

                return vRet;
            end,
            __newindex = function(t, k, v)
                local sTypeK = rawtype(k);
                local sTypeV = rawtype(v);
                print(sTypeK, sTypeV)
                if (sTypeK ~= "string") then

                    --if (sTypeK == "function") then
                        error("Error adding item to sorted dictionary.\nKey type expected: string. Type given: "..sTypeK..'.', 2);
                    --else

                    --end

                end

                if (sTypeV ~= "nil") then

                    if rawget(t, k) == nil then--TODO BUG FIX  address deletions
                        table.insert(tSortedKeys, k);
                    end

                    table.sort(tSortedKeys, fSort);
                    rawset(t, k, v);
                else
                    print(t, k, v)
                end

            end,
            __pairs = function(self)
                local nIndex = 0;

                local function iterator()
                    nIndex = nIndex + 1

                    if tSortedKeys[nIndex] then
                        return tSortedKeys[nIndex], self[tSortedKeys[nIndex]];
                    end

                end

                return iterator, self, nil;
            end,
            --__tostring = function()
                --return error("TODO")
            --end,
            __type      = "sorteddictionary",
            __subtype   = "table",
            __serialize = function() return error("TODO") end,
        }

        -- Set the metatable for the sorted dictionary
        setmetatable(tDecoy, tMeta);

        return tDecoy;
    end,
    __index = function(t, k)
        return tSDActual[k] or nil;
    end,
    __newindex = function(t, k, v)
        error("Error: attempting to modify read-only sorteddictionary factory at index ${index} with ${value} (${type})." % {index = tostring(k), value = tostring(v), type = type(v)});
    end,
    __serialize = function() end,
    __subtype = "table",
    __tostring = function()
        return "IN PROGRESS";
    end,
    __type = "sorteddictionaryfactory",
});
