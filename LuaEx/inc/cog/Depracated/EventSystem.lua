local assert    = assert;
local class     = class;
local pairs     = pairs;
local pcall     = pcall;
local table     = table;
local type      = type;

local function validateEvent(tEvents, vOwner, sEvent, sMethod)
    local bExists = tEvents[vOwner]         ~= nil and
                    tEvents[vOwner][sEvent] ~= nil;

    if not (bExists) then
        error("Error caling EventSystem method, '${method}'. Invalid event." % {method = sMethod});
    end

end

--[[!
@fqxn CoG.EventSystem
@desc The EventSystem is designed to provide a simple-to-use, safe event system for your games.
<br>Each event must have an "owner" whether that be an object, a table, or even a simple string. In fact, the owner of a registered event can be any non-nil value.
<br>Event callbacks are executed in the environment set during event registration or the default environment if one is not set during registration.
<br>Each EventSystem can be created with a default environment in which all not-otherwise-specified callbacks will fire.
<br>Note: The EventSystem class is <b>not</b> static. You may create as many EventSystems as you wish since each one must be instantiated.
!]]
return class("EventSystem",
{--METAMETHODS

},
{--STATIC PUBLIC
    --EventSystem = function(stapub) end,
},
{--PRIVATE
    defaultEnv  = null,
    events      = {},
},
{--PROTECTED

},
{--PUBLIC
    --[[!
    @fqxn CoG.EventSystem.Methods.EventSystem
    @desc The constructor for the EventSystem.
    @param table|nil tEnv The default <a href="https://www.lua.org/manual/5.3/manual.html#2.2" target="_blank">environment</a> in which to fire event callbacks (if one is not specified during event registration). If nil, the current environment will be used as the default.
    @ex
    local tRestrictedEnv = {print = print, type = type, string = string};
    local oRestrictedEventSystem = EventSystem(tRestrictedEnv); -- creates an EventSystem with a restricted default env

    local oEventSystem = EventSystem(); --creates an EventSystem using the current environment as the default
    !]]
    EventSystem = function(this, cdat, tEnv)
        cdat.pri.defaultEnv = type(tEnv) == "table" and tEnv or _ENV;
    end,


    --[[!
    @fqxn CoG.EventSystem.Methods.fire
    @desc Fires an event callback.
    @param non-nil vAny The thing which is the owner of the callback. This can be any non-nil value.
    @param string sEvent The name of the event.
    @param ... ... Any number of varargs may be entered as parameters to the event callback.
    @ret boolean bSuccess Returns true if the event fired without error, false otherwise.
    @ret variable|nil vReturn There may be <b><i>one</i></b> <i>(and only one)</i> item returned from the actual event callback. If there needs to be multiple values returned, return a table with those values inside.
    <br>Note: if there was an error in the callback event, this value will be a string with the error message.
    @ex TODO
    ]]
    fire = function(this, cdat, vOwner, sEvent, ...)
        local pri     = cdat.pri;
        local tEvents = pri.events;
        local tRet    = {};

        validateEvent(tEvents, vOwner, sEvent, "fire");

        local tCallbacks = tEvents[vOwner][sEvent];

        for fCallback, tCallback in pairs(tCallbacks) do

            if (tCallback.isActive) then
                --localize the old environment
                local tOldEnv = _ENV;
                --localize pcall so it can be used
                local pcall = pcall;
                --set the new environment
                _ENV = tCallback.env;
                --fire the event callback
                local bSuccess, vMsgOrRet = pcall(fCallback, ...);
                --reset the environment
                _ENV = tOldEnv;
                --store the results
                tRet[fCallback] = {success = bSuccess, output = vMsgOrRet};
            end

        end

        return tRet;
    end,


    --[[!
    @fqxn CoG.EventSystem.Methods.isActive
    @desc Determines if the event callback is active.
    @param non-nil vAny The thing which is the owner of the callback. This can be any non-nil value.
    @param string sEvent The name of the event.
    @param function fCallback The callback function to check.
    @ret boolean bIsActive True if the event callback is active, false otherwise.
    @ex TODO
    ]]
    isActive = function(this, cdat, vOwner, sEvent, fCallback)
        local pri       = cdat.pri;
        local tEvents   = pri.events;

        validateEvent(tEvents, vOwner, sEvent, "isActive");

        local tCallbacks = tEvents[vOwner][sEvent];

        if (tCallbacks[fCallback] == nil) then
            --TODO THROW ERROR
        end

        return tCallbacks[fCallback].isActive;
    end,


    --[[!
    @fqxn CoG.EventSystem.Methods.register
    @desc Registers a callback function with an owner and event.
    @param non-nil vAny The thing which is the owner of the callback. This can be any non-nil value.
    @param string sEvent The name of the event.
    @param function fCallback The callback function to check.
    @param table|nil tEnv The environment in which the callback will be fired. If nil, it will be set to the <b>EventSystem's</b> default environment.
    @ret EventSystem oEventSystem The EventSystem.
    @ex TODO
    ]]
    register = function(this, cdat, vOwner, sEvent, fCallback, tEnv)
        local pri     = cdat.pri;
        local tEvents = pri.events;

        assert(vOwner ~= nil, "Error regsitering event, '${event}'. Event owner cannot be nil.");
        type.assert.string(sEvent, "%S+");
        type.assert["function"](fCallback);

        --create the owner's event table if it doesn't exist
        if (tEvents[vOwner] == nil) then
            tEvents[vOwner] = {};
        end

        --create the event's callback table if it doesn't exist
        if (tEvents[vOwner][sEvent] == nil) then
            tEvents[vOwner][sEvent] = {};
        end

        local tCallbacks = tEvents[vOwner][sEvent];

        --setup the function env
        local tEnv = type(tEnv) == "table" and tEnv or pri.defaultEnv;

        --register the event with the owner (and set it active by default)
        if (tCallbacks[fCallback] == nil) then
            tCallbacks[fCallback] = {
                isActive = true,
                env      = tEnv;
            };
        end

        return this;
    end,


    --[[!
    @fqxn CoG.EventSystem.Methods.setActive
    @desc Sets event callback(s) to active/inactive.
    @param non-nil vAny The thing which is the owner of the callback. This can be any non-nil value.
    @param string sEvent The name of the event.
    @param function|nil fCallback The callback function to set active/inactive. If this is nil, all callback functions for the event will be set active/inactive.
    @param boolean bSetActive Whether to activate or deactivate the event callback.
    @ret EventSystem oEventSystem The EventSystem.
    @ex TODO
    ]]
    setActive = function(this, cdat, vOwner, sEvent, fCallback, bFlag)
        local pri       = cdat.pri;
        local tEvents   = pri.events;

        validateEvent(tEvents, vOwner, sEvent, "setActive");

        local tCallbacks = tEvents[vOwner][sEvent];
        local bActive = type(bFlag) == "boolean" and bFlag or false;

        if (fCallback == nil) then

            for fCallback, tCallback in pairs(tCallbacks) do
                tCallback.isActive = bActive;
            end

        else

            if (tCallbacks[fCallback] == nil) then
                --TODO THROW ERROR
            end

            tCallbacks[fCallback].isActive = bActive;
        end

        return this;
    end,


    --[[!
    @fqxn CoG.EventSystem.Methods.toggleActive
    @desc Sets event callback(s) to active/inactive.
    @param non-nil vAny The thing which is the owner of the callback. This can be any non-nil value.
    @param string sEvent The name of the event.
    @param function|nil fCallback The callback function to set active/inactive. If this is nil, all callback functions for the event will be set active/inactive.
    @ret EventSystem oEventSystem The EventSystem.
    @ex TODO
    ]]
    toggleActive = function(this, cdat, vOwner, sEvent, fCallback)
        local pri       = cdat.pri;
        local tEvents   = pri.events;

        validateEvent(tEvents, vOwner, sEvent, "setActive");

        local tCallbacks = tEvents[vOwner][sEvent];
        local bActive = type(bFlag) == "boolean" and bFlag or false;

        if (fCallback == nil) then

            for fCallback, tCallback in pairs(tCallbacks) do
                tCallback.isActive = not tCallback.isActive;
            end

        else

            if (tCallbacks[fCallback] == nil) then
                --TODO THROW ERROR
            end

            local tCallback = tCallbacks[fCallback];
            tCallback.isActive = not tCallback;
        end

        return this;
    end,


    --[[!
    @fqxn CoG.EventSystem.Methods.
    @desc
    @ex
    ]]
    unregister = function(this, cdat, vOwner, sEvent, fCallback)--TODO FINISH
        local pri     = cdat.pri;
        local tEvents = pri.events;

        assert(vOwner ~= nil, "Error regsitering event, '${event}'. Event owner cannot be nil.");
        type.assert.string(sEvent, "%S+");
        type.assert["function"](fCallback);

        validateEvent(tEvents, vOwner, sEvent, "unregister");

        if (tCallbacks[fCallback] == nil) then
            --TODO THROW ERROR
        end

        --unregister the event
        tCallbacks[fCallback] = nil;

        return this;
    end,
},
nil,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
