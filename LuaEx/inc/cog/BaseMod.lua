local pairs     = pairs;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local tonumber  = tonumber;
local type      = type;

--TODO implement optional strictMode which will throw and error on mod UUID duplicate.

local _                 = package.config:sub(1, 1);
local _sNot_            = _ == "\\" and "/" or "\\";
local _sInfoFilename    = luaex.cog.config.BaseMod.infoFilename;

--contains all mods in the game and is populated when a mod is created
local _tMods        = {};
local _tModsByID    = {};
local _tModIndices  = {}; --indexed by UUID, values are the mod's numeric index in the _tMods table (stored for mod overwrite scenarios)
local _nMaxVersion = 999;

return class("BaseMod",
{--METAMETHODS
    __pairs = function()
        return next, _tMods, nil;
    end,
},
{--STATIC PUBLIC
    MAX_VERSION_RO = _nMaxVersion,
    --BaseMod = function(stapub) end,
    eachMod = function() --same as __pairs (5.1 compat)
        return next, _tMods, nil;
    end,
    getByID = function(sID)
        type.assert.string(sID, "%S+");

        if (_tModsByID[sID] == nil) then
            error("Error getting mod, '${id}'. Mod does not exist" % {id = sID});
        end

        return _tModsByID[sID];
    end,
},
{--PRIVATE
},
{
    Active__auto_Fis    = false,
    authors             = {},
    Contact__autoRF     = null,
    Description__autoRF = null,
    ID__autoRF          = null,
    Name__autoRF        = null,
    Path__autoAA        = "",
    required            = {},
    Released__autoRF    = null,
    --TODO add tags system
    Updated__autoRF     = null,
    Version__autoRF     = null,
    Website__autoRF     = null,

    BaseMod = function(this, cdat, pFolder)
        local pro = cdat.pro
        type.assert.string(pFolder, "%S+", "Error importing mod. Directory must be a valid string.");

        --create the mod info file path
        local pModInfo = (pFolder.._.._sInfoFilename):gsub(_sNot_, _):gsub(_.._, _);
        --attempt opening the mod info file
        local hModInfo = io.open(pModInfo, "r");

        --throw an error if the mod info file is not found or could not be opened
        if not (hModInfo) then
            error("Error importing mod in directory, '"..pFolder.."'. Mod info file not found.");
        end

        --read the data to string and close the file
        local sModInfo = hModInfo:read("*all");
        hModInfo:close();

        --create the mod info loading function
        local fModInfo, sLoadError = load(sModInfo, "ModInfoChunk ("..pFolder..")");
        if not (fModInfo) then
            error("Error importing mod in directory, '"..pFolder.."'. : "..sLoadError);
        end

        --create a safe env to load the modinfo
        local wOld = _ENV;
        local pcall = pcall;
        _ENV = {error = error};--QUESTION do I need more things in here like tonumber, tostring, etc.?

        --attempt to load the mod info
        local bSuccess, vModInfoOrError = pcall(fModInfo);

        -- Restore the original environment
        _ENV = wOld;

        --look for errors in the mod info
        if not (bSuccess) then
            error("Error importing mod in directory, '"..pFolder.."'. : "..vModInfoOrError);
        end

        --shorten the name for readability
        local tModInfo = vModInfoOrError;

        local tAuthors      = tModInfo.authors;
        local sContact      = tModInfo.contact;
        local sDescription  = tModInfo.description;
        local sID           = tModInfo.id;
        local sName         = tModInfo.name;
        local tRequired     = tModInfo.required;
        local sReleased     = tModInfo.released;
        local sUpdated      = tModInfo.updated;
        local nVersion      = tModInfo.version;
        local sWebsite      = tModInfo.website;

        --name
        type.assert.string(sName, "%S+", "Error importing mod in folder, '"..tostring(pFolder).."': invalid mod name.");--TODO message
        pro.Name = sName;

        --author(s)
        type.assert.table(tAuthors, "number", "string", 1);
        for _, sAuthor in pairs(tAuthors) do

            if not (sAuthor:find("%S+")) then
                error("Error importing mod, '"..sName.."': invalid author name.");
            end

            pro.authors[#pro.authors + 1] = sAuthor;
        end

        --contact
        sContact = rawtype(sContact) == "string" and sContact or "";
        pro.Contact = sContact;

        --description
        type.assert.string(sDescription, "%S+", "Error importing mod, '"..sName.."': invalid description.");--TODO message
        pro.Description = sDescription;

        --uuid
        assert(rawtype(sID) == "string" and sID:isuuid(), "Error importing mod, '"..sName.."': invalid UUID ("..sID..").");
        pro.ID = sID:lower();
        local nModIndex = #_tMods + 1; --track this index in case of overwrites (due to duplicate UUIDs)

        --check for existing UUID
        if (_tModsByID[pro.ID]) then
            --if the UUID exists, overwrite the existing mod and log it
            nModIndex = _tModIndices[pro.ID];

            --TODO FINISH Log duplicate UUIDs
        end


        --required mods
        if (rawtype(tRequired) == "table") then

            for _, sRequiredID in pairs(tRequired) do

                if (rawtype(sRequiredID) == "string" and sRequiredID:isuuid()) then
                    pro.required[sRequiredID] = true;
                end

            end

        end

        --mod path
        pro.Path = pFolder;

        --released
        if not (rawtype(sReleased) == "string" and sReleased:isdatevalid()) then
            error("Error importing mod, '"..sName.."': invalid release date. Date must be a string in the following format: YYYY-MM-DD");
        end
        pro.Released = sReleased;

        --updated
        if not (rawtype(sUpdated) == "string" and sUpdated:isdatevalid()) then
            error("Error importing mod, '"..sName.."': invalid updated date. Date must be a string in the following format: YYYY-MM-DD");
        end
        pro.Updated = sUpdated;

        --version
        type.assert.number(nVersion, true, true, false, false, false, 0.01, _nMaxVersion);
        pro.Version = nVersion;

        --website
        pro.Website = (rawtype(sWebsite) == "string" and sWebsite:find("%S+")) and sWebsite or '';

        --register the mod
        _tMods[nModIndex]       = this;
        _tModsByID[pro.ID]      = this;
        _tModIndices[pro.ID]    = nModIndex;
    end,

},--PROTECTED
{--PUBLIC
    activate = function(this, cdat)
        local pro = cdat.pro;
        local sDisplay = "'"..pro.Name.."' ("..pro.ID..")";
        error("Error activating Mod, "..sDisplay..". The activate method has not been implemented in the child class.");
    end,
    eachAuthor__FNL = function(this, cdat)
        return next, cdat.pro.authors, nil;
    end,
    eachRequired__FNL = function(this, cdat)
        return next, cdat.pro.required, nil;
    end,
    deactivate = function(this, cdat)
        local pro = cdat.pro;
        local sDisplay = "'"..pro.Name.."' ("..pro.ID..")";
        error("Error deactivating Mod, "..sDisplay..". The deactivate method has not been implemented in the child class.");
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
