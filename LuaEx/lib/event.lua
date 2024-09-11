local subtype   = subtype;
local table     = table;
local type      = type;

local unpack    = table.unpack;
local remove    = table.remove;

local tArgDummy = {}; --used when no input args exist in the fire method

local function hookError(sMethod, zHook)
    error("Error in event method, '${method}'. Hook must be of type function. Type given: ${type}." % {method = sMethod, type = zHook});
end

local function event(eIDInput, wTarget)
    local tEventDecoy   = {};
    local yID           = subtype(eIDInput);
    --local zID           = type(vIDInput);


    if not (yID == "enumitem") then--or zID == "string") then
        --error("Error creating event. Event ID must be of type string or subtype enumitem. Type/subtype given: ${type}/${subtype}." % {type = zID, subtype = yID});
        error("Error creating event. Event ID must be of subtype enumitem. Subtype given: ${subtype}." % {subtype = yID});
    end

    --create the event's fields
    local bIsActive     = true;
    local wDefault      = type(wTarget) == "table" and wTarget or _ENV;
    local eID           = eIDInput;
    local tHooks        = {};
    local tHookOrder    = {};

    --setup the event actual table
    local tEvent        = {
        addHook = function(fHook, wTarget)
            zHook = type(fHook);

            if (zHook ~= "function") then
                hookError("addHook", zHook);
            end

            --add the hook
            if (tHooks[fHook] == nil) then

                tHookOrder[#tHookOrder + 1] = fHook;

                tHooks[fHook] = {
                    isActive = true,
                    env      = type(wTarget) == "table" and wTarget or wDefault,
                };

            end

            return tEventDecoy;
        end,

        fire = function(...)
            tRet = {};

            if (bIsActive) then--fire only if the event is active
                local tArgs     = {...} or arg;
                local tInput;

                for nIndex, fHook in ipairs(tHookOrder) do
                    local tHook = tHooks[fHook];

                    if (tHook.isActive) then --fire the hook only if it's active
                        --get the input args (if any)
                        tInput = tArgs[nIndex] or tArgDummy;
                        --localize the old environment
                        local tOldEnv = _ENV;
                        --localize pcall so it can be used
                        local pcall = pcall;
                        --set the new environment
                        _ENV = tHook.env;
                        --fire the event callback
                        local bSuccess, vMsgOrRet = pcall(fHook, unpack(tInput));
                        --reset the environment
                        _ENV = tOldEnv;
                        --store the results
                        tRet[nIndex] = {success = bSuccess, output = vMsgOrRet};
                    end

                end

            end

            return tRet;
        end,

        getID = function()
            return eID;
        end,

        isActive = function()
            return bIsActive;
        end,

        isHookActive = function(fHook)
            zHook = type(fHook);

            if (zHook ~= "function") then
                hookError("addHook", zHook);
            end

            return tHooks[fHook].isActive;
        end,

        hookExists = function(fHook)
            return fHook ~= nil and tHooks[fHook] ~= nil;
        end,

        removeHook = function(fHook)
            zHook = type(fHook);

            if (zHook ~= "function") then
                hookError("removeHook", zHook);
            end

            --remove the hook
            if (tHooks[fHook] ~= nil) then

                for nIndex, fExistingHook in pairs(tHookOrder) do

                    if (fHook == fExistingHook) then
                        remove(tHookOrder, nIndex);
                        break;
                    end

                end

                tHooks[fHook] = nil;
            end

            return tEventDecoy;
        end,

        setActive = function(bFlag)
            bIsActive = type(bFlag) == "boolean" and bFlag or false;
            return tEventDecoy;
        end,

        setHookActive = function(fHook, bFlag)
            zHook = type(fHook);

            if (zHook ~= "function") then
                hookError("addHook", zHook);
            end

            tHooks[fHook].isActive = type(bFlag) == "boolean" and bFlag or false;
            return tEventDecoy;
        end,


        toggleActive = function()
            bIsActive = not bIsActive;
            return tEventDecoy;
        end,


        toggleHookActive = function(fHook)
            zHook = type(fHook);

            if (zHook ~= "function") then
                hookError("addHook", zHook);
            end

            tHooks[fHook].isActive = not tHooks[fHook].isActive;
            return tEventDecoy;
        end,
    };

    --setup the event's metatable
    local tEventMeta    = {
        --__call = function(t, ...)

        --end,
        __serialize = function()
            --TODO CLONE TOO
        end,
        __index = function(t, k)
            return tEvent[k] or nil;
        end,
        __newindex = function(t, k, v) end,
        __subtype   = "event", --put here for quick checking in eventrix
        __type      = "event",
    };

    setmetatable(tEventDecoy, tEventMeta);
    return tEventDecoy;
end




local tEventFactory        = {};
local tEventFactoryDecoy   = {};
local tEventFactoryMeta    = {
    __call = function(t, ...)
        return event(...);
    end,
    __index = function(t, k)
        return tEvent[k] or nil;
    end,
    __newindex = function(t, k, v) end,
    __type = "eventfactory",
};
setmetatable(tEventFactoryDecoy, tEventFactoryMeta);

return tEventFactoryDecoy;
