-- LuaEx I/O API backed by its own native filesystem library.
-- The standard io functions remain installed; only LuaEx extensions are added.
local io        = io;
local string    = string;
local table     = table;
local type      = type;
local rawtype   = rawtype;
local pcall     = pcall;
local tostring  = tostring;
local _bOSIsWindows = package.config:sub(1, 1) == "\\";
local _pLuaEx = assert(debug.getinfo(1, "S").source:match("^@(.+)[/\\]hook[/\\]iohook%.lua$"),
    "Unable to resolve the LuaEx I/O library directory.");
local _sLuaMajor, _sLuaMinor = _VERSION:match("Lua (%d+)%.(%d+)");
local _pNative = _pLuaEx.."/bin/luaex_io-lua".._sLuaMajor.._sLuaMinor.."-";
local _tSystems = _bOSIsWindows and {"windows-x64", "windows-arm64"} or
    {"linux-x64", "linux-arm64", "macos-x64", "macos-arm64"};
local _sExtension = _bOSIsWindows and ".dll" or ".so";
local _tNative;
local _tReasons = {};

-- Loading the native module performs no directory scan and starts no process.
for _, sSystem in ipairs(_tSystems) do
    local pLibrary = _pNative..sSystem.._sExtension;
    local fOpen, sReason = package.loadlib(pLibrary, "luaopen_luaex_io");

    if (fOpen) then
        _tNative = fOpen();
        assert(type(_tNative) == "table" and _tNative.Version == 1, "Unsupported LuaEx I/O native ABI.");
        break;
    end
    _tReasons[#_tReasons + 1] = pLibrary..": "..tostring(sReason);
end
assert(_tNative, "No compatible LuaEx I/O library for ".._VERSION..". Build/install the native module.\n"..
    table.concat(_tReasons, "\n"));

--[[!
    @fqxn LuaEx.Lua Hooks.io.splitpath
    @pulsarlua function io.splitpath
    @desc Splits a filesystem path into its constituent components.
    <br>Supports Windows and Unix-style paths.
    <br>Extensions are returned without the dot.
    <br>Dotfiles (e.g. ".gitignore") return an empty filename and a populated extension.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- Trims trailing path separators (both "/" and "\").
    <br>- On Windows, captures a drive prefix (e.g. "C:") when present.
    <br>- The returned <code>directory</code> is the parent path portion (without the trailing separator).
    <br>- The returned <code>filename</code> is the leaf name without extension.
    <br>- The returned <code>extension</code> is the leaf extension without dot, only when a non-empty stem exists.
    @param string sPath The filesystem path to split.
    @ret table tParts A table containing the split path components.
    <br><strong>Fields:</strong>
    <br><code>directory</code> – Parent directory path (without trailing separator)
    <br><code>drive</code> – Drive prefix (Windows only, otherwise empty)
    <br><code>filename</code> – Leaf name without extension
    <br><code>extension</code> – Leaf extension without dot
    @ex
    local t = io.splitpath("C:\\Windows\\System32\\notepad.exe");

    --\[\[ Output->
    {
        drive     = "C:",
        directory = "C:\\Windows\\System32",
        filename  = "notepad",
        extension = "exe"
    }
    \]\];

    t = io.splitpath(".gitignore");

    --\[\[ Output->
    {
        drive     = "",
        directory = "",
        filename  = "",
        extension = "gitignore"
    }
    \]\];
!]]
local function splitpath(sPath);

    local tRet = {
        directory = "",
        drive     = "",
        extension = "",
        filename  = "",
    };

    local sWork     = "";
    local sDrive    = "";
    local bAbsolute = false;

    local sRootSep  = "/";
    local sDirPart  = nil;
    local sLeaf     = "";
    local sStem     = nil;
    local sExt      = nil;

    if not (rawtype(sPath) == "string") then
        error("io.splitpath: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.splitpath: path cannot be empty.", 2);
    end

    sWork = sPath;

    -- Decide output separator by path style (not host OS).
    -- If it has a drive or any backslash, treat as Windows-style output.
    if (sWork:match("^[A-Za-z]:") or sWork:find("\\", 1, true)) then
        sRootSep = "\\";
    end

    -- Capture drive (Windows-style), regardless of host OS.
    sDrive = sWork:match("^([A-Za-z]:)");
    if (rawtype(sDrive) == "string" and sDrive ~= "") then
        tRet.drive = sDrive;
        sWork = sWork:sub(#sDrive + 1);
    end

    -- Detect absolute root and strip leading separators (we’ll re-add exactly one root sep).
    if (sWork:match("^[\\/]+")) then
        bAbsolute = true;
        sWork = sWork:gsub("^[\\/]+", "");
    else
        -- Unix absolute without drive: "/..."
        if (tRet.drive == "" and sPath:sub(1, 1) == "/") then
            bAbsolute = true;
        end
    end

    -- Trim trailing separators.
    sWork = sWork:gsub("[/\\]+$", "");

    -- If nothing left (e.g. "C:\", "C:", "/", "////"), return empty parts (drive may be set).
    if (sWork ~= "") then

        -- Normalize remaining separators to our chosen root separator.
        sWork = sWork:gsub("[/\\]+", sRootSep);

        -- Split into directory + leaf.
        sDirPart, sLeaf = sWork:match("^(.*)"..sRootSep.."([^"..sRootSep.."]+)$");
        if (rawtype(sDirPart) == "string") then
            tRet.directory = tRet.drive..(bAbsolute and sRootSep or "")..sDirPart;
            tRet.filename  = rawtype(sLeaf) == "string" and sLeaf or "";
        else
            tRet.filename = sWork;
            tRet.directory = tRet.drive..(bAbsolute and sRootSep or "");
        end

        -- Extension handling:
        -- - normal files: "name.ext" => filename="name", extension="ext"
        -- - dotfiles: ".gitignore" => filename="", extension="gitignore"
        sStem, sExt = tRet.filename:match("^(.*)%.([^.]+)$");
        if (rawtype(sStem) == "string" and sStem ~= "") then
            tRet.filename  = sStem;
            tRet.extension = rawtype(sExt) == "string" and sExt or "";
        else

            if (tRet.filename:sub(1, 1) == "." and not tRet.filename:sub(2):find("%.", 1, true)) then
                sExt = tRet.filename:sub(2);

                if (sExt ~= "") then
                    tRet.filename  = "";
                    tRet.extension = sExt;
                end

            end

        end

    end

    return tRet;
end

--[[!
    @fqxn LuaEx.Lua Hooks.io.getenddir
    @pulsarlua function io.getenddir
    @desc Returns the final directory name in a filesystem path.
    <br>This works consistently across Windows and Unix-style paths.
    <br>If the path points to a file, the parent directory’s final segment is returned.
    <br>If the path points to a directory, that directory’s name is returned.
    @param string pPath The filesystem path to inspect.
    @ret string sEndDir The name of the last directory in the path, or an empty string if none exists.
    @ex
    io.getenddir("C:\\Windows\\System32\\notepad.exe");
    --\[\[ Output->
    System32
    \]\]

    io.getenddir("/usr/local/bin/");
    --\[\[ Output->
    bin
    \]\]

    io.getenddir("C:\\");
    --\[\[ Output->
    ""
    \]\]
!]]
function io.getenddir(vPath)
    local sRet = "";

    if not (rawtype(vPath) == "string") then
        error("io.getenddir: path must be of type string. Got "..rawtype(vPath)..".", 2);
    end

    if (vPath == "") then
        error("io.getenddir: path cannot be empty.", 2);
    end

    -- Track whether caller explicitly indicated "directory" via trailing separator(s).
    local bHadTrailingSep = (vPath:match("[/\\]$") ~= nil);

    -- Trim trailing separators (both styles).
    local sPath = vPath:gsub("[/\\]+$", "");

    if (sPath == "") then
        -- Path was only separators ("/", "////", "\\", etc.)
        return "";
    end

    if (_bOSIsWindows and sPath:match("^[A-Za-z]:$")) then
        -- Windows root like "C:\" becomes "C:" after trim.
        return "";
    end

    local tParts = splitpath(sPath);

    if not (rawtype(tParts) == "table") then
        error("io.getenddir: splitpath failed to return a table.", 2);
    end

    -- If caller gave a trailing slash, treat it as a directory path no matter what.
    if (bHadTrailingSep) then
        return sPath:match("([^/\\]+)$") or "";
    end

    -- If splitpath exposes a filename, prefer it (handles extensionless files like ".ignore").
    if (rawtype(tParts.filename) == "string" and tParts.filename ~= "") then
        return tParts.filename;
    end

    -- Otherwise treat it as a directory path; return the last segment.
    sRet = sPath:match("([^/\\]+)$") or "";

    return sRet;
end
function io.getenddirOLD(vPath);
    local sRet  = "";

    if not (rawtype(vPath) == "string") then
        error("io.getenddir: path must be of type string. Got "..rawtype(vPath)..".", 2);
    end

    if (vPath == "") then
        error("io.getenddir: path cannot be empty.", 2);
    end

    -- Trim trailing separators (both styles).
    local sPath = vPath:gsub("[/\\]+$", "");

    if (sPath == "") then
        -- Path was only separators ("/", "////", "\\", etc.)
        sRet = "";
    elseif (_bOSIsWindows and sPath:match("^[A-Za-z]:$")) then
        -- Windows root like "C:\" becomes "C:" after trim.
        sRet = "";
    else

        local tParts = splitpath(sPath);

        if not (rawtype(tParts) == "table") then
            error("io.getenddir: splitpath failed to return a table.", 2);
        end

        -- If it looks like a file path (has an extension), return the last folder from the directory portion.
        if (rawtype(tParts.extension) == "string" and tParts.extension ~= "") then

            local sDir = rawtype(tParts.directory) == "string" and tParts.directory or "";
            sDir = sDir:gsub("[/\\]+$", "");
            sRet = sDir:match("([^/\\]+)$") or "";

        else
            -- Otherwise treat it as a directory path; return the last segment.
            sRet = sPath:match("([^/\\]+)$") or "";
        end

    end

    return sRet;
end

function io.getenddirOLD(vPath);
    local sRet  = "";

    if not (rawtype(vPath) == "string") then
        error("io.getenddir: path must be of type string. Got "..rawtype(vPath)..".", 2);
    end

    if (vPath == "") then
        error("io.getenddir: path cannot be empty.", 2);
    end

    -- Trim trailing separators (both styles).
    local sPath = vPath:gsub("[/\\]+$", "");

    if (sPath == "") then
        -- Path was only separators ("/", "////", "\\", etc.)
        sRet = "";
    elseif (_bOSIsWindows and sPath:match("^[A-Za-z]:$")) then
        -- Windows root like "C:\" becomes "C:" after trim.
        sRet = "";
    else

        local tParts = splitpath(sPath);

        if not (rawtype(tParts) == "table") then
            error("io.getenddir: splitpath failed to return a table.", 2);
        end

        -- If it looks like a file path (has an extension), return the last folder from the directory portion.
        if (rawtype(tParts.extension) == "string" and tParts.extension ~= "") then

            local sDir = rawtype(tParts.directory) == "string" and tParts.directory or "";
            sDir = sDir:gsub("[/\\]+$", "");
            sRet = sDir:match("([^/\\]+)$") or "";

        else
            -- Otherwise treat it as a directory path; return the last segment.
            sRet = sPath:match("([^/\\]+)$") or "";
        end

    end

    return sRet;
end

--[[!
    @fqxn LuaEx.Lua Hooks.io.getuserdir
    @pulsarlua function io.getuserdir
    @desc Returns the current user’s home directory as defined by environment variables.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Attempts to read the <code>HOME</code> environment variable.
    <br>- If <code>HOME</code> is not set or empty, attempts to read <code>USERPROFILE</code>.
    <br>- If neither variable is present or valid, throws an error.
    <br>- Does not query the filesystem or validate path existence.
    <br>- Returns a single string value or fails explicitly.
    @ret string sUserDir The resolved user home directory path.
    @ex
    local pHome = io.getuserdir();
    print(pHome);
!]]
function io.getuserdir();

    local sHome = nil;

    sHome = os.getenv("HOME");
    if (rawtype(sHome) ~= "string" or sHome == "") then
        sHome = os.getenv("USERPROFILE");
    end

    if (rawtype(sHome) ~= "string" or sHome == "") then
        error("io.getuserdir: unable to determine user home directory from environment.", 2);
    end

    return sHome;
end

--[[!
    @fqxn LuaEx.Lua Hooks.io.isdirectchild
    @pulsarlua function io.isdirectchild
    @desc Determines whether one path is a <em>direct child</em> of another path.
    <br>
    <br>This function performs a strict, structural comparison:
    <br>- <code>pChild</code> must be exactly one directory level below <code>pParent</code>.
    <br>- The parent portion of <code>pChild</code> must match <code>pParent</code> exactly after normalization.
    <br>- Deeper descendants are rejected.
    <br>- Partial or substring matches are rejected.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires both paths to be non-empty strings.
    <br>- Normalizes both paths before comparison.
    <br>- Trailing path separators are ignored.
    <br>- Does not query the filesystem; this is a pure path-structure check.
    <br>- Works consistently across Windows and Unix-style paths.
    @param string pParent The parent directory path.
    @param string pChild The path being tested as a direct child.
    @ret boolean bIsDirectChild <code>true</code> if <code>pChild</code> is directly inside <code>pParent</code>; otherwise <code>false</code>.
    @ex
    io.isdirectchild("C:\\Games", "C:\\Games\\MyGame");
    -- true

    io.isdirectchild("C:\\Games", "C:\\Games\\MyGame\\bin");
    -- false

    io.isdirectchild("/opt/games", "/opt/games/game1");
    -- true
!]]
function io.isdirectchild(pParent, pChild)

    if not (rawtype(pParent) == "string") then
        error("io.isdirectchild: parent path must be string.", 2)
    end

    if not (rawtype(pChild) == "string") then
        error("io.isdirectchild: child path must be string.", 2)
    end

    if (pParent == "" or pChild == "") then
        error("io.isdirectchild: paths cannot be empty.", 2)
    end

    -- Trim trailing separators
    pParent = pParent:gsub("[/\\]+$", "")
    pChild  = pChild:gsub("[/\\]+$", "")

    -- Find last separator in child
    local parentPart, leaf = pChild:match("^(.*)[/\\]([^/\\]+)$")
    if not parentPart or not leaf or leaf == "" then
        return false
    end

    -- STRICT equality
    return parentPart == pParent
end

--[[!
    @fqxn LuaEx.Lua Hooks.io.normalizepath
    @pulsarlua function io.normalizepath
    @desc Normalizes a path string by removing "." segments, resolving ".." segments,
    <br>and rebuilding the path using the current OS separator.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Treats both "/" and "\" as separators when splitting.
    <br>- Removes "." segments.
    <br>- Resolves ".." by removing the previous segment when possible.
    <br>- On Windows, preserves a leading drive letter segment (e.g. "C:") if present.
    <br>- On Unix, preserves a leading "/" only if the input path started with "/".
    <br>- On Windows, if no drive letter is present, the result is forced to begin with "\".
    <br>- Does not query the filesystem; this is purely string-based normalization.
    @param string path The path string to normalize.
    @ret string pNormalized The normalized path string.
    @ex
    io.normalizepath("C:\\Windows\\System32\\..\\notepad.exe");
    --\[\[ Output->
    C:\Windows\notepad.exe
    \]\]

    io.normalizepath("/usr/local/../bin/");
    --\[\[ Output->
    /usr/bin
    \]\]

    io.normalizepath("foo/./bar/../baz");
    --\[\[ Output->
    \foo\baz
    \]\]
!]]
function io.normalizepath(sPath);

    local tParts       = {};
    local sDrive       = nil;
    local sRet         = "";

    if not (rawtype(sPath) == "string") then
        error("io.normalizepath: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.normalizepath: path cannot be empty.", 2);
    end

    for sPart in sPath:gmatch("[^/\\]+") do

        if (_bOSIsWindows and not sDrive) then

            sDrive = sPart:match("^[A-Za-z]:$");
            if (sDrive) then
                tParts[#tParts + 1] = sDrive;
            else
                if (sPart == "..") then
                    if (#tParts > 0 and tParts[#tParts] ~= sDrive) then
                        table.remove(tParts);
                    end
                elseif (sPart ~= ".") then
                    tParts[#tParts + 1] = sPart;
                end
            end

        else

            if (sPart == "..") then
                if (#tParts > 0 and tParts[#tParts] ~= sDrive) then
                    table.remove(tParts);
                end
            elseif (sPart ~= ".") then
                tParts[#tParts + 1] = sPart;
            end

        end

    end

    local sSep = _bOSIsWindows and "\\" or "/";
    sRet = table.concat(tParts, sSep);

    if (_bOSIsWindows and sDrive) then
        sRet = sDrive .. "\\" .. table.concat(tParts, sSep, 2);
    elseif (_bOSIsWindows) then
        sRet = "\\" .. sRet;
    else
        if (sPath:sub(1, 1) == "/") then
            sRet = "/" .. sRet;
        end
    end

    return sRet;
end

--[[!
@fqxn LuaEx.Lua Hooks.io.listfiles
@desc Lists child files through the native filesystem, optionally recursively.
    Extensions are case-insensitive and omit the dot. Results are sorted canonical paths;
    callbacks receive (path, true). Directory identities prevent link cycles.
    Listing or callback errors return nil and a reason; empty success returns {}.
@param string sPath Directory to inspect.
@param boolean|nil bRecursive Whether to visit descendant directories.
@param function|nil fCallback Per-result callback.
@param string ... Optional extension filters.
@ret table|nil tPaths Matching file paths.
@ret string|nil sReason Failure description.
!]]
local function pathArgument(sPath, sCaller)
    assert(rawtype(sPath) == "string" and sPath ~= "" and not sPath:find("%z"),
        sCaller..": expected a nonempty path without NUL bytes.");
    return sPath;
end

local function listPaths(tRoots, bRecursive, fCallback, bFiles, bOptional, ...)
    assert(bRecursive == nil or rawtype(bRecursive) == "boolean", "Recursive must be boolean or nil.");
    assert(fCallback == nil or rawtype(fCallback) == "function", "Callback must be a function or nil.");
    local tTypes, tPaths, tVisited, tFiles = {...}, {}, {}, {};
    local tScan = {Roots = {}, Directories = 0};
    local nTypes = select("#", ...);

    for nIndex = 1, nTypes do
        local sType = tTypes[nIndex];
        assert(rawtype(sType) == "string" and sType ~= "" and not sType:find('[.%z]'),
            "Extension filters must be nonempty strings without dots or NUL bytes.");
    end
    local function fVisit(pDirectory, nDepth, tInfo)
        assert(nDepth < 1024, "Directory traversal exceeded its depth limit.");
        local sIdentity = _bOSIsWindows and tInfo.Identity:lower() or tInfo.Identity;
        if (tVisited[sIdentity]) then return; end
        tVisited[sIdentity] = true;
        tScan.Directories = tScan.Directories + 1;
        local tEntries, sReason = _tNative.list(pDirectory, true);
        assert(tEntries, sReason);
        for _, tEntry in ipairs(tEntries) do
            local tStatus = tEntry;
            if (tStatus.Kind == "directory") then
                if (not bFiles) then tPaths[#tPaths + 1] = tEntry.Path; end
                if (bRecursive) then fVisit(tEntry.Path, nDepth + 1, tStatus); end
            elseif (bFiles and tStatus.Kind == "file") then
                local bInclude = nTypes == 0;
                local sExtension = (tEntry.Name:match("%.([^%.]+)$") or ""):lower();
                for _, sType in ipairs(tTypes) do
                    if (sType:lower() == sExtension) then bInclude = true; break; end
                end
                local sFile = _bOSIsWindows and tStatus.Identity:lower() or tStatus.Identity;
                if (bInclude and (not bOptional or not tFiles[sFile])) then
                    tPaths[#tPaths + 1] = tStatus.Identity;
                    tFiles[sFile] = true;
                end
            end
        end
    end
    local bOK, sReason = pcall(function()
        for _, pRoot in ipairs(tRoots) do
            local tInfo, sError, nCode = _tNative.stat(pRoot);
            if (not tInfo) then
                local bMissing = nCode == 2 or nCode == 20 or _bOSIsWindows and (nCode == 3 or nCode == 267);
                assert(bOptional and bMissing, sError);
            elseif (tInfo.Kind ~= "directory") then
                assert(bOptional, "Not a directory: "..pRoot);
            else
                tScan.Roots[pRoot] = tInfo.Identity;
                fVisit(pRoot, 0, tInfo);
            end
        end
        table.sort(tPaths);
        if (fCallback) then
            for _, pPath in ipairs(tPaths) do fCallback(pPath, bFiles); end
        end
    end);
    if (not bOK) then return nil, tostring(sReason); end
    return tPaths, nil, tScan;
end

function io.listfiles(sPath, bRecursive, fCallback, ...)
    pathArgument(sPath, "io.listfiles");
    local tPaths, sReason = listPaths({sPath}, bRecursive, fCallback, true, false, ...);
    return tPaths, sReason;
end

--[[!
@fqxn LuaEx.Lua Hooks.io.scanfiles
@desc Recursively lists files across a dense array of roots with one shared
    canonical-directory visited set. Relative, absolute, overlapping and linked
    roots do not repeat a directory's contents. Canonical file paths are deduplicated
    and sorted. Missing/non-directory optional roots are skipped; access/listing
    failures return nil and a reason. Filters remain generic and case-insensitive.
@param table tRoots Dense array of directory paths; an empty array succeeds.
@param string ... Optional extension filters, without dots.
@ret table|nil tPaths Matching canonical file paths.
@ret string|nil sReason Failure reason, nil on success.
@ret table|nil tScan Roots maps supplied paths to resolved directory identities;
    Directories counts distinct directories enumerated during this call.
!]]
function io.scanfiles(tRoots, ...)
    assert(rawtype(tRoots) == "table" and getmetatable(tRoots) == nil, "io.scanfiles: roots must be a plain array.");
    local nCount = 0;
    for nIndex, pRoot in pairs(tRoots) do
        assert(rawtype(nIndex) == "number" and nIndex % 1 == 0 and nIndex >= 1 and nIndex <= #tRoots,
            "io.scanfiles: roots must be a dense array.");
        pathArgument(pRoot, "io.scanfiles");
        nCount = nCount + 1;
    end
    assert(nCount == #tRoots, "io.scanfiles: roots must be a dense array.");
    return listPaths(tRoots, true, nil, true, true, ...);
end

--[[!
@fqxn LuaEx.Lua Hooks.io.listdirs
@desc Lists child directories; excludes the queried directory itself on every
    platform. Recursive traversal follows directory links with cycle detection.
    Callbacks receive (path, false); errors return nil and a reason.
@param string sPath Directory to inspect.
@param boolean|nil bRecursive Whether to visit descendants.
@param function|nil fCallback Per-result callback.
@ret table|nil tPaths Sorted directory paths.
@ret string|nil sReason Failure description.
!]]
function io.listdirs(sPath, bRecursive, fCallback)
    pathArgument(sPath, "io.listdirs");
    local tPaths, sReason = listPaths({sPath}, bRecursive, fCallback, false, false);
    return tPaths, sReason;
end

function io.list(sPath, bRecursive, fCallback, ...)
    local tDirectories, sReason = io.listdirs(sPath, bRecursive);
    if (not tDirectories) then return nil, sReason; end
    local tFiles;
    tFiles, sReason = io.listfiles(sPath, bRecursive, nil, ...);
    if (not tFiles) then return nil, sReason; end
    if (fCallback ~= nil) then
        assert(rawtype(fCallback) == "function", "Callback must be a function or nil.");
        local bOK;
        bOK, sReason = pcall(function()
            for _, pDirectory in ipairs(tDirectories) do fCallback(pDirectory, false); end
            for _, pFile in ipairs(tFiles) do fCallback(pFile, true); end
        end);
        if (not bOK) then return nil, tostring(sReason); end
    end
    for _, pFile in ipairs(tFiles) do tDirectories[#tDirectories + 1] = pFile; end
    return tDirectories;
end

function io.exists(sPath)
    pathArgument(sPath, "io.exists");
    local tInfo, sReason, nCode = _tNative.stat(sPath);
    return tInfo ~= nil, sReason, nCode;
end
function io.isdir(sPath)
    pathArgument(sPath, "io.isdir");
    local tInfo, sReason, nCode = _tNative.stat(sPath);
    return tInfo ~= nil and tInfo.Kind == "directory", sReason, nCode;
end
function io.isfile(sPath)
    pathArgument(sPath, "io.isfile");
    local tInfo, sReason, nCode = _tNative.stat(sPath);
    return tInfo ~= nil and tInfo.Kind == "file", sReason, nCode;
end

-- Native mutations return true or nil, reason, native error code. No command
-- exit statuses, permission-expression injection, or command-line tools remain.
io.mkdir  = _tNative.mkdir;
io.copy   = _tNative.copy;
io.move   = _tNative.move;
io.delete = _tNative.delete;
io.rmdir  = _tNative.rmdir;

--[[!
@fqxn LuaEx.Lua Hooks.io.chmod
@desc Sets portable rwx mode bits. Accepts octal text such as "755", numeric
    bits, or symbolic u/g/o/a clauses. Windows only represents limited mode bits;
    this API does not interpret Windows ACL/icacls expressions.
@param string|number vPermission Octal, numeric or symbolic mode.
@param string sPath Target path.
@ret boolean|nil bSuccess True on success.
@ret string|nil sReason Failure description.
!]]
function io.chmod(vPermission, sPath)
    pathArgument(sPath, "io.chmod");
    local nMode = rawtype(vPermission) == "number" and vPermission or nil;
    if (rawtype(vPermission) == "string") then
        if (vPermission:match("^[0-7][0-7]?[0-7]?$") or vPermission:match("^0[0-7][0-7][0-7]$")) then
            nMode = tonumber(vPermission, 8);
        else
            local tInfo, sReason = _tNative.stat(sPath);
            if (not tInfo) then return nil, sReason; end
            nMode = tInfo.Permissions;
            local nClauses = 0;
            for sClause in (vPermission..","):gmatch("([^,]*),") do
                local sWho, sOperation, sBits = sClause:match("^([ugoa]*)([+=%-])([rwx]*)$");
                if (not sOperation) then return nil, "Expected octal or symbolic rwx permissions; ACL expressions are unsupported."; end
                local nBits = (sBits:find("r", 1, true) and 4 or 0) |
                    (sBits:find("w", 1, true) and 2 or 0) | (sBits:find("x", 1, true) and 1 or 0);
                local nMask, nValue = 0, 0;
                for _, tGroup in ipairs({{"u", 6}, {"g", 3}, {"o", 0}}) do
                    if (sWho == "" or sWho:find("a", 1, true) or sWho:find(tGroup[1], 1, true)) then
                        nMask = nMask | (7 << tGroup[2]);
                        nValue = nValue | (nBits << tGroup[2]);
                    end
                end
                if (sOperation == "=") then nMode = (nMode & ~nMask) | nValue;
                elseif (sOperation == "+") then nMode = nMode | nValue;
                else nMode = nMode & ~nValue; end
                nClauses = nClauses + 1;
            end
            if (nClauses == 0) then return nil, "Empty permissions."; end
        end
    end
    assert(rawtype(nMode) == "number" and nMode % 1 == 0 and nMode >= 0 and nMode <= 511,
        "Permissions must represent octal 000..777.");
    return _tNative.chmod(sPath, nMode);
end

function io.findfile(sFilename, pRoot)
    pathArgument(sFilename, "io.findfile");
    assert(not sFilename:find("[/\\]"), "findfile expects a filename, not a path.");
    pRoot = pRoot or assert(_tNative.root());
    pathArgument(pRoot, "io.findfile");
    local tVisited = {};
    local function fFind(pDirectory)
        local tInfo = _tNative.stat(pDirectory);
        if (not tInfo or tInfo.Kind ~= "directory") then return; end
        local sIdentity = _bOSIsWindows and tInfo.Identity:lower() or tInfo.Identity;
        if (tVisited[sIdentity]) then return; end
        tVisited[sIdentity] = true;
        local tEntries = _tNative.list(pDirectory);
        if (not tEntries) then return; end
        for _, tEntry in ipairs(tEntries) do
            local tStatus = _tNative.stat(tEntry.Path);
            if (tStatus and tStatus.Kind == "file" and tEntry.Name == sFilename) then return tEntry.Path; end
        end
        for _, tEntry in ipairs(tEntries) do
            local tStatus = _tNative.stat(tEntry.Path);
            if (tStatus and tStatus.Kind == "directory") then
                local pFound = fFind(tEntry.Path);
                if (pFound) then return pFound; end
            end
        end
    end
    return fFind(pRoot);
end

local function searchText(sPattern, sPath, bLiteral)
    assert(rawtype(sPattern) == "string" and sPattern ~= "", "Expected nonempty search text.");
    local fLines;
    if (sPath ~= nil) then
        pathArgument(sPath, "io text search");
        local sData, sReason = _tNative.read(sPath);
        if (not sData) then return nil, sReason; end
        local nPosition = 1;
        fLines = function()
            if (nPosition > #sData) then return; end
            local nEnd = sData:find("\n", nPosition, true);
            local sLine = sData:sub(nPosition, (nEnd or #sData + 1) - 1);
            nPosition = nEnd and nEnd + 1 or #sData + 1;
            return sLine;
        end;
    else
        fLines = io.stdin:lines();
    end
    local nMatches = 0;
    local bOK, sReason = pcall(function()
        for sLine in fLines do
            if (sLine:find(sPattern, 1, bLiteral)) then
                assert(io.stdout:write(sLine.."\n"));
                nMatches = nMatches + 1;
            end
        end
    end);
    if (not bOK) then return nil, tostring(sReason); end
    return nMatches > 0, nMatches;
end

function io.findstr(sText, sPath) return searchText(sText, sPath, true); end
function io.grep(sPattern, sPath) return searchText(sPattern, sPath, false); end

function io.zip(tFiles, sDestination)
    return require("LuaEx.lib.io.Archive").write(tFiles, sDestination, _tNative);
end
function io.unzip(sArchive, sDestination)
    return require("LuaEx.lib.io.Archive").extract(sArchive, sDestination, _tNative);
end

io.splitpath = splitpath;
return io;
