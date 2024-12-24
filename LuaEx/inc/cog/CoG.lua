
--TODO NOTE: if classes getting BP info is slow, have them cache the calls

-- Pattern explanation:
-- ^        : start of the string
-- %u%u%u  : exactly three uppercase letters (XXX)
-- %-       : literal dash (-)
-- %x%x%x%x : exactly four hexadecimal digits (DDDD)
-- $        : end of the string

local _tIDCheckCache    = {};
local _nMaxIDs          = 65535; --WARNING: DO NOT CHANGE UNLESS YOU ALSO CHANGE THE ID FORMAT AND LENGTH
local _sIDFormat        = "^%u%u%u%-%x%x%x%x$";
local _tIDBank          = {
    --byClass     = {},
    --byString    = {},
};

local _tBPMasterSchema = {
    forbidden = {
        "class"
    },
    permitted = {},
    required = {
        id   = {"string"},
        name = {"string"},
    },
};

--TODO add messages when failures occur so the user knows what went wrong.

--TODO check againt master schema for conflicts
local function schemaSubtableIsValid(tInput)
    local bRet = false;

    if (type(tInput) == "table") then
        bRet = true;

        --check the first layer of schema TODO THIS IS NOT CORRECT, forbidden is numerically-index and string valued...fix this.
        for k, v in pairs(tInput) do

            if (type(k) ~= "string") then
                bRet = false;
                break;
            end

            if (type(v) ~= "table") then
                bRet = false;
                break;
            else

                --check the final layer of schema
                for kk, vv in pairs(v) do

                    if (type(kk) ~= "number") then
                        bRet = false;
                        break;
                    end

                    if (type(vv) ~= "string") then
                        bRet = false;
                        break;
                    end

                end

            end

        end

    end

    return bRet;
end


local function checkBlueprintVSSchema(tBP, tSchema)
    local bRet = false;

    --forbidden
    if (type(tSchema.forbidden) == "table") then

        for _, v in pairs(tSchema.forbidden) do

            if (tBP[v])  then
                bRet = false;
                break;
            end

        end

    end

    --required
    if (type(tSchema.required) == "table") then

        for sIndex, tTypes in pairs(tSchema.required) do
            local bFound    = false;
            local zBPItem   = type(tBP[sIndex]);

            for _, zMasterItem in pairs(tTypes) do
                local bContinue = true;

                if (bContinue and zMasterItem == zBPItem)  then
                    bFound      = true;
                    bContinue   = false;
                end

            end

            if not (bFound) then
                bRet = false;
                break;
            end

        end

    end

    --TODO PERMITTED
    --permitted

    return bRet;
end

return class("CoG",
{--METAMETHODS

},
{--STATIC PUBLIC
    --CoG = function(stapub) end,
},
{--PRIVATE
    blueprints         = {},--used for building objects from BP tables (imported generally from mods)
    blueprintSchema    = {},--used for checking that a BP is valid, set by child classes
},
{--PROTECTED
    blueprintValidator = null,
    getBlueprintSchema__FNL = function(this, cdat)
        return clone(cdat.pri.blueprintSchema);
    end,
    setBlueprintSchema__FNL = function(this, cdat, tSchema)--TODO
        local bRet          = type(tSchema) == "table" and rawtype(tSchema) == "table";
        local pri           = cdat.pri;
        local isValid       = schemaSubtableIsValid;
        pri.blueprintSchema = {};

        if (bRet) then

            if (tSchema.forbidden ~= nil and isValid(tSchema.forbidden)) then
                pri.blueprintSchema.forbidden = clone(tSchema.forbidden);
            end

            if (tSchema.permitted ~= nil and isValid(tSchema.permitted)) then
                pri.blueprintSchema.permitted = clone(tSchema.permitted);
            end

            if (tSchema.required ~= nil and isValid(tSchema.required)) then
                pri.blueprintSchema.required = clone(tSchema.required);
            end

        end

        return bRet;
    end,
},
{--PUBLIC
    CoG = function(this, cdat)

    end,
    addBlueprint__FNL = function(this, cdat, tBP)--TODO

    end,
    blueprintIDIsValid__FNL = function(this, cdat, sID)
        local bRet;

        if (_tIDCheckCache[sID] ~= nil) then
            bRet = _tIDCheckCache[sID];
        else
            bRet = type(sID) == "string" and sID:match(_sIDFormat);
            _tIDCheckCache[sID] = bRet;
        end

        return bRet;
    end,
    blueprintIsValid__FNL = function(this, cdat, tBP)--TODO
        local bRet = type(tBP) == "table" and rawtype(tBP) == "table";
        local pri = cdat.pri;
        local pro = cdat.pro;

        --first, check the master schema
        if (bRet) then
            bRet = checkBlueprintVSSchema(tBP, _tBPMasterSchema);

            --now check the class's BP schema
            if (bRet) then
                bRet = checkBlueprintVSSchema(tBP, pri.blueprintSchema);

                --now run the custom validator callback function (if it exists)
                if (bRet and type(pro.blueprintValidator) == "function") then
                    local bValid = pro.blueprintValidator(tBP);

                    if (type(bValid) == "boolean") then
                        bRet = bValid;
                    end

                end

            end

        end

        return bRet;
    end,
    fromBlueprint = function(this, cdat, sID, ...)--TODO
        local pro = cdat.pro;


    end,
    removeBlueprint__FNL = function(this, cdat, sID)--TODO

    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
