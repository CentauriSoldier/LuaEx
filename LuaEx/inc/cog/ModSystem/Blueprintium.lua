
--TODO NOTE: if classes getting BP info is slow, have them cache the calls

-- Pattern explanation:
-- ^        : start of the string
-- %u%u%u  : exactly three uppercase letters (XXX)
-- %-       : literal dash (-)
-- %u%u%u  : exactly three uppercase letters (XXX)
-- %-       : literal dash (-)
-- %x%x%x%x : exactly four hexadecimal digits (DDDD)
-- $        : end of the string
local _tIDCheckCache    = {};
local _nMaxIDs          = 65535; --WARNING: DO NOT CHANGE UNLESS YOU ALSO CHANGE THE ID FORMAT AND LENGTH
local _sIDFormat        = "^%u%u%u%-%u%u%u%-%x%x%x%x$";
local _tIDBank          = {
    --byClass     = {},
    --byString    = {},
};

local _tBPMasterSchema = {
    forbidden = {
        class = true,
    },
    permitted = {},
    required = {
        id   = {"string"},
        name = {"string"},
    },
};

local function placeholder() end

--TODO add messages when failures occur so the user knows what went wrong.


--TODO FINISH this needs to check for conflicts between the various tables (e.g., id as a forbidden index when it's present as required in the master schema)
local function schemaConflictCheck(tForbidden, tOther)
    local bRet = true;



    return bRet;
end

local function schemaForbiddenIsValid(tInput)
    local bRet      = false;
    local sMessage  = "";

    if (type(tInput) == "table") then
        bRet = true;

        for sForbiddenIndex, bForbidden in pairs(tInput) do

            --ensure the index is a number
            if (type(sForbiddenIndex) ~= "string") then
                bRet = false;
                sMessage = "Bad schema table ('forbidden' subtable). Indices must be of type string. Type given: "..type(sForbiddenIndex)..'.';
                break;
            end

            --ensure the value (forbidden index name) is a string
            if (type(bForbidden) ~= "boolean") then
                bRet = false;
                sMessage = "Bad schema table ('forbidden' subtable). Values must be of type boolean. Type given: "..type(bForbidden)..'.';
                break;
            end

        end

    else
            sMessage  = "Bad schema table ('forbidden' subtable). Input is not a table. Type given: "..type(tInput);
    end

    return bRet, sMessage;
end

local function schemaPermittedOrRequiredIsValid(tInput, sTableName)
    local bRet      = false;
    local sMessage  = "";

    if (type(tInput) == "table") then
        bRet = true;

        --check the schema's keys and values
        for sIndex, tTypes in pairs(tInput) do
            local bBreak = false;

            --ensure the index is a string
            if (type(sIndex) ~= "string") then
                bRet = false;
                sMessage  = "Bad schema table ('"..sTableName.."' subtable). Indices must be of type string. Type given: "..type(sIndex);
                break;
            end

            --ensure the value is a table (the types table)
            if (type(tTypes) ~= "table") then
                bRet = false;
                sMessage  = "Bad schema table ('"..sTableName.."' subtable). Types table must be of type table. Type given: "..type(tTypes);
                break;
            end

            --check the schema's types table
            for nIndex, sType in pairs(tTypes) do

                --ensure the index is a number
                if (type(nIndex) ~= "number") then
                    bRet    = false;
                    bBreak  = true;
                    sMessage  = "Bad schema table ('"..sTableName.."' subtable). Types table indices must be of type number. Type given: "..type(nIndex)..'.';
                    break;
                end

                --ensure the value is a string
                if (type(sType) ~= "string") then
                    bRet    = false;
                    bBreak  = true;
                    sMessage  = "Bad schema table ('"..sTableName.."' subtable). Types table values must be of type string. Type given: "..type(sType)..'.';
                    break;
                end

            end

            if (bBreak) then
                break;
            end

            --ensure that there is at least one type entry
            if (#tTypes < 1) then
                bRet = false;
                sMessage  = "Bad schema table ('"..sTableName.."' subtable). Types table must contain at least one entry.";
                break;
            end

        end

    else --if the input schema table is not a table, tell the user
        sMessage  = "Bad schema table ('"..sTableName.."' subtable). Input is not a table. Type given: "..type(tInput);
    end

    return bRet, sMessage;
end


local function checkBlueprintVSSchema(tBP, tSchema)
    local bRet      = false;
    local tChecked  = {};
    local sMessage  = "";

    --ensure there are no forbidden indices
    if (type(tSchema.forbidden) == "table") then

        for sForbiddenIndex, bForbidden in pairs(tSchema.forbidden) do

            if (tBP[sForbiddenIndex] ~= nil)  then
                bRet = false;
                sMessage = "Invalid blueprint. Forbidden index: "..sForbiddenIndex..'.';
                break;
            end

        end

    end

    --ensure all required indices exist
    if (type(tSchema.required) == "table") then

        for sIndex, tTypes in pairs(tSchema.required) do
            tChecked[sIndex]    = true; --cache checked indices
            local bFound        = false;
            local zBPItem       = type(tBP[sIndex]);

            for _, zMasterItem in pairs(tTypes) do
                local bContinue = true;

                if (bContinue and zMasterItem == zBPItem)  then
                    bFound      = true;
                    bContinue   = false;
                end

            end

            if not (bFound) then
                bRet = false;
                sMessage = "Invalid blueprint. Missing required index: "..sIndex..'.';
                break;
            end

        end

    end

    --check for extra things that should not be
    for vIndex, vTypes in pairs(tBP) do

        --TODO check index type and types tables



        if not (tChecked[k]) then
            local tTypes = tSchema.permitted[k];
            local zBPItem = type(v);

            if (tTypes == nil) then
                bRet = false;
                sMessage = "Invalid blueprint. Index is not explicitly permitted: '"..vIndex.."'.";
                break;
            end

            local bFound = false;
            local bContinue = true;

            for _, zPermitted in pairs(tTypes) do

                if (bContinue) then

                    if (zBPItem == zPermitted) then
                        bFound = true;
                        bContinue = false;
                    end

                end

            end

            if not (bFound) then
                bRet = false;
                sMessage = "Invalid blueprint. No valid value type found for permitted index: '"..vIndex.."'.";
                break;
            end

        end

    end

    return bRet, sMessage;
end

return class("Blueprintium",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Blueprintium = function(stapub) end,
    idIsValid = function(vID)
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
    end,
},
{--PRIVATE
    blueprints         = {},--used for building objects from BP tables (imported generally from mods)
    schema    = {
        forbidden   = {},
        required    = {},
        permitted   = {},
    },
    --used for checking that a BP is valid, set by child classes
    blueprintValidator = null,
},
{--PROTECTED
},
{--PUBLIC
    Blueprintium = function(this, cdat)
        cdat.pri.blueprintValidator = placeholder;
    end,
    add = function(this, cdat, tBP)--TODO

    end,
    getSchema = function(this, cdat)
        return clone(cdat.pri.schema);
    end,
    isValid = function(this, cdat, tBP)--TODO
        local bRet = type(tBP) == "table";
        local pri = cdat.pri;
        local sMessage = "";

        --first, check the master schema
        if (bRet) then
            bRet, sMessage = checkBlueprintVSSchema(tBP, _tBPMasterSchema);

            --now check the class's BP schema
            if (bRet) then
                bRet, sMessage = checkBlueprintVSSchema(tBP, pri.schema);

                --now run the custom validator callback function (if it exists)
                local bValid = pri.blueprintValidator(tBP);

                if (type(bValid) == "boolean") then
                    bRet = bValid;
                end

            end

        else
            sMessage = "Invalid blueprint. Blueprint must of type table. Type given: "..type(tBP);
        end

        return bRet, sMessage;
    end,
    remove = function(this, cdat, sID)--TODO

    end,
    setSchema = function(this, cdat, tSchema)--TODO
        local zSchema       = type(tSchema);
        local bRet          = zSchema == "table" and rawtype(tSchema) == "table";
        local pri           = cdat.pri;

        if (bRet) then
            --reset the schema table
            pri.schema = {
                forbidden   = {},
                permitted   = {},
                required    = {},
            };

            local tMySchema = pri.schema;

            if (tSchema.forbidden ~= nil) then
                local bForbiddenIsValid, sMessage = schemaForbiddenIsValid(tSchema.forbidden);

                if not (bForbiddenIsValid) then
                    error(sMessage);
                end

                tMySchema.forbidden = clone(tSchema.forbidden);
            end

            if (tSchema.permitted ~= nil) then
                local bPermittedIsValid, sMessage = schemaPermittedOrRequiredIsValid(tSchema.permitted, "permitted");

                if not (bPermittedIsValid) then
                    error(sMessage);
                end

                tMySchema.permitted = clone(tSchema.permitted);
            end

            if (tSchema.required ~= nil) then
                local bRequiredIsValid, sMessage = schemaPermittedOrRequiredIsValid(tSchema.required, "required");

                if not (bRequiredIsValid) then
                    error(sMessage);
                end

                tMySchema.required = clone(tSchema.required);
            end

            --merge the master schema into the finished one

            --forbidden
            for sForbiddenIndex, bForbidden in pairs(_tBPMasterSchema.forbidden) do
                tMySchema.forbidden[sForbiddenIndex] = bForbidden;
            end

            --permitted
            for sIndex, tTypes in pairs(_tBPMasterSchema.permitted) do
                tMySchema.permitted[sIndex] = clone(tTypes);
            end

            --required
            for sIndex, tTypes in pairs(_tBPMasterSchema.required) do
                tMySchema.required[sIndex] = clone(tTypes);
            end

        elseif (zSchema == "nil") then
            tSchema = clone(_tBPMasterSchema);
        end

        return bRet;
    end,
    setValidatorCallback = function(this, cdat, fCallback)
        local zCallback = type(fCallback);
        local pri = cdat.pri;

        if (zCallback == "function") then
            pri.blueprintValidator = fCallback;

        elseif (zCallback == "nil") then
            pri.blueprintValidator = placeholder;

        end

    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
