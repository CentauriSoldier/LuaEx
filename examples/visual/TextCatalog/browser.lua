--LOCALIZATION
local assert      = assert;
local clone       = clone;
local deserialize = deserialize;
local error       = error;
local ipairs      = ipairs;
local next        = next;
local pcall       = pcall;
local rawtype     = rawtype;
local require     = require;
local select      = select;
local serialize   = serialize;
local string      = string;
local table       = table;
local textcatalog = textcatalog;
local tostring    = tostring;

local lower  = string.lower;
local remove = table.remove;

local _tDefinition = require("examples.visual.TextCatalog.definition");
local _tRecords    = {};
local _tHistory    = {};
local _nSelected   = 1;
local _sMessage    = "Choose a node, set variables, and explore the catalog.";
local _tResult     = {kind = "none", found = false};
local _sSaved      = "";
local _tSavedMeta;
local _sSelectedPath;

--[[!
    @fqxn Examples.TextCatalog.record
    @scope local
    @desc Displays the latest result and keeps a bounded operation journal.
    @param string sMessage The operation summary.
!]]
local function record(sMessage)
    _sMessage = sMessage;
    _tHistory[#_tHistory + 1] = sMessage;

    if (#_tHistory > 25) then
        remove(_tHistory, 1);
    end
end

--[[!
    @fqxn Examples.TextCatalog.templates
    @scope local
    @desc Flattens known example source templates for the inspector. This is an
    application-owned mirror, not a private catalog hook or alternate text engine.
    @param table tNode The example's source definition.
    @param string sPath The current full path.
    @param table tResult The template lookup to populate.
!]]
local function templates(tNode, sPath, tResult)
    for sName, vEntry in next, tNode do
        local sEntryPath = sPath == "" and sName or sPath.."."..sName;

        if (rawtype(vEntry) == "table") then
            templates(vEntry, sEntryPath, tResult);
        else
            tResult[sEntryPath] = vEntry;
        end
    end
end

--[[!
    @fqxn Examples.TextCatalog.reset
    @scope local
    @desc Creates two independent catalogs with the same definitions but separate
    variable values. Neither catalog is a view into the other catalog's state.
!]]
local function reset()
    _tRecords      = {};
    _tHistory      = {};
    _nSelected     = 1;
    _sSaved        = "";
    _tSavedMeta    = nil;
    _sSelectedPath = "dialogue.merchant.greeting";
    _tResult       = {kind = "none", found = false};

    for nIndex, sName in ipairs({"Main conversation", "Other conversation"}) do
        local oCatalog   = textcatalog(_tDefinition);
        local tTemplates = {};
        local tVariables = {
            player = nIndex == 1 and "Mira" or "Tomas",
            friend = nIndex == 1 and "Elian" or "Rowan",
            price  = "25",
            amount = "10",
        };

        templates(_tDefinition, "", tTemplates);

        for sVariable, sValue in next, tVariables do
            oCatalog.setvar(sVariable, sValue);
        end

        _tRecords[nIndex] = {
            name      = sName,
            catalog   = oCatalog,
            templates = tTemplates,
            variables = tVariables,
        };
    end

    record("Two fresh catalogs. Root is active; each conversation owns its variables.");
end

--[[!
    @fqxn Examples.TextCatalog.rows
    @scope local
    @desc Turns a public rendered snapshot into tree rows for display. The UI may
    order these rows for navigation; that order never determines library search.
    @param table tNode The public snapshot.
    @param string sPath The parent path.
    @param number nDepth The display nesting depth.
    @param table tRows The output rows.
    @param table tTemplates The application-owned source template mirror.
!]]
local function rows(tNode, sPath, nDepth, tRows, tTemplates)
    for sName, vEntry in next, tNode do
        local sEntryPath = sPath == "" and sName or sPath.."."..sName;
        local bNode      = rawtype(vEntry) == "table";

        tRows[#tRows + 1] = {
            name     = sName,
            path     = sEntryPath,
            depth    = nDepth,
            kind     = bNode and "node" or "text",
            rendered = bNode and "" or vEntry,
            template = bNode and "" or tTemplates[sEntryPath],
        };

        if (bNode) then
            rows(vEntry, sEntryPath, nDepth + 1, tRows, tTemplates);
        end
    end
end

--[[!
    @fqxn Examples.TextCatalog.view
    @scope local
    @desc Reads real public catalog snapshots and exports plain display state.
    @ret table tState The current catalog browser and inspector state.
!]]
local function view()
    local tRecord  = _tRecords[_nSelected];
    local oCatalog = tRecord.catalog;
    local tActive, sActive = oCatalog.getactivenode();
    local tState = {
        visual    = "textcatalog",
        selected  = _nSelected,
        catalogs  = {},
        active    = sActive,
        snapshot  = tActive,
        rows      = {},
        variables = {},
        message   = _sMessage,
        result    = clone(_tResult),
        history   = clone(_tHistory),
        saved     = _sSaved,
        selection = {
            path     = _sSelectedPath,
            template = tRecord.templates[_sSelectedPath],
            rendered = oCatalog.gettext(_sSelectedPath, ""),
        },
    };

    for nIndex, tOther in ipairs(_tRecords) do
        tState.catalogs[#tState.catalogs + 1] = {
            id       = nIndex,
            name     = tOther.name,
            greeting = tOther.catalog.gettext("dialogue.merchant.greeting", ""),
        };
    end

    for sName, sValue in next, tRecord.variables do
        tState.variables[#tState.variables + 1] = {name = sName, value = sValue};
    end

    rows(oCatalog.getnode(""), "", 0, tState.rows, tRecord.templates);

    return tState;
end

--[[!
    @fqxn Examples.TextCatalog.workbench_action
    @desc Routes UI requests to real lowercase public methods. The optional scope
    flag distinguishes omitted scope from an explicit empty-string root scope.
    Expected errors are displayed without discarding the catalog or current inputs.
    @param string sAction The requested operation.
    @param table tData The operation arguments.
    @ret table tState The refreshed browser state.
!]]
function workbench_action(sAction, tData)
    local tData = tData or {};

    local function fApply()
        if (sAction == "view") then return; end
        if (sAction == "reset") then reset(); return; end

        if (sAction == "select") then
            assert(_tRecords[tData.id], "Unknown conversation.");
            _nSelected = tData.id;
            _tResult   = {kind = "none", found = false};
            return;
        end

        local tRecord  = _tRecords[_nSelected];
        local oCatalog = tRecord.catalog;
        local sScope;

        if (not tData.useactive) then
            sScope = tData.scope or "";
        end

        if (sAction == "active") then
            if (tData.reset) then
                oCatalog.setactivenode(nil);
            else
                oCatalog.setactivenode(tData.path);
            end
            record("Active node: "..select(2, oCatalog.getactivenode())..". Explicit per-call scopes still start at the root.");

        elseif (sAction == "inspect") then
            local sMethod = tData.method;
            local vValue, sPath;

            if (sMethod == "getnode") then
                vValue = oCatalog.getnode(sScope);
                sPath  = vValue ~= nil and sScope or nil;

                if (vValue ~= nil and tData.useactive) then
                    sPath = select(2, oCatalog.getactivenode());
                end
            elseif (sMethod == "gettext") then
                vValue = oCatalog.gettext(tData.query, sScope);
            else
                assert(sMethod == "findtext" or sMethod == "findnode", "Choose a public lookup method.");
                vValue, sPath = oCatalog[sMethod](tData.query, sScope);
            end

            _tResult = {
                kind  = (sMethod == "getnode" or sMethod == "findnode") and "node" or "text",
                found = vValue ~= nil,
                value = vValue,
                path  = sPath,
            };
            record(sMethod.." completed. Search returns the full matched path, valid scope path on no match, or nil for invalid scope.");

        elseif (sAction == "selecttext") then
            assert(tRecord.templates[tData.path] ~= nil, "Choose an existing text entry.");
            _sSelectedPath = tData.path;

        elseif (sAction == "settext") then
            assert(rawtype(tData.text) == "string" and #tData.text <= 2000, "Use a template of at most 2000 characters.");
            oCatalog.settext(_sSelectedPath, tData.text, "");
            tRecord.templates[_sSelectedPath] = tData.text;
            record("Updated the stored template. The hierarchy and previously returned snapshots are unchanged.");

        elseif (sAction == "setvar") then
            assert(rawtype(tData.name) == "string" and #tData.name <= 80, "Use a variable name of at most 80 characters.");
            assert(rawtype(tData.value) == "string" and #tData.value <= 500, "Use a string value of at most 500 characters.");
            oCatalog.setvar(tData.name, tData.value);
            tRecord.variables[lower(tData.name)] = tData.value;
            record("Persistent variable updated for this conversation only. Replacements do not chain.");

        elseif (sAction == "clearvar") then
            oCatalog.clearvar(tData.name);
            tRecord.variables[lower(tData.name)] = nil;
            record("Variable cleared. Its complete placeholder remains visible.");

        elseif (sAction == "clearvars") then
            oCatalog.clearvars();
            tRecord.variables = {};
            record("All variables cleared; stored wording and active scope remain unchanged.");

        elseif (sAction == "snapshot") then
            local tSnapshot, sPath = oCatalog.getactivenode();

            tSnapshot.snapshotOnly = "This entry was added to the returned table.";
            assert(oCatalog.getnode().snapshotOnly == nil, "Snapshot edit unexpectedly changed the catalog.");
            _tResult = {kind = "node", found = true, value = tSnapshot, path = sPath};
            record("PASS: snapshotOnly exists in this result, but is absent from a fresh catalog snapshot.");

        elseif (sAction == "checkpoint") then
            _sSaved = serialize(oCatalog);
            _tSavedMeta = {templates = clone(tRecord.templates), variables = clone(tRecord.variables)};
            record("Saved through global serialize. Change text, variables or active scope, then restore.");

        elseif (sAction == "restore") then
            assert(_sSaved ~= "", "Save a checkpoint first.");

            local oRestored = deserialize(_sSaved);

            tRecord.catalog   = oRestored;
            tRecord.templates = clone(_tSavedMeta.templates);
            tRecord.variables = clone(_tSavedMeta.variables);
            _tResult          = {kind = "none", found = false};
            record("Restored through global deserialize into an independent catalog, including variables and active node.");

        elseif (sAction == "clone") then
            local nOther = _nSelected == 1 and 2 or 1;

            _tRecords[nOther].catalog   = clone(oCatalog);
            _tRecords[nOther].templates = clone(tRecord.templates);
            _tRecords[nOther].variables = clone(tRecord.variables);
            _nSelected = nOther;
            _tResult   = {kind = "none", found = false};
            record("Copied into the other conversation. Change its text or variables, then compare the original.");

        elseif (sAction == "probe") then
            local bOK, sWhy = pcall(function()

                if (tData.test == "insert") then oCatalog.settext("brandNewEntry", "Not allowed", "");
                elseif (tData.test == "node") then oCatalog.settext("dialogue", "Not a string entry", "");
                elseif (tData.test == "variable") then oCatalog.setvar("friend", 42);
                elseif (tData.test == "active") then oCatalog.setactivenode("missing.node");
                else textcatalog({Car = "one", car = "two"}); end
            end);

            assert(not bOK, "Invalid operation unexpectedly succeeded.");
            record("Expected rejection: "..tostring(sWhy));
        else
            error("Unknown text catalog action.");
        end
    end

    local bOK, sWhy = pcall(fApply);

    if (not bOK) then
        record("Rejected: "..tostring(sWhy));
    end

    return view();
end

reset();
return view();
