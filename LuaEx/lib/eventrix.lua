local subtype   = subtype;
local table     = table;
local type      = type;

local unpack    = table.unpack;
local remove    = table.remove;



                                            --[[
                                            ███████╗██╗   ██╗███████╗███╗   ██╗████████╗
                                            ██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝
                                            █████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║
                                            ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║
                                            ███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║
                                            ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ]]



local tArgDummy = {}; --used when no input args exist in the fire method

local function hookError(sMethod, zHook)
    error("Error in event method, '${method}'. Hook must be of type function. Type given: ${type}." % {method = sMethod, type = zHook}, 3);
end

local function event(eIDInput, wTarget)
    local tEventDecoy   = {};
    local yID           = subtype(eIDInput);

    if not (yID == "enumitem") then--or zID == "string") then
        error("Error creating event. Event ID must be of subtype enumitem. Subtype given: ${subtype}." % {subtype = yID}, 3);
    end

    --create the event's fields
    local bIsActive     = true;
    local wDefault      = type(wTarget) == "table" and wTarget or _ENV;
    local eID           = eIDInput;
    local tHooks        = {};
    local tHookOrder    = {};

    --setup the event actual table
    local tEvent        = {
        ,

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

        getHookCount = function()
            return #tHookOrder;
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

                                            --[[
                                            ███████╗██╗   ██╗███████╗███╗   ██╗████████╗██████╗ ██╗██╗  ██╗
                                            ██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔══██╗██║╚██╗██╔╝
                                            █████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ██████╔╝██║ ╚███╔╝
                                            ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ██╔══██╗██║ ██╔██╗
                                            ███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ██║  ██║██║██╔╝ ██╗
                                            ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝]]


















local function eventError(sMethod, zEvent)
    error("Error in eventrix method, '${method}'. Event must be of type string or event. Type given: ${type}." % {method = sMethod, type = zEvent});
end

local function eventrix(wTarget)
    local wDefault      = type(wTarget) == "table" and wTarget or _ENV;
    local tEventrixDecoy   = {};

    --create the eventrix's fields
    local tEvents        = {};
    --local tEventsByID    = {};

    --setup the eventrix's actual table
    local tEventrix        = {
        addHook = function(eEventID, fHook, wTarget)
            local zHook = type(fHook);
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then--or zID == "string") then
                error("Error adding hook to eventrix. Event ID must be of subtype enumitem. Subtype given: ${subtype}." % {subtype = yID}, 3);
            end

            if (zHook ~= "function") then
                hookError("addHook", zHook);
            end

            --add the event if it doesn't exist
            if (tEvents[eEventID] == nil) then
                tEvents[eEventID] = {
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
        end

        getHookCount = function(eEventID)
            local nRet = 0;
            local yEvent = subtype(eEventID);

            if (yEvent ~= "enumitem") then
                error("Error getting event from eventrix. Event ID must be of subtype enumitem. Got subtype, ${subtype}." % {subtype = yEvent});
            end

            if (tEventsByID[eEventID]) then
                nRet = #tEventsByID[eEventID].hookOrder;
            end

            return nRet;
        end,

        eventExists = function(eEventID)
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then--or zID == "string") then
                error("Error adding hook to eventrix. Event ID must be of subtype enumitem. Subtype given: ${subtype}." % {subtype = yID}, 3);
            end

            return tEvents[eEventID] ~= nil;
        end,

        remove = function(vEventOrID)
            local yEvent = subtype(vEventOrID);

            if (yEvent == "event") then --search by event

                if (tEvents[vEventOrID] ~= nil) then
                    tEvents[vEventOrID]             = nil;
                    tEventsByID[vEventOrID.getID()] = nil;
                end

            elseif (yEvent == "enumitem") then --search by event ID

                if (tEventsByID[vEventOrID] ~= nil) then
                    tEvents[tEventsByID[vEventOrID]] = nil;
                    tEventsByID[vEventOrID] = nil;
                end

            else
                error("Error getting event from eventrix. Input must be of subtype event or enumitem. Got subtype, ${subtype}" % {subtype = yEvent});
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
