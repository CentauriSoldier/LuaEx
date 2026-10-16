--LOCALIZATION
local assert       = assert;
local error        = error;
local next         = next;
local rawget       = rawget;
local rawtype      = rawtype;
local require      = require;
local setmetatable = setmetatable;
local string       = string;

local find   = string.find;
local gmatch = string.gmatch;
local gsub   = string.gsub;
local lower  = string.lower;
local match  = string.match;
local sub    = string.sub;

local _tSerializer = require("LuaEx.lib.serializer");
local _tInstances  = setmetatable({}, {__mode = "k"});
local _xTextCatalog = {};

--[[!
    @fqxn LuaEx.Libraries.textcatalog
    @desc A central text catalog with fixed node/key structure and editable text
    templates. Names, paths, searches and variables are case-insensitive using
    string.lower; declared keys and original text keep their spelling. Input
    tables are copied. Keys must be nonblank strings without dots; dots separate
    path segments. Values must be strings or nested tables. Empty nodes are valid.
    Each instance owns persistent string variables and an active node, initially
    the root. Omitted scope uses that node; an explicit scope resolves from the
    root, with "" selecting the root. Exact text keys resolve within that scope.
    Searches use literal substrings in stored templates/names, then substitute
    variables in results. Ambiguous matches have no guaranteed order. Unset
    ${name} placeholders stay visible; $${name} outputs a literal ${name}.
    Replacements are literal and never chain. Node results are fresh snapshots.
    Setters return the catalog for chaining. Invalid writes raise errors before
    changing state. Ordinary member/metatable writes are blocked; explicit rawset
    and debug bypasses are outside this table-proxy contract. Clone/deserialization
    create independent catalogs, retaining templates, variables and active scope.
    @ex
    local oDialogue = textcatalog({dialogue = {merchant = {
        greeting = "Hello ${player}! Your friend ${friend} was just here.",
    }}});
    oDialogue.setvar("player", "Mira");
    oDialogue.setvar("friend", "Elian");
    oDialogue.setactivenode("dialogue.merchant");
    local sGreeting = oDialogue.gettext("greeting");
!]]

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.modifyError
    @scope local
    @desc Rejects direct changes to catalogs, the factory and public metadata.
!]]
local function modifyError()
    error("Text catalog members are read-only; use the catalog methods to change text, variables or active scope.", 2);
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.publicMeta
    @scope local
    @desc Provides a read-only type view without exposing private state or hooks.
    @param string sType The instance or factory type name.
    @ret table tView Protected public type metadata.
!]]
local function publicMeta(sType)
    return setmetatable({}, {
        __index     = {__type = sType},
        __newindex  = modifyError,
        __metatable = false,
    });
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.validateKey
    @scope local
    @desc Validates a declared key without trimming or changing its spelling.
    @param string sName A nonblank key without the path separator.
!]]
local function validateKey(sName)
    assert(rawtype(sName) == "string" and match(sName, "%S") and not find(sName, ".", 1, true),
           "Text catalog keys must be nonblank strings without dots.");
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.validateVar
    @scope local
    @desc Requires a nonblank variable name that can appear inside ${name}.
    @param string sName The variable name; braces are not allowed.
!]]
local function validateVar(sName)
    assert(rawtype(sName) == "string" and match(sName, "%S") and not find(sName, "[{}]"),
           "Text catalog variable names must be nonblank strings without braces.");
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.buildNode
    @scope local
    @desc Copies and validates an input tree into private records with folded-key
    child lookup. Rejects cycles, case-only sibling duplicates and unsupported
    values. Shared input tables become independent nodes at their separate paths.
    Input metamethods are not invoked when reading keys and values.
    @param table tInput The source node.
    @param string sPath The full declared path; "" denotes the root.
    @param table tActive Tables on the current recursion path.
    @ret table tNode A private node record.
!]]
local function buildNode(tInput, sPath, tActive)
    assert(rawtype(tInput) == "table", "Text catalog nodes must be tables.");
    assert(not tActive[tInput], "Text catalog definitions cannot contain cycles.");

    local tNode = {path = sPath, children = {}};

    tActive[tInput] = true;

    for sName, vEntry in next, tInput do
        validateKey(sName);

        local sKey       = lower(sName);
        local sEntryPath = sPath == "" and sName or sPath.."."..sName;
        local tEntry;

        assert(not tNode.children[sKey], "Duplicate case-insensitive text catalog key: "..sEntryPath);

        if (rawtype(vEntry) == "table") then
            tEntry = buildNode(vEntry, sEntryPath, tActive);
        else
            assert(rawtype(vEntry) == "string", "Text catalog entries must be strings or nodes: "..sEntryPath);

            tEntry = {path = sEntryPath, text = vEntry};
        end

        tEntry.name          = sName;
        tNode.children[sKey] = tEntry;
    end

    tActive[tInput] = nil;

    return tNode;
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.resolve
    @scope local
    @desc Resolves a case-insensitive dotted path from a supplied private node.
    Empty paths select that node. Malformed paths, missing entries and descent
    through text entries return nil. This function never changes active scope.
    @param table tNode The starting node.
    @param string sPath The path to resolve.
    @ret table|nil tEntry The private node/text record, or nil.
!]]
local function resolve(tNode, sPath)
    assert(rawtype(sPath) == "string", "Text catalog paths must be strings.");

    if (sPath == "") then
        return tNode;
    end

    if (sub(sPath, 1, 1) == "." or sub(sPath, -1) == "." or find(sPath, "..", 1, true)) then
        return nil;
    end

    local tEntry = tNode;

    for sSegment in gmatch(sPath, "[^.]+") do
        tEntry = tEntry.children and tEntry.children[lower(sSegment)];

        if (not tEntry) then
            return nil;
        end
    end

    return tEntry;
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.scope
    @scope local
    @desc Selects the active node for an omitted scope, or resolves an explicit
    root-relative path. Text entries cannot serve as a node scope.
    @param table tState The catalog state.
    @param string|nil sPath The explicit scope, or nil for the active node.
    @ret table|nil tNode The resolved node, or nil.
!]]
local function scope(tState, sPath)
    local tNode = sPath == nil and tState.active or resolve(tState.root, sPath);

    return tNode and tNode.children and tNode or nil;
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.render
    @scope local
    @desc Applies persistent variables once. Missing variables retain their whole
    placeholder. Escaped placeholders become literal text. Callback return values
    are inserted literally, so percent signs, braces and further placeholders in
    a replacement cannot trigger formatting or another replacement pass.
    @param string sText The stored template.
    @param table tVars Case-folded variable names mapped to string values.
    @ret string sResult The formatted text; the template remains unchanged.
!]]
local function render(sText, tVars)
    local function fReplace(sPrefix, sName)

        if (sPrefix == "$$") then
            return "${"..sName.."}";
        end

        return tVars[lower(sName)] or "${"..sName.."}";
    end

    local sResult = gsub(sText, "(%$%$?)%{([^{}]+)%}", fReplace);

    return sResult;
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.snapshot
    @scope local
    @desc Copies a node into nested tables with declared keys. A variable table
    requests rendered values; nil requests the original stored templates for
    copying or persistence. Returned tables never expose private records.
    @param table tNode The private node to copy.
    @param table|nil tVars Replacement variables, or nil for raw templates.
    @ret table tResult An independent nested table.
!]]
local function snapshot(tNode, tVars)
    local tResult = {};

    for _, tEntry in next, tNode.children do

        if (tEntry.children) then
            tResult[tEntry.name] = snapshot(tEntry, tVars);
        else
            tResult[tEntry.name] = tVars and render(tEntry.text, tVars) or tEntry.text;
        end

    end

    return tResult;
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.search
    @scope local
    @desc Recursively finds the first descendant whose stored text or node name
    contains the case-folded literal query. No ordering index is maintained;
    ambiguity intentionally has no guaranteed order. Text searches do not search
    substituted values. Node searches consider containers, including empty nodes.
    @param table tNode The private scope node.
    @param string sQuery The case-folded search text.
    @param boolean bNodes Whether to search node names instead of stored text.
    @ret table|nil tEntry The first matching private record, or nil.
!]]
local function search(tNode, sQuery, bNodes)
    for _, tEntry in next, tNode.children do

        if (tEntry.children) then

            if (bNodes and find(lower(tEntry.name), sQuery, 1, true)) then
                return tEntry;
            end

            local tFound = search(tEntry, sQuery, bNodes);

            if (tFound) then
                return tFound;
            end

        elseif (not bNodes and find(lower(tEntry.text), sQuery, 1, true)) then
            return tEntry;
        end

    end

    return nil;
end

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.savedState
    @scope local
    @desc Copies templates, variables and the full active-node path. Values are
    deliberately saved before replacement so later variable edits remain useful.
    @param table tState The private catalog state.
    @ret table tSaved Independent version-one persistence state.
!]]
local function savedState(tState)
    local tVars = {};

    for sName, sValue in next, tState.vars do
        tVars[sName] = sValue;
    end

    return {
        version = 1,
        entries = snapshot(tState.root, nil),
        vars    = tVars,
        active  = tState.active.path,
    };
end

local buildCatalog;
local deserialize;

--[[!
    @fqxn LuaEx.Libraries.textcatalog.__call
    @pulsarlua function textcatalog
    @desc Creates an independent catalog from a nested table of text templates.
    The hierarchy is copied and fixed, variables start empty, and scope starts
    at the root. Dot-call methods retain their catalog through private closures.
    @param table tEntries The complete named text/node definition.
    @ret textcatalog oCatalog The new catalog.
!]]
buildCatalog = function(tEntries)
    local oCatalog = {};
    local tState   = {root = buildNode(tEntries, "", {}), vars = {}};
    local tMethods = {};

    tState.active = tState.root;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.gettext
        @desc Retrieves an exact text key relative to the active or explicit node.
        Applies current variables. Missing keys, nodes and invalid scopes return nil.
        @param string sKey The dotted text key within the selected scope.
        @param string|nil sPath Optional root-relative scope; "" selects the root.
        @ret string|nil sText The rendered text, or nil.
    !]]
    tMethods.gettext = function(sKey, sPath)
        assert(rawtype(sKey) == "string", "Text catalog text keys must be strings.");

        local tNode  = scope(tState, sPath);
        local tEntry = tNode and resolve(tNode, sKey);

        return tEntry and tEntry.text and render(tEntry.text, tState.vars) or nil;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.settext
        @desc Replaces an existing string template without changing its path or
        the hierarchy. Stores the supplied text verbatim, without substitution.
        Invalid keys/scopes, nodes and non-string values raise before mutation.
        @param string sKey The dotted text key within the selected scope.
        @param string sText The replacement template; an empty string is valid.
        @param string|nil sPath Optional root-relative scope; nil uses active scope.
        @ret textcatalog oCatalog This catalog, for method chaining.
    !]]
    tMethods.settext = function(sKey, sText, sPath)
        assert(rawtype(sKey) == "string", "Text catalog text keys must be strings.");
        assert(rawtype(sText) == "string", "Text catalog replacement text must be a string.");

        local tNode  = scope(tState, sPath);
        local tEntry = tNode and resolve(tNode, sKey);

        assert(tEntry and tEntry.text ~= nil, "settext requires an existing text entry in a valid node.");

        tEntry.text = sText;

        return oCatalog;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.getnode
        @desc Returns a fresh nested snapshot with current substitutions. Omitted
        path selects the active node; explicit paths start at the root. Missing
        nodes and paths naming text entries return nil.
        @param string|nil sPath The root-relative node path, or nil for active scope.
        @ret table|nil tNode The rendered snapshot, or nil.
    !]]
    tMethods.getnode = function(sPath)
        local tNode = scope(tState, sPath);

        return tNode and snapshot(tNode, tState.vars) or nil;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.findtext
        @desc Finds the first stored template containing the literal query,
        ignoring case, within the selected node and all descendants. Substitutes
        only after matching. No match returns nil and the valid scope's full path;
        invalid scope returns nil, nil. An omitted path uses active scope.
        @param string sText The search substring; an empty string matches any text.
        @param string|nil sPath Optional root-relative scope.
        @ret string|nil sResult The rendered matching template, or nil.
        @ret string|nil sFoundPath The entry path, valid scope path, or nil.
    !]]
    tMethods.findtext = function(sText, sPath)
        assert(rawtype(sText) == "string", "Text catalog searches require a string.");

        local tNode = scope(tState, sPath);

        if (not tNode) then
            return nil, nil;
        end

        local tEntry = search(tNode, lower(sText), false);

        if (tEntry) then
            return render(tEntry.text, tState.vars), tEntry.path;
        end

        return nil, tNode.path;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.findnode
        @desc Finds the first descendant container whose declared local name
        contains the literal query, ignoring case. The scope itself is not a
        descendant. Returns a rendered snapshot and full path. No match returns
        nil and the valid scope path; invalid scope returns nil, nil.
        @param string sName The node-name substring; an empty string matches any node.
        @param string|nil sPath Optional root-relative scope; nil uses active scope.
        @ret table|nil tNode The matching snapshot, or nil.
        @ret string|nil sFoundPath The matched node path, valid scope path, or nil.
    !]]
    tMethods.findnode = function(sName, sPath)
        assert(rawtype(sName) == "string", "Text catalog node searches require a string.");

        local tNode = scope(tState, sPath);

        if (not tNode) then
            return nil, nil;
        end

        local tEntry = search(tNode, lower(sName), true);

        if (tEntry) then
            return snapshot(tEntry, tState.vars), tEntry.path;
        end

        return nil, tNode.path;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.setvar
        @desc Sets a persistent string variable for this catalog. Names ignore
        case; all subsequent results use its current value. Values remain literal
        and may be empty. Non-string names/values and invalid names raise errors.
        @param string sName The placeholder name without ${}.
        @param string sValue The literal replacement value.
        @ret textcatalog oCatalog This catalog, for method chaining.
    !]]
    tMethods.setvar = function(sName, sValue)
        validateVar(sName);
        assert(rawtype(sValue) == "string", "Text catalog variable values must be strings.");

        tState.vars[lower(sName)] = sValue;

        return oCatalog;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.clearvar
        @desc Removes a variable by case-insensitive name. An already-missing
        variable is harmless; its placeholders remain visible in future results.
        @param string sName The variable name to remove.
        @ret textcatalog oCatalog This catalog, for method chaining.
    !]]
    tMethods.clearvar = function(sName)
        validateVar(sName);

        tState.vars[lower(sName)] = nil;

        return oCatalog;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.clearvars
        @desc Removes all variables without changing text templates or active scope.
        @ret textcatalog oCatalog This catalog, for method chaining.
    !]]
    tMethods.clearvars = function()
        tState.vars = {};

        return oCatalog;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.setactivenode
        @desc Sets the default scope using a root-relative node path. Nil or ""
        resets to the root. Invalid paths or text-entry paths raise an error and
        leave the previous active node unchanged. Explicit per-call scopes never
        change this selection.
        @param string|nil sPath The node path, or nil to reset to the root.
        @ret textcatalog oCatalog This catalog, for method chaining.
    !]]
    tMethods.setactivenode = function(sPath)
        local tNode = sPath == nil and tState.root or scope(tState, sPath);

        assert(tNode, "Active text catalog scope must be an existing node.");

        tState.active = tNode;

        return oCatalog;
    end;

    --[[!
        @fqxn LuaEx.Libraries.textcatalog.Methods.getactivenode
        @desc Returns a fresh rendered snapshot and the declared full active path.
        The root's path is "". Snapshot edits do not change catalog state.
        @ret table tNode The active node's rendered snapshot.
        @ret string sPath The full active-node path.
    !]]
    tMethods.getactivenode = function()
        return snapshot(tState.active, tState.vars), tState.active.path;
    end;

    _tInstances[oCatalog] = tState;

    setmetatable(oCatalog, {
        __index = tMethods,
        __newindex = modifyError,
        __clone = function()
            return deserialize(savedState(tState));
        end,
        __serialize = function()
            return savedState(tState);
        end,
        __type      = "textcatalog",
        __metatable = publicMeta("textcatalog"),
    });

    return oCatalog;
end;

--[[!
    @fqxn LuaEx.Libraries.textcatalog.Helpers.deserialize
    @scope local
    @desc Validates saved state and constructs an independent catalog. Restores
    raw templates, string variables and active scope without applying variables
    to the saved templates. Does not change any existing catalog on failure.
    @param table tSaved The state {version = 1, entries, vars, active}.
    @ret textcatalog oCatalog The restored independent catalog.
!]]
deserialize = function(tSaved)
    assert(rawtype(tSaved) == "table", "Saved text catalog state must be a table.");

    for sField in next, tSaved do
        assert(sField == "version" or sField == "entries" or sField == "vars" or sField == "active",
               "Unknown saved text catalog field.");
    end

    assert(rawget(tSaved, "version") == 1, "Unsupported saved text catalog version.");

    local tVars   = rawget(tSaved, "vars");
    local sActive = rawget(tSaved, "active");

    assert(rawtype(tVars) == "table", "Saved text catalog variables must be a table.");
    assert(rawtype(sActive) == "string", "Saved text catalog active path must be a string.");

    -- Validate all variable names/values before constructing the new catalog.
    local tSeen = {};

    for sName, sValue in next, tVars do
        validateVar(sName);
        assert(rawtype(sValue) == "string", "Saved text catalog variable values must be strings.");

        local sKey = lower(sName);

        assert(not tSeen[sKey], "Duplicate case-insensitive saved text catalog variable.");

        tSeen[sKey] = true;
    end

    local oCatalog = buildCatalog(rawget(tSaved, "entries"));
    local tState   = _tInstances[oCatalog];
    local tActive  = scope(tState, sActive);

    assert(tActive, "Saved text catalog active node does not exist.");

    for sName, sValue in next, tVars do
        tState.vars[lower(sName)] = sValue;
    end

    tState.active = tActive;

    return oCatalog;
end;

setmetatable(_xTextCatalog, {
    __call = function(_, tEntries)
        return buildCatalog(tEntries);
    end,
    __newindex = modifyError,
    __clone = function()
        return _xTextCatalog;
    end,
    __type      = "textcatalogfactory",
    __metatable = publicMeta("textcatalogfactory"),
});

-- Declare factory persistence here, keeping catalog knowledge out of the codec.
_tSerializer.registerFactory(_xTextCatalog, {
    name    = "textcatalog",
    types   = {"textcatalog"},
    restore = deserialize,
});

return _xTextCatalog;
