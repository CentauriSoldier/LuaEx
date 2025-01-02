--TODO NOTE: if classes getting BP info is slow, have them cache the calls

-- Pattern explanation:
-- ^        : start of the string
-- %u%u%u  : exactly three uppercase letters (XXX)
-- %-       : literal dash (-)
-- %u%u%u  : exactly three uppercase letters (XXX)
-- %-       : literal dash (-)
-- %x%x%x%x : exactly four hexadecimal digits (DDDD)
-- $        : end of the string
local _sIDFormat        = "^%u%u%u%-%u%u%u%-%x%x%x%x$";
local _nMaxIDs          = 20316036096000;--WARNING: CHANGE (ONLY) IF YOU ALSO CHANGE THE ID FORMAT AND LENGTH
local _tIDCheckCache    = {};
local _fIDSchema        = schema.pattern(_sIDFormat);
local _tSchemata        = {
    --[[each entry is:
    [cClass] = {
        blueprints      = <table>,
        blueprintsByID  = <table>,
        factory         = <function>
        schema          = <function>
    },
    --]]
};

local _tBlueprints = {}; --tracks which classes and blueprints belong to which IDs for fast lookup

local function addBlueprint(cChild, sID, tBP)
    local sMessage;
    local bRet      = false;
    local bIsChild  = class.is(cChild) and class.ischild(cChild, CoG);

    if (bIsChild and _tSchemata[cChild] ~= nil) then
        local tSchema   = _tSchemata[cChild];
        local tBPsByID  = tSchema.blueprintsByID;
        local tBPs      = tSchema.blueprints;

        --TODO ID check and type errors
        if (type(sID) == "string" and sID:match(_sIDFormat) and type(tBP) == "table") then
            local sError = schema.checkSchema(tBP, tSchema.schema);

            if (sError) then --TODO FIX change error messages when class helper functions are updated
                sMessage = "Error adding blueprint to class, '"..class.name(class.of(this)).."'."..sError;
            else

                if (tBPsByID[sID] ~= nil) then
                    --clone and store the blueprint
                    local bRet      = true;
                    local tBPCloned = clone(tBP);
                    tBPsByID[sID]   = tBPCloned;
                    tBPs[#tBPs + 1] = tBPCloned;

                    --create an entry in the _tBlueprints quick-lookup table
                    _tBlueprints[sID] = {
                        class       = cChild,
                        blueprint   = tBPCloned,
                        factory     = tSchema.factory,
                    };
                else
                    --sMessage TODO
                end

            end

        end

    else
        --sMessage TODO
    end

    return bRet, sMessage;
end

local function idIsValid(vID)
    local bRet = false;

    if (_tIDCheckCache[vID] ~= nil) then
        bRet = _tIDCheckCache[vID];
    else
        local zID = type(vID);

        if (zID ~= "nil") then

            if (zID == "string" and vID:match(_sIDFormat)) then
                bRet = true;
                _tIDCheckCache[vID] = bRet;
            end

        end

    end

    return bRet;
end




return class("CoG",
{},--METAMETHODS
{--STATIC PUBLIC
    --CoG = function(stapub) end,
    SCHEMA_ID = _fIDSchema,
    addBlueprint = addBlueprint,
    fromBlueprint = function(sID, ...)
        local oRet;

        --if the blueprint exists...
        if (_tBlueprints[sID] ~= nil) then
            local tBPData = _tBlueprints[sID];
            --...run the factory method and return the created object
            oRet = tBPData.factory(clone(tBPData.blueprint), ...);

            --check that the object actually got created --TODO FIX update message after class helper functions updated
            if not (class.of(oRet) == tBPData.class) then
                --TODO THROW ERROR
            end

        else
            --TODO ...throw an error
        end

        return oRet;
    end,
    getBlueprintIDs = function(cClass)
        local tRet;

        if (_tSchemata[cClass] ~= nil) then
            tRet = {};

            for sID, tBP in pairs(_tSchemata[cClass]) do
                tRet[#tRet + 1] = sID;
            end

        end

        return tRet;
    end,
    --getBlueprint = function(this, cdat, sID)
--        return cdat.pri.blueprintsByID[sID] or nil;
--    end,
    registerBlueprintable = function(cChild, sAuthCode, fSchema, fFromBlueprint, tBlueprints)
        local bIsChild              = class.is(cChild) and class.ischild(cChild, CoG);
        print(class.is(cChild))
        print(class.ischild(cChild, CoG))
        local bAuthorized           = class.isstaticconstructorrunning(cChild, sAuthCode);
        local bIsBlueprintfunction  = type(fFromBlueprint) == "function";
        local bIsSchemaFunction     = type(fSchema) == "function";
        local bNoSchemaExists       = _tSchemata[cChild] == nil;
        local bIsPublic             = true;     --TODO FINISH use this when function is complete class.getconstructorvisibility() == "public"; Actually, dop't use this but do add that class helper function
        local bRet = false;
        local sMessage;
                                                --TODO raise errros on bad input
        if (bIsChild and bAuthorized and bIsBlueprintfunction and
            bIsSchemaFunction and bNoSchemaExists) then
            bRet = true;

            --create the schema info table
            _tSchemata[cChild] = {
                blueprints      = {},
                blueprintsByID  = {},
                factory         = fFromBlueprint,
                schema          = fSchema,
            };

            --create an entry for the ID Bank
            _tBlueprints[cChild] = {};

            if (type(tBlueprints) == "table") then

                for _, tPotentialBPInfo in pairs(tBlueprints) do

                    if (type(tPotentialBPInfo) == "table") then
                        local bSuccess, sError = addBlueprint(cChild, tPotentialBPInfo.id, tPotentialBPInfo.bp);

                        if not (bSuccess) then
                            sMessage = (sMessage or "")..sError.."\r\n";
                        end

                    end

                end

            else
                sMessage = "Error adding blueprint. Blueprint must be of type table. Type given: "..type(tBlueprints)..'.';

            end

        else
            sMessage = "Is CoG child class: "..tostring(bIsChild).."\n";
            sMessage = sMessage.."Is called from class static constructor: "..tostring(bAuthorized).."\n";
            sMessage = sMessage.."Has 'fromBlueprint' method: "..tostring(bIsBlueprintfunction).."\n";
            sMessage = sMessage.."Has schema function : "..tostring(bIsSchemaFunction).."\n";
            sMessage = sMessage.."Schema does not exist: "..tostring(bNoSchemaExists).."\n";
        end

    return bRet, sMessage;
    end,
},
{},--PRIVATE
{--PROTECTED
    CoG = function(this, cdat)
        print(class.of(this))
    end,
},
{--PUBLIC
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
