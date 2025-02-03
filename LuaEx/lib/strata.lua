local buildStrata;

buildStrata = function (_, sName, tInput)
    local tRet = {};

    local nSubKeyCount = 0;

    for k, v in pairs(tInput) do
        nSubKeyCount = nSubKeyCount + 1;

        --TODO check k, v for proper types

        local nMyKeyCount;
        local tMeta;
        tRet[k], nMyKeyCount = buildStrata(_, sName..'.'..k, v);

        setmetatable(tRet[k], {
            __call = function(t)
                return tRet;
            end,
            __index = function(t, k)
                return k;
            end,
            __len = function(t)
                return nMyKeyCount or 0;
            end,
            __unm = function(l, r)
                return k;
            end,
            __newindex = function(t, k, v) end, --deadcall
            __tostring = function()
                return sName..'.'..k;
            end,
            --__type = sName,
            --__subtype = sName..'.'..k,
            __type = sName,
            __subtype = "strata",
        });
    end

    setmetatable(tRet, {
        __call = function(t)
            --return tRet;
        end,
        __index = function(t, k)
            return tRet;
        end,
        __len = function(t)
            --local mt = getmetatable(t)
            --return mt and mt.__keycount or 0
            return nSubKeyCount
        end,
        __unm = function(l, r)
            return sName;
        end,
        __newindex = function(t, k, v) end, --deadcall
        __tostring = function()
            return sName;
        end,
        __type = "strata",
    });

    return tRet, nSubKeyCount;
end

--TODO setup for serializer and cloner
local tStrata = {

};
local tStrataDecoy  = {};
local sStrataMeta    = {
    __call = buildStrata,
    __type = "stratafactory",
    __index = function(t, k) return tStrata[k] or nil end, --deadcall
    __newindex = function(t, k, v) end, --deadcall
};

setmetatable(tStrataDecoy, sStrataMeta);
--CATS = buildStrata(_, "CATS", {MEOW = {BLUE = {}, GREEN = {}, ORANGE= {}}, NONMEOW = {LONG = {}, SHORT = {}}});
--print(CATS.MEOW.BLUE()())
return tStrataDecoy;
