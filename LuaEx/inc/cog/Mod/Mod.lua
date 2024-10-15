local pairs     = pairs;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local tonumber  = tonumber;
local type      = type;

local _nMaxVersion = 999;

return class("Mod",
{--METAMETHODS

},
{--STATIC PUBLIC
    MAX_VERSION_RO = _nMaxVersion,
    --Mod = function(stapub) end,
    isDateValid = function(sInput)
        -- Date pattern matching YYYY-MM-DD format
        local sPattern = "^%d%d%d%d%-%d%d%-%d%d$"

        -- Check if the input matches the pattern
        if not sInput:match(sPattern) then
            return false
        end

        -- Extract the year, month, and day from the input
        local year, month, day = sInput:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

        -- Convert to numbers for further validation
        year, month, day = tonumber(year), tonumber(month), tonumber(day)

        -- Check for valid month and day ranges
        if month < 1 or month > 12 then
            return false
        end

        -- Days in each month (not accounting for leap years yet)
        local daysInMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

        -- Adjust for leap year
        if month == 2 and (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) then
            daysInMonth[2] = 29
        end

        -- Check if the day is valid for the given month
        if day < 1 or day > daysInMonth[month] then
            return false
        end

        -- If all checks passed, the date is valid
        return true
    end,
},
{--PRIVATE
    Active__auto_Fis    = false,
    authors             = {},
    Contact__autoRF     = null,
    Description__autoRF = null,
    ID__autoRF          = null,
    Name__autoRF        = null,
    Path__autoAA        = "",
    required            = {},
    Released__autoRF    = null,
    Updated__autoRF     = null,
    Version__autoRF     = null,
    Website__autoRF     = null,
},
{},--PROTECTED
{--PUBLIC
    Mod = function(this, cdat, pFolder, tModInfo)
        local pri = cdat.pri

        local tAuthors      = tModInfo.authors;
        local sContact      = tModInfo.contact;
        local sDescription  = tModInfo.description;
        local sID           = tModInfo.id;
        local sName         = tModInfo.name;
        local tRequired     = tModInfo.required;
        local sReleased     = tModInfo.released;
        local sUpdated      = tModInfo.udpated;
        local nVersion      = tModInfo.version;
        local sWebsite      = tModInfo.website;

        --name
        type.assert.string(sName, "%S+", "Error importing mod in folder, '"..tostring(pFolder).."': invalid mod name.");--TODO message
        pri.Name = sName;

        --author(s)
        type.assert.table(tAuthors, "number", "string", 1);
        for _, sAuthor in pairs(tAuthors) do

            if not (sAuthor:find("%S+")) then
                error("Error importing mod, '"..sName.."': invalid author name.");
            end

            pri.authors[#pri.authors + 1] = sAuthor;
        end

        --contact
        sContact = rawtype(sContact) == "string" and sContact or "";
        pri.Contact = sContact;

        --description
        type.assert.string(sDescription, "%S+", "Error importing mod, '"..sName.."': invalid description.");--TODO message
        pri.Description = sDescription;

        --uuid
        assert(rawtype(sID) == "string" and sID:isuuid(), "Error importing mod, '"..sName.."': invalid UUID.");
        pri.ID = sID;

        --required mods
        if (rawtype(tRequired) == "table") then

            for _, sRequiredID in pairs(tRequired) do

                if (rawtype(sRequiredID) == "string" and sRequiredID:isuuid()) then
                    pri.required[sRequiredID] = true;
                end

            end

        end

        --mod path
        pri.Path = pFolder;

        --released
        if not (rawtype(sReleased) == "string" and Mod.isDateValid(sReleased)) then
            error("Error importing mod, '"..sName.."': invalid release date. Date must be a string in the following format: YYYY-MM-DD");
        end
        pri.Released = sReleased;

        --updated
        if not (rawtype(sUpdated) == "string" and Mod.isDateValid(sUpdated)) then
            error("Error importing mod, '"..sName.."': invalid release date. Date must be a string in the following format: YYYY-MM-DD");
        end
        pri.Updated = sUpdated;

        --version
        type.assert.number(nVersion, true, true, false, false, false, 0.01, _nMaxVersion);
        pri.Version = nVersion;

        --website
        pri.Website = (rawtype(sWebsite) == "string" and sWebsite:find("%S+")) and sWebsite or '';









    end,
    eachAuthor = function(this, cdat)
        return next, cdat.pri.author, nil;
    end,
    eachRequired = function(this, cdat)
        return next, cdat.pri.required, nil;
    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
