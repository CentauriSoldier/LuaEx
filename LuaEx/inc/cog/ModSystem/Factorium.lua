--LOCALIZATION
local class     = class;
local rawtype   = rawtype;
local pairs     = pairs;
local ipairs    = ipairs;
local pcall     = pcall;

-- Structural keys stay separate from class-defined blueprint fields.
local sBlueprints = "COG_MOD_fa78f374-8608-4d9f-95a7-4ac0c96ab615";
local sChildren   = "COG_MOD_854fea72-cc40-48fd-a71f-bb1ffb20cc46";

local tEnvironment   = {};
local tClasses       = {};
local tClassesByName = {};
local tClassChecks   = {};
local tHierarchy     = {};
local tNodes         = {};
local tMods          = {};
local tModOrder      = {};
local tPendingFiles  = {};
local tWarnings      = {};
local vLog;
local bDirty         = false;

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.isNonblank
    @desc Checks for a string containing a non-whitespace character.
    @param any vValue Value to inspect.
    @ret boolean bNonblank Whether the input is a nonblank string.
    @scope local
!]]
local function isNonblank(vValue)
    -- Require a string before searching for a visible character.
    return rawtype(vValue) == "string" and vValue:find("%S") ~= nil;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.normalizeID
    @desc Lowercases a string mod UUID; leaves other types unchanged for the caller to handle.
    @param any vID Mod UUID supplied by the caller.
    @ret any vNormalized Lowercase UUID or unchanged non-string input.
    @scope local
!]]
local function normalizeID(vID)
    -- Normalize mod identity without coercing invalid caller input.
    return rawtype(vID) == "string" and vID:lower() or vID;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.getLog
    @desc Returns the supplied logger or lazily creates BaseLog at Factorium.log in the working
    directory.
    @ret function|BaseLog log Current logging method or object.
    @scope local
!]]
local function getLog()
    -- Create the file-backed default only when a warning first needs it.
    if (vLog == nil) then
        local BaseLogClass = require("LuaEx.inc.classes.util.BaseLog");
        vLog = BaseLogClass("Factorium.log", function()
            -- BaseLog asks for this timestamp when it creates an entry.
            return os.date("%Y-%m-%d %H:%M:%S");
        end);
    end

    -- Reuse the chosen destination for subsequent messages.
    return vLog;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.warn
    @desc Retains a prefixed warning and attempts external logging. Logger failures are contained so
    importing can continue.
    @param string sMessage Diagnostic text including source details where applicable.
    @scope local
!]]
local function warn(sMessage)
    -- Step 1: retain the diagnostic before calling host-supplied code.
    local sWarning = "Factorium: "..sMessage;
    tWarnings[#tWarnings + 1] = sWarning;

    -- A failed logger must not stop an import. Keep an in-memory copy too.
    pcall(function()
        local log = getLog();

        -- Step 2: dispatch to a callback or dot-call log object inside the protected boundary.
        if (rawtype(log) == "function") then
            log(sWarning);
        else
            local BaseLogClass = require("LuaEx.inc.classes.util.BaseLog");
            log.log(sWarning, BaseLogClass.LEVEL.WARNING);
        end
    end);
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.reject
    @desc Logs a rejected operation and returns a failure pair without throwing.
    @param string sMessage Diagnostic text including source details where applicable.
    @ret boolean bSuccess Always false.
    @ret string sReason Supplied failure reason.
    @scope local
!]]
local function reject(sMessage)
    -- Log once and return the same failure reason to the caller.
    warn(sMessage);
    return false, sMessage;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.isPlainTable
    @desc Checks for an ordinary data table, excluding class objects, instances and tables with
    metatables.
    @param any vValue Value to inspect.
    @ret boolean bPlain Whether the input is a plain data table.
    @scope local
!]]
local function isPlainTable(vValue)
    -- Class references and instances must never enter definition data.
    return rawtype(vValue) == "table" and type(vValue) == "table"
           and getmetatable(vValue) == nil;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.checkTable
    @desc Recursively validates both keys and values. Active-path cycles are forbidden; previously
    checked shared tables are allowed.
    @param table tInput Definition table currently being checked recursively.
    @param table tVisiting Tables on the current recursion path.
    @param table tChecked Tables already validated in this traversal.
    @ret boolean bValid Whether the reachable table structure is valid.
    @ret string|nil sReason First structural failure.
    @scope local
!]]
local function checkTable(tInput, tVisiting, tChecked)
    -- Step 1: reject special objects before traversing their contents.
    if (not isPlainTable(tInput)) then
        return false, "Blueprint tables must be plain tables.";
    end

    -- Step 2: distinguish active-path cycles from previously checked sharing.
    if (tVisiting[tInput]) then
        return false, "Blueprint contains a cyclic table reference.";
    end

    if (tChecked[tInput]) then
        return true;
    end

    -- Step 3: enter the path before recursively checking keys and values.
    tVisiting[tInput] = true;

    for vKey, vValue in pairs(tInput) do
        local sKeyType = rawtype(vKey);

        -- Enforce allowed key types at every recursion depth.
        if (sKeyType ~= "string" and sKeyType ~= "number" and sKeyType ~= "table") then
            return false, "Blueprint keys must be strings, numbers or tables.";
        end

        -- Both keys and values are traversed. Shared acyclic tables are valid.
        if (sKeyType == "table") then
            local bValid, sReason = checkTable(vKey, tVisiting, tChecked);

            if (not bValid) then
                return false, sReason;
            end
        end

        local sValueType = rawtype(vValue);

        if (sValueType == "table") then
            local bValid, sReason = checkTable(vValue, tVisiting, tChecked);

            if (not bValid) then
                return false, sReason;
            end
        elseif (sValueType ~= "string" and sValueType ~= "number"
                and sValueType ~= "boolean" and sValueType ~= "function") then
            return false, "Unsupported blueprint value type: "..sValueType..".";
        end
    end

    -- Step 4: leave the path and cache this table as successfully checked.
    tVisiting[tInput] = nil;
    tChecked[tInput] = true;
    return true;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.copyTable
    @desc Copies keys and values using a memo table, preserving shared table identities within the
    copy. Functions retain their closures and environment.
    @param table tInput Validated table graph to copy.
    @param table tCopies Map of original tables to their copies.
    @ret table tCopy Independent table graph.
    @scope local
!]]
local function copyTable(tInput, tCopies)
    -- Step 1: reuse prior copies rather than duplicating shared table identities.
    if (tCopies[tInput]) then
        return tCopies[tInput];
    end

    -- Step 2: remember the destination before descending into keys or values.
    local tCopy = {};
    tCopies[tInput] = tCopy;

    -- Step 3: copy both sides of entries while retaining scalar/function values.
    for vKey, vValue in pairs(tInput) do
        local vNewKey = vKey;
        local vNewValue = vValue;

        if (rawtype(vKey) == "table") then
            vNewKey = copyTable(vKey, tCopies);
        end

        if (rawtype(vValue) == "table") then
            vNewValue = copyTable(vValue, tCopies);
        end

        -- Functions retain the host-supplied environment and closures.
        tCopy[vNewKey] = vNewValue;
    end

    return tCopy;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.mergeTable
    @desc Merges a validated source into a destination in place. Nested tables merge by key,
    including numeric positions. Supplied scalar/function values replace; omitted keys retain
    defaults.
    @param table tTarget Destination modified in place.
    @param table tSource Validated source whose supplied fields take precedence.
    @param table tKeyCopies Shared original-to-copy map for table keys across merge layers.
    @scope local
!]]
local function mergeTable(tTarget, tSource, tKeyCopies)
    -- Process each source location without modifying the source.
    for vKey, vValue in pairs(tSource) do
        local vTargetKey = vKey;

        -- Map table keys consistently across all merge layers.
        if (rawtype(vKey) == "table") then
            vTargetKey = copyTable(vKey, tKeyCopies);
        end

        -- Recurse into tables, or replace directly when the source is scalar/function data.
        if (rawtype(vValue) == "table") then
            if (rawtype(tTarget[vTargetKey]) ~= "table") then
                tTarget[vTargetKey] = {};
            end

            -- Lists merge by numeric position, just like other field tables.
            mergeTable(tTarget[vTargetKey], vValue, tKeyCopies);
        else
            tTarget[vTargetKey] = vValue;
        end
    end
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.getStaticMember
    @desc Uses the supported class helper to retrieve a public static member only when its raw type
    matches. Private class implementation tables are not inspected.
    @param class cClass Class reference supplied by the caller.
    @param string sName Required public static member name.
    @param string sType Expected raw member type.
    @ret any|nil vMember Matching public static member, or nil.
    @scope local
!]]
local function getStaticMember(cClass, sName, sType)
    -- Ask the supported helper before accessing a possibly absent member.
    local bExists, bStatic, sActualType = class.haspublicmember(cClass, sName);

    -- Only a public static member of the required type satisfies this request.
    if (bExists and bStatic and sActualType == sType) then
        return cClass[sName];
    end

    return nil;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.ensureNode
    @desc Returns or creates a private class node, attaching it to its ancestry branch and direct
    lookup index.
    @param class cClass Class reference supplied by the caller.
    @ret table tNode Existing or newly allocated node.
    @scope local
!]]
local function ensureNode(cClass)
    -- Step 1: reuse an existing branch when the class already has a node.
    if (tNodes[cClass]) then
        return tNodes[cClass];
    end

    -- Step 2: allocate separate compartments for definitions and child classes.
    local tNode = {
        [sBlueprints] = {},
        [sChildren]   = {},
    };
    tNodes[cClass] = tNode;

    -- Step 3: attach to the root or recursively create the parent branch.
    if (cClass == CoG) then
        tHierarchy[CoG] = tNode;
    else
        local cParent = class.getparent(cClass);
        ensureNode(cParent)[sChildren][cClass] = tNode;
    end

    return tNode;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.inspectClass
    @desc Checks the participating CoG contract and collects each ancestor's own defaults and
    validator in root-to-leaf order.
    @param class cClass Class reference supplied by the caller.
    @ret table|nil tInfo Class name and ordered layer information.
    @ret string|nil sReason Contract or ancestry failure.
    @scope local
!]]
local function inspectClass(cClass)
    -- Step 1: require CoG ancestry before inspecting the class contract.
    if (not class.is(cClass) or not class.ischildorself(cClass, CoG)) then
        return nil, "Only CoG classes can register.";
    end

    -- Step 2: require all three members on the target class.
    if (not getStaticMember(cClass, "Blueprint", "table")
        or not getStaticMember(cClass, "validateBlueprint", "function")
        or not getStaticMember(cClass, "fromBlueprint", "function")) then
        return nil, "Class must declare public static Blueprint, validateBlueprint and fromBlueprint.";
    end

    -- Step 3: prepend parents to produce root-to-leaf processing order.
    local tAncestors = {};
    local cAncestor = cClass;

    while (cAncestor) do
        table.insert(tAncestors, 1, cAncestor);

        if (cAncestor == CoG) then
            break;
        end

        cAncestor = class.getparent(cAncestor);
    end

    if (tAncestors[1] ~= CoG) then
        return nil, "CoG ancestry is not accessible in the registration scope.";
    end

    -- Step 4: collect ancestor contributions and structurally check their defaults.
    local tLayers = {};

    for _, cAncestorClass in ipairs(tAncestors) do
        local tDefaults = getStaticMember(cAncestorClass, "Blueprint", "table");
        local fValidator = getStaticMember(cAncestorClass, "validateBlueprint", "function");

        if (tDefaults) then
            local bValid, sReason = checkTable(tDefaults, {}, {});

            if (not bValid) then
                return nil, class.getname(cAncestorClass)..": "..sReason;
            end
        end

        -- Static members are not automatically inherited in LuaEx. Gather
        -- every ancestor's own table and validator explicitly. Ancestors
        -- without blueprint members contribute no defaults or constraints.
        tLayers[#tLayers + 1] = {
            name      = class.getname(cAncestorClass),
            defaults  = tDefaults or {},
            validator = fValidator,
        };
    end

    -- Return discovery data; registration decides whether to commit it.
    return { name = class.getname(cClass), layers = tLayers };
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Methods.registerClass
    @desc Validates and caches a participating CoG class. Both successful and failed contract
    answers are cached by class object. Records name routing and hierarchy without invoking the
    factory.
    @param class cClass Class reference supplied by the caller.
    @ret boolean bRegistered Whether the class satisfies the contract.
    @ret string|nil sReason Registration failure.
    @vis static public
!]]
local function registerClass(cClass)
    if (cClass == nil) then
        return reject("Class registration requires a CoG class.");
    end

    -- Step 1: reuse the contract answer cached for this exact class object.
    local tCached = tClassChecks[cClass];

    if (tCached) then
        return tCached.valid, tCached.reason;
    end

    -- Step 2: contain class-helper failures as rejected registration.
    local bOK, tInfo, sReason = pcall(inspectClass, cClass);

    if (not bOK) then
        sReason = tostring(tInfo);
        tInfo = nil;
    end

    if (not tInfo) then
        tClassChecks[cClass] = { valid = false, reason = sReason };
        return reject("Class registration rejected: "..tostring(sReason));
    end

    -- Step 3: commit the allowlist, name routing and hierarchy only after success.
    tClasses[cClass] = tInfo;
    tClassesByName[tInfo.name] = cClass;
    tClassChecks[cClass] = { valid = true };
    ensureNode(cClass);
    return true;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.compileBlueprint
    @desc Resolves a registered class name, merges ancestor defaults and imported fields, and
    enforces every ancestor validator against separate copies. Never invokes fromBlueprint.
    @param table tInput Raw blueprint containing string id and class routing fields.
    @ret table|nil tEntry Private class association and completed definition.
    @ret string|nil sReason Structural, routing or validation failure.
    @scope local
!]]
local function compileBlueprint(tInput)
    -- Step 1: validate the raw graph before recursive copying or merging.
    local bValid, sReason = checkTable(tInput, {}, {});

    if (not bValid) then
        return nil, sReason;
    end

    if (not isNonblank(tInput.id) or not isNonblank(tInput.class)) then
        return nil, "Blueprint requires a nonblank id and registered class name.";
    end

    -- Step 2: route the declared name through the private class allowlist.
    local cClass = tClassesByName[tInput.class];
    local tInfo = tClasses[cClass];

    if (not tInfo) then
        return nil, "Unknown registered class: "..tInput.class..".";
    end

    -- Step 3: assemble fresh data from ancestry defaults and mod overrides.
    local tCompiled = {};
    local tKeyCopies = {};

    for _, tLayer in ipairs(tInfo.layers) do
        -- Cache member discovery, not the contents of a mutable static table.
        -- Validate again in case the program edited its defaults after
        -- registration. Merging copies values into the compiled definition.
        local bLayerValid, sLayerReason = checkTable(tLayer.defaults, {}, {});

        if (not bLayerValid) then
            return nil, tLayer.name..": "..sLayerReason;
        end

        mergeTable(tCompiled, tLayer.defaults, tKeyCopies);
    end

    mergeTable(tCompiled, tInput, tKeyCopies);

    -- Step 4: enforce each ancestor validator against the completed definition.
    for _, tLayer in ipairs(tInfo.layers) do
        if (tLayer.validator) then
            -- A validator cannot change stored data or undo a parent check.
            local bOK, bAccepted, sMessage = pcall(tLayer.validator, copyTable(tCompiled, {}));

            if (not bOK) then
                return nil, tLayer.name.." validator failed: "..tostring(bAccepted);
            end

            if (bAccepted ~= true) then
                return nil, tLayer.name..": "..tostring(sMessage or "Validator rejected blueprint.");
            end
        end
    end

    -- Step 5: keep the class association private; public queries never return it.
    return { class = cClass, blueprint = tCompiled };
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.readModIDs
    @desc Normalizes an optional dependency/conflict UUID list into a lowercase membership set,
    rejecting malformed supplied lists.
    @param table|nil vInput Optional list of required or conflicting mod UUIDs.
    @param string sField Field name used in diagnostics.
    @ret table|nil tIDs UUID membership set.
    @ret string|nil sReason Invalid-list explanation.
    @scope local
!]]
local function readModIDs(vInput, sField)
    local tIDs = {};

    -- An omitted relationship list is valid and becomes an empty set.
    if (vInput == nil) then
        return tIDs;
    end

    if (not isPlainTable(vInput)) then
        return nil, sField.." must be a list of mod UUIDs.";
    end

    -- Validate every supplied UUID and normalize identity for membership checks.
    for _, sID in pairs(vInput) do
        if (rawtype(sID) ~= "string" or not sID:isuuid()) then
            return nil, sField.." contains an invalid mod UUID.";
        end

        tIDs[sID:lower()] = true;
    end

    return tIDs;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.prepareMod
    @desc Validates BaseMod metadata and creates staging state. Compilation and dependency/conflict
    resolution happen in later steps.
    @param table tInput Returned mod table containing metadata and optional definitions.
    @ret table|nil tMod Prepared record with empty blueprint history.
    @ret string|nil sReason Metadata failure.
    @scope local
!]]
local function prepareMod(tInput)
    -- Step 1: use the same metadata contract as BaseMod construction.
    local tInfo, sReason = BaseMod.validateModInfo(tInput);

    if (not tInfo) then
        return nil, sReason;
    end

    -- Step 2: convert normalized relationship lists to private lookup sets.
    local tRequired = readModIDs(tInfo.required, "required");
    local tConflicts = readModIDs(tInfo.conflicts, "conflicts");

    -- Step 3: allocate staging state; blueprint publication still waits for finalization.
    return {
        id        = tInfo.id,
        name      = tInfo.name,
        required  = tRequired,
        conflicts = tConflicts,
        requested = true,
        accepted  = false,
        entries   = {},
        rejected  = 0,
    };
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.appendBlueprint
    @desc Compiles one definition within a protected boundary. Counts and logs failure for that
    definition while allowing its siblings to continue.
    @param table tMod Private destination mod record.
    @param any vInput Raw blueprint entry supplied by the mod.
    @ret boolean bAccepted Whether the entry was appended.
    @ret string|nil sReason Compilation failure.
    @scope local
!]]
local function appendBlueprint(tMod, vInput)
    -- Step 1: isolate this definition and any validator exception.
    local bOK, tEntry, sReason = pcall(compileBlueprint, vInput);

    if (not bOK) then
        sReason = tostring(tEntry);
        tEntry = nil;
    end

    -- Step 2: count/log this failure while allowing sibling imports to proceed.
    if (not tEntry) then
        local sID = isPlainTable(vInput) and tostring(vInput.id) or "unknown";
        tMod.rejected = tMod.rejected + 1;
        warn("Mod '"..tMod.name.."' ("..tMod.id.."), blueprint '"..sID.."' skipped: "..tostring(sReason));
        return false, sReason;
    end

    -- Step 3: attach source provenance and retain the compiled definition.
    tEntry.modID = tMod.id;
    tMod.entries[#tMod.entries + 1] = tEntry;
    return true;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Methods.importMod
    @desc Imports a returned table or BaseMod instance, compiling definitions individually.
    Replacements retain load position, requested active state and old definitions whose replacements
    failed. Publication waits for finalization.
    @param table|BaseMod tInput Returned mod table or BaseMod subclass instance.
    @ret boolean bImported Whether metadata was accepted.
    @ret table|string tReport Loaded/skipped entry counts, or failure reason.
    @vis static public
!]]
local function importMod(tInput)
    -- Step 1: adapt BaseMod instances to the returned-table metadata format.
    if (class.isinstance(tInput) and class.ischildorself(class.of(tInput), BaseMod)) then
        local bOK, tInfo, sReason = pcall(tInput.getInfo);

        if (not bOK) then
            return reject("Mod metadata could not be read: "..tostring(tInfo));
        end

        if (not tInfo) then
            return reject("Mod metadata was rejected: "..tostring(sReason));
        end

        tInput = tInfo;
    end

    -- Step 2: prepare replacement state before altering an existing mod record.
    local bOK, tMod, sReason = pcall(prepareMod, tInput);

    if (not bOK) then
        sReason = tostring(tMod);
        tMod = nil;
    end

    if (not tMod) then
        local sLabel = "unknown";

        if (isPlainTable(tInput)) then
            local sName = isNonblank(tInput.name) and tInput.name or "unnamed";
            local sID = isNonblank(tInput.id) and tInput.id or "unknown ID";
            sLabel = sName.." ("..sID..")";
        end

        return reject("Mod import rejected for '"..sLabel.."': "..tostring(sReason));
    end

    -- Use deterministic order within a mod too: numeric entries first, then
    -- named entries. Each definition has its own protected import boundary.
    local tKeys = {};

    for vKey in pairs(tInput.blueprints or {}) do
        if (rawtype(vKey) == "number" or rawtype(vKey) == "string") then
            tKeys[#tKeys + 1] = vKey;
        else
            warn("Mod '"..tMod.name.."': blueprint list key must be a number or string.");
        end
    end

    table.sort(tKeys, function(a, b)
        -- Numeric list positions come first; named entries follow alphabetically.
        if (rawtype(a) ~= rawtype(b)) then
            return rawtype(a) == "number";
        end

        return a < b;
    end);

    -- Step 3: compile entries independently in deterministic order.
    for _, vKey in ipairs(tKeys) do
        appendBlueprint(tMod, tInput.blueprints[vKey]);
    end

    -- Step 4: retain requested state/load position and rescue invalid replacements.
    local tPrevious = tMods[tMod.id];

    if (tPrevious) then
        tMod.requested = tPrevious.requested;
        local tSuppliedIDs = {};
        local tValidIDs = {};

        for _, vKey in ipairs(tKeys) do
            local vDefinition = tInput.blueprints[vKey];

            if (isPlainTable(vDefinition) and isNonblank(vDefinition.id)) then
                tSuppliedIDs[vDefinition.id] = true;
            end
        end

        for _, tEntry in ipairs(tMod.entries) do
            tValidIDs[tEntry.blueprint.id] = true;
        end

        -- Preserve this mod's old definition if its replacement is invalid.
        -- Definitions omitted entirely from a successful reload are removed.
        for _, tEntry in ipairs(tPrevious.entries) do
            local sID = tEntry.blueprint.id;

            if (tSuppliedIDs[sID] and not tValidIDs[sID]) then
                tMod.entries[#tMod.entries + 1] = tEntry;
            end
        end
    else
        tModOrder[#tModOrder + 1] = tMod.id;
    end

    -- Step 5: commit private staging history and require finalization.
    tMods[tMod.id] = tMod;
    bDirty = true;
    return true, { loaded = #tMod.entries, skipped = tMod.rejected };
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.modsConflict
    @desc Checks both declarations. A conflict specified by either mod makes the pair incompatible.
    @param table tLeft First private mod record.
    @param table tRight Second private mod record.
    @ret boolean|nil bConflict Truthy when either mod declares the other incompatible.
    @scope local
!]]
local function modsConflict(tLeft, tRight)
    -- A unilateral declaration is sufficient; both mods need not list it.
    return tLeft.conflicts[tRight.id] or tRight.conflicts[tLeft.id];
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.collectRequirements
    @desc Traverses a dependency closure, rejecting missing, inactive or unavailable mods. A visited
    set prevents infinite recursion for circular requirements.
    @param string sID Mod UUID to inspect or update.
    @param table tGroup Accumulated dependency membership set.
    @param table tUnavailable Set of excluded mods.
    @ret boolean bAvailable Whether all reachable dependencies are available.
    @ret string|nil sReason Missing or rejected dependency.
    @scope local
!]]
local function collectRequirements(sID, tGroup, tUnavailable)
    -- Step 1: stop revisiting dependencies, including circular groups.
    if (tGroup[sID]) then
        return true;
    end

    -- Step 2: reject requirements that are missing, inactive or excluded.
    local tMod = tMods[sID];

    if (not tMod or not tMod.requested or tUnavailable[sID]) then
        return false, "Missing or rejected required mod: "..sID..".";
    end

    -- Step 3: mark this mod before recursing into its dependency closure.
    tGroup[sID] = true;

    for sRequired in pairs(tMod.required) do
        local bOK, sReason = collectRequirements(sRequired, tGroup, tUnavailable);

        if (not bOK) then
            return false, sReason;
        end
    end

    return true;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.publishCatalog
    @desc Rebuilds exact-class visible catalogs from accepted mods in host order. The last accepted
    entry wins globally; per-mod history remains available for restoration.
    @scope local
!]]
local function publishCatalog()
    local tWinners = {};

    -- Step 1: clear visible indexes while retaining private per-mod history.
    for _, tNode in pairs(tNodes) do
        tNode[sBlueprints] = {};
    end

    -- Step 2: follow supplied load order so later accepted entries win.
    for _, sID in ipairs(tModOrder) do
        local tMod = tMods[sID];

        -- Retain compiled definitions from inactive/rejected mods privately.
        -- Only the last accepted definition for a GLOBAL ID is published.
        if (tMod.accepted) then
            for _, tEntry in ipairs(tMod.entries) do
                tWinners[tEntry.blueprint.id] = tEntry;
            end
        end
    end

    -- Step 3: publish only winners under their exact classes, clearing stale routes.
    for sID, tEntry in pairs(tWinners) do
        tNodes[tEntry.class][sBlueprints][sID] = tEntry;
    end
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Methods.finalizeImports
    @desc Excludes missing/inactive dependency chains, applies first-loaded-wins conflicts, then
    reconsiders conflicts when winners lose requirements. Publishes only the stable accepted
    catalog.
    @ret table tReport Accepted and rejected mod counts.
    @vis static public
!]]
local function finalizeImports()
    -- Step 1: initialize independent eligibility and diagnostic sets.
    local tUnavailable = {};
    local tAccepted = {};
    local tReasons = {};

    -- Missing/inactive dependency chains are eliminated BEFORE conflicts.
    for _, sID in ipairs(tModOrder) do
        local tMod = tMods[sID];
        tMod.accepted = false;

        if (tMod.requested) then
            local bOK, sReason = collectRequirements(sID, {}, {});

            if (not bOK) then
                tUnavailable[sID] = true;
                tReasons[sID] = sReason;
            end
        else
            tUnavailable[sID] = true;
            tReasons[sID] = "Mod is inactive.";
        end
    end

    -- Conflict losers are provisional. If a winner loses a required mod,
    -- remove that winner and reconsider the conflicts it used to cause.
    -- Each pass removes at least one dependency-invalid candidate, so this
    -- process terminates without changing the host's load order.
    local bChanged = true;

    while (bChanged) do
        bChanged = false;
        tAccepted = {};

        -- Step 2: choose provisional conflict winners in the original host order.
        for _, sID in ipairs(tModOrder) do
            if (not tUnavailable[sID]) then
                local tMod = tMods[sID];
                local sReason;

                if (tMod.conflicts[sID]) then
                    sReason = "Mod declares a conflict with itself.";
                else
                    for _, sEarlier in ipairs(tModOrder) do
                        if (tAccepted[sEarlier] and modsConflict(tMod, tMods[sEarlier])) then
                            sReason = "Conflicts with earlier mod '"..tMods[sEarlier].name
                                       .."' ("..sEarlier..").";
                            break;
                        end
                    end
                end

                if (sReason) then
                    tReasons[sID] = sReason;
                else
                    tAccepted[sID] = true;
                    tReasons[sID] = nil;
                end
            end
        end

        -- Step 3: exclude winners whose requirements lost, then reconsider their conflicts.
        for _, sID in ipairs(tModOrder) do
            if (tAccepted[sID]) then
                for sRequired in pairs(tMods[sID].required) do
                    if (not tAccepted[sRequired]) then
                        tUnavailable[sID] = true;
                        tReasons[sID] = "Missing or rejected required mod: "..sRequired..".";
                        bChanged = true;
                        break;
                    end
                end
            end
        end
    end

    -- Step 4: commit stable acceptance and log excluded mods with their reasons.
    local tReport = { accepted = 0, rejected = 0 };

    for _, sID in ipairs(tModOrder) do
        local tMod = tMods[sID];
        tMod.accepted = tAccepted[sID] == true;
        tMod.reason = tReasons[sID];

        if (tMod.accepted) then
            tReport.accepted = tReport.accepted + 1;
        else
            tReport.rejected = tReport.rejected + 1;
            warn("Mod '"..tMod.name.."' ("..sID..") rejected: "..tostring(tMod.reason));
        end
    end

    -- Step 5: publish the stable catalog and unblock queries.
    publishCatalog();
    bDirty = false;
    return tReport;
end

--[[!
    @fqxn CoG.ModSystem.Factorium.Helpers.ensureFinalized
    @desc Blocks queries after staged lifecycle/import changes to prevent stale catalog results.
    @ret boolean bReady Whether the visible catalog is current.
    @ret string|nil sReason Instruction to finalize pending changes.
    @scope local
!]]
local function ensureFinalized()
    -- Pending changes must not leave stale winners visible to callers.
    if (bDirty) then
        return false, "Call finalizeImports after changing the imported mod set.";
    end

    return true;
end

--[[!
    @fqxn CoG.ModSystem.Factorium
    @desc A repository of compiled CoG blueprint definitions, NOT an object
    factory. Classes register themselves. Defaults merge from CoG down to the
    target class; every ancestor validator must accept the completed table.
    Functions remain values during import. Queries require an exact class
    reference and never return class objects. Callers construct objects using
    their class's fromBlueprint method.
    @ex
    Factorium.setEnvironment(tModEnvironment);
    Factorium.loadMod("mods/CoolDragons.lua");
    Factorium.runMods();
    Factorium.finalizeImports();
    local tBlueprint = Factorium.getBlueprint(Dragon, "fire_dragon");
    local oDragon = Dragon.fromBlueprint(tBlueprint, tSpawnContext);
!]]
return class("Factorium",
{}, --METAMETHODS
{--STATIC PUBLIC
    -- Named implementations above carry the full Dox contracts and import steps.
    registerClass = registerClass,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.isClassRegistered
        @desc Checks the exact class against the private allowlist without exposing contract data.
        @param class cClass Class reference supplied by the caller.
        @ret boolean bRegistered Whether the class registered successfully.
        @vis static public
    !]]
    isClassRegistered = function(cClass)
        -- Answer membership without returning private registration data.
        return tClasses[cClass] ~= nil;
    end,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.setEnvironment
        @desc Replaces the environment reference for subsequent loads. Starts as an empty table;
        already loaded chunks and functions retain their original environment.
        @param table tEnv Host-chosen mod execution environment.
        @ret boolean bSuccess Whether the environment was accepted.
        @ret string|nil sReason Invalid-input explanation.
        @vis static public
    !]]
    setEnvironment = function(tEnv)
        -- Validate the supplied container before replacing the reference.
        if (rawtype(tEnv) ~= "table") then
            return reject("Environment must be a table.");
        end

        -- Existing loaded functions retain their original environment.
        -- Keep the actual host table; its bindings remain under host control.
        tEnvironment = tEnv;
        return true;
    end,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.setLog
        @desc Sets a logging function or object with a dot-call log method. Objects receive message
        and BaseLog warning level. Passing nil selects lazy BaseLog fallback.
        @param function|table|nil log Logging callback/object; nil selects BaseLog.
        @ret boolean bSuccess Whether the destination was accepted.
        @ret string|nil sReason Invalid-logger explanation.
        @vis static public
    !]]
    setLog = function(log)
        -- Step 1: accept a callback directly or safely inspect an object method.
        if (log ~= nil and rawtype(log) ~= "function") then
            local bOK, bValid = pcall(function()
                -- Some log objects reject unknown members, so inspect safely.
                return rawtype(log.log) == "function";
            end);

            if (not bOK or not bValid) then
                return reject("Log must be a method or an object with a log method.");
            end
        end

        -- Step 2: replace the destination; nil selects the lazy default again.
        vLog = log;

        -- BaseMod construction shares the program-supplied destination.
        BaseMod.setLog(log);
        return true;
    end,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.getWarnings
        @desc Returns a copy of all retained warning strings, including messages whose external
        logging failed.
        @ret table tMessages Ordered warning strings.
        @vis static public
    !]]
    getWarnings = function()
        -- Copy the list so callers cannot erase retained diagnostics.
        return copyTable(tWarnings, {});
    end,

    -- Loading compiles only. Running executes queued chunks in host order.
    -- Text-only loading uses exactly the environment reference provided.
    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.loadMod
        @desc Compiles a text mod file in the current environment and queues it without executing.
        Failures are logged and never queued.
        @param string sPath Lua mod-file path.
        @ret boolean bLoaded Whether the chunk was queued.
        @ret string|nil sReason Load or argument failure.
        @vis static public
    !]]
    loadMod = function(sPath)
        if (not isNonblank(sPath)) then
            return reject("Mod path must be a nonblank string.");
        end

        -- Step 1: compile text without executing, capturing the current environment.
        local bOK, fChunk, sReason = pcall(loadfile, sPath, "t", tEnvironment);

        if (not bOK) then
            sReason = tostring(fChunk);
            fChunk = nil;
        end

        if (not fChunk) then
            return reject("Mod file '"..sPath.."' could not load: "..tostring(sReason));
        end

        -- Step 2: enqueue successful chunks in the order supplied by the host.
        tPendingFiles[#tPendingFiles + 1] = { path = sPath, chunk = fChunk };
        return true;
    end,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.runMods
        @desc Consumes the queued chunks in host order, importing their returned mod tables.
        Execution failures skip only the affected file. Finalization remains explicit.
        @ret table tReport Loaded and skipped mod-file counts.
        @vis static public
    !]]
    runMods = function()
        local tReport = { loaded = 0, skipped = 0 };
        -- Step 1: consume this queue so each file runs once per invocation.
        local tQueue = tPendingFiles;
        tPendingFiles = {};

        -- Step 2: isolate execution, then import each returned definition table.
        for _, tFile in ipairs(tQueue) do
            local bOK, tDefinition = pcall(tFile.chunk);

            if (bOK) then
                bOK = importMod(tDefinition);
            else
                warn("Mod file '"..tFile.path.."' failed: "..tostring(tDefinition));
            end

            if (bOK) then
                tReport.loaded = tReport.loaded + 1;
            else
                tReport.skipped = tReport.skipped + 1;
            end
        end

        -- Step 3: report file outcomes; publication remains a separate finalization step.
        return tReport;
    end,

    importMod = importMod,
    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.replaceMod
        @desc Uses the import pipeline for replacement without changing load position or requested
        state. Invalid metadata leaves the old mod intact; failed blueprint replacements retain
        matching old definitions.
        @param table|BaseMod tInput Replacement mod data with the existing UUID.
        @ret boolean bImported Whether metadata was accepted.
        @ret table|string tReport Loaded/skipped counts, or rejection reason.
        @vis static public
    !]]
    replaceMod = importMod,
    finalizeImports = finalizeImports,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.setModActive
        @desc Changes requested eligibility without calling BaseMod lifecycle hooks. Requires
        finalizeImports to recompute dependencies, conflicts and visible definitions.
        @param string sID Mod UUID to inspect or update.
        @param boolean bActive Requested active state.
        @ret boolean bSuccess Whether the requested state changed.
        @ret string|nil sReason Unknown mod or invalid arguments.
        @vis static public
    !]]
    setModActive = function(sID, bActive)
        -- Step 1: resolve the imported UUID and validate the requested state.
        local tMod = tMods[normalizeID(sID)];

        if (not tMod or rawtype(bActive) ~= "boolean") then
            return reject("setModActive requires an imported mod ID and a boolean.");
        end

        -- Step 2: change eligibility request and defer acceptance to finalization.
        tMod.requested = bActive;
        bDirty = true;
        return true;
    end,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.removeMod
        @desc Removes a mod and its retained history from load order. Finalization must then restore
        earlier overrides and reevaluate dependents.
        @param string sID Mod UUID to inspect or update.
        @ret boolean bRemoved False when the mod is not imported.
        @vis static public
    !]]
    removeMod = function(sID)
        sID = normalizeID(sID);

        if (not tMods[sID]) then
            return false;
        end

        -- Step 1: discard this mod's retained history and ordering slot.
        tMods[sID] = nil;

        for nIndex, sOrderedID in ipairs(tModOrder) do
            if (sOrderedID == sID) then
                table.remove(tModOrder, nIndex);
                break;
            end
        end

        -- Step 2: require rebuilding visibility and dependent eligibility.
        bDirty = true;
        return true;
    end,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.getModStatus
        @desc Returns a new status record. Active means requested state; accepted is false while
        pending, and reason may describe the preceding finalization.
        @param string sID Mod UUID to inspect or update.
        @ret table|nil tStatus ID, name, active, accepted, pending and reason; nil for an unknown
        mod.
        @vis static public
    !]]
    getModStatus = function(sID)
        -- Resolve the normalized mod identity, returning nil when absent.
        local tMod = tMods[normalizeID(sID)];

        if (not tMod) then
            return nil;
        end

        -- Return fresh scalar status data, not the private mod record.
        return {
            id       = tMod.id,
            name     = tMod.name,
            active   = tMod.requested,
            accepted = not bDirty and tMod.accepted,
            pending  = bDirty,
            reason   = tMod.reason,
        };
    end,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.getBlueprint
        @desc Returns one definition copy for the exact registered class and its source mod ID. Does
        not traverse descendants, expose class references or create objects.
        @param class cClass Class reference supplied by the caller.
        @param string sID Global blueprint identifier within the supplied exact class.
        @ret table|nil tBlueprint Definition copy, or nil if missing/pending.
        @ret string|nil sModID Source UUID on success, or pending-finalization reason.
        @vis static public
    !]]
    getBlueprint = function(cClass, sID)
        -- Step 1: require a current catalog before inspecting visible entries.
        local bReady, sReason = ensureFinalized();

        if (not bReady) then
            return nil, sReason;
        end

        -- Step 2: look only in the exact class supplied by the caller.
        local tNode = tClasses[cClass] and tNodes[cClass];
        local tEntry = tNode and tNode[sBlueprints][sID];

        if (not tEntry) then
            return nil;
        end

        -- Step 3: return copied definition data and provenance, never a class reference.
        return copyTable(tEntry.blueprint, {}), tEntry.modID;
    end,

    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.getBlueprints
        @desc Returns an ID-keyed map of blueprint copies and modID records for the exact class.
        Empty/unregistered classes return an empty map; pending changes return nil.
        @param class cClass Class reference supplied by the caller.
        @ret table|nil tBlueprints Exact-class records, or nil while pending.
        @ret string|nil sReason Pending-finalization explanation.
        @vis static public
    !]]
    getBlueprints = function(cClass)
        -- Step 1: prevent a result from a stale catalog.
        local bReady, sReason = ensureFinalized();

        if (not bReady) then
            return nil, sReason;
        end

        -- Step 2: allocate a fresh map for this exact class only.
        local tResult = {};
        local tNode = tClasses[cClass] and tNodes[cClass];

        if (tNode) then
            -- Step 3: copy each definition and expose only its source mod UUID.
            for sID, tEntry in pairs(tNode[sBlueprints]) do
                tResult[sID] = {
                    blueprint = copyTable(tEntry.blueprint, {}),
                    modID     = tEntry.modID,
                };
            end
        end

        return tResult;
    end,
},
{--PRIVATE
    --[[!
        @fqxn CoG.ModSystem.Factorium.Methods.Factorium
        @desc Private empty constructor; access the repository through static methods.
        @param Factorium this Instance under construction.
        @param table cdat LuaEx class data.
        @vis private
    !]]
    Factorium = function(this, cdat) end,
},
{}, --PROTECTED
{}, --PUBLIC
nil,   --extending class
false, --if the class is final
nil    --interfaces
);
