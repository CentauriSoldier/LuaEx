local string    = string;
local table     = table;
local execute   = os.execute;
local io        = io;
local type      = type;
local rawtype   = rawtype;

-- Define the os type
local _         = package.config:sub(1, 1);
local __        = _ == "/" and "\\" or "/";
local _sOSType  = _ == "\\" and "windows" or (_ == "/" and "unix" or "unknown");

-- Determine the operating system type
local _bOSIsWindows     = _sOSType == "windows";
local _bOSIsUnix        = _sOSType == "unix";
local _bOSIsUnknown     = _sOSType == "unknown";
local _sParent          = "..";
local _pRoot            = ".";


--[[
██╗      ██████╗  ██████╗ █████╗ ██╗         ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
██║     ██╔═══██╗██╔════╝██╔══██╗██║         ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
██║     ██║   ██║██║     ███████║██║         █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
██║     ██║   ██║██║     ██╔══██║██║         ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
███████╗╚██████╔╝╚██████╗██║  ██║███████╗    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
]]


--[[!
    @fqxn LuaEx.Lua Hooks.io.splitpath
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
            tRet.directory = (bAbsolute and sRootSep or "")..sDirPart;
            tRet.filename  = rawtype(sLeaf) == "string" and sLeaf or "";
        else
            tRet.filename = sWork;
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
    @fqxn LuaEx.Lua Hooks.io.listfiles
    @desc Lists all files in a given path (optionally recursively).
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- If <code>bRecursive</code> is provided, it must be a boolean.
    <br>- If <code>fCallback</code> is provided, it must be a function.
    <br>- Rejects <code>sPath</code> containing double quotes or CR/LF characters.
    <br>- Optional filetype filters may be provided as additional string arguments (extensions without dots).
    <br>- When filters are provided, only files whose extension matches (case-insensitive) are returned.
    <br>- On Windows, executes <code>dir /b /a-d</code> with optional <code>/s</code>.
    <br>- On Unix-like systems, executes <code>find</code> with <code>-type f</code> and optional <code>-maxdepth 1</code>.
    <br>- When not recursive on Windows, results are prefixed with <code>sPath</code>.
    <br>- If a callback is provided, it is invoked as <code>fCallback(pFile, true)</code> for each included file.
    @param string sPath The path which to search for files.
    @param boolean|nil bRecursive Whether to recurse through subdirectories.
    @param function|nil fCallback Optional callback invoked per included file.
    @param string ... Optional file extension filters (without dots), e.g. <code>"exe"</code>, <code>"png"</code>.
    @ret table tFiles A numerically-indexed table of full file paths.
    @ex
    local function printfile(pFile)
        print(pFile);
    end

    local tFiles = io.listfiles("C:\\Windows\\System32", false, printfile, "exe");
    @note <strong>On Windows</strong>: if your host process is 32-bit, Windows <em>may</em> redirect System32 → SysWOW64, so total file count can differ from Explorer's count. Use 'Sysnative' instead of 'System32' in your path if you need the real 64-bit System32.
!]]
local function listfiles(sPath, vRecursive, fCallback, ...);
    local tRet          = {};
    local sCmd          = "";
    local tTypes        = {...};
    local bCheckTypes   = false;
    local bHasCallback  = false;
    local bRecursive    = rawtype(vRecursive) == "boolean" and vRecursive or false;
    local sRecurse      = "";

    if not (rawtype(sPath) == "string") then
        error("io.listfiles: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.listfiles: path cannot be empty.", 2);
    end

    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.listfiles: path cannot contain CR/LF or double quotes (").', 2);
    end

    if (fCallback ~= nil and rawtype(fCallback) ~= "function") then
        error("io.listfiles: callback must be of type function or nil. Got "..rawtype(fCallback)..".", 2);
    end

    bHasCallback = rawtype(fCallback) == "function";
    bCheckTypes  = rawtype(tTypes) == "table" and #tTypes > 0;

    if (bCheckTypes) then

        for i = 1, #tTypes do

            if not (rawtype(tTypes[i]) == "string") then
                error("io.listfiles: filetype at index "..i.." must be of type string. Got "..rawtype(tTypes[i])..".", 2);
            end

            if (tTypes[i] == "") then
                error("io.listfiles: filetype at index "..i.." cannot be empty.", 2);
            end

            if (tTypes[i]:find('[\r\n".]', 1, false)) then
                error('io.listfiles: filetype filters cannot contain CR/LF, double quotes ("), or dots (.).', 2);
            end

        end

    end

    if (_bOSIsWindows) then

        sRecurse = bRecursive and " /s" or "";
        sCmd     = 'dir "'..sPath..'" /b /a-d'..sRecurse..' 2>nul';

    elseif (_bOSIsUnix) then

        sRecurse = bRecursive and "" or " -maxdepth 1";
        sCmd     = 'find "'..sPath..'"'..sRecurse..' -type f 2>/dev/null';

    else
        error("io.listfiles: unsupported operating system.", 2);
    end

    local uPipe = io.popen(sCmd);
    if (uPipe) then

        for sLine in uPipe:lines() do

            local pFile     = nil;
            local bInclude  = not bCheckTypes;

            if (_bOSIsWindows and not bRecursive) then
                pFile = sPath.._..sLine:gsub(__, _);
            else
                pFile = _bOSIsWindows and sLine:gsub(__, _) or sLine;
            end

            if not (bInclude) then

                local tParts    = splitpath(pFile);
                local sExt      = (rawtype(tParts) == "table" and rawtype(tParts.extension) == "string") and tParts.extension:lower() or "";

                for i = 1, #tTypes do
                    if (tTypes[i]:lower() == sExt) then
                        bInclude = true;
                        break;
                    end
                end

            end

            if (bInclude) then

                tRet[#tRet + 1] = pFile;

                if (bHasCallback) then
                    fCallback(pFile, true);
                end

            end

        end

        uPipe:close();

    end

    return tRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.listdirs
    @desc Lists all directories in a given path (optionally recursively).
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- If <code>bRecursive</code> is provided, it must be a boolean.
    <br>- If <code>fCallback</code> is provided, it must be a function.
    <br>- Rejects <code>sPath</code> containing double quotes or CR/LF characters.
    <br>- On Windows, executes <code>dir /b /ad</code> with optional <code>/s</code>.
    <br>- On Unix-like systems, executes <code>find</code> with <code>-type d</code> and optional <code>-maxdepth 1</code>.
    <br>- Returned directory paths have trailing separators removed.
    <br>- When not recursive, Windows results are prefixed with <code>sPath</code>.
    <br>- If a callback is provided, it is invoked as <code>fCallback(pDir, false)</code> for each found directory.
    @param string sPath The path which to search for directories.
    @param boolean|nil bRecursive Whether to recurse through subdirectories.
    @param function|nil fCallback Optional callback invoked per directory found.
    @ret table tDirectories A numerically-indexed table of full directory paths.
    @ex
    local function printdir(pDir)
        print(pDir);
    end

    local tDirectories = io.listdirs("C:\\Windows\\System32\\Speech", true, printdir);
!]]
local function listdirs(sPath, vRecursive, fCallback);

    local tRet          = {};
    local sCmd          = "";
    local bHasCallback  = false;
    local bRecursive    = rawtype(vRecursive) == "boolean" and vRecursive or false;
    local sRecurse      = "";

    if not (rawtype(sPath) == "string") then
        error("io.listdirs: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.listdirs: path cannot be empty.", 2);
    end

    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.listdirs: path cannot contain CR/LF or double quotes (").', 2);
    end

    if (fCallback ~= nil and rawtype(fCallback) ~= "function") then
        error("io.listdirs: callback must be of type function or nil. Got "..rawtype(fCallback)..".", 2);
    end

    bHasCallback = rawtype(fCallback) == "function";

    if (_bOSIsWindows) then

        sRecurse = bRecursive and "/s" or "";
        sCmd     = 'dir "'..sPath..'" /b /ad '..sRecurse..' 2>nul';

    elseif (_bOSIsUnix) then

        sRecurse = bRecursive and "" or " -maxdepth 1";
        sCmd     = 'find "'..sPath..'" -type d'..sRecurse..' 2>/dev/null';

    else
        error("io.listdirs: unsupported operating system.", 2);
    end

    local uPipe = io.popen(sCmd);
    if (uPipe) then

        for sLine in uPipe:lines() do

            local pDir;

            -- Normalize path separators for Windows
            pDir = _bOSIsWindows and sLine:gsub(__, _) or sLine;

            -- Remove the trailing path separator if present
            pDir = pDir:gsub("[/\\]+$", "");

            -- When not recursive on Windows, the output is relative; prefix with base path.
            if (_bOSIsWindows and not bRecursive) then
                pDir = sPath.._..pDir;
            end

            tRet[#tRet + 1] = pDir;

            if (bHasCallback) then
                fCallback(pDir, false);
            end

        end

        uPipe:close();

    end

    return tRet;
end


--[[
██████╗ ██╗      ██████╗ ██████╗  █████╗ ██╗         ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
██╔════╝ ██║     ██╔═══██╗██╔══██╗██╔══██╗██║         ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
██║  ███╗██║     ██║   ██║██████╔╝███████║██║         █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
██║   ██║██║     ██║   ██║██╔══██╗██╔══██║██║         ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
╚██████╔╝███████╗╚██████╔╝██████╔╝██║  ██║███████╗    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
]]


--[[!
    @fqxn LuaEx.Lua Hooks.io.chmod
    @desc Modifies filesystem permissions for a file or directory using the native OS command.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPermission</code> to be a non-empty string.
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- Rejects permission or path values containing double quotes or CR/LF characters.
    <br>- On Windows, executes <code>icacls</code> with <code>/grant:r</code>.
    <br>- On Unix-like systems, executes <code>chmod</code>.
    <br>- Does not translate or normalize permission formats between operating systems.
    <br>- Returns the result of <code>os.execute</code>.
    @param string sPermission The permission string passed directly to the underlying OS command.
    @param string sPath The filesystem path whose permissions are modified.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.chmod("755", "/usr/local/bin/tool");
    io.chmod("Users:(RX)", "C:\\Program Files\\MyApp");
!]]
function io.chmod(sPermission, sPath);

    if not (rawtype(sPermission) == "string") then
        error("io.chmod: permission must be of type string. Got "..rawtype(sPermission)..".", 2);
    end

    if (sPermission == "") then
        error("io.chmod: permission cannot be empty.", 2);
    end

    if not (rawtype(sPath) == "string") then
        error("io.chmod: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.chmod: path cannot be empty.", 2);
    end

    -- Safety: quoted shell args.
    if (sPermission:find('[\r\n"]', 1, false)) then
        error('io.chmod: permission cannot contain CR/LF or double quotes (").', 2);
    end

    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.chmod: path cannot contain CR/LF or double quotes (").', 2);
    end

    if (_bOSIsWindows) then
        -- Windows note: permission must be an icacls grant expression fragment (no quotes).
        -- Example: 'Users:(RX)' or 'Everyone:(F)' or 'USERNAME:(M)'
        return execute('icacls "'..sPath..'" /grant:r '..sPermission..' 1>nul 2>nul');
    elseif (_bOSIsUnix) then
        -- Unix: permission may be symbolic ("u+rwx") or octal ("755"), per chmod.
        return execute('chmod '..sPermission..' "'..sPath..'" 1>/dev/null 2>/dev/null');
    end

    error("io.chmod: unsupported operating system.", 2);
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.copy
    @desc Copies a file from a source path to a destination path using the native system command.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sSource</code> to be a non-empty string.
    <br>- Requires <code>sDestination</code> to be a non-empty string.
    <br>- Rejects source or destination paths containing double quotes or CR/LF characters.
    <br>- Executes the Windows <code>copy</code> command directly.
    <br>- This function is supported on Windows systems only.
    <br>- Does not verify file existence, overwrite behavior, or destination accessibility.
    <br>- Does not recurse directories.
    <br>- Returns the result of <code>os.execute</code>.
    @param string sSource The source file path.
    @param string sDestination The destination file path.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.copy("input.txt", "backup\\input.txt");
!]]
function io.copy(sSource, sDestination);
    local sCmd;
    local vRet;

    if not (rawtype(sSource) == "string") then
        error("io.copy: source must be of type string. Got "..rawtype(sSource)..".", 2);
    end

    if (sSource == "") then
        error("io.copy: source cannot be empty.", 2);
    end

    if not (rawtype(sDestination) == "string") then
        error("io.copy: destination must be of type string. Got "..rawtype(sDestination)..".", 2);
    end

    if (sDestination == "") then
        error("io.copy: destination cannot be empty.", 2);
    end

    -- Safety: quoted shell args
    if (sSource:find('[\r\n"]', 1, false)) then
        error('io.copy: source cannot contain CR/LF or double quotes (").', 2);
    end

    if (sDestination:find('[\r\n"]', 1, false)) then
        error('io.copy: destination cannot contain CR/LF or double quotes (").', 2);
    end

    if not (_bOSIsWindows) then
        error("io.copy: unsupported operating system (Windows only).", 2);
    end

    sCmd = 'copy "'..sSource..'" "'..sDestination..'" 1>nul 2>nul';
    vRet = execute(sCmd);

    return vRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.delete
    @desc Deletes a file using the native system command.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- Rejects path values containing double quotes or CR/LF characters.
    <br>- Executes the Windows <code>del</code> command with <code>/f</code> and <code>/q</code>.
    <br>- Supported on Windows systems only.
    <br>- Does not delete directories or perform recursive removal.
    <br>- Does not verify file existence or permissions before execution.
    <br>- Returns the result of <code>os.execute</code>.
    @param string sPath The file path to delete.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.delete("temp\\old_file.tmp");
!]]
function io.delete(sPath);

    local sCmd;
    local vRet;

    if not (rawtype(sPath) == "string") then
        error("io.delete: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.delete: path cannot be empty.", 2);
    end

    -- Safety: quoted shell arg
    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.delete: path cannot contain CR/LF or double quotes (").', 2);
    end

    if not (_bOSIsWindows) then
        error("io.delete: unsupported operating system (Windows only).", 2);
    end

    -- /f = force, /q = quiet (matches your suppression style elsewhere)
    sCmd = 'del /f /q "'..sPath..'" 1>nul 2>nul';
    vRet = execute(sCmd);

    return vRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.exists
    @desc Returns true if the given path exists (file or directory), otherwise false.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- Rejects <code>sPath</code> containing double quotes or CR/LF characters.
    <br>- Uses <code>os.rename</code> as a fast existence probe.
    <br>- Treats "permission denied" as existing.
    @param string sPath The filesystem path to test.
    @ret boolean bExists True if the path exists (file or directory).
!]]
function io.exists(sPath);

    if not (rawtype(sPath) == "string") then
        error("io.exists: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.exists: path cannot be empty.", 2);
    end

    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.exists: path cannot contain CR/LF or double quotes (").', 2);
    end

    local ok, _, code = os.rename(sPath, sPath);

    if (ok) then
        return true;
    end

    -- Windows: 13 is commonly "permission denied" (treat as exists).
    -- Some environments return nil,"Permission denied",13.
    if (code == 13) then
        return true;
    end

    return false;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.findfile
    @desc Searches the filesystem for a file by name and returns its location.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sFilename</code> to be a non-empty string.
    <br>- Rejects filenames containing double quotes or CR/LF characters.
    <br>- Searches the filesystem recursively for a regular file with an exact name match.
    <br>- On Windows, uses <code>dir /s /b /a-d</code> starting from the current drive root.
    <br>- On Unix, uses <code>find / -type f -name</code> starting from the filesystem root.
    <br>- Stops searching after the first match is found.
    <br>- Does not query file metadata or verify accessibility beyond what the underlying command returns.
    @param string sFilename The exact filename to search for.
    @ret string|nil pPath The full path to the first matching file, or <code>nil</code> if no match is found.
    @ex
    local p = io.findfile("notepad.exe");
    if (p) then
        print("Found at:", p);
    end
!]]
function io.findfile(sFilename);

    local sCmd    = "";
    local pRet    = nil;
    local uPipe   = nil;
    local sResult = nil;

    if not (rawtype(sFilename) == "string") then
        error("io.findfile: filename must be of type string. Got "..rawtype(sFilename)..".", 2);
    end

    if (sFilename == "") then
        error("io.filefind: filename cannot be empty.", 2);
    end

    -- Safety: quoted shell arg
    if (sFilename:find('[\r\n"]', 1, false)) then
        error('io.findfile: filename cannot contain CR/LF or double quotes (").', 2);
    end

    if (_bOSIsWindows) then
        -- /s  = recurse
        -- /b  = bare format
        -- /a-d = files only
        -- Searches from current drive root
        sCmd = 'dir "\\'..sFilename..'" /s /b /a-d 2>nul';
    elseif (_bOSIsUnix) then
        -- /     = filesystem root
        -- -type f = regular files only
        -- -name   = exact filename match
        -- -print -quit = first hit only
        sCmd = 'find / -type f -name "'..sFilename..'" -print -quit 2>/dev/null';
    else
        error("io.findfile: unsupported operating system.", 2);
    end

    uPipe = io.popen(sCmd);
    if (uPipe) then
        sResult = uPipe:read("*l");
        uPipe:close();

        if (rawtype(sResult) == "string" and sResult ~= "") then
            pRet = sResult;
        end
    end

    return pRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.findstr
    @desc Executes the native <code>findstr</code> command with validated arguments.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sText</code> to be a non-empty string; otherwise throws an error.
    <br>- Rejects <code>sText</code> containing double quotes or CR/LF characters.
    <br>- If <code>sPath</code> is <code>nil</code>, executes <code>findstr "&lt;sText&gt;"</code>.
    <br>- If <code>sPath</code> is provided, it must be a non-empty string.
    <br>- Rejects <code>sPath</code> containing double quotes or CR/LF characters.
    <br>- Executes the constructed command via <code>os.execute</code>.
    <br>- Returns the result of <code>os.execute</code>.
    @param string sText The text string passed directly to <code>findstr</code>.
    @param string|nil sPath Optional path argument passed directly to <code>findstr</code>.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.findstr("ERROR", "C:\\Logs\\app.log");
    io.findstr("TODO");
!]]
function io.findstr(sText, sPath);

    local sCmd  = "";
    local vRet  = nil;

    if not (rawtype(sText) == "string") then
        error("io.findstr: text must be of type string. Got "..rawtype(sText)..".", 2);
    end

    if (sText == "") then
        error("io.findstr: text cannot be empty.", 2);
    end

    -- Safety: this wrapper uses quoted args; reject quote/newline to avoid malformed commands.
    if (sText:find('[\r\n"]', 1, false)) then
        error('io.findstr: text cannot contain CR/LF or double quotes (").', 2);
    end

    if (sPath ~= nil) then

        if not (rawtype(sPath) == "string") then
            error("io.findstr: path must be a string or nil. Got "..rawtype(sPath)..".", 2);
        end

        if (sPath == "") then
            error("io.findstr: path cannot be empty when provided.", 2);
        end

        if (sPath:find('[\r\n"]', 1, false)) then
            error('io.findstr: path cannot contain CR/LF or double quotes (").', 2);
        end

        sCmd = 'findstr "'..sText..'" "'..sPath..'"';

    else
        sCmd = 'findstr "'..sText..'"';
    end

    vRet = execute(sCmd);

    return vRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.getenddir
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


--[[!
    @fqxn LuaEx.Lua Hooks.io.getuserdir
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
    @fqxn LuaEx.Lua Hooks.io.grep
    @desc Executes the native <code>grep</code> command with the provided arguments.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Validates that <code>sPattern</code> is of type string; otherwise throws an error.
    <br>- If <code>sPath</code> is a string, executes <code>grep "&lt;sPattern&gt;" "&lt;sPath&gt;"</code>.
    <br>- If <code>sPath</code> is not a string, executes <code>grep "&lt;sPattern&gt;"</code>.
    <br>- Does not perform escaping or sanitization of arguments.
    <br>- Does not add any command-line flags.
    <br>- Returns the result of <code>os.execute</code> when <code>sPath</code> is not a string.
    <br>- When <code>sPath</code> <em>is</em> a string, the command result is assigned to a local
    <br>variable but not explicitly returned (implicit <code>nil</code> return).
    @param string sPattern The pattern passed directly to <code>grep</code>.
    @param string|any sPath Optional path argument passed directly to <code>grep</code>.
    @ret any vResult The return value of <code>os.execute</code>, or <code>nil</code> depending on control flow.
    @ex
    io.grep("TODO", "/var/log/syslog");
    io.grep("error");
!]]
function io.grep(sPattern, sPath)
    local vRet;

    if not (rawtype(sPattern) == "string") then
        error("io.grep: ".."Pattern must be of type string. Got "..rawtype(sPattern)..'.');
    end

    if (rawtype(sPath) == "string") then
        vRet = execute('grep "'..sPattern..'" "'..sPath..'"');
    else
        vRet = execute('grep "'..sPattern..'"');
    end

    return vRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.isdir
    @desc Returns true if the given path exists and is a directory.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- Rejects <code>sPath</code> containing double quotes or CR/LF characters.
    <br>- Uses OS-native checks:
    <br>  - Windows: <code>if exist "path\NUL"</code>
    <br>  - Unix: <code>test -d "path"</code>
    @param string sPath The filesystem path to test.
    @ret boolean bIsDir True if the path is a directory.
!]]
function io.isdir(sPath);

    if not (rawtype(sPath) == "string") then
        error("io.isdir: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.isdir: path cannot be empty.", 2);
    end

    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.isdir: path cannot contain CR/LF or double quotes (").', 2);
    end

    local vOK;

    if (_bOSIsWindows) then
        -- NUL exists inside directories, and this is the classic fast dir test.
        vOK = os.execute('cmd /c if exist "'..sPath..'\\NUL" (exit /b 0) else (exit /b 1)');
    elseif (_bOSIsUnix) then
        vOK = os.execute('test -d "'..sPath..'"');
    else
        error("io.isdir: unsupported operating system.", 2);
    end

    -- Lua 5.3: vOK can be true/false OR (status,"exit",code) depending on platform.
    if (vOK == true) then return true end
    if (type(vOK) == "number") then return vOK == 0 end

    return false;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.isdirectchild
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
    @fqxn LuaEx.Lua Hooks.io.isfile
    @desc Returns true if the given path exists and is a regular file.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- Rejects <code>sPath</code> containing double quotes or CR/LF characters.
    <br>- Uses OS-native checks:
    <br>  - Windows: exists AND NOT a directory via <code>path\NUL</code> test.
    <br>  - Unix: <code>test -f "path"</code>
    @param string sPath The filesystem path to test.
    @ret boolean bIsFile True if the path is a regular file.
!]]
function io.isfile(sPath);

    if not (rawtype(sPath) == "string") then
        error("io.isfile: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.isfile: path cannot be empty.", 2);
    end

    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.isfile: path cannot contain CR/LF or double quotes (").', 2);
    end

    local vOK;

    if (_bOSIsWindows) then
        vOK = os.execute('cmd /c if exist "'..sPath..'" (if exist "'..sPath..'\\NUL" (exit /b 1) else (exit /b 0)) else (exit /b 1)');
    elseif (_bOSIsUnix) then
        vOK = os.execute('test -f "'..sPath..'"');
    else
        error("io.isfile: unsupported operating system.", 2);
    end

    if (vOK == true) then return true end
    if (type(vOK) == "number") then return vOK == 0 end

    return false;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.list
    @desc Lists all files and directories in a given path (optionally recursively).
    @param string sPath The path which to search for files and directories.
    @param boolean|nil bRecursive Whether to recurse through subdirectories.
    @param function|nil fCallback The function to call when a file or directory is found.
    <br>This function must accept a string as its first argument which will be the full path to the item found.
    <br>This function must accept a boolean as its second argument which indicates whether the item found is a file (true if a file) or a directory (false if a directory).
    @ret table tItems A table whose keys are strings (directories, files) whose values are numerically-indexed table whose values are full paths of the found files and directories.
    @ex
    local function printitem(pFile, bIsFile)
        print("Is File: "..tostring(bIsFile), pFile);
    end

    local tItems = io.list("C:\\Windows\\System32", true, printitem, "exe");
    --\[\[ Output->
    Is File: false	C:\Windows\System32\0409
    Is File: false	C:\Windows\System32\AdvancedInstallers
    Is File: false	C:\Windows\System32\am-et
    Is File: false	C:\Windows\System32\AppLocker
    ...
    Is File: true	C:\Windows\System32\agentactivationruntimestarter.exe
    Is File: true	C:\Windows\System32\AgentService.exe
    Is File: true	C:\Windows\System32\AggregatorHost.exe
    Is File: true	C:\Windows\System32\aitstatic.exe
    ...
    \]\]
!]]
function io.list(sPath, bRecursive, fCallback, ...)
    return {
        directories = listdirs(sPath, bRecursive, fCallback),
        files       = listfiles(sPath, bRecursive, fCallback, ...),
    };
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.mkdir
    @desc Creates a directory at the specified path using the native system command.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- Rejects path values containing double quotes or CR/LF characters.
    <br>- On Windows, executes the <code>mkdir</code> command.
    <br>- On Unix-like systems, executes <code>mkdir -p</code>.
    <br>- Parent directories are created as needed.
    <br>- Does not verify path existence or permissions before execution.
    <br>- Returns the result of <code>os.execute</code>.
    @param string sPath The directory path to create.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.mkdir("output\\logs");
!]]
function io.mkdir(sPath);

    local sCmd;
    local vRet;

    if not (rawtype(sPath) == "string") then
        error("io.mkdir: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.mkdir: path cannot be empty.", 2);
    end

    -- Safety: quoted shell arg
    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.mkdir: path cannot contain CR/LF or double quotes (").', 2);
    end

    if (_bOSIsWindows) then
        -- mkdir on Windows creates intermediate directories automatically
        sCmd = 'mkdir "'..sPath..'" 1>nul 2>nul';
    elseif (_bOSIsUnix) then
        -- -p mirrors Windows mkdir behavior (create parents, no error if exists)
        sCmd = 'mkdir -p "'..sPath..'" 1>/dev/null 2>/dev/null';
    else
        error("io.mkdir: unsupported operating system.", 2);
    end

    vRet = execute(sCmd);

    return vRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.move
    @desc Moves or renames a file using the native system command.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sSource</code> to be a non-empty string.
    <br>- Requires <code>sDestination</code> to be a non-empty string.
    <br>- Rejects source or destination paths containing double quotes or CR/LF characters.
    <br>- Executes the Windows <code>move</code> command directly.
    <br>- Supported on Windows systems only.
    <br>- Does not verify file existence, overwrite behavior, or destination accessibility.
    <br>- Does not perform recursive directory moves.
    <br>- Returns the result of <code>os.execute</code>.
    @param string sSource The source file path.
    @param string sDestination The destination file path.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.move("temp\\file.txt", "archive\\file.txt");
!]]
function io.move(sSource, sDestination);

    local sCmd;
    local vRet;

    if not (rawtype(sSource) == "string") then
        error("io.move: source must be of type string. Got "..rawtype(sSource)..".", 2);
    end

    if (sSource == "") then
        error("io.move: source cannot be empty.", 2);
    end

    if not (rawtype(sDestination) == "string") then
        error("io.move: destination must be of type string. Got "..rawtype(sDestination)..".", 2);
    end

    if (sDestination == "") then
        error("io.move: destination cannot be empty.", 2);
    end

    -- Safety: quoted shell args
    if (sSource:find('[\r\n"]', 1, false)) then
        error('io.move: source cannot contain CR/LF or double quotes (").', 2);
    end

    if (sDestination:find('[\r\n"]', 1, false)) then
        error('io.move: destination cannot contain CR/LF or double quotes (").', 2);
    end

    if not (_bOSIsWindows) then
        error("io.move: unsupported operating system (Windows only).", 2);
    end

    sCmd = 'move "'..sSource..'" "'..sDestination..'" 1>nul 2>nul';
    vRet = execute(sCmd);

    return vRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.normalizepath
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
    @fqxn LuaEx.Lua Hooks.io.rmdir
    @desc Removes a directory and its contents using the native system command.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sPath</code> to be a non-empty string.
    <br>- Rejects path values containing double quotes or CR/LF characters.
    <br>- Removes the target directory recursively.
    <br>- On Windows, executes <code>rmdir /s /q</code>.
    <br>- On Unix-like systems, executes <code>rm -rf</code>.
    <br>- Does not verify path existence or prompt for confirmation.
    <br>- Returns the result of <code>os.execute</code>.
    @param string sPath The directory path to remove.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.rmdir("build\\temp");
!]]
function io.rmdir(sPath);

    local sCmd;
    local vRet;

    if not (rawtype(sPath) == "string") then
        error("io.rmdir: path must be of type string. Got "..rawtype(sPath)..".", 2);
    end

    if (sPath == "") then
        error("io.rmdir: path cannot be empty.", 2);
    end

    -- Safety: quoted shell arg
    if (sPath:find('[\r\n"]', 1, false)) then
        error('io.rmdir: path cannot contain CR/LF or double quotes (").', 2);
    end

    if (_bOSIsWindows) then
        -- /s = remove directory tree, /q = quiet
        sCmd = 'rmdir /s /q "'..sPath..'" 1>nul 2>nul';
    elseif (_bOSIsUnix) then
        -- Recursive removal, no prompts
        sCmd = 'rm -rf "'..sPath..'" 1>/dev/null 2>/dev/null';
    else
        error("io.rmdir: unsupported operating system.", 2);
    end

    vRet = execute(sCmd);

    return vRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.zip
    @desc Creates a ZIP archive containing the specified files using the native system command.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>tFiles</code> to be a non-empty table of file path strings.
    <br>- Requires <code>sDestination</code> to be a non-empty string.
    <br>- Rejects file paths or destination paths containing double quotes or CR/LF characters.
    <br>- Does not verify file existence or accessibility before invoking the command.
    <br>- Executes the <code>zip</code> command directly; availability depends on the system environment.
    <br>- Does not recurse directories or expand wildcards.
    <br>- Returns the result of <code>os.execute</code>.
    @param table tFiles A numerically-indexed table of file paths to include in the archive.
    @param string sDestination The output ZIP file path.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.zip({ "file1.txt", "file2.txt" }, "archive.zip");
!]]
function io.zip(tFiles, sDestination);

    local sCmd;
    local nCount = 0;
    local sRet;

    if not (rawtype(tFiles) == "table") then
        error("io.zip: files must be of type table. Got "..rawtype(tFiles)..".", 2);
    end

    if not (rawtype(sDestination) == "string") then
        error("io.zip: destination must be of type string. Got "..rawtype(sDestination)..".", 2);
    end

    if (sDestination == "") then
        error("io.zip: destination cannot be empty.", 2);
    end

    if (sDestination:find('[\r\n"]', 1, false)) then
        error('io.zip: destination cannot contain CR/LF or double quotes (").', 2);
    end

    for i, v in ipairs(tFiles) do
        if not (rawtype(v) == "string") then
            error("io.zip: file at index "..i.." must be a string. Got "..rawtype(v)..".", 2);
        end

        if (v == "") then
            error("io.zip: file at index "..i.." cannot be empty.", 2);
        end

        if (v:find('[\r\n"]', 1, false)) then
            error('io.zip: file paths cannot contain CR/LF or double quotes (").', 2);
        end

        nCount = nCount + 1;
    end

    if (nCount == 0) then
        error("io.zip: files table cannot be empty.", 2);
    end

    if (_bOSIsWindows) then
        -- Requires zip to be available in PATH (e.g. from Git, MSYS, Cygwin)
        sCmd = 'zip "'..sDestination..'" "'..table.concat(tFiles, '" "')..'"';
    elseif (_bOSIsUnix) then
        sCmd = 'zip "'..sDestination..'" "'..table.concat(tFiles, '" "')..'"';
    else
        error("io.zip: unsupported operating system.", 2);
    end

    sRet = execute(sCmd);

    return sRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.io.unzip
    @desc Extracts the contents of a ZIP archive to a destination directory using the native system command.
    <br>
    <br><strong>Behavior notes (as implemented):</strong>
    <br>- Requires <code>sArchive</code> to be a non-empty string.
    <br>- Requires <code>sDestination</code> to be a non-empty string.
    <br>- Rejects archive or destination paths containing double quotes or CR/LF characters.
    <br>- Executes the <code>unzip</code> command directly; availability depends on the system environment.
    <br>- Does not verify archive existence, format validity, or destination permissions.
    <br>- Does not perform cleanup or conflict resolution.
    <br>- Returns the result of <code>os.execute</code>.
    @param string sArchive The ZIP archive file path.
    @param string sDestination The directory path to extract files into.
    @ret any vResult The return value of <code>os.execute</code> for the executed command.
    @ex
    io.unzip("archive.zip", "output_dir");
!]]
function io.unzip(sArchive, sDestination);

    local sCmd;
    local vRet;

    if not (rawtype(sArchive) == "string") then
        error("io.unzip: archive must be of type string. Got "..rawtype(sArchive)..".", 2);
    end

    if (sArchive == "") then
        error("io.unzip: archive cannot be empty.", 2);
    end

    if not (rawtype(sDestination) == "string") then
        error("io.unzip: destination must be of type string. Got "..rawtype(sDestination)..".", 2);
    end

    if (sDestination == "") then
        error("io.unzip: destination cannot be empty.", 2);
    end

    if (sArchive:find('[\r\n"]', 1, false)) then
        error('io.unzip: archive cannot contain CR/LF or double quotes (").', 2);
    end

    if (sDestination:find('[\r\n"]', 1, false)) then
        error('io.unzip: destination cannot contain CR/LF or double quotes (").', 2);
    end

    if (_bOSIsWindows or _bOSIsUnix) then
        -- Requires "unzip" to be available in PATH
        sCmd = 'unzip "'..sArchive..'" -d "'..sDestination..'"';
    else
        error("io.unzip: unsupported operating system.", 2);
    end

    vRet = execute(sCmd);

    return vRet;
end


-- proper integration of local functions
io.listdirs     = listdirs;
io.listfiles    = listfiles;
io.splitpath    = splitpath;

return io;
