-- Fresh-process standalone LuaEx discovery check; no application host is involved.
local function run()
    assert(not rawget(_G, "LUAEX_INIT"), "Run discovery checks in a fresh interpreter.");
    local sOriginalPath = package.path;
    local fExecute, fPopen = os.execute, io.popen;
    local nCalls = 0;
    local pScratch;
    local fScanFiles;
    local nScans = 0;
    local bOK, sReason = xpcall(function()
        os.execute = function() nCalls = nCalls + 1; error("Forbidden shell command."); end;
        io.popen = function() nCalls = nCalls + 1; error("Forbidden process pipe."); end;
        rawtype = type;
        require("LuaEx.hook.iohook");
        local pTemporary = os.tmpname();
        if (pTemporary:match("^\\[^\\]") and os.getenv("TEMP")) then pTemporary = os.getenv("TEMP")..pTemporary; end
        os.remove(pTemporary);
        pScratch = pTemporary.."-luaex-discovery";
        assert(io.mkdir(pScratch.."/nested"));
        local hClass = assert(io.open(pScratch.."/nested/Probe.lxc", "wb"));
        assert(hClass:write("namespace NativeIODiscovery { class Probe { public value() { return 42; } } }"));
        assert(hClass:close());
        local hEnum = assert(io.open(pScratch.."/Order.lxe", "wb"));
        assert(hEnum:write("namespace NativeIODiscovery { public enum Order { First; Second; } }"));
        assert(hEnum:close());
        local hIgnored = assert(io.open(pScratch.."/ignored.lua", "wb"));
        assert(hIgnored:write("error('Discovery executed an unrelated file.')")); assert(hIgnored:close());
        package.path = pScratch.."/?.lua;"..sOriginalPath;
        fScanFiles = io.scanfiles;
        io.scanfiles = function(...) nScans = nScans + 1; return fScanFiles(...); end;
        require("LuaEx.load")();
        assert(nScans == 1, "Startup must scan once for both declaration types.");
        assert(LUAEX_INIT and NativeIODiscovery.Probe().value() == 42);
        assert(lxe.isEnum(NativeIODiscovery.Order));
        assert(package.loaded["LuaEx.libext.schema"] and not package.loaded["LuaEx.extlib.schema"]);
        local nClasses = 0;
        for _, pSource in ipairs(lxc.discover(package.path)) do
            if (pSource:match("[/\\]Probe%.lxc$")) then nClasses = nClasses + 1; end
        end
        assert(nClasses == 1 and nCalls == 0);
        local Discovery = require("LuaEx.lib.SourceDiscovery");
        local tSnapshot = Discovery.scan(pScratch.."/?.lua;"..pScratch.."/nested/?.lua");
        assert(#tSnapshot.Files == 2 and #tSnapshot.ByExtension.lxc == 1 and #tSnapshot.ByExtension.lxe == 1);
        assert(tSnapshot.Directories == 2, "Overlapping roots must share traversal identities.");
        local hLater = assert(io.open(pScratch.."/Later.lxe", "wb"));
        assert(hLater:write("not loaded by discovery")); assert(hLater:close());
        assert(#Discovery.scan(pScratch.."/?.lua").Files == 3, "Discovery snapshots must not be cached.");
        assert(not pcall(Discovery.scan, false));
        assert(not pcall(Discovery.scan, "", {[2] = pScratch}));
        assert(nCalls == 0);
    end, debug.traceback);
    package.path = sOriginalPath;
    os.execute, io.popen = fExecute, fPopen;
    if (fScanFiles) then io.scanfiles = fScanFiles; end
    if (pScratch) then assert(io.rmdir(pScratch)); end
    if (not bOK) then error(sReason, 0); end
    print("PASS standalone LuaEx: native library selected, package.path LXC/LXE discovery, class/enum initialization, canonical source deduplication and zero shell calls.");
end
return run;
