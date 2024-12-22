local class     = class;
local enum      = enum;
local type      = type;

local function writeToFile(this, cdat, tEntry)
    local pro = cdat.pro;
    local hFile = io.open(pro.path, "a")

    if hFile then
        --hFile:write(pro.dateTimeFunction()..' ['..tostring(tEntry.level).."]-> "..tEntry.message.."\n");
        hFile:write(tEntry.datetime..'['..tostring(tEntry.level).."] "..tEntry.message.."\n");
        hFile:close();
    end

end

--[[!
@fqxn LuaEx.Classes.BaseLog.Enums.LEVEL
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
local eLevels   = enum("BaseLog.LEVEL", {"CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG", "TRACE",}, nil, true);

local function createNewEntryTable()
    return {
        datetime            = "",
        hasBeenCommitted    = false, --track which entries have been written to file
        level               = eLevels.INFO,
        message             = "",
    };
end

--[[!
@fqxn LuaEx.Classes.BaseLog
@desc A basic log class that tracks user-defined events.
!]]
return class("BaseLog",
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
    path                        = "",
    AutoWrite__auto__           = false,
    dateTimeFunction            = null,
    Level__auto_F               = eLevels.INFO;
},
{--PUBLIC
    --[[!
    @fqxn LuaEx.Classes.BaseLog.BaseLog
    @desc The constructor for the log class.
    @param string pFile The path to the log file (or where it should be created).
    @param boolean|nil bDoNotAutoWrite If set to true, it prevents autowriting to file. This can be changed at anytime by setting the autowrite value.
    !]]
    BaseLog = function(this, cdat, pFile, hDateTime, bDoNotAutoWrite)
        local pro = cdat.pro;
        type.assert.string(pFile, "%S+");
        type.assert["function"](hDateTime);

        -- Open the file in append mode
        local hFile = io.open(pFile, "a")

        -- Check if the file was successfully opened
        if not (hFile) then
            error("Error createing BaseLog instance. Path is invalid or file could not be opened.");
            hFile:close();
            --TODO auto import old from file...?
        end

        pro.AutoWrite        = not (rawtype(bDoNotAutoWrite) == "boolean" and bDoNotAutoWrite or false);
        pro.dateTimeFunction = hDateTime;
        pro.path             = pFile;

        local tEntries = cdat.pro.entries;

        --create the log entires table
        for nIndex, eLevel in eLevels() do
            tEntries[eLevel] = {};
        end

    end,

--TODO FINISH clear (memory) and purge(file) methods

    --[[!
    @fqxn LuaEx.Classes.BaseLog.getLogLevel
    @desc Returns the current <a href="#LuaEx.Classes.BaseLog.Enums.LEVEL">BaseLog.LEVEL</a> that's used by default.
    @ret Log.LEVEL eLevel The current <a href="#LuaEx.Classes.BaseLog.Enums.LEVEL">Log.LEVEL</a>.
    !]]


    --[[!
    @fqxn LuaEx.Classes.BaseLog.log
    @desc Creates a log entry and writes it to file (if autowrite is true).
    @param string sMessage The message of the log entry.
    @param Log.LEVEL|nil eLevel The <a href="#LuaEx.Classes.BaseLog.Enums.LEVEL">Log.LEVEL</a> enum item to use for the entry. If nil, it will use the current <a href="#LuaEx.Classes.BaseLog.Enums.LEVEL">Log.LEVEL</a>.
    !]]
    log = function(this, cdat, sMessage, eLevel)
        local pro = cdat.pro;
        eLevel = type(eLevel) == "BaseLog.LEVEL" and eLevel or pro.Level;
        type.assert.string(sMessage, "%S+");

        local tEntries = pro.entries;

        local tEntry = {
            datetime            = pro.dateTimeFunction(),
            hasBeenCommitted    = false, --track which entries have been written to file
            level               = eLevel,
            message             = sMessage,
        };

        tEntries[eLevel][#tEntries + 1] = tEntry;

        if (pro.AutoWrite) then
            writeToFile(this, cdat, tEntry);
        end

    end,

    purge = function(this, cdat)
        local pro = cdat.pro;
        local hFile = io.open(pro.path, "w");

        if hFile then
            hFile:write('');
            hFile:close();
        end

    end,

    --[[!
    @fqxn LuaEx.Classes.BaseLog.setLogLevel
    @desc Sets the current <a href="#LuaEx.Classes.BaseLog.Enums.LEVEL">Log.LEVEL</a> that's used by default.
    @param Log.LEVEL eLevel The <a href="#LuaEx.Classes.BaseLog.Enums.LEVEL">Log.LEVEL</a> to set as current.
    !]]
    writeToFile = function(this, cdat)
        --TODO FINISH
    end,
},
nil,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
