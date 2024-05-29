
local function clone(vItem)
    print("The cloner module is in progress...", vItem)
end




local tClonerActual = {
    clone = clone
};
local tClonerDecoy  = {};
local tClonerMeta   = {
    __index = function(t, k)

        if (rawtype(tClonerActual[k]) ~= "nil") then
            return tClonerActual[k];
        end

    end,
};

setmetatable(tClonerDecoy, tClonerMeta);
return tClonerDecoy;
