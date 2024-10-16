constant("EVENTRIX_NIL", "EVENTRIX_NIL");
--[[!
@fqxn LuaEx.Libraries.eventrix
@desc
<h3>Eventrix Overview</h3>
The eventrix library is a flexible and modular event handling system designed to function in both local and global contexts. It provides a centralized approach for managing event-based interactions across different parts of a system.

<ul>
    <li><strong>Local and Global Functionality:</strong>
        <ul>
            <li>An eventrix can operate at both the global level (shared system-wide) or locally (specific to objects or components).</li>
        </ul>
    </li>
    <li><strong>Event Management:</strong>
        <ul>
            <li>Manages events through unique identifiers, ensuring that each event is handled appropriately.</li>
            <li>Supports the dynamic firing of events with arguments, allowing flexible interaction between components.</li>
        </ul>
    </li>
    <li><strong>Hooks and Callbacks:</strong>
        <ul>
            <li>Hooks can be attached to specific events, allowing custom callbacks to execute when the event is fired.</li>
            <li>Hooks are executed in a predetermined order and can exist in different environments, promoting modularity.</li>
        </ul>
    </li>
    <li><strong>Error Handling and Validation:</strong>
        <ul>
            <li>Built-in validation ensures hooks and events receive valid inputs, with error reporting mechanisms in place.</li>
        </ul>
    </li>
    <li><strong>System-Agnostic Design:</strong>
        <ul>
            <li>Eventrix is designed to be lightweight and decoupled from specific systems, making it suitable for use in a wide range of applications.</li>
        </ul>
    </li>
</ul>

<h3>Event IDs</h3>
An Event ID (eEventID) is a unique identifier used to distinguish individual events within the eventrix system. It serves as a key that helps organize and manage events, ensuring that specific actions or callbacks are triggered when particular events occur. The Event ID can represent a wide range of occurrences, such as an attack, item use, or environmental change. By assigning unique IDs to each event, the system can effectively register, track, and fire events based on their identifiers, making event handling scalable and organized across different scopes (global or local).
<br>
An event ID must be of type enumitem.
!]]

local envrepo   = envrepo;
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

--Docs for this function are above the __call metamethod found below
local function eventrix(sEnv)
    local tEventrixDecoy    = {};
    local wEnv              = envrepo[sEnv];
    local wDefault          = wEnv and wEnv or _ENV;

    --create the eventrix's fields
    local tEvents = {};

    --setup the eventrix's actual table
    local tEventrix        = {
        addHook = function(eEventID, fHook, sHookEnv)
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
                    isActive        = true,
                    hooks           = {},
                    hookOrder       = {},
                    hookOrdinals    = {},
                };
            end

            local tEvent        = tEvents[eEventID];
            local tHooks        = tEvent.hooks;
            local tHookOrder    = tEvent.hookOrder;
            local tHookOrdinals = tEvent.hookOrdinals;
            local eEnv          = envrepo[sHookEnv];

            --add the hook
            if (tHooks[fHook] == nil) then
                local nOrdinal = #tHookOrder + 1;

                tHookOrder[nOrdinal]    = fHook;
                tHookOrdinals[fHook]    = nOrdinal;
                tHooks[fHook]           = {
                    isActive = true,
                    env      = eEnv and eEnv or wDefault,
                };

            end

            return tEventDecoy;
        end,


        --[[!
        @fqxn LuaEx.Libraries.eventrix.getHookCount
        @desc
        Determines the number of hooks that are currently registered to the specified event. Hooks are functions or callbacks associated with an event that are triggered when the event is fired. The count allows you to know how many hooks are waiting to execute when the event with the given ID is fired.
        @param enumitem eEventID The unique identifier for the event. This ID is used to retrieve the count of hooks tied to the event in question.
        @return number The number of hooks associated with the specified event.
        @ret number nHookCount The total number of hooks associated with the event. If the event does not exist, a value of -1 will be returned.
        !]]
        getHookCount = function(eEventID)
            local yID = subtype(eEventID);

            if (yID ~= "enumitem") then
                eventError("getHookCount", yID);
            end

            return tEvents[eEventID] ~= nil and #tEvents[eEventID].hookOrder or -1;
        end,


        --[[!
        @fqxn LuaEx.Libraries.eventrix.getHookOrdinal
        @desc
        Determines the ordinal number of the given hook, that is, in what fire position the hook exists. This is used primarily for determining to which function a returned error message belongs in the <a href="#LuaEx.Libraries.eventrix.fire">fire</a> method's return table. This is designed for security to prevent the <b>fire</b> method from needing to expose the hooks. The clinet with access to the hook can get its oridinal and use it for accessing the error message.
        @param enumitem eEventID The unique identifier for the event. This ID is used to retrieve the count of hooks tied to the event in question.
        @param function fHook The hook function being checked.
        @return number The number of hooks associated with the specified event.
        @ret number nHookOrdinal The ordinal value of the hook associated with the event. If the event or hook does not exist, a value of -1 will be returned.
        !]]
        getHookOrdinal = function(eEventID, fHook)
            local nRet = -1;
            local zHook = rawtype(fHook);
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("getHookOrdinal", yID);
            end

            if (zHook ~= "function") then
                hookError("getHookOrdinal", zHook);
            end

            if (tEvents[eEventID] ~= nil and tEvents[eEventID].hooks[fHook] ~= nil) then
                nRet = tEvents[eEventID].hookOrdinals[fHook];
            end

            return nRet;
        end,


        --[[!
        @fqxn LuaEx.Libraries.eventrix.eventExists
        @desc
        Checks whether an event with the specified ID is currently registered in the event system. This function is useful for determining if an event has been created before attempting to fire or manipulate it.
        @param enumitem eEventID The unique identifier for the event being checked. This ID must match an existing event in the system for the function to return true.
        @return boolean Returns true if the event exists; otherwise, returns false.
        !]]
        eventExists = function(eEventID)
            local yID = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("eventExists", yID);
            end

            return tEvents[eEventID] ~= nil;
        end,


        --[[!
        @fqxn LuaEx.Libraries.eventrix.fire
        @desc
        Triggers the execution of all registered hooks associated with the specified event ID. This method invokes each hook in the order they were registered, passing along any provided arguments. It handles the execution context and manages error handling for each hook, ensuring that an error in one hook does not prevent subsequent hooks from executing.
        @param enumitem eEventID The unique identifier for the event whose hooks are to be triggered. This ID must correspond to an existing event in the system.
        @param ... Any additional arguments that should be passed to the hooks when they are executed. These can be of any type and will be forwarded to each registered hook.
        @return table tVals A numerically-indexed table containing the results of each executed hook, where each entry corresponds to the return value of a hook. If an error occurs during the execution of a hook, an entry will contain an error message instead of the hook's return value.
        <br><b>Note</b>: if a function's return value is nil, the value listed in the table for that entry will be the constant, <b>EVENTRIX_NIL</b>.
        !]]
        fire = function(eEventID, ...)
            local tRet = {};
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("fire", yID);
            end

            if (tEvents[eEventID] ~= nil and tEvents[eEventID].isActive) then--fire only if the event exists and is active
                local tEvent    = tEvents[eEventID];
                local tHooks    = tEvent.hooks;

                for nIndex, fHook in ipairs(tEvent.hookOrder) do
                    local tHook = tHooks[fHook];

                    if (tHook.isActive) then --fire the hook only if it's active
                        bFired = true;
                        --localize the old environment
                        local tOldEnv = _ENV;
                        --localize pcall so it can be used
                        local pcall = pcall;
                        --set the new environment
                        _ENV = tHook.env;
                        --fire the event callback with any input args
                        local bSuccess, vMsgOrRet = pcall(fHook, ...);
                        --TODO log errors?

                        --record the return value
                        if (bSuccess and vMsgOrRet == nil) then
                            vMsgOrRet = EVENTRIX_NIL;
                        end

                        tRet[nIndex] = vMsgOrRet;

                        --reset the environment
                        _ENV = tOldEnv;
                    end

                end

            end

            return tRet;
        end,


        --[[!
        @fqxn LuaEx.Libraries.eventrix.isEventActive
        @desc
        Checks whether the specified event is currently active in the event system. An active event is one that has registered hooks and can be fired. This method allows for validation of event activity before attempting to trigger hooks associated with the event, helping to prevent unnecessary operations.
        @param enumitem eEventID The unique identifier for the event whose activity status is being checked. This ID must correspond to an existing event in the system.
        @return boolean Returns `true` if the event is active (i.e., it has one or more registered hooks); otherwise, returns `false`.
        !]]
        isEventActive = function(eEventID)
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("isEventActive", yID);
            end

            return tEvents[eEventID] ~= nil and tEvents[eEventID].isActive;
        end,


        --[[!
        @fqxn LuaEx.Libraries.eventrix.isHookActive
        @desc
        Checks whether a specific hook associated with an event is currently active in the event system. An active hook is one that has been registered to an event and can be triggered when the event is fired. This method allows for validation of a hook's status before attempting to invoke it, ensuring that only active hooks are executed.
        @param enumitem eEventID The unique identifier for the event to which the hook belongs. This ID must correspond to an existing event in the system.
        @param function fHook The hook function being checked.
        @return boolean Returns `true` if the specified hook is active; otherwise, returns `false`.
        !]]
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

        --[[!
        @fqxn LuaEx.Libraries.eventrix.removeEvent
        @desc Removes an event from the eventrix with the given event ID.
        @param enumitem eEventID The unique identifier for the event. This ID must correspond to an existing event in the system.
        @return eventrix kEventrix The eventrix object.
        !]]
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

        --[[!
        @fqxn LuaEx.Libraries.eventrix.removeHook
        @desc Removes a hook from an event.
        @param enumitem eEventID The unique identifier for the event to which the hook belongs. This ID must correspond to an existing event in the system.
        @param function fHook The hook to be removed.
        @return eventrix kEventrix The eventrix object.
        !]]
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

                    --reset the ordinal values of the hooks
                    tEvent.hookOrdinals = {}; --NOTE: can't use shortcut syntax for table reference, leave this as-is
                    for nIndex, fExistingHook in ipairs(tHookOrder) do
                        tEvent.hookOrdinals[fExistingHook] = nIndex;
                    end

                end

            end

            return tEventrixDecoy;
        end,

        --[[!
        @fqxn LuaEx.Libraries.eventrix.setEventActive
        @desc Sets an event active/inactive.
        @param enumitem eEventID The unique identifier for the event. This ID must correspond to an existing event in the system.
        @param boolean|nil bActive A boolean (or nil) indicating whether to set the event active. If nil, the event will be deactivated.
        @return eventrix kEventrix The eventrix object.
        !]]
        setEventActive = function(eEventID, bFlag)
            local yID   = subtype(eEventID);

            if not (yID == "enumitem") then
                eventError("setEventActive", yID);
            end

            if (tEvents[eEventID] ~= nil) then
                tEvents[eEventID].isActive = rawtype(bFlag) == "boolean" and bFlag or false;
            end

            return tEventrixDecoy;
        end,

        --[[!
        @fqxn LuaEx.Libraries.eventrix.setHookActive
        @desc Sets an event's hook activate/inactive.
        @param enumitem eEventID The unique identifier for the event to which the hook belongs. This ID must correspond to an existing event in the system.
        @param function fHook The hook function activate/deactivate.
        @param boolean|nil bActive A boolean (or nil) indicating whether to set the hook active. If nil, the hook will be deactivated.
        @return eventrix kEventrix The eventrix object.
        !]]
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
    --[[!
    @fqxn LuaEx.Libraries.eventrix.eventrix
    @desc
    <h3>Function: eventrix(sEnv)</h3>
    This is the main constructor for the eventrix system. It initializes and configures the event management system based on the provided environment as an entrix can function in different environments.
    @param string|nil sEnv The name of the environment in which the event system operates. If provided, it customizes the behavior and scope of the event handling to fit the specific needs of the given environment (e.g., global or local scope). If not provided, the default environment will be used.
    !]]
    __call = function(t, ...)
        return eventrix(...);
    end,
    __index = function(t, k)
        return tEventrix[k] or nil;
    end,
    __newindex = function(t, k, v) end,
    __type = "eventrixfactory",
};
setmetatable(tEventrixFactoryDecoy, tEventrixFactoryMeta);

return tEventrixFactoryDecoy;
