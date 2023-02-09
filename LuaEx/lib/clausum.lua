


--clausum: locked, enclosure, locked place, inclosure
local function clausum(sType)
        --setup the table which will hold the values
        local actual   = {};
        --setup the decoy
        local decoy    = {};
        --keeps track of the items entered (in order)
        local tItemsByEntry	= {};

        --used to iterate over each item in the enum
        local function itemsIterator(tTheClausum, nTheIndex)

            if (nTheIndex < #tItemsByEntry) then --todo use count value
                nTheIndex = nTheIndex + 1;
                return nTheIndex, actual[tItemsByEntry[nTheIndex]];
            end

        end

        --the iterator setup function for the __call metamethod in the enum object
        local function items(tTheClausum)
            return itemsIterator, tTheClausum, 0;
        end

        return setmetatable(decoy, {
            __call = items,

            __index = function(table, key)
                local vRet = nil;

                if (rawtype(actual[key]) ~= "nil") then
                    vRet = actual[key].val;
                end

                return vRet;
            end,

            __newindex = function(table, key, value)

                if (rawtype(actual[key]) == "nil") then
                    actual[key] = setmetatable(
                    {val = value},
                    {
                        __type = "BUG",
                    }
                    );
                    --keep track of the items entered for the __call metamethod
                    tItemsByEntry[#tItemsByEntry + 1] = key;
                else
                    error("Error setting clausum value. Key '${querykey}' already exists." % {querykey = tostring(key)});
                end

            end,

            __type = type(sType) == "string" and sType or "clausum",
            __subtype = "clausum";

            --__tostring = function()
            --    return
            --end,
        });
end

return clausum;
--[[return setmetatable({}, {
    __call = clausum,
});
]]
