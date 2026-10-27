--[[!
    @fqxn Tests.VFS
    @desc Regression checks for restricted errors, permission preflight, revocation
    and portable device names. All file operations use the example's in-memory io
    implementation. Run with node tests/vfs_regression.cjs from the repository root.
!]]
if (not LUAEX_INIT) then require("LuaEx.load")(4); end

local _nChecks = 0;

--[[!
    @fqxn Tests.VFS.Helpers.check
    @scope local
    @desc Asserts an independently specified regression expectation and counts it.
    @param string sLabel Expectation description.
    @param boolean bCondition Whether the expected behavior occurred.
!]]
local function check(sLabel, bCondition)
    assert(bCondition, sLabel);
    _nChecks = _nChecks + 1;
end

check("Documented utility module resolves to the loaded VFS class",
      require("LuaEx.classes.util.VFS") == VFS);

require("examples.support.VFSMemory").run(function(tExpectedFiles)
    local fOriginalList  = io.list;
    local fOriginalIsDir = io.isdir;
    local nLookups       = 0;
    local bListingFails  = false;

    -- Capture spies through normal VFS() construction, then restore the support
    -- API. This exercises the default backend without passing VFS an adapter.
    io.list = function(...)
        nLookups = nLookups + 1;
        if (bListingFails) then return nil, "/private/SECRET listing failure"; end
        return fOriginalList(...);
    end;
    io.isdir = function(...)
        nLookups = nLookups + 1;
        return fOriginalIsDir(...);
    end;
    local oVFS = VFS();
    io.list, io.isdir = fOriginalList, fOriginalIsDir;

    assert(oVFS.mount("/mod", "/demo/mod"));
    assert(oVFS.mount("/shared", "/demo/shared"));
    assert(oVFS.setAlias("MOD", "/mod"));
    assert(oVFS.setAlias("PRIVATE", "/shared"));

    local oDenied = oVFS.createAccess({{path = "/mod"}});
    local nBefore = nLookups;
    local vExisting, sExisting = oDenied.read("/mod/cards.csv");
    local vMissing, sMissing   = oDenied.read("/mod/absent.csv");
    check("Denied existing and missing files return the same reason",
          vExisting == nil and vMissing == nil and sExisting == sMissing);
    check("Denied file reads perform no filesystem lookup", nLookups == nBefore);

    vExisting, sExisting = oDenied.read("PRIVATE");
    vMissing, sMissing   = oDenied.read("UNKNOWN");
    check("Unauthorized and missing aliases are indistinguishable",
          vExisting == nil and vMissing == nil and sExisting == sMissing);
    check("Denied alias reads perform no filesystem lookup", nLookups == nBefore);

    check("Denied directory listing", oDenied.ls("/mod") == nil);
    check("Denied file creation", oDenied.write("/mod/new.txt", "new") == nil);
    check("Denied directory creation", oDenied.mkdir("/mod/new") == nil);
    check("Denied deletion", oDenied.remove("/mod/cards.csv") == nil);
    check("Denied operations perform no filesystem lookup", nLookups == nBefore);

    local oNoDestinationRights = oVFS.createAccess({{
        path = "/mod",
        permissions = {
            readFiles = true, writeFiles = true, copyFiles = true,
            moveFiles = true, deleteFiles = true,
        },
    }});
    nBefore = nLookups;
    check("Write needs creation or overwrite rights",
          oNoDestinationRights.write("/mod/new.txt", "new") == nil);
    check("Copy needs destination creation or overwrite rights",
          oNoDestinationRights.copy("/mod/cards.csv", "/mod/new.txt") == nil);
    check("Move needs destination creation or overwrite rights",
          oNoDestinationRights.move("/mod/cards.csv", "/mod/new.txt") == nil);
    check("Missing destination rights cause no filesystem lookup", nLookups == nBefore);

    local oDeleteFiles = oVFS.createAccess({{
        path = "/mod", permissions = {deleteFiles = true},
    }});
    vExisting, sExisting = oDeleteFiles.remove("/mod/Artwork");
    vMissing, sMissing   = oDeleteFiles.remove("/mod/absent");
    check("Type-dependent deletion denial does not reveal directory existence",
          vExisting == nil and vMissing == nil and sExisting == sMissing);

    local oReadOnly = oVFS.createAccess({{
        alias = "MOD",
        permissions = {readFiles = true, listFiles = true, listDirectories = true},
    }});
    check("Authorized binary read preserves content",
          oReadOnly.read("/mod/cards.csv") == tExpectedFiles["/demo/mod/cards.csv"]);
    local _, sOutsideAlias = oReadOnly.read("PRIVATE");
    local _, sUnknownAlias = oReadOnly.read("UNKNOWN");
    check("Read rights do not expose other aliases", sOutsideAlias == sUnknownAlias);
    check("Listings retain successful results", #assert(oReadOnly.ls("/mod")) == 5);

    bListingFails = true;
    local tEntries, sReason = oReadOnly.ls("/mod");
    check("Restricted listing failure is propagated and sanitized",
          tEntries == nil and not sReason:find("SECRET", 1, true));
    check("Restricted operational failures share the same reason", sReason == sOutsideAlias);
    bListingFails = false;

    -- The owner retains the distinction deliberately hidden from restricted calls.
    local _, sOwnerMissing = oVFS.read("/mod/absent.csv");
    local _, sOwnerAlias   = oVFS.read("UNKNOWN");
    check("Owner diagnostics retain context", sOwnerMissing ~= sOwnerAlias);

    assert(oVFS.revokeAccess(oReadOnly));
    nBefore = nLookups;
    local tRevokedCalls = {
        function() return oReadOnly.read("PRIVATE"); end,
        function() return oReadOnly.read("UNKNOWN"); end,
        function() return oReadOnly.read(nil); end,
        function() return oReadOnly.write("/mod/new", "new"); end,
        function() return oReadOnly.mkdir("/mod/new"); end,
        function() return oReadOnly.remove("/mod/cards.csv"); end,
        function() return oReadOnly.copy("/mod/cards.csv", "/mod/new"); end,
        function() return oReadOnly.move("/mod/cards.csv", "/mod/new"); end,
        function() return oReadOnly.ls("/mod"); end,
        function() return oReadOnly.listAliases(); end,
    };
    local sRevokedReason;
    for _, fCall in ipairs(tRevokedCalls) do
        local bOK, vResult, sFailure = pcall(fCall);
        check("Revoked calls reject before resolving their arguments", bOK and vResult == nil);
        sRevokedReason = sRevokedReason or sFailure;
        check("Revoked reasons are independent of the requested target", sFailure == sRevokedReason);
    end
    check("Revoked calls perform no filesystem lookup", nLookups == nBefore);

    -- Capture Windows rules independently of the POSIX memory backend. These
    -- callbacks must never be reached for a forbidden virtual component.
    local tBackend = {separator = "/"};
    for _, sMethod in ipairs({"stat", "list", "read", "write", "mkdir", "remove", "rename"}) do
        tBackend[sMethod] = function() error("Forbidden path reached the backend."); end;
    end
    local sConfig = package.config;
    package.config = "\\"..sConfig:sub(2);
    local oWindows = VFS(tBackend);
    package.config = sConfig;

    -- Check UTF-8 and single-byte encodings, casing and filename extensions.
    for _, sPrefix in ipairs({"COM", "com", "LPT", "lpt"}) do
        for _, nDigit in ipairs({185, 178, 179}) do
            for _, sDigit in ipairs({string.char(nDigit), string.char(194, nDigit)}) do
                for _, sExtension in ipairs({"", ".txt", ".archive.gz"}) do
                    local pPath = "/mod/"..sPrefix..sDigit..sExtension;
                    nBefore = nLookups;
                    local bOK, sFailure = pcall(oWindows.write, pPath, "bad");
                    check("Reserved device spelling is rejected", not bOK and sFailure:find("reserved device name", 1, true) ~= nil);
                    check("Reserved spellings never reach the filesystem", nLookups == nBefore);
                end
            end
        end
    end
    check("Device-like ordinary filenames remain valid", oVFS.write("/mod/COM10.txt", "ordinary") == true);
    check("Ordinary filename reads remain valid", oVFS.read("/mod/COM10.txt") == "ordinary");

    -- macOS and Linux both use POSIX path rules through LuaEx's Unix io API.
    -- Windows-only restrictions must not leak into these instances.
    for _, sName in ipairs({"CON", "NUL.txt", "COM1", "LPT1.txt", "trailing.", "trailing ", "colon:name", "question?", "star*", "pipe|", "less<", "greater>"}) do
        check("POSIX filename can be written: "..sName, oVFS.write("/mod/"..sName, "posix") == true);
        check("POSIX filename can be read: "..sName, oVFS.read("/mod/"..sName) == "posix");
        local bOK, sFailure = pcall(oWindows.write, "/mod/"..sName, "bad");
        check("Windows filename rejected before backend: "..sName,
              not bOK and not sFailure:find("reached the backend", 1, true));
    end
    for _, sName in ipairs({"nul"..string.char(0), ".", "..", "back\\slash", "line\nbreak"}) do
        check("POSIX VFS rejects unsafe components", not pcall(oVFS.write, "/mod/"..sName, "bad"));
    end
    local tEntries = assert(oVFS.ls("/mod"));
    local bFound = false;
    for _, tEntry in ipairs(tEntries) do
        if (tEntry.path == "/mod/CON") then bFound = true; end
    end
    check("POSIX listing accepts Windows device names", bFound);
    local oPOSIXAccess = oVFS.createAccess({{path = "/mod", permissions = {readFiles = true}}});
    check("POSIX restricted reads use the same host rules", oPOSIXAccess.read("/mod/CON") == "posix");

    -- Use the same public serialization entry points as every other class.
    -- Private namespace data must survive without running the constructor.
    assert(oVFS.registerDirectory("/mod/Artwork"));
    local sSnapshot = serialize(oVFS);
    local oRestored = deserialize(sSnapshot);
    check("Restored VFS has the correct class", class.getname(oRestored) == class.getname(VFS));
    check("Restored VFS is independent", oRestored ~= oVFS);
    check("Private aliases survive automatic serialization", oRestored.getAlias("MOD") == "/mod");
    check("Mount paths survive automatic serialization", oRestored.resolve("/mod/CON") == "/demo/mod/CON");
    check("Restored default backend reads files", oRestored.read("/mod/CON") == "posix");
    check("Restored namespace can list files", #oRestored.ls("/mod") == #oVFS.ls("/mod"));
    local oRestoredAccess = oRestored.createAccess({{path = "/mod", permissions = {readFiles = true}}});
    check("Restored VFS can issue access objects", oRestoredAccess.read("/mod/CON") == "posix");
    local oRegisteredAccess = oRestored.createAccess({{path = "/mod/Artwork", permissions = {listDirectories = true, listFiles = true}}});
    check("Explicit directory registrations survive snapshots", #oRegisteredAccess.ls("/mod/Artwork") > 0);
    check("Restored grants still deny writes", not oRestoredAccess.write("/mod/CON", "denied"));
    check("Restored namespace can remove aliases", oRestored.removeAlias("MOD"));
    check("Restored alias changes leave original independent", oVFS.getAlias("MOD") == "/mod");
    check("Original access survives restored namespace changes", oPOSIXAccess.read("/mod/CON") == "posix");
    check("Restored namespace revokes its own alias grants only", oRestoredAccess.read("/mod/CON") == "posix");
    check("Restored VFS can revoke its access objects", oRestored.revokeAccess(oRestoredAccess));
    check("Restored access revocation takes effect", not oRestoredAccess.read("/mod/CON"));
    local oEmpty = deserialize(serialize(VFS()));
    check("Empty VFS round trip retains virtual root", #oEmpty.ls("/") == 0);
    local oEmptyAccess = oEmpty.createAccess({{path = "/", permissions = {listDirectories = true}}});
    check("Restored empty root can grant access before io is used", #oEmptyAccess.ls("/", nil, VFS.DIR) == 0);
    check("Restored empty VFS can subsequently mount", oEmpty.mount("/new", "/demo/mod"));
    check("Restored namespace can be serialized again", class.getname(deserialize(serialize(oRestored))) == class.getname(VFS));

    -- Custom callbacks use the normal serializer's function support. These
    -- callbacks deliberately have no captured host resources or mutable upvalues.
    local oCustom = VFS({
        separator = "/",
        stat = function() return {kind = "directory"}; end,
        list = function() return {}; end,
        read = function() return "custom"; end,
        write = function() return true; end,
        mkdir = function() return true; end,
        remove = function() return true; end,
        rename = function() return true; end,
    });
    assert(oCustom.mount("/custom", "/custom-root"));
    local oCustomRestored = deserialize(serialize(oCustom));
    check("Custom backend callbacks survive normal serialization", #oCustomRestored.ls("/custom") == 0);
    check("Custom native roots survive normal serialization", oCustomRestored.resolve("/custom") == "/custom-root");
    local oWindowsRestored = deserialize(serialize(oWindows));
    local bWindowsOK, sWindowsFailure = pcall(oWindowsRestored.write, "/mod/CON", "bad");
    check("Captured Windows naming rules survive snapshots",
          not bWindowsOK and sWindowsFailure:find("reserved device name", 1, true) ~= nil);
end);

print("PASS VFS regression: ".._nChecks.." checks; permissions, uniform errors, revocation and reserved names.");
