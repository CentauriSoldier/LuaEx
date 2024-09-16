--[[!
@fqxn LuaEx.Libraries.Eventrix
@desc The eventrix object is designed to be an event system that can be used locally and/or globally.
!]]
local rawtype   = rawtype;
local subtype   = subtype;
local table     = table;
local type      = type;

local unpack    = table.unpack;
local remove    = table.remove;


local tArgDummy = {}; --used when no input args exist in the fire method

local function hookError(sMethod, zHook)
    error("Error in eventrix method, '${method}'. Hook must be of type function. Type given: ${type}." % {method = sMethod, type = zHook}, 3);
end

local function eventError(sMethod, yEvent)
    error("Error in eventrix method, '${method}'. Event ID must be of type enumitem. Type given: ${type}." % {method = sMethod, type = yEvent}, 3);
end

local function eventrix(wTarget)
    local tEventrixDecoy    = {};
    local wDefault          = type(wTarget) == "table" and wTarget or _ENV;

    --create the eventrix's fields
    local tEvents        = {};

    --setup the eventrix's actual table
    local tEventrix        = {
        addHook = function(eEventID, fHook, wTarget)
            local zHook = rawtype(fHook);
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("addHook", yID);
            end

            if (zHook ~= "function") then
                hookError("addHook", zHook);
            end

            --add the event if it doesn't exist
            if (tEvents[eEventID] == nil) then
                tEvents[eEventID] = {
                    isActive    = true,
                    hooks       = {},
                    hookOrder   = {},
                };
            end

            local tEvent = tEvents[eEventID];

            --add the hook
            if (tEvent.hooks[fHook] == nil) then

                tEvent.hookOrder[#tHookOrder + 1] = fHook;

                tEvent.hooks[fHook] = {
                    isActive = true,
                    env      = type(wTarget) == "table" and wTarget or wDefault,
                };

            end

            return tEventDecoy;
        end,

        getHookCount = function(eEventID)
            local yID = subtype(eEventID);

            if (yID ~= "enumitem") then
                eventError("getHookCount", yID);
            end

            return tEvents[eEventID] ~= nil and #tEvents[eEventID].hookOrder or -1;
        end,

        eventExists = function(eEventID)
            local yID = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("eventExists", yID);
            end

            return tEvents[eEventID] ~= nil;
        end,

        --[[fire = function(eEventID, ...)
            local tRet  = {};
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("fire", yID);
            end

            if (tEvents[eEventID] ~= nil and tEvents[eEventID].isActive) then--fire only if the event is active
                local tInput;
                local tArgs     = {...} or arg;
                local tEvent    = tEvents[eEventID];
                local tHooks    = tEvent.hooks;

                for nIndex, fHook in ipairs(tEvent.hookOrder) do
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
        end,]]

        fire = function(eEventID, ...)
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("fire", yID);
            end

            if (tEvents[eEventID] ~= nil and tEvents[eEventID].isActive) then--fire only if the event is active
                local tEvent    = tEvents[eEventID];
                local tHooks    = tEvent.hooks;

                for nIndex, fHook in ipairs(tEvent.hookOrder) do
                    local tHook = tHooks[fHook];

                    if (tHook.isActive) then --fire the hook only if it's active
                        --localize the old environment
                        local tOldEnv = _ENV;
                        --localize pcall so it can be used
                        local pcall = pcall;
                        --set the new environment
                        _ENV = tHook.env;
                        --fire the event callback with any input args
                        local bSuccess, vMsgOrRet = pcall(fHook, ...);
                        --TODO log errors
                        --reset the environment
                        _ENV = tOldEnv;
                    end

                end

            end

            return tEventrixDecoy;
        end,

        isEventActive = function(eEventID)
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("isEventActive", yID);
            end

            return tEvents[eEventID] ~= nil and tEvents[eEventID].isActive;
        end,

        isHookActive = function(eEventID, fHook)
            local bRet  = false;
            local yID   = subtype(eEventID);
            local zHook = rawtype(fHook);

            if not (yID == "enumitem") then
                eventError("isHookActive", yID);
            end

            if (zHook ~= "function") then
                hookError("isHookActive", zHook);
            end

            if (tEvents[eEventID]) then
                local tHooks = tEvents[eEventID].hooks;
                bRet = tHooks[fHook] ~= nil and tHooks[fHook].isActive;
            end

            return bRet;
        end,

        removeEvent = function(eEventID)
            local yID = subtype(eEventID);

            if not (yID == "enumitem") then--or zID == "string") then
                eventError("removeEvent", zHook);
            end

            if (tEvents[eEventID] ~= nil) then
                tEvents[eEventID] = nil;
            end

            return tEventrixDecoy;
        end,


        removeHook = function(eEventID, fHook) --TODO
            local yID   = subtype(eEventID);
            local zHook = rawtype(fHook);

            if not (yID == "enumitem") then
                eventError("removeHook", yID);
            end

            if (zHook ~= "function") then
                hookError("removeHook", zHook);
            end

            if (tEvents[eEventID] ~= nil) then
                local tEvent        = tEvents[eEventID];
                local tHooks        = tEvent.hooks;
                local tHookOrder    = tEvent.hookOrder;

                if (tHooks[fHook] ~= nil) then

                    for nIndex, fExistingHook in ipairs(tHookOrder) do

                        if (fHook == fExistingHook) then
                            remove(tHookOrder, nIndex);
                            tHooks[fHook] = nil;
                            break;
                        end

                    end

                end

            end

            return tEventrixDecoy;
        end,

        setEventActive = function(eEventID, bFlag)
            local yID   = subtype(eEventID);

            if not (yID == "setEventActive") then
                eventError("setEventActive", yID);
            end

            if (tEvents[eEventID] ~= nil) then
                tEvents[eEventID].isActive = rawtype(bFlag) == "boolean" and bFlag or false;
            end

            return tEventrixDecoy;
        end,

        setHookActive = function(eEventID, fHook, bFlag)
            local yID   = subtype(eEventID);
            local zHook = rawtype(fHook);

            if not (yID == "enumitem") then
                eventError("setHookActive", yID);
            end

            if (zHook ~= "function") then
                hookError("setHookActive", zHook);
            end

            if (tEvents[eEventID] ~= nil and tEvents[eEventID].hooks[fHook] ~= nil) then
                tEvents[eEventID].hooks[fHook].isActive = rawtype(bFlag) == "boolean" and bFlag or false;
            end

            return tEventrixDecoy;
        end,
    };

    --setup the eventrix's metatable
    local tEventrixMeta    = {
        --__call = function(t, ...)

        --end,
        __index = function(t, k)
            return tEventrix[k] or nil;
        end,
        __newindex = function(t, k, v) end,
        __type = "eventrix",
    };

    setmetatable(tEventrixDecoy, tEventrixMeta);
    return tEventrixDecoy;
end



--TODO FINISH clone and de/serialize
local tEventrixFactory        = {};
local tEventrixFactoryDecoy   = {};
local tEventrixFactoryMeta    = {
    __call = function(t, ...)
        return event(...);
    end,
    __index = function(t, k)
        return tEventrix[k] or nil;
    end,
    __newindex = function(t, k, v) end,
    __type = "eventrixfactory",
};
setmetatable(tEventrixFactoryDecoy, tEventrixFactoryMeta);

return tEventrixFactoryDecoy;
