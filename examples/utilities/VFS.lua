-- Independent tutorial. Edit the settings below, then choose Run code.
-- All demonstrated file operations affect Lua tables, never local directories.
local pSource     = debug.getinfo(1, "S").source:gsub("^@", "");
local pRepository = pSource:match("^(.*)[/\\]") or ".";

for _ = 1, 8 do
    local hFile = io.open(pRepository.."/LuaEx/load.lua", "r");
    if (hFile) then hFile:close(); break; end
    pRepository = pRepository.."/..";
end

package.path = pRepository.."/?.lua;"..package.path;
if (not LUAEX_INIT) then require("LuaEx.load")(0, 2); end

local VFS = VFS;
local D   = require("examples.support.tutorial").new("VFS", "Mount folders, resolve paths and grant read-only or writable access to an in-memory filesystem.");

-- Edit these values to explore the listing without changing any files.
local bRecursive = false;
local eKind      = VFS.BOTH; -- VFS.FILE, VFS.DIR or VFS.BOTH.

--[[!
    @fqxn Examples.VFS.Helpers.showEntries
    @scope local
    @desc Prints each listing record independently so all fields remain visible.
    @param table tEntries Successful VFS listing.
!]]
local function showEntries(tEntries)
    for _, tEntry in ipairs(tEntries) do
        D.show(tEntry.path, tEntry);
    end
end

--[[!
    @fqxn Examples.VFS.Helpers.command
    @scope local
    @desc Prints the exact Lua command before it executes, keeping API usage next
    to its results. Multiline grant configuration is shown in full.
    @param string sCommand Lua source displayed to the reader.
!]]
local function command(sCommand)
    print("\n[COMMAND]\n"..sCommand);
end

-- The support runner substitutes in-memory LuaEx io operations for this run.
-- Applications using real directories do not need this support runner.
require("examples.support.VFSMemory").run(function(tExpectedFiles, fMutationCount)
    D.note("This tutorial uses VFS() normally. Its LuaEx io operations are simulated in memory so writes and deletions cannot affect your computer.");

    D.section("Create a namespace over two folders", "Mount paths share one virtual root. Their native directories need not be related. The /mods grouping directory has no native backing.");
    command([=[local oVFS = VFS();]=]);
    local oVFS = VFS();
    command([=[oVFS.mount("/mods/example", "/demo/mod");]=]);
    D.check("Mount the mod folder", oVFS.mount("/mods/example", "/demo/mod"));
    command([=[oVFS.mount("/shared", "/demo/shared");]=]);
    D.check("Mount shared resources", oVFS.mount("/shared", "/demo/shared"));
    command([=[oVFS.ls("/");]=]);
    showEntries(assert(oVFS.ls("/")));
    command([=[oVFS.resolve("/mods/example/cards.csv");]=]);
    D.equal("Owner resolves a file", oVFS.resolve("/mods/example/cards.csv"), "/demo/mod/cards.csv");
    command([=[oVFS.resolve("/mods");]=]);
    D.equal("Grouping directories have no native path", oVFS.resolve("/mods"), nil);

    D.section("List files, directories or both", "The first argument is the directory. Optional recursion defaults to false; the optional kind defaults to VFS.BOTH. Dotfiles are included, but dot-directory references and aliases are excluded.");
    D.show("Recursion setting", bRecursive);
    D.show("Kind setting", eKind);
    command([=[oVFS.ls("/mods/example", bRecursive, eKind);]=]);
    showEntries(assert(oVFS.ls("/mods/example", bRecursive, eKind)));
    command([=[oVFS.ls("/mods/example");]=]);
    D.equal("Default immediate entry count", #assert(oVFS.ls("/mods/example")), 5);
    command([=[oVFS.ls("/mods/example", nil, VFS.FILE);]=]);
    D.equal("Immediate files only", #assert(oVFS.ls("/mods/example", nil, VFS.FILE)), 3);
    command([=[oVFS.ls("/mods/example", nil, VFS.DIR);]=]);
    D.equal("Immediate directories only", #assert(oVFS.ls("/mods/example", nil, VFS.DIR)), 2);
    command([=[oVFS.ls("/mods/example", true);]=]);
    D.equal("Recursive entry count", #assert(oVFS.ls("/mods/example", true)), 7);
    command([=[local tFiles = oVFS.ls("/mods/example", false, VFS.FILE);]=]);
    local tFiles = assert(oVFS.ls("/mods/example", false, VFS.FILE));
    D.equal("A leading dot is not an extension", tFiles[1].name, ".gitignore");
    D.equal("Dotfile extension", tFiles[1].ext, "");
    D.equal("Filename stem", tFiles[2].name, "cards");
    D.equal("Extension excludes its dot", tFiles[2].ext, "csv");

    D.section("Register folders and name aliases", "A grant target must be registered first. Mounts are already registered; their ordinary child folders need registration only when granted or aliased directly.");
    command([=[oVFS.registerDirectory("/mods/example/Artwork");]=]);
    D.check("Register Artwork", oVFS.registerDirectory("/mods/example/Artwork"));
    command([=[oVFS.setAlias("mod", "/mods/example");]=]);
    D.check("Create MOD alias", oVFS.setAlias("mod", "/mods/example"));
    command([=[oVFS.setAlias("mod.art", "/mods/example/Artwork");]=]);
    D.check("Create dotted MOD.ART alias", oVFS.setAlias("mod.art", "/mods/example/Artwork"));
    command([=[oVFS.setAlias("shared", "/shared");]=]);
    D.check("Create shared alias", oVFS.setAlias("shared", "/shared"));
    command([=[oVFS.getAlias("MoD.ArT");]=]);
    D.equal("Alias lookup ignores case", oVFS.getAlias("MoD.ArT"), "/mods/example/Artwork");
    command([=[oVFS.listAliases();]=]);
    for _, tAlias in ipairs(oVFS.listAliases()) do D.show(tAlias.name, tAlias.path); end
    command([=[oVFS.ls("/mods/example");]=]);
    D.equal("Aliases do not add directory entries", #assert(oVFS.ls("/mods/example")), 5);

    D.section("Give a modder two read-only grants", "Each folder has independent permissions. The mod grant permits recursive listing; shared resources permit reads and immediate file listings. No write permission is enabled.");
    command([=[local oAccess = oVFS.createAccess({
        {
            alias = "MOD",
            permissions = {
                readFiles = true, listFiles = true, listDirectories = true,
                recursive = true,
            },
        },
        {
            path = "/shared",
            permissions = {readFiles = true, listFiles = true},
        },
    });]=]);
    local oAccess = oVFS.createAccess({
        {
            alias = "MOD",
            permissions = {
                readFiles = true, listFiles = true, listDirectories = true,
                recursive = true,
            },
        },
        {
            path = "/shared",
            permissions = {readFiles = true, listFiles = true},
        },
    });
    command([=[oAccess.read("/mods/example/cards.csv");]=]);
    D.equal("Read mod data", oAccess.read("/mods/example/cards.csv"), tExpectedFiles["/demo/mod/cards.csv"]);
    command([=[oAccess.read("/mods/example/.config/settings.ini");]=]);
    D.equal("Descendant inherits file access", oAccess.read("/mods/example/.config/settings.ini"), tExpectedFiles["/demo/mod/.config/settings.ini"]);
    command([=[oAccess.read("/shared/palette.txt");]=]);
    D.equal("Read separately granted shared resource", oAccess.read("/shared/palette.txt"), tExpectedFiles["/demo/shared/palette.txt"]);
    command([=[oAccess.ls("MOD", true);]=]);
    D.equal("Recursive mod listing", #assert(oAccess.ls("MOD", true)), 7);
    command([=[oAccess.ls("/shared", nil, VFS.FILE);]=]);
    D.equal("Immediate shared file listing", #assert(oAccess.ls("/shared", nil, VFS.FILE)), 1);
    command([=[oAccess.listAliases();]=]);
    for _, tAlias in ipairs(assert(oAccess.listAliases())) do D.show("Visible alias "..tAlias.name, tAlias.path); end
    command([=[oAccess.mount]=]);
    D.equal("Owner methods are not exposed", oAccess.mount, nil);
    command([=[oAccess.resolve]=]);
    D.equal("Native resolution is not exposed", oAccess.resolve, nil);

    D.section("Denied operations stay inside the interface", "Parent access is not implied by a child grant. Denial returns nil and a reason. Permissions are checked before any mutation callback runs.");
    command([=[oAccess.ls("/mods");]=]);
    local tDenied, sReason = oAccess.ls("/mods");
    D.equal("Listing the parent is denied", tDenied, nil);
    D.show("Denial reason", sReason);
    command([=[oAccess.ls("/");]=]);
    D.equal("Listing root is denied", oAccess.ls("/"), nil);
    command([=[oAccess.ls("/shared", true, VFS.FILE);]=]);
    D.equal("Shared recursion is denied", oAccess.ls("/shared", true, VFS.FILE), nil);
    command([=[oAccess.write("/mods/example/notes.txt", "changed");]=]);
    D.equal("Overwriting is denied", oAccess.write("/mods/example/notes.txt", "changed"), nil);
    command([=[oAccess.write("/mods/example/new.txt", "new");]=]);
    D.equal("File creation is denied", oAccess.write("/mods/example/new.txt", "new"), nil);
    command([=[oAccess.mkdir("/mods/example/new");]=]);
    D.equal("Directory creation is denied", oAccess.mkdir("/mods/example/new"), nil);
    command([=[oAccess.remove("/mods/example/notes.txt");]=]);
    D.equal("Deletion is denied", oAccess.remove("/mods/example/notes.txt"), nil);
    D.equal("No filesystem mutation ran", fMutationCount(), 0);
    command([=[oAccess.read("/mods/example/notes.txt");]=]);
    D.equal("Original contents are intact", oAccess.read("/mods/example/notes.txt"), tExpectedFiles["/demo/mod/notes.txt"]);

    D.section("Malformed configuration and paths are rejected", "Programmer errors throw; operational failures return nil and a reason. Grants cannot overlap, even when an alias names one of the folders.");
    command([=[oAccess.read("/mods/example/../other/secrets.txt");]=]);
    D.reject("Parent traversal", function() oAccess.read("/mods/example/../other/secrets.txt"); end);
    command([=[oAccess.read("/mods/example\\cards.csv");]=]);
    D.reject("Backslash path separators", function() oAccess.read("/mods/example\\cards.csv"); end);
    D.reject("Overlapping grants", function()
        command([=[oVFS.createAccess({{path = "/mods/example"}, {alias = "MOD.ART"}});]=]);
        oVFS.createAccess({{path = "/mods/example"}, {alias = "MOD.ART"}});
    end);
    D.reject("Unknown permission spelling", function()
        command([=[oVFS.createAccess({{alias = "MOD", permissions = {readFile = true}}});]=]);
        oVFS.createAccess({{alias = "MOD", permissions = {readFile = true}}});
    end);
    command([=[oAccess.read("/mods/example/Cards.csv");]=]);
    D.equal("Wrong path case is rejected", oAccess.read("/mods/example/Cards.csv"), nil);

    D.section("Create, write, copy, move and delete in memory", "A separate access object has explicit mutation permissions. All native-looking locations below still refer only to Lua tables; nothing is written to the computer.");
    command([=[local oWriter = oVFS.createAccess({
        {
            alias = "MOD.ART",
            permissions = {
                listFiles = true, listDirectories = true, readFiles = true,
                writeFiles = true, createFiles = true, overwriteFiles = true,
                createDirectories = true, deleteFiles = true, deleteDirectories = true,
                copyFiles = true, moveFiles = true, recursive = true,
            },
        },
    });]=]);
    local oWriter = oVFS.createAccess({
        {
            alias = "MOD.ART",
            permissions = {
                listFiles = true, listDirectories = true, readFiles = true,
                writeFiles = true, createFiles = true, overwriteFiles = true,
                createDirectories = true, deleteFiles = true, deleteDirectories = true,
                copyFiles = true, moveFiles = true, recursive = true,
            },
        },
    });
    command([=[oWriter.mkdir("/mods/example/Artwork/working");]=]);
    D.check("Create an in-memory working directory", oWriter.mkdir("/mods/example/Artwork/working"));
    command([=[oWriter.write("/mods/example/Artwork/working/notes.txt", "First draft");]=]);
    D.check("Create a file", oWriter.write("/mods/example/Artwork/working/notes.txt", "First draft"));
    command([=[oWriter.read("/mods/example/Artwork/working/notes.txt");]=]);
    D.equal("Read the new file", oWriter.read("/mods/example/Artwork/working/notes.txt"), "First draft");
    command([=[oWriter.write("/mods/example/Artwork/working/notes.txt", "Second draft");]=]);
    D.check("Overwrite with explicit permission", oWriter.write("/mods/example/Artwork/working/notes.txt", "Second draft"));
    command([=[oWriter.copy("/mods/example/Artwork/working/notes.txt", "/mods/example/Artwork/working/copy.txt");]=]);
    D.check("Copy a file", oWriter.copy("/mods/example/Artwork/working/notes.txt", "/mods/example/Artwork/working/copy.txt"));
    command([=[oWriter.move("/mods/example/Artwork/working/copy.txt", "/mods/example/Artwork/working/moved.txt");]=]);
    D.check("Move the copy", oWriter.move("/mods/example/Artwork/working/copy.txt", "/mods/example/Artwork/working/moved.txt"));
    command([=[oWriter.read("/mods/example/Artwork/working/moved.txt");]=]);
    D.equal("Moved contents", oWriter.read("/mods/example/Artwork/working/moved.txt"), "Second draft");
    command([=[oWriter.write("/shared/new.txt", "denied");]=]);
    D.equal("Writer cannot escape its grant", oWriter.write("/shared/new.txt", "denied"), nil);
    command([=[oWriter.remove("/mods/example/Artwork/working/notes.txt");]=]);
    D.check("Delete one file", oWriter.remove("/mods/example/Artwork/working/notes.txt"));
    command([=[oWriter.remove("/mods/example/Artwork/working", true);]=]);
    D.check("Recursively delete the remaining working directory", oWriter.remove("/mods/example/Artwork/working", true));
    command([=[oWriter.ls("MOD.ART");]=]);
    D.equal("The original Artwork file remains", #assert(oWriter.ls("MOD.ART")), 1);
    D.check("Filesystem operations affected the in-memory fixture", fMutationCount() > 0);

    D.section("Revoke authority without changing files", "The owner can revoke an access object. Removing an alias also permanently revokes grants made through that alias. These are namespace changes, not physical deletions.");
    command([=[oVFS.revokeAccess(oAccess);]=]);
    D.check("Revoke the complete access object", oVFS.revokeAccess(oAccess));
    command([=[oAccess.read("/mods/example/cards.csv");]=]);
    D.equal("Revoked reads are denied", oAccess.read("/mods/example/cards.csv"), nil);
    command([=[local oAliasAccess = oVFS.createAccess({{alias = "MOD", permissions = {readFiles = true}}});]=]);
    local oAliasAccess = oVFS.createAccess({{alias = "MOD", permissions = {readFiles = true}}});
    command([=[oVFS.removeAlias("mod");]=]);
    D.check("Remove the MOD alias", oVFS.removeAlias("mod"));
    command([=[oAliasAccess.read("/mods/example/cards.csv");]=]);
    D.equal("Alias grant was revoked", oAliasAccess.read("/mods/example/cards.csv"), nil);
    command([=[oVFS.setAlias("MOD", "/mods/example");]=]);
    D.check("Recreate the alias", oVFS.setAlias("MOD", "/mods/example"));
    command([=[oAliasAccess.read("/mods/example/cards.csv");]=]);
    D.equal("Old authority does not revive", oAliasAccess.read("/mods/example/cards.csv"), nil);
    command([=[oVFS.read("/mods/example/cards.csv");]=]);
    D.equal("Owner can still read original data", oVFS.read("/mods/example/cards.csv"), tExpectedFiles["/demo/mod/cards.csv"]);
    D.note("All file operations in this run used LuaEx io signatures backed by memory. No local filesystem writes occurred.");
    D.note("Normal applications use VFS() with LuaEx filesystem operations directly. The host supplies the protected Lua environment and controls links and concurrent filesystem changes.");
    D.finish();

end);
