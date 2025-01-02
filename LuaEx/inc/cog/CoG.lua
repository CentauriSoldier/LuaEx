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
local _fIDSchema = schema.pattern(_sIDFormat);
local _tSchemata        = {};

local function addBlueprint(cChild, sID, tBP)
    local sMessage;
    local bRet      = false;
    local pri       = cdat.pri;
    local tBPsByID  = pri.blueprintsByID;
    local bIsChild  = class.is(cChild) and class.ischild(cChild, CoG);

    --TODO ID check and type errors
    if (type(sID) == "string" and type(tBP) == "table") then
        local sError = schema.checkSchema(tBP, cdat.pri.schema);

        if (sError) then
            sMessage = "Error adding blueprint to class, '"..class.name(class.of(this)).."'."..sError;
        else

            if (tBPsByID[sID] ~= nil) then
                local bRet = true;
                local tBPCloned = clone(tBP);
                tBPsByID[sID] = tBPCloned;
                blueprints[#blueprints + 1] = tBPCloned;
            else
                --sMessage TODO
            end

        end

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
{--METAMETHODS
},
{--STATIC PUBLIC
    --CoG = function(stapub) end,
    SCHEMA_ID = _fIDSchema,
    addBlueprint = addBlueprint,
    fromBlueprint = function()
        --TODO call class's from BP function here
    end,
    --getBlueprint = function(this, cdat, sID)
--        return cdat.pri.blueprintsByID[sID] or nil;
--    end,
    registerBlueprintable = function(cChild, sAuthCode, fSchema, fFromBlueprint, tBlueprints)
        local bIsChild              = class.is(cChild) and class.ischild(cChild, CoG);
        local bAuthorized           = class.isstaticconstructorrunning(cChild, sAuthCode);
        local bIsBlueprintfunction  = type(fFromBlueprint) == "function";
        local bIsSchemaFunction     = type(fSchema) == "function";
        local bNoSchemaExists       = _tSchemata[cChild] == nil;
        local bIsPublic             = true;     --TODO FINISH use this when function is complete class.getconstructorvisibility() == "public";
                                                --TODO raise errros on bad input
        if (bIsChild and bAuthorized and bIsPublic and
            bIsBlueprintfunction and bIsSchemaFunction and
            bNoSchemaExists) then
        
            _tSchemata[cChild] = {
                blueprints      = {},
                blueprintsByID  = {},
                schema          = fSchema,
            };

            --tBlueprints TODO LEFT OFF HERE
        end

    end,
},
{--PRIVATE
    blueprints      = {},
    blueprintsByID  = {},
    schema          = {}, --default until a schema functon is set
},
{--PROTECTED
    --[[getSchema = function(this, cdat)
        return cdat.pri.schema;
    end,]]
    CoG = function(this, cdat)
        print(class.of(this))
    end,
},
{--PUBLIC
    blueprintIdIsValid = idIsValid,
    fromBlueprint = function(this, cdat, sID)--TODO
        local pro = cdat.pro;
    end,
    removeBlueprint__FNL = function(this, cdat, sID)--TODO

    end,
    getBlueprintium = function(this, cdat) --TODO move to pro after testing.
        return cdat.pri.blueprintium;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
