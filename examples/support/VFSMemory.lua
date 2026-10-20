-- Browser/tutorial support only. Production code constructs VFS() directly.
local Memory = {};

--[[!
    @fqxn Examples.VFS.Memory.run
    @desc Runs a tutorial against a fresh in-memory implementation of LuaEx's io
    operations. VFS is constructed normally inside the callback. Replacements are
    restored even when the tutorial fails; captured VFS operations remain private
    to that fixture. No native filesystem writes or shell commands occur.
    @param function fTutorial Receives expected file contents and a mutation counter.
!]]
function Memory.run(fTutorial)
    -- The fixture's native locations are simulated strings, not directories on disk.
    local tDirectories = {
        ["/demo/mod"] = {
            {name = ".config", kind = "directory"},
            {name = ".gitignore", kind = "file"},
            {name = "Artwork", kind = "directory"},
            {name = "cards.csv", kind = "file"},
            {name = "notes.txt", kind = "file"},
        },
        ["/demo/mod/.config"] = {{name = "settings.ini", kind = "file"}},
        ["/demo/mod/Artwork"] = {{name = "frame.svg", kind = "file"}},
        ["/demo/shared"] = {{name = "palette.txt", kind = "file"}},
    };
    local tFiles = {
        ["/demo/mod/.gitignore"]          = "temporary/\n",
        ["/demo/mod/.config/settings.ini"] = "[Display]\nTheme=Midnight\n",
        ["/demo/mod/Artwork/frame.svg"]    = '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="96"></svg>',
        ["/demo/mod/cards.csv"]           = "Name,Power\nMoon Scout,3\nSun Guardian,5\n",
        ["/demo/mod/notes.txt"]           = "This mod folder is a simulated in-memory fixture.\n",
        ["/demo/shared/palette.txt"]      = "Midnight=#19243A\nGold=#D8AD56\n",
    };
    local nMutationCalls = 0;

    --[[!
        @fqxn Examples.VFS.Helpers.fEditEntry
        @scope local
        @desc Adds, replaces or removes a child record in the simulated parent directory.
        This helper never accesses a native filesystem.
        @param string pPath Simulated native child path.
        @param string|nil sKind File/directory kind; nil removes the child.
        @ret boolean bOK Whether the parent exists.
    !]]
    local function fEditEntry(pPath, sKind)
        local pParent, sName = pPath:match("^(.*)/([^/]+)$");
        local tEntries = tDirectories[pParent];
        if (not tEntries) then return nil; end

        for nIndex, tEntry in ipairs(tEntries) do
            if (tEntry.name == sName) then table.remove(tEntries, nIndex); break; end
        end
        if (sKind) then tEntries[#tEntries + 1] = {name = sName, kind = sKind}; end
        return true;
    end

    --[[!
        @fqxn Examples.VFS.Memory
        @desc Memory operations backed entirely by the fixture tables above. Callbacks have
        the same signatures a real host fixture would use. Mutation callbacks change
        only the tables above and count calls so permission enforcement is visible.
        @field string separator Simulated native separator.
        @field function stat Reads a file or directory kind.
        @field function list Reads immediate name/kind directory entries.
        @field function read Reads a complete file string.
        @field function write Creates or replaces simulated files.
        @field function mkdir Creates simulated directories.
        @field function remove Deletes simulated files and empty directories.
        @field function rename Moves simulated files.
    !]]
    local tMemory = {
        separator = "/",

        --[[!
            @fqxn Examples.VFS.Memory.stat
            @desc Looks up an exact simulated native path without accessing the host.
            @param string pPath Simulated native location.
            @ret table tInfo Kind record, or nil when absent.
        !]]
        stat = function(pPath)
            if (tDirectories[pPath]) then return {kind = "directory"}; end
            if (tFiles[pPath]) then return {kind = "file"}; end
            return nil, "Not found.";
        end,

        --[[!
            @fqxn Examples.VFS.Memory.list
            @desc Returns immediate entries from one simulated directory.
            @param string pDirectory Simulated native directory.
            @ret table tEntries Entry list, or nil when absent.
        !]]
        list = function(pDirectory)
            return tDirectories[pDirectory];
        end,

        --[[!
            @fqxn Examples.VFS.Memory.read
            @desc Returns the simulated file's complete contents.
            @param string pFile Simulated native file.
            @ret string sContents File contents, or nil when absent.
        !]]
        read = function(pFile)
            return tFiles[pFile];
        end,

        --[[!
            @fqxn Examples.VFS.Memory.write
            @desc Writes a simulated file, enforcing the supplied overwrite flag.
            @param string pFile Simulated native destination.
            @param string sData New contents.
            @param boolean bOverwrite Whether replacement is permitted.
            @ret boolean bOK Success, or nil when invalid.
        !]]
        write = function(pFile, sData, bOverwrite)
            nMutationCalls = nMutationCalls + 1;
            if (tDirectories[pFile] or (tFiles[pFile] ~= nil and not bOverwrite)) then return nil; end
            if (not fEditEntry(pFile, "file")) then return nil; end
            tFiles[pFile] = sData;
            return true;
        end,

        --[[!
            @fqxn Examples.VFS.Memory.mkdir
            @desc Creates one simulated directory beneath an existing parent.
            @param string pDirectory New simulated directory.
            @ret boolean bOK Success, or nil when invalid.
        !]]
        mkdir = function(pDirectory)
            nMutationCalls = nMutationCalls + 1;
            if (tDirectories[pDirectory] or tFiles[pDirectory] ~= nil) then return nil; end
            if (not fEditEntry(pDirectory, "directory")) then return nil; end
            tDirectories[pDirectory] = {};
            return true;
        end,

        --[[!
            @fqxn Examples.VFS.Memory.remove
            @desc Removes a simulated file or empty directory; recursion belongs to VFS.
            @param string pPath Simulated native path.
            @param string sKind File or directory.
            @ret boolean bOK Success, or nil when invalid.
        !]]
        remove = function(pPath, sKind)
            nMutationCalls = nMutationCalls + 1;
            if (sKind == "directory") then
                if (not tDirectories[pPath] or #tDirectories[pPath] > 0) then return nil; end
            elseif (tFiles[pPath] == nil) then return nil; end
            if (not fEditEntry(pPath)) then return nil; end
            tDirectories[pPath], tFiles[pPath] = nil, nil;
            return true;
        end,

        --[[!
            @fqxn Examples.VFS.Memory.rename
            @desc Moves a simulated file, enforcing destination overwrite policy.
            @param string pSource Simulated source.
            @param string pDestination Simulated destination.
            @param boolean bOverwrite Whether replacement is permitted.
            @ret boolean bOK Success, or nil when invalid.
        !]]
        rename = function(pSource, pDestination, bOverwrite)
            nMutationCalls = nMutationCalls + 1;
            if (tFiles[pSource] == nil or tDirectories[pDestination] or
                (tFiles[pDestination] ~= nil and not bOverwrite)) then return nil; end
            if (not fEditEntry(pDestination, "file")) then return nil; end
            fEditEntry(pSource);
            tFiles[pDestination], tFiles[pSource] = tFiles[pSource], nil;
            return true;
        end,
    };

    local tOriginalIO = {};
    local tReplacements = {
        --[[!
            @fqxn Examples.VFS.Memory.io.list
            @desc Supplies io.list's existing full-path directories/files format.
            @param string pDirectory Simulated directory.
            @ret table tListing Immediate directory/file paths.
        !]]
        list = function(pDirectory, bRecursive)
            assert(not bRecursive, "VFS requests immediate native children.");
            local tEntries = tMemory.list(pDirectory);
            if (not tEntries) then return nil; end
            local tListing = {directories = {}, files = {}};
            for _, tEntry in ipairs(tEntries) do
                local tPaths = tEntry.kind == "directory" and tListing.directories or tListing.files;
                tPaths[#tPaths + 1] = pDirectory.."/"..tEntry.name;
            end
            return tListing;
        end,
        --[[!
            @fqxn Examples.VFS.Memory.io.isdir
            @desc Tests a simulated directory using the existing io.isdir signature.
            @param string pPath Simulated path.
            @ret boolean bDirectory Whether the directory exists.
        !]]
        isdir = function(pPath)
            local tInfo = tMemory.stat(pPath);
            return tInfo ~= nil and tInfo.kind == "directory";
        end,
        --[[!
            @fqxn Examples.VFS.Memory.io.isfile
            @desc Tests a simulated file using the existing io.isfile signature.
            @param string pPath Simulated path.
            @ret boolean bFile Whether the file exists.
        !]]
        isfile = function(pPath)
            local tInfo = tMemory.stat(pPath);
            return tInfo ~= nil and tInfo.kind == "file";
        end,
        --[[!
            @fqxn Examples.VFS.Memory.io.exists
            @desc Tests whether a simulated file or directory exists.
            @param string pPath Simulated path.
            @ret boolean bExists Whether the entry exists.
        !]]
        exists = function(pPath) return tMemory.stat(pPath) ~= nil; end,
        mkdir = tMemory.mkdir,
        --[[!
            @fqxn Examples.VFS.Memory.io.open
            @desc Supplies private binary file handles over memory. Handles support
            read, write and close and never reference a native file.
            @param string pFile Simulated file path.
            @param string sMode rb or wb.
            @ret table hFile In-memory handle, or nil on failure.
        !]]
        open = function(pFile, sMode)
            if (sMode == "rb") then
                if (tMemory.read(pFile) == nil) then return nil; end
            elseif (sMode == "wb") then
                if (not tMemory.write(pFile, "", true)) then return nil; end
            else
                return nil;
            end
            local bClosed = false;
            local hFile = {};
            hFile.read = function()
                assert(not bClosed and sMode == "rb", "Invalid memory file read.");
                return tMemory.read(pFile);
            end;
            hFile.write = function(_, sData)
                assert(not bClosed and sMode == "wb", "Invalid memory file write.");
                if (not tMemory.write(pFile, sData, true)) then return nil; end
                return hFile;
            end;
            hFile.close = function() bClosed = true; return true; end;
            return hFile;
        end,
    };

    -- Save the real APIs, install the memory versions only while constructing and
    -- exercising VFS(), and restore everything regardless of the callback result.
    for sName, fReplacement in pairs(tReplacements) do
        tOriginalIO[sName] = io[sName];
        io[sName] = fReplacement;
    end
    local fOriginalRemove = os.remove;
    local fOriginalRename = os.rename;
    local sOriginalConfig = package.config;
    os.remove = function(pPath)
        local tInfo = tMemory.stat(pPath);
        if (not tInfo) then return nil; end
        return tMemory.remove(pPath, tInfo.kind);
    end;
    os.rename = function(pSource, pDestination)
        return tMemory.rename(pSource, pDestination, true);
    end;
    package.config = "/"..sOriginalConfig:sub(2);

    local bOK, sReason = pcall(fTutorial, tFiles, function() return nMutationCalls; end);
    package.config = sOriginalConfig;
    os.remove, os.rename = fOriginalRemove, fOriginalRename;
    for sName, fOriginal in pairs(tOriginalIO) do io[sName] = fOriginal; end
    if (not bOK) then error(sReason, 0); end
end

return Memory;
