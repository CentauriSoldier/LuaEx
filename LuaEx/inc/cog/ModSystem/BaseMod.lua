local class     = class;
local pairs     = pairs;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local tonumber  = tonumber;
local type      = type;

local _sDefaultModID    = "27a27ca4-5f85-48ea-a30d-e6ad95d89d84"; --WARNING: NEVER CHANGE THIS VALUE!
local _nMaxVersion      = 999;
--[[!
    @fqxn CoG.ModSystem.BaseMod
    @des BaseMod is designed to contain basic information on game mods. In addition, it is meant to be extended (having a protected constructor) by a custom Mod class which handles the more specific details of your game's Mods.
!]]
return class("BaseMod",
{}, --METAMETHODS
{   --STATIC PUBLIC
    DEFAULT_MOD_ID__RO   = _sDefaultModID,
    MAX_VERSION__RO      = _nMaxVersion,
},
{   --PRIVATE
},
{   --PROTECTED
    Active__auto_Fis    = false,
    authors             = {},
    blueprints          = {},
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

    BaseMod = function(this, cdat, tModInfo)
        local pro = cdat.pro

        if (type(tModInfo) == "table") then
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
            assert(rawtype(sID) == "string" and sID:isuuid(), "Error importing mod, '"..sName.."': invalid UUID. UUID must be string matching pattern: "..string.patterns.uuid..'.');
            pro.ID = sID:lower();

            --required mods
            if (rawtype(tRequired) == "table") then

                for _, sRequiredID in pairs(tRequired) do

                    if (rawtype(sRequiredID) == "string" and sRequiredID:isuuid()) then
                        pro.required[sRequiredID] = true;
                    end

                end

            end

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
        end

    end,

},
{--PUBLIC
    activate = function(this, cdat)
        local pro = cdat.pro;
        local sDisplay = "'"..pro.Name.."' ("..pro.ID..")";
        error("Error activating Mod, "..sDisplay..". The activate method has not been implemented in the child class.");
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
