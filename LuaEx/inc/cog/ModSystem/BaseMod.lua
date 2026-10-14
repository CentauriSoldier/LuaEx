--LOCALIZATION
local class     = class;
local pairs     = pairs;
local ipairs    = ipairs;
local rawtype   = rawtype;
local pcall     = pcall;

-- This UUID is the permanent identity for base-game/default content.
local _sDefaultModID = "27a27ca4-5f85-48ea-a30d-e6ad95d89d84"; --WARNING: NEVER CHANGE THIS VALUE!
local _nMaxVersion   = 999;
local vLog;
local tWarnings     = {};

--[[!
    @fqxn CoG.ModSystem.BaseMod.Helpers.isPlainTable
    @desc Checks for ordinary metadata tables without class/instance behavior or metatables.
    @param any vValue Candidate metadata container.
    @ret boolean bPlain Whether the value is an ordinary table.
    @scope local
!]]
local function isPlainTable(vValue)
    -- Check both raw storage and LuaEx type before accepting a data container.
    return rawtype(vValue) == "table" and type(vValue) == "table"
           and getmetatable(vValue) == nil;
end

--[[!
    @fqxn CoG.ModSystem.BaseMod.Helpers.isNonblank
    @desc Checks for a string with at least one visible character.
    @param any vValue Candidate field value.
    @ret boolean bNonblank Whether the string contains non-whitespace text.
    @scope local
!]]
local function isNonblank(vValue)
    -- Guard the type before searching the string.
    return rawtype(vValue) == "string" and vValue:find("%S") ~= nil;
end

--[[!
    @fqxn CoG.ModSystem.BaseMod.Helpers.warn
    @desc Retains a warning and sends it to the supplied log, or a lazy BaseLog fallback.
    Logging failures do not interrupt construction or later imports.
    @param string sMessage Diagnostic including the affected mod where available.
    @scope local
!]]
local function warn(sMessage)
    -- Step 1: retain the warning before invoking external logging code.
    local sWarning = "BaseMod: "..sMessage;
    tWarnings[#tWarnings + 1] = sWarning;

    -- Step 2: contain failures in both fallback creation and host logging.
    pcall(function()
        local BaseLogClass = require("LuaEx.inc.classes.util.BaseLog");

        if (vLog == nil) then
            vLog = BaseLogClass("BaseMod.log", function()
                -- BaseLog requests a timestamp for each new entry.
                return os.date("%Y-%m-%d %H:%M:%S");
            end);
        end

        if (rawtype(vLog) == "function") then
            vLog(sWarning);
        else
            vLog.log(sWarning, BaseLogClass.LEVEL.WARNING);
        end
    end);
end

--[[!
    @fqxn CoG.ModSystem.BaseMod.Helpers.readStringList
    @desc Copies a dense numeric list of strings. UUID lists are normalized and deduplicated;
    author lists retain supplied order. Invalid entries reject the list rather than disappearing.
    @param table|nil vInput Supplied list; nil is permitted only for optional lists.
    @param string sField Field name for diagnostics.
    @param boolean bUUID Whether entries must be UUIDs.
    @param boolean bRequired Whether at least one entry is required.
    @ret table|nil tList Validated independent list.
    @ret string|nil sReason First list failure.
    @scope local
!]]
local function readStringList(vInput, sField, bUUID, bRequired)
    -- Step 1: distinguish an omitted optional list from an invalid supplied value.
    if (vInput == nil and not bRequired) then
        return {};
    end

    if (not isPlainTable(vInput)) then
        return nil, sField.." must be a dense list of strings.";
    end

    -- Step 2: verify numeric positions without relying on # for a sparse table.
    local nCount = 0;

    for vKey in pairs(vInput) do
        if (rawtype(vKey) ~= "number" or vKey < 1 or vKey % 1 ~= 0) then
            return nil, sField.." must use positive integer list positions.";
        end

        nCount = nCount + 1;
    end

    if (bRequired and nCount == 0) then
        return nil, sField.." must contain at least one entry.";
    end

    -- Step 3: copy valid entries, rejecting holes and malformed UUIDs explicitly.
    local tList = {};
    local tSeen = {};

    for nIndex = 1, nCount do
        local sValue = vInput[nIndex];

        if (not isNonblank(sValue)) then
            return nil, sField.."["..nIndex.."] must be a nonblank string; holes are not allowed.";
        end

        if (bUUID) then
            if (not sValue:isuuid()) then
                return nil, sField.."["..nIndex.."] must be a mod UUID.";
            end

            sValue = sValue:lower();
        end

        if (not bUUID or not tSeen[sValue]) then
            tList[#tList + 1] = sValue;
            tSeen[sValue] = true;
        end
    end

    return tList;
end

--[[!
    @fqxn CoG.ModSystem.BaseMod.Helpers.prepareInfo
    @desc Validates and normalizes metadata without modifying the supplied table.
    Blueprint entries remain raw so Factorium can reject them individually.
    @param table tInput Mod-file metadata table.
    @ret table|nil tInfo Normalized metadata with independent author/relationship lists.
    @ret string|nil sReason Metadata rejection reason.
    @scope local
!]]
local function prepareInfo(tInput)
    -- Step 1: validate the container and required identity/display fields.
    if (not isPlainTable(tInput)) then
        return nil, "Mod metadata must be a plain table.";
    end

    if (not isNonblank(tInput.id) or not tInput.id:isuuid()) then
        return nil, "Mod id must be a UUID.";
    end

    for _, sField in ipairs({ "name", "description" }) do
        if (not isNonblank(tInput[sField])) then
            return nil, "Mod "..sField.." must be a nonblank string.";
        end
    end

    -- Step 2: validate and copy the author, dependency and conflict lists.
    local tAuthors, sReason = readStringList(tInput.authors, "authors", false, true);

    if (not tAuthors) then
        return nil, sReason;
    end

    local tRequired;
    tRequired, sReason = readStringList(tInput.required, "required", true, false);

    if (not tRequired) then
        return nil, sReason;
    end

    local tConflicts;
    tConflicts, sReason = readStringList(tInput.conflicts, "conflicts", true, false);

    if (not tConflicts) then
        return nil, sReason;
    end

    -- Step 3: check real calendar dates and finite numeric version bounds.
    for _, sField in ipairs({ "released", "updated" }) do
        local sDate = tInput[sField];

        if (rawtype(sDate) ~= "string" or not sDate:isdatevalid()) then
            return nil, "Mod "..sField.." must be a valid YYYY-MM-DD date.";
        end
    end

    local nVersion = tInput.version;

    if (rawtype(nVersion) ~= "number" or nVersion ~= nVersion
        or nVersion < 0.01 or nVersion > _nMaxVersion) then
        return nil, "Mod version must be between 0.01 and ".._nMaxVersion..".";
    end

    -- Step 4: validate only the blueprint container, leaving its entries to Factorium.
    if (tInput.blueprints ~= nil and not isPlainTable(tInput.blueprints)) then
        return nil, "Mod blueprints must be a plain table.";
    end

    -- Step 5: produce normalized metadata; omitted optional strings become empty.
    return {
        id          = tInput.id:lower(),
        name        = tInput.name,
        authors     = tAuthors,
        description = tInput.description,
        released    = tInput.released,
        updated     = tInput.updated,
        version     = nVersion,
        contact     = rawtype(tInput.contact) == "string" and tInput.contact or "",
        website     = isNonblank(tInput.website) and tInput.website or "",
        required    = tRequired,
        conflicts   = tConflicts,
        blueprints  = tInput.blueprints or {},
    };
end

--[[!
    @fqxn CoG.ModSystem.BaseMod.Methods.validateModInfo
    @desc Validates metadata through a protected boundary. Returns normalized data or a reason,
    without logging or throwing; the constructor/importer owns contextual reporting.
    @param table tInput Returned mod metadata table.
    @ret table|nil tInfo Normalized metadata on success.
    @ret string|nil sReason Validation failure, including unexpected helper errors.
    @vis static public
!]]
local function validateModInfo(tInput)
    -- Turn unexpected helper failures into the same ordinary rejection contract.
    local bOK, tInfo, sReason = pcall(prepareInfo, tInput);

    if (not bOK) then
        return nil, tostring(tInfo);
    end

    return tInfo, sReason;
end

--[[!
    @fqxn CoG.ModSystem.BaseMod
    @desc Base for game-specific mod objects. Initializes metadata atomically
    and import data, and retains raw definitions for Factorium. Invalid metadata is logged
    without throwing. Factorium owns activation, acceptance and rejection state.
!]]
return class("BaseMod",
{}, --METAMETHODS
{--STATIC PUBLIC
    DEFAULT_MOD_ID__RO = _sDefaultModID,
    MAX_VERSION__RO    = _nMaxVersion,
    validateModInfo    = validateModInfo,

    --[[!
        @fqxn CoG.ModSystem.BaseMod.Methods.setLog
        @desc Sets a logging callback/object; nil restores lazy BaseLog at BaseMod.log.
        @param function|table|nil log Callback or object with a dot-call log method.
        @ret boolean bSuccess Whether the supplied logger was accepted.
        @ret string|nil sReason Invalid-logger explanation.
        @vis static public
    !]]
    setLog = function(log)
        -- Step 1: inspect object methods safely; callbacks and nil need no lookup.
        if (log ~= nil and rawtype(log) ~= "function") then
            local bOK, bValid = pcall(function()
                return rawtype(log.log) == "function";
            end);

            if (not bOK or not bValid) then
                local sReason = "Log must be a callback or object with a log method.";
                warn(sReason);
                return false, sReason;
            end
        end

        -- Step 2: replace the destination only after validation succeeds.
        vLog = log;
        return true;
    end,

    --[[!
        @fqxn CoG.ModSystem.BaseMod.Methods.getWarnings
        @desc Returns retained warning strings independently of external logging success.
        @ret table tMessages New ordered list of warnings.
        @vis static public
    !]]
    getWarnings = function()
        -- Copy the list so callers cannot erase stored diagnostics.
        local tMessages = {};

        for nIndex, sMessage in ipairs(tWarnings) do
            tMessages[nIndex] = sMessage;
        end

        return tMessages;
    end,
},
{}, --PRIVATE
{--PROTECTED
    authors             = {},
    blueprints          = {},
    conflicts           = {},
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

    --[[!
        @fqxn CoG.ModSystem.BaseMod.Methods.BaseMod
        @desc Validates complete metadata before committing fields. On failure, logs the mod
        and reason and keeps declared defaults. No lifecycle or validity state is stored.
        Authors and relationships are copied; raw blueprints remain for per-entry import.
        @param BaseMod this Instance initialized by its subclass constructor.
        @param table cdat LuaEx class data.
        @param table tModInfo Required mod metadata and optional definitions.
        @vis protected
    !]]
    BaseMod = function(this, cdat, tModInfo)
        -- Step 1: prepare normalized data without partially changing this object.
        local tInfo, sReason = validateModInfo(tModInfo);

        if (not tInfo) then
            local sName = "unnamed";
            local sID = "unknown ID";

            if (isPlainTable(tModInfo)) then
                sName = isNonblank(tModInfo.name) and tModInfo.name or sName;
                sID = isNonblank(tModInfo.id) and tModInfo.id or sID;
            end

            warn("Mod '"..sName.."' ("..sID..") rejected: "..sReason);
            return;
        end

        -- Step 2: commit validated scalar fields and independent author data.
        local pro = cdat.pro;
        pro.ID = tInfo.id;
        pro.Name = tInfo.name;
        pro.authors = tInfo.authors;
        pro.Contact = tInfo.contact;
        pro.Description = tInfo.description;
        pro.Released = tInfo.released;
        pro.Updated = tInfo.updated;
        pro.Version = tInfo.version;
        pro.Website = tInfo.website;
        pro.blueprints = tInfo.blueprints;

        -- Step 3: convert relationship lists into protected membership sets.
        for _, sID in ipairs(tInfo.required) do
            pro.required[sID] = true;
        end

        for _, sID in ipairs(tInfo.conflicts) do
            pro.conflicts[sID] = true;
        end

    end,
},
{--PUBLIC
    --[[!
        @fqxn CoG.ModSystem.BaseMod.Methods.getInfo
        @desc Returns metadata in mod-file format. Factorium validates it during import.
        Authors/relationship lists are independent copies. Blueprint entries retain their
        raw reference until Factorium validates and copies them individually.
        @param BaseMod this Mod instance.
        @param table cdat LuaEx class data.
        @ret table tModInfo Metadata and raw definitions; uninitialized fields retain defaults.
        @vis public
    !]]
    getInfo = function(this, cdat)
        -- Step 1: copy author data and rebuild UUID lists from membership sets.
        local pro = cdat.pro;
        local tAuthors = {};
        local tRequired = {};
        local tConflicts = {};

        for nIndex, sAuthor in ipairs(pro.authors) do
            tAuthors[nIndex] = sAuthor;
        end

        for sID in pairs(pro.required) do
            tRequired[#tRequired + 1] = sID;
        end

        for sID in pairs(pro.conflicts) do
            tConflicts[#tConflicts + 1] = sID;
        end

        -- Stable ordering makes returned metadata easier to inspect and compare.
        table.sort(tRequired);
        table.sort(tConflicts);

        -- Step 2: assemble external data without exposing protected relationship sets.
        return {
            id          = pro.ID,
            name        = pro.Name,
            authors     = tAuthors,
            description = pro.Description,
            released    = pro.Released,
            updated     = pro.Updated,
            version     = pro.Version,
            contact     = pro.Contact,
            website     = pro.Website,
            required    = tRequired,
            conflicts   = tConflicts,
            blueprints  = pro.blueprints,
        };
    end,


},
nil,   --extending class
false, --if the class is final
nil    --interfaces
);
