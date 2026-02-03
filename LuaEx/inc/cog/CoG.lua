--TOOD clean this up and put function in teh proper modules.

-- Internal: leap year check
local function IsLeapYear(nYear)
    if (type(nYear) ~= "number") then return nil, "Invalid year" end
    return (nYear % 4 == 0 and nYear % 100 ~= 0) or (nYear % 400 == 0)
end

-- Internal: day-of-year
local function GetDayOfYear(nYear, nMonth, nDay)
    if type(nYear) ~= "number"
    or type(nMonth) ~= "number"
    or type(nDay) ~= "number" then
        return nil, "Invalid date components"
    end

    local bLeap, err = IsLeapYear(nYear)
    if bLeap == nil then return nil, err end

    local tDaysInMonth = {
        31,
        bLeap and 29 or 28,
        31, 30, 31, 30,
        31, 31, 30, 31, 30, 31
    }

    if nMonth < 1 or nMonth > 12 then
        return nil, "Invalid month"
    end

    if nDay < 1 or nDay > tDaysInMonth[nMonth] then
        return nil, "Invalid day"
    end

    local nTotal = nDay
    for m = 1, nMonth - 1 do
        nTotal = nTotal + tDaysInMonth[m]
    end

    return nTotal
end

-- Public: BuildVersionID
BuildVersionID = function(vPrefix, vSuffix)
    local tNow = os.date("*t")
    if type(tNow) ~= "table" then
        error("Failed to retrieve system time", 2)
    end

    local nYear  = tNow.year
    local nMonth = tNow.month
    local nDay   = tNow.day
    local nHour  = tNow.hour

    local nDOY, err = GetDayOfYear(nYear, nMonth, nDay)
    if not nDOY then
        error("BuildVersionID failed: "..err, 2)
    end

    local sPrefix = type(vPrefix) == "string" and vPrefix or "";
    local sSuffix = type(vSuffix) == "string" and vSuffix or "";

    return sPrefix..string.format("%d.%d.%02d", nYear, nDOY, nHour)..sSuffix;
end

local function VersionIDIsNewer(vID1, vID2)
    local sID1  = vID1:gsub('%.', '')
    local sID2  = vID2:gsub('%.', '')
    local nID1  = tonumber(sID1);
    local nID2  = tonumber(sID2);

    return nID1 > nID2;
end

local function VersionIDIsOlder(vID1, vID2)
    local sID1  = vID1:gsub('%.', '')
    local sID2  = vID2:gsub('%.', '')
    local nID1  = tonumber(sID1);
    local nID2  = tonumber(sID2);

    return nID1 < nID2;
end

local function VersionIDIsSame(vID1, vID2)
    local sID1  = vID1:gsub('%.', '')
    local sID2  = vID2:gsub('%.', '')
    local nID1  = tonumber(sID1);
    local nID2  = tonumber(sID2);

    return nID1 == nID2;
end

--[[
local cUtil = class("Util",
    {--METAMETHODS

    },
    {--STATIC PUBLIC
        --__INIT = function(stapub) end, --static initializer (runs before class object creation)
        --Util = function(this, sAuthCode) end, --static constructor (runs after class object creation)
        BuildVersionID = BuildVersionID,
    },
    {--PRIVATE
        Util = function(this, cdat) end,
    },
    {},--PROTECTED
    {--PUBLIC
        --Date =
    },
    CoG,   --extending class
    true,  --if the class is final
    nil    --interface(s) (either nil, or interface(s))
);]]





return class("CoG",
{},--METAMETHODS
{--STATIC PUBLIC
    --CoG = function(stapub) end,

    --getBlueprint = function(this, cdat, sID)
--        return cdat.pri.blueprintsByID[sID] or nil;
--    end,
    BuildVersionID      = BuildVersionID,
    VersionIDIsNewer    = VersionIDIsNewer,
    VersionIDIsOlder    = VersionIDIsOlder,
    VersionIDIsSame     = VersionIDIsSame,
},
{},--PRIVATE
{--PROTECTED
    CoG = function(this, cdat)
        --print(class.of(this))
    end,
},
{--PUBLIC
    --Util =
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
