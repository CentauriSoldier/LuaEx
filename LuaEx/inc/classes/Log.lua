local class     = class;
local enum      = enum;
local type      = type;

--[[!
@fqxn LuaEx.Classes.Log.Enums.LEVEL
@desc The error level enum used to define an event's level.
<ol>
    <li>CRITICAL</li>
    <li>ERROR</li>
    <li>WARNING</li>
    <li>INFO</li>
    <li>DEBUG</li>
    <li>TRACE</li>
</ol>
!]]
local eLevels   = enum("Log.LEVEL", {"CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG", "TRACE",}, nil, true);
local eLogLevel = Log.LEVEL;

local function createNewEntryTable()
    return {
        datetime    = "",
        level       = eLogLevel.INFO,
        message     = "",
    };
end

local function placeholder() end


--[[!
@fqxn LuaEx.Classes.Log
@desc A basic log class that tracks user-defined events.
!]]
return class("Log",
{--METAMETHODS

},
{--STATIC PUBLIC
    LEVEL = eLevels,
    --Log = function(stapub) end,
},
{--PRIVATE
},
{--PROTECTED
    entries                     = null,
    Level__auto_F               = eLogLevel.INFO;    
    Path__auto__                = "",
    DateTimeFunction__auto_F    = placeholder,
},
{--PUBLIC
    --[[!
    @fqxn LuaEx.Classes.Log.Log
    @desc The constructor for the log class.
    !]]
    Log = function(this, cdat)
        local tEntries = cdat.pro.entries;

        --create the log entires table
        for nIndex, eLevel in eLevels() do
            tEntries[eLevel] = {};
        end

    end,


    --[[!
    @fqxn LuaEx.Classes.Log.getLogLevel
    @desc Returns the current <a href="#LuaEx.Classes.Log.Enums.LEVEL">Log.LEVEL</a> that's used by default.
    @ret Log.LEVEL eLevel The current <a href="#LuaEx.Classes.Log.Enums.LEVEL">Log.LEVEL</a>.
    !]]


    --[[!
    @fqxn LuaEx.Classes.Log.log
    @desc Creates a log entry.
    @param string sMessage The message of the log entry.
    @param Log.LEVEL|nil eLevel The <a href="#LuaEx.Classes.Log.Enums.LEVEL">Log.LEVEL</a> enum item to use for the entry. If nil, it will use the current <a href="#LuaEx.Classes.Log.Enums.LEVEL">Log.LEVEL</a>.
    !]]
    log = function(this, cdat, sMessage, eLevel)
        type.assert.string(sMessage, "%S+");
        local pro = cdat.pro;

        pro.entries[eLevel][#entries + 1] = {
            datetime    = pro.DateTimeFunction(),
            level       = type(eLevel) == "Log.LEVEL" and eLevel or pro.Level,
            message     = sMessage,
        };
    end,

    --[[!
    @fqxn LuaEx.Classes.Log.setLogLevel
    @desc Sets the current <a href="#LuaEx.Classes.Log.Enums.LEVEL">Log.LEVEL</a> that's used by default.
    @param Log.LEVEL eLevel The <a href="#LuaEx.Classes.Log.Enums.LEVEL">Log.LEVEL</a> to set as current.
    !]]


    writeToFile = function(this, cdat)

    end,
},
nil,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
