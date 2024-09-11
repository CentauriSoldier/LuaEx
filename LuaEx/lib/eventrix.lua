local subtype   = subtype;
local table     = table;
local type      = type;

local unpack    = table.unpack;
local remove    = table.remove;

local function eventError(sMethod, zEvent)
    error("Error in eventrix method, '${method}'. Event must be of type string or event. Type given: ${type}." % {method = sMethod, type = zEvent});
end

local function eventrix()
    local tEventrixDecoy   = {};

    --create the eventrix's fields
    local tEvents        = {};
    local tEventsByID    = {};

    --setup the eventrix's actual table
    local tEventrix        = {
        add = function(jEvent)
            zEvent = type(jEvent);

            if not (zEvent == "event") then
                error("Error adding event to eventrix. Type expected: event. Type given: "..zEvent..'.');
            end

            --add the event
            if (tEvents[jEvent] == nil) then
                tEvents[jEvent]              = true;
                tEventsByID[jEvent.getID()] = jEvent;
            end

            return tEventrixDecoy;
        end,

        get = function(eEventID)
            local yEvent = subtype(eEventID);

            if (yEvent ~= "enumitem") then
                error("Error getting event from eventrix. Event ID must be of subtype enumitem. Got subtype, ${subtype}." % {subtype = yEvent});
            end

            return tEventsByID[eEventID] or nil;
        end,

        exists = function(vEventOrID)
            local bRet = false;
            local yEvent = subtype(vEventOrID);

            if (yEvent == "event") then --search by event
                bRet = tEvents[vEventOrID] ~= nil;

            elseif (yEvent == "enumitem") then --search by event ID
                bRet = tEventsByID[vEventOrID] ~= nil;

            else
                error("Error getting event from eventrix. Input must be of subtype event or enumitem. Got subtype, ${subtype}" % {subtype = yEvent});
            end

            return bRet;
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
