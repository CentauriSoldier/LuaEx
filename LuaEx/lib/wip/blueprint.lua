local function checkForMeta(vInput)--TODO handle self-refences

    if (rawtype(vInput) == "table") then

        if (type(rawgetmetatable(vInput)) == "table") then
            error("Error creating blueprint factory.\nFactory input table (and subtables) cannot have a metatable.", 5);
        end

        for k, v in pairs(vInput) do
            checkForMeta(k);
            checkForMeta(v);
        end

    end

end


local function validateInput(tInput)
    if not (type(tInput) == "table") then
        error("Error creating blueprint factory.\nExpected type table. Type given: "..type(tInput)..'.', 3);
    end

    checkForMeta(tInput);
end




local tBPFactoryBuilder         = {};
local tBPFactoryBuilderDecoy    = {};
local tBPFactoryBuilderMeta     = {
    __call = function(__IGNORE__, tInput)
        validateInput(tInput);

        local tBP        = clone(tInput, true)
        local tBPFactory = {};

        local tBPFactoryMeta = {
            __call = function(__IGNORE__ME__)
                return clone(tBP);
            end,
            __index = function(t, k)
                error("Error: attempting to access blueprint factory.", 4);
            end,
            __newindex = function(t, k)
                error("Error: attempting to modify read-only blueprint factory.", 4);
            end,
            __serialize = function()
                return "blueprint("..')';--TODO
            end,
            __tostring = function()
                return "blueprintfactory"--TODO
            end,
            __type = "blueprint",
        };

        local tBPFactoryDecoy = {};
        rawsetmetatable(tBPFactoryDecoy, tBPFactoryMeta);
        return tBPFactoryDecoy;
    end,
    __index = function(t, k)

        if (rawtype(tBPFactoryBuilder[k]) ~= "nil") then
            return tBPFactoryBuilder[k];
        end

    end,
    __newindex = function(t, k)
        error("Error: attempting to modify read-only blueprint factory builder.", 3);
    end,
    __serialize = function()
        return "blueprint";--TODO
    end,
    __tostring = function()
        return "blueprintfactorybuilder"
    end,
    __type = "blueprintfactorybuilder",
};

rawsetmetatable(tBPFactoryBuilderDecoy, tBPFactoryBuilderMeta);
return tBPFactoryBuilderDecoy;
