--[[!
    @fqxn LuaEx.Classes.VFS
    @pulsarlua class VFS
    @desc A case-sensitive, Unix-formatted namespace over LuaEx's existing io API.
    Construct with VFS(); native filesystem handling is internal. An optional
    custom backend supports specialized hosts and in-memory simulations.
    Mounts may have virtual grouping parents but cannot contain other
    mounts. Registered directories and uppercase dotted aliases can be granted to
    restricted access objects. Descendants inherit unchanged permissions.
    Uses the class system's automatic serialization and deserialization. Namespace
    state is private class data; restored instances reconnect default io callbacks
    on first filesystem use. Existing access facades belong to the original VFS.
    The host must control its Lua environment, symbolic links, junctions, concurrent
    filesystem changes and adapter correctness. This class is not an OS sandbox.
    Virtual components reject controls, backslashes and dot-directory references.
    Windows additionally rejects its reserved characters, device names and trailing
    spaces/dots. Linux and macOS use POSIX naming rules. Case folding
    uses ASCII; hosts needing Unicode portability must additionally enforce it.
    No shell commands or native handles are exposed by this module. The default
    backend rejects characters that LuaEx's quoted shell-based helpers would
    interpret: dollar signs, backticks and backslashes on Unix; percent signs,
    exclamation marks and carets on Windows; double quotes and controls on either.
    @ex local VFS = require("LuaEx.inc.classes.util.VFS");
        local oFiles = VFS();
        assert(oFiles.mount("/mods/example", pModFolder));
        local oAccess = oFiles.createAccess({
            {path = "/mods/example", permissions = {readFiles = true}},
        });
        local sText, sReason = oAccess.read("/mods/example/settings.ini");
!]]

local assert       = assert;
local class        = class;
local error        = error;
local ipairs       = ipairs;
local io           = io;
local math         = math;
local next         = next;
local os           = os;
local package      = package;
local pcall        = pcall;
local rawget       = rawget;
local rawtype      = rawtype;
local setmetatable = setmetatable;
local string       = string;
local table        = table;

-- Runtime callbacks and access facades belong to one live namespace. Persistent
-- namespace data is stored in private class fields and uses normal snapshots.
local _tRuntime      = setmetatable({}, {__mode = "k"});
local _tAccessStates = setmetatable({}, {__mode = "k"});
local _tPermissions  = {
    listDirectories   = true,
    listFiles         = true,
    recursive         = true,
    readFiles         = true,
    writeFiles        = true,
    createFiles       = true,
    overwriteFiles    = true,
    createDirectories = true,
    deleteFiles       = true,
    deleteDirectories = true,
    copyFiles         = true,
    moveFiles         = true,
};

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.filesystem
    @scope local
    @desc Builds the private default backend from existing LuaEx io helpers and
    standard file operations. Captures function references at construction so
    changing public io entries afterward does not replace this backend's callbacks.
    Native directory hooks may use shell commands; unsafe expansion characters
    are rejected before passing paths to them. The host remains responsible for
    links and concurrent filesystem changes, including check/use races.
    @ret table tFilesystem Internal callbacks; callers need not supply these.
!]]
local function filesystem()
    local sSeparator = package.config:sub(1, 1);
    assert(sSeparator == "/" or sSeparator == "\\", "VFS: unsupported native separator.");

    local fList    = io.list;
    local fIsDir   = io.isdir;
    local fIsFile  = io.isfile;
    local fExists  = io.exists;
    local fMkdir   = io.mkdir;
    local fOpen    = io.open;
    local fExecute = os.execute;
    local fRemove  = os.remove;
    local fRename  = os.rename;

    assert(rawtype(fList) == "function" and rawtype(fIsDir) == "function" and
           rawtype(fIsFile) == "function" and rawtype(fExists) == "function" and
           rawtype(fMkdir) == "function",
           "VFS: initialize LuaEx's io hooks before constructing VFS.");

    --[[!
        @fqxn LuaEx.Classes.VFS.Helpers.filesystem.validatePath
        @scope local
        @desc Rejects native characters expanded by the existing io shell helpers.
        @param string pPath Native path, including any trusted mount prefix.
    !]]
    local function fValidatePath(pPath)
        assert(not pPath:find('[%z\1-\31\127"]'), "VFS: unsupported native path character.");

        if (sSeparator == "\\") then
            assert(not pPath:find("[%%!%^]"), "VFS: native shell expansion characters are forbidden.");
        else
            assert(not pPath:find("[$`\\]"), "VFS: native shell expansion characters are forbidden.");
        end
    end

    --[[!
        @fqxn LuaEx.Classes.VFS.Helpers.filesystem.commandSucceeded
        @scope local
        @desc Normalizes the first os.execute result across Lua 5.1 and 5.3+.
        @param any vStatus Boolean status or numeric exit status.
        @ret boolean bOK Whether the command succeeded.
    !]]
    local function fCommandSucceeded(vStatus)
        return vStatus == true or (rawtype(vStatus) == "number" and vStatus == 0);
    end

    --[[!
        @fqxn LuaEx.Classes.VFS.Helpers.filesystem.comparablePath
        @scope local
        @desc Normalizes redundant Windows separators produced when io.list joins
        a drive root and a child; preserves the two leading separators of UNC paths.
        @param string pPath Native path to compare.
        @ret string pComparable Path without trailing separators.
    !]]
    local function fComparablePath(pPath)
        if (sSeparator == "\\") then
            pPath = pPath:gsub("/", "\\");
            local bUNC = pPath:sub(1, 2) == "\\\\";
            pPath = pPath:gsub("\\+", "\\");
            if (bUNC) then pPath = "\\"..pPath; end
        end
        return (pPath:gsub("[/\\]+$", ""));
    end

    --[[!
        @fqxn LuaEx.Classes.VFS.Helpers.filesystem.list
        @scope local
        @desc Converts io.list's full-path arrays to immediate name/kind records.
        Excludes the queried directory returned by Unix find, preserves dotfiles,
        and rejects any unexpected result outside the requested immediate parent.
        @param string pDirectory Native directory.
        @ret table tEntries Immediate records or nil on failure.
    !]]
    local function fListEntries(pDirectory)
        fValidatePath(pDirectory);
        if (not fIsDir(pDirectory)) then return nil; end
        local tListing = fList(pDirectory, false);
        if (rawtype(tListing) ~= "table") then return nil; end
        local pBase = fComparablePath(pDirectory);
        local tRet = {};

        for _, tGroup in ipairs({{key = "directories", kind = "directory"}, {key = "files", kind = "file"}}) do
            local tPaths = tListing[tGroup.key];
            if (rawtype(tPaths) ~= "table") then return nil; end

            for _, pEntry in ipairs(tPaths) do
                if (rawtype(pEntry) ~= "string") then return nil; end
                pEntry = fComparablePath(pEntry);

                -- io.listdirs includes its own starting directory on Unix.
                if (pEntry ~= pBase) then
                    local pParent, sName = pEntry:match("^(.*)[/\\]([^/\\]+)$");
                    if (pParent ~= pBase or not sName) then return nil; end
                    tRet[#tRet + 1] = {name = sName, kind = tGroup.kind};
                end
            end
        end

        return tRet;
    end

    return {
        separator = sSeparator,

        --[[!
            @fqxn LuaEx.Classes.VFS.Helpers.filesystem.stat
            @desc Uses io.isdir/io.isfile to identify an existing native location.
            @param string pPath Native path.
            @ret table tInfo Kind record or nil when unavailable.
        !]]
        stat = function(pPath)
            fValidatePath(pPath);
            if (fIsDir(pPath)) then return {kind = "directory"}; end
            if (fIsFile(pPath)) then return {kind = "file"}; end
            return nil;
        end,

        --[[!
            @fqxn LuaEx.Classes.VFS.Helpers.filesystem.listCallback
            @desc Supplies validated immediate children using the LuaEx listing API.
            @param string pDirectory Native directory.
            @ret table tEntries Name/kind records or nil on failure.
        !]]
        list = fListEntries,

        --[[!
            @fqxn LuaEx.Classes.VFS.Helpers.filesystem.read
            @desc Reads binary contents with io.open and closes the file on failure
            as well as success. File handles remain private to this backend.
            @param string pFile Native file.
            @ret string sData Contents or nil on failure.
        !]]
        read = function(pFile)
            fValidatePath(pFile);
            local hFile = fOpen(pFile, "rb");
            if (not hFile) then return nil; end
            local bOK, sData = pcall(hFile.read, hFile, "*a");
            local bClosed, vClosed = pcall(hFile.close, hFile);
            if (not bOK or not bClosed or not vClosed) then return nil; end
            return sData;
        end,

        --[[!
            @fqxn LuaEx.Classes.VFS.Helpers.filesystem.write
            @desc Writes binary contents with io.open, checking destination existence
            before allowing replacement. This is not an atomic exclusive-create API;
            the host must prevent concurrent changes between validation and opening.
            @param string pFile Native destination.
            @param string sData Complete binary contents.
            @param boolean bOverwrite Whether an existing file may be replaced.
            @ret boolean bOK True or nil on failure, including write/close errors.
        !]]
        write = function(pFile, sData, bOverwrite)
            fValidatePath(pFile);
            if (fIsDir(pFile) or (not bOverwrite and fExists(pFile))) then return nil; end
            local hFile = fOpen(pFile, "wb");
            if (not hFile) then return nil; end
            local bOK, vWritten = pcall(hFile.write, hFile, sData);
            local bClosed, vClosed = pcall(hFile.close, hFile);
            if (not bOK or not vWritten or not bClosed or not vClosed) then return nil; end
            return true;
        end,

        --[[!
            @fqxn LuaEx.Classes.VFS.Helpers.filesystem.mkdir
            @desc Uses io.mkdir after VFS has validated the existing parent.
            @param string pDirectory New native directory.
            @ret boolean bOK True or nil on failure.
        !]]
        mkdir = function(pDirectory)
            fValidatePath(pDirectory);
            if (fExists(pDirectory)) then return nil; end
            if (not fCommandSucceeded(fMkdir(pDirectory))) then return nil; end
            return true;
        end,

        --[[!
            @fqxn LuaEx.Classes.VFS.Helpers.filesystem.remove
            @desc Deletes files with os.remove. Empty directories use os.remove on
            Unix and plain rmdir without /s on Windows. LuaEx's io.rmdir is recursive
            and is deliberately not used for this single-entry operation: a missing
            listing or newly added child must not trigger an unplanned recursive
            delete. VFS separately authorizes and plans recursive operations.
            @param string pPath Native location.
            @param string sKind file or directory.
            @ret boolean bOK True or nil on failure.
        !]]
        remove = function(pPath, sKind)
            fValidatePath(pPath);
            if (sKind == "file") then return fRemove(pPath); end
            local tEntries = fListEntries(pPath);
            if (not tEntries or #tEntries ~= 0) then return nil; end

            if (sSeparator == "\\") then
                if (not fCommandSucceeded(fExecute('rmdir "'..pPath..'" 1>nul 2>nul'))) then return nil; end
                return true;
            end
            return fRemove(pPath);
        end,

        --[[!
            @fqxn LuaEx.Classes.VFS.Helpers.filesystem.rename
            @desc Renames a file with os.rename, preserving the source on failure.
            Destination replacement follows native rename support: some Windows
            hosts reject replacement even when authorized. No delete-first fallback
            is used. Concurrent destination changes are the host's responsibility.
            @param string pSource Native source.
            @param string pDestination Native destination.
            @param boolean bOverwrite Whether replacement is authorized.
            @ret boolean bOK True or nil on failure.
        !]]
        rename = function(pSource, pDestination, bOverwrite)
            fValidatePath(pSource);
            fValidatePath(pDestination);
            if (fIsDir(pDestination) or (not bOverwrite and fExists(pDestination))) then return nil; end
            return fRename(pSource, pDestination);
        end,
    };
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.fold
    @scope local
    @desc Folds ASCII letters without depending on the process locale.
    @param string sValue Text to fold.
    @ret string sFolded ASCII lowercase text.
!]]
local function fold(sValue)
    return (sValue:gsub("[A-Z]", function(sLetter)
        return string.char(sLetter:byte() + 32);
    end));
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.byteLess
    @scope local
    @desc Compares paths by unsigned bytes, independent of locale collation.
    @param string sLeft Left path.
    @param string sRight Right path.
    @ret boolean bLess Whether the left path precedes the right path.
!]]
local function byteLess(sLeft, sRight)
    for nIndex = 1, math.min(#sLeft, #sRight) do
        local nLeft, nRight = sLeft:byte(nIndex), sRight:byte(nIndex);

        if (nLeft ~= nRight) then
            return nLeft < nRight;
        end
    end

    return #sLeft < #sRight;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.component
    @scope local
    @desc Validates a component using the instance's captured host naming rules.
    Controls and backslashes remain forbidden by the VFS on every host.
    POSIX hosts have no Windows device-name or trailing-space/dot restrictions.
    @param table tState Private state containing the captured Windows flag.
    @param string sName A single directory or file name.
!]]
local function component(tState, sName)
    assert(rawtype(sName) == "string" and sName ~= "", "VFS: empty path component.");
    assert(sName ~= "." and sName ~= "..", "VFS: dot-directory references are forbidden.");
    assert(not sName:find('[%z\1-\31\127/\\]'), "VFS: forbidden path character.");

    -- POSIX permits Windows device spellings and punctuation. Native shell
    -- safety is checked separately by the default backend before using io hooks.
    if (not tState.windows) then return; end

    assert(not sName:find('[:<>"|?*]'), "VFS: forbidden Windows path character.");
    assert(not sName:find("[ .]$"), "VFS: trailing spaces and dots are forbidden.");

    local sDevice = fold(sName:match("^[^.]+") or sName);
    sDevice = sDevice:gsub(" +$", "");
    local sPort   = sDevice:sub(1, 3);
    local sDigit  = sDevice:sub(4);
    -- Windows also reserves COM/LPT with superscript 1, 2 and 3. Cover both
    -- UTF-8 and single-byte spellings without depending on the source encoding.
    local bSuperscript = sDigit == "\185" or sDigit == "\178" or sDigit == "\179" or
                        sDigit == "\194\185" or sDigit == "\194\178" or sDigit == "\194\179";
    assert(not (sDevice == "con" or sDevice == "prn" or sDevice == "aux" or
                sDevice == "nul" or sDevice == "conin$" or sDevice == "conout$" or
                sDevice:match("^com[1-9]$") or sDevice:match("^lpt[1-9]$") or
                ((sPort == "com" or sPort == "lpt") and bSuperscript)),
           "VFS: reserved device name.");
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.path
    @scope local
    @desc Requires an absolute virtual path. Removes one optional trailing slash;
    repeated separators, backslashes, dot segments and native drive paths fail.
    @param table tState Private state containing the captured host naming rules.
    @param string pPath Virtual path.
    @ret string pCanonical Canonical virtual path.
!]]
local function path(tState, pPath)
    assert(rawtype(pPath) == "string" and pPath:sub(1, 1) == "/", "VFS: absolute virtual path required.");
    assert(not pPath:find("//", 1, true), "VFS: repeated separators are forbidden.");

    if (#pPath > 1 and pPath:sub(-1) == "/") then
        pPath = pPath:sub(1, -2);
    end

    for sName in pPath:gmatch("[^/]+") do
        component(tState, sName);
    end

    return pPath;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.within
    @scope local
    @desc Tests containment using complete components rather than string prefixes.
    @param string pChild Candidate child.
    @param string pParent Candidate parent.
    @ret boolean bWithin Whether child equals or descends from parent.
!]]
local function within(pChild, pParent)
    return pParent == "/" or pChild == pParent or pChild:sub(1, #pParent + 1) == pParent.."/";
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.aliasName
    @scope local
    @desc Validates dotted ASCII identifiers and normalizes them to uppercase.
    @param string sName Alias such as GAMES.CURRENT.
    @ret string sCanonical Uppercase alias.
!]]
local function aliasName(sName)
    assert(rawtype(sName) == "string" and sName ~= "" and not sName:find("%.%."), "VFS: invalid alias.");
    assert(sName:sub(1, 1) ~= "." and sName:sub(-1) ~= ".", "VFS: invalid alias.");

    for sPart in sName:gmatch("[^.]+") do
        assert(sPart:match("^[A-Za-z_][A-Za-z_0-9]*$"), "VFS: invalid alias identifier.");
    end

    return (fold(sName):gsub("[a-z]", function(sLetter)
        return string.char(sLetter:byte() - 32);
    end));
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.denseLength
    @scope local
    @desc Rejects sparse arrays and nonnumeric keys in configuration and adapter lists.
    @param table tList Dense list.
    @ret number nLength Number of entries.
!]]
local function denseLength(tList)
    assert(rawtype(tList) == "table", "VFS: list expected.");
    local nCount = 0;

    for k in next, tList do
        assert(rawtype(k) == "number" and k >= 1 and k % 1 == 0, "VFS: dense list required.");
        nCount = nCount + 1;
    end

    for nIndex = 1, nCount do
        assert(rawget(tList, nIndex) ~= nil, "VFS: sparse list forbidden.");
    end

    return nCount;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.invoke
    @scope local
    @desc Calls a trusted adapter and sanitizes failures. Adapter errors never escape
    into the restricted interface with host path information.
    @param table tState Private filesystem state.
    @param string sMethod Adapter operation.
    @param ... ... Adapter arguments.
    @ret any vResult First result, or nil plus a generic operational reason.
!]]
local function invoke(tState, sMethod, ...)
    local tRuntime = _tRuntime[tState];

    -- Deserialization skips constructors. Reconnect the default io backend only
    -- when a restored namespace first performs a filesystem operation.
    if (not tRuntime) then
        tRuntime = {accesses = setmetatable({}, {__mode = "v"}), nextAccess = 0};
        _tRuntime[tState] = tRuntime;
    end
    if (not tRuntime.adapter) then
        tRuntime.adapter = next(tState.adapter) and tState.adapter or filesystem();
    end

    local bOK, vResult = pcall(tRuntime.adapter[sMethod], ...);

    if (not bOK or vResult == nil or vResult == false) then
        return nil, "VFS: filesystem operation failed ("..sMethod..").";
    end

    return vResult;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.target
    @scope local
    @desc Resolves a virtual path or exact alias name without exposing native paths.
    @param table tState Private state.
    @param string sTarget Absolute virtual path or dotted alias.
    @ret string pPath Virtual path, or nil and a reason for an undefined alias.
!]]
local function target(tState, sTarget)
    assert(rawtype(sTarget) == "string", "VFS: path or alias expected.");

    if (sTarget:sub(1, 1) == "/") then
        return path(tState, sTarget);
    end

    local tAlias = tState.aliases[aliasName(sTarget)];

    if (not tAlias) then
        return nil, "VFS: alias is not defined.";
    end

    return tAlias.path;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.entries
    @scope local
    @desc Copies and validates adapter entries, excluding dot references and rejecting
    duplicate names, ASCII case collisions, invalid components and unsupported kinds.
    @param table tState Private state.
    @param string pReal Native directory.
    @ret table tEntries Validated children, or nil plus an operational reason.
!]]
local function entries(tState, pReal)
    local tRaw = invoke(tState, "list", pReal);
    if (not tRaw) then return nil, "VFS: directory listing failed."; end

    local tRet, tSeen = {}, {};
    local bOK = pcall(function()
        local nCount = denseLength(tRaw);

        for nIndex = 1, nCount do
            local tEntry = rawget(tRaw, nIndex);
            assert(rawtype(tEntry) == "table");
            local sName, sKind = rawget(tEntry, "name"), rawget(tEntry, "kind");

            if (sName ~= "." and sName ~= "..") then
                component(tState, sName);
                assert(sKind == "file" or sKind == "directory");
                local sKey = fold(sName);
                assert(not tSeen[sKey]);
                tSeen[sKey] = true;
                tRet[#tRet + 1] = {name = sName, kind = sKind};
            end
        end
    end);

    if (not bOK) then return nil, "VFS: directory contains invalid or conflicting entries."; end
    return tRet;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.native
    @scope local
    @desc Finds the backing mount and walks exact entry names, detecting wrong case
    and case collisions even on Windows. A missing final component is allowed only
    for creation. Grouping directories have no native destination.
    @param table tState Private state.
    @param string pPath Canonical virtual path.
    @param boolean bCreate Whether the final component may be absent.
    @ret string pReal Native path, followed by kind and mount; or nil and reason.
!]]
local function native(tState, pPath, bCreate)
    local tMount;

    for pMount, tCandidate in next, tState.mounts do
        if (within(pPath, pMount)) then tMount = tCandidate; break; end
    end

    if (not tMount) then return nil, "VFS: path has no backing mount."; end
    local pReal, sKind = tMount.real, "directory";
    local tInfo = invoke(tState, "stat", pReal);
    if (rawtype(tInfo) ~= "table" or tInfo.kind ~= "directory") then
        return nil, "VFS: mounted directory is unavailable.";
    end

    local sRemainder = pPath:sub(#tMount.path + 2);
    local tParts = {};
    for sPart in sRemainder:gmatch("[^/]+") do tParts[#tParts + 1] = sPart; end

    for nIndex, sPart in ipairs(tParts) do
        if (sKind ~= "directory") then return nil, "VFS: parent is not a directory."; end
        local tChildren, sReason = entries(tState, pReal);
        if (not tChildren) then return nil, sReason; end
        local sFound;

        for _, tChild in ipairs(tChildren) do
            if (fold(tChild.name) == fold(sPart)) then
                if (tChild.name ~= sPart) then return nil, "VFS: path case does not match."; end
                sFound = tChild.kind;
            end
        end

        if (not sFound and not (bCreate and nIndex == #tParts)) then
            return nil, "VFS: path does not exist.";
        end

        local sSeparator = pReal:sub(-1) == tState.separator and "" or tState.separator;
        pReal = pReal..sSeparator..sPart;
        sKind = sFound;
    end

    return pReal, sKind, tMount;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.group
    @scope local
    @desc Tests whether a path is a synthetic ancestor of a mounted directory.
    @param table tState Private state.
    @param string pPath Virtual directory.
    @ret boolean bGroup Whether the path is a virtual grouping directory.
!]]
local function group(tState, pPath)
    if (pPath == "/") then return true; end
    for pMount in next, tState.mounts do
        if (pMount ~= pPath and within(pMount, pPath)) then return true; end
    end
    return false;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.revoke
    @scope local
    @desc Permanently revokes grants intersecting a changed namespace subtree.
    Namespace changes revoke whole intersecting grants. Physical deletion revokes
    grants rooted at/below the removed directory, preserving ancestor authority to
    manage its remaining and future children. Alias changes affect alias grants only.
    @param table tState Private state.
    @param string pPath Changed path.
    @param table|nil tAlias Specific alias identity, when applicable.
    @param boolean|nil bRemovedDirectory Restrict revocation to removed grant roots.
!]]
local function revoke(tState, pPath, tAlias, bRemovedDirectory)
    local tRuntime = _tRuntime[tState];
    for _, tAccess in next, tRuntime and tRuntime.accesses or {} do
        for _, tGrant in ipairs(tAccess.grants) do
            if ((tAlias and tGrant.alias == tAlias) or
                (not tAlias and (within(tGrant.path, pPath) or
                 (not bRemovedDirectory and within(pPath, tGrant.path))))) then
                tGrant.active = false;
            end
        end
    end
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.authorize
    @scope local
    @desc Requires an active containing grant and every requested permission.
    @param table|nil tAccess Restricted access state; nil denotes the owner.
    @param string pPath Canonical path.
    @param ... ... Required permission names.
    @ret boolean bAllowed Whether the operation is authorized.
!]]
local function authorize(tAccess, pPath, ...)
    if (not tAccess) then return true; end
    if (not tAccess.active) then return false; end

    for _, tGrant in ipairs(tAccess.grants) do
        if (tGrant.active and within(pPath, tGrant.path)) then
            for _, sPermission in ipairs({...}) do
                if (not tGrant.permissions[sPermission]) then return false; end
            end
            return true;
        end
    end

    return false;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.record
    @scope local
    @desc Builds an independent listing record. Only the final file suffix is split;
    leading dots alone and directory names are retained without an extension.
    @param string pPath Virtual path.
    @param string sKind file or directory.
    @ret table tEntry Fields name, ext, path and kind.
!]]
local function record(pPath, sKind)
    local sName = pPath:match("([^/]+)$") or "/";
    local sExt  = "";

    if (sKind == "file") then
        local sStem, sSuffix = sName:match("^(.+)%.([^.]*)$");
        if (sStem and sSuffix ~= "") then sName, sExt = sStem, sSuffix; end
    end

    return {name = sName, ext = sExt, path = pPath, kind = sKind};
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.children
    @scope local
    @desc Lists immediate real children or synthesized grouping children.
    @param table tState Private state.
    @param string pPath Virtual directory.
    @ret table tChildren Child records, or nil and a reason.
!]]
local function children(tState, pPath)
    local tRet = {};

    if (group(tState, pPath)) then
        local tSeen = {};
        local sPrefix = pPath == "/" and "/" or pPath.."/";

        for pMount in next, tState.mounts do
            if (within(pMount, pPath)) then
                local sName = pMount:sub(#sPrefix + 1):match("^[^/]+");
                if (sName and not tSeen[sName]) then
                    tSeen[sName] = true;
                    tRet[#tRet + 1] = record(sPrefix..sName, "directory");
                end
            end
        end
    else
        local pReal, sKind = native(tState, pPath, false);
        if (not pReal) then return nil, sKind; end
        if (sKind ~= "directory") then return nil, "VFS: directory required."; end
        local tEntries, sReason = entries(tState, pReal);
        if (not tEntries) then return nil, sReason; end

        for _, tEntry in ipairs(tEntries) do
            tRet[#tRet + 1] = record(pPath.."/"..tEntry.name, tEntry.kind);
        end
    end

    return tRet;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.operate
    @scope local
    @desc Shared owner/restricted dispatcher. Every call checks live authority.
    Operations expose whole-file strings, never native handles. Recursive listing
    requires recursion permission even when the current directory is empty.
    @param table tState Private state.
    @param table|nil tAccess Optional restricted state.
    @param string sOperation Operation name.
    @param string sTarget Virtual path or alias.
    @param any vOption Operation-specific argument.
    @param any vExtra Optional second argument.
    @ret any vResult Result or nil and an operational reason.
!]]
local function operate(tState, tAccess, sOperation, sTarget, vOption, vExtra)
    local pPath, sReason = target(tState, sTarget);
    if (not pPath) then return nil, sReason; end

    if (sOperation == "ls") then
        assert(vOption == nil or rawtype(vOption) == "boolean", "VFS: recursion must be boolean or nil.");
        local bRecursive = vOption == true;
        local sFilter = vExtra == nil and "both" or vExtra;
        assert(sFilter == "file" or sFilter == "directory" or sFilter == "both", "VFS: invalid listing filter.");
        if (not authorize(tAccess, pPath) or (bRecursive and not authorize(tAccess, pPath, "recursive"))) then
            return nil, "VFS: access denied.";
        end
        if ((sFilter ~= "file" and not authorize(tAccess, pPath, "listDirectories")) or
            (sFilter ~= "directory" and not authorize(tAccess, pPath, "listFiles"))) then
            return nil, "VFS: access denied.";
        end

        local tRet = {};
        local function fVisit(pDirectory, nDepth)
            -- Bound traversal when host links introduce cycles. The host owns link policy.
            if (nDepth > 256) then return nil, "VFS: traversal depth exceeded."; end
            local tChildren, sError = children(tState, pDirectory);
            if (not tChildren) then return nil, sError; end

            for _, tEntry in ipairs(tChildren) do
                if (sFilter == "both" or sFilter == tEntry.kind) then tRet[#tRet + 1] = tEntry; end
                if (bRecursive and tEntry.kind == "directory") then
                    local bOK, sFailure = fVisit(tEntry.path, nDepth + 1);
                    if (not bOK) then return nil, sFailure; end
                end
            end
            return true;
        end

        local bOK, sError = fVisit(pPath, 0);
        if (not bOK) then return nil, sError; end
        table.sort(tRet, function(tLeft, tRight) return byteLess(tLeft.path, tRight.path); end);
        return tRet;
    end

    if (not authorize(tAccess, pPath)) then return nil, "VFS: access denied."; end
    -- Reject operations with no applicable capability before looking up any
    -- physical entry. Type-dependent permissions are checked again after lookup.
    if (sOperation == "read") then
        if (not authorize(tAccess, pPath, "readFiles")) then return nil, "VFS: access denied."; end
    elseif (sOperation == "write") then
        assert(rawtype(vOption) == "string", "VFS: file contents must be a string.");
        if (not authorize(tAccess, pPath, "writeFiles") or
            (not authorize(tAccess, pPath, "createFiles") and not authorize(tAccess, pPath, "overwriteFiles"))) then
            return nil, "VFS: access denied.";
        end
    elseif (sOperation == "mkdir") then
        if (not authorize(tAccess, pPath, "createDirectories")) then return nil, "VFS: access denied."; end
    elseif (sOperation == "remove") then
        assert(vOption == nil or rawtype(vOption) == "boolean", "VFS: recursion must be boolean or nil.");
        if ((not authorize(tAccess, pPath, "deleteFiles") and not authorize(tAccess, pPath, "deleteDirectories")) or
            (vOption == true and not authorize(tAccess, pPath, "recursive"))) then
            return nil, "VFS: access denied.";
        end
    end
    local bCreating = sOperation == "write" or sOperation == "mkdir";
    local pReal, sKind = native(tState, pPath, bCreating);
    if (not pReal) then return nil, sKind; end

    if (sOperation == "read") then
        if (sKind ~= "file") then return nil, "VFS: file required."; end
        local sData = invoke(tState, "read", pReal);
        if (rawtype(sData) ~= "string") then return nil, "VFS: file read failed."; end
        return sData;
    elseif (sOperation == "write") then
        if (sKind == "directory") then return nil, "VFS: destination is a directory."; end
        local sPermission = sKind and "overwriteFiles" or "createFiles";
        if (not authorize(tAccess, pPath, "writeFiles", sPermission)) then return nil, "VFS: access denied."; end
        return invoke(tState, "write", pReal, vOption, sKind ~= nil);
    elseif (sOperation == "mkdir") then
        if (sKind) then return nil, "VFS: destination already exists."; end
        return invoke(tState, "mkdir", pReal);
    elseif (sOperation == "remove") then
        local bRecursive = vOption == true;
        local sPermission = sKind == "directory" and "deleteDirectories" or "deleteFiles";
        if (not authorize(tAccess, pPath, sPermission) or
            (bRecursive and not authorize(tAccess, pPath, "recursive"))) then
            return nil, "VFS: access denied.";
        end
        -- Namespace roots survive physical operations; explicit unmount is separate.
        for pMount in next, tState.mounts do
            if (pPath == pMount) then return nil, "VFS: cannot delete a mount root."; end
        end
        local tPlan = {};
        local function fPlan(pItem, nDepth)
            if (nDepth > 256) then return nil, "VFS: traversal depth exceeded."; end
            local pNative, sType = native(tState, pItem, false);
            if (not pNative) then return nil, sType; end
            local sRequired = sType == "directory" and "deleteDirectories" or "deleteFiles";
            if (not authorize(tAccess, pItem, sRequired)) then return nil, "VFS: access denied."; end

            if (sType == "directory") then
                local tChildren, sError = children(tState, pItem);
                if (not tChildren) then return nil, sError; end
                if (#tChildren > 0 and not bRecursive) then return nil, "VFS: directory is not empty."; end
                for _, tChild in ipairs(tChildren) do
                    local bOK, sFailure = fPlan(tChild.path, nDepth + 1);
                    if (not bOK) then return nil, sFailure; end
                end
            end

            tPlan[#tPlan + 1] = {path = pItem, real = pNative, kind = sType};
            return true;
        end
        -- Check all permissions before deletion; revoke only after executing the plan
        -- so removal of a child cannot invalidate the same in-progress operation.
        local bOK, sError = fPlan(pPath, 0);
        if (not bOK) then return nil, sError; end
        local tRemovedDirectories = {};

        for _, tItem in ipairs(tPlan) do
            bOK, sError = invoke(tState, "remove", tItem.real, tItem.kind);
            if (not bOK) then break; end
            if (tItem.kind == "directory") then
                tRemovedDirectories[#tRemovedDirectories + 1] = tItem.path;
            end
        end

        for _, pRemoved in ipairs(tRemovedDirectories) do
            revoke(tState, pRemoved, nil, true);
            for pRegistered in next, tState.directories do
                if (within(pRegistered, pRemoved)) then tState.directories[pRegistered] = nil; end
            end
            for sName, tAlias in next, tState.aliases do
                if (within(tAlias.path, pRemoved)) then tState.aliases[sName] = nil; end
            end
        end
        return bOK, sError;
    end

    error("VFS: unknown operation.");
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.transfer
    @scope local
    @desc Copies or moves one file. Checks source and destination permissions before
    mutation. Copy uses whole-file read/write; move uses an adapter rename, never a
    copy/delete fallback. Cross-device moves may fail. Overwrite defaults to false.
    @param table tState Private state.
    @param table|nil tAccess Restricted state or owner.
    @param boolean bMove Whether to move instead of copy.
    @param string sSource Source path or alias.
    @param string sDestination Destination path or alias.
    @param boolean|nil bOverwrite Explicit overwrite request.
    @ret boolean bOK Success or nil and reason.
!]]
local function transfer(tState, tAccess, bMove, sSource, sDestination, bOverwrite)
    assert(bOverwrite == nil or rawtype(bOverwrite) == "boolean", "VFS: overwrite must be boolean or nil.");
    local pSource, sReason = target(tState, sSource);
    if (not pSource) then return nil, sReason; end
    local pDestination;
    pDestination, sReason = target(tState, sDestination);
    if (not pDestination) then return nil, sReason; end
    if (pSource == pDestination) then return nil, "VFS: source and destination are identical."; end
    local sCapability = bMove and "moveFiles" or "copyFiles";
    if (not authorize(tAccess, pSource, sCapability, "readFiles") or
        not authorize(tAccess, pDestination, sCapability, "writeFiles") or
        (bMove and not authorize(tAccess, pSource, "deleteFiles"))) then
        return nil, "VFS: access denied.";
    end
    if (not authorize(tAccess, pDestination, "createFiles") and
        not authorize(tAccess, pDestination, "overwriteFiles")) then
        return nil, "VFS: access denied.";
    end
    local pFrom, sFromKind = native(tState, pSource, false);
    if (not pFrom) then return nil, sFromKind; end
    if (sFromKind ~= "file") then return nil, "VFS: source must be a file."; end
    local pTo, sToKind = native(tState, pDestination, true);
    if (not pTo) then return nil, sToKind; end
    if (sToKind == "directory") then return nil, "VFS: destination is a directory."; end
    if (sToKind and not bOverwrite) then return nil, "VFS: destination already exists."; end
    if (not authorize(tAccess, pDestination, sToKind and "overwriteFiles" or "createFiles")) then
        return nil, "VFS: access denied.";
    end

    if (bMove) then
        local bOK, sError = invoke(tState, "rename", pFrom, pTo, sToKind ~= nil);
        return bOK, sError;
    end

    local sData = invoke(tState, "read", pFrom);
    if (rawtype(sData) ~= "string") then return nil, "VFS: source read failed."; end
    return invoke(tState, "write", pTo, sData, sToKind ~= nil);
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.aliasList
    @scope local
    @desc Returns sorted alias/value records. Restricted objects see aliases only
    when their folder lies within a live grant. Records do not expose native paths.
    @param table tState Private state.
    @param table|nil tAccess Restricted state or owner.
    @ret table tAliases Records with name and path; nil and reason if revoked.
!]]
local function aliasList(tState, tAccess)
    if (tAccess and not tAccess.active) then return nil, "VFS: access revoked."; end
    local tRet = {};

    for sName, tAlias in next, tState.aliases do
        if (authorize(tAccess, tAlias.path)) then
            tRet[#tRet + 1] = {name = sName, path = tAlias.path};
        end
    end
    table.sort(tRet, function(tLeft, tRight) return byteLess(tLeft.name, tRight.name); end);
    return tRet;
end

--[[!
    @fqxn LuaEx.Classes.VFS.Helpers.accessObject
    @scope local
    @desc Builds a read-only method facade. Calls use LuaEx's bound dot convention.
    The caller must withhold debug/raw manipulation and unrestricted host APIs from
    untrusted code. The facade captures no owner object and cannot modify grants.
    Revoked objects reject calls before resolving any arguments. Restricted
    operational failures share one reason so errors cannot enumerate inaccessible
    aliases, files or directories. The owner retains detailed diagnostic reasons.
    @param table tState Private filesystem state.
    @param table tAccess Private access state.
    @ret table oAccess Restricted object.
!]]
local function accessObject(tState, tAccess)
    local tMethods = {};

    --[[!
        @fqxn LuaEx.Classes.VFS.Access.Methods.read
        @desc Reads an authorized file as a binary string; requires readFiles.
        @param string pPath Absolute virtual path or alias.
        @ret string sData File contents or nil and reason.
    !]]
    tMethods.read = function(pPath) return operate(tState, tAccess, "read", pPath); end;

    --[[!
        @fqxn LuaEx.Classes.VFS.Access.Methods.write
        @desc Writes a whole binary string; requires writeFiles and createFiles or
        overwriteFiles according to destination existence. Parents must exist.
        @param string pPath Destination.
        @param string sData Contents.
        @ret boolean bOK Success or nil and reason.
    !]]
    tMethods.write = function(pPath, sData) return operate(tState, tAccess, "write", pPath, sData); end;

    --[[!
        @fqxn LuaEx.Classes.VFS.Access.Methods.ls
        @desc Lists authorized directories/files without aliases. Defaults to no
        recursion and VFS.BOTH; nil uses defaults. Includes dotfiles, excludes dot
        references, sorts by full virtual path and returns name/ext/path/kind records.
        @param string pDirectory Directory path or alias.
        @param boolean|nil bRecursive Recursion flag.
        @param string|nil eKind VFS.FILE, VFS.DIR or VFS.BOTH.
        @ret table tEntries Entries or nil and reason.
    !]]
    tMethods.ls = function(pDirectory, bRecursive, eKind)
        return operate(tState, tAccess, "ls", pDirectory, bRecursive, eKind);
    end;

    --[[!
        @fqxn LuaEx.Classes.VFS.Access.Methods.mkdir
        @desc Creates one directory under an existing parent; requires createDirectories.
        @param string pDirectory New directory.
        @ret boolean bOK Success or nil and reason.
    !]]
    tMethods.mkdir = function(pDirectory) return operate(tState, tAccess, "mkdir", pDirectory); end;

    --[[!
        @fqxn LuaEx.Classes.VFS.Access.Methods.remove
        @desc Deletes physical content with deleteFiles/deleteDirectories. Recursion
        defaults to false and requires recursive permission. Recursive deletion is
        not transactional; failures can leave partial deletions. Mount roots cannot
        be deleted. Deleting a granted directory or its ancestor revokes that grant;
        deleting ordinary children leaves the containing directory grant active.
        @param string pPath File or directory.
        @param boolean|nil bRecursive Whether to remove descendants.
        @ret boolean bOK Success or nil and reason.
    !]]
    tMethods.remove = function(pPath, bRecursive)
        return operate(tState, tAccess, "remove", pPath, bRecursive);
    end;

    --[[!
        @fqxn LuaEx.Classes.VFS.Access.Methods.copy
        @desc Copies a file with copyFiles/readFiles at source and
        copyFiles/writeFiles/createFiles or overwriteFiles at destination.
        @param string pSource Source file.
        @param string pDestination Destination file.
        @param boolean|nil bOverwrite Allow overwrite; default false.
        @ret boolean bOK Success or nil and reason.
    !]]
    tMethods.copy = function(pSource, pDestination, bOverwrite)
        return transfer(tState, tAccess, false, pSource, pDestination, bOverwrite);
    end;

    --[[!
        @fqxn LuaEx.Classes.VFS.Access.Methods.move
        @desc Renames a file using moveFiles at both ends, readFiles/deleteFiles at
        source and writeFiles/createFiles or overwriteFiles at destination.
        @param string pSource Source file.
        @param string pDestination Destination file.
        @param boolean|nil bOverwrite Allow overwrite; default false.
        @ret boolean bOK Success or nil and reason.
    !]]
    tMethods.move = function(pSource, pDestination, bOverwrite)
        return transfer(tState, tAccess, true, pSource, pDestination, bOverwrite);
    end;

    --[[!
        @fqxn LuaEx.Classes.VFS.Access.Methods.listAliases
        @desc Lists authorized uppercase aliases as name/path records, sorted by name.
        @ret table tAliases Independent records or nil and reason.
    !]]
    tMethods.listAliases = function() return aliasList(tState, tAccess); end;

    -- Apply the same boundary to every exposed operation, including two-path
    -- transfers and alias listings. Keep programmer errors as exceptions.
    for sName, fMethod in next, tMethods do
        local fOperation = fMethod;

        tMethods[sName] = function(...)
            if (not tAccess.active) then return nil, "VFS: access revoked."; end
            local vResult, sReason = fOperation(...);

            if (vResult == nil or vResult == false) then
                return nil, "VFS: path is unavailable or access is denied.";
            end
            return vResult, sReason;
        end;
    end

    local oAccess = setmetatable({}, {
        __index = tMethods,
        __newindex = function() error("VFS: access objects are read-only.", 2); end,
        __metatable = false,
    });
    _tAccessStates[oAccess] = tAccess;
    return oAccess;
end

return class("VFS",
{},--METAMETHODS
{--STATIC PUBLIC
    --[[!
        @fqxn LuaEx.Classes.VFS.Fields.FILE
        @desc Immutable file-only listing selector and file entry kind.
    !]]
    FILE__RO = "file",
    --[[!
        @fqxn LuaEx.Classes.VFS.Fields.DIR
        @desc Immutable directory-only listing selector and directory entry kind.
    !]]
    DIR__RO = "directory",
    --[[!
        @fqxn LuaEx.Classes.VFS.Fields.BOTH
        @desc Immutable default selector including files and directories.
    !]]
    BOTH__RO = "both",
},
{--PRIVATE
    --[[!
        @fqxn LuaEx.Classes.VFS.Private.state
        @desc Namespace state automatically serialized and restored by the class
        system. Includes mounts, registered directories, aliases, platform rules
        and optional custom callbacks. The default io backend is rebuilt on use.
        Live access facades stay attached to their original namespace; callers
        create new access objects for a restored instance.
    !]]
    state = {},
},
{},--PROTECTED
{--PUBLIC
    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.VFS
        @pulsarlua function VFS
        @desc Constructs an empty VFS using LuaEx's io.list, io.isdir, io.isfile,
        io.exists and io.mkdir, plus standard io.open/os.remove/os.rename.
        Directory removal is nonrecursive at the native boundary (os.remove on
        Unix, plain rmdir on Windows); VFS plans and authorizes recursion itself.
        Captures the host platform from package.config at construction, using the
        same Windows/Unix distinction as LuaEx's io hooks. Naming restrictions
        remain fixed for this instance, including when a custom backend is supplied.
        Omit the argument or pass nil for normal filesystem use; no caller adapter
        is needed. The default backend rejects native shell expansion characters
        before invoking LuaEx's existing directory hooks. File writes and renames
        use check-then-act semantics; the host handles concurrent changes.
        A custom adapter is optional for specialized hosts and in-memory examples.
        Adapter callbacks use dot calling convention and return a result or nil,
        reason. Required callbacks: stat(path) returns {kind = 'file'|'directory'};
        list(path) returns dense immediate {name, kind} records including dotfiles;
        read(path) returns a binary string; write(path, data, overwrite), mkdir(path),
        remove(path, kind), rename(source, destination, overwrite) return true.
        mkdir creates only one directory; remove removes only a file or empty
        directory. write/rename must enforce overwrite=false without clobbering an
        existing destination. The host handles links, races, Unicode names, native
        root spelling and filesystem-specific limits. stat/list must agree and
        report resolved links according to the host's chosen policy.
        @param table|nil tAdapter Optional custom callbacks and native separator; nil uses LuaEx io.
        @ret VFS oVFS New instance. Methods use bound dot calls, as other LuaEx classes.
    !]]
    VFS = function(this, cdat, tAdapter)
        local bDefault = tAdapter == nil;
        if (bDefault) then tAdapter = filesystem(); end
        assert(rawtype(tAdapter) == "table", "VFS: optional backend must be a table or nil.");
        local tCopy = {};
        for _, sMethod in ipairs({"stat", "list", "read", "write", "mkdir", "remove", "rename"}) do
            assert(rawtype(rawget(tAdapter, sMethod)) == "function", "VFS: missing adapter callback "..sMethod..".");
            tCopy[sMethod] = rawget(tAdapter, sMethod);
        end
        local sSeparator = rawget(tAdapter, "separator");
        assert(sSeparator == "/" or sSeparator == "\\", "VFS: adapter separator must be / or backslash.");
        cdat.pri.state = {
            adapter = bDefault and {} or tCopy, separator = sSeparator, mounts = {}, directories = {},
            windows = package.config:sub(1, 1) == "\\",
            aliases = {},
        };
        cdat.pri.state.directories["/"] = {};
        _tRuntime[cdat.pri.state] = {adapter = tCopy,
                                   accesses = setmetatable({}, {__mode = "v"}), nextAccess = 0};
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.mount
        @desc Attaches an existing native absolute directory at a non-root virtual
        path and registers it and synthetic parents. Rejects ancestor/descendant
        mounts, duplicate paths and ASCII case collisions. Native locations can be
        unrelated; overlapping physical roots remain the host's responsibility.
        @param string pVirtual Virtual mount path.
        @param string pReal Absolute native directory (drive/UNC or Unix root).
        @ret boolean bOK Success or nil and operational reason.
    !]]
    mount = function(this, cdat, pVirtual, pReal)
        local tState = cdat.pri.state;
        pVirtual = path(tState, pVirtual);
        assert(pVirtual ~= "/", "VFS: mount below the virtual root.");
        assert(rawtype(pReal) == "string" and pReal ~= "" and not pReal:find("[%z\1-\31\127]"), "VFS: invalid native root.");
        if (tState.separator == "\\") then
            assert(pReal:match("^[A-Za-z]:[\\/]") or pReal:match("^[\\/][\\/][^\\/]+[\\/][^\\/]+"), "VFS: absolute native root required.");
            pReal = pReal:gsub("/", "\\");
        else
            assert(pReal:sub(1, 1) == "/", "VFS: absolute native root required.");
        end
        -- Preserve drive roots and the Unix root while trimming other trailing separators.
        while (#pReal > 1 and pReal:sub(-1) == tState.separator and not pReal:match("^[A-Za-z]:\\$")) do
            pReal = pReal:sub(1, -2);
        end
        for pMount in next, tState.mounts do
            assert(not within(fold(pVirtual), fold(pMount)) and not within(fold(pMount), fold(pVirtual)), "VFS: mounts cannot overlap.");
        end
        -- Check shared synthetic parents component by component, including their spelling.
        for pDirectory in next, tState.directories do
            local tLeft, tRight = {}, {};
            for sPart in pVirtual:gmatch("[^/]+") do tLeft[#tLeft + 1] = sPart; end
            for sPart in pDirectory:gmatch("[^/]+") do tRight[#tRight + 1] = sPart; end
            for nIndex = 1, math.min(#tLeft, #tRight) do
                if (fold(tLeft[nIndex]) ~= fold(tRight[nIndex])) then break; end
                assert(tLeft[nIndex] == tRight[nIndex], "VFS: namespace case collision.");
            end
        end
        local tInfo = invoke(tState, "stat", pReal);
        if (rawtype(tInfo) ~= "table" or tInfo.kind ~= "directory") then return nil, "VFS: native root is not an available directory."; end
        tState.mounts[pVirtual] = {path = pVirtual, real = pReal};
        local pParent = "";
        for sPart in pVirtual:gmatch("[^/]+") do
            pParent = pParent.."/"..sPart;
            tState.directories[pParent] = tState.directories[pParent] or {};
        end
        return true;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.unmount
        @desc Removes exactly one mount and its directory registrations/aliases,
        pruning unused grouping parents. Revokes every intersecting grant; never
        deletes physical files. Recreating a mount does not revive grants.
        @param string pVirtual Exact mount path.
        @ret boolean bOK Success or nil and reason.
    !]]
    unmount = function(this, cdat, pVirtual)
        local tState = cdat.pri.state;
        pVirtual = path(tState, pVirtual);
        if (not tState.mounts[pVirtual]) then return nil, "VFS: mount is not defined."; end
        revoke(tState, pVirtual);
        tState.mounts[pVirtual] = nil;
        for pDirectory in next, tState.directories do
            if (within(pDirectory, pVirtual)) then tState.directories[pDirectory] = nil; end
        end
        for sName, tAlias in next, tState.aliases do
            if (within(tAlias.path, pVirtual)) then tState.aliases[sName] = nil; end
        end
        local pParent = pVirtual:match("^(.*)/[^/]+$");
        while (pParent and pParent ~= "") do
            if (not group(tState, pParent)) then
                tState.directories[pParent] = nil;
                for sName, tAlias in next, tState.aliases do
                    if (tAlias.path == pParent) then tState.aliases[sName] = nil; end
                end
            end
            pParent = pParent:match("^(.*)/[^/]+$");
        end
        return true;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.registerDirectory
        @desc Registers an existing directory for explicit grants/aliases. Its
        descendants need no individual registration for inherited operations.
        @param string pDirectory Virtual directory.
        @ret boolean bOK Success or nil and reason.
    !]]
    registerDirectory = function(this, cdat, pDirectory)
        local tState = cdat.pri.state;
        pDirectory = path(tState, pDirectory);
        if (tState.directories[pDirectory]) then return true; end
        local pReal, sKind = native(tState, pDirectory, false);
        if (not pReal) then return nil, sKind; end
        if (sKind ~= "directory") then return nil, "VFS: directory required."; end
        tState.directories[pDirectory] = {};
        return true;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.unregisterDirectory
        @desc Removes a directory registration and descendant registrations/aliases,
        revoking intersecting grants without deleting contents. Mounts and grouping
        ancestors require unmount instead. Ordinary owner path resolution remains
        possible beneath mounts even when registration is removed.
        @param string pDirectory Registered virtual directory.
        @ret boolean bOK Success or nil and reason.
    !]]
    unregisterDirectory = function(this, cdat, pDirectory)
        local tState = cdat.pri.state;
        pDirectory = path(tState, pDirectory);
        if (not tState.directories[pDirectory]) then return nil, "VFS: directory is not registered."; end
        if (tState.mounts[pDirectory] or group(tState, pDirectory)) then return nil, "VFS: unmount the associated mounts instead."; end
        revoke(tState, pDirectory);
        for pRegistered in next, tState.directories do
            if (within(pRegistered, pDirectory)) then tState.directories[pRegistered] = nil; end
        end
        for sName, tAlias in next, tState.aliases do
            if (within(tAlias.path, pDirectory)) then tState.aliases[sName] = nil; end
        end
        return true;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.setAlias
        @desc Creates or retargets an uppercase dotted alias to a registered folder.
        Retargeting revokes grants made through the old alias identity; direct folder
        grants remain unchanged. Setting the same target is a no-op.
        @param string sName Case-insensitive dotted identifier.
        @param string pDirectory Registered virtual directory.
        @ret boolean bOK Success or nil and reason.
    !]]
    setAlias = function(this, cdat, sName, pDirectory)
        local tState = cdat.pri.state;
        sName, pDirectory = aliasName(sName), path(tState, pDirectory);
        if (not tState.directories[pDirectory]) then return nil, "VFS: alias target is not registered."; end
        local tPrevious = tState.aliases[sName];
        if (tPrevious and tPrevious.path == pDirectory) then return true; end
        if (tPrevious) then revoke(tState, tPrevious.path, tPrevious); end
        tState.aliases[sName] = {path = pDirectory};
        return true;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.removeAlias
        @desc Removes exactly one alias, revoking its grants without deleting files
        or independently named dotted child aliases.
        @param string sName Alias name in any case.
        @ret boolean bOK Success or nil and reason.
    !]]
    removeAlias = function(this, cdat, sName)
        local tState = cdat.pri.state;
        sName = aliasName(sName);
        local tAlias = tState.aliases[sName];
        if (not tAlias) then return nil, "VFS: alias is not defined."; end
        revoke(tState, tAlias.path, tAlias);
        tState.aliases[sName] = nil;
        return true;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.getAlias
        @desc Returns an alias's virtual folder value without native resolution.
        @param string sName Alias name in any case.
        @ret string pPath Assigned virtual folder or nil and reason.
    !]]
    getAlias = function(this, cdat, sName)
        local tAlias = cdat.pri.state.aliases[aliasName(sName)];
        if (not tAlias) then return nil, "VFS: alias is not defined."; end
        return tAlias.path;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.listAliases
        @desc Lists all aliases alphabetically as independent name/path records.
        @ret table tAliases Sorted alias records.
    !]]
    listAliases = function(this, cdat) return aliasList(cdat.pri.state); end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.resolve
        @desc Owner-only native resolution of an existing virtual path or alias.
        Synthetic grouping directories have no native path. Never exposed by access objects.
        @param string sTarget Virtual path or alias.
        @ret string pReal Native path or nil and reason.
    !]]
    resolve = function(this, cdat, sTarget)
        local tState = cdat.pri.state;
        local pPath, sReason = target(tState, sTarget);
        if (not pPath) then return nil, sReason; end
        local pReal, sKind = native(tState, pPath, false);
        if (not pReal) then return nil, sKind; end
        return pReal;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.createAccess
        @desc Creates a restricted object from a dense grant list. Each record has
        exactly one path or alias plus a permissions table. Targets must already be
        registered directories. Duplicate/ancestor grants, including resolved alias
        overlaps, are rejected. Every permission defaults to false; unknown names
        and nonboolean values throw. Configuration is copied and never retained.
        Supported permissions: listDirectories, listFiles, recursive, readFiles,
        writeFiles, createFiles, overwriteFiles, createDirectories, deleteFiles,
        deleteDirectories, copyFiles and moveFiles. Parent access covers all
        descendants uniformly; it grants no ancestor access. Namespace changes
        intersecting a grant revoke that entire grant permanently.
        Physical directory deletion revokes grants rooted at/below the deleted
        directory, leaving ancestor grants active. File operations do not revoke
        directory grants. Alias removal/retargeting revokes grants using that alias.
        Existing live grants include newly added descendant content and mounts.
        @param table tGrants Dense list of {path|alias, permissions} records.
        @ret table oAccess Restricted read/write/ls/mkdir/remove/copy/move/listAliases facade.
    !]]
    createAccess = function(this, cdat, tGrants)
        local tState = cdat.pri.state;
        local nCount = denseLength(tGrants);
        local tAccess = {owner = tState, active = true, grants = {}};

        for nIndex = 1, nCount do
            local tInput = rawget(tGrants, nIndex);
            assert(rawtype(tInput) == "table", "VFS: grant must be a table.");
            for sKey in next, tInput do
                assert(sKey == "path" or sKey == "alias" or sKey == "permissions", "VFS: unknown grant field.");
            end
            local pPath, sAlias = rawget(tInput, "path"), rawget(tInput, "alias");
            assert((pPath ~= nil) ~= (sAlias ~= nil), "VFS: specify exactly one path or alias.");
            local tAlias;
            if (sAlias ~= nil) then
                tAlias = tState.aliases[aliasName(sAlias)];
                assert(tAlias, "VFS: grant alias is not defined.");
                pPath = tAlias.path;
            else
                pPath = path(tState, pPath);
            end
            assert(tState.directories[pPath], "VFS: grant directory is not registered.");
            -- Validate physical targets now; synthetic groups have no physical root.
            if (not group(tState, pPath)) then
                local pReal, sKind = native(tState, pPath, false);
                assert(pReal and sKind == "directory", "VFS: grant directory is unavailable.");
            end
            for _, tExisting in ipairs(tAccess.grants) do
                assert(not within(pPath, tExisting.path) and not within(tExisting.path, pPath), "VFS: access grants cannot overlap.");
            end
            local tInputPermissions = rawget(tInput, "permissions");
            assert(tInputPermissions == nil or rawtype(tInputPermissions) == "table", "VFS: permissions must be a table.");
            local tPermissions = {};
            for sName, bValue in next, tInputPermissions or {} do
                assert(_tPermissions[sName] and rawtype(bValue) == "boolean", "VFS: invalid permission name or value.");
                tPermissions[sName] = bValue;
            end
            tAccess.grants[#tAccess.grants + 1] = {
                path = pPath, alias = tAlias, permissions = tPermissions, active = true,
            };
        end

        local oAccess = accessObject(tState, tAccess);
        local tRuntime = _tRuntime[tState];
        if (not tRuntime) then
            tRuntime = {accesses = setmetatable({}, {__mode = "v"}), nextAccess = 0};
            _tRuntime[tState] = tRuntime;
        end
        tRuntime.nextAccess = tRuntime.nextAccess + 1;
        tRuntime.accesses[tRuntime.nextAccess] = tAccess;
        return oAccess;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.revokeAccess
        @desc Permanently disables an entire access object owned by this VFS.
        @param table oAccess Object previously returned by createAccess.
        @ret boolean bOK True, including repeated revocation. Foreign objects throw.
    !]]
    revokeAccess = function(this, cdat, oAccess)
        local tAccess = _tAccessStates[oAccess];
        assert(tAccess and tAccess.owner == cdat.pri.state, "VFS: foreign access object.");
        tAccess.active = false;
        return true;
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.ls
        @desc Owner listing; same record format and defaults as Access.ls without permission restrictions.
        @param string pDirectory Virtual directory or alias.
        @param boolean|nil bRecursive Recurse; default false.
        @param string|nil eKind VFS.FILE, VFS.DIR or VFS.BOTH; default BOTH.
        @ret table tEntries Sorted entries or nil and reason.
    !]]
    ls = function(this, cdat, pDirectory, bRecursive, eKind)
        return operate(cdat.pri.state, nil, "ls", pDirectory, bRecursive, eKind);
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.read
        @desc Reads an existing file as a binary string through the private adapter.
        @param string pPath Virtual path or alias.
        @ret string sData Contents or nil and reason.
    !]]
    read = function(this, cdat, pPath) return operate(cdat.pri.state, nil, "read", pPath); end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.write
        @desc Creates or replaces a whole file; parent directory must already exist.
        @param string pPath Virtual file path.
        @param string sData Binary contents.
        @ret boolean bOK Success or nil and reason.
    !]]
    write = function(this, cdat, pPath, sData) return operate(cdat.pri.state, nil, "write", pPath, sData); end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.mkdir
        @desc Creates one physical directory without implicitly registering it for grants.
        @param string pDirectory Virtual directory path.
        @ret boolean bOK Success or nil and reason.
    !]]
    mkdir = function(this, cdat, pDirectory) return operate(cdat.pri.state, nil, "mkdir", pDirectory); end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.remove
        @desc Deletes physical content; separate from unmount/unregisterDirectory.
        Recursive failures may leave partial deletions. Deleting a granted directory
        or its ancestor revokes that grant; ordinary child deletion preserves access.
        @param string pPath Virtual path.
        @param boolean|nil bRecursive Recurse; default false.
        @ret boolean bOK Success or nil and reason.
    !]]
    remove = function(this, cdat, pPath, bRecursive) return operate(cdat.pri.state, nil, "remove", pPath, bRecursive); end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.copy
        @desc Copies one physical file; destination parents must exist.
        @param string pSource Source virtual path.
        @param string pDestination Destination virtual path.
        @param boolean|nil bOverwrite Allow replacement; default false.
        @ret boolean bOK Success or nil and reason.
    !]]
    copy = function(this, cdat, pSource, pDestination, bOverwrite)
        return transfer(cdat.pri.state, nil, false, pSource, pDestination, bOverwrite);
    end,

    --[[!
        @fqxn LuaEx.Classes.VFS.Methods.move
        @desc Renames one physical file. Cross-device moves may fail without mutation.
        @param string pSource Source virtual path.
        @param string pDestination Destination virtual path.
        @param boolean|nil bOverwrite Allow replacement; default false.
        @ret boolean bOK Success or nil and reason.
    !]]
    move = function(this, cdat, pSource, pDestination, bOverwrite)
        return transfer(cdat.pri.state, nil, true, pSource, pDestination, bOverwrite);
    end,
},
nil,
true,
nil);
